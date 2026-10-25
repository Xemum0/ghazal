// Small blocks shared by the decision sheets (web `Blocks.tsx`, ADR 0034: glyphs, figures and drawings, no sentences). A section label, a glyph
// line, the voucher price as a glyph and a figure, a switch row led by a glyph, the reason tiles, the consequence cells and the state
// composition of a sheet. Money is always integer fils through `GzPrice`; nothing here types a number or a date.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

class DcSectionLabel extends StatelessWidget {
  const DcSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: GzSpace.s2),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: GzText(text, role: GzTextRole.label, color: context.gz.colors.textSecondary),
    ),
  );
}

/// A glyph and a very short text (a consequence, a limit): glyph 16, caption text.
class DcFactLine extends StatelessWidget {
  const DcFactLine({required this.icon, required this.text, this.tone = GzIconTone.secondary, super.key});

  final IconData icon;
  final String text;
  final GzIconTone tone;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      GzIcon(icon, size: GzIconSize.xs, tone: tone),
      const SizedBox(width: GzSpace.s2),
      Expanded(
        child: GzText(text, role: GzTextRole.caption, color: context.gz.colors.textSecondary),
      ),
    ],
  );
}

/// The voucher price as a ticket glyph and an amount (the word is the accessible name).
class DcPriceFact extends StatelessWidget {
  const DcPriceFact({required this.fils, required this.label, this.total = false, super.key});

  final int fils;
  final String label;
  final bool total;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GzIcon(GzIcons.ticket, size: GzIconSize.sm, tone: GzIconTone.success),
        const SizedBox(width: GzSpace.s2),
        GzPrice(fils: fils, size: total ? GzPriceSize.total : GzPriceSize.strong),
      ],
    ),
  );
}

/// A glyph in a rose disk (40): the leading element of a glyph row.
class DcDisk extends StatelessWidget {
  const DcDisk(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: GzSize.avatarSm,
      height: GzSize.avatarSm,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.gz.colors.surfaceTint, shape: BoxShape.circle),
      child: GzIcon(icon, size: GzIconSize.md, tone: GzIconTone.primary),
    ),
  );
}

/// A row led by a glyph in a rose disk, a one or two word title and the shared switch; the whole row is the target.
class DcSwitchRow extends StatelessWidget {
  const DcSwitchRow({required this.icon, required this.title, required this.checked, required this.onChanged, super.key});

  final IconData icon;
  final String title;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!checked),
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Row(
          children: [
            DcDisk(icon),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: GzText(title, role: GzTextRole.body, color: c.textStrong),
            ),
            GzSwitch(label: title, checked: checked, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// A collapsed row: glyph disk, a one or two word title and a chevron that turns; opens the block under it.
class DcDiscloseRow extends StatelessWidget {
  const DcDiscloseRow({required this.icon, required this.title, required this.open, required this.onToggle, super.key});

  final IconData icon;
  final String title;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onToggle,
      semanticLabel: title,
      expanded: open,
      borderRadius: GzRadius.smAll,
      minHeight: GzSize.rowMin,
      expand: true,
      child: Row(
        children: [
          DcDisk(icon),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: GzText(title, role: GzTextRole.body, color: c.textStrong),
          ),
          GzIcon(open ? GzIcons.chevronUp : GzIcons.chevronDown, size: GzIconSize.sm, tone: GzIconTone.secondary),
        ],
      ),
    );
  }
}

/// One to three picks as pips: filled = picked, open = still free to pick.
class DcPickPips extends StatelessWidget {
  const DcPickPips({required this.count, required this.max, required this.label, super.key});

