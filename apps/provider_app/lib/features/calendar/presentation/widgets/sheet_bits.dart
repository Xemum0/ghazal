// The small pieces of the two calendar sheets (web `calendar/_components/CalNotice.tsx`, `ChipRow.tsx`, `Outcome.tsx`): the inset notice band, a chip
// group named by a glyph, and the outcome composition (a drawing, a few words, the facts). They sit inside a sheet that already has its gutter.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

enum NoticeTone { offline, warning, danger }

class CalNotice extends StatelessWidget {
  const CalNotice({required this.tone, this.children = const [], this.icon, this.lead, this.head, this.info, this.actionLabel, this.onAction, super.key});

  final NoticeTone tone;
  final List<Widget> children;

  /// The glyph; the tone's own by default. Pass [lead] (a mark) to stand in.
  final IconData? icon;
  final Widget? lead;
  final Widget? head;
  final Widget? info;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final bg = switch (tone) {
      NoticeTone.offline => c.surfaceQuiet,
      NoticeTone.warning => c.surfaceTint,
      NoticeTone.danger => c.statusDangerBg,
    };
    final fg = tone == NoticeTone.danger ? c.statusDangerText : c.textPrimary;
    final glyph = icon ?? (lead != null ? null : switch (tone) { NoticeTone.offline => GzIcons.offline, NoticeTone.warning => GzIcons.info, NoticeTone.danger => GzIcons.warningCircle });
    final iconColor = tone == NoticeTone.danger ? c.statusDangerText : (tone == NoticeTone.warning ? c.iconPrimary : c.iconSecondary);
    final hasHead = head != null || info != null;
    final top = hasHead ? GzSpace.s3 : GzSpace.s1;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsetsDirectional.only(start: GzSpace.s4, end: hasHead && info != null ? GzSpace.s1 : GzSpace.s4, top: hasHead ? GzSpace.s1 : GzSpace.s3, bottom: GzSpace.s3),
        decoration: BoxDecoration(color: bg, borderRadius: GzRadius.smAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lead != null) Padding(padding: EdgeInsets.only(top: top), child: SizedBox(height: GzSize.iconSm, child: Center(child: lead)))
                else if (glyph != null) Padding(padding: EdgeInsets.only(top: top), child: GzIcon(glyph, size: GzIconSize.sm, color: iconColor)),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: fg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasHead)
                          Row(children: [Expanded(child: head ?? const SizedBox.shrink()), ?info]),
                        for (var i = 0; i < children.length; i++) ...[if (i > 0 || hasHead) const SizedBox(height: GzSpace.s1), children[i]],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (actionLabel != null)
              Padding(padding: const EdgeInsetsDirectional.only(start: GzSpace.s6), child: Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: actionLabel!, variant: GzButtonVariant.tertiary, onPressed: onAction))),
          ],
        ),
      ),
    );
  }
}

/// A chip group named by a glyph instead of a label: the glyph sits at inline-start on the first line of chips, the chips wrap beside it.
class CalChipRow extends StatelessWidget {
  const CalChipRow({required this.icon, required this.child, super.key});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(child: SizedBox(width: GzSize.iconMd, height: GzSize.touchMin, child: Center(child: GzIcon(icon, size: GzIconSize.md, color: context.gz.colors.iconSecondary)))),
      const SizedBox(width: GzSpace.s3),
      Expanded(child: child),
    ],
  );
}

/// A drawing, the outcome in a few words, and the facts under it.
class CalOutcome extends StatelessWidget {
  const CalOutcome({required this.art, required this.title, this.children = const [], super.key});

  final GzIllustrationName art;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s4),
      child: Column(
        children: [
          GzIllustration(art),
          const SizedBox(height: GzSpace.s3),
          GzText(title, role: GzTextRole.uiTitle, color: context.gz.colors.textStrong, textAlign: TextAlign.center, header: true),
          for (final w in children) ...[const SizedBox(height: GzSpace.s3), w],
        ],
      ),
    ),
  );
}
