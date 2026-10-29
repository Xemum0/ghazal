import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, Review, ReviewSort;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/reviews_view.dart';
import 'widgets/flow_review_item.dart';
import 'widgets/flow_score_summary.dart';

/// CL-RVRW-01 Reviews. Covers CA-VDET-20, CA-REV-05, CA-REV-06, CA-CARD-03,
/// CA-CARD-04.
///
/// All reviews of one venue: the score with the four category bars, a strip
/// saying what the viewer can do, filter chips, and review cards with the
/// venue's reply and a report control. Reading is open to everyone; "Write
/// review" appears only for a completed booking here. A venue with no reviews
/// reads "New", never 0.0.
/// States: default, loading, new-venue-empty, filtered-empty, error, offline,
/// report-sheet, reported.
class ClRvrw01Screen extends ConsumerStatefulWidget {
  const ClRvrw01Screen({super.key});

  @override
  ConsumerState<ClRvrw01Screen> createState() => _ClRvrw01ScreenState();
}

class _ClRvrw01ScreenState extends ConsumerState<ClRvrw01Screen> {
  ReviewFilter _filter = ReviewFilter.all;
  ReviewSort _sort = ReviewSort.newest;
  int _shown = 5;
  String? _reason;

  GzNavigator get _nav => context.gzNav;

  String get _venueId => (_nav.params['venueId'] as String?) ?? 'V01';

