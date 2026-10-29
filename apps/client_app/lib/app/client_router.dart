// The router of the Client app (hand-written on purpose; `app_router.dart` is the generated composition without a guard).
//
// ADR 0038 D4: there is no guest mode. A signed-out client reaches only the first-run screens (CL-ONBD-01 Language, CL-ONBD-02
// Introduction, the CL-AUTH-* sign-in family) and nothing else: any other location redirects to the start of the first run (the Language
// screen, whose "Sign in" link and the introduction lead to the sign-in). The guard is `GzRouterSpec.requireSession` + `publicPrefixes`
// of the kit, whose redirect target (`startPath`) is also the one place a SIGNED-IN client is taken off (to Home). go_router re-parses
// the last declarative location whenever the session changes, so a real screen as `startPath` would replace the whole stack with Home the
// moment a code is verified (the stack under CL-AUTH-02 is dropped and a new account would skip "About you"). `startPath` is therefore
// the invisible route [kClientStartPath], which redirects to the Language screen and is never a location the person stays on. The
// generator (`tools/gen-routes.mjs`) emits it for the Partner app only (requests.md, [R2-CLIENT]), so this file composes the same routes
// with the client's guard. The flows are the generated ones: nothing here is a screen.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_routes.dart';
import '../features/booking/booking_routes.dart';
import '../features/bookings/bookings_routes.dart';
import '../features/discover/discover_routes.dart';
import '../features/messages/messages_routes.dart';
import '../features/my_wedding/my_wedding_routes.dart';
import '../features/onboarding/onboarding_routes.dart';
import '../features/payment/payment_routes.dart';
import '../features/planner/planner_routes.dart';
import '../features/profile/profile_routes.dart';
import '../features/reviews_rewards/reviews_rewards_routes.dart';
import '../features/saved_compare/saved_compare_routes.dart';
import '../features/services/services_routes.dart';
import '../features/venue/venue_routes.dart';
import '../features/visits/visits_routes.dart';
import '../features/vouchers/vouchers_routes.dart';
import 'app_router.dart' show kRouterSpec;
import 'app_tab_shell.dart';
import 'screen_registry.dart';

/// The invisible start of the first run: where the guard sends a signed-out client (the route redirects on to [kInitialLocation], the
/// Language screen) and the one location a signed-in client is taken off (to Home). Never shown, never a location that stays.
const String kClientStartPath = '/start';

/// The route behind [kClientStartPath]: it is only a redirect.
final GoRoute kClientStartRoute = GoRoute(path: kClientStartPath, name: 'CL-START', redirect: (BuildContext context, GoRouterState state) => kInitialLocation);

/// The screens a signed-out client may see: Language, Introduction and the whole sign-in family (sign-in, code, About you, password, biometric).
final List<String> kClientPublicPaths = <String>[kScreenRegistry['CL-ONBD-01']!.path, kScreenRegistry['CL-ONBD-02']!.path, '/auth'];

/// The navigation facts of the client app: the generated ones plus the sign-in guard.
final GzRouterSpec kClientRouterSpec = GzRouterSpec(
  app: kRouterSpec.app,
  tabs: kRouterSpec.tabs,
  chrome: kRouterSpec.chrome,
  paths: kRouterSpec.paths,
  startPath: kClientStartPath,
  homePath: kRouterSpec.homePath,
  requireSession: true,
  publicPrefixes: kClientPublicPaths,
);

/// The app router. [initialLocation] defaults to Home for a restored session and to the Language screen (the first run) otherwise. [ref]
/// connects the redirect and the refresh listenable to `sessionProvider` (the app root override passes it; a test may omit it).
GoRouter buildClientRouter({Ref? ref, String? initialLocation, Object? initialExtra, List<NavigatorObserver> observers = const <NavigatorObserver>[]}) {
  final signedIn = ref?.container.read(sessionProvider).isSignedIn ?? false;
  return buildGzRouter(
    spec: kClientRouterSpec,
    routes: <RouteBase>[
      kClientStartRoute,
      ...onboardingRoutes,
      ...authRoutes,
      ...discoverRoutes,
      ...venueRoutes,
      ...savedCompareRoutes,
      ...bookingRoutes,
      ...paymentRoutes,
      ...bookingsRoutes,
      ...myWeddingRoutes,
      ...plannerRoutes,
      ...servicesRoutes,
      ...messagesRoutes,
      ...reviewsRewardsRoutes,
      ...profileRoutes,
      ...vouchersRoutes,
      ...visitsRoutes,
    ],
    tabRoots: <String, GoRoute>{
      ...discoverTabRoots,
      ...savedCompareTabRoots,
      ...myWeddingTabRoots,
      ...messagesTabRoots,
      ...profileTabRoots,
    },
    tabShellBuilder: (BuildContext context, StatefulNavigationShell navigationShell) => AppTabShell(navigationShell: navigationShell),
    ref: ref,
    initialLocation: initialLocation ?? (signedIn ? kClientRouterSpec.homePath : kInitialLocation),
    initialExtra: initialExtra,
    observers: observers,
  );
}
