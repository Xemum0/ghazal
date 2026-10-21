// Contract used by lib/app/app_router.dart: `accessRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_accs_01.dart';
import 'presentation/hl_accs_02.dart';
import 'presentation/hl_accs_03.dart';
import 'presentation/hl_accs_04.dart';

/// Flow `access` (HL): 4 screens. Access and account status
List<RouteBase> get accessRoutes => <RouteBase>[
  GoRoute(path: '/access/sign-in', name: 'HL-ACCS-01', builder: (BuildContext context, GoRouterState state) => const HlAccs01Screen()),
  GoRoute(path: '/access/verify-code', name: 'HL-ACCS-02', builder: (BuildContext context, GoRouterState state) => const HlAccs02Screen()),
  GoRoute(path: '/access/set-password', name: 'HL-ACCS-03', builder: (BuildContext context, GoRouterState state) => const HlAccs03Screen()),
  GoRoute(path: '/access/account-status', name: 'HL-ACCS-04', builder: (BuildContext context, GoRouterState state) => const HlAccs04Screen()),
];
