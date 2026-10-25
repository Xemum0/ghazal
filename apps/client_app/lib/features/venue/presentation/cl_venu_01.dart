import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, DecimalOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/venue_model.dart';
import '../application/venue_providers.dart';
import 'venue_actions.dart';
import 'venue_glyphs.dart';
import 'widgets/venue_hall.dart';
import 'widgets/venue_hero.dart';
import 'widgets/venue_money.dart' show VenueBarPrice;
import 'widgets/venue_sections.dart';
import 'widgets/venue_strip.dart';

/// CL-VENU-01 Venue detail. Covers CA-VDET-04..26, CA-BOOK-01, CA-CMP-01, CA-TOOL-01, CA-CHAT-02, CA-AUTH-09.
///
/// The decision screen of the voucher model: a full-bleed hero with the hairline progress, the serif name with rating, area and
/// two quiet badges, the ruled Your date strip, the Booking Thread before anything has happened, hall and package choice (two
/// prices each), facilities as glyph tiles, policy tiles, reviews, the map and similar halls, and a sticky bar that replaces the
/// tab bar with the three paths: Get voucher (or Send request when a ready voucher exists), Book visit, Contact. Works fully
/// for a guest; the account is asked at Get voucher. Text diet (ADR 0034): facts are glyph and figure.
class ClVenu01Screen extends ConsumerStatefulWidget {
  const ClVenu01Screen({super.key});

  @override
  ConsumerState<ClVenu01Screen> createState() => _ClVenu01State();
}

class _ClVenu01State extends ConsumerState<ClVenu01Screen> {
  int _heroIndex = 0;

  @override
  Widget build(BuildContext context) {
    final params = VenueParams.of(context.gzNav.params);
    final brief = ref.watch(searchBriefProvider);
    final pick = ref.watch(venuePickProvider(params.venueId));
    final vkey = venueKeyOf(params, brief, pick);
    final view = ref.watch(venueViewProvider(vkey));
    final guest = !ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final actions = VenueActions(context, ref, params.venueId);
    final favourite = ref.watch(isFavouriteProvider((SavedType.venue, params.venueId)));
    final compared = ref.watch(compareProvider.select((c) => c.contains(params.venueId)));
    final compareCount = ref.watch(compareProvider.select((c) => c.length));

    final topBar = GzTopBar(
      variant: GzTopBarVariant.transparent,
      actions: [
        GzTopBarAction(
          icon: GzIcons.compare,
          label: compared ? context.l10n.clientVenueSavedView : context.gzL10n.commonA11yCompareAdd,
          count: compareCount > 0 ? compareCount : null,
          pressed: compared,
          onPressed: actions.toggleCompare,
        ),
        GzTopBarAction(icon: GzIcons.share, label: context.gzL10n.commonActionShare, onPressed: actions.share),
        GzTopBarAction(
          icon: favourite ? GzIcons.heartFill : GzIcons.heart,
          label: favourite ? context.gzL10n.commonA11yFavouriteRemove : context.gzL10n.commonA11yFavouriteAdd,
          pressed: favourite,
          onPressed: actions.toggleFavourite,
        ),
      ],
    );

    return GzScreen(
      top: topBar,
      topOverlay: true,
      bottom: view.hasValue ? _Bar(view: view.value!, guest: guest, offline: false, actions: actions) : null,
      child: _isDelisted(view)
          ? _DelistedBody(params: params)
          : GzAsyncView<VenueView>(
              value: view,
              onRetry: () => ref.invalidate(venueViewProvider(vkey)),
              loading: _DetailSkeleton(key: ValueKey<String>('venue.${params.venueId}.loading')),
              data: (v) => _Body(
                view: v,
                vkey: vkey,
                guest: guest,
                actions: actions,
                heroIndex: _heroIndex,
                onHeroIndex: (i) => setState(() => _heroIndex = i),
                onPickHall: (id) => ref.read(venuePickProvider(params.venueId).notifier).pickHall(id),
                onPickSession: (_) {},
                onPickPackage: (id) => ref.read(venuePickProvider(params.venueId).notifier).pickPackage(id),
              ),
            ),
    );
  }
}

