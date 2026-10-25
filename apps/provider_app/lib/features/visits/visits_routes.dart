// Contract used by lib/app/app_router.dart: `visitsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_vist_01.dart';
import 'presentation/hl_vist_02.dart';
import 'presentation/hl_vist_03.dart';
import 'presentation/hl_vist_04.dart';
import 'presentation/hl_vist_05.dart';

/// Flow `visits` (HL): 5 screens. Visit requests, the visit, its group chat, mark arrival (sheet) and the visit hours.
List<RouteBase> get visitsRoutes => <RouteBase>[
  GoRoute(path: '/visits/visit-requests', name: 'HL-VIST-01', builder: (BuildContext context, GoRouterState state) => const HlVist01Screen()),
  GoRoute(path: '/visits/visit-detail', name: 'HL-VIST-02', builder: (BuildContext context, GoRouterState state) => const HlVist02Screen()),
  GoRoute(path: '/visits/visit-group-chat', name: 'HL-VIST-03', builder: (BuildContext context, GoRouterState state) => const HlVist03Screen()),
  GoRoute(path: '/visits/arrival', name: 'HL-VIST-04', builder: (BuildContext context, GoRouterState state) => const HlVist04Screen()),
  GoRoute(path: '/visits/visit-availability', name: 'HL-VIST-05', builder: (BuildContext context, GoRouterState state) => const HlVist05Screen()),
];
