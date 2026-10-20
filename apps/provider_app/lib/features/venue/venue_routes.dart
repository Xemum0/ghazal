// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `venueRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `venue` (HL): 6 screens. My venue
List<RouteBase> get venueRoutes => <RouteBase>[
  GoRoute(
    path: '/venue/media-manager',
    name: 'HL-VENU-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VENU-01',
      titleEn: 'Photos and videos',
      titleAr: 'الصور والفيديو',
      kind: 'screen',
      purpose: 'Upload, reorder, set the cover for and delete the listing\'s photos and videos, with the cultural rule built into the upload itself: empty rooms and details only, tagged by zone. Large video uploads continue in the background.',
    ),
  ),
  GoRoute(
    path: '/venue/packages',
    name: 'HL-VENU-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VENU-02',
      titleEn: 'Packages and extras',
      titleAr: 'الباقات والإضافات',
      kind: 'screen',
      purpose: 'The list of what the venue sells: packages with their prices per guest and limits, and the extras couples can add. Active toggles and archiving are one tap; editing opens the package editor.',
    ),
  ),
  GoRoute(
    path: '/venue/package-editor',
    name: 'HL-VENU-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VENU-03',
      titleEn: 'Edit package',
      titleAr: 'تعديل الباقة',
      kind: 'screen',
      purpose: 'Create or edit one package: bilingual name and inclusions, the weekday and weekend per-guest price, minimum and maximum guests, halls and active state, with a live preview of what couples will see. Everything the app does not edit is stated as read-only.',
    ),
  ),
  GoRoute(
    path: '/venue/halls-amenities',
    name: 'HL-VENU-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VENU-04',
      titleEn: 'Halls, capacity and amenities',
      titleAr: 'القاعات والسعة والمرافق',
      kind: 'screen',
      purpose: 'Define each bookable hall (capacity bounds, allowed audiences, setting, session) and state its facilities and per-section facts as plain Included / Extra / Not offered rows, so couples and families find the answers they actually ask for. A single-hall venue skips the hall list and lands directly in the editor.',
    ),
  ),
  GoRoute(
    path: '/venue/policies',
    name: 'HL-VENU-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VENU-05',
      titleEn: 'Policies',
      titleAr: 'السياسات',
      kind: 'screen',
      purpose: 'The venue\'s own terms in plain words, shown to couples as written, plus the children policy, dress code and house rules. Ghazal does not collect or refund event money, so there are no cancellation tiers, no cooling-off and no refund settings: the venue states its payment and cancellation terms itself and settles them directly with the client.',
    ),
  ),
  GoRoute(
    path: '/venue/booking-rules',
    name: 'HL-VENU-06',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VENU-06',
      titleEn: 'Booking rules',
      titleAr: 'قواعد الحجز',
      kind: 'screen',
      purpose: 'Set how requests work for each hall: the reply window, the minimum notice, and the link to visit availability and voucher prices. There is no instant booking, no deposit, no pay window, no balance, no cash and no payout verification (ADR 0033).',
    ),
  ),
];
