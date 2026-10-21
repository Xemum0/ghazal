/// notifications: the centre of both apps (filled by the events that would send a push) and the client's preferences.
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../engine/engine.dart';

List<Json> _mine(MockApp app, Req r) => [for (final n in app.db.raw('Notification')) if (n['userId'] == r.userId && (r.partner == null || n['venueId'] == null || n['venueId'] == r.partner!.venueId) ) n];

Map<String, Handler> notificationsHandlers(MockApp app) => {
      'listNotifications': (r) {
        final onlyUnread = r.qBool('unread') == true;
        final rows = _mine(app, r).where((n) => !onlyUnread || n['read'] != true).toList();
        // Newest first. The partner list reproduces the web's own comparator (`a.at < b.at ? 1 : -1`), under which notifications of the same
        // minute come out in reverse fixture order (Fatima before Faisal at 11:00); the client list keeps fixture order for ties.
        final ordered = r.partner != null ? rows.reversed.toList() : rows;
        return pageMap(r, stableSorted(ordered, (a, b) => b.str('at').compareTo(a.str('at'))), wire);
      },
      'getUnreadNotificationCount': (r) => {'count': _mine(app, r).where((n) => n['read'] != true).length},
      'markNotificationRead': (r) {
        final n = app.db.get('Notification', r.p('notificationId'));
        if (n == null || n['userId'] != r.userId) throw ApiError.notFound('notification');
        n['read'] = true;
        app.db.put('Notification', n);
        return null;
      },
      'markAllNotificationsRead': (r) {
        for (final n in _mine(app, r)) {
          if (n['read'] != true) app.db.put('Notification', {...deepCopy(n), 'read': true});
        }
        return null;
      },
      'getNotificationPreferences': (r) {
        final p = app.db.peek('NotificationPreferences', r.userId);
        return {'marketing': p?['marketing'] ?? false, 'quietHours': p?['quietHours'] ?? {'start': '22:00', 'end': '09:00'}, 'maxMarketingPerWeek': p?['maxMarketingPerWeek'] ?? 2};
      },
      'updateNotificationPreferences': (r) {
        app.db.put('NotificationPreferences', {'userId': r.userId, 'marketing': r.b['marketing'], 'quietHours': r.b['quietHours'], 'maxMarketingPerWeek': r.b['maxMarketingPerWeek']}, id: r.userId);
        return {'marketing': r.b['marketing'], 'quietHours': r.b['quietHours'], 'maxMarketingPerWeek': r.b['maxMarketingPerWeek']};
      },
    };
