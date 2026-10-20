/// partner-requests and partner-bookings: Today and Needs you, the request inbox, approve (with the 8 s undo), decline, counter-offer, revoke,
/// cancel, and voucher redemption by code. The rules live in `domain/requests.dart`.
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/format.dart';
import '../domain/requests.dart' as dom;
import '../domain/views.dart';
import '../engine/engine.dart';
import 'common.dart';
import 'partner_common.dart';

Json _sla(MockApp app, Json booking) {
  final due = booking.strOrNull('respondBy');
  return due == null ? {} : slaReading(booking.str('createdAt'), due, app.now, goldPct: app.platformConfig.integer('slaGoldPct'), dangerPct: app.platformConfig.integer('slaDangerPct'));
}

int _otherSameDate(MockApp app, Json b) => app.db.raw('Booking').where((x) => x['id'] != b['id'] && x['status'] == 'pending' && x['eventDate'] == b['eventDate'] && (b['venueId'] != null ? x['venueId'] == b['venueId'] : x['providerId'] == b['providerId'])).length;

Json _row(MockApp app, Json b) {
  final v = app.db.peek('Voucher', b.str('voucherId'));
  return {
    'booking': dom.viewBooking(b, role: 'partner'),
    'halls': hallRefs(app, b),
    'voucher': v == null ? null : wire(v),
    'sla': b['status'] == 'pending' ? _sla(app, b) : null,
    'otherRequestsSameDate': _otherSameDate(app, b),
  };
}

String _clientLT(Json b) => b.str('clientName');

