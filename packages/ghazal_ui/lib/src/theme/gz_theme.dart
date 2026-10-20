import 'package:material_ui/material_ui.dart';

import '../tokens/generated/gz_colors.g.dart';
import '../tokens/generated/gz_type.g.dart';

/// Everything a Gz component reads from the theme: colours, text roles, locale and direction.
/// Constants that never change per theme are static token classes: GzSpace, GzSize, GzRadius, GzStroke, GzElevation,
/// GzGradient, GzMotion (see the generated token files).
@immutable
class GzThemeData {
  const GzThemeData({required this.colors, required this.locale});

  final GzColors colors;
  final Locale locale;

  /// True for Arabic.
  bool get isAr => locale.languageCode == 'ar';

  /// True when the UI reads right to left (Arabic).
  bool get isRtl => isAr;

  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Text style of a role in the current script (no colour).
  TextStyle text(GzTextRole role) => GzType.style(locale, role);

  /// The role set of the current script.
  GzTypeSet get types => GzType.forLocale(locale);

  @override
  bool operator ==(Object other) => other is GzThemeData && other.colors == colors && other.locale == locale;

  @override
  int get hashCode => Object.hash(colors, locale);
}

/// Inherited Gz theme. [GzApp] installs it; tests can wrap a widget in `GzTheme(locale: ..., child: ...)`.
/// Without one, `context.gz` falls back to the light colours and the ambient locale (Arabic when there is none).
class GzTheme extends InheritedWidget {
  const GzTheme({required this.locale, required super.child, this.colors = GzColors.light, super.key});

  final Locale locale;
  final GzColors colors;

  @override
  bool updateShouldNotify(GzTheme oldWidget) => oldWidget.locale != locale || oldWidget.colors != colors;

  /// The theme data in scope.
  static GzThemeData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GzTheme>();
    if (scope != null) return GzThemeData(colors: scope.colors, locale: scope.locale);
    return GzThemeData(colors: GzColors.light, locale: Localizations.maybeLocaleOf(context) ?? const Locale('ar'));
  }
}

/// `context.gz.colors.textPrimary`, `context.gz.text(GzTextRole.body)`, `context.gz.isRtl`.
extension GzContext on BuildContext {
  GzThemeData get gz => GzTheme.of(this);
}

/// The Material theme of both apps, built only from tokens (never `ColorScheme.fromSeed`). Components do not read it; it
/// exists so framework widgets (text selection, dialogs, scroll bars) agree with the product.
ThemeData buildGhazalTheme(Locale locale) {
  const c = GzColors.light;
  final types = GzType.forLocale(locale);
  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: c.actionPrimaryBg,
    onPrimary: c.actionPrimaryLabel,
    primaryContainer: c.surfaceTint,
    onPrimaryContainer: c.textStrong,
    secondary: c.actionSelectedBg,
    onSecondary: c.actionSelectedLabel,
    secondaryContainer: c.surfaceQuiet,
    onSecondaryContainer: c.textStrong,
    tertiary: c.markDecor,
    onTertiary: c.textOnGold,
    error: c.textDanger,
    onError: c.textOnDark,
    errorContainer: c.statusDangerBg,
    onErrorContainer: c.statusDangerText,
    surface: c.surfaceCanvas,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerLowest: c.surfaceRaised,
    surfaceContainerLow: c.surfaceRaised,
    surfaceContainer: c.surfaceQuiet,
    surfaceContainerHigh: c.surfaceQuiet,
    surfaceContainerHighest: c.surfacePlaceholder,
    outline: c.borderControl,
    outlineVariant: c.borderHairline,
    shadow: c.shadowLift,
    scrim: c.scrimModal,
    inverseSurface: c.surfaceDark,
    onInverseSurface: c.textOnDark,
    inversePrimary: c.textOnDarkGold,
  );
  final text = TextTheme(
    displayLarge: types.d1,
    displayMedium: types.d2,
    displaySmall: types.d3,
    headlineLarge: types.d4,
    headlineMedium: types.d5,
    headlineSmall: types.d6,
    titleLarge: types.uiTitle,
    titleMedium: types.title,
    titleSmall: types.bodyS,
    bodyLarge: types.body,
    bodyMedium: types.bodyS,
    bodySmall: types.caption,
    labelLarge: types.button,
    labelMedium: types.label,
    labelSmall: types.caption,
  ).apply(bodyColor: c.textPrimary, displayColor: c.textStrong);
  final clear = c.scrimClear;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.surfaceCanvas,
    canvasColor: c.surfaceCanvas,
    cardColor: c.surfaceRaised,
    dividerColor: c.borderHairline,
    focusColor: clear,
    hoverColor: clear,
    highlightColor: clear,
    splashColor: clear,
    splashFactory: NoSplash.splashFactory,
    textTheme: text,
    primaryTextTheme: text,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: gzPageTransitionsPlaceholder,
    extensions: const <ThemeExtension<dynamic>>[c],
  );
}

/// PLACEHOLDER page transitions (platform default). The navigation owner replaces this with the direction-aware push of the
/// motion list (24% travel + fade, flipped in RTL; the iOS interactive back swipe stays).
const PageTransitionsTheme gzPageTransitionsPlaceholder = PageTransitionsTheme();
