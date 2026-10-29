import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/venue_providers.dart';
import 'venue_actions.dart';
import 'venue_glyphs.dart';
import 'widgets/venue_hero.dart';
import 'widgets/venue_money.dart' show VenueBarPrice;
import 'widgets/venue_sections.dart' show VenueLocationSection, VenueSection;
import 'widgets/venue_sheets.dart';

/// A self-reported government-hall booking (record only, not a Ghazal booking): the date and the fee paid on the official channel.
@immutable
final class GovReport {
  const GovReport({required this.date, required this.fils});

  final LocalDate date;
  final int fils;
}

final _govReportProvider = NotifierProvider.autoDispose.family<_GovReportNotifier, GovReport?, String>(_GovReportNotifier.new);

class _GovReportNotifier extends Notifier<GovReport?> {
  _GovReportNotifier(this.venueId);

  final String venueId;

  @override
  GovReport? build() => null;

  void save(LocalDate date, int fils) => state = GovReport(date: date, fils: fils);
}

/// CL-VENU-06 Government hall. Covers CA-VDET-04, CA-VDET-07..10, CA-VDET-22, CA-HOME-07, CA-HOME-08, CA-CMP-10, CA-TOOL-17.
///
/// The distinct detail variant of a Governmental Facility: an honest listing with the official fee schedule and rules, and a
/// hand-off to the official channel. No voucher, no Ghazal request, no visit, no instant tag, no availability claim, no reviews.
class ClVenu06Screen extends ConsumerStatefulWidget {
  const ClVenu06Screen({super.key});

  @override
  ConsumerState<ClVenu06Screen> createState() => _ClVenu06State();
}

class _ClVenu06State extends ConsumerState<ClVenu06Screen> {
  int _heroIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rawId = (context.gzNav.params['venueId'] as String?) ?? kHeroGovVenueId;
    final detail = ref.watch(_govDetailProvider(rawId));
    final favourite = ref.watch(isFavouriteProvider((SavedType.venue, rawId)));
    final compared = ref.watch(compareProvider.select((c) => c.contains(rawId)));
    final compareCount = ref.watch(compareProvider.select((c) => c.length));
    final govActions = VenueActions(context, ref, rawId);

