// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `savedCompareRoutes` (non-tab screens) and `savedCompareTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `saved-compare` (CL): 4 screens. Saved and compare
List<RouteBase> get savedCompareRoutes => <RouteBase>[
  GoRoute(
    path: '/saved-compare/compare-tray',
    name: 'CL-SAVD-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-SAVD-02',
      titleEn: 'Compare tray',
      titleAr: 'شريط المقارنة',
      kind: 'sheet',
      purpose: 'The anti-nag Compare tray: one component with five states that appears only after the first add and only on Home, Results and Saved. On Venue detail it becomes a header badge so it never covers the sticky price bar.',
    ),
  ),
  GoRoute(
    path: '/saved-compare/replace-venue',
    name: 'CL-SAVD-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-SAVD-03',
      titleEn: 'Replace which one?',
      titleAr: 'أي قاعة تستبدلون؟',
      kind: 'sheet',
      purpose: 'Shown on the fourth add: Compare holds three venues, so nothing is dropped silently and the user chooses which one to replace.',
    ),
  ),
  GoRoute(
    path: '/saved-compare/compare-table',
    name: 'CL-SAVD-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-SAVD-04',
      titleEn: 'Compare',
      titleAr: 'المقارنة',
      kind: 'screen',
      purpose: 'The three-venue comparison on a 390px screen: full-bleed fluid thirds, label above values, differences only by default, best-in-row markers on objective rows, and a footer of three channel-aware actions aligned to the columns. Booking can start from here with date and guests carried over.',
    ),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get savedCompareTabRoots => <String, GoRoute>{
  'CL-SAVD-01':
    GoRoute(
      path: '/saved-compare/saved',
      name: 'CL-SAVD-01',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'CL-SAVD-01',
        titleEn: 'Saved',
        titleAr: 'المفضلة',
        kind: 'tab-root',
        purpose: 'Wishlist tab with three segments (Venues, Services, Packages), live availability and price-drop badges against the Brief date, multi-select into Compare, and honest local-only behaviour for guests.',
      ),
    ),
};
