// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `paymentRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `payment` (CL): 5 screens. Payment
List<RouteBase> get paymentRoutes => <RouteBase>[
  GoRoute(
    path: '/payment/pay',
    name: 'CL-PAYM-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PAYM-01',
      titleEn: 'Pay for your voucher',
      titleAr: 'دفع قيمة الكوبون',
      kind: 'screen',
      purpose: 'One pay screen for the KD 2 voucher: shows what the voucher is bound to, the amount, what happens next and the methods in platform order. The gateway is hosted (KNET, Apple Pay, Google Pay, cards); no card form exists in Ghazal. This is the only payment a client makes inside Ghazal (ADR 0033).',
    ),
  ),
  GoRoute(
    path: '/payment/gateway',
    name: 'CL-PAYM-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PAYM-02',
      titleEn: 'Secure payment',
      titleAr: 'الدفع الآمن',
      kind: 'screen',
      purpose: 'Ghazal\'s chrome around the gateway-hosted page (KNET bank redirect, card page, Apple Pay or Google Pay sheet), opened in the system in-app browser session (ASWebAuthenticationSession or Custom Tab, ADR 0027 D2) with a deep-link return. The return URL is never trusted: the app always fetches the payment state from the API afterwards.',
    ),
  ),
  GoRoute(
    path: '/payment/confirming',
    name: 'CL-PAYM-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PAYM-03',
      titleEn: 'Confirming with your bank',
      titleAr: 'التأكيد مع البنك',
      kind: 'screen',
      purpose: 'The pending-bank-confirmation state: a determinate-style thread line while the server verifies, an honest long-wait message after about 30 seconds, and a clear \'safe to leave\'. Prevents double payment.',
    ),
  ),
  GoRoute(
    path: '/payment/not-completed',
    name: 'CL-PAYM-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PAYM-04',
      titleEn: 'Payment not completed',
      titleAr: 'تعذّر إتمام الدفع',
      kind: 'screen',
      purpose: 'One outcome layout for every failure: outcome first, money status second, next step third, never blaming. Covers declined or cancelled payments, KNET limits, an expired instant hold, an expired pay window, and a late payment that could not be honoured.',
    ),
  ),
  GoRoute(
    path: '/payment/confirmed',
    name: 'CL-PAYM-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PAYM-05',
      titleEn: 'Your voucher is ready',
      titleAr: 'كوبونكم جاهز',
      kind: 'screen',
      purpose: 'Success of the KD 2 payment: the voucher with its single-use code and QR, what it is bound to, its validity and the next step. The one celebratory moment of the voucher purchase is small (no confetti, one success haptic); the booking-confirmed celebration lives in CL-BOOK-09.',
    ),
  ),
];
