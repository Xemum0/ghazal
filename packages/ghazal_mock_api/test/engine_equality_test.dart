// The Dart engine against the TypeScript engine: packages/contracts/fixtures/engine-cases.json holds inputs and outputs produced by the real
// TS code (tools/export-engine-cases.mjs); every case must come out identical here.
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart';

import 'support.dart';

Object? slimVenues(Object? v) {
  if (v is List) return v.map(slimVenues).toList();
  if (v is Map) {
    return {for (final e in v.entries) e.key: e.key == 'venue' && e.value is Map && (e.value as Map).containsKey('halls') ? (e.value as Map<String, dynamic>)['id'] : slimVenues(e.value)};
  }
  return v;
}

void expectSame(Object? actual, Object? expected, String what) {
  final d = jsonDiff(actual, expected);
  if (d != null) fail('$what differs at $d');
}

final Map<String, Function> pure = {
  'weekdayOf': weekdayOf,
  'epochDay': epochDay,
  'monthOf': monthOf,
  'monthNumber': monthNumber,
  'addDays': addDays,
  'diffDays': diffDays,
  'endOfMonth': endOfMonth,
  'startOfMonth': startOfMonth,
  'datesInMonth': datesInMonth,
  'addMonths': addMonths,
  'datesBetween': datesBetween,
  'instantMs': instantMs,
  'kuwaitDateOf': kuwaitDateOf,
  'kuwaitTimeOf': kuwaitTimeOf,
  'addHours': addHours,
  'addMinutes': addMinutes,
  'diffMinutes': diffMinutes,
  'atTime': atTime,
  'toKuwaitInstant': toKuwaitInstant,
  'hash32': (List<dynamic> a) => hash32(a.cast<Object>()),
  'seeded': (List<dynamic> a) => seeded(a.cast<Object>()),
  'normalizeSearch': normalizeSearch,
  'releaseOutcome': (String r) {
    final o = releaseOutcome(r);
    return {'reusable': o.reusable, 'creditEligible': o.creditEligible};
  },
  'voucherStatusAfter': voucherStatusAfter,
  'voucherValidUntil': (String p, String e, Map<String, dynamic> c) => voucherValidUntil(p, e, voucherValidityDays: c['voucherValidityDays'] as int, completionDelayHours: c['completionDelayHours'] as int),
  'voucherReuseUntil': (String p, Map<String, dynamic> c) => voucherReuseUntil(p, voucherReuseDays: c['voucherReuseDays'] as int),
  'creditVoucherValidUntil': (String p, Map<String, dynamic> c) => creditVoucherValidUntil(p, creditVoucherValidityDays: c['creditVoucherValidityDays'] as int),
  'confirmByFor': (String p, Map<String, dynamic> c) => confirmByFor(p, confirmWindowHours: c['confirmWindowHours'] as int),
  'daysLeft': daysLeft,
  'isVoucherExpired': isVoucherExpired,
  'crockford4': (List<dynamic> a) => crockford4(a.cast<Object>()),
  'voucherCode': (String at, List<dynamic> a) => voucherCode(at, a.cast<Object>()),
  'qrPayload': qrPayload,
  'voucherDiscountBps': (String id, Map<String, dynamic> b) => voucherDiscountBps(id, min: b['min'] as int, max: b['max'] as int),
  'voucherPrice': (int std, int bps, int step, Map<String, dynamic> b) => voucherPrice(std, bps, step, min: b['min'] as int, max: b['max'] as int),
  'discountBps': discountBps,
  'voucherPaysForItself': voucherPaysForItself,
};

