/// visits: the client side of site visits (dates, slots, booking with the group chat, cancel, reschedule, answering a proposed time).
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/visits.dart' as dom;
import '../domain/views.dart';
import '../engine/engine.dart';

Json _venueForVisits(MockApp app, String id) {
  final v = app.db.peek('Venue', id) ?? (throw ApiError.notFound('venue'));
  final settings = app.db.peek('VenueSettings', id);
  if (v['channel'] == 'external_link' || v.list('visitSlots').isEmpty || settings?.objOrNull('bookingRules')?['visitsEnabled'] == false) {
    throw ApiError('VISIT_NOT_ALLOWED');
  }
  return v;
}

Json ownVisit(MockApp app, Req r) {
  final v = dom.requireVisit(app, r.p('visitId'));
  if (v['clientId'] != r.userId) throw ApiError.notFound('visit');
  return v;
}

Map<String, Handler> visitsHandlers(MockApp app) => {
  'listVisitDates': (r) {
    final id = r.p('venueId');
    _venueForVisits(app, id);
    return {'venueId': id, 'dates': app.engine().visitDatesFor(id, r.qInt('days') ?? 14)};
  },
  'listVisitSlots': (r) {
    final id = r.p('venueId');
    _venueForVisits(app, id);
    return {'venueId': id, 'date': r.q('date'), 'slots': app.engine().visitSlotsFor(id, r.q('date')!)};
  },
  'bookVisit': (r) {
    final visit = dom.bookVisit(app, r.identity!.user, r.b);
    return dom.visitThread(app, visit, partner: false);
  },
  'listVisits': (r) {
    final status = r.qList('status');
    final rows = app.db.raw('VisitAppointment').where((v) => v['clientId'] == r.userId && (status.isEmpty || status.contains(v['status']))).toList();
    final sorted = stableSorted(rows, (a, b) => b.str('slotStart').compareTo(a.str('slotStart')));
    return pageMap(r, sorted, (v) => {'visit': wire(v), 'target': targetSummary(app, venueId: v.str('venueId'))});
  },
  'getVisit': (r) => wire(ownVisit(app, r)),
  'getVisitThread': (r) => dom.visitThread(app, ownVisit(app, r), partner: false),
  'cancelVisit': (r) => wire(dom.cancelVisit(app, ownVisit(app, r).str('id'), r.body?.strOrNull('reason'))),
  'rescheduleVisit': (r) => wire(dom.rescheduleVisit(app, ownVisit(app, r).str('id'), r.b.str('slotStart'))),
  'answerVisitProposal': (r) => wire(dom.answerVisitProposal(app, ownVisit(app, r).str('id'), r.b['accept'] == true)),
};
