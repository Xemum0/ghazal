import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A row whose first item is a glyph has no text baseline: CSS takes the glyph's bottom edge (a 16 px star in a baseline-aligned
/// head row sits with its bottom on the name's baseline). Reports the same baseline for a vertically centred glyph of [glyphSize].
class GzGlyphBaseline extends SingleChildRenderObjectWidget {
  const GzGlyphBaseline({
    required this.glyphSize,
    required super.child,
    super.key,
  });

  final double glyphSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGlyphBaseline(glyphSize);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderGlyphBaseline).glyphSize = glyphSize;
  }
}

class _RenderGlyphBaseline extends RenderProxyBox {
  _RenderGlyphBaseline(this._glyphSize);

  double _glyphSize;

  set glyphSize(double v) {
    if (v == _glyphSize) return;
    _glyphSize = v;
    markNeedsLayout();
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      (size.height + _glyphSize) / 2;

  @override
  double? computeDryBaseline(BoxConstraints constraints, TextBaseline baseline) =>
      (getDryLayout(constraints).height + _glyphSize) / 2;
}
