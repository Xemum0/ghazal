/// Where the seeds come from. The mock never touches the file system itself: a [SeedSource] reads one text asset by its path inside the package
/// (`seed/Venue.json`, `spec/routes.json`, `images/<id>_480.jpg`). Flutter apps pass `SeedSource.fromLoader(rootBundle.loadString ...)`; the Dart
/// VM (tests, standalone server) uses `SeedSource.fromDirectory` of `seed_source_io.dart`.
library;

abstract interface class SeedSource {
  /// The text of a package asset, e.g. `seed/Venue.json`.
  Future<String> read(String path);

  /// A source over any async loader (`(path) => rootBundle.loadString('packages/ghazal_mock_api/assets/$path')`).
  factory SeedSource.fromLoader(Future<String> Function(String path) load) = _LoaderSource;
}

final class _LoaderSource implements SeedSource {
  _LoaderSource(this._load);
  final Future<String> Function(String path) _load;

  @override
  Future<String> read(String path) => _load(path);
}

/// A source over an in-memory map (tests that edit a seed).
final class MapSeedSource implements SeedSource {
  MapSeedSource(this.files);
  final Map<String, String> files;

  @override
  Future<String> read(String path) async => files[path] ?? (throw StateError('seed asset not found: $path'));
}