  static const int _page = 5;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final venue = ref.watch(reviewVenueProvider(_venueId)).value;
    final venueName = venue?.name.of(lang) ?? '';
    final reviews = ref.watch(venueReviewsProvider((venueId: _venueId, sort: _sort)));
    final elig = ref.watch(reviewEligibilityProvider(_venueId)).value;
    // Enlarged text does not fit a title and a subtitle in the fixed bar: one combined line (the name ellipsizes).
    final dense = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final title = l.clientReviewsRewardsListTitle;
    return GzScreen(
      top: dense
          ? GzTopBar(
              titleWidget: Semantics(
                header: true,
                label: venueName.isEmpty ? title : '$title, $venueName',
                child: GzText(
                  venueName.isEmpty ? title : '$title · $venueName',
                  role: GzTextRole.title,
                  color: context.gz.colors.textStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : GzTopBar(title: title, subtitle: venueName.isEmpty ? null : venueName),
      child: GzAsyncView<List<Review>>(
        value: reviews,
        loading: const _ReviewsSkeleton(),
        onRetry: () => ref.invalidate(venueReviewsProvider((venueId: _venueId, sort: _sort))),
        data: (all) {
          final list = filterReviews(all, _filter, _sort);
          final visible = list.take(_shown).toList();
          final isNew = all.isEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isNew)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s6),
                  child: GzEmptyState(
                    key: const ValueKey<String>('reviews.new'),
                    illustration: GzIllustrationName.emptyMessages,
                    title: context.gzL10n.commonLabelNew,
                  ),
                )
              else
                const SizedBox.shrink(),
              if (!isNew)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s6),
                  child: FlowScoreSummary(rating: venue!.rating),
                ),
              _writeStrip(context, bookingId: elig?.booking.id, eventDate: elig?.booking.eventDate),
              if (!isNew) ...[
                _filters(context),
                if (list.isEmpty)
                  GzEmptyState(
                    key: const ValueKey<String>('reviews.filtered-empty'),
                    fill: false,
                    illustration: GzIllustrationName.noResult,
                    title: context.gzL10n.commonStateTitleEmptySearch,
                    action: GzStateAction(label: context.gzL10n.commonActionClear, onPressed: () => setState(() => _filter = ReviewFilter.all)),
                  )
                else
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s8),
                    child: Column(
                      children: [
                        for (final r in visible)
                          RepaintBoundary(
                            child: FlowReviewItem(
                              review: r,
                              venueName: venueName,
                              moreKey: ValueKey<String>('reviews.report.${r.id}'),
                              onMore: () => _openReport(context, r.id),
                            ),
                          ),
                        if (list.length > visible.length) ...[
                          const SizedBox(height: GzSpace.s3),
                          GzButton(
                            label: l.clientReviewsRewardsListMoreReviews,
                            variant: GzButtonVariant.secondary,
                            iconEnd: GzIcons.chevronDown,
                            onPressed: () => setState(() => _shown += _page),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  // Back returns to the venue ('CL-VENU-01'); photos open the shared viewer (the 'CL-VENU-02' pattern).
  /// The ruled strip: a hairline above and below (the YOUR DATE idiom), padded 20 at the sides.
  Widget _ruled(BuildContext context, Widget child, {double padBlock = 0, Key? key}) {
    final c = context.gz.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      child: Container(
        key: key,
        padding: EdgeInsets.symmetric(vertical: padBlock),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _writeStrip(BuildContext context, {String? bookingId, LocalDate? eventDate}) {
    final l = context.l10n;
    final nav = _nav;
    if (bookingId != null) {
      return _ruled(
        context,
        Row(
          key: const ValueKey<String>('reviews.write'),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GzFactChip(
              icon: GzIcons.calendar,
              label: l.clientReviewsRewardsListEvent,
              value: eventDate == null ? null : context.gzFormat.date(eventDate.toString(), DateStyle.dayMonth),
            ),
            const SizedBox(width: GzSpace.s4),
            GzButton(
              label: l.clientReviewsRewardsListWrite,
              iconStart: GzIcons.edit,
              onPressed: () => nav.push('CL-RVRW-02', params: <String, Object?>{'bookingId': bookingId, 'venueId': _venueId, 'from': 'list'}),
            ),
          ],
        ),
        padBlock: GzSpace.s4,
      );
    }
    final upcoming = ref.watch(reviewUpcomingProvider(_venueId)).value;
    if (upcoming == null) return const SizedBox.shrink();
    final date = context.gzFormat.date(upcoming.booking.eventDate.toString(), DateStyle.dayMonth);
    return _ruled(
      context,
      GzIconListRow(flush: true, last: true, illustration: GzIllustrationName.hourglass, title: l.clientReviewsRewardsOpens(date)),
    );
  }

  Widget _filters(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    Widget chip(ReviewFilter v, String label, {IconData? icon}) => GzChip(
      label: label,
      iconStart: icon,
      selected: _filter == v,
      onPressed: () => setState(() {
        _filter = v;
        _shown = _page;
      }),
    );
    return Padding(
      // The web rail has 20 above it and 4 of its own padding on both sides.
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s5 + GzSpace.s1, bottom: GzSpace.s1),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: GzSpace.gutter),
            GzChip(label: _sortLabel(context), iconStart: GzIcons.sort, menu: true, onPressed: () => _openSort(context)),
            const SizedBox(width: GzSpace.s2),
            chip(ReviewFilter.photos, l.clientReviewsRewardsListFilterPhotos, icon: GzIcons.camera),
            const SizedBox(width: GzSpace.s2),
            chip(ReviewFilter.five, f.integer(5), icon: GzIcons.starFill),
            const SizedBox(width: GzSpace.s2),
            chip(ReviewFilter.four, f.integer(4), icon: GzIcons.starFill),
            const SizedBox(width: GzSpace.s2),
            GzChip(
              label: '${f.integer(1)}–${f.integer(3)}',
              labelWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzText(f.integer(1), role: GzTextRole.body, figures: true),
                  GzText('–', role: GzTextRole.body),
                  GzText(f.integer(3), role: GzTextRole.body, figures: true),
                ],
              ),
              iconStart: GzIcons.starFill,
              selected: _filter == ReviewFilter.low,
              onPressed: () => setState(() {
                _filter = ReviewFilter.low;
                _shown = _page;
              }),
            ),
            const SizedBox(width: GzSpace.gutter),
          ],
        ),
      ),
    );
  }

  String _sortLabel(BuildContext context) {
    final l = context.l10n;
    return switch (_sort) {
      ReviewSort.highest => l.clientReviewsRewardsListSortHighest,
      ReviewSort.lowest => l.clientReviewsRewardsListSortLowest,
      _ => l.clientReviewsRewardsListSortRecent,
    };
  }

  void _openSort(BuildContext context) {
    final l = context.l10n;
    final nav = _nav;
    nav.openSheetBuilder(
      (_) => Column(
        key: const ValueKey<String>('reviews.sort'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GzText(l.clientReviewsRewardsListSortTitle, role: GzTextRole.d1, color: context.gz.colors.textStrong, header: true),
              ),
              const SizedBox(width: GzSpace.s3),
              GzBarButton(icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: () => nav.closeSheet()),
            ],
          ),
          const SizedBox(height: GzSpace.s2),
          GzRadioGroup<ReviewSort>(
            label: l.clientReviewsRewardsListSortTitle,
            value: _sort,
            onChanged: (v) {
              setState(() {
                _sort = v;
                _shown = _page;
              });
              nav.closeSheet();
            },
            children: [
              for (final s in [ReviewSort.newest, ReviewSort.highest, ReviewSort.lowest])
                GzRadio<ReviewSort>(
                  value: s,
                  label: s == ReviewSort.highest
                      ? l.clientReviewsRewardsListSortHighest
                      : (s == ReviewSort.lowest ? l.clientReviewsRewardsListSortLowest : l.clientReviewsRewardsListSortRecent),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openReport(BuildContext context, String reviewId) {
    final l = context.l10n;
    final nav = _nav;
    final reasons = <String>[
      l.clientReviewsRewardsListReasonAbusive,
      l.clientReviewsRewardsListReasonNotVenue,
      l.clientReviewsRewardsListReasonPeople,
      l.clientReviewsRewardsListReasonOther,
    ];
    nav.openSheetBuilder(
      (_) => StatefulBuilder(
        builder: (context, setSheet) => Column(
          key: const ValueKey<String>('reviews.report'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: GzText(l.clientReviewsRewardsListReportTitle, role: GzTextRole.d1, color: context.gz.colors.textStrong, header: true),
                ),
                const SizedBox(width: GzSpace.s3),
                GzBarButton(icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: () => nav.closeSheet()),
              ],
            ),
            const SizedBox(height: GzSpace.s2),
            GzRadioGroup<String>(
              label: l.clientReviewsRewardsListReportTitle,
              value: _reason,
              onChanged: (v) => setSheet(() => _reason = v),
              children: [for (final r in reasons) GzRadio<String>(value: r, label: r)],
            ),
            const SizedBox(height: GzSpace.s3),
            GzButton(
              label: context.gzL10n.commonActionSend,
              fullWidth: true,
              onPressed: _reason == null
                  ? null
                  : () {
                      setState(() => _reason = null);
                      nav.closeSheet();
                      nav.toast(GzToastSpec(message: l.clientReviewsRewardsListReportSent, tone: GzToastTone.success));
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          GzSkeleton(blockSize: 120),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(blockSize: 160),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(blockSize: 160),
        ],
      ),
    );
  }
}
