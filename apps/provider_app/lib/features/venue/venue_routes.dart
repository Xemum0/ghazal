// Contract used by lib/app/app_router.dart: `venueRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/hl_venu_01.dart';
import 'presentation/hl_venu_02.dart';
import 'presentation/hl_venu_03.dart';
import 'presentation/hl_venu_04.dart';
import 'presentation/hl_venu_05.dart';
import 'presentation/hl_venu_06.dart';

/// Flow `venue` (HL): 6 screens. My venue
List<RouteBase> get venueRoutes => <RouteBase>[
  GoRoute(path: '/venue/media-manager', name: 'HL-VENU-01', builder: (BuildContext context, GoRouterState state) => const HlVenu01Screen()),
  GoRoute(path: '/venue/packages', name: 'HL-VENU-02', builder: (BuildContext context, GoRouterState state) => const HlVenu02Screen()),
  GoRoute(path: '/venue/package-editor', name: 'HL-VENU-03', builder: (BuildContext context, GoRouterState state) => const HlVenu03Screen()),
  GoRoute(path: '/venue/halls-amenities', name: 'HL-VENU-04', builder: (BuildContext context, GoRouterState state) => const HlVenu04Screen()),
  GoRoute(path: '/venue/policies', name: 'HL-VENU-05', builder: (BuildContext context, GoRouterState state) => const HlVenu05Screen()),
  GoRoute(path: '/venue/booking-rules', name: 'HL-VENU-06', builder: (BuildContext context, GoRouterState state) => const HlVenu06Screen()),
];
