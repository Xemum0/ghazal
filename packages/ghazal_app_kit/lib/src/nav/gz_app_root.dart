import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'nav_providers.dart';

/// The root widget both apps share: [GzApp] over `routerProvider`, with the scopes every screen expects installed above the router:
/// [GzAppScope] (which app), [GzFormatScope] (`gzFormatProvider`: the digit style and the clock), [GzNavigatorScope] (the app's
/// navigator) and [GzToastHost] (the one toast controller). [overlays] are drawn above everything (the dev-only demo hotspot).
class GzAppRoot extends ConsumerWidget {
  const GzAppRoot({
    required this.kind,
    this.title = 'Ghazal',
    this.extraLocalizationsDelegates = const <LocalizationsDelegate<dynamic>>[],
    this.overlays = const <Widget>[],
    super.key,
  });

  final GzAppKind kind;
  final String title;
  final List<LocalizationsDelegate<dynamic>> extraLocalizationsDelegates;
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    final navigator = ref.watch(gzNavigatorProvider);
    final toasts = ref.watch(gzToastControllerProvider);
    final format = ref.watch(gzFormatProvider);
    return GzApp(
      routerConfig: router,
      locale: locale,
      title: title,
      extraLocalizationsDelegates: extraLocalizationsDelegates,
      builder: (context, child) => GzAppScope(
        app: kind,
        child: GzFormatScope(
          format: format,
          child: GzNavigatorScope(
            navigator: navigator,
            child: GzToastHost(
              controller: toasts,
              child: overlays.isEmpty ? (child ?? const SizedBox.shrink()) : Stack(children: [Positioned.fill(child: child ?? const SizedBox.shrink()), ...overlays]),
            ),
          ),
        ),
      ),
    );
  }
}
