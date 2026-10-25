/// Pure read-side selectors over the catalog (venues, packages, prices, windows, claims, visits): the Dart twin of the engine-facing part of
/// packages/contracts/src/selectors.ts (search, card price, availability by venue, compare, quotes, visit slots). [EngineData] is a cheap view
/// over lists the database owns; handlers build one per request so edits made through the API (windows, packages, claims) show up at once.
library;

import 'availability.dart' as av;
import 'dates.dart';
import 'json.dart';
import 'money.dart';
import 'pricing.dart' as pr;
import 'text.dart';
import 'visits.dart';

/// Stable sort (Dart's `List.sort` is not stable; JavaScript's is, and the TypeScript selectors rely on it).
List<T> stableSorted<T>(Iterable<T> items, int Function(T a, T b) compare) {
  final indexed = [for (final e in items.indexed) e];
  indexed.sort((a, b) {
    final c = compare(a.$2, b.$2);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// A JavaScript-style numeric comparator result (NaN counts as equal) to an int.
int cmpNum(num d) => d.isNaN ? 0 : (d > 0 ? 1 : (d < 0 ? -1 : 0));

double _orInf(num? v) => v == null ? double.infinity : v.toDouble();

class EngineData {
  EngineData({
    required this.venues,
    required this.packages,
    required this.priceRules,
    required this.extras,
    required this.windows,
    required this.claims,
    required this.overrides,
    required this.areas,
    required this.governorates,
    required this.visits,
    required this.providers,
    required this.config,
    required this.now,
    this.explicitClaimVenues,
  });

  /// Venues whose calendar is decided by explicit claims alone (the seeded hotel). Null derives it from [claims], as the TypeScript selectors do;
  /// the running mock passes the seed's set so that a claim written for another venue never switches off that venue's seeded occupancy.
  final Set<String>? explicitClaimVenues;

  final List<Json> venues, packages, priceRules, extras, windows, claims, overrides, areas, governorates, visits, providers;
  final Json config;
  final String now;

  int get fee => config.integer('voucherFeeFils');

  late final Map<String, Json> _venueIx = {for (final v in venues) v.str('id'): v};
  late final Map<String, Json> _pkgIx = {for (final p in packages) p.str('id'): p};

  Json? venue(String id) => _venueIx[id];
  Json requireVenue(String id) => _venueIx[id] ?? (throw StateError('Unknown venue $id'));
  Json? package(String id) => _pkgIx[id];

  /// `{venue, hall}` of a hall id (`V01-danah` belongs to `V01`).
  ({Json venue, Json hall})? hallById(String hallId) {
    final v = _venueIx[hallId.split('-').first];
    if (v == null) return null;
    for (final h in v.list('halls')) {
      if (h['id'] == hallId) return (venue: v, hall: h);
    }
    return null;
  }

  List<Json> packagesFor(String venueId) =>
      stableSorted(packages.where((p) => p['venueId'] == venueId), (a, b) => (a.intOrNull('sortOrder') ?? 0) - (b.intOrNull('sortOrder') ?? 0));
  List<Json> extrasFor(String venueId) => extras.where((e) => e['venueId'] == venueId).toList();
  List<Json> rulesFor(String scopeId) => priceRules.where((r) => r['scopeId'] == scopeId).toList();
  Json? area(String id) => areas.cast<Json?>().firstWhere((a) => a!['id'] == id, orElse: () => null);
  Json? governorate(String id) => governorates.cast<Json?>().firstWhere((g) => g!['id'] == id, orElse: () => null);

  /// Voucher windows live at [at] (active, started, not ended).
  List<Json> activeWindows([String? at]) {
    final t = at ?? now;
    return windows
        .where((w) => w['status'] == 'active' && w.str('startsAt').compareTo(t) <= 0 && (w['endsAt'] == null || w.str('endsAt').compareTo(t) > 0))
        .toList();
  }

  // ---------------------------------------------------------------- availability and price

  av.AvailabilityContext ctxFor(Json venue, Json hall, String at) {
    final vid = venue.str('id');
    final hasClaims = explicitClaimVenues != null ? explicitClaimVenues!.contains(vid) : claims.any((c) => c['venueId'] == vid);
    return av.AvailabilityContext(
      venue: venue,
      hall: hall,
      packages: packagesFor(vid),
      rules: priceRules.where((r) => r['scope'] == 'package' && (r['scopeId'] as String).startsWith('$vid-')).toList(),
      windows: activeWindows(at).where((w) => w['venueId'] == vid).toList(),
      claims: hasClaims || explicitClaimVenues != null ? claims.where((c) => c['hallId'] == hall['id']).toList() : const [],
      overrides: overrides.where((o) => o['hallId'] == hall['id']).toList(),
      now: at,
      voucherFeeFils: fee,
      generate: !hasClaims,
    );
  }

  /// One month of one hall: per-day state and the lowest eligible package price for the brief.
  List<Json> availabilityFor(String venueId, String hallId, String month, [Json brief = const {}, String? at]) {
    final found = hallById(hallId);
    if (found == null || found.venue['id'] != venueId) return [];
    return av.availabilityFor(ctxFor(found.venue, found.hall, at ?? now), month, brief);
  }

  static const _rank = {'available': 0, 'held': 1, 'unavailable': 2, 'closed': 3};

  /// Best state across the halls that allow the audience: available beats held beats unavailable. Government halls are `unknown`.
  /// Returns `{state, hallId, day}`.
  Json venueAvailabilityOn(String venueId, String date, [Json brief = const {}, String? at]) {
    final v = venue(venueId);
    if (v == null || v['channel'] == 'external_link') return {'state': 'unknown', 'hallId': null, 'day': null};
    final audience = brief['audience'] as String?;
    final guests = (brief['guests'] as num?)?.toInt();
    final halls = v
        .list('halls')
        .where(
          (h) =>
              (audience != null ? h.list('sections').any((s) => s['audience'] == audience) : true) &&
              (guests != null && guests != 0 ? h.obj('capacity').integer('max') >= guests : true),
        );
    Json best = {'state': 'closed', 'hallId': null, 'day': null};
    for (final hall in halls) {
      final days = availabilityFor(venueId, hall.str('id'), monthOf(date), brief, at);
      final day = days.cast<Json?>().firstWhere((d) => d!['date'] == date, orElse: () => null);
      if (day == null) continue;
      final bestDay = best['day'] as Json?;
      final dayFrom = day['fromPrice'] as Json?;
      final bestFrom = bestDay?['fromPrice'] as Json?;
      if (bestDay == null ||
          (_rank[day['state']] ?? 9) < (_rank[bestDay['state']] ?? 9) ||
          (day['state'] == bestDay['state'] && dayFrom != null && (bestFrom == null || filsOf(dayFrom) < filsOf(bestFrom)))) {
        best = {'state': day['state'], 'hallId': hall['id'], 'day': day};
      }
    }
    return best;
  }

  Json? _cheapestRuleFor(Json pkg) {
    Json? best;
    double score(Json r) {
      final mg = pkg.integer('minGuests');
      return filsOf(r.objOrNull('perGuest')) + filsOf(r.objOrNull('flat')) / (mg == 0 ? 100 : (mg > 1 ? mg : 1));
    }

    for (final r in rulesFor(pkg.str('id'))) {
      if (best == null || score(r) < score(best)) best = r;
    }
    return best;
  }

  int _sectionMin(Json venue, Json pkg, String audience) {
    final mins = [
      for (final h in venue.list('halls'))
        if (pkg.strings('hallIds').contains(h['id']))
          for (final s in h.list('sections'))
            if (s['audience'] == audience) s.integer('minGuests'),
    ];
    return mins.isEmpty ? 0 : mins.reduce((a, b) => a < b ? a : b);
  }

  ({Json? voucher, Json? savings}) _withVoucher(Json standard, Json? voucher) {
    if (voucher == null) return (voucher: null, savings: null);
    final savings = subMoney(standard, voucher);
    return filsOf(savings) > fee ? (voucher: voucher, savings: savings) : (voucher: null, savings: null);
  }

  /// The price line of a card as data (ADR 0004 D6, ADR 0018 D4, ADR 0033 D4): the standard `amount` and the `voucher` price beside it.
  Json? cardPrice(String venueId, [Json brief = const {}, String? at]) {
    final v = venue(venueId);
    if (v == null) return null;
    final fees = v.objOrNull('officialFees');
    if (fees != null) return {'mode': 'rental_fee', 'amount': fees['rent'], 'voucher': null, 'savings': null};
    final hasWomen = v.list('halls').any((h) => h.list('sections').any((s) => s['audience'] == 'women'));
    final audience = (brief['audience'] as String?) ?? (hasWomen ? 'women' : 'men');
    final pkgs = packagesFor(venueId).where((p) => p.flag('active') && p['components'] == null && p.strings('audiences').contains(audience)).toList();
    final hasAllIn = pkgs.any((p) => p['archetype'] != 'hall_only');
    final eligible = pkgs.where((p) => !(hasAllIn && p['archetype'] == 'hall_only')).toList();
    if (eligible.isEmpty) return null;
    final date = brief['date'] as String?;
    final briefGuests = (brief['guests'] as num?)?.toInt();
    final hasGuests = briefGuests != null && briefGuests != 0;

    if (date != null && date.isNotEmpty && hasGuests) {
      Json? bestDay;
      for (final hall in v.list('halls')) {
        if (!hall.list('sections').any((s) => s['audience'] == audience)) continue;
        final days = availabilityFor(venueId, hall.str('id'), monthOf(date), {...brief, 'audience': audience}, at);
        final day = days.cast<Json?>().firstWhere((d) => d!['date'] == date, orElse: () => null);
        final from = day?['fromPrice'] as Json?;
        if (from != null && (bestDay == null || filsOf(from) < filsOf(bestDay['fromPrice'] as Json?))) bestDay = day;
      }
      if (bestDay != null && bestDay['fromPrice'] != null && bestDay['packageId'] != null) {
        final pkg = package(bestDay.str('packageId'));
        final from = bestDay.obj('fromPrice');
        final vp = {'voucher': bestDay['voucherPrice'], 'savings': bestDay['voucherPrice'] != null ? subMoney(from, bestDay.obj('voucherPrice')) : null};
        if (pkg != null && pkg['pricingBasis'] == 'flat') {
          return {'mode': 'flat_night', 'amount': from, 'hasSeveralPackages': eligible.length > 1, 'packageId': pkg['id'], ...vp};
        }
        return {'mode': 'exact', 'amount': from, 'guests': briefGuests, 'packageId': bestDay['packageId'], 'tier': bestDay['tier'], ...vp};
      }
    }

    ({Json amount, Json? voucher, Json pkg, Json rule, int guests, bool atMinimum})? best;
    for (final pkg in eligible) {
      final rule = _cheapestRuleFor(pkg);
      if (rule == null) continue;
      final minEff = pr.effectiveMinGuests(pkg, _sectionMin(v, pkg, audience));
      final want = hasGuests ? briefGuests : (briefGuests ?? minEff);
      if (want > pkg.integer('maxGuests')) continue;
      final billed = want > minEff ? want : minEff;
      final billable = billed - floorDiv(billed * pkg.integer('complimentaryBps'), 10000);
      Json total(Json? flat, Json? per) => addMoney([flat ?? zero(), per != null ? mulMoney(per, billable) : zero()]);
      final amount = total(rule.objOrNull('flat'), rule.objOrNull('perGuest'));
      final hasV = rule['voucherFlat'] != null || rule['voucherPerGuest'] != null;
      final voucher = hasV
          ? total(rule.objOrNull('voucherFlat') ?? rule.objOrNull('flat'), rule.objOrNull('voucherPerGuest') ?? rule.objOrNull('perGuest'))
          : null;
      if (best == null || filsOf(amount) < filsOf(best.amount)) {
        best = (amount: amount, voucher: voucher, pkg: pkg, rule: rule, guests: billed, atMinimum: briefGuests == null || briefGuests < minEff);
      }
    }
    if (best == null) return null;
    final vp = _withVoucher(best.amount, best.voucher);
    if (best.pkg['pricingBasis'] == 'flat') {
      return {
        'mode': 'flat_night',
        'amount': best.amount,
        'hasSeveralPackages': eligible.length > 1,
        'packageId': best.pkg['id'],
        'voucher': vp.voucher,
        'savings': vp.savings,
      };
    }
    if (hasGuests && !best.atMinimum) {
      return {
        'mode': 'from_guests',
        'amount': best.amount,
        'guests': briefGuests,
        'packageId': best.pkg['id'],
        'tier': best.rule['tier'],
        'voucher': vp.voucher,
        'savings': vp.savings,
      };
    }
    return {
      'mode': 'from_minimum',
      'amount': best.amount,
      'guests': best.guests,
      'perGuest': best.rule['perGuest'],
      'voucherPerGuest': vp.voucher != null ? best.rule['voucherPerGuest'] : null,
      'packageId': best.pkg['id'],
      'voucher': vp.voucher,
      'savings': vp.savings,
    };
  }

  /// Guest range for a card: smallest per-guest package minimum to the largest hall capacity (ADR 0018 D3).
  Json? guestRange(String venueId) {
    final v = venue(venueId);
    if (v == null) return null;
    final perGuest = packagesFor(venueId).where((p) => p.flag('active') && p['components'] == null && p['pricingBasis'] != 'flat');
    final mins = [
      for (final p in perGuest)
        for (final a in p.strings('audiences')) pr.effectiveMinGuests(p, _sectionMin(v, p, a)),
    ];
    final halls = v.list('halls');
    final min = mins.isNotEmpty ? mins.reduce((a, b) => a < b ? a : b) : halls.map((h) => h.obj('capacity').integer('min')).reduce((a, b) => a < b ? a : b);
    final max = halls.map((h) => h.obj('capacity').integer('max')).reduce((a, b) => a > b ? a : b);
    return {'min': min, 'max': max};
  }

  /// Section tags of a card (women, men, mixed); empty when there is a single arrangement.
  List<String> sectionTags(String venueId) {
    final v = venue(venueId);
    if (v == null) return [];
    final set = {
      for (final h in v.list('halls'))
        for (final s in h.list('sections')) s.str('audience'),
    };
    final tags = ['women', 'men', 'mixed'].where(set.contains).toList();
    return tags.length > 1 ? tags : [];
  }

  /// Pricing structures a venue sells: per person, bundled packages, or both.
  List<String> structuresOf(String venueId) {
    final set = packagesFor(venueId).where((p) => p.flag('active') && p['components'] == null).map((p) => p.str('priceStructure')).toSet();
    return ['per_person', 'package'].where(set.contains).toList();
  }

  // ---------------------------------------------------------------- venue lists and search

  bool _includesQuery(Json v, String q) {
    final s = normalizeSearch(q);
    if (s.isEmpty) return true;
    final a = area(v.str('areaId'));
    final g = governorate(v.str('governorateId'));
    final hay = <String>[
      v.obj('name').strOrNull('en') ?? '',
      v.obj('name').strOrNull('ar') ?? '',
      a?.obj('name').strOrNull('en') ?? '',
      a?.obj('name').strOrNull('ar') ?? '',
      ...(a?.strings('aliases') ?? const <String>[]),
      g?.obj('name').strOrNull('en') ?? '',
      g?.obj('name').strOrNull('ar') ?? '',
    ].map(normalizeSearch);
    return hay.any((t) => t.contains(s));
  }

  ({int min, int max}) _venueCapacity(Json v) {
    final halls = v.list('halls');
    return (
      min: halls.map((h) => h.obj('capacity').integer('min')).reduce((a, b) => a < b ? a : b),
      max: halls.map((h) => h.obj('capacity').integer('max')).reduce((a, b) => a > b ? a : b),
    );
  }

  /// Search and filter venues (CA-FLT). [filter] keys: governorateIds, areaIds, types, styles, tiers, capacity {min,max}, priceStructure, voucherOnly,
  /// audience, minRating, availableOnDate, availableBetween {from,to}, query, sort, origin. [brief]: date, guests, audience, areaIds.
  /// Rows: `{venue, price, availability, availabilityHallId, badge, windowId, guestRange, structures, tags, distance, sponsored}`.
  List<Json> listVenues([Json filter = const {}, Json brief = const {}, String? at]) {
    final t = at ?? now;
    final briefAreas = (brief['areaIds'] as List?)?.cast<String>();
    final origin = (filter['origin'] as String?) ?? (briefAreas != null && briefAreas.isNotEmpty ? 'ref-${briefAreas.first}' : null);
    final audience = (brief['audience'] as String?) ?? (filter['audience'] as String?);
    final briefGuests = (brief['guests'] as num?)?.toInt() ?? 0;
    final briefDate = brief['date'] as String?;
    final rows = <Json>[];
    List<String>? list(String k) => (filter[k] as List?)?.cast<String>();
    for (final v in venues) {
      final areaIds = list('areaIds');
      final govIds = list('governorateIds');
      final types = list('types');
      final styles = list('styles');
      final tiers = list('tiers');
      if (areaIds != null && areaIds.isNotEmpty && !areaIds.contains(v['areaId'])) continue;
      if (govIds != null && govIds.isNotEmpty && !govIds.contains(v['governorateId'])) continue;
      if (types != null && types.isNotEmpty && !types.contains(v['type'])) continue;
      if (styles != null && styles.isNotEmpty && !styles.contains(v['style'])) continue;
      if (tiers != null && !tiers.contains(v['tier'])) continue;
      final minRating = (filter['minRating'] as num?)?.toDouble();
      if (minRating != null && minRating != 0 && ((v.obj('rating')['average'] as num?)?.toDouble() ?? 0) < minRating) continue;
      final fAud = filter['audience'] as String?;
      if (fAud != null && !v.list('halls').any((h) => h.list('sections').any((s) => s['audience'] == fAud))) continue;
      if (filter['voucherOnly'] == true && !v.flag('voucherEnabled')) continue;
      final ps = filter['priceStructure'] as String?;
      if (ps != null && ps != 'either' && !structuresOf(v.str('id')).contains(ps)) continue;
      final cap = filter['capacity'] as Map?;
      if (cap != null) {
        final c = _venueCapacity(v);
        if (cap['min'] != null && c.max < (cap['min'] as num)) continue;
        if (cap['max'] != null && c.min > (cap['max'] as num)) continue;
      }
      final q = filter['query'] as String?;
      if (q != null && q.isNotEmpty && !_includesQuery(v, q)) continue;
      if (briefGuests != 0 &&
          v['channel'] != 'external_link' &&
          v.list('halls').map((h) => h.obj('capacity').integer('max')).reduce((a, b) => a > b ? a : b) < briefGuests) {
        continue;
      }
      final b = <String, dynamic>{...brief, 'audience': ?audience};
      final avail = briefDate != null && briefDate.isNotEmpty ? venueAvailabilityOn(v.str('id'), briefDate, b, t) : null;
      if (filter['availableOnDate'] == true && briefDate != null && briefDate.isNotEmpty && (v['channel'] == 'external_link' || avail?['state'] != 'available')) {
        continue;
      }
      final between = filter['availableBetween'] as Map?;
      if (between != null) {
        if (v['channel'] == 'external_link') continue;
        final dates = datesBetween(between['from'] as String, between['to'] as String).take(62);
        if (!dates.any((d) => venueAvailabilityOn(v.str('id'), d, b, t)['state'] == 'available')) continue;
      }
      final price = cardPrice(v.str('id'), b, t);
      String? windowId;
      if (price != null && briefDate != null && briefDate.isNotEmpty && price['mode'] != 'rental_fee') {
        final w = pr.bestWindow(windows.where((x) => x['venueId'] == v['id']), eventDate: briefDate, now: t, packageId: price.str('packageId'));
        windowId = w?.str('id');
      }
      final flags = v.obj('flags');
      rows.add({
        'venue': v,
        'price': price,
        'availability': avail?['state'],
        'availabilityHallId': avail?['hallId'],
        'badge': windowId != null ? 'window' : (flags.flag('featured') ? 'featured' : null),
        'windowId': windowId,
        'guestRange': guestRange(v.str('id')),
        'structures': structuresOf(v.str('id')),
        'tags': sectionTags(v.str('id')),
        'distance': origin != null ? v.obj('distances')[origin] : null,
        'sponsored': flags.flag('sponsored'),
      });
    }
    final sort = (filter['sort'] as String?) ?? 'recommended';
    double score(Json r) {
      final v = r.obj('venue');
      final rating = v.obj('rating');
      var s = ((rating['average'] as num?)?.toDouble() ?? 3.8) * 10 + (rating.integer('count') < 200 ? rating.integer('count') : 200) / 40;
      if (briefAreas != null && briefAreas.contains(v['areaId'])) s += 25;
      if (r['availability'] == 'available') s += 12;
      if (r['availability'] == 'unavailable') s -= 30;
      if (v.obj('flags').flag('featured')) s += 3;
      if (v['channel'] == 'external_link') s -= 8;
      return s;
    }

    return stableSorted(rows, (a, b) {
      switch (sort) {
        case 'voucher_price':
          return cmpNum(
            _orInf(((a['price'] as Json?)?['voucher'] as Json?)?['fils'] as num?) - _orInf(((b['price'] as Json?)?['voucher'] as Json?)?['fils'] as num?),
          );
        case 'price':
          return cmpNum(
            _orInf(((a['price'] as Json?)?['amount'] as Json?)?['fils'] as num?) - _orInf(((b['price'] as Json?)?['amount'] as Json?)?['fils'] as num?),
          );
        case 'rating':
          return cmpNum(((b.obj('venue').obj('rating')['average'] as num?) ?? 0) - ((a.obj('venue').obj('rating')['average'] as num?) ?? 0));
        case 'distance':
          return cmpNum(_orInf((a['distance'] as Json?)?['minutes'] as num?) - _orInf((b['distance'] as Json?)?['minutes'] as num?));
        case 'newest':
          return (b.obj('venue').obj('flags').flag('isNew') ? 1 : 0) - (a.obj('venue').obj('flags').flag('isNew') ? 1 : 0);
        default:
          return cmpNum(score(b) - score(a));
      }
    });
  }

  /// Region and name search of CL-DISC-07: governorate, area or venue, Arabic-normalised, with the number of venues behind each.
  List<Json> searchRegions(String query) {
    final s = normalizeSearch(query);
    if (s.isEmpty) return [];
    final out = <Json>[];
    bool hit(Iterable<String?> names) => names.any((t) => normalizeSearch(t ?? '').contains(s));
    for (final g in governorates) {
      final n = g.obj('name');
      if (hit([n.strOrNull('en'), n.strOrNull('ar')])) {
        out.add({
          'kind': 'governorate',
          'id': g['id'],
          'name': n,
          'governorateId': g['id'],
          'venueCount': venues.where((v) => v['governorateId'] == g['id']).length,
        });
      }
    }
    for (final a in areas) {
      final n = a.obj('name');
      if (hit([n.strOrNull('en'), n.strOrNull('ar'), ...a.strings('aliases')])) {
        out.add({
          'kind': 'area',
          'id': a['id'],
          'name': n,
          'governorateId': a['governorateId'],
          'venueCount': venues.where((v) => v['areaId'] == a['id']).length,
        });
      }
    }
    for (final v in venues) {
      final n = v.obj('name');
      if (hit([n.strOrNull('en'), n.strOrNull('ar')])) {
        out.add({'kind': 'venue', 'id': v['id'], 'name': n, 'governorateId': v['governorateId'], 'venueCount': 1});
      }
    }
    return out;
  }

  /// Venues near another venue or a reference point, nearest first: `{venue, minutes, km}`.
  List<Json> nearby(String from, [int limit = 6]) {
    final origin = venue(from);
    final out = <Json>[];
    for (final v in venues) {
      if (v['id'] == from) continue;
      if (origin != null) {
        final vg = v.obj('geo');
        final og = origin.obj('geo');
        final d = ((vg['lat'] as num) - (og['lat'] as num)).abs() + ((vg['lng'] as num) - (og['lng'] as num)).abs();
        out.add({'venue': v, 'minutes': jsRound(d * 400), 'km': jsRound(d * 110) > 1 ? jsRound(d * 110) : 1});
      } else {
        final dist = v.obj('distances')[from] as Map?;
        if (dist != null) out.add({'venue': v, 'minutes': dist['minutes'], 'km': dist['km']});
      }
    }
    return stableSorted(out, (a, b) => (a['minutes'] as num).toInt() - (b['minutes'] as num).toInt()).take(limit).toList();
  }

  // ---------------------------------------------------------------- compare (ADR 0009)

  /// Compare up to three venues: columns as `CompareColumn` with the full venue under `venue`.
  List<Json> compareSet(List<String> ids, [Json brief = const {}, String origin = 'ref-salmiya', String? at]) {
    final audience = (brief['audience'] as String?) ?? 'women';
    final guests = (brief['guests'] as num?)?.toInt();
    final date = brief['date'] as String?;
    final cols = <Json>[];
    for (final id in ids.take(3)) {
      final v = venue(id);
      if (v == null) continue;
      final price = cardPrice(id, {...brief, 'audience': audience}, at);
      final exact = price != null && price['mode'] == 'exact' ? price : null;
      final avail = date != null && date.isNotEmpty ? venueAvailabilityOn(id, date, {...brief, 'audience': audience}, at)['state'] : null;
      final pk = packagesFor(id)
          .where((p) => p.flag('active') && p['components'] == null && p['archetype'] != 'hall_only' && p.strings('audiences').contains(audience))
          .toList();
      final rules = pk.expand((p) => rulesFor(p.str('id'))).toList();
      final perGuest = [
        for (final r in rules)
          if (r['perGuest'] != null) r.obj('perGuest'),
      ];
      final vPerGuest = [
        for (final r in rules)
          if (r['voucherPerGuest'] != null) r.obj('voucherPerGuest'),
      ];
      Json? lowest(List<Json> l) => l.isEmpty ? null : l.reduce((a, b) => filsOf(a) <= filsOf(b) ? a : b);
      final low = lowest(perGuest);
      final lowV = lowest(vPerGuest);
      Json? sec;
      for (final h in v.list('halls')) {
        for (final s in h.list('sections')) {
          if (sec == null && s['audience'] == audience) sec = s;
        }
      }
      final hallMax = v.list('halls').map((h) => h.obj('capacity').integer('max')).reduce((a, b) => a > b ? a : b);
      Json? valet;
      for (final a in v.list('amenities')) {
        if (a['amenityId'] == 'valet') {
          valet = a;
          break;
        }
      }
      cols.add({
        'venue': v,
        'channel': v['channel'],
        'availability': avail,
        'price': exact?['amount'],
        'voucherPrice': exact?['voucher'],
        'savings': exact?['savings'],
        'fromPerGuest': low,
        'fromVoucherPerGuest': lowV,
        'maxGuests': hallMax,
        'fits': guests != null && guests != 0 ? guests <= hallMax : true,
        'valet': valet?['state'],
        'photography': sec?.obj('policy')['photography'],
        'rating': v['rating'],
        'distance': v.obj('distances')[origin],
        'structures': structuresOf(id),
        'packages': {'count': pk.length, 'from': low, 'fromVoucher': lowV},
        'best': {'price': false, 'nearest': false, 'fit': false},
      });
    }
    num headline(Json c) => filsOf((c['voucherPrice'] ?? c['price']) as Json?);
    final priced = cols.where((c) => c['price'] != null).toList();
    if (priced.length > 1) {
      final low = priced.map(headline).reduce((a, b) => a < b ? a : b);
      for (final c in priced) {
        c.obj('best')['price'] = headline(c) == low;
      }
    }
    if (guests != null && guests != 0) {
      final fitting = cols.where((c) => c['channel'] != 'external_link' && c.integer('maxGuests') >= guests).toList();
      if (fitting.length > 1) {
        final tightest = fitting.map((c) => c.integer('maxGuests')).reduce((a, b) => a < b ? a : b);
        for (final c in fitting) {
          c.obj('best')['fit'] = c.integer('maxGuests') == tightest;
        }
      }
    }
    final near = cols.where((c) => c['distance'] != null && c['channel'] != 'external_link').toList();
    if (near.length > 1) {
      final m = near.map((c) => (c.obj('distance')['minutes'] as num)).reduce((a, b) => a < b ? a : b);
      for (final c in near) {
        c.obj('best')['nearest'] = c.obj('distance')['minutes'] == m;
      }
    }
    return cols;
  }

  // ---------------------------------------------------------------- quotes

  /// Quote one booking shape for a venue (both columns). Throws [StateError] on an unknown hall, package or an unsold date.
  Json quoteFor({
    required String venueId,
    required String eventDate,
    required List<Json> sections,
    List<Json> extras = const [],
    Json? venueDiscount,
    String? at,
  }) {
    final v = requireVenue(venueId);
    final t = at ?? now;
    final secs = <Json>[];
    for (final s in sections) {
      final found = hallById(s.str('hallId'));
      final pkg = package(s.str('packageId'));
      if (found == null || pkg == null) throw StateError('Unknown hall or package: ${s['hallId']} ${s['packageId']}');
      final sec = found.hall.list('sections').cast<Json?>().firstWhere((x) => x!['audience'] == s['audience'], orElse: () => null);
      secs.add({'hallId': s['hallId'], 'audience': s['audience'], 'guests': s['guests'], 'package': pkg, 'hallMinGuests': sec?.integer('minGuests') ?? 0});
    }
    final ex = <Json>[];
    for (final e in extras) {
      final x = this.extras.cast<Json?>().firstWhere((y) => y!['id'] == e['extraId'], orElse: () => null);
      if (x != null) ex.add({'extra': x, 'qty': e['qty']});
    }
    return pr.quote(
      venueId: venueId,
      eventDate: eventDate,
      now: t,
      sections: secs,
      rules: priceRules,
      extras: ex,
      voucherWindows: activeWindows(t).where((w) => w['venueId'] == venueId).toList(),
      venueDiscount: venueDiscount,
      serviceChargeBps: v.obj('policies').integer('serviceChargeBps'),
      voucherFeeFils: fee,
    );
  }

  /// Quote a provider package: quantity times the unit price, standard and voucher.
  Json quoteForProvider({required String providerId, required String packageId, required int qty, Json? venueDiscount}) {
    final provider = providers.cast<Json?>().firstWhere((p) => p!['id'] == providerId, orElse: () => null);
    final pkg = provider?.list('packages').cast<Json?>().firstWhere((p) => p!['id'] == packageId, orElse: () => null);
    if (provider == null || pkg == null) throw StateError('Unknown provider package: $providerId $packageId');
    return pr.quoteProviderPackage(providerId: providerId, pkg: pkg, qty: qty, venueDiscount: venueDiscount, voucherFeeFils: fee);
  }

  // ---------------------------------------------------------------- visits

  /// Bookable 30-minute arrival windows of a venue on a date: the partner's weekly rules minus past slots and slots already taken.
  List<Json> visitSlotsFor(String venueId, String date, [String? at]) {
    final v = venue(venueId);
    final rules = v?.list('visitSlots') ?? const <Json>[];
    if (v == null || rules.isEmpty) return [];
    final t = at ?? now;
    final taken = visits.where((x) => x['venueId'] == venueId && !['declined', 'cancelled'].contains(x['status'])).map((x) => x.str('slotStart')).toSet();
    return [
      for (final time in slotTimesOn(rules, date))
        () {
          final start = '${date}T$time:00+03:00';
          return <String, dynamic>{'start': start, 'available': start.compareTo(t) > 0 && !taken.contains(start)};
        }(),
    ];
  }

  /// The next dates (from tomorrow) on which a venue has at least one bookable visit slot.
  List<String> visitDatesFor(String venueId, [int days = 14, String? at]) {
    final t = at ?? now;
    final from = addDays(kuwaitDateOf(t), 1);
    return datesBetween(from, addDays(from, days - 1)).where((d) => visitSlotsFor(venueId, d, t).any((s) => s['available'] == true)).toList();
  }
}
