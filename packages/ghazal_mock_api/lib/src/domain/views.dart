/// Builders for the composite shapes of the contract (target summaries, request rows, wallet items, venue results): small pure functions over
/// documents, shared by the handlers of both apps.
library;

import '../core/app.dart';
import '../db/mock_db.dart';
import '../engine/engine.dart';

export '../db/mock_db.dart' show wire;

const venueSummaryKeys = [
  'id', 'slug', 'name', 'type', 'style', 'tier', 'stars', 'channel', 'status', 'governorateId', 'areaId', 'address', 'geo', 'tagline', 'cover', 'hasVideo', 'rating', 'voucherEnabled', 'flags',
];

Json venueSummary(Json v) => {for (final k in venueSummaryKeys) k: v[k]};

String _monogram(Json name) {
  final ar = name.strOrNull('ar') ?? name.strOrNull('en') ?? '?';
  return ar.isEmpty ? '?' : String.fromCharCode(ar.runes.first);
}

/// `TargetSummary` of a venue or provider.
Json targetSummary(MockApp app, {String? venueId, String? providerId}) {
  if (venueId != null) {
    final v = app.db.peek('Venue', venueId);
    if (v == null) throw NotInDb('Venue', venueId);
    return {'kind': 'venue', 'id': venueId, 'name': v['name'], 'monogram': _monogram(v.obj('name')), 'areaId': v['areaId'], 'cover': v['cover'], 'phone': v['phone'], 'channel': v['channel']};
  }
  final p = app.db.peek('ServiceProvider', providerId ?? '');
  if (p == null) throw NotInDb('ServiceProvider', providerId ?? '');
  final portfolio = p.list('portfolio');
  return {'kind': 'provider', 'id': providerId, 'name': p['name'], 'monogram': p['monogram'], 'areaId': p['areaId'], 'cover': portfolio.isEmpty ? null : portfolio.first, 'phone': p['phone'], 'channel': 'ghazal_voucher'};
}

/// `NamedRef[]` of the halls a request uses.
List<Json> hallRefs(MockApp app, Json booking) {
  final venueId = booking.strOrNull('venueId');
  if (venueId == null) return [];
  final venue = app.db.peek('Venue', venueId);
  if (venue == null) return [];
  final ids = booking.list('sections').map((s) => s['hallId']).toSet();
  return [for (final h in venue.list('halls')) if (ids.contains(h['id'])) {'id': h['id'], 'name': h['name']}];
}

/// A `VenueResult` from an engine row (the venue becomes its summary).
Json venueResult(Json row) => {
      'venue': venueSummary(row.obj('venue')),
      'price': row['price'],
      'availability': row['availability'],
      'availabilityHallId': row['availabilityHallId'],
      'badge': row['badge'],
      'windowId': row['windowId'],
      'guestRange': row['guestRange'],
      'structures': row['structures'],
      'tags': row['tags'],
      'distance': row['distance'],
      'sponsored': row['sponsored'],
    };

/// Wire form of a quote of the engine (adds the target, the snapshot id and the offer flag).
Json wireQuote(Json q, {required String targetType, required String targetId, String? quoteId, String? expiresAt}) => {
      'quoteId': quoteId,
      'expiresAt': expiresAt,
      'targetType': targetType,
      'targetId': targetId,
      'eventDate': q['eventDate'],
      'lines': q['lines'],
      'totals': q['totals'],
      'voucherOffered': q['voucherEligible'],
    };

/// `Money` of an integer.
Json money(int f) => fils(f);

/// Largest number among two ints (readability).
int maxInt(int a, int b) => a > b ? a : b;
