/// wedding: the profile, overview, checklist (with the automatic venue item), budget (the venue line follows the voucher and the confirmed
/// request) and favourites.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/requests.dart' as dom;
import '../domain/views.dart';
import '../engine/engine.dart';

Json _profileDefaults(MockApp app, String uid) {
  final u = app.requireUser(uid);
  return {
    'id': 'wedding-$uid',
    'userId': uid,
    'role': 'bride',
    'brideName': u['name'],
    'partnerName': null,
    'weddingDate': addDays(app.today(), 365),
    'dateMode': 'undecided',
    'guests': {'women': 0, 'men': 0},
    'venueBudget': {'min': fils(0), 'max': fils(0)},
    'totalBudget': fils(0),
    'areaIds': <String>[],
    'governorateIds': <String>[],
    'searching': <String>[],
  };
}

Json _mergeProfile(Json base, Json input) {
  final out = deepCopy(base);
  for (final e in input.entries) {
    if (e.value != null || {'partnerName'}.contains(e.key)) out[e.key] = e.value;
  }
  return out;
}

bool _confirmedLike(Json b) => {'confirmed', 'redeemed', 'completed'}.contains(b['status']);

List<Json> _checklist(MockApp app, String uid) {
  if (!app.db.raw('ChecklistItem').any((c) => c['_userId'] == uid)) {
    for (final seedItem in app.seed.rows('ChecklistItem')) {
      app.db.put('ChecklistItem', {
        ...deepCopy(seedItem),
        'id': '${seedItem['id']}-${uid.replaceAll('user-', '')}',
        'done': false,
        'doneAt': null,
        'bookingId': null,
        '_userId': uid,
      });
    }
  }
  final bookings = app.db.raw('Booking').where((b) => b['clientId'] == uid && b['venueId'] != null).toList();
  final confirmed = bookings.cast<Json?>().firstWhere((b) => _confirmedLike(b!), orElse: () => null);
  final open = confirmed ?? bookings.cast<Json?>().firstWhere((b) => b!['status'] == 'pending' || b['status'] == 'approved', orElse: () => null);
  return [
    for (final c in app.db.raw('ChecklistItem'))
      if (c['_userId'] == uid)
        c['auto'] == true ? {...wire(c), 'done': confirmed != null, 'doneAt': confirmed?['confirmedAt'], 'bookingId': open?['id']} : wire(c),
  ];
}

Json _progress(List<Json> items) {
  final done = items.where((i) => i['done'] == true).length;
  return {'done': done, 'total': items.length, 'percent': items.isEmpty ? 0 : jsRound(done / items.length * 100)};
}

Json _budgetDoc(MockApp app, String uid) {
  var b = app.db.get('Budget', uid);
  if (b == null) {
    final profile = app.db.peek('WeddingProfile', uid);
    final seedBudget = app.seed.rows('Budget').first;
    final seedTotal = filsOf(seedBudget.obj('total'));
    final total = profile != null && filsOf(profile.obj('totalBudget')) > 0 ? filsOf(profile.obj('totalBudget')) : seedTotal;
    b = {
      'id': uid,
      'total': fils(total),
      'categories': [
        for (final c in seedBudget.list('categories'))
          {...deepCopy(c), 'allocated': fils(floorDiv(filsOf(c.obj('allocated')) * total, seedTotal)), 'paid': zero(), 'committed': zero()},
      ],
      '_userId': uid,
    };
    app.db.put('Budget', b);
  }
  return b;
}

Json budgetView(MockApp app, String uid) {
  final b = _budgetDoc(app, uid);
  final expenses = [
    for (final e in app.db.raw('Expense'))
      if (e['_userId'] == uid) e,
  ];
  final vouchers = app.db
      .raw('Voucher')
      .where((v) => v['clientId'] == uid && v['kind'] == 'bound' && {'bound', 'used'}.contains(v['status']) && v['payment'] != null)
      .toList();
  final committed = app.db.raw('Booking').where((x) => x['clientId'] == uid && _confirmedLike(x)).toList();
  final cats = <Json>[];
  var paid = 0, comm = 0;
  for (final c in b.list('categories')) {
    var p = 0, k = 0;
    if (c['autoLinked'] == true) {
      p += vouchers.fold<int>(0, (s, v) => s + v.integer('priceFils'));
      k += committed.fold<int>(0, (s, x) => s + filsOf(x.obj('totals').obj('voucherTotal')));
    }
    for (final e in expenses.where((e) => e['categoryId'] == c['id'])) {
      if (e['status'] == 'paid') p += filsOf(e.obj('amount'));
      if (e['status'] == 'committed') k += filsOf(e.obj('amount'));
    }
    paid += p;
    comm += k;
    cats.add({...c, 'paid': fils(p), 'committed': fils(k)});
  }
  final total = filsOf(b.obj('total'));
  return {
    'budget': {'total': b['total'], 'categories': cats, 'expenses': expenses.map(wire).toList()},
    'paid': fils(paid),
    'committed': fils(comm),
    'remaining': fils(total - paid - comm),
  };
}

