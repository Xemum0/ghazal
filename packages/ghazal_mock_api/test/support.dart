import 'dart:convert';
import 'dart:io';

import 'package:ghazal_mock_api/ghazal_mock_api.dart';
import 'package:ghazal_mock_api/src/seed/seed_source_io.dart';
import 'package:path/path.dart' as p;

/// The repository root (the folder holding `packages/contracts`), found from the working directory.
String repoRoot() {
  var dir = Directory.current.absolute;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'packages/contracts/fixtures/engine-cases.json')).existsSync()) return dir.path;
    dir = dir.parent;
  }
  throw StateError('repository root not found from ${Directory.current.path}');
}

Json readJson(String relative) => (jsonDecode(File(p.join(repoRoot(), relative)).readAsStringSync()) as Map).cast<String, dynamic>();

SeedData? _seed;
Future<SeedData> loadSeed() async => _seed ??= await SeedData.load(DirectorySeedSource(p.join(repoRoot(), 'packages/ghazal_mock_api/assets')));
