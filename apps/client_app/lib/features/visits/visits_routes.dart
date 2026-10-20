// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `visitsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `visits` (CL): 5 screens. Visits
List<RouteBase> get visitsRoutes => <RouteBase>[
  GoRoute(
    path: '/visits/book-visit',
    name: 'CL-VIST-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VIST-01',
      titleEn: 'Book a visit',
      titleAr: 'احجزوا زيارة',
      kind: 'sheet',
      purpose: 'Choose a visit slot at a hotel or hall: date, arrival window, number of visitors and an optional note. Opened from the venue detail, the booking-confirmed screen and Booking detail. No voucher is needed. Guests are gated at Send.',
    ),
  ),
  GoRoute(
    path: '/visits/visit-requested',
    name: 'CL-VIST-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VIST-02',
      titleEn: 'Visit requested',
      titleAr: 'تم طلب الزيارة',
      kind: 'screen',
      purpose: 'Confirmation of the visit request that redirects into the group chat: what was requested, who is in the chat and what happens next. The redirect is the owner\'s rule: the client confirms the appointment arrival inside the chat.',
    ),
  ),
  GoRoute(
    path: '/visits/visit-group-chat',
    name: 'CL-VIST-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VIST-03',
      titleEn: 'Visit chat',
      titleAr: 'محادثة الزيارة',
      kind: 'screen',
      purpose: 'The dedicated three-way group chat of one visit: the client, a hotel representative and a Ghazal support representative. A pinned card carries the slot, status and the arrival actions; messages show the sender\'s role chip. It uses the shared chat component with real-time delivery, photos, documents and optional voice. Closes read-only 24 hours after the slot.',
    ),
  ),
  GoRoute(
    path: '/visits/my-visits',
    name: 'CL-VIST-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VIST-04',
      titleEn: 'My visits',
      titleAr: 'زياراتي',
      kind: 'screen',
      purpose: 'The list of the client\'s visits by state (Upcoming, Past) with status chips and a way into each chat. Reached from Profile and My Wedding.',
    ),
  ),
  GoRoute(
    path: '/visits/visit-change',
    name: 'CL-VIST-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VIST-05',
      titleEn: 'Change or cancel visit',
      titleAr: 'تغيير الزيارة أو إلغاؤها',
      kind: 'sheet',
      purpose: 'Ask the hotel for another time or cancel a visit, with the consequence stated: nothing is charged and nothing is lost, and the chat records the change.',
    ),
  ),
];
