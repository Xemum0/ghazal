// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `bookingsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `bookings` (CL): 5 screens. Bookings and statuses
List<RouteBase> get bookingsRoutes => <RouteBase>[
  GoRoute(
    path: '/bookings/bookings-list',
    name: 'CL-BKNG-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BKNG-01',
      titleEn: 'Bookings',
      titleAr: 'الحجوزات',
      kind: 'screen',
      purpose: 'All of the user\'s bookings grouped by what needs attention, with venue, date, amount and a status chip (icon plus label). Pushed from the My Wedding Bookings card and the Profile row. The six PRD statuses are reachable in two taps.',
    ),
  ),
  GoRoute(
    path: '/bookings/booking-detail',
    name: 'CL-BKNG-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BKNG-02',
      titleEn: 'Booking detail',
      titleAr: 'تفاصيل الحجز',
      kind: 'screen',
      purpose: 'The canonical request/booking screen, one layout with status variants. The Booking Thread (Request, Approval, Confirmation, Redemption, Day) leads; below it the status block, the voucher card, event and sections, package and extras, price in two columns, venue terms and venue contact. The primary changes with the status: Confirm booking (approved), Show voucher (confirmed). There is no payment, b…',
    ),
  ),
  GoRoute(
    path: '/bookings/cancel-booking',
    name: 'CL-BKNG-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BKNG-03',
      titleEn: 'Cancel request',
      titleAr: 'إلغاء الطلب',
      kind: 'sheet',
      purpose: 'A short sheet flow that shows the voucher consequence first: withdrawing a pending request or declining the approval returns the voucher for reuse at the same venue; cancelling a confirmed booking uses the voucher up. Then a reason and an explicit confirm. There is no refund amount, no IBAN and no arrival estimate because no event money moved through Ghazal (ADR 0033).',
    ),
  ),
  GoRoute(
    path: '/bookings/venue-proposed-date',
    name: 'CL-BKNG-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BKNG-04',
      titleEn: 'Venue proposed another date',
      titleAr: 'اقتراح موعد آخر من المكان',
      kind: 'sheet',
      purpose: 'The client counterpart of the hotel\'s \'Propose another date\': one card type for counter-offers (on a request) and reschedules (on a confirmed booking). The couple picks one of 1 to 3 dates or declines, with the price and consequences stated up front.',
    ),
  ),
  GoRoute(
    path: '/bookings/payments',
    name: 'CL-BKNG-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BKNG-05',
      titleEn: 'Receipts',
      titleAr: 'الإيصالات',
      kind: 'screen',
      purpose: 'Every Ghazal receipt: the KD 2 voucher payments (no credit notes; credit vouchers appear in the wallet), with a bilingual PDF viewer. There are no scheduled payments, no balances and no event invoices. Opened from Profile > Receipts, My vouchers and the voucher-ready screen.',
    ),
  ),
];
