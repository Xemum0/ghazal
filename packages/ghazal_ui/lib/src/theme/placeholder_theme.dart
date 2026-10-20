import 'package:material_ui/material_ui.dart';

import '../tokens/placeholder_tokens.dart';
import 'gz_fonts.dart';

/// PLACEHOLDER theme (phase F0): already applies the right font per locale so Arabic renders correctly.
/// The real token-driven theme (`buildGhazalTheme`) arrives in phase F1a and replaces this file.
ThemeData buildPlaceholderTheme(Locale locale) {
  final ui = GzFonts.uiFor(locale);
  final fallback = GzFonts.fallbackFor(locale);
  TextStyle style(double size, FontWeight weight, {String? family, Color? color}) => TextStyle(
        fontFamily: family ?? ui,
        fontFamilyFallback: fallback,
        package: GzFonts.package,
        fontSize: size,
        fontWeight: weight,
        height: 1.4,
        letterSpacing: 0,
        color: color ?? GzPlaceholderColors.ink900,
        leadingDistribution: TextLeadingDistribution.even,
      );
  final text = TextTheme(
    displayLarge: style(32, FontWeight.w600, family: GzFonts.display),
    headlineMedium: style(24, FontWeight.w600, family: GzFonts.display),
    titleLarge: style(20, FontWeight.w600, family: GzFonts.display),
    titleMedium: style(16, FontWeight.w600),
    bodyLarge: style(16, FontWeight.w400),
    bodyMedium: style(14, FontWeight.w400, color: GzPlaceholderColors.ink700),
    labelLarge: style(14, FontWeight.w600),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: GzPlaceholderColors.ink900,
      onPrimary: GzPlaceholderColors.onDark,
      secondary: GzPlaceholderColors.gold500,
      surface: GzPlaceholderColors.paper,
      onSurface: GzPlaceholderColors.ink900,
    ),
    scaffoldBackgroundColor: GzPlaceholderColors.canvas,
    canvasColor: GzPlaceholderColors.canvas,
    textTheme: text,
    splashFactory: NoSplash.splashFactory,
    highlightColor: GzPlaceholderColors.transparent,
  );
}
