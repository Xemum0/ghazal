// Contract used by lib/app/app_router.dart: `messagesRoutes` (non-tab screens) and `messagesTabRoots` (tab roots by inventory id).
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/cl_msgs_01.dart';
import 'presentation/cl_msgs_02.dart';
import 'presentation/cl_msgs_03.dart';
import 'presentation/cl_msgs_04.dart';

/// Flow `messages` (CL): 4 screens. Messages and notifications
List<RouteBase> get messagesRoutes => <RouteBase>[
  GoRoute(
    path: '/messages/thread',
    name: 'CL-MSGS-02',
    builder: (BuildContext context, GoRouterState state) => const ClMsgs02Screen(),
  ),
  GoRoute(
    path: '/messages/conversation-info',
    name: 'CL-MSGS-03',
    builder: (BuildContext context, GoRouterState state) => const ClMsgs03Screen(),
  ),
  GoRoute(path: '/messages/notification-centre', name: 'CL-MSGS-04', builder: (BuildContext context, GoRouterState state) => const ClMsgs04Screen()),
];

/// Roots of the main tabs that live in this flow, keyed by inventory id.
Map<String, GoRoute> get messagesTabRoots => <String, GoRoute>{
  'CL-MSGS-01': GoRoute(path: '/messages/inbox', name: 'CL-MSGS-01', builder: (BuildContext context, GoRouterState state) => const ClMsgs01Screen()),
};
