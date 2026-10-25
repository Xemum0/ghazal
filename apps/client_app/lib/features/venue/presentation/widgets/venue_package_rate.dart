import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/venue_model.dart';
import '../venue_glyphs.dart';
import 'venue_money.dart';

/// The most guests the package can take in its hall for its audience (web `maxInHall`).
int packageMaxInHall(VenueView view, PackageRow row) {
  final section = sectionOf(view.hall, row.audience);
  var max = view.hall.capacity.max;
  if (section != null && section.maxGuests < max) max = section.maxGuests;
  if (row.pkg.maxGuests > 0 && row.pkg.maxGuests < max) max = row.pkg.maxGuests;
  return max;
}

bool packageOverCapacity(VenueView view, PackageRow row) {
  final guests = view.prices?.billedGuests;
  return guests != null && guests > packageMaxInHall(view, row);
}

/// The sibling package of the other day-type in the same hall (weekday against weekend): its base per-guest rates.
PackageOffer? siblingPackage(VenueView view, PackageRow row) {
  const pairs = <PackageArchetype, PackageArchetype>{
    PackageArchetype.ladiesWeekend: PackageArchetype.ladiesWeekday,
    PackageArchetype.ladiesWeekday: PackageArchetype.ladiesWeekend,
  };
  final other = pairs[row.pkg.archetype];
  if (other == null) return null;
  return view.detail.packages
      .where((o) => o.package.archetype == other && o.package.hallIds.contains(view.hall.id) && o.package.id != row.pkg.id)
      .firstOrNull;
}

String _tierName(AppL10n l, PriceTier tier) => switch (tier) {
  PriceTier.weekday => l.clientVenuePkgTierWeekday,
  PriceTier.weekend => l.clientVenuePkgTierWeekend,
  PriceTier.holiday => l.clientVenuePkgTierHoliday,
  PriceTier.specialDate => l.clientVenuePkgTierSpecialDate,
  _ => l.clientVenuePkgTierSeason,
};

/// The ruled rate block of the package sheet (web `.gzv-pk__rate`): the facts, the two prices of the quote, the per-guest pair and the
/// day type of the date with the sibling rate beside it. Glyphs and figures only (ADR 0034).
class PackageRateBlock extends StatelessWidget {
  const PackageRateBlock({required this.view, required this.row, required this.guest, super.key});

  final VenueView view;
  final PackageRow row;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final lc = context.gzL10n;
    final f = context.gzFormat;
    final pkg = row.pkg;
    final price = row.price;
    final date = view.day?.date;
    final unavailable = view.status == DayStatusKind.unavailable;
    final over = packageOverCapacity(view, row);
    final maxIn = packageMaxInHall(view, row);
    final eligible = price != null && price.voucherOffered;
    final perGuest = pkg.pricingBasis == PricingBasis.perGuest || pkg.pricingBasis == PricingBasis.flatPlusPerGuest;
    final prices = price == null
        ? null
        : QuotePrices(
            eligible: eligible,
            standard: price.standard.fils,
            voucher: price.voucher?.fils ?? price.standard.fils,
            savings: price.savings?.fils ?? 0,
            billedGuests: price.billedGuests ?? row.minGuests,
          );
    final sep = sepOf(f);

    // The web facts row is the body line plus 4 high (32 in Arabic, 28 in English): the limits chip sits in an inline span whose line
    // box is taller than the chip, at its top.
    final bodyStyle = context.gz.text(GzTextRole.body);
    final factsHeight = (bodyStyle.height ?? 1) * (bodyStyle.fontSize ?? 16) + GzSpace.s1;
    Widget fact(Widget chip, {bool top = false}) => SizedBox(
      height: factsHeight,
      child: Align(alignment: top ? AlignmentDirectional.topStart : AlignmentDirectional.centerStart, widthFactor: 1, child: chip),
    );
    final body = <Widget>[
      Wrap(
        spacing: GzSpace.s5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          fact(GzFactChip(icon: audienceGlyph(row.audience), label: audienceName(l, row.audience))),
          if (pkg.priceStructure == PriceStructure.package) fact(GzFactChip(icon: GzIcons.package, label: lc.commonPricingPackage)),
          fact(
            GzFactChip(
              icon: GzIcons.usersThree,
              label: '${lc.commonUnitMinGuests(row.minGuests)}$sep${lc.commonUnitUpToGuests(maxIn)}',
              valueWidget: GzNum('${f.integer(row.minGuests)}–${f.integer(maxIn)}', role: GzTextRole.figBodyS),
            ),
            top: true,
          ),
          if (row.belowMinimum && !unavailable && price != null)
            fact(
              GzFactChip(
                icon: GzIcons.usersThree,
                tone: GzFactTone.accent,
                value: '${f.integer(row.minGuests)}+',
                label: l.clientVenueEstimateMinimum(f.plain(f.guests(row.minGuests))),
              ),
              top: true,
            ),
        ],
      ),
    ];

    if (unavailable) {
      body.add(
        Wrap(
          spacing: GzSpace.s3,
          runSpacing: GzSpace.s3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const GzStatusPill(status: GzStatus.unavailable),
            if (date != null)
              GzFactChip(
                icon: GzIcons.calendar,
                value: f.date(date.toString(), DateStyle.short),
                label: l.clientVenuePkgUnavailable(f.plain(f.date(date.toString(), DateStyle.full))),
              ),
          ],
        ),
      );
    } else if (price != null) {
      if (date != null && !over && prices != null && !row.lowestRate) body.add(PriceBlock(prices: prices, guest: guest, owned: view.owned != null));
      if (perGuest && price.perGuest != null) body.add(_RatePair(price: price, eligible: eligible, guest: guest));
      if (date != null) body.add(_TierLine(row: row, price: price, date: date, eligible: eligible, sibling: siblingPackage(view, row)));
    }
    if (over && !unavailable) {
      body.add(
        Semantics(
          container: true,
          child: GzIconListRow(
            flush: true,
            last: true,
            icon: GzIcons.warning,
            title: l.clientVenuePkgOverTitle,
            trailing: GzFactChip(
              icon: GzIcons.usersThree,
              value: f.integer(maxIn),
              label: l.clientVenuePkgOverCap(context.bi(view.hall.name), f.plain(f.guests(maxIn))),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s4),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < body.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s3), body[i]],
        ],
      ),
    );
  }
}

