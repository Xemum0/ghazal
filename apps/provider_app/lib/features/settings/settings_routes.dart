// Contract used by lib/app/app_router.dart: `settingsRoutes` (non-tab screens) and `settingsTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_sett_01.dart';
import 'presentation/hl_sett_02.dart';
import 'presentation/hl_sett_03.dart';
import 'presentation/hl_sett_04.dart';
import 'presentation/hl_sett_05.dart';

/// Flow `settings` (HL): 5 screens. More and settings
List<RouteBase> get settingsRoutes => <RouteBase>[
  GoRoute(
    path: '/settings/notification-prefs',
    name: 'HL-SETT-02',
    builder: (BuildContext context, GoRouterState state) => const HlSett02Screen(),
  ),
  GoRoute(
    path: '/settings/staff',
    name: 'HL-SETT-03',
    builder: (BuildContext context, GoRouterState state) => const HlSett03Screen(),
  ),
  GoRoute(
    path: '/settings/bank-info',
    name: 'HL-SETT-04',
    builder: (BuildContext context, GoRouterState state) => const HlSett04Screen(),
  ),
  GoRoute(
    path: '/settings/business-hours',
    name: 'HL-SETT-05',
    builder: (BuildContext context, GoRouterState state) => const HlSett05Screen(),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get settingsTabRoots => <String, GoRoute>{
  'HL-SETT-01': GoRoute(
    path: '/settings/more-root',
    name: 'HL-SETT-01',
    builder: (BuildContext context, GoRouterState state) => const HlSett01Screen(),
  ),
};
