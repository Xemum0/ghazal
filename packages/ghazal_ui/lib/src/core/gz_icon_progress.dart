import 'package:flutter/widgets.dart';

import '../brand/gz_thread_knot.dart';
import '../foundation.dart';
import 'gz_draw_once.dart';

class GzIconProgressStep {
  const GzIconProgressStep({required this.id, required this.icon, required this.label, required this.state, this.endedIcon, this.endedTone = GzKnotEndedTone.danger});

  final String id;
  final IconData icon;

  /// One word. Shown only under the active step (or all steps with [GzProgressLabels.all]).
  final String label;
  final GzKnotState state;

  /// `ended` steps: the terminal glyph and tone on the knot.
  final IconData? endedIcon;
  final GzKnotEndedTone endedTone;
}

/// `active` (default): one word under the active step. `all`: every step is labelled. `none`: icons only (the accessible names remain).
enum GzProgressLabels { active, all, none }

/// The note under the thread is gold-700 while waiting, danger when ended.
enum GzProgressNoteTone { muted, now, danger }

/// IconProgress (ADR 0034): the thread with an icon per knot. Each step is a glyph above its knot on one gold thread; only the
/// active step (now, or the one that ended) carries a one-word label, every other label is read by assistive technology only.
/// A knot ties only on a recorded event (direction section 4): the caller supplies the states. The thread draws once from
/// inline-start over 480 ms ([draw]), a knot pops once on a live change ([pop]), reduced motion keeps the finished state.
class GzIconProgress extends StatelessWidget {
  const GzIconProgress({
    required this.steps,
    required this.label,
    this.describe,
    this.labels = GzProgressLabels.active,
    this.note,
    this.noteTone = GzProgressNoteTone.muted,
    this.onDark = false,
    this.draw = GzDraw.inview,
    this.pop,
    super.key,
  });

  final List<GzIconProgressStep> steps;

  /// The group's accessible name ("Booking progress").
  final String label;

  /// The sentence for assistive technology: "Request, step 2 of 5". Built by the caller from the formatter.
  final String? describe;
  final GzProgressLabels labels;

  /// A full-width line under the thread (a deadline: glyph and time, never a sentence). Hairline above.
  final Widget? note;
  final GzProgressNoteTone noteTone;
  final bool onDark;
  final GzDraw draw;

  /// Step id that just changed in view: its knot pops once.
  final String? pop;

  bool _reached(GzIconProgressStep s) => s.state != GzKnotState.open;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final animate = draw != GzDraw.off;
    final titleWeight = gz.text(GzTextRole.title).fontWeight;
    final cols = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final last = i == steps.length - 1;
      final active = s.state == GzKnotState.now || s.state == GzKnotState.ended;
      final shown = labels == GzProgressLabels.all || (labels == GzProgressLabels.active && active);
      final Color iconColor = switch (s.state) {
        GzKnotState.now => onDark ? c.textOnDarkGold : c.iconAccent,
        _ when onDark => c.iconOnDark,
        GzKnotState.open => c.iconDisabled,
        GzKnotState.tied => c.iconPrimary,
        GzKnotState.ended => s.endedTone == GzKnotEndedTone.danger || s.endedTone == GzKnotEndedTone.dangerOutline ? c.iconDanger : c.iconSecondary,
      };
      final labelColor = s.state == GzKnotState.ended ? (onDark ? c.textOnDarkMuted : c.textSecondary) : (onDark ? c.textOnDark : c.textStrong);
      final head = Padding(
        padding: const EdgeInsetsDirectional.only(end: GzSpace.s1),
        child: Row(
          children: [
            GzThreadKnot(state: s.state, onDark: onDark, endedIcon: s.endedIcon, endedTone: s.endedTone, pop: pop == s.id),
            if (!last) ...[
              const SizedBox(width: GzSpace.s1),
              Expanded(
                child: SizedBox(
                  height: GzStroke.thread,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: onDark ? c.markTrackOnDark : c.markTrack)),
                      if (_reached(steps[i + 1]))
                        Positioned.fill(
                          child: GzDrawOnce(enabled: animate, delay: GzMotion.durationFast * i, child: ColoredBox(color: c.markKhayt)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
      cols.add(
        Expanded(
          child: Semantics(
            label: s.label,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: GzSize.iconLg, height: GzSize.iconMd, child: Center(child: GzIcon(s.icon, size: GzIconSize.md, color: iconColor))),
                const SizedBox(height: GzSpace.s1),
                head,
                const SizedBox(height: GzSpace.s1),
                if (shown)
                  SizedBox(
                    width: GzSize.iconLg,
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: Text(
                        s.label,
                        softWrap: false,
                        style: gz.text(GzTextRole.caption).copyWith(color: labelColor, fontWeight: titleWeight, decoration: TextDecoration.none),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    final noteColor = switch (noteTone) {
      GzProgressNoteTone.muted => onDark ? c.textOnDarkMuted : c.textSecondary,
      GzProgressNoteTone.now => onDark ? c.textOnDarkGold : c.textGoldInk,
      GzProgressNoteTone.danger => c.textDanger,
    };
    return Semantics(
      container: true,
      label: describe == null ? label : '$label: $describe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols),
          if (note != null) ...[
            const SizedBox(height: GzSpace.s3),
            Container(
              padding: const EdgeInsets.only(top: GzSpace.s2),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: onDark ? c.borderOnDark : c.borderHairline, width: GzStroke.hair))),
              child: DefaultTextStyle(
                style: gz.text(GzTextRole.caption).copyWith(color: noteColor, decoration: TextDecoration.none),
                child: IconTheme(data: IconThemeData(color: noteColor), child: note!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
