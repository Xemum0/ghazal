// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `discoverRoutes` (non-tab screens) and `discoverTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `discover` (CL): 7 screens. Discover: Home, Brief and results
List<RouteBase> get discoverRoutes => <RouteBase>[
  GoRoute(
    path: '/discover/brief-sheet',
    name: 'CL-DISC-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-DISC-02',
      titleEn: 'Your Brief',
      titleAr: 'تفاصيل زفافكم',
      kind: 'sheet',
      purpose: 'The single editor of the global Brief, opened from the Home hero card, the Results pill, Compare (\'Set your date\') and Saved. Changing a row updates price and availability on visible cards in place. Also hosts the one-time merge variant shown when a signed-in account already holds a different Brief.',
    ),
  ),
  GoRoute(
    path: '/discover/results',
    name: 'CL-DISC-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-DISC-03',
      titleEn: 'Results',
      titleAr: 'نتائج البحث',
      kind: 'screen',
      purpose: 'The venue list for the Brief plus filters and sort, with the canonical venue card (ADR 0018) now showing two prices: the voucher price as the headline and the standard price beneath, with a saving chip when the saving beats the KD 2 voucher. Shows only venues matching the selected region and preferences, with a result count and removable chips. Deals with the three price grammars, availability li…',
    ),
  ),
  GoRoute(
    path: '/discover/filters',
    name: 'CL-DISC-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-DISC-04',
      titleEn: 'Filters',
      titleAr: 'التصفية',
      kind: 'sheet',
      purpose: 'One 90% sheet with every PRD filter grouped by what couples decide first, a live result count within 200 ms of each change, and a sticky footer. Sort is a separate small sheet so it never mixes with filtering.',
    ),
  ),
  GoRoute(
    path: '/discover/results-map',
    name: 'CL-DISC-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-DISC-05',
      titleEn: 'Map',
      titleAr: 'الخريطة',
      kind: 'screen',
      purpose: 'Full-screen map alternative to the list: price-label pins for the Brief date and a card carousel. The only place a live interactive map is used in browse (never inside lists).',
    ),
  ),
  GoRoute(
    path: '/discover/date-filter',
    name: 'CL-DISC-06',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-DISC-06',
      titleEn: 'Dates for your search',
      titleAr: 'تواريخ البحث',
      kind: 'sheet',
      purpose: 'A filterable availability calendar for search (not tied to one venue): pick a date or a short range and Results shows only venues with an available hall on it. It is the filter-capable sibling of the venue calendar (CL-VENU-03) and writes the Brief date.',
    ),
  ),
  GoRoute(
    path: '/discover/region-search',
    name: 'CL-DISC-07',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-DISC-07',
      titleEn: 'Search by region',
      titleAr: 'البحث حسب المنطقة',
      kind: 'screen',
      purpose: 'Region, governorate and location search: a typeahead over governorates, areas and venue names (Arabic-normalised) above a governorate-grouped area list with venue counts. Selecting writes the Brief area and the Results filter.',
    ),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get discoverTabRoots => <String, GoRoute>{
  'CL-DISC-01':
    GoRoute(
      path: '/discover/home',
      name: 'CL-DISC-01',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'CL-DISC-01',
        titleEn: 'Home',
        titleAr: 'الرئيسية',
        kind: 'tab-root',
        purpose: 'Root of the Discover tab and the default launch tab until a booking needs attention. A hero \'brief card\' (editable summary of the Brief), one urgency-ranked status card, six category tiles, then Brief-aware shelves. Shelves load independently to meet the 2-second budget.',
      ),
    ),
};
