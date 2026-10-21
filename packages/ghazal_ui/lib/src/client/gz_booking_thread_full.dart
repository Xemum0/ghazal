import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';

import '../brand/gz_thread_knot.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'gz_booking_thread_model.dart';
import 'gz_booking_thread_parts.dart';

/// The full thread: a glyph over each 20 dp knot on one gold thread, one word under the active knot (or every knot, or none), a
/// hairline and the deadline note under it. The layout of the web IconProgress; kept here (not in core) because core's
/// [GzIconProgress] sizes its label with an unbounded `OverflowBox`, which throws inside a scroll view (see requests.md).
class GzThreadFull extends StatelessWidget {
  const GzThreadFull({
    required this.model,
    required this.labelOf,
    required this.semantics,
    required this.labels,
    required this.note,
    required this.noteTone,
    required this.onDark,
    required this.draw,
    required this.pop,
    super.key,
  });

  final List<GzThreadKnotModel> model;
  final String Function(GzThreadKnotModel) labelOf;
  final String semantics;
  final GzProgressLabels labels;
  final GzThreadSub? note;
  final GzThreadTone noteTone;
  final bool onDark;
  final GzDraw draw;
  final GzThreadKey? pop;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final animate = draw != GzDraw.off;
    final titleWeight = gz.text(GzTextRole.title).fontWeight;
    final cols = <Widget>[];
    for (var i = 0; i < model.length; i++) {
      final k = model[i];
      final last = i == model.length - 1;
      final active = k.state == GzKnotState.now || k.state == GzKnotState.ended;
      final shown =
          labels == GzProgressLabels.all ||
          (labels == GzProgressLabels.active && active);
      final Color iconColor = switch (k.state) {
        GzKnotState.now => onDark ? c.textOnDarkGold : c.iconAccent,
        _ when onDark => c.iconOnDark,
        GzKnotState.open => c.iconDisabled,
        GzKnotState.tied => c.iconPrimary,
        GzKnotState.ended =>
          k.endedTone == GzKnotEndedTone.danger ||
                  k.endedTone == GzKnotEndedTone.dangerOutline
              ? c.iconDanger
              : c.iconSecondary,
      };
      final labelColor = k.state == GzKnotState.ended
          ? (onDark ? c.textOnDarkMuted : c.textSecondary)
          : (onDark ? c.textOnDark : c.textStrong);
      cols.add(
        Expanded(
          child: Semantics(
            label: labelOf(k),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: GzSize.iconLg,
                  height: GzSize.iconMd,
                  child: Center(
                    child: GzIcon(
                      gzThreadIcon(k.key),
                      size: GzIconSize.md,
                      color: iconColor,
                    ),
                  ),
                ),
                const SizedBox(height: GzSpace.s1),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: GzSpace.s1),
                  child: Row(
                    children: [
                      GzThreadKnot(
                        state: k.state,
                        onDark: onDark,
                        endedIcon: k.endedIcon,
                        endedTone: k.endedTone ?? GzKnotEndedTone.danger,
                        pop: pop == k.key,
                      ),
                      if (!last) ...[
                        const SizedBox(width: GzSpace.s1),
                        Expanded(
                          child: SizedBox(
                            height: GzStroke.thread,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: onDark
                                        ? c.markTrackOnDark
                                        : c.markTrack,
                                  ),
                                ),
                                if (model[i + 1].state != GzKnotState.open)
                                  Positioned.fill(
                                    child: GzDrawOnce(
                                      enabled: animate,
                                      delay: GzMotion.durationFast * i,
                                      child: ColoredBox(color: c.markKhayt),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (shown) ...[
                  const SizedBox(height: GzSpace.s1),
                  SizedBox(
                    width: GzSize.iconLg,
                    child: OverflowBox(
                      fit: OverflowBoxFit.deferToChild,
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: Text(
                        labelOf(k),
                        softWrap: false,
                        style: gz
                            .text(GzTextRole.caption)
                            .copyWith(
                              color: labelColor,
                              fontWeight: titleWeight,
                              decoration: TextDecoration.none,
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      label: semantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols),
          if (note != null) ...[
            const SizedBox(height: GzSpace.s3),
            Container(
              padding: const EdgeInsets.only(top: GzSpace.s2),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: onDark ? c.borderOnDark : c.borderHairline,
                    width: GzStroke.hair,
                  ),
                ),
              ),
              child: GzThreadNote(sub: note!, onDark: onDark),
            ),
          ],
        ],
      ),
    );
  }
}
