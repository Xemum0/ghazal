// Contract used by lib/app/app_router.dart: `todayRoutes` (non-tab screens) and `todayTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_tody_01.dart';
import 'presentation/hl_tody_02.dart';
import 'presentation/hl_tody_03.dart';
import 'presentation/hl_tody_04.dart';
import 'presentation/hl_tody_05.dart';

/// Flow `today` (HL): 5 screens. Today, alerts and messages
List<RouteBase> get todayRoutes => <RouteBase>[
  GoRoute(path: '/today/needs-you', name: 'HL-TODY-02', builder: (BuildContext context, GoRouterState state) => const HlTody02Screen()),
  GoRoute(path: '/today/notifications', name: 'HL-TODY-03', builder: (BuildContext context, GoRouterState state) => const HlTody03Screen()),
  GoRoute(path: '/today/thread', name: 'HL-TODY-05', builder: (BuildContext context, GoRouterState state) => const HlTody05Screen()),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get todayTabRoots => <String, GoRoute>{
  'HL-TODY-01': GoRoute(path: '/today/today', name: 'HL-TODY-01', builder: (BuildContext context, GoRouterState state) => const HlTody01Screen()),
  'HL-TODY-04': GoRoute(path: '/today/inbox', name: 'HL-TODY-04', builder: (BuildContext context, GoRouterState state) => const HlTody04Screen()),
};
