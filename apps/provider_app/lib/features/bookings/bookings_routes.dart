// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `bookingsRoutes` (non-tab screens) and `bookingsTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `bookings` (HL): 6 screens. Bookings
List<RouteBase> get bookingsRoutes => <RouteBase>[
  GoRoute(
    path: '/bookings/upcoming-and-past',
    name: 'HL-BOOK-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-BOOK-02',
      titleEn: 'Upcoming and past',
      titleAr: 'القادمة والسابقة',
      kind: 'screen',
      purpose: 'Everything that is no longer waiting for a decision. Upcoming is sectioned Awaiting deposit (with the hold timer) then Confirmed; Past carries a chip row so all six PRD statuses are reachable in two taps. This screen also hosts search and the date filter for the whole tab.',
    ),
  ),
  GoRoute(
    path: '/bookings/booking-detail',
    name: 'HL-BOOK-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-BOOK-03',
      titleEn: 'Booking detail',
      titleAr: 'تفاصيل الحجز',
      kind: 'screen',
      purpose: 'The canonical request screen for the partner: who, when, what, the voucher price and what happens next, with one set of sections and a variant per status. The voucher panel (code last four, state, bound quote, redeemed by and when) replaces the money panel; there is no payment, cash, invoice or payout section. The sticky bar changes with the status and carries Redeem voucher once the request is c…',
    ),
  ),
  GoRoute(
    path: '/bookings/contact-sheet',
    name: 'HL-BOOK-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-BOOK-04',
      titleEn: 'Contact client',
      titleAr: 'التواصل مع العميل',
      kind: 'sheet',
      purpose: 'A small bottom sheet that turns \'reach this client\' into one tap: call the contact person, message in the app, or open WhatsApp. It respects the privacy rule that a number is shown only once the client shared it.',
    ),
  ),
  GoRoute(
    path: '/bookings/redeem-voucher',
    name: 'HL-BOOK-06',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-BOOK-06',
      titleEn: 'Redeem a voucher',
      titleAr: 'استخدام كوبون',
      kind: 'screen',
      purpose: 'Redeem a client voucher at the venue: scan the QR or type the code, see the bound quote and confirm. Checks that the code belongs to this partner, that the request is confirmed and that it was not used before, with specific calm errors. Reachable from Today (quick action), Bookings and the Booking detail sticky bar.',
    ),
  ),
  GoRoute(
    path: '/bookings/voucher-redeemed',
    name: 'HL-BOOK-07',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-BOOK-07',
      titleEn: 'Voucher redeemed',
      titleAr: 'تم استخدام الكوبون',
      kind: 'sheet',
      purpose: 'Confirmation after redemption: the request is now Redeemed, the voucher used, and the venue\'s next step is simply to honour the voucher price it showed. Shows who redeemed and when, and offers the booking.',
    ),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get bookingsTabRoots => <String, GoRoute>{
  'HL-BOOK-01':
    GoRoute(
      path: '/bookings/pending-requests',
      name: 'HL-BOOK-01',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'HL-BOOK-01',
        titleEn: 'Pending requests',
        titleAr: 'الطلبات المعلقة',
        kind: 'tab-root',
        purpose: 'Triage. Every request waiting for a reply as a decision-ready card, ordered by nearest deadline, with one gold Accept and two quiet alternatives. The staff member should be able to decide without opening the booking.',
      ),
    ),
};
