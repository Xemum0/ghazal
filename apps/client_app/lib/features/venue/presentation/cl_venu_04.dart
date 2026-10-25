import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show sessionProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/venue_model.dart';
import '../application/venue_providers.dart';
import 'venue_actions.dart';
import 'venue_glyphs.dart';
import 'widgets/venue_money.dart' show QuietMoney;
import 'widgets/venue_package_rate.dart';
import 'widgets/venue_sheets.dart' show VenueFootRule, VenueSheetHead;

/// Inclusions shown before the count: the sheet is about what is included, the rest wait behind one chevron.
const int kShownInclusions = 4;

/// CL-VENU-04 Package (sheet). Covers CA-VDET-07, CA-VDET-08, CA-VDET-12..14, CA-BOOK-04, CA-BOOK-14, CA-VCH-02, CA-VCH-03.
///
/// Everything one package includes and what it costs for the Brief: inclusions, in-house menu summary, per-guest rate,
/// guest limits and the date-dependent rate. Selecting continues into booking with the package carried over.
class ClVenu04Screen extends ConsumerStatefulWidget {
  const ClVenu04Screen({super.key});

  @override
  ConsumerState<ClVenu04Screen> createState() => _ClVenu04State();
}

class _ClVenu04State extends ConsumerState<ClVenu04Screen> {
  bool _allIncluded = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final params = VenueParams.of(context.gzNav.params);
    final brief = ref.watch(searchBriefProvider);
    final pick = ref.watch(venuePickProvider(params.venueId));
    final vkey = venueKeyOf(VenueParams(venueId: params.venueId, hallId: params.hallId, packageId: params.packageId ?? pick.packageId), brief, pick);
    final view = ref.watch(venueViewProvider(vkey));
    final guest = !ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final actions = VenueActions(context, ref, params.venueId);
    final data = view.value;
    final row = data?.rows.where((r) => r.pkg.id == vkey.packageId).firstOrNull ?? data?.row;
    final pkg = row?.pkg;
    final saved = ref.watch(isFavouriteProvider((SavedType.package, pkg?.id ?? '')));

    return Column(
      key: ValueKey<String>('venue.pkg.${params.packageId ?? params.venueId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: VenueSheetHead(title: pkg == null ? l.clientVenuePackagesTitle : context.bi(pkg.name), onClose: () => context.gzNav.closeSheet()),
        ),
        if (view.isLoading && data == null)
          const Column(
            children: [
              GzSkeleton(inlineSize: 200, blockSize: 28),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(blockSize: 72),
              SizedBox(height: GzSpace.s3),
              GzSkeletonText(lines: 5),
            ],
          )
        else if (data == null || pkg == null || row == null)
          GzEmptyState(
            illustration: GzIllustrationName.noResult,
            title: l.clientVenuePackagesNone,
            action: GzStateAction(
              label: l.clientVenueSeeAllDates,
              variant: GzButtonVariant.primary,
              onPressed: () => actions.openCalendar(data?.hall.id),
            ),
          )
        else
          _PkgBody(
            view: data,
            row: row,
            guest: guest,
            actions: actions,
            saved: saved,
            allIncluded: _allIncluded,
            onToggleIncluded: () => setState(() => _allIncluded = !_allIncluded),
            onToggleSave: () => _toggleSave(pkg.id, saved),
          ),
        const SizedBox(height: GzSpace.s4),
      ],
    );
  }

  Future<void> _toggleSave(String packageId, bool saved) async {
    final l10n = context.l10n;
    final savedMsg = context.gzL10n.commonStateSaved;
    final nav = context.gzNav;
    final notifier = ref.read(favouritesProvider.notifier);
    final on = await notifier.toggle(SavedType.package, packageId);
    if (!mounted) return;
    nav.toast(
      GzToastSpec(
        message: on ? savedMsg : l10n.clientVenueSavedRemoved,
        icon: on ? GzIcons.heartFill : null,
        action: on ? GzToastAction(label: l10n.clientVenueSavedView, onPressed: () => nav.switchTab('saved')) : null,
      ),
    );
  }
}

class _PkgBody extends StatelessWidget {
  const _PkgBody({
    required this.view,
    required this.row,
    required this.guest,
    required this.actions,
    required this.saved,
    required this.allIncluded,
    required this.onToggleIncluded,
    required this.onToggleSave,
  });

  final VenueView view;
  final PackageRow row;
  final bool guest;
  final VenueActions actions;
  final bool saved;
  final bool allIncluded;
  final VoidCallback onToggleIncluded;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pkg = row.pkg;
    final price = row.price;
    final unavailable = view.status == DayStatusKind.unavailable;
    final overCapacity = packageOverCapacity(view, row);
    final eligible = price != null && price.voucherOffered;
    final carry = QuoteCarry(
      venueId: view.venue.id,
      hallId: view.hall.id,
      packageId: pkg.id,
      date: view.day?.date,
      guests: view.prices?.billedGuests,
      audience: row.audience,
    );
    final extras = view.detail.extras
        .where((e) => e.active && (e.audiences.isEmpty || e.audiences.contains(row.audience)) && !e.includedInPackageIds.contains(pkg.id))
        .take(4)
        .toList();
    final shown = allIncluded ? pkg.inclusions : pkg.inclusions.take(kShownInclusions).toList();
    final hidden = pkg.inclusions.length - kShownInclusions;
    final c = context.gz.colors;
    final getsVoucher = !unavailable && !overCapacity && view.day?.date != null && eligible && view.owned == null;

