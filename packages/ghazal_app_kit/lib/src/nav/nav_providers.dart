import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import 'go_router_navigator.dart';
import 'nav_spec.dart';

/// The router of the running app. Each app root overrides it with its `buildAppRouter(ref: ref)`:
/// `routerProvider.overrideWith((ref) => buildAppRouter(ref: ref))` (the apps export `clientRouterOverride` / `partnerRouterOverride`).
final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) => throw UnimplementedError('routerProvider is overridden by the app root'));

/// The router spec of each router built by `buildGzRouter` (the navigator reads tabs, chrome and paths from it).
final Expando<GzRouterSpec> gzRouterSpecs = Expando<GzRouterSpec>('gzRouterSpecs');

/// The one toast controller of the app (the app root hands it to `GzToastHost`; the tab shell tells it how tall the bar is).
final Provider<GzToastController> gzToastControllerProvider = Provider<GzToastController>((ref) {
  final controller = GzToastController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// The go_router adapter itself (tests and the tab shell need the extras: `scrollSignals`, `attachShell`).
final Provider<GoRouterNavigator> goRouterNavigatorProvider = Provider<GoRouterNavigator>((ref) {
  final router = ref.watch(routerProvider);
  final spec = gzRouterSpecs[router];
  if (spec == null) throw StateError('The router was not built with buildGzRouter (no GzRouterSpec).');
  return GoRouterNavigator(router: router, spec: spec, toasts: ref.watch(gzToastControllerProvider));
});

/// The navigator contract over the router: `ref.read(gzNavigatorProvider).push('CL-VENU-01', params: {...})`. Screens normally use
/// `GzNavigatorScope.of(context)` (the same adapter, scoped to the screen: its params, its back state); providers use this one.
final Provider<GzNavigator> gzNavigatorProvider = Provider<GzNavigator>((ref) => ref.watch(goRouterNavigatorProvider));

/// Badges of the tab bar by tab id (My Wedding dot and Messages count for the client; Bookings and Messages counts for the partner).
/// The flows fill it: `gzTabBadgesProvider.overrideWith(...)` or a provider that watches their state.
final Provider<Map<String, GzTabBadge>> gzTabBadgesProvider = Provider<Map<String, GzTabBadge>>((ref) => const <String, GzTabBadge>{});

/// Overrides that install an already built [router] for a `ProviderScope` (widget tests, harnesses): the router and the navigator that
/// reads it, so the nested scope never falls back to the parent's `routerProvider`.
List<Override> gzFixedRouterOverrides(GoRouter router) => <Override>[
      routerProvider.overrideWithValue(router),
      goRouterNavigatorProvider.overrideWith((ref) {
        final spec = gzRouterSpecs[router];
        if (spec == null) throw StateError('The router was not built with buildGzRouter (no GzRouterSpec).');
        return GoRouterNavigator(router: router, spec: spec, toasts: ref.watch(gzToastControllerProvider));
      }),
    ];
