/// Cursor pagination helpers: `{items, nextCursor}` with an opaque base64url cursor over the position in the sorted list. The sort is done by
/// the caller and must be stable and unique, like the real backend's keyset.
library;

import 'dart:convert';

import '../engine/json.dart';
import 'problem.dart';
import 'request.dart';

String encodeCursor(int offset) => base64Url.encode(utf8.encode('o:$offset')).replaceAll('=', '');

int decodeCursor(String? cursor) {
  if (cursor == null || cursor.isEmpty) return 0;
  try {
    final s = utf8.decode(base64Url.decode(base64Url.normalize(cursor)));
    if (s.startsWith('o:')) return int.parse(s.substring(2));
  } catch (_) {}
  throw ApiError.validation('/cursor', 'invalid_cursor');
}

/// One page of [items] (already filtered and sorted): `{items, nextCursor}`.
Json pageOf(Req r, List<Object?> items) {
  final start = decodeCursor(r.q('cursor'));
  final end = start + r.limit;
  final slice = items.skip(start).take(r.limit).toList();
  return {'items': slice, 'nextCursor': end < items.length ? encodeCursor(end) : null};
}

/// A page whose rows are built lazily from [rows] (only the visible slice is mapped).
Json pageMap<T>(Req r, List<T> rows, Object? Function(T) build) {
  final start = decodeCursor(r.q('cursor'));
  final end = start + r.limit;
  return {'items': rows.skip(start).take(r.limit).map(build).toList(), 'nextCursor': end < rows.length ? encodeCursor(end) : null};
}
