// HL-GROW-04 Analytics (web `HL-GROW-04.tsx`): is the listing working. Views, clicks, vouchers purchased, requests (and approved), vouchers redeemed
// and conversion for a chosen period, the funnel from view to redeemed voucher and the top packages, each chart with a table twin. Tapping a figure
// changes the main chart. There is no revenue: Ghazal holds no event money (ADR 0033 D7).
// Requirements: HA-ANLY-01, HA-ANLY-02, HA-ANLY-03, HA-ANLY-05, HA-ANLY-06, HA-ANLY-07, HA-ANLY-08, HA-VCH-04, HA-AUTH-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/grow_data.dart';
import 'widgets/analytics_parts.dart';
import 'widgets/grow_bits.dart';

enum _Range { month, d30, d90, custom }

enum _Metric { views, clicks, vouchers, requests, redeemed, conversion }

const int _minTrendDays = 7;

IconData _glyph(Object id) => switch (id) {
  _Metric.views => GzIcons.eye,
  _Metric.clicks => GzIcons.bolt,
  _Metric.vouchers => GzIcons.ticket,
  _Metric.requests => GzIcons.clipboard,
  'confirmed' => GzIcons.calendarCheck,
  _Metric.redeemed => GzIcons.checkDouble,
  _ => GzIcons.percent,
};

KpiId _kpi(_Metric m) => switch (m) {
  _Metric.views => KpiId.views,
  _Metric.clicks => KpiId.clicks,
  _Metric.vouchers => KpiId.vouchersBought,
  _Metric.requests => KpiId.requests,
  _Metric.redeemed => KpiId.vouchersRedeemed,
  _Metric.conversion => KpiId.conversion,
};

class HlGrow04Screen extends ConsumerStatefulWidget {
  const HlGrow04Screen({super.key});

  @override
  ConsumerState<HlGrow04Screen> createState() => _HlGrow04ScreenState();
}

class _HlGrow04ScreenState extends ConsumerState<HlGrow04Screen> {
  _Range _range = _Range.month;
  AnSpan? _custom;
  _Metric _metric = _Metric.views;
  final Set<String> _tables = <String>{};

  AnSpan _span(LocalDate today) {
    switch (_range) {
      case _Range.month:
        return (from: LocalDate(today.year, today.month, 1), to: today);
      case _Range.d30:
        return (from: today.addDays(-29), to: today);
      case _Range.d90:
        return (from: today.addDays(-89), to: today);
      case _Range.custom:
        return _custom ?? (from: today.addDays(-29), to: today);
    }
  }

