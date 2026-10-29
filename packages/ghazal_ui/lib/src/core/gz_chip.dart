import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_badge.dart';
import 'gz_preview.dart';
import 'gz_steady_label.dart';

void _noop() {}

/// Chip (direction section 3): 44 high, radius 8, 1 dp hairline border, `body-s` label. Selected = ink border on paper, the
/// label in 500 and an 8 dp gold bead (a thing chosen), never a gold fill. The width of the 500 weight is reserved by measuring it
/// ([GzSteadyLabel]), so choosing a chip never changes its width and the label is drawn once. A chip with no [onPressed], no
/// [selected] and no [menu] is a plain, non-interactive label.
///
/// The label is [label] (a string; with [figures] its digit runs become figure islands) with an optional muted [countText] after it
/// (the web `<span class="n">12</span>` of a filter group), or any [labelWidget]. [semanticLabel] is the accessible name when it
/// differs from the words. [expand] fills the cell it is given (equal-width tiles: the label is centred and a selected chip trades
/// 4 dp of start padding for its bead and gives it back at the end, so equal tiles stay equal).
class GzChip extends StatelessWidget {
  const GzChip({
    required this.label,
    this.labelWidget,
    this.semanticLabel,
    this.figures = false,
    this.countText,
    this.selected,
    this.iconStart,
    this.iconSize = GzIconSize.sm,
    this.glyphInLabel = false,
    this.onPressed,
    this.disabled = false,
    this.menu = false,
    this.count,
    this.expand = false,
    this.previewState,
    super.key,
  });

  final String label;

  /// Replaces the drawn label (a glyph and a word, a figure). The width of the heavy weight is not reserved for it.
  final Widget? labelWidget;

  /// The accessible name when it is not the label (a glyph chip, a label widget).
  final String? semanticLabel;

  /// Digit runs of [label] become figure islands (Manrope tabular LTR, `35,000+` keeps its plus on the right in Arabic).
  final bool figures;

  /// A muted number after the label, already formatted (a figures island in the secondary tone).
  final String? countText;

  /// Chosen: ink border, bead, weight 500. Makes the chip a toggle.
  final bool? selected;
  final IconData? iconStart;

  /// `sm` for the web `iconStart` of a Chip, `xs` for the glyph inside a ChipGroup label.
  final GzIconSize iconSize;

  /// The glyph is part of the label (the web ChipGroup option `<Icon/> name`): the glyph and the words are one label, centred together
  /// in the width the heavy weight reserves. Off, the glyph is the web Chip `iconStart`, outside the label (the default).
  final bool glyphInLabel;
  final VoidCallback? onPressed;
  final bool disabled;

  /// Opens a sheet or menu: trailing chevron-down.
  final bool menu;

  /// Number of filters applied (a gold count badge when above zero).
  final int? count;

  /// Fill the cell (the web `flex: 1; justify-content: center`).
  final bool expand;
  final GzPreviewState? previewState;

  bool get _interactive => onPressed != null || selected != null || menu;

  String get _name => semanticLabel ?? (countText == null ? label : '$label $countText');

