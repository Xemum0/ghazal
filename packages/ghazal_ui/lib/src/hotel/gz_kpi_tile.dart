import 'package:flutter/widgets.dart';

import '../charts/charts.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'hotel_a_kit.dart';

/// What a KPI tile counts, so the formatter, not the screen, writes it: money (integer fils), a count, or a percent (in percent
/// points: 0.93 is `0.9%`).
sealed class GzKpiValue {
  const GzKpiValue();

  const factory GzKpiValue.money(int fils) = GzKpiMoney;
  const factory GzKpiValue.count(num value) = GzKpiCount;
  const factory GzKpiValue.percent(num value) = GzKpiPercent;
}

final class GzKpiMoney extends GzKpiValue {
  const GzKpiMoney(this.fils);
  final int fils;
}

final class GzKpiCount extends GzKpiValue {
  const GzKpiCount(this.value);
  final num value;
}

final class GzKpiPercent extends GzKpiValue {
  const GzKpiPercent(this.value);
  final num value;
}

/// The trend of a KPI tile: values over the period, oldest first, and the accessible name of the line.
class GzKpiTrend {
  const GzKpiTrend({required this.values, required this.label});

  final List<num> values;
  final String label;
}

/// KpiTile: one number of the venue's performance. A hairline panel (paper, 1 dp ink-300, radius 12, padding 16): a caption label
/// (or, with [icon], a glyph in a disk that names the number), the value in the KPI voice, an optional sub-line, a sparkline, and the
/// delta with its icon and sign (up is more; the trend icon never mirrors). [hero] makes the tile full width with a taller
/// sparkline. With an [icon] the label is the accessible name and the delta's comparison words are read, not shown (ADR 0034).
/// Pass [onPressed] to make the tile a button. Web `KpiTile`.
class GzKpiTile extends StatelessWidget {
  const GzKpiTile({
    required this.label,
    required this.value,
    this.icon,
    this.delta,
    this.deltaLabel,
    this.sub,
    this.trend,
    this.hero = false,
    this.onPressed,
    super.key,
  });

  /// Caption above the value. With [icon] it is the accessible name only.
  final String label;
  final GzKpiValue value;

  /// The glyph that names the number: replaces the caption.
  final IconData? icon;

  /// Change against the previous period, in percent points (12 = +12%).
  final num? delta;

  /// What the delta is measured against (`vs previous 30 days`).
  final String? deltaLabel;

  /// A line under the value; numbers inside it are set as figures.
  final String? sub;
  final GzKpiTrend? trend;

  /// Full-width tile with the sparkline under the value.
  final bool hero;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final Widget figure = switch (value) {
      GzKpiMoney(:final fils) => GzPrice(fils: fils, size: GzPriceSize.kpi),
      GzKpiCount(:final value) => GzNum(f.integer(value), role: GzTextRole.kpi, color: c.textStrong),
      GzKpiPercent(:final value) => GzNum(f.percent(value, maxFraction: 1), role: GzTextRole.kpi, color: c.textStrong),
    };
    final d = delta;
    final pct = d == null ? '' : f.percent(d.abs(), maxFraction: 1);
    final signed = d == null || d == 0 ? pct : '${d > 0 ? '+' : '−'}$pct';
    final deltaColor = d == null ? c.textSecondary : (d > 0 ? c.textSuccess : (d < 0 ? c.textDanger : c.textSecondary));
    final deltaName = d == null ? null : (d == 0 ? l.uiHotelKpiFlat : (d > 0 ? l.uiHotelKpiUp(pct) : l.uiHotelKpiDown(pct)));
    final gap = hero ? GzSpace.s2 : GzSpace.s1;

    final children = <Widget>[
      if (icon != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            label: label,
            excludeSemantics: true,
            child: Container(
              width: GzSize.disk,
              height: GzSize.disk,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
              child: GzIcon(icon!, size: GzIconSize.sm, tone: GzIconTone.primary),
            ),
          ),
        )
      else
        GzText(label, role: GzTextRole.caption, color: c.textSecondary),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s1),
        child: Align(alignment: AlignmentDirectional.centerStart, child: figure),
      ),
      if (sub != null) GzText(sub!, role: GzTextRole.caption, color: c.textSecondary, figures: true),
      if (trend != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
          child: GzSparkline(values: trend!.values, label: trend!.label, height: hero ? GzSize.chartSparkLg : GzSize.chartSpark),
        ),
      if (d != null)
        Semantics(
          label: deltaName,
          excludeSemantics: true,
          child: Wrap(
            spacing: GzSpace.s1,
            runSpacing: GzSpace.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GzIcon(
                d > 0 ? GzIcons.trendUp : (d < 0 ? GzIcons.trendDown : GzIcons.minus),
                size: GzIconSize.xs,
                color: deltaColor,
                mirror: false,
              ),
              // The web figure island has line-height 0: it never makes the run taller than its icon (16).
              GzCenteredInLine(
                height: GzSize.iconXs,
                child: gzFigText(context, signed, role: GzTextRole.caption, weight: gz.text(GzTextRole.badge).fontWeight, color: deltaColor),
              ),
              if (deltaLabel != null && icon == null) GzText(deltaLabel!, role: GzTextRole.caption, color: c.textSecondary),
            ],
          ),
        ),
    ];

    Widget panel(bool pressed) => Container(
      padding: const EdgeInsets.all(GzSpace.s4),
      decoration: BoxDecoration(
        color: pressed ? c.surfaceQuiet : c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
        ],
      ),
    );
    if (onPressed == null) return panel(false);
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: [label, if (d != null) deltaName!].join(', '),
      borderRadius: GzRadius.mdAll,
      minHeight: 0,
      builder: (context, st) => panel(st.pressed),
    );
  }
}
