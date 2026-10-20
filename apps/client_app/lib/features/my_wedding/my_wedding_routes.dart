// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `myWeddingRoutes` (non-tab screens) and `myWeddingTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `my-wedding` (CL): 5 screens. My Wedding and planning tools
List<RouteBase> get myWeddingRoutes => <RouteBase>[
  GoRoute(
    path: '/my-wedding/checklist',
    name: 'CL-WEDD-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-WEDD-02',
      titleEn: 'Checklist',
      titleAr: 'قائمة المهام',
      kind: 'screen',
      purpose: 'Rules-based checklist with the PRD defaults, due dates derived from the wedding date, custom items, a completion percentage and deep links into Services. The Venue item completes automatically when a booking is confirmed.',
    ),
  ),
  GoRoute(
    path: '/my-wedding/budget',
    name: 'CL-WEDD-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-WEDD-03',
      titleEn: 'Budget',
      titleAr: 'الميزانية',
      kind: 'screen',
      purpose: 'Budget manager built around committed versus paid versus remaining. A hero figure, one segmented bar, ranked category rows with meters, automatic rows from Ghazal bookings and payments, manual expenses and calm alerts at 80% and 100%.',
    ),
  ),
  GoRoute(
    path: '/my-wedding/add-expense',
    name: 'CL-WEDD-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-WEDD-04',
      titleEn: 'Add expense',
      titleAr: 'إضافة مصروف',
      kind: 'sheet',
      purpose: 'Record a purchase made outside Ghazal, or a planned one, against a category. Also the edit and delete sheet for manual expenses; automatic rows are read-only.',
    ),
  ),
  GoRoute(
    path: '/my-wedding/budget-setup',
    name: 'CL-WEDD-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-WEDD-05',
      titleEn: 'Set budget',
      titleAr: 'تحديد الميزانية',
      kind: 'sheet',
      purpose: 'Set or edit the total wedding budget (asked here; onboarding only gives the venue and catering band, which appears as a reference on that category) and allocate it across categories; shows the unallocated remainder and explains the alerts.',
    ),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get myWeddingTabRoots => <String, GoRoute>{
  'CL-WEDD-01':
    GoRoute(
      path: '/my-wedding/my-wedding',
      name: 'CL-WEDD-01',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'CL-WEDD-01',
        titleEn: 'My Wedding',
        titleAr: 'زفافكم',
        kind: 'tab-root',
        purpose: 'Phase-aware home of the wedding file: countdown hero with milestone states, up to three \'Next up\' actions, the Bookings card, the planner offer or assigned planner, and a tools row. Becomes the launch tab as soon as a booking is awaiting a deposit, has a balance due, or is confirmed.',
      ),
    ),
};
