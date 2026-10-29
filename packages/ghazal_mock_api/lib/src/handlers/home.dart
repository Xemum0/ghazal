/// home: the composed Discover feed (status card, free-date shelves, categories), the platform configuration and analytics ingestion.
library;

import '../core/app.dart';
import '../core/request.dart';
import '../domain/views.dart';
import '../engine/engine.dart';
import '../engine/discover.dart' as web;

/// The Brief of the Home: the query as sent; with no Brief field in the query, the signed-in couple's wedding profile (the web store starts from
/// `storyBrief()`: the wedding date, the women's guest count, the first audience searched, the areas).
Json _homeBrief(Req r, Json? profile) {
  final areas = r.qList('areaIds');
  final governorates = r.qList('governorateIds');
  final given = r.q('date') != null || r.qInt('guests') != null || r.q('audience') != null || areas.isNotEmpty || governorates.isNotEmpty;
  if (given || profile == null) {
    return {'date': r.q('date'), 'guests': r.qInt('guests'), 'audience': r.q('audience'), 'areaIds': areas, 'governorateIds': governorates}..removeWhere((k, v) => v == null);
  }
  final searching = profile.strings('searching');
  return {
    'date': profile.strOrNull('weddingDate'),
    'guests': (profile.objOrNull('guests')?['women'] as num?)?.toInt(),
    'audience': searching.isEmpty ? null : searching.first,
    'areaIds': profile.strings('areaIds'),
    'governorateIds': profile.strings('governorateIds'),
  }..removeWhere((k, v) => v == null);
}

Json _statusCard(MockApp app, Req r, String? date) {
  Json card(String kind, {Json? target, String? bookingId, String? voucherId, String? visitId, String? deadline}) => {
    'kind': kind,
    'target': target,
    'bookingId': bookingId,
    'voucherId': voucherId,
    'visitId': visitId,
    'deadline': deadline,
  };
  final uid = r.identity?.userId;
  if (uid != null) {
    final bookings = stableSorted(app.db.raw('Booking').where((b) => b['clientId'] == uid), (a, b) => b.str('createdAt').compareTo(a.str('createdAt')));
    Json? firstWith(String status) => bookings.cast<Json?>().firstWhere((b) => b!['status'] == status, orElse: () => null);
    Json tgt(Json b) => targetSummary(app, venueId: b['venueId'] as String?, providerId: b['providerId'] as String?);
    final approved = firstWith('approved');
    if (approved != null) {
      return card(
        'approved',
        target: tgt(approved),
        bookingId: approved.str('id'),
        voucherId: approved.str('voucherId'),
        deadline: approved.strOrNull('confirmBy'),
      );
    }
    final pending = firstWith('pending');
    if (pending != null) {
      return card('pending', target: tgt(pending), bookingId: pending.str('id'), voucherId: pending.str('voucherId'), deadline: pending.strOrNull('respondBy'));
    }
    final visit = stableSorted(
      app.db
          .raw('VisitAppointment')
          .where(
            (v) =>
                v['clientId'] == uid &&
                v['status'] == 'confirmed' &&
                diffDays(app.today(), kuwaitDateOf(v.str('slotStart'))) >= 0 &&
                diffDays(app.today(), kuwaitDateOf(v.str('slotStart'))) <= 7,
          ),
      (a, b) => a.str('slotStart').compareTo(b.str('slotStart')),
    ).cast<Json?>().firstWhere((_) => true, orElse: () => null);
    if (visit != null) {
      return card(
        'visit-soon',
        target: targetSummary(app, venueId: visit.str('venueId')),
        visitId: visit.str('id'),
        deadline: visit.str('slotStart'),
      );
    }
    final confirmed = firstWith('confirmed');
    if (confirmed != null) return card('confirmed', target: tgt(confirmed), bookingId: confirmed.str('id'), voucherId: confirmed.str('voucherId'));
    final voucher = app.db
        .raw('Voucher')
        .cast<Json?>()
        .firstWhere((v) => v!['clientId'] == uid && v['status'] == 'active' && v['kind'] == 'bound', orElse: () => null);
    if (voucher != null) {
      final isVenue = voucher['targetType'] == 'venue';
      return card(
        'voucher-ready',
        target: targetSummary(app, venueId: isVenue ? voucher.str('venueOrProviderId') : null, providerId: isVenue ? null : voucher.str('venueOrProviderId')),
        voucherId: voucher.str('id'),
      );
    }
  }
  return card(date != null ? 'brief-set' : 'no-date');
}

Map<String, Handler> homeHandlers(MockApp app) => {
  'getHome': (r) {
    final uid = r.identity?.userId;
    final profile = uid == null ? null : app.db.peek('WeddingProfile', uid);
    final brief = _homeBrief(r, profile);
    final date = brief['date'] as String?;
    final engine = app.engine();
    final shelves = <Json>[];
    Json item(Json row, [String? at]) => {'row': venueResult(row), 'date': at ?? date};
    final s = web.shelves(engine, brief);
    void shelf(String id, Iterable<Json> rows, {List<String>? dates}) {
      if (rows.isEmpty) return;
      shelves.add({
        'id': id,
        'items': [for (final x in rows.indexed) item(x.$2, dates?[x.$1])],
      });
    }

    // The order of the Home rails and their rules are the web's (data.ts `shelves`): free (needs a date), featured (one card), voucher prices,
    // this week (one card per venue on its soonest free day, `date` is that day), for you, trending, nearby.
    if (date != null) shelf('free', s.free);
    shelf('featured', [if (s.featured != null) s.featured!]);
    shelf('voucher', s.voucher);
    shelf('week', s.week.map((x) => x.row), dates: s.week.map((x) => x.date).toList());
    shelf('recommended', s.recommended);
    shelf('trending', s.trending);
    shelf('nearby', s.nearby);
    final everyone = engine.listVenues(const {}, brief);
    int count(String id) => everyone.where((x) => web.inCategory(x.obj('venue'), x.objOrNull('price'), id)).length;
    final categories = [
      for (final id in const ['luxury-hotels', 'wedding-halls', 'government', 'beach', 'outdoor', 'vip']) {'id': id, 'venueCount': count(id)},
    ];
    final unread = uid == null ? 0 : app.db.raw('Notification').where((n) => n['userId'] == uid && n['read'] != true).length;
    final wedding = profile?.strOrNull('weddingDate');
    return {
      'statusCard': _statusCard(app, r, date),
      'freeCount': date == null ? null : web.freeCount(engine, brief),
      'nearestFreeDates': date == null ? <String>[] : web.nearestFreeDates(engine, brief),
      'shelves': shelves,
      'categories': categories,
      'unreadNotifications': unread,
      'daysToWedding': wedding == null ? null : diffDays(app.today(), wedding),
    };
  },
  'getAppConfig': (r) {
    final meta = app.seed.extra.obj('meta');
    return {
      'serverNow': app.now,
      'timezone': 'Asia/Kuwait',
      'config': app.platformConfig,
      'occasions': meta['occasions'],
      'availabilityWindow': meta['availabilityWindow'],
      'minAppVersion': app.seed.extra.str('minAppVersion'),
      'partnerAppUrl': app.seed.extra.strOrNull('partnerAppUrl'),
    };
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
