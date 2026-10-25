// HL-PROV-07 Listing performance (web `HL-PROV-07.tsx`): how a listing is doing. Views, vouchers bought, requests and redeemed for a period and
// the funnel from view to redemption, with a table twin. No revenue anywhere. Live listings only; an ended listing shows its last period and
// "Renew". Requirements: PA-LST-05, HA-ANLY-08, HA-ANLY-07.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, NameStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/perf_data.dart';
import '../application/provider_data.dart';
import 'widgets/perf_range_sheet.dart';
import 'widgets/prov_bits.dart';

class HlProv07Screen extends ConsumerStatefulWidget {
  const HlProv07Screen({super.key});

  @override
  ConsumerState<HlProv07Screen> createState() => _HlProv07State();
}

class _HlProv07State extends ConsumerState<HlProv07Screen> {
  RangeId _range = RangeId.month;
  (LocalDate, LocalDate)? _custom;
  bool _funnelTable = false;

  void _choose(RangeId? id) {
    if (id == null) return;
    if (id != RangeId.custom) return setState(() => _range = id);
    final nav = GzNavigatorScope.of(context);
    final today = dayOf(context.gzFormat, ref.read(clockProvider)());
    nav.openSheetBuilder(
      (_) => PerfRangeSheet(
        today: today,
        initial: _custom,
        onApply: (from, to) {
          setState(() {
            _custom = (from, to);
            _range = RangeId.custom;
          });
          nav.closeSheet();
        },
      ),
      options: GzSheetOptions(title: context.l10n.hotelProviderRangeTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final nav = GzNavigatorScope.of(context);
    final id = nav.params['listingId'] as String? ?? kHeroLiveListingId;
    final today = dayOf(f, ref.watch(clockProvider)());
    final listingV = ref.watch(pickedListingProvider(ListingPick(id, const [ListingStatus.active, ListingStatus.expired])));
    final billing = ref.watch(partnerBillingProvider).value;
    final ctx = ref.watch(partnerContextProvider);
    final exempt = billing?.feeExempt ?? false;
    final listing = listingV.value;
    final ended = listing?.status == ListingStatus.expired;
    final (from, to) = spanOf(_range, today, _custom);
    final perf = listing == null ? null : ref.watch(listingPerformanceProvider(PerfArgs(listing.id, from, to)));
    final enough = PerfArgs(id, from, to).days >= kMinFunnelDays;

    GzActionBar? bottom;
    if (ended && listing != null && !exempt) {
      bottom = GzActionBar(action: GzActionBarAction(label: l.hotelProviderStepRenew, iconEnd: GzIcons.chevronRight, onPressed: () => nav.push('HL-PROV-04', params: {'listingId': listing.id, 'renewal': true})));
    }

    Widget tile(String label, num value, {num? delta}) => Expanded(
          child: GzKpiTile(label: label, value: GzKpiValue.count(value), delta: delta, deltaLabel: delta == null ? null : l.hotelProviderPerfVsPrevious),
        );

    Widget body(ListingPerformance p) {
      final t = p.tiles;
      final rows = <(String, int)>[
        (l.hotelProviderPerfViews, t.views.value),
        (l.hotelProviderPerfSaves, t.clicks),
        (l.hotelProviderPerfVouchers, t.vouchersBought),
        (l.hotelProviderPerfRequests, t.requests),
        (l.hotelProviderPerfRedeemed, t.vouchersRedeemed),
      ];
      final rangeText = '${f.date(from.toJson(), DateStyle.short)} – ${f.weekdayName(f.civil(to.toJson()).weekday, NameStyle.short)} ${f.date(to.toJson(), DateStyle.compact)}';
      const gap = SizedBox(height: GzSpace.s5);
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (listing != null) ...[
              Row(children: [
                Expanded(child: GzUserText(listing.title.of(lang), role: GzTextRole.title, color: c.textStrong)),
                const SizedBox(width: GzSpace.s3),
                GzListingStatusPill(status: listing.status),
              ]),
              gap,
            ],
            if (ended && listing?.endsOn != null) ...[ProvNote(icon: GzIcons.calendar, figures: true, text: l.hotelProviderPerfEnded(f.date(listing!.endsOn!.toJson(), DateStyle.short))), gap],
            GzChipGroup<RangeId>(
              label: l.hotelProviderPerfRangeLabel,
              value: _range,
              onChanged: _choose,
              options: [
                GzChipOption(value: RangeId.month, label: l.hotelProviderPerfRangeMonth),
                GzChipOption(value: RangeId.d30, label: l.hotelProviderPerfRange30(30)),
                GzChipOption(value: RangeId.d90, label: l.hotelProviderPerfRange90(90)),
                GzChipOption(value: RangeId.custom, label: l.hotelProviderPerfRangeCustom),
              ],
            ),
            const SizedBox(height: GzSpace.s2),
            GzText(rangeText, role: GzTextRole.bodyS, color: c.textSecondary, figures: true),
            gap,
            Semantics(
              container: true,
              label: l.hotelProviderPerfTitle,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i += 2) ...[
                    if (i > 0) const SizedBox(height: GzSpace.s3),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          tile(rows[i].$1, rows[i].$2, delta: i == 0 ? t.views.deltaPct : null),
                          if (i + 1 < rows.length) ...[const SizedBox(width: GzSpace.s3), tile(rows[i + 1].$1, rows[i + 1].$2)],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            gap,
            GzSectionHeader(title: l.hotelProviderPerfFunnel, voice: GzHeaderVoice.partner),
            const SizedBox(height: GzSpace.s3),
            if (enough) ...[
              GzFunnelBars(
                stages: [for (var i = 0; i < rows.length; i++) GzFunnelStage(id: 'm$i', label: rows[i].$1, value: rows[i].$2)],
                formatValue: (n) => f.integer(n),
                formatStep: (percent, previous) => l.hotelProviderPerfStep(f.percent(percent, maxFraction: 1)),
                title: l.hotelProviderPerfFunnel,
                description: l.hotelProviderPerfFunnelDesc,
                valueLabel: l.hotelProviderPerfCount,
                showTable: _funnelTable,
              ),
              const SizedBox(height: GzSpace.s3),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GzButton(
                  label: _funnelTable ? l.hotelProviderPerfAsChart : l.hotelProviderPerfAsTable,
                  variant: GzButtonVariant.tertiary,
                  iconStart: _funnelTable ? GzIcons.chartBar : GzIcons.list,
                  onPressed: () => setState(() => _funnelTable = !_funnelTable),
                ),
              ),
            ] else
              ProvNote(icon: GzIcons.info, figures: true, text: l.hotelProviderPerfInsufficient(kMinFunnelDays)),
            gap,
            if (ctx?.isProvider != true) ...[
              GzButton(label: l.hotelProviderPerfVenueAnalytics, variant: GzButtonVariant.secondary, iconEnd: GzIcons.chevronRight, fullWidth: true, onPressed: () => nav.push('HL-GROW-04')),
              gap,
            ],
            if (listing != null)
              Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: l.hotelProviderPerfAllListings, variant: GzButtonVariant.tertiary, onPressed: () => nav.push('HL-PROV-02'))),
          ],
        ),
      );
    }

    final value = listingV.hasError ? AsyncValue<ListingPerformance?>.error(listingV.error!, listingV.stackTrace ?? StackTrace.empty) : (perf ?? const AsyncValue<ListingPerformance>.loading()).whenData<ListingPerformance?>((v) => v);
    return GzScreen(
      top: GzTopBar(
        title: l.hotelProviderPerfTitle,
        actions: [if (listing != null && !ended) GzTopBarAction(icon: GzIcons.edit, label: l.hotelProviderPerfEdit, onPressed: () => nav.push('HL-PROV-03', params: {'listingId': listing.id}))],
      ),
      bottom: bottom,
      child: GzAsyncView<ListingPerformance?>(
        value: value,
        isEmpty: (v) => v == null,
        empty: GzEmptyState(illustration: GzIllustrationName.emptyResults, title: l.hotelProviderPerfEmptyTitle, fill: false),
        loading: const _Skeleton(),
        onRetry: () {
          ref.invalidate(pickedListingProvider);
          ref.invalidate(listingPerformanceProvider);
        },
        data: (p) => body(p!),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 48),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 112),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 112),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 240),
          ],
        ),
      );
}
