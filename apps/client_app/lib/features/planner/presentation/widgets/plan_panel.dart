import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The planner flow's panel (web `.gzp-panel`): raised, strong hairline, 16 inside the border. A `Container` with a decoration, so the
/// border insets its child (a `DecoratedBox` border does not: the card came out 2 dp short).
class PlanPanel extends StatelessWidget {
  const PlanPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsets.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: child,
    );
  }
}
