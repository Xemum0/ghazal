/// partner-growth: voucher price windows (time-boxed voucher prices) and analytics (tiles, funnel, series; seeded for the hotel, derived from live
/// data otherwise).
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../engine/engine.dart';

Json _ownWindow(MockApp app, Req r) {
  final w = app.db.get('VoucherWindow', r.p('windowId'));
  if (w == null || w['venueId'] != r.ctx.targetId) throw ApiError.notFound('voucher window');
  return w;
}

String _windowStatus(MockApp app, Json w) {
  if (w['status'] == 'ended') return 'ended';
  final ends = w.strOrNull('endsAt');
  if (ends != null && instantMs(app.now) >= instantMs(ends)) return 'ended';
  return instantMs(app.now) < instantMs(w.str('startsAt')) ? 'scheduled' : 'active';
}

Json _windowFrom(MockApp app, Req r, Json input, String id, {Json? existing}) {
  final packages = input.strings('packageIds');
  for (final p in packages) {
    final pkg = app.db.peek('Package', p);
    if (pkg == null || pkg['venueId'] != r.ctx.venueId) throw ApiError.validation('/packageIds', 'unknown_package');
  }
  if (input['voucherPerGuest'] == null && input['voucherFlat'] == null) throw ApiError.validation('/voucherPerGuest', 'required');
  if (input['endsAt'] != null && instantMs(input.str('endsAt')) <= instantMs(input.str('startsAt'))) throw ApiError.validation('/endsAt', 'before_start');
  final w = <String, dynamic>{
    'id': id,
    'venueId': r.ctx.venueId,
    'title': input['title'],
    'packageIds': packages,
    'voucherPerGuest': input['voucherPerGuest'],
    'voucherFlat': input['voucherFlat'],
    'eventFrom': input['eventFrom'],
    'eventTo': input['eventTo'],
    'eventDates': input['eventDates'],
    'eventWeekdays': input['eventWeekdays'],
    'startsAt': input['startsAt'],
    'endsAt': input['endsAt'],
    'status': 'active',
    'vouchersBought': existing?['vouchersBought'] ?? 0,
  };
  w['status'] = _windowStatus(app, w);
  return w;
}

// ---------------------------------------------------------------- analytics

Json _series(String id, String unit, List<String> days, String scope, int base, int spread) => {
      'id': id,
      'unit': unit,
      'points': [for (final d in days) {'date': d, 'value': base + (seeded([id, scope, d]) * spread).floor()}],
    };

