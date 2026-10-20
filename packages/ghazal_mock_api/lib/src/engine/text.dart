/// Search text normalisation (CA-FLT: Arabic-normalised region search). Port of engine/text.ts.
///
/// JavaScript runs NFKD first and Dart has no Unicode normaliser, so the decompositions of the ranges that matter (Latin, Arabic and its
/// presentation forms, punctuation, fullwidth forms) live in the generated `nfkd_table.g.dart`.
library;

import 'nfkd_table.g.dart';

final Map<int, String> _nfkd = () {
  final m = <int, String>{};
  for (final pair in nfkdPairs.split(',')) {
    final i = pair.indexOf(':');
    m[int.parse(pair.substring(0, i), radix: 16)] = String.fromCharCodes(pair.substring(i + 1).split('.').map((h) => int.parse(h, radix: 16)));
  }
  return m;
}();

String _decompose(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    b.write(_nfkd[r] ?? String.fromCharCode(r));
  }
  return b.toString();
}

final _diacritics = RegExp('[ؐ-ًؚ-ٟۖ-ۭـ]');

String normalizeSearch(String input) => _decompose(input)
    .replaceAll(_diacritics, '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .toLowerCase()
    .trim();
