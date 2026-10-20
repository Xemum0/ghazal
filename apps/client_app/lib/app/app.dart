import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_router.dart';

/// The app root: owns the router, feeds the locale from `localeProvider` into `GzApp` (the only MaterialApp host).
class ClientApp extends ConsumerStatefulWidget {
  const ClientApp({this.router, super.key});

  /// Injected by tests and the shot harness; a normal start builds its own.
  final GoRouter? router;

  @override
  ConsumerState<ClientApp> createState() => _ClientAppState();
}

class _ClientAppState extends ConsumerState<ClientApp> {
  late final GoRouter _router = widget.router ?? buildAppRouter();

  @override
  void dispose() {
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return GzApp(
      routerConfig: _router,
      locale: locale,
      title: 'Ghazal',
      extraLocalizationsDelegates: const [AppL10n.delegate],
    );
  }
}
