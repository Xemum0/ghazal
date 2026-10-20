import 'package:flutter/widgets.dart';

import '../core/gz_draw_once.dart';
import '../foundation.dart';

const String _kLatin = 'Ghazal';
const String _kArabic = '\u063a\u0632\u0644';

enum GzWordmarkSize { sm, md, lg, xl }

enum GzWordmarkScript { both, latin, arabic }

/// Wordmark: the master lockup (ADR 0030 D10, direction section 7). The display serif "Ghazal" and "غزل" on a shared baseline, a
/// gold-500 thread running along that baseline and ending in a knot. Brand marks never mirror (ADR 0014), so the lockup is always
/// LTR: Latin first, then Arabic, in both languages. The line draws on once at session start (900 ms) when [draw] is set.
/// Sizes: sm 24 (the minimum), md 28 (the top-bar mark), lg 40, xl 60. Never recolour the thread, never put it above the letters.
class GzWordmark extends StatelessWidget {
  const GzWordmark({this.size = GzWordmarkSize.md, this.script = GzWordmarkScript.both, this.onDark = false, this.draw = false, super.key});

  final GzWordmarkSize size;

  /// `both` is the master lockup; `latin` or `arabic` is the single-script form.
  final GzWordmarkScript script;

  /// On an ink panel: letters in canvas. The thread stays gold-500, never recoloured.
  final bool onDark;

  /// Draw the thread on once (session start only).
  final bool draw;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    // Geometry per size, derived from the direction 7 formulas: pad start/end, thread distance from the box bottom, tracking, knot, gap.
    final (double padStart, double padEnd, double base, double track, double knot, double gap, double thick, GzTextRole role) = switch (size) {
      GzWordmarkSize.sm => (6.0, 12.0, 12.0, 0.48, GzSpace.s1, GzSpace.s2, GzStroke.icon, GzTextRole.d2),
      GzWordmarkSize.md => (6.0, 14.0, 10.0, 0.56, GzSpace.s1, GzSpace.s3, GzStroke.icon, GzTextRole.wordmark),
      GzWordmarkSize.lg => (8.0, 20.0, 19.0, 0.8, 6.0, GzSpace.s4, GzStroke.icon, GzTextRole.d4),
      GzWordmarkSize.xl => (12.0, 28.0, 20.0, 1.2, GzSize.knotBead, GzSpace.s5, GzStroke.thread, GzTextRole.d6),
    };
    final latinOnly = script == GzWordmarkScript.latin;
    final baseGap = latinOnly
        ? switch (size) {
            GzWordmarkSize.sm => 9.0,
            GzWordmarkSize.md => 8.0,
            GzWordmarkSize.lg => 12.0,
            GzWordmarkSize.xl => 15.0,
          }
        : base;
    final ink = onDark ? c.textOnDark : c.textStrong;
    final latin = GzType.style(const Locale('en'), role).copyWith(color: ink, decoration: TextDecoration.none, letterSpacing: track); // gz-rules-ok: brand lockup tracking from the direction 7 formula, Latin only
    final arabic = GzType.style(const Locale('ar'), role).copyWith(color: ink, decoration: TextDecoration.none, letterSpacing: 0);
    final thread = PositionedDirectional(
      start: 0,
      end: 0,
      bottom: baseGap,
      height: thick,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GzDrawOnce(
              enabled: draw,
              duration: GzMotion.durationWordmark,
              child: DecoratedBox(decoration: BoxDecoration(color: c.markKhayt, borderRadius: GzRadius.pillAll)),
            ),
          ),
          PositionedDirectional(
            end: 0,
            top: (thick - knot) / 2,
            child: GzFadeInOnce(
              enabled: draw,
              delay: GzMotion.durationWordmark,
              child: Transform.rotate(angle: 0.7853981633974483, child: SizedBox.square(dimension: knot, child: ColoredBox(color: c.markKhayt))),
            ),
          ),
        ],
      ),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Semantics(
        label: '$_kLatin $_kArabic',
        image: true,
        excludeSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            thread,
            Padding(
              padding: EdgeInsetsDirectional.only(start: padStart, end: padEnd),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  if (script != GzWordmarkScript.arabic) Text(_kLatin, style: latin, softWrap: false),
                  if (script == GzWordmarkScript.both) SizedBox(width: gap),
                  if (script != GzWordmarkScript.latin) Text(_kArabic, style: arabic, softWrap: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
