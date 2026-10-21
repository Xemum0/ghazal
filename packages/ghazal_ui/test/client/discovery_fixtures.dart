import 'dart:convert';
import 'dart:io';

import 'package:ghazal_domain/ghazal_domain.dart';

/// Real seeded venue summaries (the file the mock serves) for the discovery card tests. Real file IO: call from `setUpAll`.
class DiscoveryFixtures {
  DiscoveryFixtures._(this.venues, this.areas, this.windows);

  final Map<String, VenueSummary> venues;
  final Map<String, LocalizedText> areas;
  final Map<String, VoucherWindow> windows;

  static DiscoveryFixtures? _cached;

  static Future<DiscoveryFixtures> load() async {
    if (_cached != null) return _cached!;
    const seed = '../ghazal_mock_api/assets/seed';
    final rows = jsonDecode(await File('$seed/VenueSummary.seed.json').readAsString()) as List<dynamic>;
    final areas = jsonDecode(await File('$seed/Area.seed.json').readAsString()) as List<dynamic>;
    final wins = jsonDecode(await File('$seed/VoucherWindow.seed.json').readAsString()) as List<dynamic>;
    return _cached = DiscoveryFixtures._(
      {for (final r in rows) (r as Map)['id'] as String: VenueSummary.fromJson(r.cast<String, Object?>())},
      {for (final a in areas) (a as Map)['id'] as String: LocalizedText.fromJson((a['name'] as Map).cast<String, Object?>())},
      {for (final w in wins) (w as Map)['id'] as String: VoucherWindow.fromJson(w.cast<String, Object?>())},
    );
  }

  VenueSummary venue(String id) => venues[id]!;
  LocalizedText areaOf(String id) => areas[venues[id]!.areaId]!;
}
