// Contract used by lib/app/app_router.dart: `profileRoutes` (non-tab screens) and `profileTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_prof_01.dart';
import 'presentation/cl_prof_02.dart';
import 'presentation/cl_prof_03.dart';
import 'presentation/cl_prof_04.dart';
import 'presentation/cl_prof_05.dart';
import 'presentation/cl_prof_06.dart';

/// Flow `profile` (CL): 6 screens. Profile and settings. CL-PROF-01 is the Profile tab root.
List<RouteBase> get profileRoutes => <RouteBase>[
  GoRoute(path: '/profile/wedding-info', name: 'CL-PROF-02', builder: (BuildContext context, GoRouterState state) => const ClProf02Screen()),
  GoRoute(path: '/profile/personal-info', name: 'CL-PROF-03', builder: (BuildContext context, GoRouterState state) => const ClProf03Screen()),
  GoRoute(path: '/profile/notification-preferences', name: 'CL-PROF-04', builder: (BuildContext context, GoRouterState state) => const ClProf04Screen()),
  GoRoute(path: '/profile/settings', name: 'CL-PROF-05', builder: (BuildContext context, GoRouterState state) => const ClProf05Screen()),
  GoRoute(path: '/profile/delete-account', name: 'CL-PROF-06', builder: (BuildContext context, GoRouterState state) => const ClProf06Screen()),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get profileTabRoots => <String, GoRoute>{
  'CL-PROF-01': GoRoute(path: '/profile/profile', name: 'CL-PROF-01', builder: (BuildContext context, GoRouterState state) => const ClProf01Screen()),
};
