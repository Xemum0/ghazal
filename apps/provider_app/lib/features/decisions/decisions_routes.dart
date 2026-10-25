// Contract used by lib/app/app_router.dart: `decisionsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_dcsn_01.dart';
import 'presentation/hl_dcsn_02.dart';
import 'presentation/hl_dcsn_03.dart';
import 'presentation/hl_dcsn_04.dart';

/// Flow `decisions` (HL): 4 screens. Accept, decline and change
List<RouteBase> get decisionsRoutes => <RouteBase>[
  GoRoute(path: '/decisions/accept', name: 'HL-DCSN-01', builder: (BuildContext context, GoRouterState state) => const HlDcsn01Screen()),
  GoRoute(path: '/decisions/decline', name: 'HL-DCSN-02', builder: (BuildContext context, GoRouterState state) => const HlDcsn02Screen()),
  GoRoute(
    path: '/decisions/propose-date',
    name: 'HL-DCSN-03',
    builder: (BuildContext context, GoRouterState state) => const HlDcsn03Screen(),
  ),
  GoRoute(
    path: '/decisions/cancel-booking',
    name: 'HL-DCSN-04',
    builder: (BuildContext context, GoRouterState state) => const HlDcsn04Screen(),
  ),
];
