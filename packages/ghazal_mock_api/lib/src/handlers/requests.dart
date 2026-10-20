/// requests: the client side of the request lifecycle (R01, R05, R07, R08, R10a, R13a). The rules live in `domain/requests.dart`.
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/chat.dart';
import '../domain/requests.dart' as dom;
import '../domain/vouchers.dart';
import '../domain/views.dart';
import '../engine/engine.dart';

Json ownBooking(MockApp app, Req r) {
  final b = dom.requireBooking(app, r.p('requestId'));
  if (b['clientId'] != r.userId) throw ApiError.notFound('request');
  return b;
}

Json _out(Req r, Json b) {
  r.out['ETag'] = '"v${b['version']}"';
  return dom.viewBooking(b);
}

Json confirmWindowOf(MockApp app, Json b) {
  if (b['status'] != 'approved' || b['confirmBy'] == null) return {'state': 'none', 'deadline': b['confirmBy'], 'minutesLeft': 0};
  final left = diffMinutes(app.now, b.str('confirmBy'));
  return {'state': left <= 0 ? 'ended' : (left <= 60 ? 'last_hour' : 'open'), 'deadline': b['confirmBy'], 'minutesLeft': left > 0 ? left : 0};
}

Map<String, Handler> requestsHandlers(MockApp app) => {
      'createRequest': (r) {
        final b = dom.createRequest(app, r.identity!, r.b);
        return _out(r, b);
      },
      'listRequests': (r) {
        final status = r.qList('status');
        final rows = app.db.raw('Booking').where((b) => b['clientId'] == r.userId && (status.isEmpty || status.contains(b['status']))).toList();
        final sorted = stableSorted(rows, (a, b) => b.str('createdAt').compareTo(a.str('createdAt')));
        return pageMap(r, sorted, (b) => {
              'booking': dom.viewBooking(b),
              'target': targetSummary(app, venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
              'halls': hallRefs(app, b),
            });
      },
      'getRequest': (r) {
        final b = ownBooking(app, r);
        final v = app.db.get('Voucher', b.str('voucherId'));
        final conv = app.db.firstWhere('Conversation', (c) => c['bookingId'] == b['id'] && c['kind'] != 'support');
        final review = app.db.firstWhere('Review', (x) => x['_bookingId'] == b['id']);
        r.out['ETag'] = '"v${b['version']}"';
        return {
          'booking': dom.viewBooking(b),
          'halls': hallRefs(app, b),
          'voucher': v == null ? null : asSeen(app, v),
          'target': targetSummary(app, venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
          'confirmWindow': confirmWindowOf(app, b),
          'conversationId': conv?['id'],
          'review': review == null ? null : wire(review),
        };
      },
      'getConfirmWindow': (r) => confirmWindowOf(app, ownBooking(app, r)),
      'confirmRequest': (r) {
        final b = ownBooking(app, r);
        dom.checkIfMatch(r, b);
        return _out(r, dom.confirmRequest(app, b.str('id')));
      },
      'withdrawRequest': (r) {
        final b = ownBooking(app, r);
        dom.checkIfMatch(r, b);
        return _out(r, dom.withdrawRequest(app, b.str('id')));
      },
      'cancelRequest': (r) {
        final b = ownBooking(app, r);
        dom.checkIfMatch(r, b);
        return _out(r, dom.cancelByClient(app, b.str('id'), reason: r.body?.strOrNull('reason')));
      },
      'acceptProposal': (r) {
        final b = ownBooking(app, r);
        dom.checkIfMatch(r, b);
        if (b.objOrNull('proposal')?['id'] != r.p('proposalId')) throw ApiError.notFound('proposal');
        return _out(r, dom.acceptProposal(app, b.str('id'), r.b.integer('optionIndex')));
      },
      'declineProposal': (r) {
        final b = ownBooking(app, r);
        dom.checkIfMatch(r, b);
        if (b.objOrNull('proposal')?['id'] != r.p('proposalId')) throw ApiError.notFound('proposal');
        return _out(r, dom.declineProposal(app, b.str('id')));
      },
      'reportIssue': (r) {
        final b = ownBooking(app, r);
        final completedAt = b.strOrNull('completedAt');
        if (b['status'] != 'completed' || completedAt == null || instantMs(app.now) > instantMs(addHours(completedAt, app.platformConfig.integer('issueReportHours')))) throw dom.conflict(b);
        (b['overlays'] as Map)['issueReported'] = true;
        (b['events'] as List).add({'at': app.now, 'kind': 'overlay', 'from': null, 'to': null, 'actor': 'client', 'actorName': b['clientName'], 'note': {'en': 'Issue reported', 'ar': 'تم الإبلاغ عن مشكلة'}});
        b['version'] = b.list('events').length + 1;
        app.db.put('Booking', b);
        final support = ensureSupportConversation(app, clientId: r.userId);
        appendMessage(app, support.str('id'), from: 'client', senderName: b.str('clientName'), text: {'en': null, 'ar': r.b.str('text')}, origin: 'ar');
        scheduleReplies(app, support.str('id'));
        return _out(r, b);
      },
    };
