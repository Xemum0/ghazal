// HL-GROW-06 Reviews (web `HL-GROW-06.tsx`): read what couples wrote, reply once in the venue's voice and report abuse. The venue never approves, edits
// or hides a review; Ghazal moderates (CF-24); hiding or deleting is asked of support. Also the landing of the new-review notification (`reviewId`
// param: scrolled to, reply sheet ready). The list opens on the four newest and grows by one tap. A reply is open for 30 days after a review is posted.
// Requirements: HA-NOTI-04, HA-NOTI-07, HA-NOTI-09, HA-AUTH-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show clockProvider, DecimalOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/grow_data.dart';
import 'widgets/review_item.dart';
import 'widgets/review_sheets.dart';

enum _Filter { all, needs, replied, reported }

const int _replyWindowDays = 30;
const int _firstPage = 4;

class HlGrow06Screen extends ConsumerStatefulWidget {
  const HlGrow06Screen({super.key});

  @override
  ConsumerState<HlGrow06Screen> createState() => _HlGrow06ScreenState();
}

class _HlGrow06ScreenState extends ConsumerState<HlGrow06Screen> {
  _Filter _filter = _Filter.all;
  int _shown = _firstPage;
  bool _landed = false;

  void _openReply(Review r) => GzNavigatorScope.of(context).openSheetBuilder(
    (_) => ReplySheet(review: r, initial: r.replyDraft?.of(r.origin.value) ?? ''),
    options: GzSheetOptions(
      title: context.l10n.hotelGrowRwReplyTitle(r.anonymous ? context.l10n.hotelGrowRwAnonymous : r.author.of(context.gz.locale.languageCode)),
    ),
  );

  void _openReport(Review r) => GzNavigatorScope.of(context).openSheetBuilder(
    (_) => ReportSheet(review: r),
    options: GzSheetOptions(title: context.l10n.hotelGrowRwReportTitle),
  );

