import 'package:flutter/widgets.dart';

import '../core/gz_format_scope.dart';
import '../foundation.dart';

/// ChecklistProgress: "2 of 9 done" and a 4 dp gold line as long as the share done (a state, direction 2.3 e). One image node for
/// assistive technology; the percentage is an LTR island. Takes counts only: the screen decides what is done.
class GzChecklistProgress extends StatelessWidget {
  const GzChecklistProgress({required this.done, required this.total, super.key});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final c = context.gz.colors;
    final share = total == 0 ? 0 : (done / total * 1000).round();
    final words = l.uiClientChecklistDone(f.integer(done), f.integer(total));
    final pct = f.percent(total == 0 ? 0 : done / total * 100, maxFraction: 0);
    return Semantics(
      label: '${l.uiClientChecklistProgress}: ${f.plain(words)}',
      image: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The web head is one line high plus 1: the figure's line box rides the baseline 1 dp lower than the label's (measured 25 / 27).
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: (context.gz.text(GzTextRole.bodyS).fontSize ?? 15) * (context.gz.text(GzTextRole.bodyS).height ?? 1.6) + 1),
            child: Row(
              textBaseline: TextBaseline.alphabetic,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Expanded(
                  child: GzText(words, role: GzTextRole.bodyS, color: c.textPrimary, figures: true),
                ),
                const SizedBox(width: GzSpace.s3),
                GzNum(pct, role: GzTextRole.bodyS, color: c.textStrong),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s2),
          SizedBox(
            height: GzStroke.threadMax,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (share > 0)
                  Expanded(
                    flex: share,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: c.markKhayt, borderRadius: GzRadius.pillAll),
                    ),
                  ),
                if (share < 1000)
                  Expanded(
                    flex: 1000 - share,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: c.markTrack, borderRadius: GzRadius.pillAll),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
