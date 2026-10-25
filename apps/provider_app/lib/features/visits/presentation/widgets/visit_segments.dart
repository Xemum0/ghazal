// VisitSegments: the Requested / Upcoming / Past control of HL-VIST-01 (web `SegmentedControl` with a node label). The web options are
// `flex: 1 1 0` but never narrower than their content, so "Requested [1]" keeps its full word and the other two share what is left; the kit's
// GzSegmentTrack gives every option an equal third and clipped the word ("Request…"). Same track, thumb and gold thread as the kit, with
// option widths from the content (a kit option for it is in docs/engineering/requests.md).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

class VisitSegments extends StatelessWidget {
  const VisitSegments({required this.label, required this.words, required this.active, required this.onChanged, this.badge = 0, super.key});

  /// The group's accessible name.
  final String label;
  final List<String> words;
  final int active;
  final ValueChanged<int> onChanged;

  /// The count shown after the first word (hidden at 0), capped at 9.
  final int badge;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final slide = GzReducedMotion.movement(context, GzMotion.durationSlow);
    final style = gz.text(GzTextRole.button);
    final dir = Directionality.of(context);
    final n = words.length;
    double wordWidth(String s) {
      final p = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: dir,
        maxLines: 1,
      )..layout();
      return p.width;
    }

    return Semantics(
      container: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.controlTrack, borderRadius: GzRadius.mdAll),
        child: Padding(
          padding: const EdgeInsets.all(GzSpace.s1),
          child: LayoutBuilder(
            builder: (context, box) {
              final badgeWidth = badge > 0 ? GzSpace.s1 + GzSize.badge + (badge > 9 ? GzSpace.s2 : 0) : 0.0;
              final mins = [for (var i = 0; i < n; i++) wordWidth(words[i]) + (i == 0 ? badgeWidth : 0) + 2 * GzSpace.s3];
              final equal = box.maxWidth / n;
              final wide = [
                for (var i = 0; i < n; i++)
                  if (mins[i] > equal) i,
              ];
              final rest = wide.length == n ? equal : (box.maxWidth - wide.fold<double>(0, (s, i) => s + mins[i])) / (n - wide.length);
              final widths = [for (var i = 0; i < n; i++) wide.contains(i) ? mins[i] : rest];
              final starts = <double>[for (var i = 0, x = 0.0; i < n; x += widths[i], i++) x];
              return SizedBox(
                height: GzSize.controlSm,
                child: Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      duration: slide,
                      curve: GzMotion.easeStandard,
                      start: starts[active],
                      width: widths[active],
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: c.actionSelectedBg, borderRadius: GzRadius.smAll),
                        child: Align(
                          alignment: AlignmentDirectional.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s3, bottom: GzSpace.s1),
                            child: SizedBox(
                              width: double.infinity,
                              height: GzStroke.thread,
                              child: ColoredBox(color: c.markKhayt),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < n; i++)
                          SizedBox(
                            width: widths[i],
                            child: _Option(word: words[i], selected: i == active, badge: i == 0 ? badge : 0, onPressed: () => onChanged(i)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.word, required this.selected, required this.badge, required this.onPressed});

  final String word;
  final bool selected;
  final int badge;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final color = selected ? c.actionSelectedLabel : c.textPrimary;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: GzPressable(
        onPressed: onPressed,
        semanticLabel: word,
        selected: selected,
        borderRadius: GzRadius.smAll,
        builder: (context, st) => SizedBox(
          width: double.infinity,
          height: GzSize.controlSm,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: GzText(word, role: GzTextRole.button, color: color, maxLines: 1, softWrap: false),
                ),
                if (badge > 0) ...[
                  const SizedBox(width: GzSpace.s1),
                  Center(
                    child: SizedBox(
                      height: GzSize.badge,
                      child: GzCountBadge(count: badge, max: 9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
