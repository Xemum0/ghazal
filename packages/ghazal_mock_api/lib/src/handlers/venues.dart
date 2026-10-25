/// venues: search with filters, sort, facets and cursor pages; venue detail with package offers for the brief; availability by day; quotes;
/// compare; areas and region search. All reads go through the engine selectors that the shared engine cases prove equal to the prototype.
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/requests.dart';
import '../domain/views.dart';
import '../engine/engine.dart';

const _internalVenueKeys = {'demand', 'partnerAccountId', 'major'};

/// A venue as clients see it (internal fields stripped).
Json publicVenue(Json v) => {
  for (final e in v.entries)
    if (!_internalVenueKeys.contains(e.key)) e.key: e.value,
};

/// The search query of `searchVenues` and `countVenues` as the Discover logic takes it (see `engine/discover.dart`): the Brief (date, guests,
/// audience, areaIds) and the Filters sheet. `areaIds` is the Brief's area list: it narrows the list and ranks it; with a `shelf` it only ranks.
({Json filter, Json brief}) searchParams(Req r) {
  List<String>? list(String k) => r.qList(k).isEmpty ? null : r.qList(k);
  final areas = list('areaIds');
  final briefAreas = list('briefAreaIds') ?? areas;
  List<int>? range(String lo, String hi) => r.qInt(lo) != null || r.qInt(hi) != null ? [r.qInt(lo) ?? 0, r.qInt(hi) ?? 1 << 40] : null;
  final filter = <String, dynamic>{
    'query': r.q('q'),
    'areaIds': areas ?? (r.qBool('allAreas') == true ? const <String>[] : null),
    'governorateIds': list('governorateIds'),
    'types': list('types'),
    'styles': list('styles'),
    'levels': list('tiers'),
    'capacity': r.qInt('capacityMin') != null || r.qInt('capacityMax') != null ? {'min': r.qInt('capacityMin'), 'max': r.qInt('capacityMax')} : null,
    'priceStructure': r.q('priceStructure'),
    'voucherOnly': r.qBool('voucherOnly') == true ? true : null,
    'arrangement': r.q('arrangement'),
    'minRating': r.qNum('minRating'),
    'available': r.qBool('availableOnDate') == true ? true : null,
    'availableBetween': r.q('availableFrom') != null && r.q('availableTo') != null ? {'from': r.q('availableFrom'), 'to': r.q('availableTo')} : null,
    'withinMinutes': r.qInt('withinMinutes'),
    'perGuest': range('perGuestMin', 'perGuestMax'),
    'voucherPerGuest': range('voucherPerGuestMin', 'voucherPerGuestMax'),
    'settings': list('settings'),
    'facilities': list('facilities'),
    'brands': list('brands'),
    'category': r.q('category'),
    'shelf': r.q('shelf'),
    'sort': r.q('sort'),
    'origin': r.q('originId'),
  }..removeWhere((k, v) => v == null);
  if (filter['capacity'] is Map) (filter['capacity'] as Map).removeWhere((k, v) => v == null);
  final brief = <String, dynamic>{'date': r.q('date'), 'guests': r.qInt('guests'), 'audience': r.q('audience'), 'areaIds': briefAreas}
    ..removeWhere((k, v) => v == null);
  return (filter: filter, brief: brief);
}

/// The Results rows of a search: published venues only, in the web's order.
List<Json> searchRows(MockApp app, Req r) {
  final p = searchParams(r);
  final f = p.filter;
  final rows = searchResults(app.engine(), p.brief, f, sort: f['sort'] as String?, origin: f['origin'] as String?);
  final styles = (f['styles'] as List?)?.cast<String>();
  return rows.where((x) => x.obj('venue')['status'] == 'published' && (styles == null || styles.contains(x.obj('venue')['style']))).toList();
}

Json _stripDay(Json d) => {
  for (final e in d.entries)
    if (e.key != 'internalReason') e.key: e.value,
};

List<Json> _visibleVenues(MockApp app) => app.db.raw('Venue').where((v) => v['status'] == 'published').toList();

