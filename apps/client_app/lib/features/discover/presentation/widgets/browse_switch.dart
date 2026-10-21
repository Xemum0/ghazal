import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// The Venues | Services switch under the Home header: two tabs, each a glyph over its one word (both words shown), the 2 dp gold thread under
/// the active one. Flow-local because the system `GzIconTabs` with every label shown overflows its 56 cell by 4 (the web item measures 60:
/// glyph 24, gap 4, label 20, 4 and 4 of padding); `requests.md`.
class BrowseSwitch extends StatelessWidget {
  const BrowseSwitch({required this.onServices, super.key});

  final VoidCallback onServices;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.l10n;
    Widget tab(IconData icon, String label, bool selected, VoidCallback? onTap, {required Key key}) => Expanded(
      child: GzPressable(
        key: key,
        onPressed: onTap ?? () {},
        semanticLabel: label,
        selected: selected,
        builder: (context, st) => SizedBox(
          height: GzSpace.s16 - GzSpace.s1,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s1, horizontal: GzSpace.s1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GzIcon(icon, size: GzIconSize.md, color: selected ? c.iconPrimary : c.iconSecondary),
                const SizedBox(height: GzSpace.s1),
                SizedBox(
                  height: GzSpace.s5,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: gz.text(GzTextRole.tab).copyWith(color: selected ? c.textStrong : c.textSecondary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: l.clientDiscoverSwitchLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderStrong, width: GzStroke.hair))),
        child: Stack(
          children: [
            Row(
              children: [
                tab(GzIcons.hall, l.clientShellSwitchVenues, true, null, key: const ValueKey<String>('discover.switch.venues')),
                tab(GzIcons.flower, l.clientShellSwitchServices, false, onServices, key: const ValueKey<String>('discover.switch.services')),
              ],
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: Row(
                children: [
                  Expanded(child: SizedBox(height: GzStroke.thread, child: ColoredBox(color: c.markKhayt))),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
