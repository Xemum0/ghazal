// Contract used by lib/app/app_router.dart: `bookingRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_book_01.dart';
import 'presentation/cl_book_02.dart';
import 'presentation/cl_book_04.dart';
import 'presentation/cl_book_05.dart';
import 'presentation/cl_book_06.dart';
import 'presentation/cl_book_07.dart';
import 'presentation/cl_book_08.dart';
import 'presentation/cl_book_09.dart';
import 'presentation/cl_book_10.dart';

/// Flow `booking` (CL): 10 screens. Booking request
List<RouteBase> get bookingRoutes => <RouteBase>[
  GoRoute(path: '/booking/your-event', name: 'CL-BOOK-01', builder: (BuildContext context, GoRouterState state) => const ClBook01Screen()),
  GoRoute(path: '/booking/package', name: 'CL-BOOK-02', builder: (BuildContext context, GoRouterState state) => const ClBook02Screen()),
  GoRoute(path: '/booking/your-details', name: 'CL-BOOK-04', builder: (BuildContext context, GoRouterState state) => const ClBook04Screen()),
  GoRoute(path: '/booking/review', name: 'CL-BOOK-05', builder: (BuildContext context, GoRouterState state) => const ClBook05Screen()),
  GoRoute(path: '/booking/request-sent', name: 'CL-BOOK-06', builder: (BuildContext context, GoRouterState state) => const ClBook06Screen()),
  GoRoute(path: '/booking/date-taken', name: 'CL-BOOK-07', builder: (BuildContext context, GoRouterState state) => const ClBook07Screen()),
  GoRoute(path: '/booking/confirm-booking', name: 'CL-BOOK-08', builder: (BuildContext context, GoRouterState state) => const ClBook08Screen()),
  GoRoute(path: '/booking/booking-confirmed', name: 'CL-BOOK-09', builder: (BuildContext context, GoRouterState state) => const ClBook09Screen()),
  GoRoute(path: '/booking/confirm-window-ended', name: 'CL-BOOK-10', builder: (BuildContext context, GoRouterState state) => const ClBook10Screen()),
];
