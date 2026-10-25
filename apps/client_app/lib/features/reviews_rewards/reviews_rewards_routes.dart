// Contract used by lib/app/app_router.dart: `reviewsRewardsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_rvrw_01.dart';
import 'presentation/cl_rvrw_02.dart';

/// Flow `reviews-rewards` (CL): 2 screens. Reviews and rewards
List<RouteBase> get reviewsRewardsRoutes => <RouteBase>[
  GoRoute(
    path: '/reviews-rewards/reviews-list',
    name: 'CL-RVRW-01',
    builder: (BuildContext context, GoRouterState state) => const ClRvrw01Screen(),
  ),
  GoRoute(
    path: '/reviews-rewards/write-review',
    name: 'CL-RVRW-02',
    builder: (BuildContext context, GoRouterState state) => const ClRvrw02Screen(),
  ),
];
