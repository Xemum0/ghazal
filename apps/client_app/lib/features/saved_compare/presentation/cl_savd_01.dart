import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart'
    show BookingChannel, CardPriceExact, MoneyAmount, SavedType, ServiceProvider, VenueDayState, VenueResult;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/saved_data.dart';
import 'widgets/saved_rows.dart';
import 'widgets/saved_tray.dart';

/// CL-SAVD-01 Saved (tab root of the Saved tab). Covers CA-TOOL-01..04, CA-PROF-03, CA-CMP-01, CA-CMP-12, CA-NOTI-04, CA-AUTH-09, CA-AUTH-10, CA-VCH-02.
///
/// The family's shortlist, said in glyphs and figures (ADR 0034): three segments as glyph tabs (halls, services, packages), halls sorted
/// free-first, the Brief date stated once above the list as `[calendar] 14 Jan` and `[check] 4/5` free, and per row a quiet area, an
/// availability glyph and the voucher price with the standard price struck beside it. Hearts remove with Undo, Select enters multi-select
/// into Compare, the quiet Compare tray docks above the tab bar, and a guest sees "This phone only" with Sign in. Empty segments are one
/// drawing, three words and one action. States: default, loading, empty-venues / services / packages, guest-local, select-mode,
/// venue-unlisted, offline, error.
class ClSavd01Screen extends ConsumerStatefulWidget {
  const ClSavd01Screen({super.key});

  @override
  ConsumerState<ClSavd01Screen> createState() => _ClSavd01ScreenState();
}

class _ClSavd01ScreenState extends ConsumerState<ClSavd01Screen> {
  SavedSegment _seg = SavedSegment.venues;
  bool _selecting = false;
  String _refetched = '';

  GzNavigator get _nav => context.gzNav;

