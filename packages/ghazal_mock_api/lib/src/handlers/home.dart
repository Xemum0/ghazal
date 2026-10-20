/// home: the composed Discover feed (status card, free-date shelves, categories), the platform configuration and analytics ingestion.
library;

import '../core/app.dart';
import '../core/request.dart';
import '../domain/views.dart';
import '../engine/engine.dart';

Json _homeBrief(Req r, Json? profile) => {
      'date': r.q('date') ?? profile?.strOrNull('weddingDate'),
      'guests': r.qInt('guests'),
      'audience': r.q('audience'),
      'areaIds': r.qList('areaIds').isNotEmpty ? r.qList('areaIds') : (profile?.strings('areaIds') ?? const <String>[]),
    }..removeWhere((k, v) => v == null);

Json _statusCard(MockApp app, Req r, String? date) {
  Json card(String kind, {Json? target, String? bookingId, String? voucherId, String? visitId, String? deadline}) => {'kind': kind, 'target': target, 'bookingId': bookingId, 'voucherId': voucherId, 'visitId': visitId, 'deadline': deadline};
  final uid = r.identity?.userId;
  if (uid != null) {
    final bookings = stableSorted(app.db.raw('Booking').where((b) => b['clientId'] == uid), (a, b) => b.str('createdAt').compareTo(a.str('createdAt')));
    Json? firstWith(String status) => bookings.cast<Json?>().firstWhere((b) => b!['status'] == status, orElse: () => null);
    Json tgt(Json b) => targetSummary(app, venueId: b['venueId'] as String?, providerId: b['providerId'] as String?);
    final approved = firstWith('approved');
    if (approved != null) return card('approved', target: tgt(approved), bookingId: approved.str('id'), voucherId: approved.str('voucherId'), deadline: approved.strOrNull('confirmBy'));
    final pending = firstWith('pending');
    if (pending != null) return card('pending', target: tgt(pending), bookingId: pending.str('id'), voucherId: pending.str('voucherId'), deadline: pending.strOrNull('respondBy'));
    final visit = stableSorted(app.db.raw('VisitAppointment').where((v) => v['clientId'] == uid && v['status'] == 'confirmed' && diffDays(app.today(), kuwaitDateOf(v.str('slotStart'))) >= 0 && diffDays(app.today(), kuwaitDateOf(v.str('slotStart'))) <= 7), (a, b) => a.str('slotStart').compareTo(b.str('slotStart'))).cast<Json?>().firstWhere((_) => true, orElse: () => null);
    if (visit != null) return card('visit-soon', target: targetSummary(app, venueId: visit.str('venueId')), visitId: visit.str('id'), deadline: visit.str('slotStart'));
    final confirmed = firstWith('confirmed');
    if (confirmed != null) return card('confirmed', target: tgt(confirmed), bookingId: confirmed.str('id'), voucherId: confirmed.str('voucherId'));
    final voucher = app.db.raw('Voucher').cast<Json?>().firstWhere((v) => v!['clientId'] == uid && v['status'] == 'active' && v['kind'] == 'bound', orElse: () => null);
    if (voucher != null) {
      final isVenue = voucher['targetType'] == 'venue';
      return card('voucher-ready', target: targetSummary(app, venueId: isVenue ? voucher.str('venueOrProviderId') : null, providerId: isVenue ? null : voucher.str('venueOrProviderId')), voucherId: voucher.str('id'));
    }
  }
  return card(date != null ? 'brief-set' : 'no-date');
}

/// Up to three dates from [date] on where at least one venue has a free hall (month tables are computed once per hall).
List<String> _nearestFree(MockApp app, String date, Json brief) {
  final engine = app.engine();
  final start = diffDays(app.today(), date) < minLeadDays ? addDays(app.today(), minLeadDays) : date;
  final candidates = datesBetween(addDays(start, -10).compareTo(addDays(app.today(), minLeadDays)) < 0 ? addDays(app.today(), minLeadDays) : addDays(start, -10), addDays(start, 21));
  final free = <String>{};
  final cache = <String, List<Json>>{};
  for (final v in engine.venues) {
    if (v['channel'] == 'external_link') continue;
    for (final h in v.list('halls')) {
      for (final d in candidates) {
        final key = '${h['id']}|${monthOf(d)}';
        final days = cache[key] ??= engine.availabilityFor(v.str('id'), h.str('id'), monthOf(d), brief);
        final day = days.cast<Json?>().firstWhere((x) => x!['date'] == d, orElse: () => null);
        if (day != null && day['state'] == 'available') free.add(d);
      }
    }
  }
  final sorted = free.toList()..sort((a, b) => (diffDays(date, a).abs() - diffDays(date, b).abs()) != 0 ? diffDays(date, a).abs() - diffDays(date, b).abs() : a.compareTo(b));
  return (sorted.take(3).toList()..sort());
}

