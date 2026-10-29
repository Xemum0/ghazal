// Contract used by lib/app/app_router.dart: `authRoutes` (non-tab screens; no auth screen is a tab root).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_auth_01.dart';
import 'presentation/cl_auth_02.dart';
import 'presentation/cl_auth_03.dart';
import 'presentation/cl_auth_04.dart';
import 'presentation/cl_auth_05.dart';

/// Flow `auth` (CL): 5 screens. Sign in and account. CL-AUTH-01 is a full screen since ADR 0038 (no guest mode, no gate sheet).
List<RouteBase> get authRoutes => <RouteBase>[
  GoRoute(path: '/auth/sign-in', name: 'CL-AUTH-01', builder: (BuildContext context, GoRouterState state) => const ClAuth01Screen()),
  GoRoute(path: '/auth/whatsapp-otp', name: 'CL-AUTH-02', builder: (BuildContext context, GoRouterState state) => const ClAuth02Screen()),
  GoRoute(path: '/auth/about-you', name: 'CL-AUTH-03', builder: (BuildContext context, GoRouterState state) => const ClAuth03Screen()),
  GoRoute(path: '/auth/password', name: 'CL-AUTH-04', builder: (BuildContext context, GoRouterState state) => const ClAuth04Screen()),
  GoRoute(path: '/auth/biometric', name: 'CL-AUTH-05', builder: (BuildContext context, GoRouterState state) => const ClAuth05Screen()),
];
