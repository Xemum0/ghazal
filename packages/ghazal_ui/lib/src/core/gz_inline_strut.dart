import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_chrome_baseline.dart';

/// A web block that holds one inline-level child (an inline-flex price, a rating, a chip): the block's line box also contains the
/// STRUT of its own text role, so a child that sits on its own baseline is taller than itself by the part of the strut that
/// sticks out above or below it. `.gz-best__value` around a 24 dp price in a 15/24 cell is 25 dp high, around a rating (baseline at
/// its star's bottom) 27 dp, around plain text 24 dp.
///
/// Lays the child out, then makes the box `max(child ascent, strut ascent) + max(child descent, strut descent)` high and puts the
/// child on the shared baseline. The box reports that baseline (the web inline-block baseline). A child without a baseline sits on
/// its bottom edge. The strut is the browser's: [role]'s line height with its whole-pixel baseline ([GzChromeBaseline]).
class GzInlineStrut extends StatelessWidget {
  const GzInlineStrut({required this.child, this.role = GzTextRole.bodyS, super.key});

  final Widget child;

  /// The text role of the block (the cell's own type).
  final GzTextRole role;

  @override
  Widget build(BuildContext context) {
    final style = context.gz.text(role);
    final line = (style.height ?? 1) * (style.fontSize ?? 16);
    final base = GzChromeBaseline.baselineOf(style, Directionality.of(context));
    return _InlineStrut(strutAscent: base, strutDescent: line - base, child: child);
  }
}

class _InlineStrut extends SingleChildRenderObjectWidget {
  const _InlineStrut({required this.strutAscent, required this.strutDescent, required super.child});

  final double strutAscent;
  final double strutDescent;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderInlineStrut(strutAscent, strutDescent);

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _RenderInlineStrut)
      ..strutAscent = strutAscent
      ..strutDescent = strutDescent;
  }
}

class _RenderInlineStrut extends RenderShiftedBox {
  _RenderInlineStrut(this._strutAscent, this._strutDescent) : super(null);

  double _strutAscent;
  double _strutDescent;
  double _baseline = 0;

  set strutAscent(double v) {
    if (v == _strutAscent) return;
    _strutAscent = v;
    markNeedsLayout();
  }

  set strutDescent(double v) {
    if (v == _strutDescent) return;
    _strutDescent = v;
    markNeedsLayout();
  }

  ({double ascent, double descent, Size childSize})? _measure(RenderBox c, BoxConstraints constraints, {required bool dry}) {
    final Size cs = dry ? c.getDryLayout(constraints) : c.size;
    final double b = (dry ? c.getDryBaseline(constraints, TextBaseline.alphabetic) : c.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true)) ?? cs.height;
    final ascent = b > _strutAscent ? b : _strutAscent;
    final below = cs.height - b;
    final descent = below > _strutDescent ? below : _strutDescent;
    return (ascent: ascent, descent: descent, childSize: cs);
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints, parentUsesSize: true);
    final m = _measure(c, constraints, dry: false)!;
    final b = c.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true) ?? c.size.height;
    _baseline = m.ascent;
    size = constraints.constrain(Size(c.size.width, m.ascent + m.descent));
    (c.parentData! as BoxParentData).offset = Offset(0, m.ascent - b);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => _baseline;

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) {
    final c = child;
    return c == null ? null : _measure(c, constraints, dry: true)!.ascent;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.smallest;
    final m = _measure(c, constraints, dry: true)!;
    return constraints.constrain(Size(m.childSize.width, m.ascent + m.descent));
  }

  @override
  double computeMinIntrinsicHeight(double width) => computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) => computeDryLayout(BoxConstraints(maxWidth: width)).height;
}
