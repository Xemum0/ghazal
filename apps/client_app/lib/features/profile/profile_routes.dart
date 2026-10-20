// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `profileRoutes` (non-tab screens) and `profileTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `profile` (CL): 6 screens. Profile and settings
List<RouteBase> get profileRoutes => <RouteBase>[
  GoRoute(
    path: '/profile/wedding-info',
    name: 'CL-PROF-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PROF-02',
      titleEn: 'Wedding info',
      titleAr: 'بيانات الزفاف',
      kind: 'screen',
      purpose: 'View and edit the wedding file: role, names, date, guests, budget and areas. The same pickers as the Brief; every field is optional and editable at any time. Edits flow into the countdown, budget and recommendations.',
    ),
  ),
  GoRoute(
    path: '/profile/personal-info',
    name: 'CL-PROF-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PROF-03',
      titleEn: 'Personal info',
      titleAr: 'البيانات الشخصية',
      kind: 'screen',
      purpose: 'Name, verified phone and optional email, plus the sign-in methods linked to the account. Changing the number re-verifies by WhatsApp.',
    ),
  ),
  GoRoute(
    path: '/profile/notification-preferences',
    name: 'CL-PROF-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PROF-04',
      titleEn: 'Notification preferences',
      titleAr: 'تفضيلات الإشعارات',
      kind: 'screen',
      purpose: 'Choose what reaches the user. Transactional messages (bookings, payments, messages) are always delivered; reminders are on by default; marketing (offers, price drops, new venues) is opt-in. Shows the OS permission state.',
    ),
  ),
  GoRoute(
    path: '/profile/settings',
    name: 'CL-PROF-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PROF-05',
      titleEn: 'Settings',
      titleAr: 'الإعدادات',
      kind: 'screen',
      purpose: 'App preferences: language and digits, biometric unlock, permissions, usage data, legal pages, version, sign out, and the entry to account deletion in its own section. Switching language applies immediately without a restart and keeps scroll and open sheets.',
    ),
  ),
  GoRoute(
    path: '/profile/delete-account',
    name: 'CL-PROF-06',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PROF-06',
      titleEn: 'Delete account',
      titleAr: 'حذف الحساب',
      kind: 'screen',
      purpose: 'In-app account deletion required by the app stores. It lists the consequences, re-authenticates by WhatsApp code and confirms. If a future booking is awaiting a deposit or confirmed, deletion is paused with a way forward, never a dead end.',
    ),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get profileTabRoots => <String, GoRoute>{
  'CL-PROF-01':
    GoRoute(
      path: '/profile/profile',
      name: 'CL-PROF-01',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'CL-PROF-01',
        titleEn: 'Profile',
        titleAr: 'حسابكم',
        kind: 'tab-root',
        purpose: 'Hub of the Profile tab: monogram identity header and a short list of rows grouped by purpose. Also the guest view with only sign-in, language and legal pages.',
      ),
    ),
};
