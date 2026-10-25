// Contract used by lib/app/app_router.dart: `visitsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_vist_01.dart';
import 'presentation/cl_vist_02.dart';
import 'presentation/cl_vist_03.dart';
import 'presentation/cl_vist_04.dart';
import 'presentation/cl_vist_05.dart';

/// Flow `visits` (CL): 5 screens. Visits
List<RouteBase> get visitsRoutes => <RouteBase>[
  GoRoute(
    path: '/visits/book-visit',
    name: 'CL-VIST-01',
    builder: (BuildContext context, GoRouterState state) => const ClVist01Screen(),
  ),
  GoRoute(
    path: '/visits/visit-requested',
    name: 'CL-VIST-02',
    builder: (BuildContext context, GoRouterState state) => const ClVist02Screen(),
  ),
  GoRoute(
    path: '/visits/visit-group-chat',
    name: 'CL-VIST-03',
    builder: (BuildContext context, GoRouterState state) => const ClVist03Screen(),
  ),
  GoRoute(
    path: '/visits/my-visits',
    name: 'CL-VIST-04',
    builder: (BuildContext context, GoRouterState state) => const ClVist04Screen(),
  ),
  GoRoute(
    path: '/visits/visit-change',
    name: 'CL-VIST-05',
    builder: (BuildContext context, GoRouterState state) => const ClVist05Screen(),
  ),
];
