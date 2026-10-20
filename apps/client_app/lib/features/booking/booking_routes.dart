// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `bookingRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `booking` (CL): 10 screens. Booking request
List<RouteBase> get bookingRoutes => <RouteBase>[
  GoRoute(
    path: '/booking/your-event',
    name: 'CL-BOOK-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-01',
      titleEn: 'Your event',
      titleAr: 'مناسبتكم',
      kind: 'screen',
      purpose: 'Step 1 of 5. Confirm date, what is being hosted, guests and (only if there is a real choice) hall and session. Guests move here because price and capacity validity depend on them. Starts from a card, Venue detail, a calendar date or the Compare table.',
    ),
  ),
  GoRoute(
    path: '/booking/package',
    name: 'CL-BOOK-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-02',
      titleEn: 'Package',
      titleAr: 'الباقة',
      kind: 'screen',
      purpose: 'Step 2 of 5. Choose exactly one package priced for the date and guests; in a two-section booking a Ladies | Men tab pair appears so each section gets its own package.',
    ),
  ),
  GoRoute(
    path: '/booking/extras',
    name: 'CL-BOOK-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-03',
      titleEn: 'Extras',
      titleAr: 'الإضافات',
      kind: 'screen',
      purpose: 'Step 3 of 5. Optional add-ons priced separately, with a running total. Also the second entry point for adding a men\'s reception. For a guest, Continue triggers the account sheet before any personal data is asked.',
    ),
  ),
  GoRoute(
    path: '/booking/your-details',
    name: 'CL-BOOK-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-04',
      titleEn: 'Your details',
      titleAr: 'بياناتكم',
      kind: 'screen',
      purpose: 'Step 4 of 5. Contact person, who the booking is for, special requests, and inline phone verification. A verified phone is required to send a request; users who signed in with Apple, Google or email verify here by WhatsApp without leaving the step.',
    ),
  ),
  GoRoute(
    path: '/booking/review',
    name: 'CL-BOOK-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-05',
      titleEn: 'Review',
      titleAr: 'المراجعة',
      kind: 'screen',
      purpose: 'Step 5 of 5. The last screen before commitment: the itemised price in both columns, the saving, the attached voucher (code last four, state) and consent. The primary reads "Send request at the voucher price". There is no deposit, no payment schedule, no coupon or points field and no instant mode. The summary states the model plainly: "Nothing more to pay Ghazal. After you confirm, you pay the ven…',
    ),
  ),
  GoRoute(
    path: '/booking/request-sent',
    name: 'CL-BOOK-06',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-06',
      titleEn: 'Request sent',
      titleAr: 'تم إرسال الطلب',
      kind: 'screen',
      purpose: 'Outcome of request mode and the most important screen nobody screenshots: it keeps the valley between request and reply calm. It shows the Booking Thread, an absolute expected-reply time, what is and is not happening to money and the date, and one-time offers.',
    ),
  ),
  GoRoute(
    path: '/booking/date-taken',
    name: 'CL-BOOK-07',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-07',
      titleEn: 'That date is no longer available',
      titleAr: 'لم يعد هذا التاريخ متاحًا',
      kind: 'sheet',
      purpose: 'Recovery sheet for the moment a date or session is taken during checkout. Told before payment, never a dead end: nearest free dates for the same hall, the same date at similar halls, or a new date.',
    ),
  ),
  GoRoute(
    path: '/booking/confirm-booking',
    name: 'CL-BOOK-08',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-08',
      titleEn: 'Confirm your booking',
      titleAr: 'تأكيد الحجز',
      kind: 'screen',
      purpose: 'The official confirmation the owner requires within 24 hours of approval. Shows what the venue approved (date, hall, package, voucher price), the absolute deadline and, in the last hour, a live countdown, then one primary "Confirm booking". After confirming, the hold becomes a booking and the voucher code and QR are shown. If the window lapses the screen turns into the lapsed state (CL-BOOK-10).',
    ),
  ),
  GoRoute(
    path: '/booking/booking-confirmed',
    name: 'CL-BOOK-09',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-09',
      titleEn: 'Booking confirmed',
      titleAr: 'تم تأكيد الحجز',
      kind: 'screen',
      purpose: 'The one celebratory moment of the booking flow: the booking is confirmed, the date is booked at the voucher price, and the voucher code and QR are ready for the venue. Explains the next step plainly: pay the venue directly and show the code. Surfaces calendar, directions, visit and planner offers.',
    ),
  ),
  GoRoute(
    path: '/booking/confirm-window-ended',
    name: 'CL-BOOK-10',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-BOOK-10',
      titleEn: 'Confirmation window ended',
      titleAr: 'انتهت مهلة التأكيد',
      kind: 'screen',
      purpose: 'The calm outcome when the 24 hour confirm window lapses (or the venue revoked the approval): what lapsed, what happened to the date and what happens to the voucher, with a clear way forward. Never blaming, never a dead end.',
    ),
  ),
];
