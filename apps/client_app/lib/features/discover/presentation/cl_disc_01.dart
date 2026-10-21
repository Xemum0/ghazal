import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show requestsRepositoryProvider, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show DateMode, HomeCategoryId, HomeFeed, HomeStatusKind, LocalDate;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/discover_filters.dart' show discoverStateProvider;
import '../application/discover_home.dart';
import '../application/discover_regions.dart';
import '../application/discover_search.dart' show briefCountProvider;
import 'widgets/compare_dock.dart';
import 'widgets/discover_failure.dart';
import 'widgets/home_brief_card.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_shelves.dart';
import 'widgets/rail.dart';
import 'widgets/status_card.dart';

/// CL-DISC-01 Home (tab root of Discover). Covers CA-HOME-01 to CA-HOME-16, CA-ONB-08, CA-VCH-02, CA-VCH-12, CA-FLT-06, CA-SVC-13.
///
/// The Maison hero with the arch crown, the structured Brief card (each row a button that opens the Brief sheet on that row; one gold CTA
/// with the live count), one urgency-ranked status card, the Venues | Services switch, six photo category tiles, then the Brief-aware
/// shelves. A guest sees all of it; the third heart raises the once-only sign-up nudge. States: default, loading, empty, error, offline,
/// guest, tray.
class ClDisc01Screen extends ConsumerStatefulWidget {
  const ClDisc01Screen({super.key});

  @override
  ConsumerState<ClDisc01Screen> createState() => _ClDisc01ScreenState();
}

/// The photographs of the six category tiles (the same ones the prototype uses), by category.
const Map<HomeCategoryId, String> kCategoryPhotos = <HomeCategoryId, String>{
  HomeCategoryId.luxuryHotels: 'asset://ghazal_mock_api/images/halls-25-marble-staircase-foyer',
  HomeCategoryId.weddingHalls: 'asset://ghazal_mock_api/images/ballrooms-04-striped-chair-ballroom-full-room',
  HomeCategoryId.government: 'asset://ghazal_mock_api/images/halls-06-heritage-skylight-banquet-hall',
  HomeCategoryId.beach: 'asset://ghazal_mock_api/images/outdoor-02-white-arch-beach-ceremony',
  HomeCategoryId.outdoor: 'asset://ghazal_mock_api/images/outdoor-14-lakeside-ceremony-white-florals',
  HomeCategoryId.vip: 'asset://ghazal_mock_api/images/outdoor-24-villa-terrace-infinity-pool-sea',
};

const List<HomeCategoryId> kCategoryOrder = <HomeCategoryId>[
  HomeCategoryId.luxuryHotels,
  HomeCategoryId.weddingHalls,
  HomeCategoryId.government,
  HomeCategoryId.beach,
  HomeCategoryId.outdoor,
  HomeCategoryId.vip,
];

class _ClDisc01ScreenState extends ConsumerState<ClDisc01Screen> {
  Timer? _merge;

  @override
  void dispose() {
    _merge?.cancel();
    super.dispose();
  }

  GzNavigator get _nav => context.gzNav;

  void _editBrief([GzBriefField? field]) =>
      _nav.openSheet('CL-DISC-02', options: GzSheetOptions(params: <String, Object?>{'from': 'home', if (field != null) 'focus': field.name}));

  void _openResults(Map<String, Object?> preset) => _nav.push('CL-DISC-03', params: <String, Object?>{'from': 'discover', ...preset});

  void _showHalls(SearchBrief brief) => _openResults(<String, Object?>{'available': brief.date != null});

  void _openStatus(HomeFeed feed, SearchBrief brief) {
    final card = feed.statusCard;
    switch (card.kind) {
      case HomeStatusKind.noDate || HomeStatusKind.unknown:
        _editBrief(GzBriefField.date);
      case HomeStatusKind.briefSet:
        _showHalls(brief);
      case HomeStatusKind.voucherReady || HomeStatusKind.confirmed:
        _nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': card.voucherId, 'from': 'discover'});
      case HomeStatusKind.visitSoon:
        _nav.push('CL-VIST-03', params: <String, Object?>{'visitId': card.visitId, 'from': 'discover'});
      case HomeStatusKind.pending || HomeStatusKind.approved:
        _nav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': card.bookingId});
    }
  }

  Future<void> _refresh(SearchBrief brief) async {
    ref.invalidate(homeFeedProvider(brief));
    ref.invalidate(briefCountProvider(brief));
    try {
      await ref.read(homeFeedProvider(brief).future);
      if (mounted) _nav.toast(GzToastSpec(message: context.l10n.clientDiscoverRefreshed, tone: GzToastTone.success));
    } on Object {
      // the screen shows its own error state
    }
  }

