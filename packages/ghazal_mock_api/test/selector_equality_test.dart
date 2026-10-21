// The mock against the web view logic: packages/contracts/fixtures/selector-cases.json holds arguments and the ids, order and counts that the
// prototype's selectors and screens produce for the hero persona (tools/export-selector-cases.mjs). Every case is sent to the mock handlers
// over the in-process adapter (the real routes, validation and personas) and must answer the same. engine_equality_test.dart proves the
// arithmetic; this file proves the selection: shelves, search filters, regions, the Needs-you queue, the request segments, notification order.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart';

import 'harness.dart';
import 'support.dart';

typedef Out = Map<String, dynamic>;

void main() {
  late World w;
  late Json cases;
  final failures = <String>[];
  var checked = 0;

  setUpAll(() async {
    w = await World.create();
    cases = readJson('packages/contracts/fixtures/selector-cases.json').obj('cases');
  });

  Actor actorFor(Json c) => w.actor(c.strOrNull('persona') ?? 'guest', venueId: c.strOrNull('venue'));

  Future<Object?> get(Actor a, String path, Json query) async {
    final res = await a.dio.get<Object?>(path, queryParameters: {for (final e in query.entries) e.key: e.value is List ? (e.value as List).map((x) => '$x').toList() : e.value});
    return res.data;
  }

  Future<Object?> post(Actor a, String path, Object body) async => (await a.dio.post<Object?>(path, data: body, options: Options(headers: {'Idempotency-Key': 'sel-${path.hashCode}-${body.hashCode}'}))).data;

  void same(String id, String what, Object? actual, Object? expected) {
    checked++;
    final d = jsonDiff(actual, expected);
    if (d != null) failures.add('$id: $what differs at $d\n    mock: ${_short(actual)}\n    web:  ${_short(expected)}');
  }

  List<String> ids(Object? items, [String Function(Json)? pick]) => [for (final i in (items as List).cast<Json>()) pick != null ? pick(i) : i.str('id')];
  Json c(Object? o) => (o as Map).cast<String, dynamic>();

  Future<void> guard(String id, Future<void> Function() run) async {
    try {
      await run();
    } on DioException catch (e) {
      failures.add('$id: HTTP ${e.response?.statusCode} ${_short(e.response?.data)}');
    } catch (e, st) {
      failures.add('$id: $e\n$st');
    }
  }

  test('home: shelves, free count, nearest dates, categories', () async {
    for (final k in (cases['home'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final h = c(await get(actorFor(k), '/home', k.obj('query')));
        final o = k.obj('out');
        same(k.str('id'), 'freeCount', h['freeCount'], o['freeCount']);
        if (o.containsKey('free')) {
          final shelves = {for (final s in (h['shelves'] as List).cast<Json>()) s.str('id'): s};
          same(k.str('id'), 'free shelf', ids(shelves['free']?['items'] ?? [], (i) => i.obj('row').obj('venue').str('id')), o['free']);
          same(k.str('id'), 'featured', (shelves['featured']?['items'] as List?)?.map((i) => (i as Json).obj('row').obj('venue')['id']).firstOrNull, o['featured']);
          same(k.str('id'), 'week shelf', ids(shelves['week']?['items'] ?? [], (i) => i.obj('row').obj('venue').str('id')), o['week']);
          return;
        }
        same(k.str('id'), 'nearestFreeDates', h['nearestFreeDates'], o['nearestFreeDates']);
        same(k.str('id'), 'categories', {for (final x in (h['categories'] as List).cast<Json>()) x.str('id'): x['venueCount']}, {for (final x in (o['categories'] as List).cast<Json>()) x.str('id'): x['venueCount']});
        final mock = [
          for (final s in (h['shelves'] as List).cast<Json>())
            {
              'id': s['id'],
              'ids': ids(s['items'], (i) => i.obj('row').obj('venue').str('id')),
              if (s['id'] == 'week') 'dates': [for (final i in (s['items'] as List).cast<Json>()) i['date']],
            }
        ];
        same(k.str('id'), 'shelves', mock, o['shelves']);
      });
    }
  });

  Object? rowOut(Json r) => {
        'id': r.obj('venue')['id'],
        'availability': r['availability'],
        'amount': (r['price'] as Map?)?['amount']?['fils'],
        'voucher': (r['price'] as Map?)?['voucher']?['fils'],
        'badge': r['badge'],
        'minutes': (r['distance'] as Map?)?['minutes'],
      };

  test('search: filters, sorts, shelves, categories, text', () async {
    for (final k in (cases['search'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final a = actorFor(k);
        final q = {...k.obj('query'), 'limit': 50};
        final page = c(await get(a, '/venues', q));
        final o = k.obj('out');
        same(k.str('id'), 'rows', [for (final r in (page['items'] as List).cast<Json>()) rowOut(r)], o['rows']);
        final count = c(await get(a, '/venues/count', k.obj('query')));
        same(k.str('id'), 'count', count['count'], o['count']);
      });
    }
  });

  test('regions: governorates, areas that hold a hall, halls', () async {
    for (final k in (cases['regions'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final r = await get(actorFor(k), '/areas/search', k.obj('query'));
        same(k.str('id'), 'matches', [for (final m in (r as List).cast<Json>()) {'kind': m['kind'], 'id': m['id'], 'venueCount': m['venueCount']}], k['out']);
      });
    }
  });

  test('venue detail: the price of every package for the hall in the Brief', () async {
    for (final k in (cases['venueDetail'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final q = k.obj('query');
        final d = c(await get(actorFor(k), '/venues/${q['venueId']}', {...q}..remove('venueId')));
        final o = k.obj('out');
        final shown = [
          for (final p in (d['packages'] as List).cast<Json>())
            if (p.obj('package')['components'] == null && p.obj('package').strings('hallIds').contains(q['hallId']) || q['date'] == null) p
        ];
        final mock = [
          for (final p in shown)
            {
              'id': p.obj('package')['id'],
              'forBrief': p['forBrief'] == null ? null : {for (final key in ['standard', 'voucher', 'savings']) key: (p.obj('forBrief')[key] as Map?)?['fils'], 'voucherOffered': p.obj('forBrief')['voucherOffered'], for (final key in ['perGuest', 'flat', 'voucherPerGuest', 'voucherFlat']) key: (p.obj('forBrief')[key] as Map?)?['fils'], 'billedGuests': p.obj('forBrief')['billedGuests'], 'billableGuests': p.obj('forBrief')['billableGuests'], 'tier': p.obj('forBrief')['tier'], 'hallId': p.obj('forBrief')['hallId'], 'audience': p.obj('forBrief')['audience']},
            }
        ];
        same(k.str('id'), 'packages', mock, o['packages']);
        same(k.str('id'), 'guestRange', d['guestRange'], o['guestRange']);
        same(k.str('id'), 'tags', d['tags'], o['tags']);
        same(k.str('id'), 'structures', d['structures'], o['structures']);
        final card = d['price'] as Map?;
        same(k.str('id'), 'card', card == null ? null : {'mode': card['mode'], 'amount': card['amount']['fils'], 'voucher': (card['voucher'] as Map?)?['fils']}, o['card']);
      });
    }
  });

  test('availability by day and by venue', () async {
    for (final k in (cases['availability'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final q = k.obj('query');
        if (k.str('id').startsWith('venueDay')) {
          final d = c(await get(actorFor(k), '/venues/${q['venueId']}/availability/day', {...q}..remove('venueId')));
          same(k.str('id'), 'day', {'state': d['state'], 'hallId': d['hallId'], 'from': ((d['day'] as Map?)?['fromPrice'] as Map?)?['fils']}, k['out']);
        } else {
          final d = c(await get(actorFor(k), '/venues/${q['venueId']}/availability', {...q}..remove('venueId')));
          same(k.str('id'), 'days', [for (final x in (d['days'] as List).cast<Json>()) {'date': x['date'], 'state': x['state'], 'from': (x['fromPrice'] as Map?)?['fils'], 'voucher': (x['voucherPrice'] as Map?)?['fils'], 'packageId': x['packageId']}], k.obj('out')['days']);
        }
      });
    }
  });

  test('quotes (extras carry a quantity)', () async {
    for (final k in (cases['quote'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final q = k.obj('query');
        final r = c(await post(actorFor(k), '/venues/${q['venueId']}/quotes', q['body']! as Object));
        final o = k.obj('out');
        same(k.str('id'), 'offered', r['voucherOffered'], o['voucherOffered']);
        same(k.str('id'), 'lines', [for (final l in (r['lines'] as List).cast<Json>()) {'kind': l['kind'], 'qty': l['qty'], 'amount': l.obj('amount')['fils'], 'standardAmount': l.obj('standardAmount')['fils'], 'unit': (l['unit'] as Map?)?['fils']}], o['lines']);
        same(k.str('id'), 'totals', {for (final e in r.obj('totals').entries) e.key: e.value is Map ? (e.value as Map)['fils'] : e.value}, o['totals']);
      });
    }
  });

  test('compare', () async {
    for (final k in (cases['compare'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final r = c(await post(actorFor(k), '/compare/prices', k['query']! as Object));
        same(k.str('id'), 'columns', [for (final x in (r['columns'] as List).cast<Json>()) {'id': x.obj('venue')['id'], 'availability': x['availability'], 'price': (x['price'] as Map?)?['fils'], 'voucherPrice': (x['voucherPrice'] as Map?)?['fils'], 'fromPerGuest': (x['fromPerGuest'] as Map?)?['fils'], 'fits': x['fits'], 'best': x['best'], 'packages': x.obj('packages')['count']}], k.obj('out')['columns']);
      });
    }
  });

  test('reviews and areas', () async {
    for (final k in (cases['reviews'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final q = k.obj('query');
        final r = c(await get(actorFor(k), '/venues/${q['venueId']}/reviews', {'sort': q['sort'], 'limit': 50}));
        same(k.str('id'), 'ids', ids(r['items']), k.obj('out')['ids']);
      });
    }
    for (final k in (cases['areas'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final r = c(await get(actorFor(k), '/areas', {}));
        same(k.str('id'), 'governorates', ids(r['governorates']), k.obj('out')['governorates']);
        same(k.str('id'), 'areas', ids(r['areas']), k.obj('out')['areas']);
      });
    }
  });

  test('partner: memberships, Today, Needs you', () async {
    for (final k in (cases['partnerMemberships'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final me = c(await get(actorFor(k), '/partner/me', {}));
        final ms = (me['memberships'] as List).cast<Json>();
        final o = k.obj('out');
        same(k.str('id'), 'venues', [for (final m in ms) m['venueId']], o['venues']);
        same(k.str('id'), 'roles', [for (final m in ms) m['role']], o['roles']);
        same(k.str('id'), 'sister pending', ms.last['pendingRequests'], o['sisterPending']);
      });
    }
    for (final k in (cases['partnerToday'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final t = c(await get(actorFor(k), '/partner/today', k.obj('query')));
        final o = k.obj('out');
        same(k.str('id'), 'tiles', {'requests': t.obj('tiles')['requests'], 'awaitingClient': t.obj('tiles')['awaitingClient']}, o['tiles']);
        same(k.str('id'), 'needsYou', [for (final n in (t['needsYou'] as List).cast<Json>()) n.obj('item')['id']], o['needsYou']);
        same(k.str('id'), 'events (the story day only)', [for (final e in (t['events'] as List).cast<Json>()) e.obj('booking')['id']], o['events']);
      });
    }
    for (final k in (cases['needsYou'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final t = (await get(actorFor(k), '/partner/needs-you', k.obj('query')) as List).cast<Json>();
        final o = k.obj('out');
        same(k.str('id'), 'ids', [for (final n in t) n.obj('item')['id']], o['ids']);
        same(k.str('id'), 'types', [for (final n in t) n.obj('item')['type']], o['types']);
        same(k.str('id'), 'count', t.length, o['count']);
      });
    }
  });

  test('partner: request segments, redeemable vouchers, calendar, notifications, conversations', () async {
    for (final k in (cases['requests'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final p = c(await get(actorFor(k), '/partner/requests', k.obj('query')));
        same(k.str('id'), 'ids', [for (final r in (p['items'] as List).cast<Json>()) r.obj('booking')['id']], k.obj('out')['ids']);
      });
    }
    for (final k in (cases['redeem'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final p = c(await get(actorFor(k), '/partner/vouchers/redeemable', {'limit': 50}));
        final got = [for (final r in (p['items'] as List).cast<Json>()) r.obj('booking')['id'] as String]..sort();
        same(k.str('id'), 'ids (as a set)', got, (k.obj('out')['ids'] as List).cast<String>().toList()..sort());
      });
    }
    for (final k in (cases['calendar'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final p = c(await get(actorFor(k), '/partner/calendar', k.obj('query')));
        same(k.str('id'), 'days', [for (final d in (p['days'] as List).cast<Json>()) {'date': d['date'], 'claims': [for (final x in (d['claims'] as List).cast<Json>()) x['id'] as String]..sort()}], k.obj('out')['days']);
      });
    }
    for (final k in (cases['notifications'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final p = c(await get(actorFor(k), '/notifications', k.obj('query')));
        same(k.str('id'), 'ids', ids(p['items']), k.obj('out')['ids']);
        final n = c(await get(actorFor(k), '/notifications/unread-count', {}));
        same(k.str('id'), 'unread', n['count'], k.obj('out')['unread']);
      });
    }
    for (final k in (cases['conversations'] as List).cast<Json>()) {
      await guard(k.str('id'), () async {
        final p = c(await get(actorFor(k), '/conversations', k.obj('query')));
        same(k.str('id'), 'ids', ids(p['items']), k.obj('out')['ids']);
      });
    }
  });

  tearDownAll(() {
    // ignore: avoid_print
    print('selector cases: $checked assertions, ${failures.length} failures');
    if (failures.isNotEmpty) {
      // ignore: avoid_print
      print(failures.take(60).join('\n'));
    }
  });

  test('every disagreement is listed above; none remain', () {
    expect(failures, isEmpty, reason: failures.take(25).join('\n'));
  });
}

String _short(Object? o) {
  final s = '$o';
  return s.length > 600 ? '${s.substring(0, 600)}...' : s;
}
