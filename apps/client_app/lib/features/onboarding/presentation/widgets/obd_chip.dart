import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// An equal-width tile chip (web `.obd-roles__chip`, `.obd-presets__chip`, `.obd-months__chip`: `flex: 1; justify-content: center`; a
/// selected tile trades 4 dp of start padding for its bead and gives them back at the end so equal tiles stay equal). The kit [GzChip]
/// hugs its label inside any parent (its pressable shrink-wraps), so a chip that must fill its cell is drawn here with the same anatomy
/// (requests.md: `GzChip(expand: true)`).
class ObdChip extends StatelessWidget {
  const ObdChip({required this.label, required this.selected, required this.onPressed, this.iconStart, this.figures = false, super.key});

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? iconStart;

  /// The label holds numbers: digits are drawn as figure islands.
  final bool figures;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final fg = selected ? c.textStrong : c.textPrimary;
    final base = gzResetLabelStyle(gz);
    final heavy = gz.text(GzTextRole.title).fontWeight;
    final weight = selected ? heavy : base.fontWeight;
    final Widget text = figures
        ? gzFigText(context, label, role: GzTextRole.figBodyS, weight: weight, color: fg)
        : GzText(label, role: GzTextRole.body, color: fg, maxLines: 1);
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      borderRadius: GzRadius.smAll,
      scale: 1,
      child: AnimatedContainer(
        duration: GzMotion.durationBase,
        curve: GzMotion.easeStandard,
        constraints: const BoxConstraints(minHeight: GzSize.controlSm),
        width: double.infinity,
        padding: EdgeInsetsDirectional.only(start: selected ? GzSpace.s3 : GzSpace.s4, end: selected ? GzSpace.s5 : GzSpace.s4),
        decoration: BoxDecoration(
          color: selected ? c.controlBg : null,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: selected ? c.controlChipBorderSelected : c.controlChipBorder, width: GzStroke.hair),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[const GzBeadBox(), const SizedBox(width: GzSpace.s2)],
            if (iconStart != null) ...[GzIcon(iconStart!, size: GzIconSize.sm, color: fg), const SizedBox(width: GzSpace.s2)],
            Flexible(child: text),
          ],
        ),
      ),
    );
  }
}
