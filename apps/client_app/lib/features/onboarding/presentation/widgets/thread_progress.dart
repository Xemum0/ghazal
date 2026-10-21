import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The 2 dp thread that tells the couple where they are in onboarding (web `ThreadProgress`): a gold line filled in reading direction,
/// the 8 dp bead where it ends, a hairline track after. Used for the three intro slides and the four profile steps.
class ObdThreadProgress extends StatelessWidget {
  const ObdThreadProgress({required this.count, required this.index, required this.label, super.key});

  /// Number of stops (3 slides, 4 steps).
  final int count;

  /// Zero-based current stop; the line is filled up to and including it.
  final int index;

  /// Spoken name: "Step 2 of 4".
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final done = (index + 1).clamp(0, count);
    final duration = GzReducedMotion.movement(context, GzMotion.durationSlow);
    return Semantics(
      container: true,
      label: label,
      value: '$done/$count',
      child: ExcludeSemantics(
        child: SizedBox(
          height: GzSize.knotBead,
          child: LayoutBuilder(
            builder: (context, box) {
              final track = math.max(0.0, box.maxWidth - GzSize.knotBead);
              return Row(
                children: [
                  AnimatedContainer(
                    duration: duration,
                    curve: GzMotion.easeStandard,
                    width: track * done / count,
                    height: GzStroke.thread,
                    color: c.markKhayt,
                  ),
                  Transform.rotate(
                    angle: math.pi / 4,
                    child: SizedBox(
                      width: GzSize.knotBead,
                      height: GzSize.knotBead,
                      child: ColoredBox(color: c.markKhayt),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: c.borderHairline,
                      child: const SizedBox(height: GzStroke.thread),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
