// Contract used by lib/app/app_router.dart: `growRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_grow_01.dart';
import 'presentation/hl_grow_02.dart';
import 'presentation/hl_grow_03.dart';
import 'presentation/hl_grow_04.dart';
import 'presentation/hl_grow_06.dart';

/// Flow `grow` (HL): 5 screens. Offers, analytics and reviews
List<RouteBase> get growRoutes => <RouteBase>[
  GoRoute(path: '/grow/offers-list', name: 'HL-GROW-01', builder: (BuildContext context, GoRouterState state) => const HlGrow01Screen()),
  GoRoute(path: '/grow/create-offer', name: 'HL-GROW-02', builder: (BuildContext context, GoRouterState state) => const HlGrow02Screen()),
  GoRoute(path: '/grow/offer-schedule', name: 'HL-GROW-03', builder: (BuildContext context, GoRouterState state) => const HlGrow03Screen()),
  GoRoute(path: '/grow/analytics', name: 'HL-GROW-04', builder: (BuildContext context, GoRouterState state) => const HlGrow04Screen()),
  GoRoute(path: '/grow/reviews', name: 'HL-GROW-06', builder: (BuildContext context, GoRouterState state) => const HlGrow06Screen()),
];
