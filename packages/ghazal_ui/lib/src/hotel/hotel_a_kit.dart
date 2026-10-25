import 'package:flutter/widgets.dart';

import 'package:flutter/rendering.dart';

import '../foundation.dart';

/// The hairline panel of the analytics cards (paper, 1 dp ink-300, radius 12, padding 16, 16 between blocks).
class GzHotelPanel extends StatelessWidget {
  const GzHotelPanel({required this.children, this.gap = GzSpace.s4, super.key});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsets.all(GzSpace.s4),
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
        ],
      ),
    );
  }
}

/// Gives [child] a box of its own width and a fixed [height], centred on it vertically (the child may be taller: it is neither
/// clipped nor flagged as overflow). The web figure island has line-height 0 and never makes a run taller than its icon.
class GzCenteredInLine extends SingleChildRenderObjectWidget {
  const GzCenteredInLine({required this.height, required Widget super.child, super.key});

  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCenteredInLine(height);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) => (renderObject as _RenderCenteredInLine).height = height;
}

class _RenderCenteredInLine extends RenderShiftedBox {
  _RenderCenteredInLine(this._height) : super(null);

  double _height;
  set height(double v) {
    if (v == _height) return;
    _height = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(0, _height));
      return;
    }
    child.layout(BoxConstraints(maxWidth: constraints.maxWidth), parentUsesSize: true);
    size = constraints.constrain(Size(child.size.width, _height));
    (child.parentData! as BoxParentData).offset = Offset(0, (size.height - child.size.height) / 2);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    final w = child == null ? 0.0 : child.getDryLayout(BoxConstraints(maxWidth: constraints.maxWidth)).width;
    return constraints.constrain(Size(w, _height));
  }

  @override
  double computeMinIntrinsicHeight(double width) => _height;
  @override
  double computeMaxIntrinsicHeight(double width) => _height;
}
