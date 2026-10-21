import 'package:flutter/widgets.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';

/// The tab shell of the client app: the shared [GzTabShell] with this app's tab names (Discover, Saved, My Wedding, Messages, Profile).
/// Badges come from `gzTabBadgesProvider` (the flows fill it).
class AppTabShell extends StatelessWidget {
  const AppTabShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static String _label(BuildContext context, String tabId) {
    final l = context.l10n;
    return switch (tabId) {
      'discover' => l.clientShellTabDiscover,
      'saved' => l.clientShellTabSaved,
      'my-wedding' => l.clientShellTabMyWedding,
      'messages' => l.clientShellTabMessages,
      'profile' => l.clientShellTabProfile,
      _ => tabId,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GzTabShell(navigationShell: navigationShell, kind: GzAppKind.client, labelOf: _label, barLabel: context.l10n.clientShellTabBarLabel);
  }
}
