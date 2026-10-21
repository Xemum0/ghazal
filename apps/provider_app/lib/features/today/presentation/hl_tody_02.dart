// HL-TODY-02 Needs you (web `HL-TODY-02.tsx`): the full queue behind the count on Today. Everything that needs a person, ranked by nearest
// deadline: pending requests, visit requests, an unanswered message, a review waiting for a reply, the weekly calendar check, then the requests
// approved and waiting for the client. No money row, no swipe actions (ADR 0014 D4): every action is a visible control.
// Requirements: HA-DASH-03, HA-DASH-04, HA-DASH-06, HA-NOTI-09, HA-VIS-01.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/today_data.dart';
import 'widgets/need_queue.dart';
import 'widgets/today_bits.dart';

enum NeedFilter { all, request, visit, message, review, calendar }

const Map<NeedFilter, List<NeedKind>> _kinds = {
  NeedFilter.request: [NeedKind.request, NeedKind.awaiting],
  NeedFilter.visit: [NeedKind.visit],
  NeedFilter.message: [NeedKind.message],
  NeedFilter.review: [NeedKind.review],
  NeedFilter.calendar: [NeedKind.calendar],
};

int _count(List<NeedItem> items, NeedFilter f) => f == NeedFilter.all ? items.length : items.where((e) => _kinds[f]!.contains(e.kind)).length;

IconData _icon(NeedFilter f) => switch (f) {
      NeedFilter.all => GzIcons.list,
      NeedFilter.request => GzIcons.calendarDots,
      NeedFilter.visit => GzIcons.calendarPlus,
      NeedFilter.message => GzIcons.chat,
      NeedFilter.review => GzIcons.star,
      NeedFilter.calendar => GzIcons.calendarCheck,
    };

String _word(AppL10n l, NeedFilter f) => switch (f) {
      NeedFilter.all => l.hotelTodayFilterAll,
      NeedFilter.request => l.hotelTodayFilterRequests,
      NeedFilter.visit => l.hotelTodayFilterVisits,
      NeedFilter.message => l.hotelTodayFilterMessages,
      NeedFilter.review => l.hotelTodayFilterReviews,
      NeedFilter.calendar => l.hotelTodayFilterCalendar,
    };

class HlTody02Screen extends ConsumerStatefulWidget {
  const HlTody02Screen({super.key});

  @override
  ConsumerState<HlTody02Screen> createState() => _HlTody02ScreenState();
}

class _HlTody02ScreenState extends ConsumerState<HlTody02Screen> {
  NeedFilter _filter = NeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final needs = ref.watch(needItemsProvider);
    final confirmed = ref.watch(calendarConfirmedProvider);
    final skeletonRow = Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Row(
          children: [
            const GzSkeleton(variant: GzSkeletonVariant.circle, inlineSize: 40),
            const SizedBox(width: GzSpace.s3),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [GzSkeleton(inlineSize: 168, blockSize: 24), SizedBox(height: GzSpace.s1), GzSkeleton(inlineSize: 128, blockSize: 20)]),
            ),
            const SizedBox(width: GzSpace.s3),
            GzSkeleton(inlineSize: 56, blockSize: 20),
          ],
        ),
      ),
    );
    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: GzTopBar(title: l.hotelTodayNeedsTitle),
        child: GzAsyncView<List<NeedItem>>(
          value: needs,
          loading: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: Column(children: [for (var i = 0; i < 5; i++) skeletonRow]),
          ),
          onRetry: () => ref.invalidate(partnerTodayProvider),
          data: (all) {
            final entries = all.where((e) => !(confirmed && e.kind == NeedKind.calendar)).toList();
            if (entries.isEmpty) return _Clear();
            final effective = _filter != NeedFilter.all && _count(entries, _filter) == 0 ? NeedFilter.all : _filter;
            final list = effective == NeedFilter.all ? entries : entries.where((e) => _kinds[effective]!.contains(e.kind)).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s1),
                  child: GzIconTabs<NeedFilter>(
                    label: l.hotelTodayFiltersLabel,
                    value: effective,
                    onChanged: (v) => setState(() => _filter = v),
                    items: [
                      for (final f in NeedFilter.values) GzIconTabItem<NeedFilter>(value: f, icon: _icon(f), label: _word(l, f), count: _count(entries, f) == 0 ? null : _count(entries, f)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s8),
                  child: NeedQueue(key: ValueKey(effective), entries: list, detail: true),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// All clear: the drawing and two words, then the next event as facts under them.
class _Clear extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final now = ref.watch(clockProvider)();
    final today = ref.watch(partnerTodayProvider).value;
    final next = nextEventOf(today, now, lang);
    final when = next == null ? null : f.time(f.instant('${f.isoDay(now)}T${next.start}'));
    final hall = next?.hall;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s6),
      child: Column(
        children: [
          GzEmptyState(illustration: GzIllustrationName.seal, title: l.hotelTodayAllClear, fill: false, size: GzIllustrationSize.hero),
          if (when != null)
            GzFactRow(
              label: l.hotelTodayNextLabel,
              children: [
                TextFact(icon: GzIcons.clock, label: l.hotelTodayFactTime, text: when),
                if (hall != null && hall.isNotEmpty) TextFact(icon: GzIcons.hall, label: l.hotelTodayFactHall, text: hall, muted: true),
              ],
            ),
        ],
      ),
    );
  }
}
