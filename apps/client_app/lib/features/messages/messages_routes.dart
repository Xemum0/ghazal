// GENERATED STUB: tools/gen-routes.mjs. A flow agent removes this first line when it takes the file over; the generator then never touches it again.
// Contract used by lib/app/app_router.dart: `messagesRoutes` (non-tab screens) and `messagesTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

/// Flow `messages` (CL): 4 screens. Messages and notifications
List<RouteBase> get messagesRoutes => <RouteBase>[
  GoRoute(
    path: '/messages/thread',
    name: 'CL-MSGS-02',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-MSGS-02',
      titleEn: 'Conversation',
      titleAr: 'المحادثة',
      kind: 'screen',
      purpose: 'One chat thread for a venue, planner, vendor or Ghazal support with real-time delivery states, photos, videos, documents and voice notes. A pinned booking context bar keeps the date and status in view. Structured cards carry booking summaries, meetings and quote requests.',
    ),
  ),
  GoRoute(
    path: '/messages/conversation-info',
    name: 'CL-MSGS-03',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-MSGS-03',
      titleEn: 'Conversation details',
      titleAr: 'تفاصيل المحادثة',
      kind: 'sheet',
      purpose: 'Who you are talking to, the linked booking, shared media and the safety actions required for user-generated content: report a message and block a conversation.',
    ),
  ),
  GoRoute(
    path: '/messages/notification-centre',
    name: 'CL-MSGS-04',
    builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
      id: 'CL-MSGS-04',
      titleEn: 'Notifications',
      titleAr: 'الإشعارات',
      kind: 'screen',
      purpose: 'The in-app record of booking updates, payments, messages, offers, price drops, new venues and wedding reminders, grouped by day. Each row lands on the exact object with the back stack rebuilt (tab root, parent, target). Hosts the OS permission pre-prompt and its denied banner.',
    ),
  ),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get messagesTabRoots => <String, GoRoute>{
  'CL-MSGS-01':
    GoRoute(
      path: '/messages/inbox',
      name: 'CL-MSGS-01',
      builder: (BuildContext context, GoRouterState state) => const GzStubScreen(
        id: 'CL-MSGS-01',
        titleEn: 'Messages',
        titleAr: 'الرسائل',
        kind: 'tab-root',
        purpose: 'Inbox of all conversations with last message, time and unread count, filterable by counterpart. Support is pinned. The tab badge shows the total unread count.',
      ),
    ),
};
