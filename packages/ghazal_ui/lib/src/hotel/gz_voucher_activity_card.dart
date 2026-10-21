import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;

import '../charts/charts.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'hotel_a_kit.dart';

/// One day of the voucher line: its civil date and the number of vouchers bought.
class GzVoucherDay {
  const GzVoucherDay({required this.date, required this.value});

  final String date;
  final int value;
}

/// VoucherActivityCard: the month of vouchers in one hairline panel (it replaces the revenue card because Ghazal holds no event
/// money). Headline = vouchers bought for this venue in the period with its change, then the daily line (flat tint under an ink
/// line, first and last date labelled), then three ruled lines: requests received, waiting for the client to confirm (the 24 h
/// window), vouchers redeemed at the venue. Counts only, never a money figure. Web `VoucherActivityCard`.
class GzVoucherActivityCard extends StatelessWidget {
  const GzVoucherActivityCard({
    required this.title,
    required this.bought,
    required this.daily,
    required this.requests,
    required this.awaitingClient,
    required this.redeemed,
    this.period,
    this.delta,
    super.key,
  });

  /// Panel title (`Vouchers this month`) and the period under it (`1 - 12 Nov 2026`).
  final String title;
  final String? period;

  /// Vouchers bought for this venue in the period.
  final int bought;

  /// Change against the previous period, percent points.
  final num? delta;

  /// Daily counts of the line, oldest first.
  final List<GzVoucherDay> daily;
  final int requests;
  final int awaitingClient;
  final int redeemed;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final d = delta;
    final pct = d == null ? '' : f.percent(d.abs(), maxFraction: 1);
    final color = d == null ? c.textSecondary : (d > 0 ? c.textSuccess : (d < 0 ? c.textDanger : c.textSecondary));
    return GzHotelPanel(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: GzText(title, role: GzTextRole.title, color: c.textStrong, header: true),
            ),
            if (period != null) ...[
              const SizedBox(width: GzSpace.s3),
              GzText(period!, role: GzTextRole.caption, color: c.textSecondary, figures: true),
            ],
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s3,
          runSpacing: GzSpace.s1,
          children: [
            GzNum(f.integer(bought), role: GzTextRole.kpi, color: c.textPrimary),
            if (d != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(
                    d > 0 ? GzIcons.trendUp : (d < 0 ? GzIcons.trendDown : GzIcons.minus),
                    size: GzIconSize.xs,
                    color: color,
                    mirror: false,
                  ),
                  const SizedBox(width: GzSpace.s1),
                  gzFigText(context, d == 0 ? pct : '${d > 0 ? '+' : '−'}$pct', role: GzTextRole.caption, color: color),
                ],
              ),
          ],
        ),
        GzLineChart(
          title: l.uiHotelVactChart,
          height: GzSize.chartPlotCompact,
          xLabels: 3,
          xLabel: (i) => f.date(i < daily.length ? daily[i].date : '', DateStyle.dayMonth),
          formatAxis: (n) => f.integer(n),
          formatValue: (n) => f.integer(n),
          series: [
            GzLineSeries(id: 'daily', label: l.uiHotelVactDaily, values: [for (final v in daily) v.value], area: true),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (label, n) in [
              (l.uiHotelVactRequests, requests),
              (l.uiHotelVactAwaiting, awaitingClient),
              (l.uiHotelVactRedeemed, redeemed),
            ])
              Container(
                constraints: const BoxConstraints(minHeight: GzSize.controlMd),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GzText(label, role: GzTextRole.bodyS, color: c.textPrimary),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    GzNum(f.integer(n), role: GzTextRole.priceStrong, color: c.textPrimary),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