/// A NOT_FOUND answer reads as a dead universal link, not an error state.
bool _isDelisted(AsyncValue<VenueView> view) {
  final e = view.error;
  return view.hasError && !view.hasValue && e is ApiProblem && e.code == ApiProblemCode.notFound;
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      VenueHero.loading(context),
      const GzSkeleton(inlineSize: 24, blockSize: 1),
      const Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzSkeleton(blockSize: 40),
            SizedBox(height: GzSpace.s3),
            GzSkeleton(inlineSize: 200, blockSize: 20),
          ],
        ),
      ),
      const SizedBox(height: GzSpace.s4),
      VenueDateStrip.loading(context),
      const SizedBox(height: GzSpace.s4),
      const Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
        child: Column(
          children: [
            GzSkeleton(blockSize: 96),
            SizedBox(height: GzSpace.s3),
            GzSkeletonText(lines: 3),
            SizedBox(height: GzSpace.s3),
            GzSkeleton(blockSize: 160),
          ],
        ),
      ),
    ],
  );
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.view,
    required this.vkey,
    required this.guest,
    required this.actions,
    required this.heroIndex,
    required this.onHeroIndex,
    required this.onPickHall,
    required this.onPickSession,
    required this.onPickPackage,
  });

  final VenueView view;
  final VenueKey vkey;
  final bool guest;
  final VenueActions actions;
  final int heroIndex;
  final ValueChanged<int> onHeroIndex;
  final ValueChanged<String> onPickHall;
  final ValueChanged<String?> onPickSession;
  final ValueChanged<String> onPickPackage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final venue = view.venue;
    final gallery = VenueGallery(context, venue);
    final quote = QuoteCarry(
      venueId: venue.id,
      hallId: view.hall.id,
      packageId: view.row?.pkg.id,
      date: view.day?.date,
      guests: view.prices?.billedGuests,
      audience: view.audience,
    );
    final brief = ref.watch(searchBriefProvider);
    return Column(
      key: ValueKey<String>('venue.${venue.id}.body'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          child: VenueHero(
            gallery: gallery,
            index: heroIndex,
            onIndexChanged: onHeroIndex,
            onOpen: (i) => context.gzNav.push('CL-VENU-02', params: <String, Object?>{'venueId': venue.id, 'index': i}),
            label: l.clientVenueHeroLabel(context.bi(venue.name)),
            heroGroup: 'venue-hero-${venue.id}',
          ),
        ),
        VenueHeader(venue: venue, area: view.areaName, governorate: view.governorateName),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s5),
          child: VenueDateStrip(
            date: view.day?.date ?? brief.date,
            guests: brief.guests,
            status: view.status,
            prices: view.prices,
            row: view.row,
            guest: guest,
            owned: view.owned != null,
            windowTitle: view.windowTitle == null ? null : context.bi(view.windowTitle!),
            nearest: view.nearest,
            onOpenCalendar: () => actions.openCalendar(view.hall.id),
            onEditGuests: actions.editBrief,
            onHow: () => actions.openHow(quote),
            onPickDate: (_) {},
          ),
        ),
        if (view.prices == null || view.prices!.eligible || view.owned != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.section, start: GzSpace.gutter, end: GzSpace.gutter),
            child: VenueThreadPreview(
              note: l.clientVenueThreadNote(context.gzFormat.money(view.feeFils), context.bi(venue.name)),
              replyHours: venue.response?.usuallyRepliesHours,
              onViewVoucher: view.owned == null
                  ? null
                  : () => context.gzNav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': view.owned!.id}),
            ),
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.section, start: GzSpace.gutter, end: GzSpace.gutter),
          child: VenueHallSection(
            halls: view.halls,
            hall: view.hall,
            onHall: onPickHall,
            day: view.day,
            date: view.day?.date ?? brief.date,
            sessionId: null,
            onSession: onPickSession,
          ),
        ),
        VenuePackagesSection(
          view: view,
          date: view.day?.date ?? brief.date,
          guests: brief.guests,
          guest: guest,
          onPick: onPickPackage,
          actions: actions,
        ),
        VenueFacilitiesSection(venue: venue, audience: view.audience),
        VenuePoliciesSection(venue: venue, hall: view.hall, actions: actions),
        _ReviewsPreview(venueId: venue.id, venueName: context.bi(venue.name), rating: venue.rating, actions: actions),
        VenueLocationSection(venue: venue, area: view.areaName, origin: view.origin, actions: actions),
        _Similar(vkey: vkey, actions: actions),
        const SizedBox(height: GzSpace.s12),
      ],
    );
  }
}

/// The rating summary (tappable) with the one preview review: the full history lives on CL-RVRW-01.
class _ReviewsPreview extends ConsumerWidget {
  const _ReviewsPreview({required this.venueId, required this.venueName, required this.rating, required this.actions});

