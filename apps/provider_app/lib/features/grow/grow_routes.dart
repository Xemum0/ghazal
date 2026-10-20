// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `growRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `grow` (HL): 5 screens. Offers, analytics and reviews
List<RouteBase> get growRoutes => <RouteBase>[
  GoRoute(
    path: '/grow/offers-list',
    name: 'HL-GROW-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-GROW-01',
      titleEn: 'Voucher prices',
      titleAr: 'أسعار الكوبون',
      kind: 'screen',
      purpose: 'All the venue\'s voucher-price settings by state (Active, Scheduled, Ended): the standing voucher prices of each package and any time-boxed windows (for example a lower voucher price for open weekend dates). Replaces Offers, flash sales and venue coupon codes, which no longer exist (ADR 0033 D4).',
    ),
  ),
  GoRoute(
    path: '/grow/create-offer',
    name: 'HL-GROW-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-GROW-02',
      titleEn: 'Voucher price window: what',
      titleAr: 'نافذة سعر الكوبون: التفاصيل',
      kind: 'screen',
      purpose: 'Step 1 of 2. Choose which packages and halls the window covers and the lower voucher price (a fixed KD amount per guest or per package, never higher than the standard price), with a live preview of the client card and the saving.',
    ),
  ),
  GoRoute(
    path: '/grow/offer-schedule',
    name: 'HL-GROW-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-GROW-03',
      titleEn: 'Voucher price window: when',
      titleAr: 'نافذة سعر الكوبون: المدة',
      kind: 'screen',
      purpose: 'Step 2 of 2. Set the event dates the window applies to and when it runs, then publish. Windows are dated (`valid_range` on the voucher price); there are no usage limits per code and no coupon codes.',
    ),
  ),
  GoRoute(
    path: '/grow/analytics',
    name: 'HL-GROW-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-GROW-04',
      titleEn: 'Analytics',
      titleAr: 'التحليلات',
      kind: 'screen',
      purpose: 'Answer \'is the listing working\' in one screen: views, clicks, requests, confirmed bookings, revenue, conversion and top packages for a chosen period, with the funnel and a table twin for every chart.',
    ),
  ),
  GoRoute(
    path: '/grow/reviews',
    name: 'HL-GROW-06',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-GROW-06',
      titleEn: 'Reviews',
      titleAr: 'التقييمات',
      kind: 'screen',
      purpose: 'Read what couples wrote, reply once in the venue\'s voice and report abuse (HA-NOTI-09, an IMPLIED line pending owner approval, OQ-P-18; full review management is web, VD-REV-02/03). The venue never approves, edits or hides a review; Ghazal moderates (CF-24). This is also the landing for the new-review notification.',
    ),
  ),
];