/// The two per-guest rates side by side: the voucher column, then the standard one (struck when a voucher price exists).
class _RatePair extends StatelessWidget {
  const _RatePair({required this.price, required this.eligible, required this.guest});

  final PackageBriefPrice price;
  final bool eligible;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final lc = context.gzL10n;
    final c = context.gz.colors;
    final voucher = price.voucherPerGuest;
    return Wrap(
      spacing: GzSpace.s5,
      runSpacing: GzSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GzIcon(GzIcons.perGuest, size: GzIconSize.sm, tone: GzIconTone.secondary, semanticLabel: lc.commonUnitPerGuest),
        if (eligible && voucher != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(
                guest ? GzIcons.lock : GzIcons.ticket,
                size: GzIconSize.sm,
                tone: guest ? GzIconTone.secondary : GzIconTone.success,
                semanticLabel: lc.commonVoucherPrice,
              ),
              const SizedBox(width: GzSpace.s2),
              GzPrice(fils: voucher.fils, size: GzPriceSize.card),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(GzIcons.offer, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: lc.commonStandardPrice),
            const SizedBox(width: GzSpace.s2),
            if (eligible && voucher != null)
              QuietMoney(fils: price.perGuest!.fils, struck: true)
            else
              GzPrice(fils: price.perGuest!.fils, size: GzPriceSize.card),
          ],
        ),
      ],
    );
  }
}

/// The day type of the date (a glyph and one word) and the sibling rate beside it (weekday against weekend).
class _TierLine extends StatelessWidget {
  const _TierLine({required this.row, required this.price, required this.date, required this.eligible, required this.sibling});

  final PackageRow row;
  final PackageBriefPrice price;
  final LocalDate date;
  final bool eligible;
  final PackageOffer? sibling;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final tier = price.tier;
    final sib = sibling?.package;
    final weekend = tier == PriceTier.weekend;
    final days = weekend ? const <int>[0, 3] : const <int>[4, 6];
    final showSibling = sib != null && tier != null && (tier == PriceTier.weekend || tier == PriceTier.weekday);
    final siblingVoucher = showSibling && sib.voucherFils != null && eligible;
    return Wrap(
      spacing: GzSpace.s5,
      runSpacing: GzSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GzFactChip(
          icon: GzIcons.calendarDots,
          tone: GzFactTone.accent,
          value: tier == null ? _tierName(l, PriceTier.season) : _tierName(l, tier),
          label: l.clientVenuePkgTierLabel(f.plain(f.date(date.toString(), DateStyle.full))),
        ),
        if (showSibling)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzText(
                '${f.weekdayName(days.first, NameStyle.short)}–${f.weekdayName(days.last, NameStyle.short)}',
                role: GzTextRole.caption,
                color: c.textSecondary,
                figures: true,
              ),
              if (siblingVoucher) ...[
                const SizedBox(width: GzSpace.s2),
                const GzIcon(GzIcons.ticket, size: GzIconSize.xs, tone: GzIconTone.success),
                const SizedBox(width: GzSpace.s2),
                CaptionMoney(fils: sib.voucherFils!),
              ],
              const SizedBox(width: GzSpace.s2),
              GzIcon(GzIcons.offer, size: GzIconSize.xs, color: c.iconSecondary),
              const SizedBox(width: GzSpace.s2),
              CaptionMoney(fils: sib.standardFils, struck: true),
            ],
          ),
      ],
    );
  }
}
