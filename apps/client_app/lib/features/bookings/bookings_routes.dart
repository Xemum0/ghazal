// Contract used by lib/app/app_router.dart: `bookingsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_bkng_01.dart';
import 'presentation/cl_bkng_02.dart';
import 'presentation/cl_bkng_03.dart';
import 'presentation/cl_bkng_04.dart';
import 'presentation/cl_bkng_05.dart';

/// Flow `bookings` (CL): 5 screens. Bookings and statuses
List<RouteBase> get bookingsRoutes => <RouteBase>[
  GoRoute(path: '/bookings/bookings-list', name: 'CL-BKNG-01', builder: (BuildContext context, GoRouterState state) => const ClBkng01Screen()),
  GoRoute(path: '/bookings/booking-detail', name: 'CL-BKNG-02', builder: (BuildContext context, GoRouterState state) => const ClBkng02Screen()),
  GoRoute(path: '/bookings/cancel-booking', name: 'CL-BKNG-03', builder: (BuildContext context, GoRouterState state) => const ClBkng03Screen()),
  GoRoute(path: '/bookings/venue-proposed-date', name: 'CL-BKNG-04', builder: (BuildContext context, GoRouterState state) => const ClBkng04Screen()),
  GoRoute(path: '/bookings/payments', name: 'CL-BKNG-05', builder: (BuildContext context, GoRouterState state) => const ClBkng05Screen()),
];
