import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// A full-bleed photograph whose top edge is the named arch crown (direction rule 3: onboarding and splash hero only; rise 64, gold line
/// along the crown). The crown is one painter in the canvas colour (the two corners outside the arch) plus the khayt line. The path is read
/// from the token (`GzShape.archPath`) and split into its control points, never retyped.
class ObdArchHero extends StatelessWidget {
  const ObdArchHero({required this.src, required this.alt, required this.height, super.key});

  final String src;
  final String alt;

  /// Total height in dp, crown included.
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.surfacePlaceholder, child: GzPhoto(src: src, alt: alt, priority: true)),
            PositionedDirectional(
              start: 0,
              end: 0,
              top: 0,
              height: GzShape.archRise,
              child: IgnorePointer(
                child: ExcludeSemantics(child: CustomPaint(painter: _CrownPainter(fill: c.surfaceCanvas, line: c.markKhayt))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  _CrownPainter({required this.fill, required this.line});

  final Color fill;
  final Color line;

  /// `M0 100 C0 46 28 36 50 0 C72 36 100 46 100 100 Z`: p0, c1, c2, apex, c3, c4, p1 on a 0..100 square.
  static final List<double> _n = RegExp(r'-?\d+(?:\.\d+)?').allMatches(GzShape.archPath).map((m) => double.parse(m.group(0)!)).toList();

  @override
  void paint(Canvas canvas, Size size) {
    final n = _n;
    Offset p(int i) => Offset(n[i] / 100 * size.width, n[i + 1] / 100 * size.height);
    final crown = Path()
      ..moveTo(p(0).dx, p(0).dy)
      ..cubicTo(p(2).dx, p(2).dy, p(4).dx, p(4).dy, p(6).dx, p(6).dy)
      ..cubicTo(p(8).dx, p(8).dy, p(10).dx, p(10).dy, p(12).dx, p(12).dy);
    final outside = Path()
      ..moveTo(p(0).dx, 0)
      ..lineTo(p(12).dx, 0)
      ..lineTo(p(12).dx, p(12).dy)
      ..cubicTo(p(10).dx, p(10).dy, p(8).dx, p(8).dy, p(6).dx, p(6).dy)
      ..cubicTo(p(4).dx, p(4).dy, p(2).dx, p(2).dy, p(0).dx, p(0).dy)
      ..close();
    canvas.drawPath(outside, Paint()..color = fill);
    canvas.drawPath(
      crown,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = GzStroke.khayt,
    );
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.fill != fill || old.line != line;
}
