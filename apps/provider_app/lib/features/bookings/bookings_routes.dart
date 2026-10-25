// Contract used by lib/app/app_router.dart: `bookingsRoutes` (non-tab screens) and `bookingsTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_book_01.dart';
import 'presentation/hl_book_02.dart';
import 'presentation/hl_book_03.dart';
import 'presentation/hl_book_04.dart';
import 'presentation/hl_book_06.dart';
import 'presentation/hl_book_07.dart';

/// Flow `bookings` (HL): 6 screens. Bookings
List<RouteBase> get bookingsRoutes => <RouteBase>[
  GoRoute(
    path: '/bookings/upcoming-and-past',
    name: 'HL-BOOK-02',
    builder: (BuildContext context, GoRouterState state) => const HlBook02Screen(),
  ),
  GoRoute(
    path: '/bookings/booking-detail',
    name: 'HL-BOOK-03',
    builder: (BuildContext context, GoRouterState state) => const HlBook03Screen(),
  ),
  GoRoute(
    path: '/bookings/contact-sheet',
    name: 'HL-BOOK-04',
    builder: (BuildContext context, GoRouterState state) => const HlBook04Screen(),
  ),
  GoRoute(
    path: '/bookings/redeem-voucher',
    name: 'HL-BOOK-06',
    builder: (BuildContext context, GoRouterState state) => const HlBook06Screen(),
  ),
  GoRoute(
    path: '/bookings/voucher-redeemed',
    name: 'HL-BOOK-07',
    builder: (BuildContext context, GoRouterState state) => const HlBook07Screen(),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get bookingsTabRoots => <String, GoRoute>{
  'HL-BOOK-01':
    GoRoute(
      path: '/bookings/pending-requests',
      name: 'HL-BOOK-01',
      builder: (BuildContext context, GoRouterState state) => const HlBook01Screen(),
    ),
};
