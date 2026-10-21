import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// The hint that range selection has two doors (web `DragAffordance`, ADR 0008 D9, ADR 0014 D4): press and hold a day, then drag across
/// the dates; or tap a start day and an end day (the accessible path). A tiny diagram says it without words: two gold cells joined by
/// the gold thread, and an arrow that points the way the week runs (it mirrors in Arabic with the registry arrow). Static, nothing loops.
class GzDragAffordance extends StatelessWidget {
  const GzDragAffordance({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    Widget cell() => DecoratedBox(
      decoration: BoxDecoration(
        color: c.markKhayt,
        borderRadius: GzRadius.xsAll,
        border: Border.all(color: c.markKhayt, width: GzStroke.hair),
      ),
      child: const SizedBox.square(dimension: GzSpace.s5),
    );
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.smAll),
      child: Padding(
        padding: const EdgeInsets.all(GzSpace.s3),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  cell(),
                  const SizedBox(width: GzSpace.s1),
                  SizedBox(
                    width: GzSpace.s4,
                    height: GzStroke.thread,
                    child: ColoredBox(color: c.markKhayt),
                  ),
                  const SizedBox(width: GzSpace.s1),
                  cell(),
                  const SizedBox(width: GzSpace.s1),
                  const GzIcon(GzIcons.arrowRight, size: GzIconSize.xs, tone: GzIconTone.secondary),
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: GzText(context.gzL10n.uiHotelCalDragHint, role: GzTextRole.caption, color: c.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
