import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../nav/nav_providers.dart' show gzNavigatorProvider;
import 'demo_control.dart';
import 'demo_hotspot.dart';
import 'demo_sheet.dart';

/// The demo tools overlay: mount it in the `overlays` of `GzAppRoot` (a child of the app's `Stack`). Outside production builds with the
/// in-process mock, five taps on the 44 dp hotspot at the top-start corner open [GzDemoToolsSheet] as a sheet; otherwise it draws nothing.
class GzDemoTools extends ConsumerWidget {
  const GzDemoTools({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(demoToolsAvailableProvider)) return const SizedBox.shrink();
    return GzDemoHotspot(
      onActivated: () => ref.read(gzNavigatorProvider).openSheetBuilder(
            (_) => const GzDemoToolsSheet(),
            options: GzSheetOptions(title: context.gzL10n.uiKitDemoTitle),
          ),
    );
  }
}
