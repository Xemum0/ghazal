import 'package:flutter/widgets.dart' show Locale;

/// Bundled font families (static TTFs in `assets/fonts`, declared in this package's pubspec).
/// Family names differ from the web only in spaces: web "El Messiri" is `ElMessiri`; "Manrope" and "Almarai" are identical.
abstract final class GzFonts {
  static const String package = 'ghazal_ui';

  /// Display voice (headings, wordmark), both languages.
  static const String display = 'ElMessiri';

  /// English UI voice.
  static const String uiLatin = 'Manrope';

  /// Arabic UI voice (also the Arabic fallback of every Latin family).
  static const String uiArabic = 'Almarai';

  /// UI family for a locale: Almarai for Arabic, Manrope for English.
  static String uiFor(Locale locale) => locale.languageCode == 'ar' ? uiArabic : uiLatin;

  /// Fallback chain: the other UI family covers the glyphs the first one lacks (Manrope has no Arabic).
  static List<String> fallbackFor(Locale locale) =>
      locale.languageCode == 'ar' ? const [uiLatin, display] : const [uiArabic, display];
}
