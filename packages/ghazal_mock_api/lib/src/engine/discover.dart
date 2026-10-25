/// The Discover view logic of the prototype, in Dart: the Home shelves, the Results list with every filter of the Filters sheet, the free
/// count, the nearest free dates, the category membership and the region search. Port of design/src/screens/client/discover/_components/data.ts
/// and of the region search of CL-DISC-07; packages/contracts/fixtures/selector-cases.json (tools/export-selector-cases.mjs) proves it equal,
/// case by case, to the web (test/selector_equality_test.dart). It runs on [EngineData], whose selectors engine-cases.json already proves equal.
///
/// Where the web has a defect the mock keeps the web's intent and says so in docs/architecture/mock-api.md ("Known differences from the web").
library;

import 'catalog.dart';
import 'dates.dart';
import 'json.dart';
import 'money.dart';

// ---------------------------------------------------------------- text

final _tashkeel = RegExp('[ؐ-ًؚ-ٰٟـۖ-ۭ]');

/// Search folding: lower case, tashkeel and tatweel off, alef forms to alef, ya forms to ya, teh marbuta to heh, hamza seats to their letter, and the
/// article (the leading `ال` of a word of four letters or more) off, so «المشرف» finds «مشرف» and «مشرف» finds «المشرف».
String foldSearch(String s) {
  final t = s
      .toLowerCase()
      .replaceAll(_tashkeel, '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .trim();
  return t.split(RegExp(r'\s+')).map((w) => w.length >= 4 && w.startsWith('ال') ? w.substring(2) : w).join(' ');
}

// ---------------------------------------------------------------- categories, facilities, brands (data.ts)

const _coastal = {'messila', 'fintas', 'khiran', 'mahboula', 'salmiya'};

/// Category membership is derived from the venue record (type, hall settings, area, price grammar).
bool inCategory(Json v, Json? price, String id) {
  final open = v.list('halls').any((h) => h['setting'] != 'indoor');
  switch (id) {
    case 'luxury-hotels':
      return v['type'] == 'hotel';
    case 'wedding-halls':
      return v['type'] == 'private-hall' && (v['style'] == 'hall' || v['style'] == 'convention');
    case 'government':
      return v['type'] == 'governmental';
    case 'beach':
      return open && _coastal.contains(v['areaId']);
    case 'outdoor':
      return open;
    case 'vip':
      return price?['mode'] == 'flat_night';
  }
  return false;
}

String? _amenity(Json v, String id) {
  for (final a in v.list('amenities')) {
    if (a['amenityId'] == id) return a['state'] as String?;
  }
  return null;
}

bool hasFacility(Json v, String key) {
  switch (key) {
    case 'parking':
      return _amenity(v, 'parking') == 'included';
    case 'valet':
      return _amenity(v, 'valet') == 'included' || _amenity(v, 'valet') == 'extra';
    case 'bridal':
      return _amenity(v, 'bridal-suite') != null && _amenity(v, 'bridal-suite') != 'not_offered';
    case 'buffet':
      return _amenity(v, 'buffet') == 'included';
    case 'decor':
      return const ['basic-decor', 'kosha', 'florals'].any((id) => _amenity(v, id) == 'included');
    case 'photography':
      return v.list('halls').any((h) => h.list('sections').any((s) => s.obj('policy')['photography'] != 'none'));
  }
  return false;
}

/// Hotel brand = the first word of a hotel's own name (English). Null for non-hotels.
String? brandOf(Json v) => v['type'] == 'hotel' ? (v.obj('name').str('en').split(' ').first) : null;

/// Lowest per-guest rate of one price column over the venue's per-guest packages for an audience, in fils rounded to KD 0.500 (the web rounds to
/// half a dinar); null for flat, hall-only and official-fee venues.
int? perGuestFrom(EngineData e, Json v, String audience, {required bool voucher}) {
  if (v['officialFees'] != null) return null;
  int? best;
  for (final pkg in e.packagesFor(v.str('id'))) {
    if (!pkg.flag('active') || pkg['components'] != null || pkg['pricingBasis'] == 'flat' || !pkg.strings('audiences').contains(audience)) continue;
    for (final r in e.rulesFor(pkg.str('id'))) {
      final money = r.objOrNull(voucher ? 'voucherPerGuest' : 'perGuest');
      if (money == null) continue;
      final kd = jsRound(filsOf(money) / 500) * 500;
      if (best == null || kd < best) best = kd;
    }
  }
  return best;
}

// ---------------------------------------------------------------- the Results list

/// The Filters of the Results screen as the API sends them. [f] keys (all optional): areaIds (bound areas), governorateIds, types, capacity
/// {min,max}, priceStructure, voucherOnly, availableBetween {from,to}, arrangement, withinMinutes, perGuest [min,max] (fils), voucherPerGuest
/// [min,max] (fils), settings, facilities, available (free or on hold on the Brief date), minRating, levels, brands, category, shelf, query.
/// [brief]: date, guests, audience, areaIds (the Brief's areas; they rank the list, and narrow it when [f] has no `areaIds` and no governorate or shelf).
List<Json> searchResults(EngineData e, Json brief, Json f, {String? sort, String? origin}) {
  List<String> list(String k) => ((f[k] as List?) ?? const []).cast<String>();
  final briefAreas = ((brief['areaIds'] as List?) ?? const []).cast<String>();
  final bound = f['areaIds'] != null ? list('areaIds') : (list('governorateIds').isNotEmpty || f['shelf'] != null ? const <String>[] : briefAreas);
  final org = origin ?? (bound.isNotEmpty ? 'ref-${bound.first}' : 'ref-salmiya');
  final engineFilter = <String, dynamic>{
    'sort': sort ?? 'recommended',
    'origin': org,
    if (bound.isNotEmpty) 'areaIds': bound,
    if (list('governorateIds').isNotEmpty) 'governorateIds': list('governorateIds'),
    if (list('types').isNotEmpty) 'types': list('types'),
    if (f['capacity'] != null) 'capacity': f['capacity'],
    if (f['priceStructure'] != null) 'priceStructure': f['priceStructure'],
    if (f['voucherOnly'] == true) 'voucherOnly': true,
    if (f['availableBetween'] != null) 'availableBetween': f['availableBetween'],
  };
  var rows = e.listVenues(engineFilter, brief);
  final q = f['query'] as String?;
  if (q != null && q.trim().isNotEmpty) {
    final needle = foldSearch(q);
    rows = rows.where((r) => _venueMatchesText(e, r.obj('venue'), needle)).toList();
  }
  final shelf = f['shelf'] as String?;
  final ids = shelf != null ? shelfIds(e, shelf, brief) : null;
  return rows.where((r) => (ids == null || ids.contains(r.obj('venue')['id'])) && _matches(e, r, f, brief)).toList();
}

bool _venueMatchesText(EngineData e, Json v, String needle) {
  if (needle.isEmpty) return true;
  final a = e.area(v.str('areaId'));
  final g = e.governorate(v.str('governorateId'));
  final hay = <String?>[
    v.obj('name').strOrNull('en'),
    v.obj('name').strOrNull('ar'),
    a?.obj('name').strOrNull('en'),
    a?.obj('name').strOrNull('ar'),
    ...(a?.strings('aliases') ?? const <String>[]),
    g?.obj('name').strOrNull('en'),
    g?.obj('name').strOrNull('ar'),
  ];
  return hay.any((t) => foldSearch(t ?? '').contains(needle));
}

bool _matches(EngineData e, Json row, Json f, Json brief) {
  final v = row.obj('venue');
  final audience = (brief['audience'] as String?) ?? 'women';
  List<String> list(String k) => ((f[k] as List?) ?? const []).cast<String>();
  final category = f['category'] as String?;
  if (category != null && !inCategory(v, row.objOrNull('price'), category)) return false;
  final arrangement = f['arrangement'] as String?;
  if (arrangement != null && !v.list('halls').any((h) => h.list('sections').any((s) => s['audience'] == arrangement))) return false;
  final within = (f['withinMinutes'] as num?)?.toInt();
  if (within != null) {
    final m = row.objOrNull('distance')?['minutes'] as num?;
    if (m == null || m > within) return false;
  }
  final price = f['perGuest'] as List?;
  if (price != null) {
    final kd = perGuestFrom(e, v, audience, voucher: false);
    if (kd == null || kd < (price[0] as num) || kd > (price[1] as num)) return false;
  }
  final vprice = f['voucherPerGuest'] as List?;
  if (vprice != null) {
    final kd = perGuestFrom(e, v, audience, voucher: true);
    if (kd == null || kd < (vprice[0] as num) || kd > (vprice[1] as num)) return false;
  }
  final settings = list('settings');
  if (settings.isNotEmpty && !v.list('halls').any((h) => settings.contains(h['setting']))) return false;
  if (list('facilities').any((k) => !hasFacility(v, k))) return false;
  final date = brief['date'] as String?;
  if (f['available'] == true && date != null && date.isNotEmpty && row['availability'] != 'available' && row['availability'] != 'held') return false;
  final minRating = (f['minRating'] as num?)?.toDouble();
  if (minRating != null && ((v.obj('rating')['average'] as num?)?.toDouble() ?? 0) < minRating) return false;
  final levels = list('levels');
  if (levels.isNotEmpty && !levels.contains(v['tier'])) return false;
  final brands = list('brands');
  if (brands.isNotEmpty) {
    final b = brandOf(v);
    if (b == null || !brands.contains(b)) return false;
  }
  return true;
}

/// Halls a request can go to on the Brief date, in the Brief's areas (a held hall still takes a request, so it counts): the Home count.
int freeCount(EngineData e, Json brief) {
  final rows = searchResults(e, brief, const {});
  return rows.where((r) => r['availability'] == 'available' || r['availability'] == 'held').length;
}

/// Nearest Thursday-to-Saturday dates around the Brief date on which at least one venue of the Brief's areas is free.
List<String> nearestFreeDates(EngineData e, Json brief, {int count = 3}) {
  final around = brief['date'] as String?;
  if (around == null || around.isEmpty) return [];
  final today = kuwaitDateOf(e.now);
  final ids = [
    for (final r in searchResults(e, brief, const {}))
      if (r.obj('venue')['channel'] != 'external_link') r.obj('venue').str('id'),
  ];
  final out = <({String date, int gap})>[];
  for (var k = 1; k <= 21; k++) {
    for (final sign in const [1, -1]) {
      final d = addDays(around, k * sign);
      if (d.compareTo(today) < 0 || d == around) continue;
      if (weekdayOf(d) < 4) continue;
      if (ids.any((id) => e.venueAvailabilityOn(id, d, {...brief, 'date': d})['state'] == 'available')) out.add((date: d, gap: k));
    }
  }
  final sorted = stableSorted(out, (a, b) => a.gap - b.gap).take(count).map((x) => x.date).toList()..sort();
  return sorted;
}

// ---------------------------------------------------------------- the Home shelves

bool _notGovernment(Json r) => r.obj('venue')['channel'] != 'external_link';

/// The Home shelves for a Brief: `free`, `featured` (one row or null), `voucher`, `week` ([{row, date}]), `recommended`, `trending`, `nearby`.
({List<Json> free, Json? featured, List<Json> voucher, List<({Json row, String date})> week, List<Json> recommended, List<Json> trending, List<Json> nearby})
shelves(EngineData e, Json brief) {
  final areas = ((brief['areaIds'] as List?) ?? const []).cast<String>();
  final all = e.listVenues({'origin': areas.isNotEmpty ? 'ref-${areas.first}' : 'ref-salmiya'}, brief);
  bool inAreas(Json r) => areas.isEmpty || areas.contains(r.obj('venue')['areaId']);
  final date = brief['date'] as String?;
  final free = date != null && date.isNotEmpty ? all.where((r) => _notGovernment(r) && inAreas(r) && r['availability'] == 'available').toList() : <Json>[];
  final used = {for (final r in free) r.obj('venue').str('id')};

  // Featured: the first paid placement that is not already booked on the date.
  final pool = all.where((r) => r.obj('venue').obj('flags').flag('featured')).toList();
  final featured = pool.isEmpty
      ? null
      : stableSorted(pool, (a, b) => (b['availability'] != 'unavailable' ? 1 : 0) - (a['availability'] != 'unavailable' ? 1 : 0)).first;
  if (featured != null) used.add(featured.obj('venue').str('id'));

  bool open(Json r) => _notGovernment(r) && r['availability'] != 'unavailable';
  final recommended = all.where((r) => open(r) && !used.contains(r.obj('venue')['id'])).take(4).toList();
  for (final r in recommended) {
    used.add(r.obj('venue').str('id'));
  }
  final trending = stableSorted(
    all.where((r) => open(r) && !used.contains(r.obj('venue')['id'])),
    (a, b) => b.obj('venue').obj('rating').integer('count') - a.obj('venue').obj('rating').integer('count'),
  ).take(4).toList();
  final nearby = stableSorted(
    all.where((r) => _notGovernment(r) && r['distance'] != null),
    (a, b) => ((a.obj('distance')['minutes'] as num?) ?? 0).toInt() - ((b.obj('distance')['minutes'] as num?) ?? 0).toInt(),
  ).take(3).toList();

  final voucher = stableSorted(
    all.where(
      (r) =>
          _notGovernment(r) &&
          r['price'] != null &&
          r.obj('price')['voucher'] != null &&
          r.obj('price')['savings'] != null &&
          filsOf(r.obj('price').obj('savings')) > e.fee,
    ),
    (a, b) => filsOf(b.obj('price').obj('savings')) - filsOf(a.obj('price').obj('savings')),
  ).take(4).toList();

  return (free: free, featured: featured, voucher: voucher, week: _weekShelf(e, brief), recommended: recommended, trending: trending, nearby: nearby);
}

/// Free dates in the next seven days, one card per venue on its soonest such date; the first four by date then id.
List<({Json row, String date})> _weekShelf(EngineData e, Json brief) {
  final today = kuwaitDateOf(e.now);
  final days = [for (var k = 1; k <= 7; k++) addDays(today, k)];
  final audience = (brief['audience'] as String?) ?? 'women';
  final guests = (brief['guests'] as num?)?.toInt() ?? 350;
  final perDate = <String, List<Json>>{};
  final out = <({Json row, String date})>[];
  for (final v in e.venues) {
    if (v['channel'] == 'external_link') continue;
    String? date;
    for (final d in days) {
      if (e.venueAvailabilityOn(v.str('id'), d, {'audience': audience, 'guests': guests, 'date': d})['state'] == 'available') {
        date = d;
        break;
      }
    }
    if (date == null) continue;
    final rows = perDate[date] ??= e.listVenues(const {}, {
      'date': date,
      'guests': guests,
      'audience': audience,
      'areaIds': brief['areaIds'] ?? const <String>[],
    });
    final row = rows.cast<Json?>().firstWhere((r) => r!.obj('venue')['id'] == v['id'], orElse: () => null);
    if (row != null) out.add((row: row, date: date));
  }
  out.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : a.row.obj('venue').str('id').compareTo(b.row.obj('venue').str('id'));
  });
  return out.take(4).toList();
}

