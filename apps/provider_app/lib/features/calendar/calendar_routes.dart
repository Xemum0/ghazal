// Contract used by lib/app/app_router.dart: `calendarRoutes` (non-tab screens) and `calendarTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_caln_01.dart';
import 'presentation/hl_caln_02.dart';
import 'presentation/hl_caln_03.dart';
import 'presentation/hl_caln_04.dart';
import 'presentation/hl_caln_05.dart';

/// Flow `calendar` (HL): 5 screens. Calendar and availability
List<RouteBase> get calendarRoutes => <RouteBase>[
  GoRoute(path: '/calendar/week', name: 'HL-CALN-02', builder: (BuildContext context, GoRouterState state) => const HlCaln02Screen()),
  GoRoute(path: '/calendar/day', name: 'HL-CALN-03', builder: (BuildContext context, GoRouterState state) => const HlCaln03Screen()),
  GoRoute(path: '/calendar/block-dates', name: 'HL-CALN-04', builder: (BuildContext context, GoRouterState state) => const HlCaln04Screen()),
  GoRoute(path: '/calendar/calendar-by-email', name: 'HL-CALN-05', builder: (BuildContext context, GoRouterState state) => const HlCaln05Screen()),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get calendarTabRoots => <String, GoRoute>{
  'HL-CALN-01': GoRoute(path: '/calendar/month', name: 'HL-CALN-01', builder: (BuildContext context, GoRouterState state) => const HlCaln01Screen()),
};
