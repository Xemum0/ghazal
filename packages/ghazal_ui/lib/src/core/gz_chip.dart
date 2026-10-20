import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_badge.dart';
import 'gz_preview.dart';

void _noop() {}

/// Chip (direction section 3): 44 high, radius 8, 1 dp hairline border, `body-s` label. Selected = ink border on paper, the
/// label in 500 and an 8 dp gold bead (a thing chosen), never a gold fill. The 500 weight is reserved by a hidden copy of the
/// label, so choosing a chip never changes the width of its label. A chip with no [onPressed], no [selected] and no [menu] is a
/// plain, non-interactive label.
class GzChip extends StatelessWidget {
  const GzChip({
    required this.label,
    this.selected,
    this.iconStart,
    this.onPressed,
    this.disabled = false,
    this.menu = false,
    this.count,
    this.previewState,
    super.key,
  });

  final String label;

  /// Chosen: ink border, bead, weight 500. Makes the chip a toggle.
  final bool? selected;
  final IconData? iconStart;
  final VoidCallback? onPressed;
  final bool disabled;

  /// Opens a sheet or menu: trailing chevron-down.
  final bool menu;

  /// Number of filters applied (a gold count badge when above zero).
  final int? count;
  final GzPreviewState? previewState;

  bool get _interactive => onPressed != null || selected != null || menu;

  @override
  Widget build(BuildContext context) {
    if (!_interactive) return _GzChipBody(chip: this, pressed: false, disabled: false);
    return GzPressable(
      onPressed: disabled ? null : (onPressed ?? _noop),
      semanticLabel: label,
      selected: selected,
      borderRadius: GzRadius.smAll,
      scale: 1,
      builder: (context, st) {
        final pressed = st.pressed || previewState == GzPreviewState.pressed;
        return gzPreview(previewState, _GzChipBody(chip: this, pressed: pressed, disabled: !st.enabled), radius: GzRadius.sm, scale: false);
      },
    );
  }
}

class _GzChipBody extends StatelessWidget {
  const _GzChipBody({required this.chip, required this.pressed, required this.disabled});

  final GzChip chip;
  final bool pressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final sel = chip.selected ?? false;
    final border = disabled ? c.borderHairline : (sel ? c.controlChipBorderSelected : c.controlChipBorder);
    final fg = disabled ? c.textDisabled : (sel ? c.textStrong : c.textPrimary);
    final bg = sel ? c.controlBg : (pressed && !disabled ? c.surfaceQuiet : null);
    final base = gzResetLabelStyle(gz); // the rendered web label type, see gzResetLabelStyle
    final heavy = gz.text(GzTextRole.title).fontWeight;
    final text = Stack(
      alignment: Alignment.center,
      children: [
        // The hidden 500 copy reserves the width of the selected label.
        Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Text(chip.label, style: base.copyWith(fontWeight: heavy), softWrap: false),
        ),
        AnimatedDefaultTextStyle(
          duration: GzMotion.durationBase,
          curve: GzMotion.easeStandard,
          style: base.copyWith(color: fg, fontWeight: sel ? heavy : base.fontWeight, decoration: TextDecoration.none),
          child: Text(chip.label, softWrap: false),
        ),
      ],
    );
    return AnimatedContainer(
      duration: GzMotion.durationBase,
      curve: GzMotion.easeStandard,
      constraints: const BoxConstraints(minHeight: GzSize.controlSm),
      // Measured against the reference renders: the web chip's border-box is about 0.5 dp tighter per side than padding + border
      // (and 1.5 dp tighter before the bead), so the padding here is the token minus that measured amount.
      padding: EdgeInsetsDirectional.only(start: sel ? GzSpace.s3 - 1.5 : GzSpace.s4 - 0.5, end: GzSpace.s4 - 0.5),
      decoration: BoxDecoration(color: bg, borderRadius: GzRadius.smAll, border: Border.all(color: border, width: GzStroke.hair)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (sel) ...[const GzBeadBox(), const SizedBox(width: GzSpace.s2)],
          if (chip.iconStart != null) ...[GzIcon(chip.iconStart!, size: GzIconSize.sm, color: fg), const SizedBox(width: GzSpace.s2)],
          text,
          if (chip.count != null && chip.count! > 0) ...[const SizedBox(width: GzSpace.s2), GzCountBadge(count: chip.count!)],
          if (chip.menu) ...[const SizedBox(width: GzSpace.s2), GzIcon(GzIcons.chevronDown, size: GzIconSize.xs, color: fg)],
        ],
      ),
    );
  }
}

/// A chip that filters: toggles on tap ([onToggle] gets the next value), or (with [menu]) opens the filter sheet and reports how
/// many filters are on.
class GzFilterChip extends StatelessWidget {
  const GzFilterChip({
    required this.label,
    required this.selected,
    required this.onToggle,
    this.iconStart,
    this.disabled = false,
    this.menu = false,
    this.count,
    this.previewState,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final IconData? iconStart;
  final bool disabled;
  final bool menu;
  final int? count;
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) => GzChip(
        label: label,
        selected: selected,
        iconStart: iconStart,
        disabled: disabled,
        menu: menu,
        count: count,
        previewState: previewState,
        onPressed: () => onToggle(!selected),
      );
}