void main() {
  late Json cases;
  late EngineData data;

  setUpAll(() async {
    cases = readJson('packages/contracts/fixtures/engine-cases.json').obj('cases');
    data = (await loadSeed()).engineData();
  });

  group('pure functions equal the TypeScript engine', () {
    for (final suite in ['dates', 'seeded', 'text', 'voucher']) {
      test(suite, () {
        final list = (cases[suite] as List<dynamic>).cast<Map<String, dynamic>>();
        expect(list, isNotEmpty);
        for (final c in list) {
          final fn = pure[c['fn']] ?? (throw StateError('no Dart twin for ${c['fn']}'));
          final out = Function.apply(fn, (c['args'] as List<dynamic>).map((e) => e is List<dynamic> ? List<dynamic>.from(e) : e).toList());
          expectSame(out, c['out'], '${c['fn']}(${c['args']})');
        }
      });
    }
  });

  test('transition table, matrix and voucher status', () {
    final t = cases.obj('transitions');
    expectSame(transitions.map((x) => x.toJson()).toList(), t['table'], 'TRANSITIONS');
    expectSame(terminalStatuses, t['terminal'], 'TERMINAL');
    expectSame(openStatuses, t['open'], 'OPEN_STATUSES');
    for (final c in (t['canTransition'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      expect(canTransition(c['from'] as String?, c['to'] as String), c['out'], reason: '${c['from']} -> ${c['to']}');
    }
    for (final c in (t['transitionsFrom'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      expectSame(transitionsFrom(c['from'] as String?).map((x) => x.id).toList(), c['out'], 'transitionsFrom ${c['from']}');
    }
    for (final c in (t['voucherStatusFor'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      expect(voucherStatusFor(c['status'] as String), c['out']);
    }
  });

  test('SLA readings', () {
    final list = (cases['sla'] as List).cast<Json>();
    expect(list.length, greaterThan(50));
    for (final c in list) {
      expectSame(slaReading(c.str('raisedAt'), c.str('dueAt'), c.str('now')), c['out'], 'sla ${c['raisedAt']} ${c['dueAt']} ${c['now']}');
    }
  });

  test('visit slot times and bookable slots', () {
    for (final c in (cases['slotTimes'] as List).cast<Json>()) {
      expectSame(slotTimesOn(c.list('rules'), c.str('date')), c['out'], 'slotTimesOn ${c['date']}');
    }
    for (final c in (cases['visits'] as List).cast<Json>()) {
      final args = c['args'] as List<dynamic>;
      final out = c['fn'] == 'visitSlotsFor' ? data.visitSlotsFor(args[0] as String, args[1] as String) : data.visitDatesFor(args[0] as String, args[1] as int, args[1] == 5 ? '2026-11-13T20:00:00+03:00' : null);
      expectSame(out, c['out'], '${c['fn']}$args');
    }
  });

  test('venue quotes (standard and voucher columns)', () {
    final list = (cases['quote'] as List).cast<Json>();
    var priced = 0, refused = 0;
    for (final c in list) {
      final i = c.obj('input');
      Json run() => data.quoteFor(
            venueId: i.str('venueId'),
            eventDate: i.str('eventDate'),
            sections: i.list('sections'),
            extras: i.list('extras'),
            venueDiscount: i.objOrNull('venueDiscount'),
            at: i.str('now'),
          );
      if (c['throws'] == true) {
        refused++;
        expect(run, throwsStateError, reason: 'expected a refusal for $i');
      } else {
        priced++;
        expectSame(run(), c['out'], 'quote $i');
      }
    }
    expect(priced, greaterThan(150));
    expect(refused, greaterThan(0));
    for (final c in (cases['providerQuote'] as List).cast<Json>()) {
      expectSame(data.quoteForProvider(providerId: c.str('providerId'), packageId: c.str('packageId'), qty: c.integer('qty'), venueDiscount: c.objOrNull('venueDiscount')), c['out'], 'provider quote $c');
    }
  });

  test('availability by day (months of every hall)', () {
    final list = (cases['availability'] as List).cast<Json>();
    var days = 0;
    for (final c in list) {
      final out = data.availabilityFor(c.str('venueId'), c.str('hallId'), c.str('month'), c.obj('brief'), c.str('now'));
      days += out.length;
      expectSame(out, c['out'], 'availability ${c['hallId']} ${c['month']} ${c['brief']}');
    }
    expect(days, greaterThan(1000));
    for (final c in (cases['venueDay'] as List).cast<Json>()) {
      expectSame(data.venueAvailabilityOn(c.str('venueId'), c.str('date'), c.obj('brief'), c.str('now')), c['out'], 'venueDay ${c['venueId']} ${c['date']}');
    }
  });

  test('card prices, guest ranges, section tags, structures', () {
    for (final c in (cases['cardPrice'] as List).cast<Json>()) {
      final id = c.str('venueId');
      final Object? out = switch (c['fn']) {
        'guestRange' => data.guestRange(id),
        'sectionTags' => data.sectionTags(id),
        'structuresOf' => data.structuresOf(id),
        _ => data.cardPrice(id, c.obj('brief'), c.str('now')),
      };
      expectSame(out, c['out'], 'cardPrice $id ${c['brief']} ${c['fn']}');
    }
  });

  test('search, filters, sorts, regions, nearby, compare', () {
    for (final c in (cases['listVenues'] as List).cast<Json>()) {
      final rows = data.listVenues(c.obj('filter'), c.obj('brief'), c.str('now'));
      expectSame(slimVenues(rows), c['out'], 'listVenues ${c['filter']} ${c['brief']}');
    }
    for (final c in (cases['searchRegions'] as List).cast<Json>()) {
      expectSame(data.searchRegions(c.str('query')), c['out'], 'searchRegions "${c['query']}"');
    }
    for (final c in (cases['nearby'] as List).cast<Json>()) {
      expectSame(slimVenues(data.nearby(c.str('from'), c.integer('limit'))), c['out'], 'nearby ${c['from']}');
    }
    for (final c in (cases['compare'] as List).cast<Json>()) {
      expectSame(slimVenues(data.compareSet((c['ids'] as List).cast<String>(), c.obj('brief'), c.str('origin'), c.str('now'))), c['out'], 'compare ${c['ids']}');
    }
  });

  test('the hero story prices: KD 18,200 standard, KD 15,400 voucher', () {
    final q = data.quoteFor(venueId: 'V01', eventDate: '2027-01-14', sections: [
      {'hallId': 'V01-danah', 'audience': 'women', 'guests': 350, 'packageId': 'V01-ladies-weekend'}
    ]);
    expect(filsOf(q.obj('totals').obj('standardTotal')), 18200000);
    expect(filsOf(q.obj('totals').obj('voucherTotal')), 15400000);
    expect(q['voucherEligible'], true);
  });
}
