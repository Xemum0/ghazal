// Contract used by lib/app/app_router.dart: `servicesRoutes` (non-tab screens).
// Flow `services` (CL): 4 screens. Wedding services
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_serv_01.dart';
import 'presentation/cl_serv_02.dart';
import 'presentation/cl_serv_03.dart';
import 'presentation/cl_serv_04.dart';

/// Flow `services` (CL): 4 screens. Wedding services
List<RouteBase> get servicesRoutes => <RouteBase>[
  GoRoute(path: '/services/services-hub', name: 'CL-SERV-01', builder: (BuildContext context, GoRouterState state) => const ClServ01Screen()),
  GoRoute(path: '/services/category-list', name: 'CL-SERV-02', builder: (BuildContext context, GoRouterState state) => const ClServ02Screen()),
  GoRoute(path: '/services/vendor-profile', name: 'CL-SERV-03', builder: (BuildContext context, GoRouterState state) => const ClServ03Screen()),
  GoRoute(path: '/services/request-quote', name: 'CL-SERV-04', builder: (BuildContext context, GoRouterState state) => const ClServ04Screen()),
];
