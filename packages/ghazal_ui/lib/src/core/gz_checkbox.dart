import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_preview.dart';

/// Checkbox: a 24 box (radius 4) in a row that is at least 44 high and whole-row tappable. Checked = ink-700 fill with a canvas
/// check (the same ink as the Switch: choice is ink, never gold). [indeterminate] shows a minus. [error] = danger border + icon + text.
class GzCheckbox extends StatefulWidget {
  const GzCheckbox({
    required this.label,
    this.checked,
    this.defaultChecked = false,
    this.indeterminate = false,
    this.onChanged,
    this.error,
    this.disabled = false,
    this.previewState,
    super.key,
  });

  /// The visible label.
  final String label;
  final bool? checked;
  final bool defaultChecked;
  final bool indeterminate;
  final ValueChanged<bool>? onChanged;

  /// Validation message: shown under the row with an icon, and the box turns danger.
  final String? error;
  final bool disabled;
  final GzPreviewState? previewState;

  @override
  State<GzCheckbox> createState() => _GzCheckboxState();
}

class _GzCheckboxState extends State<GzCheckbox> {
  late bool _internal = widget.defaultChecked;

  bool get _on => widget.checked ?? _internal;

  void _toggle() {
    final next = widget.indeterminate ? true : !_on;
    if (widget.checked == null) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final enabled = !widget.disabled;
    final on = _on || widget.indeterminate;
    final row = Semantics(
      container: true,
      checked: widget.indeterminate ? null : _on,
      mixed: widget.indeterminate,
      enabled: enabled,
      label: widget.label,
      hint: widget.error,
      onTap: enabled ? _toggle : null,
      excludeSemantics: true,
      child: GzPressable(
        onPressed: enabled ? _toggle : null,
        borderRadius: GzRadius.smAll,
        scale: 1,
        builder: (context, st) {
          final pressed = st.pressed || widget.previewState == GzPreviewState.pressed;
          Color border = c.borderControl;
          Color fill = pressed ? c.surfaceQuiet : c.controlBg;
          if (!enabled) {
            border = on ? c.iconDisabled : c.borderStrong;
            fill = on ? c.iconDisabled : c.controlTrack;
          } else if (on) {
            border = pressed ? c.actionSelectedBgPressed : c.controlToggleOn;
            fill = border;
          } else if (widget.error != null) {
            border = c.borderError;
          }
          final box = AnimatedContainer(
            duration: GzMotion.durationBase,
            curve: GzMotion.easeStandard,
            width: GzSize.iconMd,
            height: GzSize.iconMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: fill, borderRadius: GzRadius.xsAll, border: Border.all(color: border, width: GzStroke.icon)),
            child: widget.indeterminate
                ? GzIcon(GzIcons.minus, size: GzIconSize.xs, color: c.controlToggleKnob)
                : (_on ? GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.controlToggleKnob) : null),
          );
          final body = ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Row(
              children: [
                box,
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzText(widget.label, role: GzTextRole.bodyS, color: enabled ? c.textStrong : c.textDisabled)),
              ],
            ),
          );
          return gzPreview(widget.previewState, body, radius: GzRadius.sm, scale: false);
        },
      ),
    );
    if (widget.error == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        const SizedBox(height: GzSpace.s1),
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.s1),
            child: Row(
              children: [
                GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger),
                const SizedBox(width: GzSpace.s1),
                Expanded(child: GzText(widget.error!, role: GzTextRole.caption, color: c.textDanger)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
