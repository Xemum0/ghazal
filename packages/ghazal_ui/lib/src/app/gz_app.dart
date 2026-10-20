import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/gz_localizations.dart';
import '../theme/placeholder_theme.dart';

/// Supported UI locales: Arabic (RTL) first, English (LTR).
const List<Locale> gzAppLocales = [Locale('ar'), Locale('en')];

/// The framework delegates every Ghazal app needs (words of ghazal_ui, widgets, material, cupertino). Apps add their own `AppL10n.delegate`.
const List<LocalizationsDelegate<dynamic>> gzLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  GzL10n.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// The one app host of both apps and the ONLY place that uses `MaterialApp.router` (plan section 2).
///
/// - [routerConfig]: any `RouterConfig<Object>` (the apps pass their `GoRouter`), so this package never imports go_router.
/// - [locale]: the current UI locale; the apps feed it from `localeProvider` (default Arabic on first run, switchable).
///   Text direction follows the locale through the Widgets localizations.
/// - [extraLocalizationsDelegates]: the app's own `AppL10n.delegate`.
class GzApp extends StatelessWidget {
  const GzApp({
    required this.routerConfig,
    required this.locale,
    this.extraLocalizationsDelegates = const [],
    this.title = 'Ghazal',
    this.builder,
    super.key,
  });

  final RouterConfig<Object> routerConfig;
  final Locale locale;
  final List<LocalizationsDelegate<dynamic>> extraLocalizationsDelegates;
  final String title;
  final TransitionBuilder? builder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      routerConfig: routerConfig,
      locale: locale,
      supportedLocales: gzAppLocales,
      localizationsDelegates: [...extraLocalizationsDelegates, ...gzLocalizationsDelegates],
      theme: buildPlaceholderTheme(locale),
      builder: (context, child) {
        // No Scaffold/Material above plain widgets: give them the body text style (no yellow debug underline).
        final body = Theme.of(context).textTheme.bodyLarge;
        final content = DefaultTextStyle(
          style: (body ?? const TextStyle()).copyWith(decoration: TextDecoration.none),
          child: child ?? const SizedBox.shrink(),
        );
        return builder == null ? content : builder!(context, content);
      },
    );
  }
}
