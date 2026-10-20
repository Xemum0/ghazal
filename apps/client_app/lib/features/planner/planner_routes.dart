// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `plannerRoutes` (non-tab screens).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `planner` (CL): 4 screens. Wedding planner
List<RouteBase> get plannerRoutes => <RouteBase>[
  GoRoute(
    path: '/planner/planner-packages',
    name: 'CL-PLAN-01',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PLAN-01',
      titleEn: 'Wedding planner packages',
      titleAr: 'باقات تنسيق الأعراس',
      kind: 'screen',
      purpose: 'Compare the three planner tiers and choose one. Reached from the one-time \'Need a wedding planner?\' card (after Request sent or Confirmed), the planner module in My Wedding, and the Services hub. Browsing is open to guests; the account is requested only when sending the consultation request.',
    ),
  ),
  GoRoute(
    path: '/planner/request-consultation',
    name: 'CL-PLAN-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PLAN-02',
      titleEn: 'Request consultation',
      titleAr: 'طلب استشارة',
      kind: 'screen',
      purpose: 'A short form to request a consultation: chosen package, preferred time windows and notes. Hard-gated: the sign-in sheet opens at Send and resumes here with everything typed.',
    ),
  ),
  GoRoute(
    path: '/planner/planner-status',
    name: 'CL-PLAN-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PLAN-03',
      titleEn: 'Your planner',
      titleAr: 'منسّقتكم',
      kind: 'screen',
      purpose: 'Request status and, once assigned, the planner\'s name, role, package and ways to reach her. Shows the three states of the request (requested, assigned, meeting scheduled) on the thread and the next meeting. No planner directory.',
    ),
  ),
  GoRoute(
    path: '/planner/schedule-meeting',
    name: 'CL-PLAN-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-PLAN-04',
      titleEn: 'Schedule a meeting',
      titleAr: 'تحديد موعد الاجتماع',
      kind: 'sheet',
      purpose: 'Pick a slot from the assigned planner\'s availability. Opens from the status screen and from inside the planner chat; confirming drops a meeting card into the thread.',
    ),
  ),
];