  final int count;
  final int max;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++) ...[
            if (i > 0) const SizedBox(width: GzSpace.s2),
            Container(
              width: GzSize.knotCompact,
              height: GzSize.knotCompact,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < count ? c.markKhayt : null,
                border: Border.all(color: i < count ? c.markDecor : c.borderControl, width: GzStroke.hair),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DcReason<V> {
  const DcReason(this.value, this.icon, this.label);

  final V value;
  final IconData icon;
  final String label;
}

/// A required single choice as equal glyph tiles (a glyph in a rose disk over one word); the selected tile takes an ink border and an ink disk.
class DcReasonTiles<V> extends StatelessWidget {
  const DcReasonTiles({required this.options, required this.value, required this.onChanged, required this.label, super.key});

  final List<DcReason<V>> options;
  final V? value;
  final ValueChanged<V> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    return Semantics(
      container: true,
      label: label,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: GzSpace.s2),
              Expanded(
                child: Builder(
                  builder: (_) {
                    final o = options[i];
                    final on = o.value == value;
                    return GzPressable(
                      onPressed: () => onChanged(o.value),
                      semanticLabel: o.label,
                      selected: on,
                      borderRadius: GzRadius.mdAll,
                      minHeight: GzSize.rowMin,
                      scale: 1,
                      expand: true,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s1, vertical: GzSpace.s3),
                        decoration: BoxDecoration(
                          color: on ? c.controlBg : null,
                          borderRadius: GzRadius.mdAll,
                          border: Border.all(color: on ? c.controlChipBorderSelected : c.controlChipBorder, width: GzStroke.hair),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: GzSize.disk,
                              height: GzSize.disk,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: on ? c.surfaceDark : c.surfaceTint, shape: BoxShape.circle),
                              child: GzIcon(o.icon, size: GzIconSize.sm, tone: on ? GzIconTone.onDark : GzIconTone.primary),
                            ),
                            const SizedBox(height: GzSpace.s2),
                            GzText(
                              o.label,
                              role: GzTextRole.caption,
                              color: on ? c.textStrong : c.textPrimary,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DcConsequence {
  const DcConsequence(this.icon, this.label, {this.danger = false});

  final IconData icon;
  final String label;
  final bool danger;
}

/// What happens, as glyphs: one panel, equal columns divided by hairlines, each a glyph in a disk over one word.
class DcConsequenceRow extends StatelessWidget {
  const DcConsequenceRow({required this.items, required this.label, super.key});

  final List<DcConsequence> items;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s3),
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : BorderDirectional(
                              start: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                            ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: GzSize.disk,
                          height: GzSize.disk,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: items[i].danger ? c.statusDangerBg : c.surfaceTint, shape: BoxShape.circle),
                          child: GzIcon(items[i].icon, size: GzIconSize.sm, tone: items[i].danger ? GzIconTone.danger : GzIconTone.primary),
                        ),
                        const SizedBox(height: GzSpace.s2),
                        GzText(items[i].label, role: GzTextRole.caption, color: c.textStrong, textAlign: TextAlign.center),
                      ],
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

/// A quiet 48 high row that leads somewhere else (the softer way out): glyph, a one or two word title, a chevron that mirrors.
class DcLinkRow extends StatelessWidget {
  const DcLinkRow({required this.icon, required this.title, required this.onPressed, super.key});

  final IconData icon;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GzPressable(
    onPressed: onPressed,
    semanticLabel: title,
    borderRadius: GzRadius.smAll,
    minHeight: GzSize.controlMd,
    expand: true,
    child: Row(
      children: [
        GzIcon(icon, size: GzIconSize.md, tone: GzIconTone.primary),
        const SizedBox(width: GzSpace.s3),
        Expanded(
          child: GzText(title, role: GzTextRole.body, color: context.gz.colors.textStrong),
        ),
        GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, tone: GzIconTone.secondary),
      ],
    ),
  );
}

/// An empty or success composition inside a sheet: the drawing, a title of at most four words, the info glyph; the sheet footer owns the action.
class DcState extends StatelessWidget {
  const DcState({required this.illustration, required this.title, this.detail, this.facts, this.success = false, super.key});

  final GzIllustrationName illustration;
  final String title;
  final String? detail;
  final Widget? facts;
  final bool success;

  @override
  Widget build(BuildContext context) => success
      ? GzSuccessState(
          illustration: illustration,
          title: title,
          detail: detail,
          detailTitle: context.gzL10n.commonLabelDetails,
          facts: facts,
          fill: false,
          size: GzIllustrationSize.lg,
        )
      : GzEmptyState(
          illustration: illustration,
          title: title,
          detail: detail,
          detailTitle: context.gzL10n.commonLabelDetails,
          facts: facts,
          fill: false,
          size: GzIllustrationSize.lg,
        );
}