/// The Needs-you queue computed from live data (requests, awaiting-client countdowns, visits, unanswered messages, reviews, the calendar nudge).
List<Json> needsYou(MockApp app, Req r) {
  final c = r.ctx;
  final items = <Json>[];
  Json item({required String id, required String type, required String raisedAt, String? dueAt, int? slaHours, String? bookingId, String? conversationId, String? reviewId, String? visitId, String? voucherId, String? voucherCode, required Json title, Json? subtitle, required int order}) => {
        'id': id, 'type': type, 'venueId': c.targetId, 'raisedAt': raisedAt, 'dueAt': dueAt, 'slaHours': slaHours, 'bookingId': bookingId, 'conversationId': conversationId, 'reviewId': reviewId, 'visitId': visitId, 'voucherId': voucherId, 'voucherCode': voucherCode, 'title': title, 'subtitle': subtitle, 'order': order,
      };
  var order = 10;
  for (final b in ctxBookings(app, r)) {
    final v = app.db.peek('Voucher', b.str('voucherId'));
    if (b['status'] == 'pending') {
      items.add(item(id: 'triage-${b['ref']}', type: 'request', raisedAt: b.str('createdAt'), dueAt: b.strOrNull('respondBy'), slaHours: b.intOrNull('slaHours'), bookingId: b.str('id'), voucherId: b.str('voucherId'), voucherCode: v?.strOrNull('code'), title: {'en': _clientLT(b), 'ar': _clientLT(b)}, order: order++));
    } else if (b['status'] == 'approved') {
      items.add(item(id: 'triage-await-${b['ref']}', type: 'awaiting_client', raisedAt: b.strOrNull('approvedAt') ?? b.str('createdAt'), dueAt: b.strOrNull('confirmBy'), slaHours: 24, bookingId: b.str('id'), voucherId: b.str('voucherId'), voucherCode: v?.strOrNull('code'), title: {'en': 'Waiting for ${_clientLT(b)} to confirm', 'ar': 'بانتظار تأكيد ${_clientLT(b)}'}, subtitle: {'en': '${dateText(b.str('eventDate'), 'en')} · the client confirms within 24 hours', 'ar': '${dateText(b.str('eventDate'), 'ar')} · يؤكد العميل خلال 24 ساعة'}, order: 20 + order++));
    }
  }
  if (c.venueId != null) {
    for (final v in app.db.raw('VisitAppointment')) {
      if (v['venueId'] == c.venueId && v['status'] == 'requested') {
        items.add(item(id: 'triage-visit-${v['id']}', type: 'visit_request', raisedAt: v.str('requestedAt'), conversationId: v.str('conversationId'), visitId: v.str('id'), title: {'en': 'Visit request · ${v['clientName']}', 'ar': 'طلب زيارة · ${v['clientName']}'}, subtitle: {'en': '${dateText(kuwaitDateOf(v.str('slotStart')), 'en')} · ${v['visitors']} visitors', 'ar': '${dateText(kuwaitDateOf(v.str('slotStart')), 'ar')} · ${v['visitors']} زائرين'}, order: 35));
      }
    }
  }
  for (final cv in app.db.raw('Conversation')) {
    final mine = c.venueId != null ? cv['venueId'] == c.venueId : cv['vendorId'] == c.providerId;
    if (mine && cv['awaitingReplySince'] != null && {'venue', 'enquiry', 'vendor'}.contains(cv['kind'])) {
      items.add(item(id: 'triage-msg-${cv['id']}', type: 'message', raisedAt: cv.str('awaitingReplySince'), conversationId: cv.str('id'), bookingId: cv.strOrNull('bookingId'), title: {'en': 'Unanswered message · ${cv['clientName']}', 'ar': 'رسالة بانتظار الرد · ${cv['clientName']}'}, order: 30));
    }
  }
  if (c.venueId != null) {
    for (final rv in app.db.raw('Review')) {
      if (rv['venueId'] == c.venueId && rv['ownerReply'] == null && diffDays(kuwaitDateOf(rv.str('postedAt')), app.today()) >= 7) {
        final a = rv.obj('author');
        items.add(item(id: 'triage-review-${rv['id']}', type: 'review_reply', raisedAt: rv.str('postedAt'), reviewId: rv.str('id'), title: {'en': 'Review awaiting a reply · ${a['en']}', 'ar': 'تقييم بانتظار الرد · ${a['ar']}'}, subtitle: {'en': '${rv['rating']} stars · posted ${diffDays(kuwaitDateOf(rv.str('postedAt')), app.today())} days ago', 'ar': '${rv['rating']} نجوم · نُشر قبل ${diffDays(kuwaitDateOf(rv.str('postedAt')), app.today())} يومًا'}, order: 40));
      }
    }
    for (final seeded in app.seed.rows('RequestItem')) {
      if (seeded['venueId'] == c.venueId && seeded['type'] == 'calendar_confirm') items.add({...seeded});
    }
  }
  final goldPct = app.platformConfig.integer('slaGoldPct'), dangerPct = app.platformConfig.integer('slaDangerPct');
  final rows = [for (final i in items) {'item': i, 'sla': i['dueAt'] == null ? null : slaReading(i.str('raisedAt'), i.str('dueAt'), app.now, goldPct: goldPct, dangerPct: dangerPct)}];
  return stableSorted(rows, (a, b) {
    final sa = a['sla'] as Json?, sb = b['sla'] as Json?;
    if (sa != null && sb != null) return sa.integer('minutesLeft') - sb.integer('minutesLeft');
    if (sa != null) return -1;
    if (sb != null) return 1;
    return a.obj('item').integer('order') - b.obj('item').integer('order');
  });
}

Json _out(Req r, Json b) {
  r.out['ETag'] = '"v${b['version']}"';
  return dom.viewBooking(b, role: 'partner');
}