Json _savedEntry(MockApp app, Json item, Json rowsByVenue) {
  final type = item.str('type');
  final id = item.str('id');
  return {
    'item': wire(item),
    'venue': type == 'venue' ? rowsByVenue[id] : null,
    'provider': type == 'vendor' ? app.db.peek('ServiceProvider', id) : null,
    'package': type == 'package' ? app.db.peek('Package', id) : null,
  };
}

Json _savedList(MockApp app, Req r) {
  final brief = <String, dynamic>{'date': r.q('date'), 'guests': r.qInt('guests'), 'audience': r.q('audience')}..removeWhere((k, v) => v == null);
  final rows = {for (final x in app.engine().listVenues({}, brief)) x.obj('venue').str('id'): venueResult(x)};
  final mine = stableSorted([
    for (final s in app.db.raw('SavedItem'))
      if (s['_userId'] == r.userId) s,
  ], (a, b) => b.str('savedAt').compareTo(a.str('savedAt')));
  return {
    'items': [for (final s in mine) _savedEntry(app, s, rows)],
  };
}

void _requireEntity(MockApp app, String type, String id) {
  final ok = switch (type) {
    'venue' => app.db.has('Venue', id),
    'vendor' => app.db.has('ServiceProvider', id),
    'package' => app.db.has('Package', id),
    _ => false,
  };
  if (!ok) throw ApiError.notFound(type);
}

