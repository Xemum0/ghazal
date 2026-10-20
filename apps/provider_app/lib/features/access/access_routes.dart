// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `accessRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `access` (HL): 4 screens. Access and account status
List<RouteBase> get accessRoutes => <RouteBase>[
  GoRoute(
    path: '/access/sign-in',
    name: 'HL-ACCS-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-ACCS-01',
      titleEn: 'Sign in',
      titleAr: 'تسجيل الدخول',
      kind: 'screen',
      purpose: 'The single entry for venue staff: Kuwait mobile number plus password. Staff are multinational, so the language can be flipped before signing in. A returning user on a trusted device goes straight to Today.',
    ),
  ),
  GoRoute(
    path: '/access/verify-code',
    name: 'HL-ACCS-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-ACCS-02',
      titleEn: 'Verify with email',
      titleAr: 'التحقق عبر البريد الإلكتروني',
      kind: 'screen',
      purpose: 'One reusable code screen for four moments: first sign-in on a new device, password reset, the step-up check before high-risk actions (bank information, inviting or removing staff), and the authenticator code that venue admins add on a new device (ADR 0028 D5-D6).',
    ),
  ),
  GoRoute(
    path: '/access/set-password',
    name: 'HL-ACCS-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-ACCS-03',
      titleEn: 'Set your password',
      titleAr: 'تعيين كلمة المرور',
      kind: 'screen',
      purpose: 'Landing for the emailed invitation link and for password reset. A new staff member sees who invited them and in which role, picks a password and a language, and continues to device verification.',
    ),
  ),
  GoRoute(
    path: '/access/account-status',
    name: 'HL-ACCS-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-ACCS-04',
      titleEn: 'Account status',
      titleAr: 'حالة الحساب',
      kind: 'screen',
      purpose: 'A specific, calm screen for every moment the app cannot open normally: venue under review, venue suspended, staff member deactivated, session ended by an admin, and a deep link to something the role may not open. Never a dead end: each variant has exactly one next step.',
    ),
  ),
];
