// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `providerRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `provider` (HL): 7 screens. Provider and listings
List<RouteBase> get providerRoutes => <RouteBase>[
  GoRoute(
    path: '/provider/account-type',
    name: 'HL-PROV-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-PROV-01',
      titleEn: 'Choose your account type',
      titleAr: 'اختاروا نوع الحساب',
      kind: 'screen',
      purpose: 'First-run onboarding for a new partner: choose Hotel or wedding hall, or Service provider, then complete the profile (business name in both languages, categories for providers, contact) and submit for review. Existing venue accounts skip it; a person with both types switches in More.',
    ),
  ),
  GoRoute(
    path: '/provider/my-listings',
    name: 'HL-PROV-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-PROV-02',
      titleEn: 'My listings',
      titleAr: 'إعلاناتي',
      kind: 'tab-root',
      purpose: 'The provider\'s home for listings (the slot of the Calendar tab for service providers; More for hotels that also list services): every listing with its lifecycle status, plan period and a clear next action. Create a listing from here.',
    ),
  ),
  GoRoute(
    path: '/provider/listing-editor',
    name: 'HL-PROV-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-PROV-03',
      titleEn: 'Listing',
      titleAr: 'الإعلان',
      kind: 'screen',
      purpose: 'Create or edit a listing: category, bilingual title and description, photos, and packages each with a standard price and a voucher price on the same basis (per person or package). Saves as a draft; "Continue" chooses the plan. Editing a live listing returns it to review while the approved version stays live (A-09).',
    ),
  ),
  GoRoute(
    path: '/provider/ad-plan',
    name: 'HL-PROV-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-PROV-04',
      titleEn: 'Choose a plan',
      titleAr: 'اختاروا الباقة',
      kind: 'screen',
      purpose: 'Choose the advertising or listing plan: Weekly, Monthly or Annual, with a short list of what each includes. Rates are not decided: while they are not set every card says "Rates announced soon" and the continue action is disabled with that reason. Major hotels see an explanation instead of plans and go straight to review.',
    ),
  ),
  GoRoute(
    path: '/provider/ad-payment',
    name: 'HL-PROV-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-PROV-05',
      titleEn: 'Pay for the plan',
      titleAr: 'دفع الباقة',
      kind: 'screen',
      purpose: 'Pay for the chosen plan through the gateway (same hosted methods as the client voucher) and see every outcome. Payment moves the listing to review; it never publishes it. Rates not set means the screen cannot be reached.',
    ),
  ),
  GoRoute(
    path: '/provider/review-status',
    name: 'HL-PROV-06',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-PROV-06',
      titleEn: 'Review status',
      titleAr: 'حالة المراجعة',
      kind: 'screen',
      purpose: 'Where a listing is in manual review: Pending (what to expect), Approved (when it goes live) or Rejected with reason codes and a note, and the way to edit and resubmit. Moderators check content compliance and correct category placement; exempt partners are reviewed too.',
    ),
  ),
  GoRoute(
    path: '/provider/listing-performance',
    name: 'HL-PROV-07',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-PROV-07',
      titleEn: 'Listing performance',
      titleAr: 'أداء الإعلان',
      kind: 'screen',
      purpose: 'How a listing is doing: views, saves, vouchers purchased for it and requests, for a date range, with a table twin for every chart. The provider counterpart of venue analytics.',
    ),
  ),
];