  /// Once after sign-in: the phone and the account hold different Briefs, so the merge variant of the Brief sheet asks which to keep.
  void _maybeMerge(SearchBrief brief) {
    final session = ref.read(sessionProvider);
    if (!session.isSignedIn || ref.read(discoverStateProvider).mergeShown) return;
    final profile = ref.read(weddingProfileProvider).value;
    if (profile == null || brief.date == null) return;
    final differs = brief.date != profile.weddingDate || brief.guests != profile.guests.women || brief.areaIds.join(',') != profile.areaIds.join(',');
    if (!differs) return;
    _merge?.cancel();
    _merge = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || (ModalRoute.of(context)?.isCurrent ?? false) == false) return;
      ref.read(discoverStateProvider.notifier).markMergeShown();
      _nav.openSheet('CL-DISC-02', options: const GzSheetOptions(params: <String, Object?>{'variant': 'merge'}));
    });
  }

  Future<void> _pickDate(LocalDate d) async {
    ref.read(searchBriefProvider.notifier).update((b) => b.copyWith(date: d, dateMode: DateMode.exact));
    _nav.toast(GzToastSpec(message: context.l10n.clientDiscoverEmptyDateSet, tone: GzToastTone.success));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final brief = ref.watch(searchBriefProvider);
    final feed = ref.watch(homeFeedProvider(brief));
    final count = ref.watch(briefCountProvider(brief));
    final areas = ref.watch(areasProvider).value?.areas ?? const [];
    final unread = ref.watch(unreadNotificationsProvider);
    final hasTray = ref.watch(compareProvider.select((c) => !c.isEmpty));
    ref.listen<AsyncValue<Object?>>(weddingProfileProvider, (_, _) => _maybeMerge(ref.read(searchBriefProvider)));
    ref.listen<SearchBrief>(searchBriefProvider, (_, next) => _maybeMerge(next));
    final loading = feed.isLoading && !feed.hasValue && !feed.hasError;
    final failed = feed.hasError && !feed.hasValue;
    final offline = failed && isOfflineError(feed.error);
    final data = feed.value;
    final shownCount = loading || offline || brief.date == null ? null : count.value;
    final clockNow = ref.watch(clockProvider)();
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeHero(unread: unread, onBell: () => _nav.push('CL-MSGS-04')),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: HomeBriefCard(brief: brief, areas: areas, count: shownCount, onEdit: _editBrief, onShow: () => _showHalls(brief)),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, start: GzSpace.gutter, end: GzSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (offline) GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.card),
              if (offline) const SizedBox(height: GzSpace.s3),
              if (loading) const _StatusSkeleton() else if (data != null) _status(data, brief, count.value ?? 0),
              if (offline) ...[
                const SizedBox(height: GzSpace.s3),
                GzFactChip(
                  icon: GzIcons.clock,
                  label: l.clientDiscoverA11yUpdated,
                  value: f.dateTime(clockNow, DateStyle.short),
                  small: true,
                  tone: GzFactTone.muted,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, start: GzSpace.gutter, end: GzSpace.gutter),
          child: GzIconTabs<String>(
            label: l.clientDiscoverSwitchLabel,
            labels: GzIconTabsLabels.all,
            value: 'venues',
            onChanged: (v) {
              if (v == 'services') _nav.push('CL-SERV-01');
            },
            items: [
              GzIconTabItem(value: 'venues', icon: GzIcons.hall, label: l.clientShellSwitchVenues),
              GzIconTabItem(value: 'services', icon: GzIcons.flower, label: l.clientShellSwitchServices),
            ],
          ),
        ),
        if (loading)
          const ShelvesSkeleton()
        else if (failed)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.section, start: GzSpace.gutter, end: GzSpace.gutter),
            child: DiscoverFailure(error: feed.error!, onRetry: () => ref.invalidate(homeFeedProvider(brief)), retrying: feed.isLoading),
          )
        else ...[
          if (brief.date != null && count.hasValue && count.value == 0) _emptyLead(brief, data),
          _categories(),
          HomeShelves(brief: brief, onSeeAll: (s) => _openResults(<String, Object?>{'shelf': s.value})),
        ],
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.section, bottom: GzSpace.s12),
          child: Center(
            child: GzButton(
              key: const ValueKey<String>('discover.all'),
              label: l.clientDiscoverBrowseAll,
              variant: GzButtonVariant.tertiary,
              iconEnd: GzIcons.chevronRight,
              onPressed: () => _showHalls(brief),
            ),
          ),
        ),
      ],
    );
    return GzPullToRefresh(
      onRefresh: () => _refresh(brief),
      child: GzScreen(
        top: HomeBar(unread: unread, onBell: () => _nav.push('CL-MSGS-04')),
        topOverlay: true,
        bottom: hasTray && !loading && !failed
            ? ColoredBox(
                color: context.gz.colors.surfaceCanvas,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: GzSpace.s2),
                  child: CompareDock(),
                ),
              )
            : null,
        child: body,
      ),
    );
  }

  Widget _status(HomeFeed data, SearchBrief brief, int count) {
    final card = data.statusCard;
    Widget view(String? eventDate) =>
        HomeStatusCardView(card: card, briefDate: brief.date?.toString(), count: count, eventDate: eventDate, onOpen: () => _openStatus(data, brief));
    if (card.kind != HomeStatusKind.confirmed || card.bookingId == null) return view(null);
    return Consumer(
      builder: (context, ref, _) {
        final date = ref.watch(_confirmedDateProvider(card.bookingId!)).value;
        return view(date);
      },
    );
  }

  /// The lead shelf when no hall is free on the Brief date: a calm line, "Change date", and the nearest dates that have one.
  Widget _emptyLead(SearchBrief brief, HomeFeed? data) {
    final l = context.l10n;
    final date = brief.date!;
    final near = <LocalDate>[
      for (final d in data?.nearestFreeDates ?? const <LocalDate>[])
        if (d != date) d,
    ];
    return ShelfSection(
      title: l.clientDiscoverFreeTitle(shelfDayLabel(context, date.toString())),
      draw: GzDraw.mount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: GzEmptyState(
              key: const ValueKey<String>('discover.empty'),
              illustration: GzIllustrationName.emptyBookings,
              title: l.clientDiscoverEmptyTitle,
              fill: false,
              center: false,
              action: GzStateAction(
                label: l.clientDiscoverEmptyWiden,
                variant: GzButtonVariant.secondary,
                iconStart: GzIcons.calendar,
                onPressed: () => _editBrief(GzBriefField.date),
              ),
            ),
          ),
          if (near.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
              child: Semantics(
                container: true,
                label: l.clientDiscoverEmptyNearLabel,
                child: Wrap(
                  spacing: GzSpace.s2,
                  runSpacing: GzSpace.s2,
                  children: [
                    for (final d in near)
                      GzChip(label: shelfDayLabel(context, d.toString()), iconStart: GzIcons.calendar, onPressed: () => _pickDate(d)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categories() {
    final l = context.l10n;
    String label(HomeCategoryId id) => switch (id) {
      HomeCategoryId.luxuryHotels => l.clientDiscoverCategoryLuxuryHotels,
      HomeCategoryId.weddingHalls => l.clientDiscoverCategoryWeddingHalls,
      HomeCategoryId.government => l.clientDiscoverCategoryGovernment,
      HomeCategoryId.beach => l.clientDiscoverCategoryBeach,
      HomeCategoryId.outdoor => l.clientDiscoverCategoryOutdoor,
      HomeCategoryId.vip => l.clientDiscoverCategoryVip,
      HomeCategoryId.unknown => '',
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.section),
      child: Rail(
        label: l.clientDiscoverBrowseTitle,
        width: 152,
        children: [
          for (final id in kCategoryOrder)
            GzCategoryTile(
              key: ValueKey<String>('discover.category.${id.value}'),
              label: label(id),
              image: kCategoryPhotos[id],
              onOpen: () => _openResults(<String, Object?>{'category': id.value, 'areaIds': const <String>[]}),
            ),
        ],
      ),
    );
  }
}

/// The date of a confirmed request, for the status card (the home feed names the request, not its date).
final _confirmedDateProvider = FutureProvider.autoDispose.family<String?, String>((ref, id) async {
  final r = await ref.watch(requestsRepositoryProvider).getRequest(requestId: id);
  return r.booking.eventDate.toString();
});

class _StatusSkeleton extends StatelessWidget {
  const _StatusSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: GzSize.briefRow),
          padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
          decoration: BoxDecoration(
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: c.borderStrong, width: GzStroke.hair),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GzSkeleton(inlineSize: 240, blockSize: 24),
              SizedBox(height: GzSpace.s2),
              GzSkeleton(inlineSize: 180, blockSize: 20),
            ],
          ),
        ),
      ),
    );
  }
}
