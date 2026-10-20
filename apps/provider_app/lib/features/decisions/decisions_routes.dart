// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `decisionsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `decisions` (HL): 4 screens. Accept, decline and change
List<RouteBase> get decisionsRoutes => <RouteBase>[
  GoRoute(
    path: '/decisions/accept',
    name: 'HL-DCSN-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-DCSN-01',
      titleEn: 'Accept request',
      titleAr: 'قبول الطلب',
      kind: 'sheet',
      purpose: 'Approve a pending request in two taps. The server applies the approval at once and creates the hold; an 8-second Undo window delays the client\'s push and WhatsApp. A compact confirm sheet appears only when approving has side effects the manager must see.',
    ),
  ),
  GoRoute(
    path: '/decisions/decline',
    name: 'HL-DCSN-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-DCSN-02',
      titleEn: 'Decline request',
      titleAr: 'الاعتذار عن الطلب',
      kind: 'sheet',
      purpose: 'Decline with a required reason in three taps. The reason is what lets the couple recover: the client sees a gentle category and three alternatives that are free on their date. The sheet hands off to \'Propose another date\' by default because suggesting a nearby date is the most natural Kuwaiti reply.',
    ),
  ),
  GoRoute(
    path: '/decisions/propose-date',
    name: 'HL-DCSN-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-DCSN-03',
      titleEn: 'Propose another date',
      titleAr: 'اقتراح موعد آخر',
      kind: 'sheet',
      purpose: 'Offer the couple one to three other dates for the same hall and session, instead of declining a request or when the venue itself needs to move a confirmed booking. One component serves both: a counter-offer on a Pending request (the client has 48 hours) and a venue-initiated reschedule of a confirmed booking (72 hours, Admin and Manager only).',
    ),
  ),
  GoRoute(
    path: '/decisions/cancel-booking',
    name: 'HL-DCSN-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-DCSN-04',
      titleEn: 'Cancel booking',
      titleAr: 'إلغاء الحجز',
      kind: 'sheet',
      purpose: 'Cancel a confirmed booking with the consequence shown first. Venue-caused cancellations refund the client in full and carry costs for the venue; cancelling for non-payment follows the client\'s policy. Admin and Manager only. A softer alternative, proposing another date, is offered before the destructive path.',
    ),
  ),
];
