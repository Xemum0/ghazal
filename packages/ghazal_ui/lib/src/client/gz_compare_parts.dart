import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import '../inputs/gz_toggle_row.dart';

/// RangeBar (web `RangeBar`): a 2 dp track in the track colour, a gold fill as long as the value, an ink tick (1.5 x 12) at "your"
/// value. Grows from the inline-start edge (it mirrors with the row). [decorative] hides it from assistive tech because the value is
/// already written beside it.
class GzRangeBar extends StatelessWidget {
  const GzRangeBar({required this.value, required this.max, required this.label, this.mark, this.markLabel, this.decorative = false, super.key});

  /// The cell's value on the shared scale.
  final num value;

  /// The largest value on the row (the full track).
  final num max;

  /// "Your" value on the same scale (guests): draws the ink tick.
  final num? mark;

  /// Legend under the bar for the tick ("your 350"), already formatted.
  final String? markLabel;

  /// Accessible description ("Up to 650 guests").
  final String label;
  final bool decorative;

  static int _flex(num v) => (v * 1000).round();

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final top = max < 1 ? 1 : max;
    final v = value.clamp(0, top);
    final m = mark?.clamp(0, top);
    Widget tick() => SizedBox(
      width: GzStroke.icon,
      child: ColoredBox(color: c.textPrimary),
    );
    Widget grow(int flex, [Widget? child]) => flex > 0 ? Expanded(flex: flex, child: child ?? const SizedBox.shrink()) : const SizedBox.shrink();
    final track = SizedBox(
      height: GzStroke.thread,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          grow(_flex(v), ColoredBox(color: c.markKhayt)),
          grow(_flex(top - v), ColoredBox(color: c.markTrack)),
        ],
      ),
    );
    final stage = SizedBox(
      height: GzSize.knotCompact,
      child: Stack(
        children: [
          Positioned.fill(child: Center(child: track)),
          if (m != null)
            Positioned.fill(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [grow(_flex(m)), tick(), grow(_flex(top - m))]),
            ),
        ],
      ),
    );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: stage),
        if (markLabel != null) ...[
          const SizedBox(height: GzSpace.s1),
          Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: GzStroke.icon,
                  height: GzSize.knotCompact,
                  child: ColoredBox(color: c.textPrimary),
                ),
              ),
              const SizedBox(width: GzSpace.s1),
              Flexible(
                child: GzText(markLabel!, role: GzTextRole.caption, color: c.textSecondary, figures: true),
              ),
            ],
          ),
        ],
      ],
    );
    return KeyedSubtree(
      key: const ValueKey('gz-range-bar'),
      child: decorative ? body : Semantics(image: true, label: label, excludeSemantics: true, child: body),
    );
  }
}

/// BestInRow (web `BestInRow`): the gold-ink bead before the winning value of an objective row. Never colour alone: the words travel
/// with it as the semantics value.
class GzBestInRow extends StatelessWidget {
  const GzBestInRow({required this.child, this.role = GzTextRole.bodyS, super.key});

  final Widget child;

  /// The text role the web value block inherits: the cell's (body-s), or a figure role when a `gz-t-fig-*` span wraps the whole row item.
  final GzTextRole role;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final best = context.gzL10n.uiClientCompareBest;
    return MergeSemantics(
      child: Semantics(
        value: best,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzStroke.thread),
                child: GzBead(color: c.textGoldInk),
              ),
            ),
            const SizedBox(width: GzSpace.s1),
            // The web `.gz-best__value` is a block: its line box holds the cell's strut around the inline-level value.
            Flexible(child: GzInlineStrut(role: role, child: child)),
          ],
        ),
      ),
    );
  }
}

/// CompareBand (web `CompareBand`): a group band on the quiet surface.
class GzCompareBand extends StatelessWidget {
  const GzCompareBand({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    return ExcludeSemantics(
      child: Container(
        width: double.infinity,
        color: c.surfaceQuiet,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3, vertical: GzSpace.s2),
        child: Text(
          label,
          style: gz
              .text(GzTextRole.caption)
              .copyWith(color: c.textPrimary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
        ),
      ),
    );
  }
}

/// A row of equal thirds with 1 dp hairlines between them (the web flex `1 1 0` columns with a start border): the hairline sits outside
/// the equal shares, which is what the box model of the web gives.
class GzCompareThirds extends StatelessWidget {
  const GzCompareThirds({required this.children, this.stretch = true, super.key});

  final List<Widget> children;

  /// Stretch the columns to the tallest one (`align-items: stretch`); false centres them.
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final row = Row(
      crossAxisAlignment: stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            SizedBox(
              width: GzStroke.hair,
              child: ColoredBox(color: c.borderHairline),
            ),
          Expanded(child: children[i]),
        ],
      ],
    );
    return stretch ? IntrinsicHeight(child: row) : row;
  }
}

/// One cell of a [GzCompareRow]: the web `.gz-cmpr__cell` (padding 8 / 12 / 12, a 44 minimum, 4 between its children).
class GzCompareCell extends StatelessWidget {
  const GzCompareCell({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s3, top: GzSpace.s2, bottom: GzSpace.s3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s1), children[i]],
          ],
        ),
      ),
    );
  }
}

/// CompareRow (web `CompareRow`): a label over three cells with hairline dividers. [owners] are the hall names, read before each cell.
class GzCompareRow extends StatelessWidget {
  const GzCompareRow({required this.label, required this.cells, this.owners, super.key});

  final String label;

  /// One node per column, in column order (build each with [GzCompareCell]).
  final List<Widget> cells;
  final List<String>? owners;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s3, top: GzSpace.s3),
              child: ExcludeSemantics(
                child: GzText(label, role: GzTextRole.caption, color: c.textSecondary),
              ),
            ),
            GzCompareThirds(
              children: [
                for (var i = 0; i < cells.length; i++)
                  Semantics(container: true, label: owners != null && i < owners!.length ? owners![i] : null, child: cells[i]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// DifferencesToggle (web `DifferencesToggle`): the "Differences only" row with its hidden-row count.
class GzDifferencesToggle extends StatelessWidget {
  const GzDifferencesToggle({required this.checked, required this.onChanged, required this.hidden, super.key});

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final int hidden;

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final f = context.gzFormat;
    final description = !checked || hidden == 0
        ? l.uiClientCompareAllShown
        : (hidden == 1 ? l.uiClientCompareHiddenOne : l.uiClientCompareHidden(f.integer(hidden)));
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      child: GzToggleRow(title: l.uiClientCompareDifferences, description: description, checked: checked, onChanged: onChanged),
    );
  }
}
