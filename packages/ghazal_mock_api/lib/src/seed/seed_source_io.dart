/// dart:io implementations of [SeedSource] for the Dart VM (tests, the standalone server). Not imported by the in-process adapter.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'seed_source.dart';

/// Reads assets from a directory (the package's `assets` folder).
final class DirectorySeedSource implements SeedSource {
  DirectorySeedSource(this.directory);
  final String directory;

  @override
  Future<String> read(String path) => File(p.join(directory, path)).readAsString();

  /// The folder holding `seed/`, `spec/` and `images/`.
  String get assetsDir => directory;
}

/// The `assets` folder of this package, found through the package config (works inside the workspace and from `dart run`).
Future<DirectorySeedSource> packageSeedSource() async => DirectorySeedSource(await packageAssetsDirectory());

Future<String> packageAssetsDirectory() async {
  try {
    final uri = await Isolate.resolvePackageUri(Uri.parse('package:ghazal_mock_api/ghazal_mock_api.dart'));
    if (uri != null) return p.join(p.dirname(p.dirname(uri.toFilePath())), 'assets');
  } on UnsupportedError {
    // `flutter test` cannot resolve package URIs: look for the folder from the working directory instead
  }
  var dir = Directory.current.absolute;
  for (var i = 0; i < 8; i++) {
    for (final candidate in [p.join(dir.path, 'assets'), p.join(dir.path, 'packages/ghazal_mock_api/assets')]) {
      if (File(p.join(candidate, 'seed/manifest.json')).existsSync()) return candidate;
    }
    dir = dir.parent;
  }
  throw StateError('package:ghazal_mock_api is not resolvable and no assets folder was found from ${Directory.current.path}');
}

/// Optional override through the `GZ_MOCK_ASSETS` environment variable.
Future<DirectorySeedSource> defaultSeedSource() async {
  final env = Platform.environment['GZ_MOCK_ASSETS'];
  return env != null && env.isNotEmpty ? DirectorySeedSource(env) : packageSeedSource();
}
