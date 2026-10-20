/// partner-visits (confirm, decline, propose, arrival, weekly availability) and partner-growth (voucher price windows, analytics).
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../domain/views.dart';
import '../domain/visits.dart' as dom;
import '../engine/engine.dart';
import 'common.dart';
import 'partner_common.dart';

Json _ownVisit(MockApp app, Req r) {
  final v = dom.requireVisit(app, r.p('visitId'));
  if (v['venueId'] != requireVenue(app, r)['id']) throw ApiError.notFound('visit');
  return v;
}

Map<String, Handler> partnerVisitsHandlers(MockApp app) => {
      'listPartnerVisits': (r) {
        final venue = requireVenue(app, r);
        final status = r.qList('status');
        final rows = app.db.raw('VisitAppointment').where((v) => v['venueId'] == venue['id'] && (status.isEmpty || status.contains(v['status']))).toList();
        return pageMap(r, stableSorted(rows, (a, b) => b.str('slotStart').compareTo(a.str('slotStart'))), wire);
      },
      'getPartnerVisit': (r) => wire(_ownVisit(app, r)),
      'getPartnerVisitThread': (r) => dom.visitThread(app, _ownVisit(app, r), partner: true),
      'confirmVisit': (r) {
        app.requirePermission(r, 'visit:manage');
        return wire(dom.confirmVisit(app, _ownVisit(app, r).str('id'), actorName(r)));
      },
      'declineVisit': (r) {
        app.requirePermission(r, 'visit:manage');
        return wire(dom.declineVisit(app, _ownVisit(app, r).str('id'), actorName(r), r.body?.strOrNull('reason')));
      },
      'proposeVisitSlot': (r) {
        app.requirePermission(r, 'visit:manage');
        return wire(dom.proposeVisitSlot(app, _ownVisit(app, r).str('id'), actorName(r), r.b.str('slotStart')));
      },
      'markVisitArrived': (r) {
        app.requirePermission(r, 'visit:manage');
        return wire(dom.markVisit(app, _ownVisit(app, r).str('id'), actorName(r), arrived: true));
      },
      'markVisitMissed': (r) {
        app.requirePermission(r, 'visit:manage');
        return wire(dom.markVisit(app, _ownVisit(app, r).str('id'), actorName(r), arrived: false));
      },
      'getVisitAvailability': (r) {
        final v = requireVenue(app, r);
        return {'enabled': venueSettings(app, v.str('id')).obj('bookingRules')['visitsEnabled'] != false && v.list('visitSlots').isNotEmpty, 'rules': v['visitSlots']};
      },
      'putVisitAvailability': (r) {
        app.requirePermission(r, 'visit:manage');
        final v = requireVenue(app, r);
        v['visitSlots'] = r.b['rules'];
        app.db.put('Venue', v);
        final s = venueSettings(app, v.str('id'));
        final rules = s.obj('bookingRules');
        rules['visitsEnabled'] = r.b['enabled'] == true;
        s['bookingRules'] = rules;
        saveSettings(app, s);
        return {'enabled': r.b['enabled'] == true, 'rules': r.b['rules']};
      },
    };
