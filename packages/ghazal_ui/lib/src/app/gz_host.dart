import 'package:material_ui/material_ui.dart';

import '../theme/gz_theme.dart';
import '../tokens/generated/gz_colors.g.dart';
import '../tokens/generated/gz_type.g.dart';
import 'gz_app.dart' show gzAppLocales, gzLocalizationsDelegates;

/// A minimal app host for galleries and widget tests: the same theme, localisation delegates, text defaults and `GzTheme` as
/// [GzApp], with a Navigator and Overlay (sheets, dialogs, tooltips, text selection) but no router.
///
/// `GzHost(locale: Locale('ar'), child: MyWidget())`. Production code never uses it; apps use [GzApp].
class GzHost extends StatelessWidget {
  const GzHost({
    required this.locale,
    required this.child,
    this.extraLocalizationsDelegates = const [],
    super.key,
  });

  final Locale locale;
  final Widget child;
  final List<LocalizationsDelegate<dynamic>> extraLocalizationsDelegates;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: gzAppLocales,
      localizationsDelegates: [...extraLocalizationsDelegates, ...gzLocalizationsDelegates],
      theme: buildGhazalTheme(locale),
      builder: (context, navigator) => GzTheme(
        locale: locale,
        child: DefaultTextStyle(
          style: GzType.style(locale, GzTextRole.body).copyWith(color: GzColors.light.textPrimary, decoration: TextDecoration.none),
          child: navigator ?? const SizedBox.shrink(),
        ),
      ),
      home: child,
    );
  }
}
