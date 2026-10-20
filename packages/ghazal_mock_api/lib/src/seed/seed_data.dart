/// The parsed seeds: one list of wire objects per collection (exactly the output of `fixtures-to-wire.mjs`), the `extra.json` with the
/// raw non-schema fixtures (config, personas, billing, hotel settings), and the slim route table of the contract.
library;

import 'dart:convert';

import '../engine/catalog.dart';
import '../engine/json.dart';
import 'seed_source.dart';

class SeedData {
  SeedData({required this.collections, required this.extra, required this.manifest, required this.routes});

  /// Collection name (the schema name, e.g. `Venue`) to its rows.
  final Map<String, List<Json>> collections;
  final Json extra;
  final Json manifest;

  /// `assets/spec/routes.json`: operations, error codes and the request schemas.
  final Json routes;

  List<Json> rows(String name) => collections[name] ?? const [];

  Json get config => extra.obj('meta').obj('config');
  String get now => extra.obj('clock').str('now');

  static Future<SeedData> load(SeedSource source) async {
    final manifest = (jsonDecode(await source.read('seed/manifest.json')) as Map).cast<String, dynamic>();
    final collections = <String, List<Json>>{};
    Json extra = {};
    for (final f in (manifest['files'] as List).cast<String>()) {
      final value = jsonDecode(await source.read('seed/$f'));
      if (f == 'extra.json') {
        extra = (value as Map).cast<String, dynamic>();
      } else {
        collections[f.replaceAll('.seed.json', '')] = (value as List).map((e) => (e as Map).cast<String, dynamic>()).toList();
      }
    }
    final routes = (jsonDecode(await source.read('spec/routes.json')) as Map).cast<String, dynamic>();
    return SeedData(collections: collections, extra: extra, manifest: manifest, routes: routes);
  }

  /// A read-only engine view over the seeds (tests and the equality proof; the running mock builds its own from the live database).
  EngineData engineData({String? now}) => EngineData(
        venues: rows('Venue'),
        packages: rows('Package'),
        priceRules: rows('PriceRule'),
        extras: rows('Extra'),
        windows: rows('VoucherWindow'),
        claims: rows('CalendarClaim'),
        overrides: extra.list('dayOverrides'),
        areas: rows('Area'),
        governorates: rows('Governorate'),
        visits: rows('VisitAppointment'),
        providers: rows('ServiceProvider'),
        config: config,
        now: now ?? this.now,
      );
}