Map<String, Handler> homeHandlers(MockApp app) => {
      'getHome': (r) {
        final uid = r.identity?.userId;
        final profile = uid == null ? null : app.db.peek('WeddingProfile', uid);
        final brief = _homeBrief(r, profile);
        final date = brief['date'] as String?;
        final engine = app.engine();
        final shelves = <Json>[];
        Json item(Json row) => {'row': venueResult(row), 'date': date};
        final all = engine.listVenues({}, brief);
        int? freeCount;
        if (date != null) {
          final free = engine.listVenues({'availableOnDate': true}, brief);
          freeCount = free.length;
          if (free.isNotEmpty) shelves.add({'id': 'free', 'items': free.take(10).map(item).toList()});
        }
        final featured = all.where((x) => x.obj('venue').obj('flags').flag('featured')).take(10).toList();
        if (featured.isNotEmpty) shelves.add({'id': 'featured', 'items': featured.map(item).toList()});
        final voucher = all.where((x) => x['windowId'] != null || engine.activeWindows().any((w) => w['venueId'] == x.obj('venue')['id'])).take(10).toList();
        if (voucher.isNotEmpty) shelves.add({'id': 'voucher', 'items': voucher.map(item).toList()});
        shelves.add({'id': 'recommended', 'items': all.take(10).map(item).toList()});
        final trending = stableSorted(all, (a, b) => b.obj('venue').obj('rating').integer('count') - a.obj('venue').obj('rating').integer('count')).take(10).toList();
        shelves.add({'id': 'trending', 'items': trending.map(item).toList()});
        final areas = (brief['areaIds'] as List?)?.cast<String>() ?? const <String>[];
        if (areas.isNotEmpty) {
          final near = engine.listVenues({'sort': 'distance'}, brief);
          shelves.add({'id': 'nearby', 'items': near.take(10).map(item).toList()});
        }
        int count(bool Function(Json v) test) => engine.venues.where(test).length;
        final categories = [
          {'id': 'luxury-hotels', 'venueCount': count((v) => v['type'] == 'hotel')},
          {'id': 'wedding-halls', 'venueCount': count((v) => v['type'] == 'private-hall')},
          {'id': 'government', 'venueCount': count((v) => v['type'] == 'governmental')},
          {'id': 'beach', 'venueCount': count((v) => v['style'] == 'resort' || v.obj('name')['en'].toString().toLowerCase().contains('beach'))},
          {'id': 'outdoor', 'venueCount': count((v) => v['style'] == 'outdoor' || v['style'] == 'villa')},
          {'id': 'vip', 'venueCount': count((v) => v['tier'] == 'prestige')},
        ];
        final unread = uid == null ? 0 : app.db.raw('Notification').where((n) => n['userId'] == uid && n['read'] != true).length;
        final wedding = profile?.strOrNull('weddingDate');
        return {
          'statusCard': _statusCard(app, r, date),
          'freeCount': freeCount,
          'nearestFreeDates': date == null ? <String>[] : _nearestFree(app, date, {...brief}..remove('date')),
          'shelves': shelves,
          'categories': categories,
          'unreadNotifications': unread,
          'daysToWedding': wedding == null ? null : diffDays(app.today(), wedding),
        };
      },
      'getAppConfig': (r) {
        final meta = app.seed.extra.obj('meta');
        return {'serverNow': app.now, 'timezone': 'Asia/Kuwait', 'config': app.platformConfig, 'occasions': meta['occasions'], 'availabilityWindow': meta['availabilityWindow'], 'minAppVersion': app.seed.extra.str('minAppVersion')};
      },
      'ingestEvents': (r) {
        final events = r.b.list('events');
        final rejected = <Json>[];
        var accepted = 0;
        for (final e in events) {
          final name = e.strOrNull('name') ?? '';
          if (name.isEmpty || !RegExp(r'^[a-z0-9_.]+$').hasMatch(name)) {
            rejected.add({'eventId': e['eventId'], 'code': 'invalid_name'});
          } else {
            accepted++;
            app.logEvent('analytics', {'name': name, 'eventId': e['eventId'], 'userId': r.identity?.userId});
          }
        }
        return {'accepted': accepted, 'rejected': rejected};
      },
    };