    return GzAsyncView<_GovDetail>(
      value: detail,
      onRetry: () => ref.invalidate(_govDetailProvider(rawId)),
      loading: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VenueHero.loading(context),
          const SizedBox(height: GzSpace.s4),
          const Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: Column(
              children: [
                GzSkeleton(blockSize: 40),
                SizedBox(height: GzSpace.s3),
                GzSkeleton(inlineSize: 200, blockSize: 20),
              ],
            ),
          ),
        ],
      ),
      data: (d) {
        final venue = d.venue;
        if (venue.officialFees == null) {
          return GzScreen(
            top: const GzTopBar(),
            child: Padding(
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
          );
        }
        final actions = VenueActions(context, ref, venue.id);
        final gallery = VenueGallery(context, venue);
        final report = ref.watch(_govReportProvider(venue.id));
        return GzScreen(
          top: GzTopBar(
            variant: GzTopBarVariant.transparent,
            actions: [
              GzTopBarAction(
                icon: GzIcons.compare,
                label: compared ? l.clientVenueSavedView : context.gzL10n.commonA11yCompareAdd,
                count: compareCount > 0 ? compareCount : null,
                pressed: compared,
                onPressed: govActions.toggleCompare,
              ),
              GzTopBarAction(icon: GzIcons.share, label: context.gzL10n.commonActionShare, onPressed: govActions.share),
              GzTopBarAction(
                icon: favourite ? GzIcons.heartFill : GzIcons.heart,
                label: favourite ? context.gzL10n.commonA11yFavouriteRemove : context.gzL10n.commonA11yFavouriteAdd,
                pressed: favourite,
                onPressed: govActions.toggleFavourite,
              ),
            ],
          ),
          topOverlay: true,
          bottom: GzActionBar(
            action: GzActionBarAction(label: l.clientVenueGovCtaOfficial, iconEnd: GzIcons.externalLink, onPressed: () => _leave(context)),
            summaryValue: VenueBarPrice(glyph: GzIcons.coins, label: context.gzL10n.commonMoneyRentalFee, fils: venue.officialFees!.rent.fils),
          ),
          child: Column(
            key: ValueKey<String>('venue.gov.${venue.id}.body'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                child: VenueHero(
                  gallery: gallery,
                  index: _heroIndex,
                  onIndexChanged: (i) => setState(() => _heroIndex = i),
                  onOpen: (i) => context.gzNav.push('CL-VENU-02', params: <String, Object?>{'venueId': venue.id, 'index': i}),
                  label: l.clientVenueHeroLabel(context.bi(venue.name)),
                  heroGroup: 'venue-hero-${venue.id}',
                ),
              ),
              VenueHeader(
                venue: venue,
                area: d.areaName,
                governorate: d.governorateName,
                hideRating: true,
                capacity: venue.halls.firstOrNull?.capacity,
              ),
              VenueSection(
                title: l.clientVenueGovFeesTitle,
                keyId: 'gov.fees',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FeeRow(icon: GzIcons.coins, label: context.gzL10n.commonMoneyRentalFee, fils: venue.officialFees!.rent.fils),
                    const SizedBox(height: GzSpace.s2),
                    _FeeRow(
                      icon: GzIcons.shieldCheck,
                      label: l.clientVenueGovSecurity,
                      fils: venue.officialFees!.securityDeposit.fils,
                      badge: l.clientVenueGovRefundable,
                    ),
                    const SizedBox(height: GzSpace.s3),
                    Row(
                      children: [
                        GzBadge(label: l.clientVenueGovHallOnlyShort, variant: GzBadgeVariant.quiet, icon: GzIcons.hall),
                        const SizedBox(width: GzSpace.s2),
                        GzInfoButton(
                          title: l.clientVenueGovFeesInfoTitle,
                          label: l.clientVenueGovFeesInfoTitle,
                          paragraphs: [l.clientVenueGovHallOnly, context.bi(venue.officialFees!.note)],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              VenueSection(
                title: l.clientVenueGovRulesTitle,
                keyId: 'gov.rules',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GzIconListRow(flush: true, icon: GzIcons.calendarX, title: l.clientVenueGovRuleNoChange),
                    GzIconListRow(
                      flush: true,
                      icon: GzIcons.timer,
                      title: l.clientVenueGovRulePay,
                      trailing: GzInfoButton(
                        title: l.clientVenueGovRulesTitle,
                        label: l.clientVenueGovRulePay,
                        paragraphs: [l.clientVenueGovRulePayInfo],
                      ),
                    ),
                    GzIconListRow(flush: true, last: true, icon: GzIcons.card, title: l.clientVenueGovRuleKnet),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, start: GzSpace.gutter, end: GzSpace.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GzIconListRow(
                      flush: true,
                      icon: GzIcons.calendar,
                      title: l.clientVenueGovAvail,
                      trailing: const GzIcon(GzIcons.externalLink, size: GzIconSize.sm, tone: GzIconTone.secondary),
                      onPressed: () => _leave(context),
                    ),
                    if (report != null) ...[
                      GzIconListRow(
                        flush: true,
                        icon: GzIcons.checkCircle,
                        title: shortDay(context.gzFormat, report.date),
                        trailing: const GzIcon(GzIcons.edit, size: GzIconSize.sm, tone: GzIconTone.secondary),
                        onPressed: () => _openSelfReport(context, ref, venue, report),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: GzButton(
                          label: l.clientVenueGovSelfView,
                          variant: GzButtonVariant.tertiary,
                          iconEnd: GzIcons.chevronRight,
                          onPressed: () => context.gzNav.switchTab('my-wedding'),
                        ),
                      ),
                    ] else
                      GzIconListRow(
                        flush: true,
                        icon: GzIcons.calendarCheck,
                        title: l.clientVenueGovSelfLink,
                        chevron: true,
                        onPressed: () => _openSelfReport(context, ref, venue, null),
                      ),
                    GzAsideInfo(
                      icon: GzIcons.ticket,
                      word: l.clientVenueGovWhyTitle,
                      title: l.clientVenueGovWhyTitle,
                      paragraphs: [l.clientVenueGovWhyBody],
                    ),
                  ],
                ),
              ),
              VenueLocationSection(venue: venue, area: d.areaName, origin: null, actions: actions),
              if (venue.faq.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, start: GzSpace.gutter, end: GzSpace.gutter),
                  child: GzIconListRow(
                    flush: true,
                    last: true,
                    icon: GzIcons.help,
                    title: l.clientVenueFaqTitle,
                    chevron: true,
                    onPressed: () => context.gzNav.openSheetBuilder(
                      (_) => GzFaqAccordion(items: venue.faq),
                      options: GzSheetOptions(title: l.clientVenueFaqTitle),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.s12),
                child: Center(
                  child: GzButton(
                    label: l.clientVenueGovBrowse,
                    variant: GzButtonVariant.tertiary,
                    iconStart: GzIcons.search,
                    onPressed: () => context.gzNav.push('CL-DISC-03'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _leave(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    nav
        .openDialog(
          GzDialogSpec(
            title: l.clientVenueGovLeaveTitle,
            body: l.clientVenueGovLeaveBody,
            icon: GzIcons.externalLink,
            confirmLabel: context.gzL10n.commonActionContinue,
            cancelLabel: context.gzL10n.commonActionCancel,
          ),
        )
        .then((answer) {
          if (answer == GzDialogResult.confirm) nav.toast(GzToastSpec(message: l.clientVenueGovLeaveToast, icon: GzIcons.externalLink));
        });
  }

  void _openSelfReport(BuildContext context, WidgetRef ref, Venue venue, GovReport? report) {
    final l = context.l10n;
    final nav = context.gzNav;
    nav.openSheetBuilder(
      (_) => VenueSelfReportSheet(
        defaultDate: report?.date ?? LocalDate(2027, 1, 14),
        defaultFils: report?.fils ?? venue.officialFees!.rent.fils,
        onSave: (date, fils) {
          ref.read(_govReportProvider(venue.id).notifier).save(date, fils);
          nav.closeSheet();
          nav.toast(GzToastSpec(message: l.clientVenueGovSelfToast, icon: GzIcons.check, tone: GzToastTone.success));
        },
      ),
      options: GzSheetOptions(title: l.clientVenueGovSelfTitle),
    );
  }
}

/// The venue of the page with its area names: the requested one when it carries official fees, else the hero government hall.
final _govDetailProvider = FutureProvider.autoDispose.family<_GovDetail, String>((ref, venueId) async {
  final venues = ref.watch(venuesRepositoryProvider);
  final areas = await ref.watch(venueAreasProvider.future);
  Future<Venue> load(String id) async => (await venues.getVenue(venueId: id)).venue;
  Venue venue;
  try {
    venue = await load(venueId);
  } on Object {
    venue = await load(kHeroGovVenueId);
  }
  if (venue.officialFees == null) venue = await load(kHeroGovVenueId);
  LocalizedText? named(String id) => areas.areas.where((a) => a.id == id).firstOrNull?.name;
  LocalizedText? govd(String id) => areas.governorates.where((g) => g.id == id).firstOrNull?.name;
  return _GovDetail(venue: venue, areaName: named(venue.areaId), governorateName: govd(venue.governorateId));
});

/// The venue of the page with its area names.
@immutable
final class _GovDetail {
  const _GovDetail({required this.venue, required this.areaName, required this.governorateName});

  final Venue venue;
  final LocalizedText? areaName;
  final LocalizedText? governorateName;
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.icon, required this.label, required this.fils, this.badge});

  final IconData icon;
  final String label;
  final int fils;
  final String? badge;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: Row(
      children: [
        GzIcon(icon, size: GzIconSize.md, tone: GzIconTone.secondary),
        if (badge != null) ...[const SizedBox(width: GzSpace.s2), GzBadge(label: badge!, variant: GzBadgeVariant.outline, icon: GzIcons.undo)],
        const Spacer(),
        GzPrice(fils: fils, size: GzPriceSize.total),
      ],
    ),
  );
}

// Edges (inventory navigatesTo): 'CL-VENU-02' (the hero opens the viewer; no link to the Services hub, ADR 0038),
// 'CL-DISC-03' (Browse halls), 'CL-WEDD-01' (a self-report views in My Wedding, through switchTab('my-wedding')).
