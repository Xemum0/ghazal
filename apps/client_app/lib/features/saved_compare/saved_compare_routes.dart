// Contract used by lib/app/app_router.dart: `savedCompareRoutes` (non-tab screens) and `savedCompareTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_savd_01.dart';
import 'presentation/cl_savd_02.dart';
import 'presentation/cl_savd_03.dart';
import 'presentation/cl_savd_04.dart';

/// Flow `saved-compare` (CL): 4 screens. Saved and compare. CL-SAVD-01 is the Saved tab root; 02 and 03 are sheets.
List<RouteBase> get savedCompareRoutes => <RouteBase>[
  GoRoute(path: '/saved-compare/compare-tray', name: 'CL-SAVD-02', builder: (BuildContext context, GoRouterState state) => const ClSavd02Screen()),
  GoRoute(path: '/saved-compare/replace-venue', name: 'CL-SAVD-03', builder: (BuildContext context, GoRouterState state) => const ClSavd03Screen()),
  GoRoute(path: '/saved-compare/compare-table', name: 'CL-SAVD-04', builder: (BuildContext context, GoRouterState state) => const ClSavd04Screen()),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get savedCompareTabRoots => <String, GoRoute>{
  'CL-SAVD-01': GoRoute(
    path: '/saved-compare/saved',
    name: 'CL-SAVD-01',
    builder: (BuildContext context, GoRouterState state) => const ClSavd01Screen(),
  ),
};
