// Layout kit of the client-domain gallery page (the web `design/src/system/domain-client/gallery/kit.tsx` + gallery.css): Section, Spec,
// full-bleed specimens and the pill buttons. Harness only: ghazal_testing may hold string literals.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

String gcT(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

/// `Section`: khayt, d2 title, note (gap 8), then the specimens (gap 32) after a gap of 20.
Widget gcSection(BuildContext context, {required String title, required String note, required List<Widget> specs}) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: GzThreadRule(draw: GzDraw.off),
      ),
      const SizedBox(height: GzSpace.s2),
      GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true),
      const SizedBox(height: GzSpace.s2),
      GzText(note, role: GzTextRole.bodyS, color: c.textSecondary),
      const SizedBox(height: GzSpace.s5),
      for (var i = 0; i < specs.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s8), specs[i]],
    ],
  );
}

/// `Spec`: a state caption over a hairline (gap 12), then the live component(s) with a gap of 24. [bleed] gives the body the whole
/// 390 frame (the page's 20 of gutter on each side is taken back).
Widget gcSpec(BuildContext context, String state, List<Widget> children, {bool bleed = false}) {
  final gz = context.gz;
  final c = gz.colors;
  final body = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]],
    ],
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Text(
          state,
          style: gz
              .text(GzTextRole.caption)
              .copyWith(color: c.textSecondary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
        ),
      ),
      const SizedBox(height: GzSpace.s3),
      bleed ? GcBleed(child: body) : body,
    ],
  );
}

/// A child laid out [GzSpace.gutter] wider than the column on each side (`margin-inline: -20`); the box keeps the column width.
class GcBleed extends SingleChildRenderObjectWidget {
  const GcBleed({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBleed();
}

class _RenderBleed extends RenderProxyBox {
  @override
  void performLayout() {
    final w = constraints.maxWidth + GzSpace.gutter * 2;
    child!.layout(BoxConstraints.tightFor(width: w), parentUsesSize: true);
    size = Size(constraints.maxWidth, child!.size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) => context.paintChild(child!, offset - const Offset(GzSpace.gutter, 0));

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      child!.hitTest(result, position: position + const Offset(GzSpace.gutter, 0));

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.translateByDouble(-GzSpace.gutter, 0, 0, 1);
}

/// `gc-pill`: a 44 high outlined button of the harness (the add buttons of the tray demo).
class GcPill extends StatelessWidget {
  const GcPill({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final off = onPressed == null;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: GzRadius.smAll,
      builder: (context, st) => SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: GzRadius.smAll,
            border: Border.all(color: c.controlChipBorder, width: GzStroke.hair),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Center(
              child: Text(
                label,
                softWrap: false,
                style: gzResetLabelStyle(gz).copyWith(color: off ? c.textDisabled : c.textPrimary, decoration: TextDecoration.none),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
