import 'package:collection/collection.dart';

import 'instants.dart';
import 'local_date.dart';

/// Strict JSON readers used by the generated models. A wrong shape throws [FormatException]; the generated `fromJson` adds the model name.
String asString(Object? v) => v is String ? v : throw FormatException('expected string, got ${_kind(v)}');

int asInt(Object? v) {
  if (v is int) return v;
  if (v is num && v == v.truncate()) return v.toInt();
  throw FormatException('expected integer, got ${_kind(v)}');
}

double asDouble(Object? v) => v is num ? v.toDouble() : throw FormatException('expected number, got ${_kind(v)}');

bool asBool(Object? v) => v is bool ? v : throw FormatException('expected boolean, got ${_kind(v)}');

/// An instant with an explicit offset (normally +03:00), kept as a UTC [DateTime]; `instantToJson` writes it back as Kuwait time.
DateTime asInstant(Object? v) => parseInstant(asString(v));

LocalDate asLocalDate(Object? v) => LocalDate.parse(asString(v));

LocalTime asLocalTime(Object? v) => LocalTime.parse(asString(v));

Map<String, Object?> asMap(Object? v) {
  if (v is Map<String, Object?>) return v;
  if (v is Map) return v.map((k, value) => MapEntry(k.toString(), value));
  throw FormatException('expected object, got ${_kind(v)}');
}

List<T> asList<T>(Object? v, T Function(Object? v) parse) {
  if (v is! List) throw FormatException('expected array, got ${_kind(v)}');
  return List<T>.unmodifiable(v.map(parse));
}

Map<String, T> asStringMap<T>(Object? v, T Function(Object? v) parse) =>
    Map<String, T>.unmodifiable(asMap(v).map((k, value) => MapEntry(k, parse(value))));

/// `null` stays `null`; anything else goes through [parse].
T? nullable<T>(Object? v, T Function(Object? v) parse) => v == null ? null : parse(v);

/// Passes a free-form value (`additionalProperties: true`) through unchanged.
Object? asAny(Object? v) => v;

String _kind(Object? v) => v == null ? 'null' : v.runtimeType.toString();

const DeepCollectionEquality _deep = DeepCollectionEquality();

/// Value equality for lists and maps held by generated models.
bool deepEquals(Object? a, Object? b) => _deep.equals(a, b);

/// Hash that agrees with [deepEquals].
int deepHash(Object? v) => _deep.hash(v);

/// Marker for `copyWith`: "argument not passed", so a nullable field can be set to `null` explicitly.
final class Unset {
  const Unset();
}

const Object unsetValue = Unset();

/// Reads a required, non-null field; the error names the key (`sections: BookingSection: hallId: expected string, got null`).
T reqField<T>(Map<String, Object?> json, String key, T Function(Object? v) parse) {
  final v = json[key];
  if (v == null) throw FormatException('$key: missing or null');
  try {
    return parse(v);
  } on FormatException catch (e) {
    throw FormatException('$key: ${e.message}');
  }
}

/// Reads an optional or nullable field: absent and `null` both give `null`.
T? optField<T>(Map<String, Object?> json, String key, T Function(Object? v) parse) {
  final v = json[key];
  if (v == null) return null;
  try {
    return parse(v);
  } on FormatException catch (e) {
    throw FormatException('$key: ${e.message}');
  }
}
