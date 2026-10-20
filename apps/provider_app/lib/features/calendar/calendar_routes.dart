// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `calendarRoutes` (non-tab screens) and `calendarTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `calendar` (HL): 5 screens. Calendar and availability
List<RouteBase> get calendarRoutes => <RouteBase>[
  GoRoute(
    path: '/calendar/week',
    name: 'HL-CALN-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-CALN-02',
      titleEn: 'Week view',
      titleAr: 'العرض الأسبوعي',
      kind: 'screen',
      purpose: 'Seven day rows for planning the week: for each day what each hall is doing, so the manager sees gaps and clashes faster than in the month grid.',
    ),
  ),
  GoRoute(
    path: '/calendar/day',
    name: 'HL-CALN-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-CALN-03',
      titleEn: 'Day view',
      titleAr: 'العرض اليومي',
      kind: 'screen',
      purpose: 'One date in operational detail: for every hall, the prep, event and teardown timeline, the booking card with its money state, and what can be done with the date. This is where \'tap a date opens its day agenda and the related booking\' lands.',
    ),
  ),
  GoRoute(
    path: '/calendar/block-dates',
    name: 'HL-CALN-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-CALN-04',
      titleEn: 'Block or open dates',
      titleAr: 'إغلاق التواريخ أو فتحها',
      kind: 'sheet',
      purpose: 'Take dates off sale (offline sales, maintenance, private events) or put them back on sale, for one date or a range, scoped by hall. It states exactly what couples will see and warns about pending requests before anything changes.',
    ),
  ),
  GoRoute(
    path: '/calendar/calendar-by-email',
    name: 'HL-CALN-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-CALN-05',
      titleEn: 'Calendar by email',
      titleAr: 'التقويم عبر البريد',
      kind: 'sheet',
      purpose: 'Keep an outside calendar (Google, Outlook, Apple) in step by email: the venue gets an .ics invitation by email for each confirmed booking and each block, and may add one more address. There is no WhatsApp channel for this (ADR 0035 D8).',
    ),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get calendarTabRoots => <String, GoRoute>{
  'HL-CALN-01':
    GoRoute(
      path: '/calendar/month',
      name: 'HL-CALN-01',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'HL-CALN-01',
        titleEn: 'Month calendar',
        titleAr: 'التقويم الشهري',
        kind: 'tab-root',
        purpose: 'The month at a glance with the selected day\'s agenda beneath it. Entry point for blocking, reopening, range select and soft-date mode (the unsold weekend dates worth an offer).',
      ),
    ),
};