  final String venueId;
  final String venueName;
  final RatingSummary rating;
  final VenueActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final reviews = ref.watch(venueReviewsProvider(venueId));
    final items = reviews.value ?? const <Review>[];
    final has = rating.average != null && rating.count > 0;
    if (!has && reviews.hasValue && items.isEmpty) return const SizedBox.shrink();
    final preview = items.where((r) => r.ownerReply != null).firstOrNull ?? items.firstOrNull;
    return VenueSection(
      title: l.clientVenueReviewsTitle,
      keyId: 'venue.reviews',
      onSeeAll: !has ? null : actions.openReviews,
      seeAllLabel: !has ? null : l.clientVenueReviewsAll(f.integer(rating.count)),
      child: reviews.isLoading && items.isEmpty
          ? const Column(
              children: [
                GzSkeleton(blockSize: 120),
                SizedBox(height: GzSpace.s3),
                GzSkeleton(blockSize: 120),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (has)
                  GzPressable(
                    onPressed: actions.openReviews,
                    semanticLabel: l.clientVenueReviewsAll(f.integer(rating.count)),
                    scale: 1,
                    borderRadius: GzRadius.mdAll,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GzNum(f.plain(f.number(rating.average!, const DecimalOptions(minFraction: 1, maxFraction: 1))), role: GzTextRole.fig3xl),
                            const SizedBox(width: GzSpace.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GzRating(value: rating.average!, showValue: false),
                                  GzText(
                                    '(${f.integer(rating.count)})',
                                    role: GzTextRole.caption,
                                    color: context.gz.colors.textSecondary,
                                    figures: true,
                                  ),
                                ],
                              ),
                            ),
                            const GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, tone: GzIconTone.secondary),
                          ],
                        ),
                        if (rating.categories != null) ...[
                          const SizedBox(height: GzSpace.s3),
                          GzFactRow(
                            label: l.clientVenueReviewsTitle,
                            children: [
                              _CatScore(icon: GzIcons.hall, label: l.clientVenueCatVenue, value: rating.categories!.venue),
                              _CatScore(icon: GzIcons.catering, label: l.clientVenueCatFood, value: rating.categories!.food),
                              _CatScore(icon: GzIcons.staff, label: l.clientVenueCatService, value: rating.categories!.service),
                              _CatScore(icon: GzIcons.coins, label: l.clientVenueCatValue, value: rating.categories!.value),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                if (preview != null) ...[
                  if (has) const SizedBox(height: GzSpace.s3),
                  RepaintBoundary(
                    child: GzReviewCard(review: preview, venueName: venueName),
                  ),
                ],
              ],
            ),
    );
  }
}

/// One rating category: the glyph and its figure (the full name stays the accessible name).
class _CatScore extends StatelessWidget {
  const _CatScore({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    return GzFactChip(
      icon: icon,
      label: label,
      valueWidget: GzText(
        f.plain(f.number(value, const DecimalOptions(minFraction: 1, maxFraction: 1))),
        role: GzTextRole.figBodyS,
        color: context.gz.colors.textStrong,
        figures: true,
      ),
    );
  }
}

class _Similar extends ConsumerWidget {
  const _Similar({required this.vkey, required this.actions});

  final VenueKey vkey;
  final VenueActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(searchBriefProvider);
    final rows = ref.watch(venueSimilarProvider(vkey)).value ?? const <VenueResult>[];
    return VenueRail(rows: rows, title: context.l10n.clientVenueSimilarTitle, date: brief.date, actions: actions);
  }
}

/// The sticky bar that replaces the tab bar: Get voucher (or Send request with a ready voucher), Book visit, Contact.
class _Bar extends StatelessWidget {
  const _Bar({required this.view, required this.guest, required this.offline, required this.actions});

