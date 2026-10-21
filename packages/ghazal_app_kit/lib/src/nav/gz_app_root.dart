import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'nav_providers.dart';

/// The root widget both apps share: [GzApp] over `routerProvider`, with the scopes every screen expects installed above the router:
/// [GzAppScope] (which app), [GzFormatScope] (`gzFormatProvider`: the digit style and the clock), [GzNavigatorScope] (the app's
/// navigator) and [GzToastHost] (the one toast controller). [overlays] are drawn above everything (the dev-only demo hotspot).
///
/// - [onResume]: callbacks run each time the app comes back to the foreground (a `WidgetsBindingObserver`), in order. The apps pass their
///   badge refresh: `GzAppRoot(kind: ..., onResume: [refreshClientBadges])`, so a message that arrived while away shows on the tab bar.
/// - [warmUp]: providers the root listens to for as long as the app runs, so their data is loading before a screen asks for it
///   (the client's wedding profile, which seeds the Brief at sign-in): `warmUp: [weddingProfileProvider]`.
class GzAppRoot extends ConsumerStatefulWidget {
  const GzAppRoot({
    required this.kind,
    this.title = 'Ghazal',
    this.extraLocalizationsDelegates = const <LocalizationsDelegate<dynamic>>[],
    this.overlays = const <Widget>[],
    this.onResume = const <void Function(WidgetRef ref)>[],
    this.warmUp = const <ProviderListenable<Object?>>[],
    super.key,
  });

  final GzAppKind kind;
  final String title;
  final List<LocalizationsDelegate<dynamic>> extraLocalizationsDelegates;
  final List<Widget> overlays;
  final List<void Function(WidgetRef ref)> onResume;
  final List<ProviderListenable<Object?>> warmUp;

  @override
  ConsumerState<GzAppRoot> createState() => _GzAppRootState();
}

class _GzAppRootState extends ConsumerState<GzAppRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    for (final callback in widget.onResume) {
      callback(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    for (final provider in widget.warmUp) {
      ref.listen<Object?>(provider, (_, _) {});
    }
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    final navigator = ref.watch(gzNavigatorProvider);
    final toasts = ref.watch(gzToastControllerProvider);
    final format = ref.watch(gzFormatProvider);
    final overlays = widget.overlays;
    return GzApp(
      routerConfig: router,
      locale: locale,
      title: widget.title,
      extraLocalizationsDelegates: widget.extraLocalizationsDelegates,
      builder: (context, child) => GzAppScope(
        app: widget.kind,
        child: GzFormatScope(
          format: format,
          child: GzNavigatorScope(
            navigator: navigator,
            child: GzToastHost(
              controller: toasts,
              child: overlays.isEmpty
                  ? (child ?? const SizedBox.shrink())
                  : Stack(
                      children: [
                        Positioned.fill(child: child ?? const SizedBox.shrink()),
                        ...overlays,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
