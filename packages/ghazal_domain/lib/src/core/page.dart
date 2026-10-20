/// One cursor page: `{ items, nextCursor }` with `nextCursor` null on the last page (api-conventions section 6).
///
/// Also exported as `CursorPage<T>`: `package:flutter/widgets.dart` has its own `Page<T>` (navigator pages), so feature code that imports
/// both uses the alias.
final class Page<T> {
  const Page({required this.items, this.nextCursor});

  factory Page.fromJson(Map<String, Object?> json, T Function(Object? item) parseItem) {
    final raw = json['items'];
    if (raw is! List) throw const FormatException('page.items must be an array');
    final cursor = json['nextCursor'];
    return Page(items: List<T>.unmodifiable(raw.map(parseItem)), nextCursor: cursor as String?);
  }

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  Page<R> map<R>(R Function(T item) f) => Page<R>(items: List<R>.unmodifiable(items.map(f)), nextCursor: nextCursor);

  @override
  String toString() => 'Page(${items.length} items, next: $nextCursor)';
}

typedef CursorPage<T> = Page<T>;
