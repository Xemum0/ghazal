/// JSON helpers shared by the engine and the handlers: the mock works on the wire shape (maps and lists), exactly what the contract carries.
library;

typedef Json = Map<String, dynamic>;

extension JsonRead on Map<String, dynamic> {
  String str(String k) => this[k] as String;
  String? strOrNull(String k) => this[k] as String?;
  int integer(String k) => (this[k] as num).toInt();
  int? intOrNull(String k) => (this[k] as num?)?.toInt();
  bool flag(String k) => this[k] == true;
  Json obj(String k) => (this[k] as Map).cast<String, dynamic>();
  Json? objOrNull(String k) => (this[k] as Map?)?.cast<String, dynamic>();
  List<Json> list(String k) => ((this[k] as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  List<String> strings(String k) => ((this[k] as List?) ?? const []).map((e) => e as String).toList();
  List<int> ints(String k) => ((this[k] as List?) ?? const []).map((e) => (e as num).toInt()).toList();
}

/// Deep copy of a JSON value (the database hands out copies, never references).
T deepCopy<T>(T v) {
  if (v is Map) return v.map((k, x) => MapEntry(k as String, deepCopy(x))) as T;
  if (v is List) return v.map(deepCopy).toList() as T;
  return v;
}

/// JavaScript `Math.round`: halves go up (towards +infinity), unlike Dart's `round()` (away from zero).
int jsRound(num x) => (x + 0.5).floor();

/// Integer floor division (Dart's `~/` truncates towards zero).
int floorDiv(int a, int b) {
  final q = a ~/ b;
  return (a % b != 0 && ((a < 0) != (b < 0))) ? q - 1 : q;
}

/// Deep structural equality of two JSON values (numbers compare by value, so `1` equals `1.0`; key order does not matter).
bool jsonEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !jsonEquals(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!jsonEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is num && b is num) return a == b;
  return a == b;
}

/// The first difference between two JSON values as a path, or null when equal (for readable test failures).
String? jsonDiff(Object? a, Object? b, [String path = r'$']) {
  if (a is Map && b is Map) {
    for (final k in {...a.keys, ...b.keys}) {
      if (!a.containsKey(k)) return '$path.$k only in expected: ${b[k]}';
      if (!b.containsKey(k)) return '$path.$k only in actual: ${a[k]}';
      final d = jsonDiff(a[k], b[k], '$path.$k');
      if (d != null) return d;
    }
    return null;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return '$path length ${a.length} != ${b.length}';
    for (var i = 0; i < a.length; i++) {
      final d = jsonDiff(a[i], b[i], '$path[$i]');
      if (d != null) return d;
    }
    return null;
  }
  return jsonEquals(a, b) ? null : '$path: $a != $b';
}