  void _openRange(LocalDate today) {
    final l = context.l10n;
    GzNavigatorScope.of(context).openSheetBuilder(
      (_) => RangeSheet(
        initial: _custom == null ? GzDateRange.empty : GzDateRange(start: _custom!.from.toString(), end: _custom!.to.toString()),
        today: today.toString(),
        minDate: today.addDays(-364).toString(),
        onApply: (r) => setState(() {
          _custom = (from: LocalDate.parse(r.start!), to: LocalDate.parse(r.end!));
          _range = _Range.custom;
        }),
      ),
      options: GzSheetOptions(title: l.hotelGrowAnCustomTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final today = ref.watch(growTodayProvider);
    final span = _span(today);
    final value = ref.watch(analyticsProvider(span));
    final catalog = ref.watch(growCatalogProvider).value;
    final names = <Object, String>{
      _Metric.views: l.hotelGrowAnKpiViews,
      _Metric.clicks: l.hotelGrowAnKpiClicks,
      _Metric.vouchers: l.hotelGrowAnKpiVouchers,
      _Metric.requests: l.hotelGrowAnKpiRequests,
      'confirmed': l.hotelGrowAnStageConfirmed,
      _Metric.redeemed: l.hotelGrowAnKpiRedeemed,
      _Metric.conversion: l.hotelGrowAnKpiConversion,
    };
    return GzPullToRefresh(
      onRefresh: () async {
        ref.invalidate(analyticsProvider(span));
        await ref.read(analyticsProvider(span).future);
      },
      child: GzScreen(
        top: GzTopBar(title: l.hotelGrowAnTitle),
        child: GzAsyncView<PartnerAnalytics>(
          value: value,
          loading: const _Skeleton(),
          onRetry: () => ref.invalidate(analyticsProvider(span)),
          data: (a) {
            final days = span.from.daysUntil(span.to) + 1;
            final t = a.tiles;
            final empty = t.views.value == 0 && a.funnel.views == 0 && t.requests == 0;
            if (empty) {
              return Column(
                children: [
                  const SizedBox(height: GzSpace.s4),
                  GzTag(label: l.commonLabelNew, icon: GzIcons.sparkle),
                  GzEmptyState(fill: false, illustration: GzIllustrationName.emptyResults, title: l.hotelGrowAnEmptyTitle),
                ],
              );
            }
            final enough = days >= _minTrendDays;
            final series = a.series.where((s) => s.id == _kpi(_metric)).firstOrNull;
            final points = series?.points ?? const <KpiPoint>[];
            final pct = _metric == _Metric.conversion;
            final values = [for (final p in points) pct ? p.value / 100 : p.value];
            String fmtAxis(num n) => pct ? f.percent(n, maxFraction: 1) : f.integer(n);
            final delta = t.views.deltaPct;
            Widget tile(_Metric m, String figure, {Widget? sub, bool withDelta = false}) {
              String? dt;
              Dir dir = Dir.flat;
              String? spoken;
              if (withDelta) {
                dt = '${delta >= 0 ? '+' : '−'}${f.percent(delta.abs(), maxFraction: 1)}';
                dir = delta > 0 ? Dir.up : (delta < 0 ? Dir.down : Dir.flat);
                spoken = '$dt ${l.hotelGrowAnVsPrevious}';
              }
              return Expanded(
                child: MetricTile(
                  icon: _glyph(m),
                  label: names[m]!,
                  figure: figure,
                  deltaText: dt,
                  dir: dir,
                  spoken: spoken,
                  sub: sub,
                  selected: _metric == m,
                  onPressed: () => setState(() => _metric = m),
                ),
              );
            }

            Widget toggle(String key, IconData chartIcon) => GzButton(
              label: _tables.contains(key) ? l.hotelGrowAnAsChart : l.hotelGrowAnAsTable,
              variant: GzButtonVariant.tertiary,
              iconStart: _tables.contains(key) ? chartIcon : GzIcons.list,
              onPressed: () => setState(() => _tables.contains(key) ? _tables.remove(key) : _tables.add(key)),
            );
            final stages = [
              GzFunnelStage(id: 'views', label: names[_Metric.views]!, value: a.funnel.views),
              GzFunnelStage(id: 'clicks', label: names[_Metric.clicks]!, value: a.funnel.clicks),
              GzFunnelStage(id: 'vouchers', label: names[_Metric.vouchers]!, value: t.vouchersBought),
              GzFunnelStage(id: 'requests', label: names[_Metric.requests]!, value: a.funnel.requests),
              GzFunnelStage(id: 'confirmed', label: names['confirmed']!, value: a.funnel.confirmed),
              GzFunnelStage(id: 'redeemed', label: names[_Metric.redeemed]!, value: a.funnel.redeemed),
            ];
            final ranks = [
              for (final p in a.topPackages)
                GzRankedItem(
                  id: p.packageId,
                  label: catalog == null
                      ? p.packageId
                      : (catalog.packages.where((e) => e.package.id == p.packageId).firstOrNull?.package.name.of(lang) ?? p.packageId),
                  value: p.confirmed,
                ),
            ];
            final rangeText = '${dm(f, span.from.toString())} – ${f.date(span.to.toString(), DateStyle.compact)}';
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GzChipGroup<_Range>(
                    label: l.hotelGrowAnRangeLabel,
                    value: _range,
                    onChanged: (v) {
                      if (v == null) return;
                      if (v == _Range.custom) return _openRange(today);
                      setState(() => _range = v);
                    },
                    options: [
                      GzChipOption(value: _Range.month, label: l.hotelGrowAnRangeMonth),
                      GzChipOption(value: _Range.d30, label: l.hotelGrowAnRangeDays(30)),
                      GzChipOption(value: _Range.d90, label: l.hotelGrowAnRangeDays(90)),
                      GzChipOption(value: _Range.custom, icon: GzIcons.calendar, label: l.hotelGrowAnRangeCustom),
                    ],
                  ),
                  const SizedBox(height: GzSpace.s3),
                  Row(
                    children: [
                      GzFactChip(
                        icon: GzIcons.calendar,
                        valueWidget: GzText(rangeText, role: GzTextRole.figBodyS, color: c.textPrimary, figures: true),
                        label: l.hotelGrowAnRangeLabel,
                      ),
                      const Spacer(),
                      GzIconButton(
                        icon: GzIcons.info,
                        iconSize: GzIconSize.sm,
                        label: l.hotelGrowAnDefsTitle,
                        onPressed: () => GzNavigatorScope.of(context).openSheetBuilder(
                          (_) => DefinitionsSheet(rows: [for (final e in names.entries) (icon: _glyph(e.key), name: e.value)]),
                          options: GzSheetOptions(title: l.hotelGrowAnDefsTitle),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GzSpace.section),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tile(_Metric.views, f.integer(t.views.value), withDelta: true),
                        const SizedBox(width: GzSpace.s2),
                        tile(_Metric.clicks, f.integer(t.clicks)),
                        const SizedBox(width: GzSpace.s2),
                        tile(_Metric.vouchers, f.integer(t.vouchersBought)),
                      ],
                    ),
                  ),
                  const SizedBox(height: GzSpace.s2),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tile(
                          _Metric.requests,
                          f.integer(t.requests),
                          sub: GzFactChip(
                            icon: GzIcons.checkCircle,
                            value: f.integer(t.approved),
                            label: l.hotelGrowAnApproved,
                            small: true,
                            tone: GzFactTone.muted,
                          ),
                        ),
                        const SizedBox(width: GzSpace.s2),
                        tile(_Metric.redeemed, f.integer(t.vouchersRedeemed)),
                        const SizedBox(width: GzSpace.s2),
                        tile(_Metric.conversion, f.percent(t.conversionBps / 100, maxFraction: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: GzSpace.section),
                  GrowHead(icon: _glyph(_metric), title: names[_metric]!, trailing: enough ? toggle('chart', GzIcons.chartLine) : null),
                  const SizedBox(height: GzSpace.s3),
                  if (enough && values.isNotEmpty)
                    GzLineChart(
                      key: ValueKey(_metric),
                      series: [GzLineSeries(id: _metric.name, label: names[_metric]!, values: values, area: true)],
                      title: names[_metric]!,
                      description: l.hotelGrowAnChartDesc(
                        names[_metric]!,
                        f.date(span.from.toString(), DateStyle.short),
                        f.date(span.to.toString(), DateStyle.short),
                      ),
                      xLabel: (i) => f.date(points[i.clamp(0, points.length - 1)].date.toString(), DateStyle.dayMonth),
                      formatAxis: fmtAxis,
                      formatValue: fmtAxis,
                      showTable: _tables.contains('chart'),
                    )
                  else
                    GrowNote(
                      icon: GzIcons.hourglass,
                      text: NoteText(l.hotelGrowAnInsufShort(f.integer(_minTrendDays))),
                      info: GzInfoButton(title: l.hotelGrowAnInsufTitle, paragraphs: [l.hotelGrowAnInsufBody(_minTrendDays)]),
                    ),
                  const SizedBox(height: GzSpace.section),
                  GrowHead(icon: GzIcons.chartBar, title: l.hotelGrowAnFunnelTitle, trailing: toggle('funnel', GzIcons.chartBar)),
                  const SizedBox(height: GzSpace.s3),
                  GzFunnelBars(
                    stages: stages,
                    formatValue: (n) => f.integer(n),
                    formatStep: (p, _) => f.percent(p, maxFraction: 1),
                    title: l.hotelGrowAnFunnelDesc,
                    valueLabel: l.hotelGrowAnValueLabel,
                    showTable: _tables.contains('funnel'),
                  ),
                  const SizedBox(height: GzSpace.section),
                  GrowHead(icon: GzIcons.package, title: l.hotelGrowAnTopTitle, trailing: toggle('top', GzIcons.chartBar)),
                  const SizedBox(height: GzSpace.s3),
                  GzRankedBars(
                    items: ranks,
                    formatValue: (n) => f.integer(n),
                    title: l.hotelGrowAnTopDesc,
                    valueLabel: l.hotelGrowAnStageConfirmed,
                    showTable: _tables.contains('top'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 48),
        SizedBox(height: GzSpace.s4),
        Row(
          children: [
            Expanded(child: GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120)),
            SizedBox(width: GzSpace.s2),
            Expanded(child: GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120)),
            SizedBox(width: GzSpace.s2),
            Expanded(child: GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120)),
          ],
        ),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 176),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 240),
      ],
    ),
  );
}
