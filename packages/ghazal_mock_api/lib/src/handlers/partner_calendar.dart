/// partner-calendar: the claims calendar (bookings, holds, blocks, requested dates), day detail per hall, blocks, soft dates and email sync.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../domain/format.dart';
import '../engine/engine.dart';
import 'common.dart';
import 'partner_common.dart';
import 'partner_requests.dart' show softDatesOf;

const _reasonLabel = {
  'offline_booking': {'en': 'Booked offline', 'ar': 'حجز خارج التطبيق'},
  'maintenance': {'en': 'Maintenance', 'ar': 'صيانة'},
  'private_event': {'en': 'Private event', 'ar': 'مناسبة خاصة'},
  'other': {'en': 'Blocked', 'ar': 'محجوب'},
};

Map<String, Handler> partnerCalendarHandlers(MockApp app) => {
  'getPartnerCalendar': (r) {
    final v = requireVenue(app, r);
    final from = r.q('from')!, to = r.q('to')!;
    if (diffDays(from, to) < 0 || diffDays(from, to) > 120) throw ApiError.validation('/to', 'range_invalid');
    final hallId = r.q('hallId');
    final claims = app.db.raw('CalendarClaim').where((c) => c['venueId'] == v['id'] && (hallId == null || c['hallId'] == hallId)).toList();
    return {
      'venueId': v['id'],
      'from': from,
      'to': to,
      'days': [
        for (final d in datesBetween(from, to)) {'date': d, 'claims': claims.where((c) => c['date'] == d).map(wire).toList()},
      ],
    };
  },
  'getPartnerCalendarDay': (r) {
    final v = requireVenue(app, r);
    final date = r.p('date');
    final engine = app.engine();
    final halls = <Json>[];
    for (final h in v.list('halls')) {
      final day = engine.availabilityFor(v.str('id'), h.str('id'), monthOf(date)).cast<Json?>().firstWhere((x) => x!['date'] == date, orElse: () => null);
      halls.add({
        'hallId': h['id'],
        'state': day?['state'] ?? 'closed',
        'claims': app.db.raw('CalendarClaim').where((c) => c['hallId'] == h['id'] && c['date'] == date).map(wire).toList(),
        'sessions':
            day?['sessions'] ??
            [
              for (final s in h.list('sessions')) {'sessionId': s['id'], 'state': 'closed'},
            ],
      });
    }
    final others = app.db.raw('Booking').where((b) => b['venueId'] == v['id'] && b['status'] == 'pending' && b['eventDate'] == date).length;
    return {'date': date, 'halls': halls, 'otherRequests': others};
  },
  'createCalendarBlocks': (r) {
    app.requirePermission(r, 'calendar:edit');
    final v = requireVenue(app, r);
    final b = r.b;
    final halls = b.strings('hallIds');
    final dates = b.strings('dates');
    for (final h in halls) {
      if (!v.list('halls').any((x) => x['id'] == h)) throw ApiError.validation('/hallIds', 'unknown_hall');
    }
    for (final h in halls) {
      for (final d in dates) {
        if (app.db.raw('CalendarClaim').any((c) => c['hallId'] == h && c['date'] == d && {'booking', 'hold'}.contains(c['kind']))) {
          throw ApiError('SLOT_UNAVAILABLE', params: {'hallId': h, 'eventDate': d});
        }
      }
    }
    final id = 'blk-m${app.db.next('block').toString().padLeft(3, '0')}';
    final reason = b.str('reason');
    final note = b.strOrNull('note');
    final claimIds = <String>[];
    for (final h in halls) {
      for (final d in dates) {
        final cid = 'claim-block-$d-$h';
        claimIds.add(cid);
        app.db.put('CalendarClaim', {
          'id': cid,
          'venueId': v['id'],
          'hallId': h,
          'date': d,
          'kind': 'block',
          'bookingId': null,
          'audience': null,
          'guests': null,
          'clientName': null,
          'blockReason': reason,
          'blockNote': note != null && note.isNotEmpty ? {'en': note, 'ar': note} : _reasonLabel[reason],
          'blockedBy': actorName(r),
          'holdUntil': null,
          'start': null,
          'end': null,
          '_batchId': id,
        });
      }
    }
    final batch = {
      'id': id,
      'hallIds': halls,
      'dates': dates,
      'reason': reason,
      'note': note,
      'createdAt': app.now,
      'createdBy': actorName(r),
      'claimIds': claimIds,
      '_venueId': v['id'],
    };
    app.db.put('BlockBatch', batch);
    return wire(batch);
  },
  'removeCalendarBlockBatch': (r) {
    app.requirePermission(r, 'calendar:edit');
    final v = requireVenue(app, r);
    final batch = app.db.get('BlockBatch', r.p('batchId'));
    if (batch == null || batch['_venueId'] != v['id']) throw ApiError.notFound('block batch');
    for (final c in app.db.raw('CalendarClaim').toList()) {
      if (c['_batchId'] == batch['id']) app.db.remove('CalendarClaim', c.str('id'));
    }
    app.db.remove('BlockBatch', batch.str('id'));
    return null;
  },
  'listCalendarHolds': (r) {
    final v = requireVenue(app, r);
    return stableSorted(
      app.db.raw('CalendarClaim').where((c) => c['venueId'] == v['id'] && c['kind'] == 'hold'),
      (a, b) => a.str('date').compareTo(b.str('date')),
    ).map(wire).toList();
  },
  'getSoftDates': (r) {
    final v = requireVenue(app, r);
    final opt = app.db.peek('SoftDates', v.str('id'))?.strings('optedOut') ?? <String>[];
    final dates = softDatesOf(app, v.str('id'));
    return {'dates': dates, 'optedOut': opt};
  },
  'getCalendarSync': (r) => venueSettings(app, requireVenue(app, r).str('id')).obj('calendarSync'),
  'updateCalendarSync': (r) {
    app.requirePermission(r, 'calendar:edit');
    final id = requireVenue(app, r).str('id');
    final s = venueSettings(app, id);
    s['calendarSync'] = {'channel': 'email', 'address': r.b['address'], 'ics': r.b['ics']};
    saveSettings(app, s);
    return s.obj('calendarSync');
  },
  'sendCalendarIcs': (r) {
    final id = requireVenue(app, r).str('id');
    final sync = venueSettings(app, id).obj('calendarSync');
    final address = sync.strOrNull('address') ?? '';
    if (address.isEmpty) throw ApiError.validation('/address', 'required');
    final count = app.db.raw('CalendarClaim').where((c) => c['venueId'] == id && {'booking', 'hold'}.contains(c['kind'])).length;
    app.outbox.add({
      'at': app.now,
      'to': address,
      'kind': 'calendar_ics',
      'venueId': id,
      'events': count,
      'subject': 'Ghazal calendar ${dateText(app.today(), 'en')}',
    });
    return null;
  },
};
