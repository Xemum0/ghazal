import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../theme/gz_theme.dart';
import '../tokens/generated/gz_dimensions.g.dart';
import '../tokens/generated/gz_motion.g.dart';
import 'gz_haptics.dart';
import 'gz_reduced_motion.dart';

/// What a [GzPressable] builder can react to.
@immutable
class GzPressState {
  const GzPressState({required this.pressed, required this.focused, required this.enabled});

  final bool pressed;

  /// Keyboard or accessibility focus (the ring is drawn by the pressable itself).
  final bool focused;
  final bool enabled;
}

typedef GzPressableBuilder = Widget Function(BuildContext context, GzPressState state);

/// The one press behaviour of the product (plan section 7, direction press feedback): scale 0.985 and a tone step in 120 ms on
/// the standard curve, a haptic hook, a 44 x 44 minimum target, a 2 dp focus ring offset 2 dp outside, a disabled state when
/// [onPressed] is null, and Semantics as a button. Every button, chip, row and card of ghazal_ui is built on it.
///
/// Give a [child] (and optionally [color] / [pressedColor] for the tone step) or a [builder] when the content itself changes
/// with the state. Reduced motion removes the scale and keeps the 120 ms tone fade.
class GzPressable extends StatefulWidget {
  const GzPressable({
    this.child,
    this.builder,
    this.onPressed,
    this.onLongPress,
    this.semanticLabel,
    this.color,
    this.pressedColor,
    this.disabledColor,
    this.borderRadius,
    this.scale = GzMotion.scalePress,
    this.minWidth = GzSize.touchMin,
    this.minHeight = GzSize.touchMin,
    this.haptic = GzHapticKind.light,
    this.onDark = false,
    this.focusNode,
    this.autofocus = false,
    this.selected,
    this.expanded,
    this.link = false,
    this.expand = false,
    super.key,
  }) : assert(child != null || builder != null, 'GzPressable needs a child or a builder');

  final Widget? child;
  final GzPressableBuilder? builder;

  /// Null disables the control (no gestures, no feedback, Semantics `enabled: false`).
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Accessible name. When given it replaces the semantics of the content; otherwise the content's text is the label.
  final String? semanticLabel;

  /// Resting fill, the fill while pressed (the tone step) and the fill when disabled. Null means no fill.
  final Color? color;
  final Color? pressedColor;
  final Color? disabledColor;
  final BorderRadiusGeometry? borderRadius;

  /// Scale while pressed (token 0.985).
  final double scale;

  /// Minimum target size (never below the 44 dp touch token).
  final double minWidth;
  final double minHeight;
  final GzHapticKind haptic;

  /// Focus ring in the on-dark colour (for controls on the ink surface).
  final bool onDark;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Semantics `selected` for tabs, chips and segments.
  final bool? selected;

  /// Semantics `expanded` for a control that opens and closes something (a menu chip, an accordion head); null = not applicable.
  final bool? expanded;

  /// The control opens an address outside the app (a store page, a web page): announced as a link, not as a button.
  final bool link;

  /// Fill the width the parent gives instead of shrink-wrapping the child (equal-width tiles, a chip that fills its cell). In an
  /// unbounded width it still wraps.
  final bool expand;

  bool get enabled => onPressed != null;

  @override
  State<GzPressable> createState() => _GzPressableState();
}

class _GzPressableState extends State<GzPressable> {
  bool _pressed = false;
  bool _focused = false;
  bool _keyboardMode = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    final keyboard = mode == FocusHighlightMode.traditional;
    if (_keyboardMode != keyboard && mounted) setState(() => _keyboardMode = keyboard);
  }

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  void _activate() {
    if (!widget.enabled) return;
    GzHaptics.fire(widget.haptic);
    widget.onPressed!();
  }

  @override
  void didUpdateWidget(GzPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final enabled = widget.enabled;
    final reduced = GzReducedMotion.of(context);
    final state = GzPressState(pressed: _pressed && enabled, focused: _focused && enabled, enabled: enabled);
    final fill = !enabled
        ? (widget.disabledColor ?? widget.color)
        : (state.pressed ? (widget.pressedColor ?? widget.color) : widget.color);
    final content = widget.builder != null ? widget.builder!(context, state) : widget.child!;

    Widget body = AnimatedContainer(
      duration: GzMotion.durationFast,
      curve: GzMotion.easeStandard,
      decoration: BoxDecoration(color: fill, borderRadius: widget.borderRadius),
      child: content,
    );
    body = AnimatedScale(
      scale: state.pressed && !reduced ? widget.scale : 1,
      duration: GzReducedMotion.movement(context, GzMotion.durationFast),
      curve: GzMotion.easeStandard,
      child: body,
    );
    body = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.minWidth < GzSize.touchMin ? GzSize.touchMin : widget.minWidth,
        minHeight: widget.minHeight < GzSize.touchMin ? GzSize.touchMin : widget.minHeight,
      ),
      child: Center(widthFactor: widget.expand ? null : 1, heightFactor: 1, child: body),
    );

    // Focus ring: 2 dp stroke, 2 dp outside the box (direction: focus-visible), only when focused.
    const out = GzStroke.focus + GzStroke.focusOffset;
    final ring = state.focused
        ? PositionedDirectional(
            start: -out,
            end: -out,
            top: -out,
            bottom: -out,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: widget.onDark ? gz.colors.textOnDark : gz.colors.focusRing, width: GzStroke.focus),
                  borderRadius: widget.borderRadius == null ? null : _outset(widget.borderRadius!, Directionality.of(context), out),
                ),
              ),
            ),
          )
        : null;
    if (ring != null) body = Stack(clipBehavior: Clip.none, children: [body, ring]);

    body = FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onFocusChange: (v) {
        if (_focused != v && mounted) setState(() => _focused = v);
      },
      shortcuts: _activateKeys,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          _activate();
          return null;
        }),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled ? _activate : null,
        onLongPress: enabled && widget.onLongPress != null
            ? () {
                _set(false);
                widget.onLongPress!();
              }
            : null,
        child: body,
      ),
    );

    return Semantics(
      container: true,
      button: !widget.link,
      link: widget.link ? true : null,
      enabled: enabled,
      selected: widget.selected,
      expanded: widget.expanded,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      onTap: enabled ? _activate : null,
      child: body,
    );
  }

  static final Map<ShortcutActivator, Intent> _activateKeys = <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.numpadEnter): const ActivateIntent(),
    const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
  };

  /// Outer ring radius for a uniform corner radius (all Ghazal radii are uniform): the radius plus the ring offset.
  static BorderRadius _outset(BorderRadiusGeometry r, TextDirection dir, double by) {
    final corner = r.resolve(dir).topLeft; // uniform radii: any corner will do
    return BorderRadius.all(Radius.circular(corner.x + by));
  }
}
