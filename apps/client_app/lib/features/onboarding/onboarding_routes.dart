// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `onboardingRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `onboarding` (CL): 6 screens. Welcome and wedding Brief
List<RouteBase> get onboardingRoutes => <RouteBase>[
  GoRoute(
    path: '/onboarding/language',
    name: 'CL-ONBD-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-ONBD-01',
      titleEn: 'Language',
      titleAr: 'اللغة',
      kind: 'screen',
      purpose: 'First-ever screen. The couple chooses Arabic or English; direction flips immediately and the choice persists. Returning users can jump straight to sign-in.',
    ),
  ),
  GoRoute(
    path: '/onboarding/intro',
    name: 'CL-ONBD-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-ONBD-02',
      titleEn: 'Introduction',
      titleAr: 'تعريف سريع',
      kind: 'screen',
      purpose: 'Three swipeable, skippable slides with one promise each. Skipping goes straight to Home with an empty Brief.',
    ),
  ),
  GoRoute(
    path: '/onboarding/about-you',
    name: 'CL-ONBD-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-ONBD-03',
      titleEn: 'Who is planning?',
      titleAr: 'من يخطط للزفاف؟',
      kind: 'screen',
      purpose: 'Capture the planner\'s role and names so the monogram, countdown and Wedding info start filled. Optional and editable later.',
    ),
  ),
  GoRoute(
    path: '/onboarding/wedding-date',
    name: 'CL-ONBD-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-ONBD-04',
      titleEn: 'Wedding date',
      titleAr: 'موعد الزفاف',
      kind: 'screen',
      purpose: 'Set the wedding date or mark it undecided. This is the full-screen version of the shared date picker later reused as the Brief date sheet.',
    ),
  ),
  GoRoute(
    path: '/onboarding/guests-budget',
    name: 'CL-ONBD-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-ONBD-05',
      titleEn: 'Guests and budget',
      titleAr: 'الضيوف والميزانية',
      kind: 'screen',
      purpose: 'Set the guest count and the venue-and-catering budget together, because per-guest pricing makes them one decision in Kuwait.',
    ),
  ),
  GoRoute(
    path: '/onboarding/areas',
    name: 'CL-ONBD-06',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-ONBD-06',
      titleEn: 'Preferred areas',
      titleAr: 'المناطق المفضلة',
      kind: 'screen',
      purpose: 'Multi-select Kuwait areas grouped by governorate, then finish onboarding with a live count of matching halls. Reused as the area picker in the Brief sheet and filters.',
    ),
  ),
];
