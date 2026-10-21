import 'package:ghazal_core/ghazal_core.dart' show normalizeDigits;

/// Search-only normalisation (ADR 0012 D8): strip tashkeel and tatweel, unify alef forms and ya, ta marbuta to ha, Eastern digits
/// to Western, Latin case-fold, and drop the definite article ال at the start of a word so `السالمية` finds `سالمية`. The
/// displayed text is never changed; only the comparison key is.
String gzSearchKey(String input) {
  final s = normalizeDigits(input)
      .replaceAll(RegExp('[ً-ٰٟـ]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .toLowerCase();
  return s.split(RegExp(r'\s+')).map((word) => word.length > 3 && word.startsWith('ال') ? word.substring(2) : word).join(' ').trim();
}

/// Every query word must appear in the label (or any extra search alias).
bool gzMatchesSearch(String query, [String? a, String? b, String? c]) {
  final q = gzSearchKey(query);
  if (q.isEmpty) return true;
  final hay = gzSearchKey([a, b, c].whereType<String>().where((s) => s.isNotEmpty).join(' '));
  return q.split(' ').every(hay.contains);
}
