import 'package:flutter/widgets.dart';

import '../../l10n/generated/gz_localizations.dart';
import '../motion/gz_pressable.dart';
import '../text/gz_bidi.dart';
import '../text/gz_text.dart';
import '../theme/gz_theme.dart';
import '../tokens/generated/gz_dimensions.g.dart';
import '../tokens/generated/gz_type.g.dart';

/// A clearly labelled "Not built yet" screen for an inventory screen with no Flutter implementation.
/// Unbuilt screens stay visible on purpose: the final sweep fails on any route that still renders this widget.
/// `tools/gen-routes.mjs` emits one per inventory screen; a flow agent replaces it with the real screen.
class GzStubScreen extends StatelessWidget {
  const GzStubScreen({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.kind,
    this.purpose = '',
    super.key,
  });

  /// Inventory id, for example `CL-DISC-01`.
  final String id;
  final String titleEn;
  final String titleAr;

  /// Inventory kind: `screen`, `sheet` or `tab-root`.
  final String kind;

  /// Inventory purpose text (English, developer-facing, shown on stubs only).
  final String purpose;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    return ColoredBox(
      color: c.surfaceCanvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s6, vertical: GzSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.statusPendingBg,
                  border: Border.all(color: c.markKhayt, width: GzStroke.hair),
                  borderRadius: GzRadius.smAll,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3, vertical: GzSpace.s2),
                  child: GzText(GzL10n.of(context).stubNotBuilt, role: GzTextRole.button, color: c.textStrong),
                ),
              ),
              const SizedBox(height: GzSpace.s5),
              GzLtr(child: GzText(id, role: GzTextRole.title, color: c.textSecondary)),
              const SizedBox(height: GzSpace.s2),
              GzText(gz.isAr ? titleAr : titleEn, role: GzTextRole.d3, color: c.textStrong),
              const SizedBox(height: GzSpace.s1),
              GzLtr(child: GzText(kind, role: GzTextRole.caption, color: c.textSecondary)),
              if (purpose.isNotEmpty) ...[
                const SizedBox(height: GzSpace.s4),
                GzLtr(child: GzText(purpose, role: GzTextRole.bodyS, color: c.textSecondary, maxLines: 8)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One entry of the stub tab bar.
class GzStubTab {
  const GzStubTab({required this.titleEn, required this.titleAr});

  final String titleEn;
  final String titleAr;
}

/// PLACEHOLDER tab bar for the tab shell (labels always visible; order mirrors in RTL because it is a Row).
/// Replaced by `GzTabBar` in phase F2.
class GzStubTabBar extends StatelessWidget {
  const GzStubTabBar({required this.tabs, required this.currentIndex, required this.onTap, super.key});

  final List<GzStubTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: bottom),
        child: SizedBox(
          height: GzSize.tabBar,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: GzPressable(
                    onPressed: () => onTap(i),
                    selected: i == currentIndex,
                    child: Center(
                      child: GzText(
                        gz.isAr ? tabs[i].titleAr : tabs[i].titleEn,
                        role: GzTextRole.tab,
                        color: i == currentIndex ? c.textStrong : c.textSecondary,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
