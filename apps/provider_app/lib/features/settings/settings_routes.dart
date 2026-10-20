// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `settingsRoutes` (non-tab screens) and `settingsTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `settings` (HL): 5 screens. More and settings
List<RouteBase> get settingsRoutes => <RouteBase>[
  GoRoute(
    path: '/settings/notification-prefs',
    name: 'HL-SETT-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-SETT-02',
      titleEn: 'Notification preferences',
      titleAr: 'تفضيلات الإشعارات',
      kind: 'screen',
      purpose: 'Choose which notification types this person receives, limited by role, and hear what the new-request alert sounds like. Critical alerts for the roles that act on requests cannot be switched off.',
    ),
  ),
  GoRoute(
    path: '/settings/staff',
    name: 'HL-SETT-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-SETT-03',
      titleEn: 'Staff and roles',
      titleAr: 'الموظفون والأدوار',
      kind: 'screen',
      purpose: 'Invite staff, assign a role, deactivate or remove a person and end their sessions. Admin only. A role is explained in one line so the owner knows what each person will see.',
    ),
  ),
  GoRoute(
    path: '/settings/bank-info',
    name: 'HL-SETT-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-SETT-04',
      titleEn: 'Billing and fees',
      titleAr: 'الفوترة والرسوم',
      kind: 'screen',
      purpose: 'Where a partner sees what Ghazal charges and what it has paid: the listing or advertising plan (weekly, monthly or annual), its period and renewal, receipts, and, for major hotels, the exemption badge. There is no bank information and no payout (partners are never paid through Ghazal).',
    ),
  ),
  GoRoute(
    path: '/settings/business-hours',
    name: 'HL-SETT-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-SETT-05',
      titleEn: 'Business hours',
      titleAr: 'ساعات العمل',
      kind: 'screen',
      purpose: 'Set the hours the venue office is reachable, shown to couples as working hours, and the closures that apply. The same hours decide when a new-request alert makes a sound.',
    ),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get settingsTabRoots => <String, GoRoute>{
  'HL-SETT-01':
    GoRoute(
      path: '/settings/more-root',
      name: 'HL-SETT-01',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'HL-SETT-01',
        titleEn: 'More',
        titleAr: 'المزيد',
        kind: 'tab-root',
        purpose: 'The root of everything that is not the daily loop. Top card shows the listing status, language completeness and payout status; below it the groups My venue, Grow, Notifications, Business and Account, at most two levels deep.',
      ),
    ),
};