    GzActionBarAction action;
    IconData? endIcon;
    if (overCapacity && !unavailable) {
      action = GzActionBarAction(label: l.clientVenueCtaChangeGuests, onPressed: actions.editBrief);
      endIcon = GzIcons.calendar;
    } else if (unavailable) {
      action = GzActionBarAction(label: l.clientVenueCtaSeeDates, onPressed: () => actions.openCalendar(view.hall.id));
      endIcon = GzIcons.calendar;
    } else if (view.day?.date == null) {
      action = GzActionBarAction(label: l.clientVenueCtaChooseDate, onPressed: () => actions.openCalendar(view.hall.id));
      endIcon = GzIcons.calendar;
    } else if (!eligible) {
      action = GzActionBarAction(label: l.clientVenueCtaContact, onPressed: actions.contactVenue);
    } else if (view.owned != null) {
      action = GzActionBarAction(label: l.clientVenueCtaSendRequest, onPressed: () => actions.sendRequest(carry, view.owned!));
    } else {
      action = GzActionBarAction(label: l.clientVenueCtaGetVoucher, onPressed: () => actions.getVoucher(carry));
      endIcon = GzIcons.ticket;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PackageRateBlock(view: view, row: row, guest: guest),
        if (pkg.inclusions.isNotEmpty) ...[
          const SizedBox(height: GzSpace.s5),
          Semantics(
            container: true,
            label: l.clientVenuePkgIncludes,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzText(l.clientVenuePkgIncludes, role: GzTextRole.title, color: c.textStrong, header: true),
                const SizedBox(height: GzSpace.s3),
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(height: GzSpace.s3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GzIcon(GzIcons.check, size: GzIconSize.sm, tone: GzIconTone.success),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(
                        child: GzText(context.bi(shown[i]), role: GzTextRole.bodyS, color: c.textPrimary, figures: true),
                      ),
                    ],
                  ),
                ],
                if (hidden > 0) ...[
                  const SizedBox(height: GzSpace.s3),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GzButton(
                      label: allIncluded ? context.gzL10n.commonActionShowLess : GzBidi.isolateLtr('+${context.gzFormat.integer(hidden)}'),
                      variant: GzButtonVariant.tertiary,
                      iconEnd: allIncluded ? GzIcons.chevronUp : GzIcons.chevronDown,
                      onPressed: onToggleIncluded,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: GzSpace.s5),
        GzAccordion(
          items: [
            GzAccordionItem(
              id: 'menu',
              title: l.clientVenuePkgMenu,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GzText(context.bi(pkg.description), role: GzTextRole.bodyS, color: c.textPrimary),
                  for (final n in pkg.notes) ...[
                    const SizedBox(height: GzSpace.s3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsetsDirectional.only(top: GzStroke.thread),
                          child: GzIcon(GzIcons.info, size: GzIconSize.xs, tone: GzIconTone.secondary),
                        ),
                        const SizedBox(width: GzSpace.s2),
                        Expanded(
                          child: GzText(context.bi(n), role: GzTextRole.bodyS, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (extras.isNotEmpty)
              GzAccordionItem(
                id: 'extras',
                title: l.clientVenuePkgExtras,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < extras.length; i++) ...[
                      if (i > 0) const SizedBox(height: GzSpace.s3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const GzIcon(GzIcons.plus, size: GzIconSize.sm, tone: GzIconTone.secondary),
                          const SizedBox(width: GzSpace.s3),
                          Expanded(
                            child: GzText(context.bi(extras[i].name), role: GzTextRole.bodyS, color: c.textPrimary),
                          ),
                          QuietMoney(fils: (extras[i].priceMin ?? extras[i].price).fils),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        if (view.visitOpen) ...[
          const SizedBox(height: GzSpace.s5),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzButton(
              label: l.clientVenueCtaVisit,
              variant: GzButtonVariant.tertiary,
              iconStart: GzIcons.calendarCheck,
              onPressed: actions.bookVisit,
            ),
          ),
        ],
        const SizedBox(height: GzSpace.s4),
        GzSheetFooter(
          child: VenueFootRule(
            child: Row(
              children: [
                GzIconButton(
                  icon: saved ? GzIcons.heartFill : GzIcons.heart,
                  label: saved ? l.clientVenuePkgSaved : l.clientVenuePkgSave,
                  variant: GzIconButtonVariant.outline,
                  active: saved,
                  onPressed: onToggleSave,
                ),
                if (getsVoucher) ...[
                  const SizedBox(width: GzSpace.s3),
                  GzIcon(GzIcons.ticket, size: GzIconSize.sm, tone: GzIconTone.secondary, semanticLabel: context.gzL10n.commonVoucher),
                  const SizedBox(width: GzSpace.s2),
                  GzPrice(fils: view.feeFils, size: GzPriceSize.display),
                ],
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzButton(label: action.label, iconEnd: endIcon, fullWidth: true, onPressed: action.onPressed),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Edges (inventory navigatesTo): 'CL-BOOK-01' (Send request with a ready voucher), 'CL-VENU-01' (closing the sheet returns),
// 'CL-SAVD-01' (the save toast offers Saved), 'CL-VCHR-01' (Get voucher bound to the package), 'CL-VIST-01' (Book a visit).
