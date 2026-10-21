import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show PlannerPackage;

import '../brand/brand.dart';
import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';
import 'gz_service_tile.dart' show gzImageSrc;

/// PlannerTierCard (CA-PLAN): Silver / Gold / Royal as a choice. One, two or three thread beads signal the tier, never a metal colour;
/// the price with its basis, what is included, who it suits, and for the planner, information only (no voucher: the consultation is a
/// conversation). With [onSelect] the photo and head are one radio (selected = ink border); [onRequest] adds the card's own action.
class GzPlannerTierCard extends StatelessWidget {
  const GzPlannerTierCard({required this.pkg, this.selected = false, this.onSelect, this.onRequest, this.loading = false, super.key});

  final PlannerPackage pkg;
  final bool selected;
  final VoidCallback? onSelect;

  /// The card's own action (the consultation request); omit when the screen has one sticky bar.
  final VoidCallback? onRequest;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    if (loading) {
      return Semantics(
        container: true,
        label: l.commonStateLoading,
        child: _TierPanel(
          selected: false,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 160),
              SizedBox(height: GzSpace.s4),
              Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 140, blockSize: 28)),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(blockSize: 20),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(blockSize: 20),
            ],
          ),
        ),
      );
    }
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzPhoto(
          src: gzImageSrc(pkg.image.file, pkg.image.baseUrl),
          alt: pkg.image.alt.of(lang),
          aspectRatio: GzLayout.aspect16x10,
          borderRadius: GzRadius.smAll,
        ),
        const SizedBox(height: GzSpace.s3),
        Row(
          children: [
            Expanded(
              child: GzText(pkg.name.of(lang), role: GzTextRole.d2, color: c.textStrong),
            ),
            const SizedBox(width: GzSpace.s3),
            Semantics(
              image: true,
              label: l.uiClientTierMarks(f.integer(pkg.marks)),
              excludeSemantics: true,
              child: Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < pkg.marks; i++) const GzThreadBead()]),
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s1),
        GzText(pkg.tagline.of(lang), role: GzTextRole.bodyS, color: c.textSecondary),
      ],
    );
    final choose = onSelect == null
        ? body
        : Semantics(
            inMutuallyExclusiveGroup: true,
            checked: selected,
            child: GzPressable(onPressed: onSelect, borderRadius: GzRadius.smAll, scale: 1, minHeight: 0, minWidth: 0, child: body),
          );
    return _TierPanel(
      selected: selected,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          choose,
          const SizedBox(height: GzSpace.s4),
          // The web price sits in a block whose strut is the body line (28 in Arabic): the block is as tall as that line.
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: (gz.text(GzTextRole.body).fontSize ?? 16) * (gz.text(GzTextRole.body).height ?? 1)),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzPrice(fils: pkg.from.fils, size: GzPriceSize.strong, prefix: l.uiSharedFrom),
            ),
          ),
          const SizedBox(height: GzSpace.s4),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
              ),
            ),
            padding: const EdgeInsets.only(top: GzSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < pkg.inclusions.length; i++) ...[
                  if (i > 0) const SizedBox(height: GzSpace.s2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: GzStroke.thread),
                        child: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.iconAccent),
                      ),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(child: GzText(pkg.inclusions[i].of(lang), role: GzTextRole.bodyS)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s4),
          GzText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${l.uiClientTierSuits} ',
                  style: TextStyle(color: c.textStrong, fontWeight: gz.text(GzTextRole.title).fontWeight),
                ),
                TextSpan(text: pkg.suits.of(lang)),
              ],
            ),
            role: GzTextRole.caption,
            color: c.textSecondary,
          ),
          if (onRequest != null) ...[
            const SizedBox(height: GzSpace.s4),
            GzButton(label: l.uiClientTierConsult, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: onRequest, iconEnd: GzIcons.chevronRight),
          ],
        ],
      ),
    );
  }
}

class _TierPanel extends StatelessWidget {
  const _TierPanel({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsets.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: selected ? c.controlChipBorderSelected : c.borderStrong, width: GzStroke.hair),
      ),
      child: child,
    );
  }
}
