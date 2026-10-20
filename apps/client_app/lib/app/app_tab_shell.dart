import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import 'screen_registry.dart';

/// The tab shell: the current branch above a tab bar. PLACEHOLDER bar (GzStubTabBar) until `GzTabBar` lands in phase F2.
class AppTabShell extends StatelessWidget {
  const AppTabShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: MediaQuery.removePadding(context: context, removeBottom: true, child: navigationShell)),
        GzStubTabBar(
          tabs: [for (final t in kAppTabs) GzStubTab(titleEn: t.titleEn, titleAr: t.titleAr)],
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        ),
      ],
    );
  }
}
