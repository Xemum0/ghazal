// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `venueRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `venue` (CL): 6 screens. Venue details
List<RouteBase> get venueRoutes => <RouteBase>[
  GoRoute(
    path: '/venue/venue-detail',
    name: 'CL-VENU-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VENU-01',
      titleEn: 'Venue detail',
      titleAr: 'تفاصيل القاعة',
      kind: 'screen',
      purpose: 'The canonical screen for one venue (pushed, tab bar visible). One scroll with a sticky bar. Works fully for guests (they see both prices and that a voucher exists); the account is requested at Get voucher. Brief date and guests drive the date strip, package prices and availability. The three paths of the voucher model are all one tap away: Get voucher (voucher path), Book a visit (visit path) and…',
    ),
  ),
  GoRoute(
    path: '/venue/gallery',
    name: 'CL-VENU-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VENU-02',
      titleEn: 'Photos and videos',
      titleAr: 'الصور والفيديو',
      kind: 'screen',
      purpose: 'Full-screen photo tour with zone chips, pinch zoom and inline video playback. Empty rooms and details only; seating-layout plans are first-class photos for 300, 500 and 800 guests.',
    ),
  ),
  GoRoute(
    path: '/venue/availability-calendar',
    name: 'CL-VENU-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VENU-03',
      titleEn: 'Dates and prices',
      titleAr: 'التواريخ والأسعار',
      kind: 'sheet',
      purpose: 'Live availability calendar for one venue, with an Availability | Prices switch. Selecting a date updates the sticky CTA and can start booking. Also reused in booking step 1, Compare (\'See dates\') and the cancel flow\'s \'Change the date instead\'.',
    ),
  ),
  GoRoute(
    path: '/venue/package-detail',
    name: 'CL-VENU-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VENU-04',
      titleEn: 'Package',
      titleAr: 'الباقة',
      kind: 'sheet',
      purpose: 'Everything one package includes and what it costs for the Brief: inclusions, in-house menu summary, per-guest rate, guest limits and the date-dependent rate. Selecting continues into booking with the package carried over.',
    ),
  ),
  GoRoute(
    path: '/venue/policies',
    name: 'CL-VENU-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VENU-05',
      titleEn: 'Policies and hall rules',
      titleAr: 'السياسات وقواعد القاعة',
      kind: 'sheet',
      purpose: 'Plain-language terms with absolute dates where relevant, plus the per-section facts families actually ask about (photography, music, cloakroom, entrances). Three segments: Terms, Hall rules by section, Good to know. The earlier cancellation tier bar and cooling-off are retired (there is no event payment in the app).',
    ),
  ),
  GoRoute(
    path: '/venue/government-hall',
    name: 'CL-VENU-06',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VENU-06',
      titleEn: 'Government hall',
      titleAr: 'قاعة حكومية',
      kind: 'screen',
      purpose: 'Distinct detail variant for a Governmental Facility (venue type): an honest listing with the official fee schedule and rules, and a hand-off to the official channel. No voucher, no Ghazal request, no visit, no instant tag, no availability claim and no reviews (A-13).',
    ),
  ),
];
