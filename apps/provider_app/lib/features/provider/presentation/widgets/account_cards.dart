// The two choice cards of HL-PROV-01 and the chip of a chosen category (web `HL-PROV-01.css`: hp01__card, hp01__cat).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// One large choice card: a disk with the glyph, the title, the gold bead of the choice and three quiet glyphs of what the account does.
class AccountCard extends StatelessWidget {
  const AccountCard({required this.icon, required this.title, required this.facts, required this.selected, required this.onTap, super.key});

  final IconData icon;
  final String title;
  final List<IconData> facts;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: GzPressable(
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: selected ? c.controlChipBorderSelected : c.controlChipBorder, width: selected ? GzStroke.focus : GzStroke.hair),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                    child: SizedBox(width: GzSize.avatarSm, height: GzSize.avatarSm, child: Center(child: GzIcon(icon, size: GzIconSize.md, color: c.iconPrimary))),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(child: GzText(title, role: GzTextRole.title, color: c.textStrong)),
                  GzThreadBead(tone: selected ? GzBeadTone.gold : GzBeadTone.hollow),
                ],
              ),
              const SizedBox(height: GzSpace.s3),
              Row(
                children: [
                  for (final (i, f) in facts.indexed) ...[
                    if (i > 0) const SizedBox(width: GzSpace.s4),
                    GzIcon(f, size: GzIconSize.md, color: c.iconSecondary),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A chosen category: a tinted chip with its glyph.
class SelectedCategory extends StatelessWidget {
  const SelectedCategory({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.smAll),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(icon, size: GzIconSize.xs, color: c.iconPrimary),
              const SizedBox(width: GzSpace.s2),
              GzText(label, role: GzTextRole.bodyS, color: c.textStrong),
            ],
          ),
        ),
      ),
    );
  }
}
