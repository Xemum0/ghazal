/// Authored text in both languages. A missing language is `null`; the reader falls back to the other one (NF-LOC-06), so switching
/// language needs no refetch. User-typed text (names, notes) is shown as typed and never translated.
final class LocalizedText {
  const LocalizedText({this.en, this.ar});

  factory LocalizedText.fromJson(Map<String, Object?> json) {
    final en = json['en'], ar = json['ar'];
    if ((en != null && en is! String) || (ar != null && ar is! String)) throw const FormatException('localized text values must be strings or null');
    return LocalizedText(en: en as String?, ar: ar as String?);
  }

  /// The same text in both languages (names typed by the user).
  const LocalizedText.same(String text)
      : en = text,
        ar = text;

  final String? en;
  final String? ar;

  /// The text for a language code (`'ar'` or `'en'`; anything else reads as English), falling back to the other language, then to `''`.
  ///
  /// Takes the language code so this package stays free of Flutter: `text.of(Localizations.localeOf(context).languageCode)`.
  String of(String languageCode) => (languageCode == 'ar' ? (ar ?? en) : (en ?? ar)) ?? '';

  /// True when the requested language is missing and [of] fell back to the other one (the quiet language chip, NF-LOC-06).
  bool isFallback(String languageCode) => (languageCode == 'ar' ? ar : en) == null && (en != null || ar != null);

  bool get isEmpty => (en ?? '').isEmpty && (ar ?? '').isEmpty;

  Map<String, Object?> toJson() => {'en': en, 'ar': ar};

  @override
  bool operator ==(Object other) => other is LocalizedText && other.en == en && other.ar == ar;

  @override
  int get hashCode => Object.hash(en, ar);

  @override
  String toString() => 'LocalizedText(en: $en, ar: $ar)';
}
