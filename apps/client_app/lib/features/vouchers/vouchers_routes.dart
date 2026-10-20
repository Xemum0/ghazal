// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `vouchersRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `vouchers` (CL): 5 screens. Vouchers
List<RouteBase> get vouchersRoutes => <RouteBase>[
  GoRoute(
    path: '/vouchers/voucher-explainer',
    name: 'CL-VCHR-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VCHR-01',
      titleEn: 'How the voucher works',
      titleAr: 'كيف يعمل الكوبون',
      kind: 'sheet',
      purpose: 'The explainer and binding confirmation shown before the first purchase and on every Get voucher: what the voucher is, what it is bound to (this venue, date, hall, package, guests), the KD 2 price, the saving, and the 24 hour confirm rule, the credit voucher from support and the reuse rule in plain words. One primary continues to payment.',
    ),
  ),
  GoRoute(
    path: '/vouchers/my-vouchers',
    name: 'CL-VCHR-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VCHR-02',
      titleEn: 'My vouchers',
      titleAr: 'كوبوناتي',
      kind: 'screen',
      purpose: 'The vouchers wallet: every voucher by state with its target, saving and validity. Three segments (Ready to use, In a request, History). Reached from Profile, Booking detail and the voucher-ready screen. Guests see a sign-in teaser.',
    ),
  ),
  GoRoute(
    path: '/vouchers/voucher-detail',
    name: 'CL-VCHR-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VCHR-03',
      titleEn: 'Voucher',
      titleAr: 'الكوبون',
      kind: 'screen',
      purpose: 'One voucher: the single-use code and QR the venue scans, what it is bound to, its validity, its status and its history, with the actions that fit its state (send request, show to the venue, ask support). The QR view raises screen brightness and stays awake.',
    ),
  ),
  GoRoute(
    path: '/vouchers/voucher-for-request',
    name: 'CL-VCHR-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VCHR-04',
      titleEn: 'Voucher for this request',
      titleAr: 'كوبون هذا الطلب',
      kind: 'sheet',
      purpose: 'The voucher-bound request summary as a sheet, opened from Review (CL-BOOK-05) and the booking steps: shows which voucher is attached, whether it still matches the quote (standard price, voucher price, saving), lets the client choose among matching ready vouchers, or get one when none exists. One voucher, one request.',
    ),
  ),
  GoRoute(
    path: '/vouchers/voucher-refund-reuse',
    name: 'CL-VCHR-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-VCHR-05',
      titleEn: 'Use again or ask support',
      titleAr: 'استخدام مجددًا أو طلب من الدعم',
      kind: 'sheet',
      purpose: 'What happened to a released voucher and the choices that apply: use it again at the same venue until the reuse date, ask support for a credit voucher (no money returns), or understand why neither is available. Also the refund status once requested.',
    ),
  ),
];
