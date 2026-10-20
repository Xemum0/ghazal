/// A small JSON-schema validator over the slim request schemas of `assets/spec/routes.json` (type, required, properties, enum, items, oneOf,
/// pattern, bounds, formats). Request bodies and query parameters are validated with it: a bad body is a 422 VALIDATION_FAILED with one
/// `{path, code}` per problem, like the real backend's DTO validation.
library;

import '../engine/json.dart';

class SchemaValidator {
  SchemaValidator(this.schemas);

  /// `components.schemas`, slimmed.
  final Json schemas;

  /// Validates [value] against [schema] (an inline schema or `{$ref}`), returning the list of `{path, code}` problems (empty when valid).
  List<Json> validate(Object? value, Object? schema, [String path = '']) {
    final errs = <Json>[];
    _check(value, schema, path, errs);
    return errs;
  }

  Object? _resolve(Object? schema) {
    var s = schema;
    var guard = 0;
    while (s is Map && s[r'$ref'] != null && guard++ < 20) {
      s = schemas[(s[r'$ref'] as String).split('/').last];
    }
    return s;
  }

  static const _dateRe = r'^\d{4}-\d{2}-\d{2}$';

  void _check(Object? v, Object? schemaIn, String path, List<Json> errs) {
    final schema = _resolve(schemaIn);
    if (schema is! Map) return;
    void bad(String code) => errs.add({'path': path.isEmpty ? '/' : path, 'code': code});

    final oneOf = schema['oneOf'] ?? schema['anyOf'];
    if (oneOf is List) {
      for (final alt in oneOf) {
        final sub = <Json>[];
        _check(v, alt, path, sub);
        if (sub.isEmpty) return;
      }
      bad('no_variant_matches');
      return;
    }
    final allOf = schema['allOf'];
    if (allOf is List) {
      for (final part in allOf) {
        _check(v, part, path, errs);
      }
    }
    final type = schema['type'];
    final types = type is List ? type.cast<String>() : (type is String ? [type] : const <String>[]);
    if (v == null) {
      if (types.isNotEmpty && !types.contains('null')) bad('required');
      return;
    }
    if (types.isNotEmpty && !types.any((t) => _isType(v, t))) {
      bad('invalid_type');
      return;
    }
    final en = schema['enum'];
    if (en is List && !en.any((e) => e == v)) {
      bad('invalid_enum');
      return;
    }
    if (schema.containsKey('const') && schema['const'] != v) bad('invalid_value');
    if (v is String) {
      final min = schema['minLength'];
      final max = schema['maxLength'];
      if (min is num && v.length < min) bad('too_short');
      if (max is num && v.length > max) bad('too_long');
      final pat = schema['pattern'];
      if (pat is String && !RegExp(pat).hasMatch(v)) bad('invalid_format');
      final fmt = schema['format'];
      if (fmt == 'date' && !RegExp(_dateRe).hasMatch(v)) bad('invalid_date');
      if (fmt == 'date-time' && DateTime.tryParse(v) == null) bad('invalid_date_time');
      if (fmt == 'email' && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) bad('invalid_email');
      if (fmt == 'local-time' && !RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) bad('invalid_time');
    } else if (v is num) {
      final min = schema['minimum'];
      final max = schema['maximum'];
      if (min is num && v < min) bad('too_small');
      if (max is num && v > max) bad('too_large');
    } else if (v is List) {
      final min = schema['minItems'];
      final max = schema['maxItems'];
      if (min is num && v.length < min) bad('too_few');
      if (max is num && v.length > max) bad('too_many');
      final items = schema['items'];
      if (items != null) {
        for (var i = 0; i < v.length; i++) {
          _check(v[i], items, '$path/$i', errs);
        }
      }
    } else if (v is Map) {
      final required = schema['required'];
      if (required is List) {
        for (final k in required) {
          if (!v.containsKey(k)) errs.add({'path': '$path/$k', 'code': 'required'});
        }
      }
      final props = schema['properties'];
      if (props is Map) {
        for (final e in props.entries) {
          if (v.containsKey(e.key)) _check(v[e.key], e.value, '$path/${e.key}', errs);
        }
      }
    }
  }

  static bool _isType(Object v, String t) {
    switch (t) {
      case 'string':
        return v is String;
      case 'integer':
        return v is int || (v is double && v == v.truncateToDouble());
      case 'number':
        return v is num;
      case 'boolean':
        return v is bool;
      case 'array':
        return v is List;
      case 'object':
        return v is Map;
      case 'null':
        return false;
    }
    return true;
  }

  /// Coerces a query-string value to the parameter's JSON type (`"12"` to 12, `"true"` to true); lists are handled by the caller.
  static Object? coerce(String raw, Object? schema) {
    final type = schema is Map ? schema['type'] : null;
    final t = type is List ? type.firstWhere((x) => x != 'null', orElse: () => 'string') : type;
    switch (t) {
      case 'integer':
        return int.tryParse(raw) ?? raw;
      case 'number':
        return num.tryParse(raw) ?? raw;
      case 'boolean':
        return raw == 'true' ? true : (raw == 'false' ? false : raw);
    }
    return raw;
  }
}
