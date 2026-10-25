// Contract used by lib/app/app_router.dart: `venueRoutes` (non-tab screens).
// Flow `venue` (CL): 6 screens. Venue details
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_venu_01.dart';
import 'presentation/cl_venu_02.dart';
import 'presentation/cl_venu_03.dart';
import 'presentation/cl_venu_04.dart';
import 'presentation/cl_venu_05.dart';
import 'presentation/cl_venu_06.dart';

/// Flow `venue` (CL): 6 screens. Venue details
List<RouteBase> get venueRoutes => <RouteBase>[
  GoRoute(path: '/venue/venue-detail', name: 'CL-VENU-01', builder: (BuildContext context, GoRouterState state) => const ClVenu01Screen()),
  GoRoute(path: '/venue/gallery', name: 'CL-VENU-02', builder: (BuildContext context, GoRouterState state) => const ClVenu02Screen()),
  GoRoute(path: '/venue/availability-calendar', name: 'CL-VENU-03', builder: (BuildContext context, GoRouterState state) => const ClVenu03Screen()),
  GoRoute(path: '/venue/package-detail', name: 'CL-VENU-04', builder: (BuildContext context, GoRouterState state) => const ClVenu04Screen()),
  GoRoute(path: '/venue/policies', name: 'CL-VENU-05', builder: (BuildContext context, GoRouterState state) => const ClVenu05Screen()),
  GoRoute(path: '/venue/government-hall', name: 'CL-VENU-06', builder: (BuildContext context, GoRouterState state) => const ClVenu06Screen()),
];
