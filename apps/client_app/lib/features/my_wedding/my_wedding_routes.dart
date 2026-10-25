// Contract used by lib/app/app_router.dart: `myWeddingRoutes` (non-tab screens) and `myWeddingTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_wedd_01.dart';
import 'presentation/cl_wedd_02.dart';
import 'presentation/cl_wedd_03.dart';
import 'presentation/cl_wedd_04.dart';
import 'presentation/cl_wedd_05.dart';

/// Flow `my-wedding` (CL): 5 screens. My Wedding and planning tools
List<RouteBase> get myWeddingRoutes => <RouteBase>[
  GoRoute(path: '/my-wedding/checklist', name: 'CL-WEDD-02', builder: (BuildContext context, GoRouterState state) => const ClWedd02Screen()),
  GoRoute(path: '/my-wedding/budget', name: 'CL-WEDD-03', builder: (BuildContext context, GoRouterState state) => const ClWedd03Screen()),
  GoRoute(path: '/my-wedding/add-expense', name: 'CL-WEDD-04', builder: (BuildContext context, GoRouterState state) => const ClWedd04Screen()),
  GoRoute(path: '/my-wedding/budget-setup', name: 'CL-WEDD-05', builder: (BuildContext context, GoRouterState state) => const ClWedd05Screen()),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get myWeddingTabRoots => <String, GoRoute>{
  'CL-WEDD-01': GoRoute(path: '/my-wedding/my-wedding', name: 'CL-WEDD-01', builder: (BuildContext context, GoRouterState state) => const ClWedd01Screen()),
};
