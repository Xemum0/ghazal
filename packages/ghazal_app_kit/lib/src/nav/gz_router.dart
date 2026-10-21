import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import '../session/session.dart';
import 'go_router_navigator.dart';
import 'gz_pages.dart';
import 'gz_tab_shell.dart';
import 'nav_providers.dart';
import 'nav_spec.dart';

/// Redirect rule of both apps (pure, so it is testable): a signed-in person never sees the first-start screen again (they go to the
/// first tab root, or to the [landing] the flow named for this sign-in: `signInLandingProvider`), and in an app that
/// [GzRouterSpec.requireSession] a signed-out person only sees the public flows (access).
/// Returns the location to go to, or null to stay. The client app is open to guests (ADR 0007), so only its first-start rule applies.
String? gzRedirect(GzRouterSpec spec, {required bool signedIn, required String location, GateResume? landing}) {
  final path = location.startsWith(kRootPathPrefix) ? location.substring(kRootPathPrefix.length) : location;
  if (signedIn && path == spec.startPath) return (landing == null ? null : spec.paths[landing.routeName]) ?? spec.homePath;
  if (!signedIn && spec.requireSession && path != spec.startPath && !spec.publicPrefixes.any((p) => path == p || path.startsWith('$p/'))) {
    return spec.startPath;
  }
  return null;
}

/// Rebuilds a [GoRoute] whose screen is a plain `builder:` so its page is [gzScreenPage] / [gzSheetPage] (a route that already gives a
/// `pageBuilder:` is left alone: its owner chose the page). [rename] and [pathPrefix] make the root-level twin of a branch route.
GoRoute _withPage(GoRoute r, GzRouterSpec spec, {String? rename, String pathPrefix = ''}) {
  final builder = r.builder;
  final id = gzScreenIdOf(r.name);
  final sheet = spec.isSheet(id);
  GoRouterPageBuilder? pageBuilder = r.pageBuilder;
  if (pageBuilder == null && builder != null) {
    pageBuilder = (BuildContext context, GoRouterState state) =>
        sheet ? gzSheetPage<Object?>(state, builder(context, state)) : gzScreenPage<Object?>(state, builder(context, state));
  }
  if (pageBuilder == null && rename == null && pathPrefix.isEmpty) return r;
  return GoRoute(
    path: '$pathPrefix${r.path}',
    name: rename ?? r.name,
    pageBuilder: pageBuilder,
    redirect: r.redirect,
    onExit: r.onExit,
    caseSensitive: r.caseSensitive,
    routes: r.routes,
  );
}

/// Composes the router of an app (called by the generated `buildAppRouter`).
///
/// - [routes]: every screen route that is not the root of a tab (the flows' `<flow>Routes`); [tabRoots]: the roots by inventory id.
/// - A screen that belongs to a tab AND shows the tab bar goes INSIDE that tab's `StatefulShellBranch` (the bar stays, the branch keeps
///   its stack). A screen that hides the bar, belongs to no tab, or is a sheet goes on the root navigator, above the bar. The decision
///   comes from `spec.chrome` (the port of `chromeFor`), never from where the flow file declared the route.
/// - Each branch screen also gets a root-level twin (`<id>@root`, see [kRootRouteSuffix]) for pushes made from a screen above the bar.
/// - [ref] connects the redirect and the refresh listenable to `sessionProvider`; without it there is no redirect (tests). The router
///   follows the session through `ref.container`, NOT through `ref.listen`: a `listen` makes the router (and the navigator that watches it)
///   a dependent of the session provider, and the session notifier then could not read the navigator (a CircularDependencyError in
///   debug builds, `SessionNotifier.completeGate`).
/// - A sign-in with a landing set (`signInLandingProvider`) goes straight to that route with its params in ONE navigation: the session
///   change would otherwise redirect to the home tab, dispose the sign-in screen and drop the params.
GoRouter buildGzRouter({
  required GzRouterSpec spec,
  required List<RouteBase> routes,
  required Map<String, GoRoute> tabRoots,
  required Widget Function(BuildContext context, StatefulNavigationShell shell) tabShellBuilder,
  Ref? ref,
  String? initialLocation,
  Object? initialExtra,
  List<NavigatorObserver> observers = const <NavigatorObserver>[],
}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'gz-root');
  final branchRoutes = <String, List<RouteBase>>{
    for (final t in spec.tabs)
      t.id: <RouteBase>[_withPage(tabRoots[t.rootScreen] ?? (throw StateError('No route for the root of tab ${t.id} (${t.rootScreen})')), spec)],
  };
  final rootRoutes = <RouteBase>[];
  for (final route in routes) {
    if (route is! GoRoute) {
      rootRoutes.add(route);
      continue;
    }
    final chrome = spec.chrome[gzScreenIdOf(route.name)];
    if (chrome != null && chrome.inBranch && branchRoutes.containsKey(chrome.tab)) {
      branchRoutes[chrome.tab]!.add(_withPage(route, spec));
      rootRoutes.add(_withPage(route, spec, rename: '${route.name}$kRootRouteSuffix', pathPrefix: kRootPathPrefix));
    } else {
      rootRoutes.add(_withPage(route, spec));
    }
  }

  ValueNotifier<int>? refresh;
  GoRouter? built;
  if (ref != null) {
    final container = ref.container;
    final changes = ValueNotifier<int>(0);
    refresh = changes;
    final subscription = container.listen<AppSession>(sessionProvider, (_, next) {
      final landing = next.isSignedIn ? container.read(signInLandingProvider.notifier).take() : null;
      final target = built;
      if (landing != null && target != null && spec.paths.containsKey(landing.routeName)) {
        container.read(gateProvider.notifier).dismiss();
        target.goNamed(landing.routeName, extra: landing.params);
      }
      changes.value++;
    });
    ref.onDispose(() {
      subscription.close();
      changes.dispose();
    });
  }

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation ?? spec.startPath,
    initialExtra: initialExtra,
    observers: observers,
    refreshListenable: refresh,
    redirect: ref == null
        ? null
        : (BuildContext context, GoRouterState state) => gzRedirect(
            spec,
            signedIn: ref.container.read(sessionProvider).isSignedIn,
            location: state.uri.path,
            landing: ref.container.read(signInLandingProvider),
          ),
    routes: <RouteBase>[
      ...rootRoutes,
      StatefulShellRoute(
        pageBuilder: (BuildContext context, GoRouterState state, StatefulNavigationShell shell) =>
            GzPage<Object?>(key: state.pageKey, name: 'tabs', child: tabShellBuilder(context, shell)),
        navigatorContainerBuilder: (BuildContext context, StatefulNavigationShell shell, List<Widget> children) =>
            GzTabContainer(shell: shell, branches: children),
        branches: <StatefulShellBranch>[
          for (final t in spec.tabs)
            StatefulShellBranch(
              navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'gz-tab-${t.id}'),
              routes: branchRoutes[t.id]!,
            ),
        ],
      ),
    ],
  );
  gzRouterSpecs[router] = spec;
  built = router;
  return router;
}
