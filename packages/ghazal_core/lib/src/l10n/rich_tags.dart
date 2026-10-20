/// One piece of a rich-text message: plain text, or the text inside `<tag>...</tag>`.
class RichPart {
  const RichPart(this.text, [this.tag]);

  final String text;

  /// The tag name (`f`, `n`, `terms`, `privacy`), or null for plain text.
  final String? tag;

  bool get isPlain => tag == null;

  @override
  bool operator ==(Object other) => other is RichPart && other.text == text && other.tag == tag;

  @override
  int get hashCode => Object.hash(text, tag);

  @override
  String toString() => tag == null ? 'RichPart($text)' : 'RichPart(<$tag>$text)';
}

final RegExp _tag = RegExp(r'<([A-Za-z][A-Za-z0-9]*)>([\s\S]*?)</\1>');

/// Splits an ARB string that keeps literal tags (`Holds <f>Sun 15 Nov</f> for <n>Sara</n>`) into parts for `GzRich`.
/// Tags do not nest; an unmatched `<` stays plain text. Empty plain parts are dropped.
List<RichPart> parseRichTags(String message) {
  final parts = <RichPart>[];
  var cursor = 0;
  for (final m in _tag.allMatches(message)) {
    if (m.start > cursor) parts.add(RichPart(message.substring(cursor, m.start)));
    parts.add(RichPart(m.group(2)!, m.group(1)));
    cursor = m.end;
  }
  if (cursor < message.length) parts.add(RichPart(message.substring(cursor)));
  return parts;
}