  @override
  Widget build(BuildContext context) {
    if (!_interactive) return _GzChipBody(chip: this, pressed: false, disabled: false);
    return GzPressable(
      onPressed: disabled ? null : (onPressed ?? _noop),
      semanticLabel: _name,
      selected: selected,
      expand: expand,
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

  InlineSpan _span(BuildContext context, Color secondary) {
    final words = chip.figures ? GzFigures.spans(context, chip.label, role: GzTextRole.bodyS) : <InlineSpan>[TextSpan(text: chip.label)];
    final n = chip.countText;
    if (n == null) return TextSpan(children: words);
    return TextSpan(
      children: [
        ...words,
        TextSpan(
          style: TextStyle(color: secondary),
          children: [const TextSpan(text: ' '), ...GzFigures.spans(context, n, role: GzTextRole.bodyS)],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final sel = chip.selected ?? false;
    final border = disabled ? c.borderHairline : (sel ? c.controlChipBorderSelected : c.controlChipBorder);
    final fg = disabled ? c.textDisabled : (sel ? c.textStrong : c.textPrimary);
    final bg = sel ? c.controlBg : (pressed && !disabled ? c.surfaceQuiet : null);
    final base = gzResetLabelStyle(gz).copyWith(color: fg); // the rendered web label type, see gzResetLabelStyle
    final inLabel = chip.glyphInLabel && chip.iconStart != null && chip.labelWidget == null;
    final Widget text = chip.labelWidget == null
        ? GzSteadyLabel(
            span: _span(context, disabled ? c.textDisabled : c.textSecondary),
            style: base,
            selected: sel,
            fit: chip.expand,
            leading: inLabel ? Padding(padding: const EdgeInsetsDirectional.only(end: GzSpace.s2), child: GzIcon(chip.iconStart!, size: chip.iconSize, color: fg)) : null,
            leadingExtent: inLabel ? chip.iconSize.dp + GzSpace.s2 : 0,
          )
        : AnimatedDefaultTextStyle(
            duration: GzMotion.durationBase,
            curve: GzMotion.easeStandard,
            style: base.copyWith(fontWeight: sel ? gz.text(GzTextRole.title).fontWeight : base.fontWeight, decoration: TextDecoration.none),
            child: chip.labelWidget!,
          );
    return AnimatedContainer(
      duration: GzMotion.durationBase,
      curve: GzMotion.easeStandard,
      width: chip.expand ? double.infinity : null,
      constraints: const BoxConstraints(minHeight: GzSize.controlSm),
      // The web padding exactly (computed in Chrome: 16 + 1 hairline per side, 12 before the bead); the border adds its width to it.
      padding: EdgeInsetsDirectional.only(start: sel ? GzSpace.s3 : GzSpace.s4, end: sel && chip.expand ? GzSpace.s5 : GzSpace.s4),
      decoration: BoxDecoration(color: bg, borderRadius: GzRadius.smAll, border: Border.all(color: border, width: GzStroke.hair)),
      child: Row(
        mainAxisSize: chip.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (sel) ...[const GzBeadBox(), const SizedBox(width: GzSpace.s2)],
          if (chip.iconStart != null && !inLabel) ...[GzIcon(chip.iconStart!, size: chip.iconSize, color: fg), const SizedBox(width: GzSpace.s2)],
          chip.expand ? Flexible(child: text) : text,
          if (chip.count != null && chip.count! > 0) ...[const SizedBox(width: GzSpace.s2), GzCountBadge(count: chip.count!)],
          if (chip.menu) ...[const SizedBox(width: GzSpace.s2), GzIcon(GzIcons.chevronDown, size: GzIconSize.xs, color: fg)],
        ],
      ),
    );
  }
}

/// A chip that filters: toggles on tap ([onToggle] gets the next value), or (with [menu]) opens the filter sheet and reports how
/// many filters are on. Takes the options of [GzChip] (label widget, figures, muted count, semantic label, expand).
class GzFilterChip extends StatelessWidget {
  const GzFilterChip({
    required this.label,
    required this.selected,
    required this.onToggle,
    this.labelWidget,
    this.semanticLabel,
    this.figures = false,
    this.countText,
    this.iconStart,
    this.iconSize = GzIconSize.sm,
    this.disabled = false,
    this.menu = false,
    this.count,
    this.expand = false,
    this.previewState,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final Widget? labelWidget;
  final String? semanticLabel;
  final bool figures;
  final String? countText;
  final IconData? iconStart;
  final GzIconSize iconSize;
  final bool disabled;
  final bool menu;
  final int? count;
  final bool expand;
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) => GzChip(
    label: label,
    labelWidget: labelWidget,
    semanticLabel: semanticLabel,
    figures: figures,
    countText: countText,
    selected: selected,
    iconStart: iconStart,
    iconSize: iconSize,
    disabled: disabled,
    menu: menu,
    count: count,
    expand: expand,
    previewState: previewState,
    onPressed: () => onToggle(!selected),
  );
}
