// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `visitsRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `visits` (HL): 5 screens. Visits
List<RouteBase> get visitsRoutes => <RouteBase>[
  GoRoute(
    path: '/visits/visit-requests',
    name: 'HL-VIST-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VIST-01',
      titleEn: 'Visit requests',
      titleAr: 'طلبات الزيارة',
      kind: 'screen',
      purpose: 'All visits by state: Requested (needs a reply), Upcoming and Past, ordered by the nearest slot. The place the hotel representative works from; also reachable from Today > Needs you.',
    ),
  ),
  GoRoute(
    path: '/visits/visit-detail',
    name: 'HL-VIST-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VIST-02',
      titleEn: 'Visit',
      titleAr: 'الزيارة',
      kind: 'screen',
      purpose: 'One visit: who, when, how many, what they asked, with the representative\'s actions (confirm, propose another time, decline), the assigned representative and the link into the group chat. Variant per status.',
    ),
  ),
  GoRoute(
    path: '/visits/visit-group-chat',
    name: 'HL-VIST-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VIST-03',
      titleEn: 'Visit chat',
      titleAr: 'محادثة الزيارة',
      kind: 'screen',
      purpose: 'The dedicated group chat for the visit, seen by the hotel representative: the client, the hotel representative (you or a colleague with the visit permission) and a Ghazal support representative. Same chat component as the client (CL-VIST-03), with the representative\'s actions on the pinned card.',
    ),
  ),
  GoRoute(
    path: '/visits/arrival',
    name: 'HL-VIST-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VIST-04',
      titleEn: 'Mark arrival',
      titleAr: 'تأكيد الوصول',
      kind: 'sheet',
      purpose: 'On the day, confirm that the client arrived (or flag that they did not): the representative\'s half of the arrival confirmation that the client starts in the chat.',
    ),
  ),
  GoRoute(
    path: '/visits/visit-availability',
    name: 'HL-VIST-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-VIST-05',
      titleEn: 'Visit availability',
      titleAr: 'مواعيد الزيارة',
      kind: 'screen',
      purpose: 'Set when visits can be requested: days, hours, slot length and a switch to turn visits off. Drives the slots clients see in CL-VIST-01. Admin and Manager only.',
    ),
  ),
];
