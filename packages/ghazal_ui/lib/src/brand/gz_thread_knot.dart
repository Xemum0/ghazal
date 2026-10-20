import 'package:flutter/widgets.dart';

import '../core/gz_pop.dart';
import '../core/gz_preview.dart';
import '../foundation.dart';

/// open = hollow, 1.5 dp ink-500 ring (not yet); now = gold centre, 3 dp canvas gap, 3 dp gold-650 ring (the ring is the sole
/// carrier of "now"); tied = gold-500 fill with an ink-900 check (recorded); ended = a terminal knot with an icon in a tone.
enum GzKnotState { open, now, tied, ended }

/// `booking` 20 (full thread) and `compact` 12 (partner request card).
enum GzKnotSize { booking, compact }

/// The terminal tones: x danger, clock neutral, return arrow on rose, user-minus danger-outline.
enum GzKnotEndedTone { danger, dangerOutline, neutral, rose }

/// ThreadKnot (direction section 4): one knot = one recorded event. Every state sits in the same slot (32 / 24), so the ring of
/// `now` never moves its neighbours. [pop] plays the 0.6 -> 1.4 -> 1 pop once, for a live state change.
class GzThreadKnot extends StatelessWidget {
  const GzThreadKnot({
    required this.state,
    this.size = GzKnotSize.booking,
    this.onDark = false,
    this.endedIcon,
    this.endedTone = GzKnotEndedTone.danger,
    this.pop = false,
    this.alignStart = false,
    this.label,
    super.key,
  });

  final GzKnotState state;
  final GzKnotSize size;

  /// On an ink panel (partner header, confirmation hero): the ring gap and hollow centre are ink, not canvas.
  final bool onDark;

  /// `ended` only: the glyph (default close) shown on the 20 dp knot, not the 12 dp one.
  final IconData? endedIcon;
  final GzKnotEndedTone endedTone;

  /// Play the knot pop once (a state that just changed in view).
  final bool pop;

  /// The 12 dp compact knot sits flush with the inline-start text edge instead of centred in its 24 dp slot.
  final bool alignStart;

  /// Accessible name; without it the knot is decorative (its label sits next to it in the thread).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final compact = size == GzKnotSize.compact;
    final d = compact ? GzSize.knotCompact : GzSize.knotBooking;
    final slot = compact ? GzSize.iconMd : GzSize.iconLg;
    final canvas = onDark ? c.surfaceDark : c.surfaceCanvas;
    final Widget knot;
    switch (state) {
      case GzKnotState.open:
        knot = _circle(d, color: canvas, border: c.markOpen);
      case GzKnotState.now:
        knot = Container(
          width: d + 2 * GzSize.knotNowGap,
          height: d + 2 * GzSize.knotNowGap,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.markKhayt,
            border: Border.all(color: canvas, width: GzSize.knotNowGap),
            boxShadow: [BoxShadow(color: onDark ? c.markKhayt : c.markState, spreadRadius: GzSize.knotNowRing)],
          ),
        );
      case GzKnotState.tied:
        knot = _circle(d, color: c.markKhayt, glyph: compact ? null : GzIcons.check, glyphColor: c.textOnGold);
      case GzKnotState.ended:
        final (Color fill, Color border, Color fg) = switch (endedTone) {
          GzKnotEndedTone.danger =>
            onDark ? (c.surfaceDark, c.statusDangerBg, c.statusDangerBg) : (c.statusDangerText, c.statusDangerText, c.textOnDark),
          GzKnotEndedTone.dangerOutline =>
            onDark ? (c.surfaceDark, c.statusDangerBg, c.statusDangerBg) : (c.surfaceCanvas, c.statusDangerText, c.statusDangerText),
          GzKnotEndedTone.neutral =>
            onDark ? (c.surfaceDark, c.textOnDarkMuted, c.textOnDarkMuted) : (c.textSecondary, c.textSecondary, c.textOnDark),
          GzKnotEndedTone.rose => (c.surfaceTint, c.textSecondary, c.textPrimary),
        };
        knot = _circle(d, color: fill, border: border, glyph: compact ? null : (endedIcon ?? GzIcons.close), glyphColor: fg);
    }
    final box = SizedBox(
      width: slot,
      height: slot,
      child: Align(alignment: alignStart ? AlignmentDirectional.centerStart : Alignment.center, child: pop ? GzScalePop.knot(trigger: true, child: knot) : knot),
    );
    if (label == null) return ExcludeSemantics(child: box);
    return Semantics(label: label, image: true, excludeSemantics: true, child: box);
  }

  Widget _circle(double d, {required Color color, Color? border, IconData? glyph, Color? glyphColor}) {
    return Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: border == null ? null : Border.all(color: border, width: GzStroke.icon)),
      child: glyph == null ? null : GzIcon(glyph, sizeDp: GzSize.knotCompact, color: glyphColor),
    );
  }
}

enum GzBeadTone { gold, ink, hollow }

/// ThreadBead: the 8 dp diamond, boxed to 12 so the rotated square never clips or crowds the text beside it.
/// gold = chosen or progressing (default); ink = a quiet mark; hollow = not yet.
class GzThreadBead extends StatelessWidget {
  const GzThreadBead({this.tone = GzBeadTone.gold, super.key});

  final GzBeadTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ExcludeSemantics(
      child: GzBeadBox(color: tone == GzBeadTone.ink ? c.textStrong : null, hollow: tone == GzBeadTone.hollow),
    );
  }
}