Map<String, Handler> partnerRequestsHandlers(MockApp app) => {
      'getPartnerToday': (r) {
        final c = r.ctx;
        final bookings = ctxBookings(app, r);
        final pending = bookings.where((b) => b['status'] == 'pending').length;
        final awaiting = bookings.where((b) => b['status'] == 'approved').length;
        final month = app.today().substring(0, 7);
        final vouchers = app.db.raw('Voucher').where((v) => v['venueOrProviderId'] == c.targetId && v['kind'] == 'bound').toList();
        final bought = vouchers.where((v) => v['purchasedAt'] != null && (v.str('purchasedAt')).startsWith(month)).length;
        final redeemed = vouchers.where((v) => v['usedReason'] == 'redeemed' && (v.strOrNull('usedAt') ?? '').startsWith(month)).length;
        var open = 0;
        if (c.venueId != null) {
          final engine = app.engine();
          final v = app.db.peek('Venue', c.venueId!)!;
          if (v['channel'] != 'external_link') {
            final months = {monthOf(app.today()), monthOf(addDays(app.today(), 30))};
            final free = <String>{};
            for (final h in v.list('halls')) {
              for (final m in months) {
                for (final d in engine.availabilityFor(c.venueId!, h.str('id'), m)) {
                  if (d['state'] == 'available' && diffDays(app.today(), d.str('date')) <= 30) free.add(d.str('date'));
                }
              }
            }
            open = free.length;
          }
        }
        final soft = c.venueId == null ? 0 : _soft(app, c.venueId!).length;
        final unread = app.db.raw('Conversation').where((x) => (c.venueId != null ? x['venueId'] == c.venueId : x['vendorId'] == c.providerId)).fold<int>(0, (s, x) => s + x.obj('unread').integer('hotel'));
        final events = stableSorted(bookings.where((b) => {'confirmed', 'redeemed'}.contains(b['status']) && diffDays(app.today(), b.str('eventDate')) >= 0 && diffDays(app.today(), b.str('eventDate')) <= 30), (a, b) => a.str('eventDate').compareTo(b.str('eventDate')));
        final listings = c.providerId == null ? null : app.db.raw('Listing').where((l) => l['providerId'] == c.providerId && l['status'] == 'active').length;
        return {
          'tiles': {'requests': pending, 'awaitingClient': awaiting, 'vouchersRedeemed': redeemed, 'vouchersBought': bought, 'openDatesNext30Days': open, 'softDateCount': soft, 'unreadMessages': unread},
          'needsYou': needsYou(app, r),
          'events': events.take(10).map((b) => _row(app, b)).toList(),
          'activeListings': listings,
        };
      },
      'listNeedsYou': (r) => needsYou(app, r),
      'listPartnerRequests': (r) {
        final seg = r.q('segment')!;
        final all = ctxBookings(app, r);
        bool upcoming(Json b) => {'confirmed', 'redeemed'}.contains(b['status']) && b.str('eventDate').compareTo(app.today()) >= 0;
        var rows = switch (seg) {
          'pending' => all.where((b) => b['status'] == 'pending').toList(),
          'awaiting_client' => all.where((b) => b['status'] == 'approved').toList(),
          'upcoming' => all.where(upcoming).toList(),
          _ => all.where((b) => !{'pending', 'approved'}.contains(b['status']) && !upcoming(b)).toList(),
        };
        rows = stableSorted(rows, (a, b) {
          switch (seg) {
            case 'pending':
              return (a.strOrNull('respondBy') ?? '').compareTo(b.strOrNull('respondBy') ?? '');
            case 'awaiting_client':
              return (a.strOrNull('confirmBy') ?? '').compareTo(b.strOrNull('confirmBy') ?? '');
            case 'upcoming':
              return a.str('eventDate').compareTo(b.str('eventDate'));
            default:
              return b.str('createdAt').compareTo(a.str('createdAt'));
          }
        });
        return pageMap(r, rows, (b) => _row(app, b));
      },
      'getPartnerRequest': (r) {
        final b = ctxBooking(app, r);
        final v = app.db.peek('Voucher', b.str('voucherId'));
        final conv = app.db.firstWhere('Conversation', (c) => c['bookingId'] == b['id'] && c['kind'] != 'support');
        final contact = b.obj('contact');
        r.out['ETag'] = '"v${b['version']}"';
        return {
          'booking': dom.viewBooking(b, role: 'partner'),
          'halls': hallRefs(app, b),
          'voucher': v == null ? null : wire(v),
          'target': targetSummary(app, venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
          'client': {'name': contact['name'], 'phone': contact['shared'] == true ? contact['phone'] : null, 'shared': contact['shared'], 'bookingFor': contact['bookingFor']},
          'sla': b['status'] == 'pending' ? _sla(app, b) : null,
          'otherRequestsSameDate': _otherSameDate(app, b),
          'conversationId': conv?['id'],
        };
      },
      'acceptRequest': (r) {
        app.requirePermission(r, 'request:respond');
        final b = ctxBooking(app, r);
        dom.checkIfMatch(r, b);
        final lower = r.body?.objOrNull('lowerVoucherTotal');
        return _out(r, dom.approveRequest(app, b.str('id'), actorName: actorName(r), lowerVoucherTotal: lower == null ? null : filsOf(lower)));
      },
      'undoAcceptRequest': (r) {
        app.requirePermission(r, 'request:respond');
        final b = ctxBooking(app, r);
        return _out(r, dom.undoApprove(app, b.str('id'), actorName: actorName(r)));
      },
      'declineRequest': (r) {
        app.requirePermission(r, 'request:respond');
        final b = ctxBooking(app, r);
        dom.checkIfMatch(r, b);
        return _out(r, dom.declineRequest(app, b.str('id'), actorName: actorName(r), reason: r.b.str('reason'), note: r.b.strOrNull('note')));
      },
      'proposeDates': (r) {
        app.requirePermission(r, 'request:respond');
        final b = ctxBooking(app, r);
        dom.checkIfMatch(r, b);
        final options = r.b.list('options');
        if (options.isEmpty || options.length > 3) throw ApiError.validation('/options', 'one_to_three');
        return _out(r, dom.proposeDates(app, b.str('id'), options, actorName: actorName(r)));
      },
      'revokeApproval': (r) {
        app.requirePermission(r, 'request:respond');
        final b = ctxBooking(app, r);
        dom.checkIfMatch(r, b);
        return _out(r, dom.revokeApproval(app, b.str('id'), actorName: actorName(r), reason: r.b.str('reason'), note: r.b.strOrNull('note')));
      },
      'cancelConfirmedRequest': (r) {
        app.requirePermission(r, 'request:respond');
        final b = ctxBooking(app, r);
        dom.checkIfMatch(r, b);
        return _out(r, dom.cancelConfirmedByVenue(app, b.str('id'), actorName: actorName(r), reason: r.b.str('reason'), note: r.b.strOrNull('note')));
      },
    };

/// Soft dates: Thu-Sat dates in the next 60 days the venue is offering (seeded for the hotel, computed from free weekend nights otherwise).
List<String> _soft(MockApp app, String venueId) {
  final settings = app.db.peek('SoftDates', venueId);
  if (settings != null) return settings.strings('dates');
  final v = app.db.peek('Venue', venueId);
  if (v == null || v['channel'] == 'external_link') return [];
  final engine = app.engine();
  final out = <String>[];
  final cache = <String, List<Json>>{};
  final optedOut = <String>[];
  for (final d in datesBetween(app.today(), addDays(app.today(), 60))) {
    final wd = weekdayOf(d);
    if (wd != 4 && wd != 5 && wd != 6) continue;
    if (optedOut.contains(d)) continue;
    final allFree = v.list('halls').every((h) {
      final days = cache['${h['id']}|${monthOf(d)}'] ??= engine.availabilityFor(venueId, h.str('id'), monthOf(d));
      return days.cast<Json?>().firstWhere((x) => x!['date'] == d, orElse: () => null)?['state'] == 'available';
    });
    if (allFree) out.add(d);
    if (out.length >= 6) break;
  }
  return out;
}

List<String> softDatesOf(MockApp app, String venueId) => _soft(app, venueId);