Map<String, Handler> venuesHandlers(MockApp app) => {
  'searchVenues': (r) {
    return pageMap(r, searchRows(app, r), venueResult);
  },
  'countVenues': (r) {
    return {'count': searchRows(app, r).length};
  },
  'getFilterTaxonomy': (r) {
    final t = app.seed.rows('FilterTaxonomy').first;
    return {
      'venueTypes': t['venueTypes'],
      'capacityRange': t['capacityRange'],
      'capacityBands': t['capacityBands'],
      'priceStructures': t['priceStructures'],
      'sorts': t['sorts'],
      'amenities': app.seed.rows('AmenityDef'),
    };
  },
  'getVenue': (r) {
    final id = r.p('venueId');
    final v = app.db.get('Venue', id);
    if (v == null || (v['status'] != 'published' && r.identity?.isPartner != true)) throw ApiError.notFound('venue');
    final brief = <String, dynamic>{'date': r.q('date'), 'guests': r.qInt('guests'), 'audience': r.q('audience')}..removeWhere((k, val) => val == null);
    final engine = app.engine();
    final date = brief['date'] as String?;
    final offers = <Json>[];
    final wantedHall = r.q('hallId');
    if (wantedHall != null && !v.list('halls').any((h) => h['id'] == wantedHall)) throw ApiError.validation('/hallId', 'unknown_hall');
    for (final pkg in engine.packagesFor(id)) {
      if (!pkg.flag('active')) continue;
      Json? forBrief;
      if (date != null && pkg['components'] == null) {
        // The hall being booked: the one asked for (its packages only), else the first hall of the package that has the Brief's audience.
        final audience = (brief['audience'] as String?) != null && pkg.strings('audiences').contains(brief['audience'])
            ? brief['audience'] as String
            : pkg.strings('audiences').first;
        Json? hall;
        if (wantedHall != null) {
          hall = pkg.strings('hallIds').contains(wantedHall) ? v.list('halls').firstWhere((h) => h['id'] == wantedHall) : null;
        } else {
          for (final hid in pkg.strings('hallIds')) {
            final cand = v.list('halls').cast<Json?>().firstWhere((h) => h!['id'] == hid, orElse: () => null);
            if (cand != null && cand.list('sections').any((s) => s['audience'] == audience)) {
              hall = cand;
              break;
            }
          }
          hall ??= pkg.strings('hallIds').isEmpty
              ? null
              : v.list('halls').cast<Json?>().firstWhere((h) => h!['id'] == pkg.strings('hallIds').first, orElse: () => null);
        }
        final sec = hall?.list('sections').cast<Json?>().firstWhere((s) => s!['audience'] == audience, orElse: () => null);
        if (hall != null && sec != null) {
          final minEff = effectiveMinGuests(pkg, sec.integer('minGuests'));
          final guests = (brief['guests'] as int?) ?? minEff;
          if (guests <= pkg.integer('maxGuests')) {
            final pp = packagePrice(
              pkg: pkg,
              rules: engine.priceRules.where((x) => x['scopeId'] == pkg['id']).toList(),
              windows: engine.activeWindows().where((w) => w['venueId'] == id).toList(),
              eventDate: date,
              now: app.now,
              hallId: hall.str('id'),
              guests: guests,
              hallMinGuests: sec.integer('minGuests'),
              serviceChargeBps: v.obj('policies').integer('serviceChargeBps'),
              voucherFeeFils: app.voucherFeeFils,
            );
            if (pp != null) {
              final offered = pp.flag('voucherEligible');
              forBrief = {
                'standard': pp['standard'],
                'voucher': offered ? pp['voucher'] : null,
                'savings': offered ? pp['savings'] : null,
                'voucherOffered': offered,
                'unit': pkg['priceUnit'],
                'hallId': hall['id'],
                'audience': audience,
                'perGuest': pp['perGuest'],
                'flat': pp['flat'],
                'voucherPerGuest': pp['voucherPerGuest'],
                'voucherFlat': pp['voucherFlat'],
                'billedGuests': pp['billed'],
                'billableGuests': pp['billable'],
                'tier': pp['tier'],
              };
            }
          }
        }
      }
      offers.add({'package': pkg, 'forBrief': forBrief});
    }
    return {
      'venue': publicVenue(v),
      'packages': offers,
      'extras': engine.extrasFor(id).where((e) => e.flag('active')).toList(),
      'windows': engine.activeWindows().where((w) => w['venueId'] == id).toList(),
      'price': engine.cardPrice(id, brief),
      'guestRange': engine.guestRange(id),
      'tags': engine.sectionTags(id),
      'structures': engine.structuresOf(id),
    };
  },
  'getVenueAvailability': (r) {
    final id = r.p('venueId');
    final v = app.db.peek('Venue', id) ?? (throw ApiError.notFound('venue'));
    final from = r.q('from')!, to = r.q('to')!;
    final guests = r.qInt('guests');
    final audience = r.q('audience');
    final halls = v.list('halls');
    Json? hall;
    if (r.q('hallId') != null) {
      hall = halls.cast<Json?>().firstWhere((h) => h!['id'] == r.q('hallId'), orElse: () => null) ?? (throw ApiError.notFound('hall'));
    } else {
      hall =
          halls.cast<Json?>().firstWhere(
            (h) =>
                (audience == null || h!.list('sections').any((s) => s['audience'] == audience)) &&
                (guests == null || h!.obj('capacity').integer('max') >= guests),
            orElse: () => null,
          ) ??
          halls.first;
    }
    if (diffDays(from, to) > 370) throw ApiError.validation('/to', 'range_too_long');
    final brief = <String, dynamic>{'guests': guests, 'audience': audience}..removeWhere((k, val) => val == null);
    final days = <Json>[];
    var month = monthOf(from);
    final engine = app.engine();
    while (month.compareTo(monthOf(to)) <= 0) {
      for (final d in engine.availabilityFor(id, hall.str('id'), month, brief)) {
        if (d.str('date').compareTo(from) >= 0 && d.str('date').compareTo(to) <= 0) days.add(_stripDay(d));
      }
      month = addMonths(month, 1);
    }
    return {'venueId': id, 'hallId': hall['id'], 'from': from, 'to': to, 'days': days};
  },
  'getVenueDayAvailability': (r) {
    final id = r.p('venueId');
    app.db.peek('Venue', id) ?? (throw ApiError.notFound('venue'));
    final brief = <String, dynamic>{'guests': r.qInt('guests'), 'audience': r.q('audience')}..removeWhere((k, val) => val == null);
    final out = app.engine().venueAvailabilityOn(id, r.q('date')!, brief);
    final day = out['day'] as Json?;
    return {'state': out['state'], 'hallId': out['hallId'], 'day': day == null ? null : _stripDay(day)};
  },
  'quoteVenue': (r) {
    final id = r.p('venueId');
    checkExtras(app, id, r.b.list('extras'));
    final built = buildSections(app, id, r.b.str('eventDate'), r.b.list('sections'), sessionRequired: false);
    final q = app.engine().quoteFor(venueId: id, eventDate: r.b.str('eventDate'), sections: built.quoteSections, extras: r.b.list('extras'));
    final qid = 'qt-${app.db.next('quote').toString().padLeft(5, '0')}';
    final expires = app.clock.after(const Duration(minutes: 30));
    app.db.put('Quote', {
      'id': qid,
      'venueId': id,
      'standardTotal': filsOf(q.obj('totals').obj('standardTotal')),
      'voucherTotal': filsOf(q.obj('totals').obj('voucherTotal')),
      'expiresAt': expires,
    });
    return wireQuote(q, targetType: 'venue', targetId: id, quoteId: qid, expiresAt: expires);
  },
  'listNearbyVenues': (r) {
    final id = r.p('venueId');
    app.db.peek('Venue', id) ?? (throw ApiError.notFound('venue'));
    return [
      for (final n in app.engine().nearby(id, (r.qInt('limit') ?? 6).clamp(1, 50)))
        {'venue': venueSummary(n.obj('venue')), 'minutes': n['minutes'], 'km': n['km']},
    ];
  },
  'compareVenues': (r) {
    final ids = r.b.strings('venueIds');
    final brief = <String, dynamic>{'date': r.b['date'], 'guests': r.b['guests'], 'audience': r.b['audience']}..removeWhere((k, v) => v == null);
    final cols = app.engine().compareSet(ids, brief, r.b.strOrNull('originId') ?? 'ref-salmiya');
    return {
      'columns': [
        for (final c in cols)
          {
            'venue': venueSummary(c.obj('venue')),
            for (final k in [
              'channel',
              'availability',
              'price',
              'voucherPrice',
              'savings',
              'fromPerGuest',
              'fromVoucherPerGuest',
              'maxGuests',
              'fits',
              'valet',
              'photography',
              'rating',
              'distance',
              'structures',
              'packages',
              'best',
            ])
              k: c[k],
          },
      ],
    };
  },
  'listAreas': (r) => {'governorates': app.seed.rows('Governorate'), 'areas': app.seed.rows('Area'), 'referencePoints': app.seed.rows('ReferencePoint')},
  'searchRegions': (r) {
    final published = _visibleVenues(app).map((v) => v['id']).toSet();
    return regionMatches(app.engine(), r.q('q') ?? '').where((m) => m['kind'] != 'venue' || published.contains(m['id'])).toList();
  },
};
