/// planners: planner packages, the consultation request (assigned at once, with bookable video-call slots) and scheduling the meeting.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../domain/chat.dart';
import '../domain/notify.dart';
import '../domain/format.dart';
import '../engine/engine.dart';

const _times = {
  'morning': ['09:00', '09:30', '10:30'],
  'afternoon': ['14:00', '14:30', '16:00'],
  'evening': ['17:00', '17:30', '19:30', '20:00'],
};

Map<String, Handler> plannersHandlers(MockApp app) => {
      'listPlannerPackages': (r) => app.seed.rows('PlannerPackage'),
      'getPlanner': (r) {
        final p = app.seed.rows('Planner').cast<Json?>().firstWhere((x) => x!['id'] == r.p('plannerId'), orElse: () => null) ?? (throw ApiError.notFound('planner'));
        return {'planner': p, 'packages': app.seed.rows('PlannerPackage').where((pk) => p.strings('tiers').contains(pk['tier'])).toList()};
      },
      'createPlannerRequest': (r) {
        if (app.db.peek('User', r.userId)?['_phoneVerified'] == false) throw ApiError('PHONE_VERIFICATION_REQUIRED');
        final b = r.b;
        final planners = app.seed.rows('Planner').where((p) => p.strings('tiers').contains(b['tier'])).toList();
        final planner = planners.isEmpty ? app.seed.rows('Planner').first : planners[app.db.count('PlannerRequest') % planners.length];
        final windows = b.list('windows');
        final dates = windows.isEmpty ? [addDays(app.today(), 2), addDays(app.today(), 3)] : windows.map((w) => w.str('date')).toSet().toList();
        final slots = [
          for (final d in dates)
            {'date': d, 'times': (windows.where((w) => w['date'] == d).expand((w) => _times[w['part']] ?? const <String>[]).toSet().toList()..sort()).isEmpty ? _times['evening']! : (windows.where((w) => w['date'] == d).expand((w) => _times[w['part']] ?? const <String>[]).toSet().toList()..sort())}
        ];
        final id = 'plannerreq-m${app.db.next('plannerreq').toString().padLeft(3, '0')}';
        final doc = {
          'id': id,
          'clientId': r.userId,
          'tier': b['tier'],
          'venueId': b['venueId'],
          'eventDate': b['eventDate'],
          'windows': windows,
          'note': b['note'] ?? '',
          'requestedAt': app.now,
          'status': 'assigned',
          'plannerId': planner['id'],
          'assignedAt': app.now,
          'meeting': null,
          'slots': slots,
        };
        app.db.put('PlannerRequest', doc);
        final convId = 'conv-planner-${planner['id']}-${r.userId}';
        if (!app.db.has('Conversation', convId)) {
          app.db.put('Conversation', {
            'id': convId,
            'kind': 'planner',
            'title': planner['name'],
            'subtitle': {'en': 'Your wedding planner', 'ar': 'منسّقة زفافكم'},
            'monogram': planner['monogram'],
            'clientId': r.userId,
            'clientName': r.identity!.user['name'],
            'venueId': null,
            'bookingId': null,
            'plannerId': planner['id'],
            'vendorId': null,
            'pinned': false,
            'unread': {'client': 0, 'hotel': 0},
            'handledBy': null,
            'lastMessageAt': app.now,
            'awaitingReplySince': null,
            'usuallyRepliesHours': 2,
          });
          appendMessage(app, convId, from: 'planner', senderName: (planner.obj('name')['en'] as String?), text: {'en': 'Hello! I am your wedding planner. Pick a time for our video call.', 'ar': 'أهلًا! أنا منسّقة زفافكم. اختاروا وقتًا لمكالمتنا.'}, origin: 'ar');
        }
        return wire(doc);
      },
      'getCurrentPlannerRequest': (r) {
        final mine = app.db.raw('PlannerRequest').where((p) => p['clientId'] == r.userId).toList();
        if (mine.isEmpty) throw ApiError.notFound('planner request');
        return wire(stableSorted(mine, (a, b) => b.str('requestedAt').compareTo(a.str('requestedAt'))).first);
      },
      'schedulePlannerMeeting': (r) {
        final p = app.db.get('PlannerRequest', r.p('requestId'));
        if (p == null || p['clientId'] != r.userId) throw ApiError.notFound('planner request');
        final at = atTime(r.b.str('date'), r.b.str('time'));
        p['status'] = 'meeting_scheduled';
        p['meeting'] = {'at': at, 'durationMin': 60, 'channel': 'video_call'};
        app.db.put('PlannerRequest', p);
        final planner = app.seed.rows('Planner').firstWhere((x) => x['id'] == p['plannerId']);
        notify(app, userId: r.userId, kind: 'planner_assigned', audience: 'client', vars: {'planner': planner['name'] as Object, 'meetingAt': instantLT(at)}, params: {'planner': p['plannerId'], 'meetingAt': at}, conversationId: 'conv-planner-${p['plannerId']}-${r.userId}');
        return wire(p);
      },
    };
