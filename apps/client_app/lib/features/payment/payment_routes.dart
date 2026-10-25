// Contract used by lib/app/app_router.dart: `paymentRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_paym_01.dart';
import 'presentation/cl_paym_02.dart';
import 'presentation/cl_paym_03.dart';
import 'presentation/cl_paym_04.dart';
import 'presentation/cl_paym_05.dart';

/// Flow `payment` (CL): 5 screens. Payment
List<RouteBase> get paymentRoutes => <RouteBase>[
  GoRoute(path: '/payment/pay', name: 'CL-PAYM-01', builder: (BuildContext context, GoRouterState state) => const ClPaym01Screen()),
  GoRoute(path: '/payment/gateway', name: 'CL-PAYM-02', builder: (BuildContext context, GoRouterState state) => const ClPaym02Screen()),
  GoRoute(path: '/payment/confirming', name: 'CL-PAYM-03', builder: (BuildContext context, GoRouterState state) => const ClPaym03Screen()),
  GoRoute(path: '/payment/not-completed', name: 'CL-PAYM-04', builder: (BuildContext context, GoRouterState state) => const ClPaym04Screen()),
  GoRoute(path: '/payment/confirmed', name: 'CL-PAYM-05', builder: (BuildContext context, GoRouterState state) => const ClPaym05Screen()),
];
