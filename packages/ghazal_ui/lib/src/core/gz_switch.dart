import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_preview.dart';

/// Switch (direction section 3, "Toggle"): 52 x 32 track inside a 44 high target. Off = paper with an ink-500 ring; on = ink-700
/// with the canvas knob and an ink-900 check. Never gold. On = knob toward inline-end, so it mirrors with the language (ADR 0014).
/// Controlled with [checked] + [onChanged], or uncontrolled from [defaultChecked].
class GzSwitch extends StatefulWidget {
  const GzSwitch({
    required this.label,
    this.checked,
    this.defaultChecked = false,
    this.onChanged,
    this.disabled = false,
    this.previewState,
    super.key,
  });

  /// The accessible name (the row's visible title, or what the switch does).
  final String label;
  final bool? checked;
  final bool defaultChecked;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  /// Gallery only.
  final GzPreviewState? previewState;

  @override
  State<GzSwitch> createState() => _GzSwitchState();
}

class _GzSwitchState extends State<GzSwitch> {
  late bool _internal = widget.defaultChecked;

  bool get _on => widget.checked ?? _internal;

  void _toggle() {
    final next = !_on;
    if (widget.checked == null) setState(() => _internal = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final on = _on;
    final enabled = !widget.disabled;
    return Semantics(
      container: true,
      toggled: on,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? _toggle : null,
      excludeSemantics: true,
      child: GzPressable(
        onPressed: enabled ? _toggle : null,
        borderRadius: GzRadius.pillAll,
        scale: 1,
        minWidth: GzSize.toggleWidth,
        builder: (context, st) {
          final pressed = st.pressed || widget.previewState == GzPreviewState.pressed;
          final Color border;
          final Color fill;
          if (!enabled) {
            border = on ? c.iconDisabled : c.borderHairline;
            fill = on ? c.iconDisabled : c.controlTrack;
          } else if (on) {
            border = pressed ? c.actionSelectedBgPressed : c.controlToggleOn;
            fill = border;
          } else {
            border = c.borderControl;
            fill = pressed ? c.surfaceQuiet : c.controlBg;
          }
          final ring = on ? null : [BoxShadow(color: enabled ? c.borderControl : c.borderStrong, spreadRadius: GzStroke.hair)];
          final knobColor = !enabled && on ? c.iconDisabled : c.controlToggleCheck;
          final track = AnimatedContainer(
            duration: GzMotion.durationBase,
            curve: GzMotion.easeStandard,
            width: GzSize.toggleWidth,
            height: GzSize.toggleHeight,
            decoration: BoxDecoration(color: fill, borderRadius: GzRadius.pillAll, border: Border.all(color: border, width: GzStroke.hair)),
            child: Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: GzReducedMotion.movement(context, GzMotion.durationBase),
                  curve: GzMotion.easeStandard,
                  start: GzSpace.s1 + (on ? GzSize.toggleTravel : 0),
                  top: (GzSize.toggleHeight - 2 * GzStroke.hair - GzSize.toggleKnob) / 2,
                  child: AnimatedContainer(
                    key: const ValueKey('gz:switch.knob'),
                    duration: GzMotion.durationBase,
                    curve: GzMotion.easeStandard,
                    width: GzSize.toggleKnob,
                    height: GzSize.toggleKnob,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.controlToggleKnob, boxShadow: ring),
                    child: on ? GzIcon(GzIcons.check, size: GzIconSize.xs, color: knobColor) : null,
                  ),
                ),
              ],
            ),
          );
          final body = SizedBox(width: GzSize.toggleWidth, height: GzSize.touchMin, child: Center(child: track));
          return gzPreview(widget.previewState, body, radius: GzSize.touchMin / 2, scale: false);
        },
      ),
    );
  }
}
