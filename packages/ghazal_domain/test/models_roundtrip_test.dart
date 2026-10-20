import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

/// Every sample payload (the design fixtures mapped to the wire shape and validated against the OpenAPI schemas by
/// packages/contracts/openapi/scripts/fixtures-to-wire.mjs, plus the hero-story examples of the contract) round-trips through its model:
///   1. fromJson accepts it,
///   2. toJson never invents or changes a value (every emitted key equals the input value; keys the schema does not declare are dropped),
///   3. fromJson(toJson(m)) == m (value equality and hashCode).
void main() {
  final dir = Directory('test/samples');
  final samples = <String, List<Object?>>{};
  for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
    final name = f.uri.pathSegments.last.replaceAll('.json', '');
    if (name == '_spec_examples') continue;
    samples[name] = (jsonDecode(f.readAsStringSync()) as List).cast<Object?>();
  }
  final examples = (jsonDecode(File('test/samples/_spec_examples.json').readAsStringSync()) as Map<String, Object?>);

  void check(String schema, Object? input) {
    final from = kModelFromJson[schema];
    if (from == null) fail('no model registered for $schema');
    final model = from(input! as Map<String, Object?>);
    final out = (model as dynamic).toJson() as Map<String, Object?>;
    _expectSubset(out, input, schema);
    final again = from(jsonDecode(jsonEncode(out)) as Map<String, Object?>);
    expect(again, model, reason: '$schema: fromJson(toJson(m)) != m');
    expect(again.hashCode, model.hashCode, reason: '$schema: hashCode differs after round trip');
  }

  group('fixture samples', () {
    for (final entry in samples.entries) {
      test(entry.key, () {
        if (!kModelFromJson.containsKey(entry.key)) return; // builtin or enum-only schema (Money and friends are hand-written, tested separately)
        for (final row in entry.value) {
          check(entry.key, row);
        }
      });
    }
  });

  group('contract examples', () {
    for (final entry in examples.entries) {
      test(entry.key, () => check(entry.key, entry.value));
    }
  });

  test('every model class is registered', () {
    expect(kModelFromJson.length, greaterThan(250));
  });
}

void _expectSubset(Object? out, Object? input, String path) {
  if (out is Map<String, Object?>) {
    final inMap = input as Map<String, Object?>;
    for (final e in out.entries) {
      if (e.value == null) continue;
      expect(inMap.containsKey(e.key), isTrue, reason: '$path.${e.key} emitted but absent in the input');
      _expectSubset(e.value, inMap[e.key], '$path.${e.key}');
    }
  } else if (out is List) {
    final inList = input as List;
    expect(out.length, inList.length, reason: '$path length');
    for (var i = 0; i < out.length; i++) {
      _expectSubset(out[i], inList[i], '$path[$i]');
    }
  } else if (out is String && input is String && DateTime.tryParse(out) != null && out.contains('T') && input.contains('T')) {
    expect(DateTime.parse(out).toUtc(), DateTime.parse(input).toUtc(), reason: '$path instant');
  } else if (out is num && input is num) {
    expect(out, input, reason: path);
  } else {
    expect(out, input, reason: path);
  }
}