Json analyticsFor(MockApp app, String id, {String? from, String? to}) {
  final today = app.today();
  final seedDoc = app.db.peek('Analytics', id);
  final lo = from ?? seedDoc?.obj('window').str('from') ?? addDays(today, -29);
  final hi = to ?? seedDoc?.obj('window').str('to') ?? today;
  if (diffDays(lo, hi) < 0 || diffDays(lo, hi) > 366) throw ApiError.validation('/to', 'range_invalid');
  final days = datesBetween(lo, hi);
  final bookings = app.db.raw('Booking').where((b) => (b['venueId'] == id || b['providerId'] == id) && b.str('createdAt').substring(0, 10).compareTo(lo) >= 0 && b.str('createdAt').substring(0, 10).compareTo(hi) <= 0).toList();
  final vouchers = app.db.raw('Voucher').where((v) => v['venueOrProviderId'] == id && v['kind'] == 'bound').toList();
  Json tiles, funnel;
  List<Json> series;
  List<Json> top;
  if (seedDoc != null) {
    final seedDays = diffDays(seedDoc.obj('window').str('from'), seedDoc.obj('window').str('to')) + 1;
    final k = days.length / seedDays;
    final st = seedDoc.obj('tiles');
    int scale(num v) => jsRound(v * k);
    tiles = {
      'views': {'value': scale(st.obj('views').integer('value')), 'deltaPct': st.obj('views')['deltaPct']},
      'clicks': scale(st.integer('clicks')),
      'requests': scale(st.integer('requests')),
      'approved': scale(st.integer('approved')),
      'confirmed': scale(st.integer('confirmed')),
      'vouchersBought': scale(st.integer('vouchersBought')),
      'vouchersRedeemed': scale(st.integer('vouchersRedeemed')),
      'openDatesNext30Days': st['openDatesNext30Days'],
      'conversionBps': st['conversionBps'],
    };
    if (from == null && to == null) tiles = deepCopy(st);
    final sf = seedDoc.obj('funnel');
    funnel = from == null && to == null ? deepCopy(sf) : {for (final e in sf.entries) e.key: scale(e.value as num)};
    series = [for (final s in seedDoc.list('series')) {...deepCopy(s), 'points': s.list('points').where((p) => p.str('date').compareTo(lo) >= 0 && p.str('date').compareTo(hi) <= 0).toList()}];
    top = seedDoc.list('topPackages');
  } else {
    final requests = bookings.length;
    final approved = bookings.where((b) => b['approvedAt'] != null).length;
    final confirmed = bookings.where((b) => b['confirmedAt'] != null).length;
    final bought = vouchers.where((v) => v['purchasedAt'] != null).length;
    final redeemed = vouchers.where((v) => v['usedReason'] == 'redeemed').length;
    final views = days.length * 38 + requests * 25;
    final clicks = (views / 5).round();
    tiles = {
      'views': {'value': views, 'deltaPct': 4.5},
      'clicks': clicks,
      'requests': requests,
      'approved': approved,
      'confirmed': confirmed,
      'vouchersBought': bought,
      'vouchersRedeemed': redeemed,
      'openDatesNext30Days': 0,
      'conversionBps': clicks == 0 ? 0 : (requests * 10000 / clicks).round(),
    };
    funnel = {'views': views, 'clicks': clicks, 'requests': requests, 'confirmed': confirmed, 'redeemed': redeemed};
    series = [
      _series('views', 'count', days, id, 20, 60),
      _series('clicks', 'count', days, id, 4, 14),
      _series('requests', 'count', days, id, 0, 3),
      _series('vouchers_bought', 'count', days, id, 0, 3),
      _series('vouchers_redeemed', 'count', days, id, 0, 2),
      _series('conversion', 'percent', days, id, 1, 5),
    ];
    final counts = <String, int>{};
    for (final b in bookings.where((b) => b['confirmedAt'] != null)) {
      final pk = b.list('sections').isEmpty ? (b.objOrNull('service')?['packageId'] as String?) : b.list('sections').first.strOrNull('packageId');
      if (pk != null) counts[pk] = (counts[pk] ?? 0) + 1;
    }
    top = [for (final e in (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))) {'packageId': e.key, 'confirmed': e.value}];
  }
  final custom = from != null || to != null;
  return {
    'venueId': id,
    'range': {'from': lo, 'to': hi, 'label': custom ? {'en': 'Custom range', 'ar': 'فترة مخصصة'} : (seedDoc?['range'] as Json?)?['label'] ?? {'en': 'Last 30 days', 'ar': 'آخر 30 يومًا'}},
    'window': {'from': lo, 'to': hi},
    'tiles': tiles,
    'funnel': funnel,
    'topPackages': top,
    'series': series,
  };
}

Map<String, Handler> partnerGrowthHandlers(MockApp app) => {
      'listVoucherWindows': (r) {
        final status = r.qList('status');
        final rows = [for (final w in app.db.raw('VoucherWindow')) if (w['venueId'] == r.ctx.targetId) {...deepCopy(w), 'status': _windowStatus(app, w)}];
        final filtered = rows.where((w) => status.isEmpty || status.contains(w['status'])).toList();
        return {'windows': stableSorted(filtered, (a, b) => b.str('startsAt').compareTo(a.str('startsAt')))};
      },
      'createVoucherWindow': (r) {
        app.requirePermission(r, 'windows:manage');
        final w = _windowFrom(app, r, r.b, 'vw-m${app.db.next('window').toString().padLeft(3, '0')}');
        app.db.put('VoucherWindow', w);
        return w;
      },
      'updateVoucherWindow': (r) {
        app.requirePermission(r, 'windows:manage');
        final existing = _ownWindow(app, r);
        if (_windowStatus(app, existing) == 'ended') throw ApiError('LISTING_STATE_CONFLICT', detail: 'the window already ended');
        final w = _windowFrom(app, r, r.b, existing.str('id'), existing: existing);
        app.db.put('VoucherWindow', w);
        return w;
      },
      'endVoucherWindow': (r) {
        app.requirePermission(r, 'windows:manage');
        final w = _ownWindow(app, r);
        w['status'] = 'ended';
        w['endsAt'] = app.now;
        app.db.put('VoucherWindow', w);
        return w;
      },
      'getPartnerAnalytics': (r) => analyticsFor(app, r.ctx.targetId, from: r.q('from'), to: r.q('to')),
      'getListingPerformance': (r) {
        final l = app.db.get('Listing', r.p('listingId'));
        if (l == null || l['partnerAccountId'] != r.ctx.accountId) throw ApiError.notFound('listing');
        final a = analyticsFor(app, l.str('providerId'), from: r.q('from'), to: r.q('to'));
        return {'listingId': l['id'], 'range': a['range'], 'tiles': a['tiles'], 'funnel': a['funnel'], 'series': a['series']};
      },
    };
