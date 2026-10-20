import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// Gallery and test only: show the pressed or the keyboard-focus look without a pointer or a keyboard (the web `previewState`).
/// Product screens never pass it; `GzPressable` does the real states.
enum GzPreviewState { pressed, focus }

/// The 2 dp focus ring 2 dp outside the child (the same geometry as `GzPressable`'s own ring).
class GzFocusOutline extends StatelessWidget {
  const GzFocusOutline({required this.child, this.show = true, this.radius = 0, this.onDark = false, super.key});

  final Widget child;
  final bool show;

  /// Corner radius of the child; the ring adds its offset.
  final double radius;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    const out = GzStroke.focus + GzStroke.focusOffset;
    final colors = context.gz.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          start: -out,
          end: -out,
          top: -out,
          bottom: -out,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: onDark ? colors.textOnDark : colors.focusRing, width: GzStroke.focus),
                borderRadius: BorderRadius.circular(radius + out),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Applies a [GzPreviewState] to a visible box: the 0.985 press scale or the focus ring.
Widget gzPreview(GzPreviewState? state, Widget child, {double radius = 0, bool onDark = false, bool scale = true}) {
  switch (state) {
    case GzPreviewState.pressed:
      return scale ? Transform.scale(scale: GzMotion.scalePress, child: child) : child;
    case GzPreviewState.focus:
      return GzFocusOutline(radius: radius, onDark: onDark, child: child);
    case null:
      return child;
  }
}

/// The 8 dp gold diamond (`.gz-bead`): a rotated square. Boxed to 12 by [GzBeadBox] so it never clips or crowds the text beside it.
class GzBead extends StatelessWidget {
  const GzBead({this.color, this.hollow = false, super.key});

  /// Defaults to the khayt gold.
  final Color? color;

  /// A bordered diamond (borders, never inset shadows): the "not yet" bead.
  final bool hollow;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Transform.rotate(
      angle: 0.7853981633974483,
      child: SizedBox.square(
        dimension: GzSize.knotBead,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: hollow ? c.surfaceCanvas : (color ?? c.markKhayt),
            border: hollow ? Border.all(color: c.markOpen, width: GzStroke.icon) : null,
          ),
        ),
      ),
    );
  }
}

/// A [GzBead] in its 12 x 12 box.
class GzBeadBox extends StatelessWidget {
  const GzBeadBox({this.color, this.hollow = false, super.key});

  final Color? color;
  final bool hollow;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: GzSpace.s3, child: Center(child: GzBead(color: color, hollow: hollow)));
}

/// The label type of a web `<button class="gz-reset gz-t-...">`. The prototype's `.gz-reset { font: inherit }` is declared after the
/// type role classes, so on those buttons it wins and the label renders in the inherited page type (the `body` role: 16/24
/// regular in English) instead of the named `button` / `body-s` role. The reference renders are the specification, so Button, Chip and
/// the toast action take this style. If the prototype CSS is fixed, change this one function.
TextStyle gzResetLabelStyle(GzThemeData gz) => gz.text(GzTextRole.body);
