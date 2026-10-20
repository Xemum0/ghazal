/// The in-memory database of the mock: named collections of JSON documents (the wire shape), copy-on-read, with id generation and
/// referential helpers. Documents may carry internal fields prefixed `_` (for example `_userId`); [wire] strips them before anything leaves the server.
library;

import 'dart:collection';

import '../engine/json.dart';

class MockDb {
  final Map<String, LinkedHashMap<String, Json>> _c = {};
  final Map<String, int> _seq = {};
  final Map<String, int> versions = {};

  /// Collection names that exist.
  Iterable<String> get collections => _c.keys;

  LinkedHashMap<String, Json> _col(String c) => _c.putIfAbsent(c, () => LinkedHashMap());

  int count(String c) => _c[c]?.length ?? 0;

  bool has(String c, String id) => _c[c]?.containsKey(id) ?? false;

  /// Read-only live view of the stored documents: NEVER mutate the maps it yields (the engine reads through this for speed).
  List<Json> raw(String c) => _c[c]?.values.toList(growable: false) ?? const [];

  /// Copies of all documents of a collection, in insertion order.
  List<Json> all(String c) => [for (final d in _c[c]?.values ?? const <Json>[]) deepCopy(d)];

  /// A copy of the document, or null.
  Json? get(String c, String id) {
    final d = _c[c]?[id];
    return d == null ? null : deepCopy(d);
  }

  /// A copy of the document, or throws a 404-mapped [StateError] the caller turns into NOT_FOUND.
  Json require(String c, String id) => get(c, id) ?? (throw NotInDb(c, id));

  /// The stored document itself (not a copy) for in-place engine reads; do not mutate.
  Json? peek(String c, String id) => _c[c]?[id];

  /// Stores a copy under [id] (default: the document's `id`).
  void put(String c, Json doc, {String? id}) {
    _col(c)[id ?? doc.str('id')] = deepCopy(doc);
  }

  void putAll(String c, Iterable<Json> docs, {String Function(Json)? key}) {
    for (final d in docs) {
      put(c, d, id: key?.call(d));
    }
  }

  Json? remove(String c, String id) => _c[c]?.remove(id);

  /// Documents matching [test] (copies).
  List<Json> where(String c, bool Function(Json d) test) => [for (final d in _c[c]?.values ?? const <Json>[]) if (test(d)) deepCopy(d)];

  /// First document matching [test] (copy) or null.
  Json? firstWhere(String c, bool Function(Json d) test) {
    for (final d in _c[c]?.values ?? const <Json>[]) {
      if (test(d)) return deepCopy(d);
    }
    return null;
  }

  void clear() {
    _c.clear();
    _seq.clear();
    versions.clear();
  }

  /// Monotonic counter by [name] (ids, receipt numbers).
  int next(String name, [int start = 1]) => _seq[name] = (_seq[name] ?? (start - 1)) + 1;

  /// Version of a settings document (ETag `"vN"`); starts at 1.
  int versionOf(String key) => versions[key] ?? 1;

  int bumpVersion(String key) => versions[key] = versionOf(key) + 1;
}

class NotInDb implements Exception {
  NotInDb(this.collection, this.id);
  final String collection;
  final String id;
  @override
  String toString() => 'NotInDb($collection/$id)';
}

/// A copy of [v] without internal `_` fields at any depth.
T wire<T>(T v) {
  if (v is Map) {
    return {for (final e in v.entries) if (!(e.key as String).startsWith('_')) e.key as String: wire(e.value)} as T;
  }
  if (v is List) return v.map(wire).toList() as T;
  return v;
}
