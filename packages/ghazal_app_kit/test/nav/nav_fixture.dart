// A small inventory (three tabs, a sheet, a hidden-bar screen, a first-start screen) driven through the REAL router composition
// (`buildGzRouter`), the real tab shell and the real navigator, with probe screens that record what they were told.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

const GzRouterSpec fixtureSpec = GzRouterSpec(
  app: GzAppKind.client,
  tabs: <GzTabSpec>[GzTabSpec('discover', 'T-DISC-01'), GzTabSpec('saved', 'T-SAVD-01'), GzTabSpec('profile', 'T-PROF-01')],
  chrome: <String, GzScreenChrome>{
    'T-ONBD-01': GzScreenChrome(),
    'T-DISC-01': GzScreenChrome(tab: 'discover', tabBar: true),
    'T-DISC-02': GzScreenChrome(tab: 'discover', tabBar: true),
    'T-DISC-03': GzScreenChrome(tab: 'discover'), // hides the bar
    'T-SAVD-01': GzScreenChrome(tab: 'saved', tabBar: true),
    'T-SAVD-02': GzScreenChrome(tab: 'saved', tabBar: true),
    'T-PROF-01': GzScreenChrome(tab: 'profile', tabBar: true),
    'T-SHET-01': GzScreenChrome(tab: 'discover', sheet: true),
    'T-SHET-02': GzScreenChrome(sheet: true),
  },
  paths: <String, String>{
    'T-ONBD-01': '/onboarding/start',
    'T-DISC-01': '/discover/home',
    'T-DISC-02': '/discover/list',
    'T-DISC-03': '/discover/detail',
    'T-SAVD-01': '/saved/home',
    'T-SAVD-02': '/saved/list',
    'T-PROF-01': '/profile/home',
    'T-SHET-01': '/discover/sheet',
    'T-SHET-02': '/discover/sheet-two',
  },
  startPath: '/onboarding/start',
  homePath: '/discover/home',
);

/// What each probe screen saw the last time it built.
class Seen {
  final Map<String, GzNavigator> navigators = <String, GzNavigator>{};
  final Map<String, int> builds = <String, int>{};

  GzNavigator of(String id) => navigators[id]!;
}

GoRoute _route(String id, Seen seen, GzRouterSpec spec) => GoRoute(
  path: spec.paths[id]!,
  name: id,
  builder: (BuildContext context, GoRouterState state) => Probe(id: id, seen: seen),
);

class Probe extends StatelessWidget {
  const Probe({required this.id, required this.seen, super.key});

  final String id;
  final Seen seen;

  @override
  Widget build(BuildContext context) {
    seen.navigators[id] = GzNavigatorScope.of(context);
    seen.builds[id] = (seen.builds[id] ?? 0) + 1;
    return Center(child: Text('screen:$id'));
  }
}

GoRouter buildFixtureRouter(Seen seen, {String? initialLocation, Ref? ref, GzRouterSpec spec = fixtureSpec}) => buildGzRouter(
  spec: spec,
  routes: <RouteBase>[
    for (final id in spec.chrome.keys)
      if (!spec.isTabRoot(id)) _route(id, seen, spec),
  ],
  tabRoots: <String, GoRoute>{for (final t in spec.tabs) t.rootScreen: _route(t.rootScreen, seen, spec)},
  tabShellBuilder: (BuildContext context, StatefulNavigationShell shell) =>
      GzTabShell(navigationShell: shell, kind: spec.app, labelOf: (BuildContext context, String id) => 'tab:$id', barLabel: 'main'),
  ref: ref,
  initialLocation: initialLocation,
);

class NavRig {
  NavRig(this.tester, this.container, this.router, this.seen);

  final WidgetTester tester;
  final ProviderContainer container;
  final GoRouter router;
  final Seen seen;

  GoRouterNavigator get nav => container.read(goRouterNavigatorProvider);

  Future<void> settle() async {
    // Bounded: a few frames of the 320 ms push and the 200 ms tab fade.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  bool get barVisible => find.byType(GzTabBar).hitTestable().evaluate().isNotEmpty;
  bool shows(String id) => find.text('screen:$id').hitTestable().evaluate().isNotEmpty;
  bool built(String id) => find.text('screen:$id', skipOffstage: false).evaluate().isNotEmpty;
}

/// Pumps the fixture app. [useSession] builds the router with a `ref` (redirect + refresh on `sessionProvider`).
Future<NavRig> pumpNav(
  WidgetTester tester, {
  String initialLocation = '/discover/home',
  Locale locale = const Locale('en'),
  bool useSession = false,
  GzRouterSpec spec = fixtureSpec,
  List<Override> overrides = const <Override>[],
  List<void Function(WidgetRef ref)> onResume = const <void Function(WidgetRef ref)>[],
  List<ProviderListenable<Object?>> warmUp = const <ProviderListenable<Object?>>[],
}) async {
  tester.view
    ..devicePixelRatio = 2
    ..physicalSize = const Size(780, 1688);
  addTearDown(tester.view.reset);
  final seen = Seen();
  late GoRouter router;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        localeProvider.overrideWith(() => LocaleNotifier(locale)),
        routerProvider.overrideWith((ref) {
          router = buildFixtureRouter(seen, initialLocation: initialLocation, ref: useSession ? ref : null, spec: spec);
          ref.onDispose(router.dispose);
          return router;
        }),
        ...overrides,
      ],
      child: GzAppRoot(kind: spec.app, onResume: onResume, warmUp: warmUp),
    ),
  );
  final container = ProviderScope.containerOf(tester.element(find.byType(GzAppRoot)));
  final rig = NavRig(tester, container, router, seen);
  await rig.settle();
  return rig;
}