  final VenueView view;
  final bool guest;
  final bool offline;
  final VenueActions actions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final priced = view.prices != null && (view.status == DayStatusKind.available || view.status == DayStatusKind.held);
    final voucherPath = priced && view.prices!.eligible;
    final contactPrimary = priced && !view.prices!.eligible;
    final guestsMissing = (view.status == DayStatusKind.available || view.status == DayStatusKind.held) && view.prices == null;
    final carry = QuoteCarry(
      venueId: view.venue.id,
      hallId: view.hall.id,
      packageId: view.row?.pkg.id,
      date: view.day?.date,
      guests: view.prices?.billedGuests,
      audience: view.audience,
    );
    final GzActionBarAction action;
    if (offline) {
      action = GzActionBarAction(label: l.clientVenueCtaOffline, iconEnd: GzIcons.offline, disabled: true);
    } else if (view.status == DayStatusKind.none) {
      action = GzActionBarAction(label: l.clientVenueCtaChooseDate, iconEnd: GzIcons.calendar, onPressed: () => actions.openCalendar(view.hall.id));
    } else if (view.status == DayStatusKind.unavailable) {
      action = GzActionBarAction(label: l.clientVenueCtaSeeDates, iconEnd: GzIcons.calendar, onPressed: () => actions.openCalendar(view.hall.id));
    } else if (guestsMissing) {
      action = GzActionBarAction(label: l.clientVenueCtaChangeGuests, iconEnd: GzIcons.usersThree, onPressed: actions.editBrief);
    } else if (contactPrimary) {
      action = GzActionBarAction(label: l.clientVenueCtaContact, iconEnd: GzIcons.chat, onPressed: actions.contactVenue);
    } else if (view.owned != null && voucherPath) {
      action = GzActionBarAction(label: l.clientVenueCtaSendRequest, iconEnd: GzIcons.send, onPressed: () => actions.sendRequest(carry, view.owned!));
    } else {
      action = GzActionBarAction(label: l.clientVenueCtaGetVoucher, iconEnd: GzIcons.ticket, onPressed: () => actions.getVoucher(carry));
    }
    final getsVoucher =
        !offline &&
        view.status != DayStatusKind.none &&
        view.status != DayStatusKind.unavailable &&
        !guestsMissing &&
        !contactPrimary &&
        !(view.owned != null && voucherPath);
    return GzActionBar(
      action: action,
      summaryValue: getsVoucher ? VenueBarPrice(glyph: GzIcons.ticket, label: l.commonVoucherPrice, fils: view.feeFils) : null,
      noteWidget: offline
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (view.visitOpen)
                  GzButton(
                    label: l.clientVenueCtaVisit,
                    variant: GzButtonVariant.tertiary,
                    iconStart: GzIcons.calendarCheck,
                    onPressed: actions.bookVisit,
                  )
                else
                  Semantics(
                    label: l.clientVenueVisitNone,
                    child: ExcludeSemantics(
                      child: GzButton(label: l.clientVenueCtaVisit, variant: GzButtonVariant.tertiary, iconStart: GzIcons.calendarX, onPressed: null),
                    ),
                  ),
                if (!contactPrimary)
                  GzButton(
                    label: l.clientVenueCtaContact,
                    variant: GzButtonVariant.tertiary,
                    iconStart: GzIcons.chat,
                    onPressed: actions.contactVenue,
                  ),
              ],
            ),
    );
  }
}

/// A dead universal link: "This venue is no longer listed" with nearby halls (content for the outer screen, not a screen).
class _DelistedBody extends ConsumerWidget {
  const _DelistedBody({required this.params});

  final VenueParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final brief = ref.watch(searchBriefProvider);
    final rows =
        ref
            .watch(
              venueSimilarProvider(const VenueKey(venueId: kHeroVenueId, hallId: null, packageId: null, date: null, guests: null, audience: null)),
            )
            .value ??
        const <VenueResult>[];
    final actions = VenueActions(context, ref, kHeroVenueId);
    return Column(
      key: ValueKey<String>('venue.${params.venueId}.delisted'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.section),
          child: GzEmptyState(
            illustration: GzIllustrationName.noResult,
            title: l.clientVenueDelistedTitle,
            action: GzStateAction(
              label: l.clientVenueDelistedCta,
              variant: GzButtonVariant.primary,
              onPressed: () => context.gzNav.switchTab('discover'),
            ),
          ),
        ),
        VenueRail(rows: rows, title: l.clientVenueSimilarTitle, date: brief.date, actions: actions),
      ],
    );
  }
}

// Edges (inventory navigatesTo): 'CL-VENU-02' (the hero opens the viewer), 'CL-VENU-03' (the date strip opens the calendar sheet),
// 'CL-VENU-04' (a package opens its sheet), 'CL-VENU-05' (the policy tiles open the policies sheet), 'CL-RVRW-01' (reviews),
// 'CL-BOOK-01' (Send request with a ready voucher), 'CL-MSGS-02' (Contact the venue opens the chat), 'CL-SAVD-02' (the compare
// badge opens the tray, 'CL-SAVD-03' when it is full), 'CL-AUTH-01' (the guest gate, opened internally by requireSignIn),
// 'CL-DISC-02' (the Brief editor), 'CL-VCHR-01' (Get voucher and How the voucher works), 'CL-VCHR-03' (a ready voucher),
// 'CL-VIST-01' (Book a visit).
