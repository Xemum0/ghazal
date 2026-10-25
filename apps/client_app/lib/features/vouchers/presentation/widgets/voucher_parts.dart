import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ImageRef;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../voucher_fmt.dart';

/// The title row of a sheet screen (web `SheetTop`): the title at inline-start, then the info glyph that holds the one paragraph that
/// survived the diet and the close glyph at inline-end (ADR 0014 D3). The sheet already carries the 20 gutter.
class VoucherSheetTop extends StatelessWidget {
  const VoucherSheetTop({required this.title, this.infoTitle, this.infoParagraphs = const <String>[], this.infoChildren = const <Widget>[], this.onClose, super.key});

  final String title;
  final String? infoTitle;
  final List<String> infoParagraphs;
  final List<Widget> infoChildren;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      child: Row(
        children: [
          Expanded(child: GzText(title, role: GzTextRole.d1, color: c.textStrong, header: true)),
          if (infoTitle != null) ...[
            const SizedBox(width: GzSpace.s1),
            GzInfoButton(title: infoTitle!, paragraphs: infoParagraphs, bleed: true, children: infoChildren),
          ],
          const SizedBox(width: GzSpace.s1),
          GzBarButton(key: const ValueKey<String>('gz:sheet.close'), icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: onClose ?? context.gzNav.closeSheet),
        ],
      ),
    );
  }
}

/// The venue's cover photograph at 56, or the provider's monogram (never a face): one square for every voucher row and plate.
class VoucherThumb extends StatelessWidget {
  const VoucherThumb({required this.name, this.cover, this.monogram, super.key});

  final String name;
  final ImageRef? cover;
  final String? monogram;

  @override
  Widget build(BuildContext context) {
    final ref = cover;
    if (ref != null) {
      return SizedBox(
        width: GzSize.thumbMd,
        height: GzSize.thumbMd,
        child: GzPhoto(src: gzImageRefSrc(ref), alt: ref.alt.of(context.gz.locale.languageCode), borderRadius: GzRadius.smAll),
      );
    }
    return GzAvatar(name: name, initial: monogram != null && monogram!.isNotEmpty ? monogram : null, size: GzAvatarSize.md);
  }
}

/// What a voucher saves at the venue, as a glyph and one figure (web `Saving`): "You save" is the glyph's accessible name.
class VoucherSaving extends StatelessWidget {
  const VoucherSaving({required this.fils, this.size = GzPriceSize.total, super.key});

  final int fils;
  final GzPriceSize size;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    return Semantics(
      container: true,
      label: context.gzL10n.commonYouSave(f.moneyBrowse(fils)),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: GzSize.disk,
            height: GzSize.disk,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
            child: GzIcon(GzIcons.trendDown, size: GzIconSize.sm, color: c.iconSuccess, mirror: false),
          ),
          const SizedBox(width: GzSpace.s2),
          Flexible(child: GzPrice(fils: fils, size: size)),
        ],
      ),
    );
  }
}

/// One of two equal choices (web `ChoiceRow`): a glyph in a quiet disk, a title, its facts and a mirrored chevron. A whole row is the
/// target (64 and up). Neither choice is gold.
class VoucherChoiceRow extends StatelessWidget {
  const VoucherChoiceRow({required this.icon, required this.title, required this.onPressed, this.facts, this.disabled = false, super.key});

  final IconData icon;
  final String title;
  final Widget? facts;
  final VoidCallback onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final ink = disabled ? c.textDisabled : c.textStrong;
    return GzPressable(
      onPressed: disabled ? null : onPressed,
      semanticLabel: title,
      borderRadius: GzRadius.mdAll,
      minHeight: GzSize.rowMin,
      expand: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
        decoration: BoxDecoration(
          color: c.surfaceCanvas,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: disabled ? c.borderHairline : c.borderStrong, width: GzStroke.hair),
        ),
        child: Row(
          children: [
            Container(
              width: GzSize.avatarSm,
              height: GzSize.avatarSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.surfaceQuiet, shape: BoxShape.circle),
              child: GzIcon(icon, size: GzIconSize.sm, color: disabled ? c.iconDisabled : c.iconPrimary),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzText(title, role: GzTextRole.title, color: ink),
                  if (facts != null) ...[const SizedBox(height: GzSpace.s1), facts!],
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
          ],
        ),
      ),
    );
  }
}

enum PhaseTone { neutral, pending, success, danger }

/// What the voucher is doing now (web `PhaseStrip`): a glyph (or a drawing for an ended voucher), a word or two, facts and the info
/// glyph holding the one paragraph that survived the diet. A quiet panel with no fill colour: the tone reaches the glyph only.
class PhaseStrip extends StatelessWidget {
  const PhaseStrip({
    this.icon,
    this.tone = PhaseTone.neutral,
    this.illustration,
    this.title,
    this.child,
    this.infoTitle,
    this.infoParagraphs = const <String>[],
    this.infoChildren = const <Widget>[],
    this.actions,
    super.key,
  });

  final IconData? icon;
  final PhaseTone tone;
  final GzIllustrationName? illustration;
  final String? title;
  final Widget? child;
  final String? infoTitle;
  final List<String> infoParagraphs;
  final List<Widget> infoChildren;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final glyph = switch (tone) {
      PhaseTone.neutral => c.iconSecondary,
      PhaseTone.pending => c.iconAccent,
      PhaseTone.success => c.iconSuccess,
      PhaseTone.danger => c.iconDanger,
    };
    return Container(
      key: const ValueKey<String>('voucher.phase'),
      padding: GzSpace.panel,
      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (illustration != null) ...[
                ExcludeSemantics(child: GzIllustration(illustration!, size: GzIllustrationSize.md)),
                const SizedBox(width: GzSpace.s3),
              ] else if (icon != null) ...[
                Container(
                  width: GzSize.touchMin,
                  height: GzSize.touchMin,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.surfaceRaised, shape: BoxShape.circle),
                  child: ExcludeSemantics(child: GzIcon(icon!, size: GzIconSize.md, color: glyph)),
                ),
                const SizedBox(width: GzSpace.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) GzText(title!, role: GzTextRole.title, color: tone == PhaseTone.danger ? c.textDanger : c.textStrong, header: true),
                    if (child != null) ...[if (title != null) const SizedBox(height: GzSpace.s2), child!],
                  ],
                ),
              ),
              if (infoTitle != null) ...[const SizedBox(width: GzSpace.s3), GzInfoButton(title: infoTitle!, paragraphs: infoParagraphs, bleed: true, children: infoChildren)],
            ],
          ),
          if (actions != null) ...[const SizedBox(height: GzSpace.s4), Wrap(spacing: GzSpace.s3, runSpacing: GzSpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [actions!])],
        ],
      ),
    );
  }
}

/// A fact row with one chip, for a date or a count (the common case of a phase strip).
Widget voucherFact(BuildContext context, {required IconData icon, required String label, required String value, GzFactTone tone = GzFactTone.muted}) =>
    GzFactRow(children: [GzFactChip(icon: icon, label: label, value: value, tone: tone)]);