  @override
  void initState() {
    super.initState();
    // another screen asked for a segment (the services hub opens Saved on Services): apply it once
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPending(ref.read(pendingSavedSegmentProvider)));
  }

  void _applyPending(SavedSegment? wanted) {
    if (wanted == null || !mounted) return;
    setState(() {
      _seg = wanted;
      _selecting = false;
    });
    ref.read(pendingSavedSegmentProvider.notifier).ask(null);
  }

  void _openVenue(VenueResult r) => _nav.push(
    r.venue.channel == BookingChannel.externalLink ? 'CL-VENU-06' : 'CL-VENU-01',
    params: <String, Object?>{'venueId': r.venue.id, 'from': 'saved'},
  );

  /// Removes a heart with the Undo toast (every action has a visible control; no swipe).
  Future<void> _unsave(SavedType kind, String id, {MoneyAmount? seen}) async {
    final fav = ref.read(favouritesProvider.notifier);
    await fav.toggle(kind, id);
    if (!mounted) return;
    _nav.toast(
      GzToastSpec(
        message: context.l10n.clientSavedCompareSavedRemoved,
        undo: true,
        action: GzToastAction(
          label: context.gzL10n.commonActionUndo,
          onPressed: () => fav.toggle(kind, id, lastSeenPrice: seen),
        ),
      ),
    );
  }

  void _toggleCompare(String id) {
    final r = ref.read(compareProvider.notifier).toggle(id);
    if (r == CompareResult.full) _nav.openSheet('CL-SAVD-03', options: GzSheetOptions(params: <String, Object?>{'incoming': id}));
  }

  Widget _empty(SavedSegment seg) {
    final l = context.l10n;
    final (art, title, action, target) = switch (seg) {
      SavedSegment.venues => (
        GzIllustrationName.emptySaved,
        l.clientSavedCompareSavedEmptyVenuesTitle,
        l.clientSavedCompareSavedEmptyVenuesAction,
        'CL-DISC-03',
      ),
      SavedSegment.services => (
        GzIllustrationName.bouquet,
        l.clientSavedCompareSavedEmptyServicesTitle,
        l.clientSavedCompareSavedEmptyServicesAction,
        'CL-SERV-01',
      ),
      SavedSegment.packages => (
        GzIllustrationName.invitation,
        l.clientSavedCompareSavedEmptyPackagesTitle,
        l.clientSavedCompareSavedEmptyPackagesAction,
        'CL-PLAN-01',
      ),
    };
    return GzEmptyState(
      key: ValueKey<String>('saved.empty.${seg.name}'),
      illustration: art,
      title: title,
      action: GzStateAction(label: action, variant: GzButtonVariant.primary, onPressed: () => _nav.push(target)),
      fill: false,
      size: GzIllustrationSize.hero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    ref.listen<SavedSegment?>(pendingSavedSegmentProvider, (_, next) => _applyPending(next));
    final brief = ref.watch(searchBriefProvider);
    final guest = ref.watch(clientUserIdProvider) == null;
    final favAsync = ref.watch(favouritesProvider);
    final bundleAsync = ref.watch(savedBundleProvider);
    final readyAsync = ref.watch(readyVouchersProvider);
    final areas = ref.watch(savedAreaNamesProvider).value ?? const {};
    final compareIds = ref.watch(compareProvider.select((s) => s.venueIds));
    final fav = favAsync.value ?? FavouritesState.empty;
    final bundle = bundleAsync.value;
    final loading = (bundleAsync.isLoading && !bundleAsync.hasValue && !bundleAsync.hasError) || (favAsync.isLoading && !favAsync.hasValue);
    final error = bundleAsync.hasError && !bundleAsync.hasValue ? bundleAsync.error : null;
    final problem = error is ApiProblem ? error : (error == null ? null : const ApiProblem(status: 0, code: ApiProblemCode.unknown));
    final offline = problem?.isOffline ?? false;
    final ready = readyAsync.value ?? const <String, String>{};

    // a heart placed after the list was fetched has no row yet: fetch again once for that set
    if (bundle != null && !bundleAsync.isLoading) {
      final have = <String>{for (final r in bundle.venues) r.venue.id, for (final v in bundle.vendors) v.id, for (final p in bundle.packages) p.id};
      final want = <String>{...fav.venue, ...fav.vendor, ...fav.package};
      final missing = want.difference(have);
      final key = missing.toList()..sort();
      if (missing.isNotEmpty && _refetched != key.join('|')) {
        _refetched = key.join('|');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.invalidate(savedBundleProvider);
        });
      }
    }

    final venueRows = <VenueResult>[
      if (bundle != null)
        for (final r in bundle.venues)
          if (fav.venue.contains(r.venue.id)) r,
    ]..sort((a, b) => availabilityRank(a, brief).compareTo(availabilityRank(b, brief)));
    final vendors = <ServiceProvider>[
      if (bundle != null)
        for (final v in bundle.vendors)
          if (fav.vendor.contains(v.id)) v,
    ];
    final packages = <SavedPackage>[
      if (bundle != null)
        for (final p in bundle.packages)
          if (fav.package.contains(p.id)) p,
    ];
    final counts = (venues: venueRows.length, services: vendors.length, packages: packages.length);
    final countOf = switch (_seg) {
      SavedSegment.venues => counts.venues,
      SavedSegment.services => counts.services,
      SavedSegment.packages => counts.packages,
    };
    final free = venueRows.where((r) => r.availability == VenueDayState.available).length;
    final dateText = brief.date == null ? null : f.date(brief.date.toString(), DateStyle.dayMonth);
    final summaryName = dateText == null
        ? ''
        : counts.venues == 1
        ? (free == 1 ? l.clientSavedCompareSavedSummaryOneFree(dateText) : l.clientSavedCompareSavedSummaryOneBusy(dateText))
        : l.clientSavedCompareSavedSummaryFree(free, counts.venues, dateText);

    final canSelect = _seg == SavedSegment.venues && counts.venues > 1 && !loading && error == null;
    final showTray = !_selecting && !loading && error == null && compareIds.isNotEmpty;
    final pair = GzBidi.isolateLtr('${f.integer(compareIds.length)}/${f.integer(kCompareMax)}');
    final Widget? bottom = _selecting
        ? GzActionBar(
            action: GzActionBarAction(
              label: l.clientShellCompareTray(pair),
              onPressed: compareIds.length < 2 ? null : () => _nav.push('CL-SAVD-04', params: const <String, Object?>{'from': 'saved'}),
              disabled: compareIds.length < 2,
              reason: compareIds.length < 2 ? l.clientSavedCompareSavedSelectNeedTwo : null,
            ),
          )
        : (showTray ? const SavedTrayLayer() : null);

    final tabs = GzIconTabs<SavedSegment>(
      key: const ValueKey<String>('saved.tabs'),
      label: l.clientSavedCompareSavedTabsLabel,
      value: _seg,
      labels: GzIconTabsLabels.all,
      onChanged: (v) => setState(() {
        _seg = v;
        _selecting = false;
      }),
      items: [
        GzIconTabItem<SavedSegment>(value: SavedSegment.venues, icon: GzIcons.hall, label: l.clientShellSwitchVenues),
        GzIconTabItem<SavedSegment>(value: SavedSegment.services, icon: GzIcons.sparkle, label: l.clientShellSwitchServices),
        GzIconTabItem<SavedSegment>(value: SavedSegment.packages, icon: GzIcons.package, label: l.clientShellSwitchPackages),
      ],
    );

    Widget list() {
      if (loading) return const SavedRowsSkeleton();
      if (countOf == 0) return _empty(_seg);
      switch (_seg) {
        case SavedSegment.venues:
          return Column(
            children: [
              for (var i = 0; i < venueRows.length; i++)
                SavedVenueRow(
                  row: venueRows[i],
                  area: areas[venueRows[i].venue.areaId]?.of(lang),
                  guest: guest,
                  hasDate: brief.date != null && !offline,
                  dateText: dateText,
                  savingChanged: _savingChanged(venueRows[i], bundle?.lastSeen[venueRows[i].venue.id]) && !offline,
                  voucherId: guest || offline ? null : ready[venueRows[i].venue.id],
                  onOpenVoucher: () => _nav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': ready[venueRows[i].venue.id]}),
                  selecting: _selecting,
                  selected: compareIds.contains(venueRows[i].venue.id),
                  onOpen: () => _selecting ? _toggleCompare(venueRows[i].venue.id) : _openVenue(venueRows[i]),
                  onRemove: () => _unsave(SavedType.venue, venueRows[i].venue.id, seen: bundle?.lastSeen[venueRows[i].venue.id]),
                  last: i == venueRows.length - 1,
                ),
            ],
          );
        case SavedSegment.services:
          return Column(
            children: [
              for (var i = 0; i < vendors.length; i++)
                SavedVendorRow(
                  vendor: vendors[i],
                  area: areas[vendors[i].areaId]?.of(lang),
                  guest: guest,
                  onOpen: () => _nav.push('CL-SERV-03', params: <String, Object?>{'vendorId': vendors[i].id}),
                  onRemove: () => _unsave(SavedType.vendor, vendors[i].id),
                  last: i == vendors.length - 1,
                ),
            ],
          );
        case SavedSegment.packages:
          return Column(
            children: [
              for (var i = 0; i < packages.length; i++)
                switch (packages[i]) {
                  SavedPlannerPackage(:final pkg) => SavedPlannerRow(
                    pkg: pkg,
                    onOpen: () => _nav.push('CL-PLAN-01', params: <String, Object?>{'tier': pkg.tier.value}),
                    onRemove: () => _unsave(SavedType.package, pkg.id),
                    last: i == packages.length - 1,
                  ),
                  SavedHallPackage(:final pkg, :final venue) => SavedHallPackageRow(
                    pkg: pkg,
                    venue: venue,
                    guest: guest,
                    onOpen: () => _nav.push(
                      venue.channel == BookingChannel.externalLink ? 'CL-VENU-06' : 'CL-VENU-01',
                      params: <String, Object?>{'venueId': venue.id, 'from': 'saved'},
                    ),
                    onRemove: () => _unsave(SavedType.package, pkg.id),
                    last: i == packages.length - 1,
                  ),
                },
            ],
          );
      }
    }

    final body = Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (guest && !loading && error == null && counts.venues + counts.services + counts.packages > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
              child: DecoratedBox(
                key: const ValueKey<String>('saved.guest'),
                decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s1),
                  child: Row(
                    children: [
                      GzIcon(GzIcons.phone, size: GzIconSize.sm, color: c.iconSecondary),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(child: GzText(l.clientSavedCompareSavedGuestBanner, role: GzTextRole.bodyS)),
                      GzButton(
                        key: const ValueKey<String>('saved.guest.signin'),
                        label: l.clientSavedCompareSavedGuestSignIn,
                        variant: GzButtonVariant.tertiary,
                        onPressed: () => _nav.openSheet('CL-AUTH-01', options: const GzSheetOptions(params: <String, Object?>{'reason': 'save'})),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (offline)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: GzFactChip(
                  icon: GzIcons.clock,
                  small: true,
                  tone: GzFactTone.muted,
                  label: l.clientSavedCompareLastUpdated,
                  value: f.time(f.now()),
                ),
              ),
            ),
          tabs,
          if (problem != null && !offline)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
              child: GzErrorState(
                key: const ValueKey<String>('saved.error'),
                kind: gzProblemKind(problem),
                body: gzProblemMessage(lg, problem),
                fill: false,
                retrying: bundleAsync.isLoading,
                onRetry: () => ref.invalidate(savedBundleProvider),
              ),
            )
          else ...[
            if (!loading && _seg == SavedSegment.venues && counts.venues > 0)
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.controlSm),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                  child: Row(
                    children: [
                      Expanded(
                        child: brief.date != null
                            ? Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: GzFactRow(
                                  label: summaryName,
                                  children: [
                                    GzFactChip(icon: GzIcons.calendar, label: l.clientSavedCompareFactDate, value: dateText),
                                    GzFactChip(
                                      icon: GzIcons.checkCircle,
                                      label: l.clientSavedCompareFactFreeHalls,
                                      value: '${f.integer(free)}/${f.integer(counts.venues)}',
                                    ),
                                  ],
                                ),
                              )
                            : Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: GzButton(
                                  key: const ValueKey<String>('saved.setdate'),
                                  label: l.clientSavedCompareCompareSetDate,
                                  variant: GzButtonVariant.tertiary,
                                  iconStart: GzIcons.calendar,
                                  onPressed: () => _nav.openSheet('CL-DISC-02'),
                                ),
                              ),
                      ),
                      if (canSelect)
                        GzButton(
                          key: const ValueKey<String>('saved.select'),
                          label: _selecting ? lg.commonActionCancel : l.clientSavedCompareSavedSelect,
                          variant: GzButtonVariant.tertiary,
                          onPressed: () => setState(() => _selecting = !_selecting),
                        ),
                    ],
                  ),
                ),
              ),
            list(),
          ],
        ],
      ),
    );

    return GzPullToRefresh(
      onRefresh: () async {
        ref.invalidate(savedBundleProvider);
        try {
          await ref.read(savedBundleProvider.future);
        } on Object {
          // the screen shows its own error state
        }
      },
      child: GzScreen(
        top: GzTopBar(variant: GzTopBarVariant.largeTitle, back: GzTopBarBack.hide, title: l.clientSavedCompareSavedTitle),
        bottom: bottom,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (offline) GzBanner(message: lg.commonStateOffline, tone: GzBannerTone.offline),
            body,
          ],
        ),
      ),
    );
  }

  /// The standard price moved since the family last looked, so the saving they were shown moved with it.
  bool _savingChanged(VenueResult r, MoneyAmount? seen) {
    final p = r.price;
    if (p is! CardPriceExact || seen == null) return false;
    return p.voucher != null && p.amount.fils != seen.fils;
  }
}
