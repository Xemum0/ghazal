// The pieces of Notification preferences (web `NotifParts.tsx`; text diet, ADR 0034): one switch row per alert type (a glyph disk, one word, the
// switch) and the "about this page" body the top bar's (i) opens: at most three short lines, each with its glyph.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The whole row is the target; the switch is the one focusable control and carries the title as its name.
class PrefRow extends StatelessWidget {
  const PrefRow({required this.icon, required this.title, required this.checked, required this.onChanged, this.disabled = false, this.last = false, super.key});

  final IconData icon;
  final String title;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final bool disabled;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : () => onChanged(!checked),
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline.withAlpha(last ? 0 : 255), width: GzStroke.hair))),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: GzSize.avatarSm,
                height: GzSize.avatarSm,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                child: GzIcon(icon, size: GzIconSize.md, color: disabled ? c.iconDisabled : c.iconPrimary),
              ),
            ),
            const SizedBox(width: GzSpace.s4),
            Expanded(child: GzText(title, role: GzTextRole.title, color: disabled ? c.textDisabled : c.textStrong)),
            GzSwitch(label: title, checked: checked, disabled: disabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// The (i) of a settings page: lines of at most one short sentence, each with its glyph.
class AboutLines extends StatelessWidget {
  const AboutLines({required this.lines, super.key});

  final List<(IconData, String)> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: GzSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: GzIcon(lines[i].$1, size: GzIconSize.sm, color: c.iconSecondary)),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: GzText(lines[i].$2)),
            ],
          ),
        ],
      ],
    );
  }
}