  void _rules() {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: GzSpace.s2),
          GzText(l.hotelGrowRwModerated, role: GzTextRole.body, color: context.gz.colors.textPrimary),
          const SizedBox(height: GzSpace.s4),
          GzButton(
            label: l.hotelGrowRwAskSupport,
            variant: GzButtonVariant.secondary,
            iconStart: GzIcons.chatText,
            fullWidth: true,
            onPressed: () {
              nav.closeSheet();
              nav.push('HL-TODY-05', params: {'conversationId': 'conv-support-aurelia'});
            },
          ),
        ],
      ),
      options: GzSheetOptions(title: l.hotelGrowRwRulesTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final value = ref.watch(growReviewsProvider);
    final reported = ref.watch(reportedReviewsProvider);
    final venue = ref.watch(growVenueProvider).value?.venue;
    final now = ref.watch(clockProvider)();
    final targetId = nav.params['reviewId'] as String?;
    final all = value.value ?? const <Review>[];
    final view = [
      for (final r in all)
        (
          review: r,
          reported: reported.contains(r.id),
          replied: r.ownerReply != null,
          open: r.ownerReply == null && !reported.contains(r.id) && now.difference(r.postedAt).inDays <= _replyWindowDays,
        ),
    ];
    final needs = view.where((v) => v.open).length;
    final matching = view
        .where(
          (v) => switch (_filter) {
            _Filter.all => true,
            _Filter.needs => v.open,
            _Filter.replied => v.replied,
            _Filter.reported => v.reported,
          },
        )
        .toList();
    final targetAt = targetId == null ? -1 : matching.indexWhere((v) => v.review.id == targetId);
    final visible = matching.take(_shown > targetAt + 1 ? _shown : targetAt + 1).toList();
    final rest = matching.length - visible.length;
    if (!_landed && targetId != null && value.hasValue) {
      _landed = true;
      final r = all.where((x) => x.id == targetId).firstOrNull;
      if (r != null && r.ownerReply == null && !reported.contains(r.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _openReply(r) : null);
      }
    }
    const one = DecimalOptions(minFraction: 1, maxFraction: 1);
    final cat = venue?.rating.categories;
    Widget summary() {
      if (venue == null) return const SizedBox.shrink();
      final r = venue.rating;
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
        child: Semantics(
          container: true,
          label: l.hotelGrowRwSummaryLabel,
          child: Container(
            padding: const EdgeInsetsDirectional.all(GzSpace.s4),
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: GzRadius.mdAll,
              border: Border.all(color: c.borderStrong, width: GzStroke.hair),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    r.count > 0 && r.average != null
                        ? GzText(f.number(r.average!, one), role: GzTextRole.fig3xl, color: c.textStrong, figures: true)
                        : GzTag(label: l.commonLabelNew),
                    const SizedBox(width: GzSpace.s4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GzRating(value: r.average ?? 0, variant: GzRatingVariant.stars, showValue: false),
                          const SizedBox(height: GzSpace.s1),
                          GzFactChip(
                            icon: GzIcons.chatText,
                            value: f.integer(r.count),
                            label: l.hotelGrowRwReviews,
                            small: true,
                            tone: GzFactTone.muted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (cat != null) ...[
                  const SizedBox(height: GzSpace.s4),
                  Container(height: GzStroke.hair, color: c.borderHairline),
                  const SizedBox(height: GzSpace.s3),
                  Semantics(
                    container: true,
                    label: l.hotelGrowRwCategories,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GzFactChip(icon: GzIcons.hall, value: f.number(cat.venue, one), label: l.hotelGrowRwCatVenue),
                        GzFactChip(icon: GzIcons.catering, value: f.number(cat.food, one), label: l.hotelGrowRwCatFood),
                        GzFactChip(icon: GzIcons.staff, value: f.number(cat.service, one), label: l.hotelGrowRwCatService),
                        GzFactChip(icon: GzIcons.coins, value: f.number(cat.value, one), label: l.hotelGrowRwCatValue),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return GzPullToRefresh(
      onRefresh: () async {
        ref.invalidate(growReviewsProvider);
        await ref.read(growReviewsProvider.future);
      },
      child: GzScreen(
        top: GzTopBar(
          title: l.hotelGrowRwTitle,
          actions: [GzTopBarAction(icon: GzIcons.info, label: l.commonA11yInfo, onPressed: _rules)],
        ),
        child: GzAsyncView<List<Review>>(
          value: value,
          loading: const _Skeleton(),
          onRetry: () => ref.invalidate(growReviewsProvider),
          data: (_) {
            if (all.isEmpty) {
              return Column(
                children: [
                  const SizedBox(height: GzSpace.s4),
                  GzTag(label: l.commonLabelNew, icon: GzIcons.sparkle),
                  GzEmptyState(fill: false, illustration: GzIllustrationName.partnerReview, title: l.hotelGrowRwEmptyTitle),
                ],
              );
            }
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  summary(),
                  GzIconTabs<_Filter>(
                    label: l.hotelGrowRwFilterLabel,
                    value: _filter,
                    onChanged: (v) => setState(() {
                      _filter = v;
                      _shown = _firstPage;
                    }),
                    items: [
                      GzIconTabItem(value: _Filter.all, icon: GzIcons.list, label: l.hotelGrowRwFilterAll),
                      GzIconTabItem(value: _Filter.needs, icon: GzIcons.reply, label: l.hotelGrowRwFilterNeeds, count: needs),
                      GzIconTabItem(value: _Filter.replied, icon: GzIcons.checkDouble, label: l.hotelGrowRwFilterReplied),
                      GzIconTabItem(value: _Filter.reported, icon: GzIcons.flag, label: l.hotelGrowRwFilterReported),
                    ],
                  ),
                  const SizedBox(height: GzSpace.s4),
                  if (visible.isNotEmpty)
                    for (var i = 0; i < visible.length; i++)
                      ReviewItem(
                        key: ValueKey(visible[i].review.id),
                        review: visible[i].review,
                        state: visible[i].reported
                            ? ReviewItemState.reported
                            : (visible[i].open ? ReviewItemState.needsReply : ReviewItemState.replied),
                        last: i == visible.length - 1 && rest == 0,
                        onReply: () => _openReply(visible[i].review),
                        onReport: () => _openReport(visible[i].review),
                      )
                  else
                    GzEmptyState(
                      fill: false,
                      illustration: _filter == _Filter.needs ? GzIllustrationName.successRequest : GzIllustrationName.shelf,
                      title: _filter == _Filter.needs ? l.hotelGrowRwNoNeedsTitle : l.hotelGrowRwNoFilterTitle,
                      action: GzStateAction(
                        label: l.hotelGrowRwShowAll,
                        variant: GzButtonVariant.secondary,
                        onPressed: () => setState(() => _filter = _Filter.all),
                      ),
                    ),
                  if (rest > 0)
                    Align(
                      alignment: AlignmentDirectional.center,
                      child: GzButton(
                        label: '${l.hotelGrowRwMore} ${f.integer(rest)}',
                        variant: GzButtonVariant.tertiary,
                        iconStart: GzIcons.chevronDown,
                        onPressed: () => setState(() => _shown = visible.length + _firstPage),
                      ),
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
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 128),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 56),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 176),
        SizedBox(height: GzSpace.s4),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 176),
      ],
    ),
  );
}
