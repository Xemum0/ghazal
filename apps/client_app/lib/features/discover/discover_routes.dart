// Contract used by lib/app/app_router.dart: `discoverRoutes` (non-tab screens) and `discoverTabRoots` (tab roots by inventory id).
// Flow `discover` (CL): 7 screens. Discover: Home, Brief and results. CL-DISC-01 is the Discover tab root; 02, 04 and 06 are sheets.
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_disc_01.dart';
import 'presentation/cl_disc_02.dart';
import 'presentation/cl_disc_03.dart';
import 'presentation/cl_disc_04.dart';
import 'presentation/cl_disc_05.dart';
import 'presentation/cl_disc_06.dart';

List<RouteBase> get discoverRoutes => <RouteBase>[
  GoRoute(path: '/discover/brief-sheet', name: 'CL-DISC-02', builder: (BuildContext context, GoRouterState state) => const ClDisc02Screen()),
  GoRoute(path: '/discover/results', name: 'CL-DISC-03', builder: (BuildContext context, GoRouterState state) => const ClDisc03Screen()),
  GoRoute(path: '/discover/filters', name: 'CL-DISC-04', builder: (BuildContext context, GoRouterState state) => const ClDisc04Screen()),
  GoRoute(path: '/discover/results-map', name: 'CL-DISC-05', builder: (BuildContext context, GoRouterState state) => const ClDisc05Screen()),
  GoRoute(path: '/discover/date-filter', name: 'CL-DISC-06', builder: (BuildContext context, GoRouterState state) => const ClDisc06Screen()),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get discoverTabRoots => <String, GoRoute>{
  'CL-DISC-01': GoRoute(path: '/discover/home', name: 'CL-DISC-01', builder: (BuildContext context, GoRouterState state) => const ClDisc01Screen()),
};
