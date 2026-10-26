import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GateReason, GateResume, WidgetSessionGate, sessionProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart';
import '../../../../l10n/l10n.dart';
import '../../application/discover_regions.dart';

/// The venue card as Discover draws it, with its behaviour wired once (Home rails, Results, the map carousel): the whole card opens the
/// venue (a governmental facility its own detail), the heart saves (the third heart of a guest raises the once-only sign-up nudge, ADR 0007
/// D10), the compare toggle fills the tray (a fourth add opens "Replace which one?", ADR 0009 D1). A signed-out visitor sees the standard
/// price and a locked voucher line.
class DiscoverVenueCard extends ConsumerWidget {
  const DiscoverVenueCard({required this.row, this.variant = GzVenueCardVariant.card, this.date, this.useBriefDate = true, super.key});

  final VenueResult row;
  final GzVenueCardVariant variant;

  /// The date this card speaks about (a "This week" card carries its own free date). Default: the Brief date.
  final LocalDate? date;

  /// false: no availability line even when the Brief has a date (the shelves that already say "free").
  final bool useBriefDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(searchBriefProvider);
    final day = date ?? (useBriefDate ? brief.date : null);
    final signedIn = ref.watch(sessionProvider.select((s) => s.isSignedIn));
    final id = row.venue.id;
    final area = ref.watch(areasProvider.select((a) => a.value?.areas.where((x) => x.id == row.venue.areaId).firstOrNull?.name));
    final nav = context.gzNav;
    return DiscoverCardKey(
      id: id,
      child: GzVenueCard(
        venue: row.venue,
        area: area,
        price: row.price,
        availability: day == null ? null : row.availability,
        date: day,
        badge: row.badge,
        audience: signedIn ? GzPriceAudience.member : GzPriceAudience.guest,
        tags: row.tags,
        guestRange: row.guestRange,
        sponsored: row.sponsored,
        variant: variant,
        favourite: ref.watch(isFavouriteProvider((SavedType.venue, id))),
        onFavouriteChange: (_) => _toggleHeart(ref, nav, id),
        compared: ref.watch(compareProvider.select((c) => c.contains(id))),
        onCompareChange: (_) => _toggleCompare(ref, nav, id),
        onOpen: () => nav.push(row.venue.channel == BookingChannel.externalLink ? 'CL-VENU-06' : 'CL-VENU-01', params: <String, Object?>{'venueId': id, 'from': 'discover'}),
      ),
    );
  }
}

/// A stable key per venue for tests and the shot harness (`find.byKey(ValueKey('discover.card.V01'))`).
class DiscoverCardKey extends StatelessWidget {
  const DiscoverCardKey({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: ValueKey<String>('discover.card.$id'), child: child);
}

Future<void> _toggleHeart(WidgetRef ref, GzNavigator nav, String id) async {
  final notifier = ref.read(favouritesProvider.notifier);
  final saved = await notifier.toggle(SavedType.venue, id);
  if (saved && (ref.read(favouritesProvider).value?.signupNudge ?? false)) {
    notifier.clearSignupNudge();
    nav.openSheet('CL-AUTH-01', options: const GzSheetOptions(params: <String, Object?>{'reason': 'save'}));
  }
}

void _toggleCompare(WidgetRef ref, GzNavigator nav, String id) {
  final r = ref.read(compareProvider.notifier).toggle(id);
  if (r == CompareResult.full) nav.openSheet('CL-SAVD-03', options: GzSheetOptions(params: <String, Object?>{'incoming': id}));
}

/// The package a card price quotes (a rental fee has none).
String? cardPackageId(CardPrice? p) => switch (p) {
  CardPriceExact() => p.packageId,
  CardPriceFromGuests() => p.packageId,
  CardPriceFromMinimum() => p.packageId,
  CardPriceFlatNight() => p.packageId,
  _ => null,
};

/// A venue the voucher can be asked for: not governmental, and the price carries a voucher price.
bool voucherOffered(VenueResult r) => r.venue.voucherEnabled && r.venue.type != VenueType.governmental && r.price?.voucher != null;

/// The trailing 44 action under a card whose hall is free (or on hold) on the Brief date (CL-DISC-03): "Get voucher" for a
/// voucher-eligible venue (opens CL-VCHR-01 with the quote; a guest meets the sign-in sheet first with the quote intact), otherwise
/// "View". Nothing under a governmental facility and nothing before a date is chosen.
class DiscoverCardAction extends ConsumerWidget {
  const DiscoverCardAction({required this.row, super.key});

  final VenueResult row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brief = ref.watch(searchBriefProvider);
    final date = brief.date;
    if (date == null || row.venue.channel == BookingChannel.externalLink || (row.availability != VenueDayState.available && row.availability != VenueDayState.held)) {
      return const SizedBox.shrink();
    }
    final eligible = voucherOffered(row);
    final l = context.l10n;
    final nav = context.gzNav;
    void getVoucher() {
      final packageId = cardPackageId(row.price);
      ref.read(bookingDraftProvider.notifier).start(venueId: row.venue.id, hallId: row.availabilityHallId, packageId: packageId, eventDate: date, guests: brief.guests, audience: brief.audience);
      final params = <String, Object?>{
        'venueId': row.venue.id,
        'hallId': row.availabilityHallId,
        'packageId': packageId,
        'eventDate': date.toString(),
        'guests': brief.guests,
        'from': 'discover',
      };
      if (!ref.requireSignIn(GateReason.voucher, resume: GateResume('CL-VCHR-01', params))) return;
      nav.openSheet('CL-VCHR-01', options: GzSheetOptions(params: params));
    }

    // The web item is a 4 gap column and the action row carries its own 4 of top padding: 8 under the card.
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: GzButton(
          key: ValueKey<String>('discover.action.${row.venue.id}'),
          label: eligible ? l.clientDiscoverCardGetVoucher : l.clientDiscoverCardView,
          variant: GzButtonVariant.tertiary,
          iconEnd: eligible ? GzIcons.ticket : null,
          onPressed: eligible ? getVoucher : () => nav.push('CL-VENU-01', params: <String, Object?>{'venueId': row.venue.id, 'from': 'discover'}),
        ),
      ),
    );
  }
}
