import 'package:flutter/widgets.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';

/// The tab shell of the partner app: the shared [GzTabShell] with this app's tab names (Today, Bookings, Calendar, Messages, More).
/// Badges come from `gzTabBadgesProvider` (the partner flows fill it: pending requests on Bookings, unread on Messages).
class AppTabShell extends StatelessWidget {
  const AppTabShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static String _label(BuildContext context, String tabId) {
    final l = context.l10n;
    return switch (tabId) {
      'today' => l.hotelShellTabToday,
      'bookings' => l.hotelShellTabBookings,
      'calendar' => l.hotelShellTabCalendar,
      'messages' => l.hotelShellTabMessages,
      'more' => l.hotelShellTabMore,
      _ => tabId,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GzTabShell(navigationShell: navigationShell, kind: GzAppKind.partner, labelOf: _label, barLabel: context.l10n.hotelShellTabBarLabel);
  }
}
