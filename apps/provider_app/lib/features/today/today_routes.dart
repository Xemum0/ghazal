// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `todayRoutes` (non-tab screens) and `todayTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `today` (HL): 5 screens. Today, alerts and messages
List<RouteBase> get todayRoutes => <RouteBase>[
  GoRoute(
    path: '/today/needs-you',
    name: 'HL-TODY-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-TODY-02',
      titleEn: 'Needs you',
      titleAr: 'بانتظاركم',
      kind: 'screen',
      purpose: 'The full queue behind \'See all N\': everything that needs a person, ranked by nearest deadline, so nothing waits unseen. It mixes pending requests, unanswered messages, overdue balances, reviews awaiting a reply and the weekly calendar confirmation.',
    ),
  ),
  GoRoute(
    path: '/today/notifications',
    name: 'HL-TODY-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-TODY-03',
      titleEn: 'Notifications',
      titleAr: 'الإشعارات',
      kind: 'screen',
      purpose: 'The in-app list of everything the system told the venue, with read and unread state. A new booking request is visually and audibly distinct from every other type. Each row opens its object with a rebuilt back stack.',
    ),
  ),
  GoRoute(
    path: '/today/thread',
    name: 'HL-TODY-05',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'HL-TODY-05',
      titleEn: 'Conversation',
      titleAr: 'المحادثة',
      kind: 'screen',
      purpose: 'A real-time conversation with a couple (or with Ghazal Support) that always shows the booking it belongs to, so staff can answer and decide in one place. Text, photos, documents and voice notes.',
    ),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get todayTabRoots => <String, GoRoute>{
  'HL-TODY-01':
    GoRoute(
      path: '/today/today',
      name: 'HL-TODY-01',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'HL-TODY-01',
        titleEn: 'Today',
        titleAr: 'اليوم',
        kind: 'tab-root',
        purpose: 'Glance and decide. For Admin and Manager: status sentence, Needs-you cards (two expanded), today\'s events, 14-day availability strip with the soft-date shortcut, quick actions and three money tiles, then a messages preview and the latest notifications. Reception, Accountant and Marketing see the same screen with role-aware content instead of a different navigation.',
      ),
    ),
  'HL-TODY-04':
    GoRoute(
      path: '/today/inbox',
      name: 'HL-TODY-04',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'HL-TODY-04',
        titleEn: 'Messages',
        titleAr: 'الرسائل',
        kind: 'tab-root',
        purpose: 'The shared inbox of client conversations with unread counts, booking context and a pinned Ghazal Support conversation. It answers \'who is waiting for me\' and lets reception hand over to the manager without losing history.',
      ),
    ),
};
