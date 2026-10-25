// Contract used by lib/app/app_router.dart: `providerRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_prov_01.dart';
import 'presentation/hl_prov_02.dart';
import 'presentation/hl_prov_03.dart';
import 'presentation/hl_prov_04.dart';
import 'presentation/hl_prov_05.dart';
import 'presentation/hl_prov_06.dart';
import 'presentation/hl_prov_07.dart';

/// Flow `provider` (HL): 7 screens. Provider and listings
List<RouteBase> get providerRoutes => <RouteBase>[
  GoRoute(
    path: '/provider/account-type',
    name: 'HL-PROV-01',
    builder: (BuildContext context, GoRouterState state) => const HlProv01Screen(),
  ),
  GoRoute(
    path: '/provider/my-listings',
    name: 'HL-PROV-02',
    builder: (BuildContext context, GoRouterState state) => const HlProv02Screen(),
  ),
  GoRoute(
    path: '/provider/listing-editor',
    name: 'HL-PROV-03',
    builder: (BuildContext context, GoRouterState state) => const HlProv03Screen(),
  ),
  GoRoute(
    path: '/provider/ad-plan',
    name: 'HL-PROV-04',
    builder: (BuildContext context, GoRouterState state) => const HlProv04Screen(),
  ),
  GoRoute(
    path: '/provider/ad-payment',
    name: 'HL-PROV-05',
    builder: (BuildContext context, GoRouterState state) => const HlProv05Screen(),
  ),
  GoRoute(
    path: '/provider/review-status',
    name: 'HL-PROV-06',
    builder: (BuildContext context, GoRouterState state) => const HlProv06Screen(),
  ),
  GoRoute(
    path: '/provider/listing-performance',
    name: 'HL-PROV-07',
    builder: (BuildContext context, GoRouterState state) => const HlProv07Screen(),
  ),
];