/// The venue ids behind a shelf (the same selection the Home rail draws): the "See all" of the shelf.
Set<String> shelfIds(EngineData e, String shelf, Json brief) {
  final s = shelves(e, brief);
  String id(Json r) => r.obj('venue').str('id');
  switch (shelf) {
    case 'free':
      return s.free.map(id).toSet();
    case 'featured':
      return {
        for (final v in e.venues)
          if (v.obj('flags').flag('featured')) v.str('id'),
      };
    case 'voucher':
      return e.listVenues({'voucherOnly': true}, brief).where((r) => r['price'] != null && r.obj('price')['voucher'] != null).map(id).toSet();
    case 'week':
      return s.week.map((c) => id(c.row)).toSet();
    case 'recommended':
      return s.recommended.map(id).toSet();
    default: // trending, nearby
      return {
        for (final v in e.venues)
          if (v['channel'] != 'external_link') v.str('id'),
      };
  }
}

// ---------------------------------------------------------------- the region search (CL-DISC-07)

/// Governorates and areas that hold a hall, then halls, matched with [foldSearch]; `{kind, id, name, governorateId, venueCount}`.
List<Json> regionMatches(EngineData e, String query) {
  final needle = foldSearch(query);
  if (needle.isEmpty) return [];
  bool hit(Iterable<String?> names) => names.any((x) => foldSearch(x ?? '').contains(needle));
  final perArea = <String, int>{};
  for (final v in e.venues) {
    perArea[v.str('areaId')] = (perArea[v.str('areaId')] ?? 0) + 1;
  }
  final out = <Json>[];
  final groups = <({Json governorate, List<Json> areas, int count})>[];
  for (final g in e.governorates) {
    final areas = e.areas.where((a) => a['governorateId'] == g['id'] && perArea.containsKey(a['id'])).toList();
    if (areas.isEmpty) continue;
    groups.add((governorate: g, areas: areas, count: areas.fold(0, (n, a) => n + perArea[a.str('id')]!)));
  }
  for (final g in groups) {
    final n = g.governorate.obj('name');
    if (hit([n.strOrNull('en'), n.strOrNull('ar')])) {
      out.add({'kind': 'governorate', 'id': g.governorate['id'], 'name': n, 'governorateId': g.governorate['id'], 'venueCount': g.count});
    }
  }
  for (final g in groups) {
    for (final a in g.areas) {
      final n = a.obj('name');
      if (hit([n.strOrNull('en'), n.strOrNull('ar'), ...a.strings('aliases')])) {
        out.add({'kind': 'area', 'id': a['id'], 'name': n, 'governorateId': a['governorateId'], 'venueCount': perArea[a.str('id')] ?? 0});
      }
    }
  }
  for (final v in e.venues) {
    if (_venueNameMatches(e, v, needle)) out.add({'kind': 'venue', 'id': v['id'], 'name': v['name'], 'governorateId': v['governorateId'], 'venueCount': 1});
  }
  return out;
}

/// The web's `matchesQuery`: the venue's names, its area's names and the area's aliases (no governorate).
bool _venueNameMatches(EngineData e, Json v, String needle) {
  final a = e.area(v.str('areaId'));
  final n = v.obj('name');
  return [
    n.strOrNull('en'),
    n.strOrNull('ar'),
    a?.obj('name').strOrNull('en'),
    a?.obj('name').strOrNull('ar'),
    ...(a?.strings('aliases') ?? const <String>[]),
  ].any((t) => foldSearch(t ?? '').contains(needle));
}
