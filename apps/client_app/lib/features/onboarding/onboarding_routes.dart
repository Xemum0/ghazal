// Contract used by lib/app/app_router.dart: `onboardingRoutes` (non-tab screens) and `onboardingTabRoots` (none: no onboarding screen is a tab root).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_onbd_01.dart';
import 'presentation/cl_onbd_02.dart';
import 'presentation/cl_onbd_03.dart';
import 'presentation/cl_onbd_04.dart';
import 'presentation/cl_onbd_05.dart';

/// Flow `onboarding` (CL): 5 screens. Welcome, then the optional wedding steps after the account is created (CL-ONBD-06 is retired, ADR 0038).
List<RouteBase> get onboardingRoutes => <RouteBase>[
  GoRoute(path: '/onboarding/language', name: 'CL-ONBD-01', builder: (BuildContext context, GoRouterState state) => const ClOnbd01Screen()),
  GoRoute(path: '/onboarding/intro', name: 'CL-ONBD-02', builder: (BuildContext context, GoRouterState state) => const ClOnbd02Screen()),
  GoRoute(path: '/onboarding/about-you', name: 'CL-ONBD-03', builder: (BuildContext context, GoRouterState state) => const ClOnbd03Screen()),
  GoRoute(path: '/onboarding/wedding-date', name: 'CL-ONBD-04', builder: (BuildContext context, GoRouterState state) => const ClOnbd04Screen()),
  GoRoute(path: '/onboarding/guests-budget', name: 'CL-ONBD-05', builder: (BuildContext context, GoRouterState state) => const ClOnbd05Screen()),
];
