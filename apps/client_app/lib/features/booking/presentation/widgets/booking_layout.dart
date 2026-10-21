import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// A column with a fixed gap (the web `display: flex; flex-direction: column; gap`).
class BookingGap extends StatelessWidget {
  const BookingGap({required this.children, this.gap = GzSpace.s4, this.cross = CrossAxisAlignment.stretch, super.key});

  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment cross;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(SizedBox(height: gap));
      items.add(children[i]);
    }
    return Column(crossAxisAlignment: cross, mainAxisSize: MainAxisSize.min, children: items);
  }
}

/// A section of a step (web `.bk-section`): the screen gutter, a column gap of 16 (12 when [tight]) and 24 below.
class StepSection extends StatelessWidget {
  const StepSection({required this.children, this.tight = false, this.gap, this.bottom = GzSpace.s6, this.label, super.key});

  final List<Widget> children;
  final bool tight;
  final double? gap;
  final double bottom;
  final String? label;

  @override
  Widget build(BuildContext context) {
    Widget body = Padding(
      padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: bottom),
      child: BookingGap(gap: gap ?? (tight ? GzSpace.s3 : GzSpace.s4), children: children),
    );
    if (label != null) body = Semantics(container: true, label: label, child: body);
    return body;
  }
}

/// Moves a 44 dp control toward the inline end by its slack so its glyph meets the 20 dp gutter (the web `inset-inline-end: -10px`).
class EndBleed extends StatelessWidget {
  const EndBleed({required this.child, this.by = 10, super.key});

  final Widget child;
  final double by;

  @override
  Widget build(BuildContext context) => Transform.translate(offset: Offset(context.gz.isRtl ? -by : by, 0), child: child);
}

/// The same toward the inline start (a tertiary button's padding).
class StartBleed extends StatelessWidget {
  const StartBleed({required this.child, this.by = 8, super.key});

  final Widget child;
  final double by;

  @override
  Widget build(BuildContext context) => Transform.translate(offset: Offset(context.gz.isRtl ? by : -by, 0), child: child);
}

/// A hairline-ruled block (a border above and below, no panel).
class BookingRuled extends StatelessWidget {
  const BookingRuled({required this.child, this.color, super.key});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final line = BorderSide(color: color ?? context.gz.colors.borderStrong, width: GzStroke.hair);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: line, bottom: line),
      ),
      child: child,
    );
  }
}
