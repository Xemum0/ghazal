// Contract used by lib/app/app_router.dart: `plannerRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_plan_01.dart';
import 'presentation/cl_plan_02.dart';
import 'presentation/cl_plan_03.dart';
import 'presentation/cl_plan_04.dart';

/// Flow `planner` (CL): 4 screens. Wedding planner
List<RouteBase> get plannerRoutes => <RouteBase>[
  GoRoute(path: '/planner/planner-packages', name: 'CL-PLAN-01', builder: (BuildContext context, GoRouterState state) => const ClPlan01Screen()),
  GoRoute(path: '/planner/request-consultation', name: 'CL-PLAN-02', builder: (BuildContext context, GoRouterState state) => const ClPlan02Screen()),
  GoRoute(path: '/planner/planner-status', name: 'CL-PLAN-03', builder: (BuildContext context, GoRouterState state) => const ClPlan03Screen()),
  GoRoute(path: '/planner/schedule-meeting', name: 'CL-PLAN-04', builder: (BuildContext context, GoRouterState state) => const ClPlan04Screen()),
];
