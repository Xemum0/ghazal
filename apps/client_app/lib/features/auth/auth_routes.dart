// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `authRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `auth` (CL): 5 screens. Sign in and account
List<RouteBase> get authRoutes => <RouteBase>[
  GoRoute(
    path: '/auth/sign-in-sheet',
    name: 'CL-AUTH-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-AUTH-01',
      titleEn: 'Sign in or continue',
      titleAr: 'تسجيل الدخول أو المتابعة',
      kind: 'sheet',
      purpose: 'The single identity entry (no separate Sign up and Login) and the reusable guest-gate sheet. A context line says why the account is needed; after auth the interrupted intent resumes exactly.',
    ),
  ),
  GoRoute(
    path: '/auth/whatsapp-otp',
    name: 'CL-AUTH-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-AUTH-02',
      titleEn: 'WhatsApp code',
      titleAr: 'رمز التحقق عبر واتساب',
      kind: 'screen',
      purpose: 'Verify the phone with a six-digit code delivered over WhatsApp. Also reused inline in the booking Details step and for password reset and phone change.',
    ),
  ),
  GoRoute(
    path: '/auth/name-terms',
    name: 'CL-AUTH-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-AUTH-03',
      titleEn: 'Name and terms',
      titleAr: 'الاسم والموافقة على الشروط',
      kind: 'screen',
      purpose: 'Final step for a brand-new account: confirm the name and accept the Terms of Use and Privacy Policy. Onboarding answers held on the device attach to the account here.',
    ),
  ),
  GoRoute(
    path: '/auth/password',
    name: 'CL-AUTH-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-AUTH-04',
      titleEn: 'Password',
      titleAr: 'كلمة المرور',
      kind: 'screen',
      purpose: 'Tertiary path for people who prefer a password: sign in, create a password account, and recover a forgotten password, as modes of one screen.',
    ),
  ),
  GoRoute(
    path: '/auth/biometric',
    name: 'CL-AUTH-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-AUTH-05',
      titleEn: 'Biometric unlock',
      titleAr: 'الفتح بالبصمة أو الوجه',
      kind: 'screen',
      purpose: 'Optional app lock: a pre-prompt sheet after the first sign-in and the unlock screen shown on launch to returning users. Biometrics unlock a stored session; they never replace first login.',
    ),
  ),
];
