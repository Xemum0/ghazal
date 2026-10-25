// Contract used by lib/app/app_router.dart: `vouchersRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_vchr_01.dart';
import 'presentation/cl_vchr_02.dart';
import 'presentation/cl_vchr_03.dart';
import 'presentation/cl_vchr_04.dart';
import 'presentation/cl_vchr_05.dart';

/// Flow `vouchers` (CL): 5 screens. Vouchers
List<RouteBase> get vouchersRoutes => <RouteBase>[
  GoRoute(path: '/vouchers/voucher-explainer', name: 'CL-VCHR-01', builder: (BuildContext context, GoRouterState state) => const ClVchr01Screen()),
  GoRoute(path: '/vouchers/my-vouchers', name: 'CL-VCHR-02', builder: (BuildContext context, GoRouterState state) => const ClVchr02Screen()),
  GoRoute(path: '/vouchers/voucher-detail', name: 'CL-VCHR-03', builder: (BuildContext context, GoRouterState state) => const ClVchr03Screen()),
  GoRoute(path: '/vouchers/voucher-for-request', name: 'CL-VCHR-04', builder: (BuildContext context, GoRouterState state) => const ClVchr04Screen()),
  GoRoute(path: '/vouchers/voucher-refund-reuse', name: 'CL-VCHR-05', builder: (BuildContext context, GoRouterState state) => const ClVchr05Screen()),
];