Map<String, Handler> weddingHandlers(MockApp app) => {
  'getWeddingProfile': (r) => wire(app.db.peek('WeddingProfile', r.userId) ?? (throw ApiError.notFound('wedding profile'))),
  'putWeddingProfile': (r) {
    final base = app.db.get('WeddingProfile', r.userId) ?? _profileDefaults(app, r.userId);
    final merged = _mergeProfile(base, r.b);
    app.db.put('WeddingProfile', merged, id: r.userId);
    return wire(merged);
  },
  'updateWeddingProfile': (r) {
    final base = app.db.get('WeddingProfile', r.userId) ?? (throw ApiError.notFound('wedding profile'));
    final merged = _mergeProfile(base, r.b);
    app.db.put('WeddingProfile', merged, id: r.userId);
    return wire(merged);
  },
  'getWeddingOverview': (r) {
    final profile = app.db.peek('WeddingProfile', r.userId);
    final items = _checklist(app, r.userId);
    final bv = budgetView(app, r.userId);
    final open = app.db.raw('Booking').where((b) => b['clientId'] == r.userId && {'pending', 'approved'}.contains(b['status'])).toList();
    final planner = app.db.raw('PlannerRequest').where((p) => p['clientId'] == r.userId).toList();
    return {
      'profile': profile == null ? null : wire(profile),
      'daysToWedding': profile == null ? null : diffDays(app.today(), profile.str('weddingDate')),
      'checklist': _progress(items),
      'budget': profile == null ? null : {'total': bv.obj('budget')['total'], 'paid': bv['paid'], 'committed': bv['committed'], 'remaining': bv['remaining']},
      'openRequests': [
        for (final b in open)
          {
            'booking': dom.viewBooking(b),
            'target': targetSummary(app, venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
            'halls': hallRefs(app, b),
          },
      ],
      'plannerRequest': planner.isEmpty ? null : wire(planner.last),
    };
  },
  'listBudgetBands': (r) => app.seed.rows('BudgetBand'),
  'getChecklist': (r) {
    final items = _checklist(app, r.userId);
    return {'items': items, 'percent': _progress(items).integer('percent')};
  },
  'createChecklistItem': (r) {
    _checklist(app, r.userId);
    final title = r.b.str('title');
    final item = {
      'id': 'chk-m${app.db.next('checklist').toString().padLeft(3, '0')}',
      'group': r.b.strOrNull('group') ?? 'custom',
      'title': {'en': title, 'ar': title},
      'dueOn': r.b['dueOn'],
      'done': false,
      'doneAt': null,
      'auto': false,
      'custom': true,
      'serviceCategoryId': null,
      'bookingId': null,
      '_userId': r.userId,
    };
    app.db.put('ChecklistItem', item);
    return wire(item);
  },
  'updateChecklistItem': (r) {
    final c = app.db.get('ChecklistItem', r.p('itemId'));
    if (c == null || c['_userId'] != r.userId) throw ApiError.notFound('checklist item');
    if (c['auto'] == true && r.b.containsKey('done')) throw ApiError.validation('/done', 'automatic_item');
    if (r.b.containsKey('done')) {
      c['done'] = r.b['done'] == true;
      c['doneAt'] = r.b['done'] == true ? app.now : null;
    }
    if (r.b['title'] != null) c['title'] = {'en': r.b['title'], 'ar': r.b['title']};
    if (r.b.containsKey('dueOn')) c['dueOn'] = r.b['dueOn'];
    app.db.put('ChecklistItem', c);
    return wire(c);
  },
  'deleteChecklistItem': (r) {
    final c = app.db.get('ChecklistItem', r.p('itemId'));
    if (c == null || c['_userId'] != r.userId) throw ApiError.notFound('checklist item');
    if (c['auto'] == true) throw ApiError.forbidden('the venue item is automatic');
    app.db.remove('ChecklistItem', c.str('id'));
    return null;
  },
  'getBudget': (r) => budgetView(app, r.userId),
  'setBudget': (r) {
    final b = _budgetDoc(app, r.userId);
    b['total'] = r.b['total'];
    final alloc = {for (final a in r.b.list('allocations')) a.str('categoryId'): a['allocated']};
    b['categories'] = [
      for (final c in b.list('categories')) alloc.containsKey(c['id']) ? {...c, 'allocated': alloc[c['id']]} : c,
    ];
    app.db.put('Budget', b, id: r.userId);
    return budgetView(app, r.userId);
  },
  'addExpense': (r) {
    _budgetDoc(app, r.userId);
    final e = {
      'id': 'exp-m${app.db.next('expense').toString().padLeft(3, '0')}',
      'categoryId': r.b['categoryId'],
      'label': r.b['label'],
      'amount': r.b['amount'],
      'status': r.b['status'],
      'date': r.b['date'],
      'bookingId': null,
      'vendorId': null,
      '_userId': r.userId,
    };
    app.db.put('Expense', e);
    return wire(e);
  },
  'updateExpense': (r) {
    final e = app.db.get('Expense', r.p('expenseId'));
    if (e == null || e['_userId'] != r.userId) throw ApiError.notFound('expense');
    for (final k in ['categoryId', 'label', 'amount', 'status', 'date']) {
      if (r.b.containsKey(k)) e[k] = r.b[k];
    }
    app.db.put('Expense', e);
    return wire(e);
  },
  'deleteExpense': (r) {
    final e = app.db.get('Expense', r.p('expenseId'));
    if (e == null || e['_userId'] != r.userId) throw ApiError.notFound('expense');
    app.db.remove('Expense', e.str('id'));
    return null;
  },
  'listWishlist': (r) => _savedList(app, r),
  'mergeWishlist': (r) {
    for (final m in r.b.list('items')) {
      final key = '${r.userId}|${m['type']}|${m['id']}';
      if (app.db.has('SavedItem', key)) continue;
      if (!_exists(app, m.str('type'), m.str('id'))) continue;
      app.db.put('SavedItem', {'type': m['type'], 'id': m['id'], 'savedAt': m['savedAt'] ?? app.now, 'lastSeenPrice': null, '_userId': r.userId}, id: key);
    }
    return _savedList(app, r);
  },
  'saveWishlistItem': (r) {
    final type = r.p('type'), id = r.p('id');
    _requireEntity(app, type, id);
    final key = '${r.userId}|$type|$id';
    final prior = app.db.peek('SavedItem', key);
    final item = {
      'type': type,
      'id': id,
      'savedAt': prior?['savedAt'] ?? app.now,
      'lastSeenPrice': r.body?['lastSeenPrice'] ?? prior?['lastSeenPrice'],
      '_userId': r.userId,
    };
    app.db.put('SavedItem', item, id: key);
    return wire(item);
  },
  'removeWishlistItem': (r) {
    app.db.remove('SavedItem', '${r.userId}|${r.p('type')}|${r.p('id')}');
    return null;
  },
};

bool _exists(MockApp app, String type, String id) => switch (type) {
  'venue' => app.db.has('Venue', id),
  'vendor' => app.db.has('ServiceProvider', id),
  'package' => app.db.has('Package', id),
  _ => false,
};
