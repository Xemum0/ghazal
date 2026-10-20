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
Json publicVenue(Json v) => {for (final e in v.entries) if (!_internalVenueKeys.contains(e.key)) e.key: e.value};

({Json filter, Json brief}) searchParams(Req r) {
  final filter = <String, dynamic>{
    'query': r.q('q'),
    'governorateIds': r.qList('governorateIds').isEmpty ? null : r.qList('governorateIds'),
    'areaIds': r.qList('areaIds').isEmpty ? null : r.qList('areaIds'),
    'types': r.qList('types').isEmpty ? null : r.qList('types'),
    'styles': r.qList('styles').isEmpty ? null : r.qList('styles'),
    'tiers': r.qList('tiers').isEmpty ? null : r.qList('tiers'),
    'capacity': r.qInt('capacityMin') != null || r.qInt('capacityMax') != null ? {'min': r.qInt('capacityMin'), 'max': r.qInt('capacityMax')} : null,
    'priceStructure': r.q('priceStructure'),
    'voucherOnly': r.qBool('voucherOnly') == true ? true : null,
    'audience': r.q('audience'),
    'minRating': r.qNum('minRating'),
    'availableOnDate': r.qBool('availableOnDate') == true ? true : null,
    'availableBetween': r.q('availableFrom') != null && r.q('availableTo') != null ? {'from': r.q('availableFrom'), 'to': r.q('availableTo')} : null,
    'sort': r.q('sort'),
    'origin': r.q('originId'),
  }..removeWhere((k, v) => v == null);
  if (filter['capacity'] is Map) (filter['capacity'] as Map).removeWhere((k, v) => v == null);
  final brief = <String, dynamic>{'date': r.q('date'), 'guests': r.qInt('guests'), 'audience': r.q('audience')}..removeWhere((k, v) => v == null);
  return (filter: filter, brief: brief);
}

Json _stripDay(Json d) => {for (final e in d.entries) if (e.key != 'internalReason') e.key: e.value};

List<Json> _visibleVenues(MockApp app) => app.db.raw('Venue').where((v) => v['status'] == 'published').toList();

Map<String, Handler> venuesHandlers(MockApp app) => {
      'searchVenues': (r) {
        final p = searchParams(r);
        final rows = app.engine().listVenues(p.filter, p.brief).where((x) => x.obj('venue')['status'] == 'published').toList();
        return pageMap(r, rows, venueResult);
      },
      'countVenues': (r) {
        final p = searchParams(r);
        return {'count': app.engine().listVenues(p.filter, p.brief).where((x) => x.obj('venue')['status'] == 'published').length};
      },
      'getFilterTaxonomy': (r) {
        final t = app.seed.rows('FilterTaxonomy').first;
        return {'venueTypes': t['venueTypes'], 'capacityRange': t['capacityRange'], 'capacityBands': t['capacityBands'], 'priceStructures': t['priceStructures'], 'sorts': t['sorts'], 'amenities': app.seed.rows('AmenityDef')};
      },
      'getVenue': (r) {
        final id = r.p('venueId');
        final v = app.db.get('Venue', id);
        if (v == null || (v['status'] != 'published' && r.identity?.isPartner != true)) throw ApiError.notFound('venue');
        final brief = <String, dynamic>{'date': r.q('date'), 'guests': r.qInt('guests'), 'audience': r.q('audience')}..removeWhere((k, val) => val == null);
        final engine = app.engine();
        final date = brief['date'] as String?;
        final offers = <Json>[];
        for (final pkg in engine.packagesFor(id)) {
          if (!pkg.flag('active')) continue;
          Json? forBrief;
          if (date != null) {
            final hallId = pkg.strings('hallIds').isEmpty ? null : pkg.strings('hallIds').first;
            final hall = v.list('halls').cast<Json?>().firstWhere((h) => h!['id'] == hallId, orElse: () => null);
            if (hall != null && pkg['components'] == null) {
              final audience = (brief['audience'] as String?) != null && pkg.strings('audiences').contains(brief['audience']) ? brief['audience'] as String : pkg.strings('audiences').first;
              final sec = hall.list('sections').cast<Json?>().firstWhere((s) => s!['audience'] == audience, orElse: () => null);
              if (sec != null) {
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
                    forBrief = {'standard': pp['standard'], 'voucher': offered ? pp['voucher'] : null, 'savings': offered ? pp['savings'] : null, 'voucherOffered': offered, 'unit': pkg['priceUnit']};
                  }
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
          hall = halls.cast<Json?>().firstWhere((h) => (audience == null || h!.list('sections').any((s) => s['audience'] == audience)) && (guests == null || h!.obj('capacity').integer('max') >= guests), orElse: () => null) ?? halls.first;
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
        final built = buildSections(app, id, r.b.str('eventDate'), r.b.list('sections'), sessionRequired: false);
        final q = app.engine().quoteFor(venueId: id, eventDate: r.b.str('eventDate'), sections: built.quoteSections, extras: r.b.list('extras'));
        final qid = 'qt-${app.db.next('quote').toString().padLeft(5, '0')}';
        final expires = app.clock.after(const Duration(minutes: 30));
        app.db.put('Quote', {'id': qid, 'venueId': id, 'standardTotal': filsOf(q.obj('totals').obj('standardTotal')), 'voucherTotal': filsOf(q.obj('totals').obj('voucherTotal')), 'expiresAt': expires});
        return wireQuote(q, targetType: 'venue', targetId: id, quoteId: qid, expiresAt: expires);
      },
      'listNearbyVenues': (r) {
        final id = r.p('venueId');
        app.db.peek('Venue', id) ?? (throw ApiError.notFound('venue'));
        return [for (final n in app.engine().nearby(id, r.qInt('limit') ?? 6)) {'venue': venueSummary(n.obj('venue')), 'minutes': n['minutes'], 'km': n['km']}];
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
                for (final k in ['channel', 'availability', 'price', 'voucherPrice', 'savings', 'fromPerGuest', 'fromVoucherPerGuest', 'maxGuests', 'fits', 'valet', 'photography', 'rating', 'distance', 'structures', 'packages', 'best']) k: c[k],
              }
          ]
        };
      },
      'listAreas': (r) => {'governorates': app.seed.rows('Governorate'), 'areas': app.seed.rows('Area'), 'referencePoints': app.seed.rows('ReferencePoint')},
      'searchRegions': (r) {
        final published = _visibleVenues(app).map((v) => v['id']).toSet();
        return app.engine().searchRegions(r.q('q') ?? '').where((m) => m['kind'] != 'venue' || published.contains(m['id'])).toList();
      },
    };
