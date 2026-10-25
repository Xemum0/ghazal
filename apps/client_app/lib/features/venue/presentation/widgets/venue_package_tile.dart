import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/venue_model.dart';
import '../venue_glyphs.dart';
import 'venue_money.dart';

/// PackageTile (CL-VENU-01 packages; ADR 0004, ADR 0033 D4, ADR 0034): one priced package as a choice, figure-led. The serif name, three
/// facts as glyph and figure (the section, the guest minimum, how many inclusions), and the price: the total for the party under the
/// voucher column (ticket for a member, lock for a guest) with the standard total struck and the saving, and the per-guest rate as a
/// fact. No sentence, no inclusion list (the sheet has them: CL-VENU-04). Choosing is ink and a gold bead, never a gold fill.
class VenuePackageTile extends StatelessWidget {
  const VenuePackageTile({
    required this.row,
    required this.selected,
    required this.onSelect,
    required this.onDetails,
    this.guests,
    this.unavailable = false,
    this.guest = false,
    super.key,
  });

  final PackageRow row;

  /// The guest count the total is for; without it (no date or no guests) the tile shows the lowest per-guest rate.
  final int? guests;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDetails;

  /// Not sold on the Brief date: muted, not a target.
  final bool unavailable;

  /// Signed out: the voucher column carries a lock (voucher-model 4.5).
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final lc = context.gzL10n;
    final f = context.gzFormat;
    final pkg = row.pkg;
    final price = row.price;
    final basis = pkg.pricingBasis;
    final voucherOn = price != null && price.voucherOffered && price.voucher != null;
    // No date yet: the package's own rates stand in for a quote.
    final baseVoucher = pkg.voucherFils != null && pkg.voucherFils! < pkg.standardFils;
    final total = price == null ? null : (voucherOn ? price.voucher!.fils : price.standard.fils);
    final rate = price == null
        ? (baseVoucher ? pkg.voucherFils : pkg.standardFils)
        : (voucherOn ? (price.voucherPerGuest ?? price.perGuest)?.fils : price.perGuest?.fils);
    final flat = price == null ? null : (voucherOn ? (price.voucherFlat ?? price.flat)?.fils : price.flat?.fils);
    final showTotal = total != null && guests != null && basis != PricingBasis.flat;
    final perGuestBasis = basis == PricingBasis.perGuest || basis == PricingBasis.flatPlusPerGuest;
    final minimum = row.minGuests > 0 ? '${f.integer(row.minGuests)}+' : null;

    Widget mark(bool voucher) => GzIcon(
      voucher ? (guest ? GzIcons.lock : GzIcons.ticket) : GzIcons.coins,
      size: GzIconSize.sm,
      tone: voucher && !guest ? GzIconTone.success : GzIconTone.secondary,
      semanticLabel: voucher ? lc.commonVoucherPrice : lc.commonStandardPrice,
    );
    Widget struck(int fils) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GzIcon(GzIcons.offer, size: GzIconSize.xs, tone: GzIconTone.secondary, semanticLabel: lc.commonStandardPrice),
        const SizedBox(width: GzSpace.s2),
        GzStruckMoney(fils: fils),
      ],
    );
    Widget rateChip(int fils) =>
        GzFactChip(icon: GzIcons.perGuest, valueWidget: QuietMoney(fils: fils), label: lc.commonUnitPerGuest);

    Widget? money;
    if (unavailable) {
      money = GzIcon(GzIcons.calendarX, size: GzIconSize.sm, tone: GzIconTone.secondary, semanticLabel: lc.commonAvailabilityUnavailable);
    } else if (price != null || row.lowestRate) {
      final p = price;
      if (showTotal && p != null) {
        money = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s2,
              runSpacing: GzSpace.s2,
              children: [
                mark(voucherOn),
                GzPrice(fils: total, size: GzPriceSize.total),
                if (rate != null && perGuestBasis) rateChip(rate),
              ],
            ),
            if (voucherOn) ...[
              const SizedBox(height: GzSpace.s1),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: GzSpace.s3,
                runSpacing: GzSpace.s1,
                children: [struck(p.standard.fils), if (p.savings != null) SavingPill(fils: p.savings!.fils)],
              ),
            ],
          ],
        );
      } else if (basis == PricingBasis.flatPlusPerGuest && flat != null && rate != null) {
        money = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s2,
          children: [mark(voucherOn), GzPrice(fils: flat, size: GzPriceSize.total), const GzIcon(GzIcons.plus, size: GzIconSize.xs, tone: GzIconTone.secondary), rateChip(rate)],
        );
      } else if (basis == PricingBasis.perGuest && rate != null) {
        money = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s2,
              children: [
                mark(voucherOn || (price == null && baseVoucher)),
                GzPrice(fils: rate, size: GzPriceSize.total),
                GzIcon(GzIcons.perGuest, size: GzIconSize.sm, tone: GzIconTone.secondary, semanticLabel: lc.commonUnitPerGuest),
              ],
            ),
            if ((voucherOn && p?.perGuest != null) || (p == null && baseVoucher)) ...[
              const SizedBox(height: GzSpace.s1),
              struck(p?.perGuest?.fils ?? pkg.standardFils),
            ],
          ],
        );
      } else if (flat != null || (price == null && basis == PricingBasis.flat)) {
        final amount = flat ?? (baseVoucher ? pkg.voucherFils! : pkg.standardFils);
        final was = voucherOn ? p?.flat?.fils : (p == null && baseVoucher ? pkg.standardFils : null);
        money = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s2,
          children: [
            mark(voucherOn || (price == null && baseVoucher)),
            GzPrice(fils: amount, size: GzPriceSize.total, unit: pkg.archetype == PackageArchetype.hallOnly ? null : GzPriceUnit.perNight, was: was),
          ],
        );
      }
    }

    final border = unavailable ? c.borderHairline : (selected ? c.controlChipBorderSelected : c.borderStrong);
    final headline = Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
      child: GzText(context.bi(pkg.name), role: GzTextRole.d1, color: unavailable ? c.textSecondary : c.textStrong),
    );
    final facts = GzFactRow(
      children: [
        for (final a in pkg.audiences)
          if (a != Audience.unknown) GzFactChip(icon: audienceGlyph(a), label: audienceName(l, a)),
        if (pkg.priceStructure == PriceStructure.package) GzFactChip(icon: GzIcons.package, label: lc.commonPricingPackage),
        if (minimum != null) GzFactChip(icon: GzIcons.usersThree, value: minimum, label: l.clientVenuePkgMinGuests),
        if (pkg.inclusions.isNotEmpty) GzFactChip(icon: GzIcons.checklist, value: f.integer(pkg.inclusions.length), label: l.clientVenuePkgIncludes),
      ],
    );
    final choose = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
              child: SizedBox(height: GzSpace.s6, child: Center(child: GzThreadBead(tone: selected ? GzBeadTone.gold : GzBeadTone.hollow))),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(child: headline),
          ],
        ),
        const SizedBox(height: GzSpace.s3),
        Padding(padding: const EdgeInsetsDirectional.only(start: GzSpace.s6), child: facts),
        if (money != null) ...[
          const SizedBox(height: GzSpace.s3),
          Padding(padding: const EdgeInsetsDirectional.only(start: GzSpace.s6), child: money),
        ],
      ],
    );
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: unavailable ? c.surfaceCanvas : c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: border, width: GzStroke.hair),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.panelPad, top: GzSpace.panelPad, bottom: GzSpace.panelPad, end: GzSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GzPressable(
                  onPressed: unavailable ? null : onSelect,
                  selected: selected,
                  semanticLabel: context.bi(pkg.name),
                  scale: 1,
                  minHeight: 0,
                  minWidth: 0,
                  borderRadius: GzRadius.smAll,
                  child: choose,
                ),
              ),
              if (!unavailable) ...[
                const SizedBox(width: GzSpace.s1),
                GzIconButton(icon: GzIcons.chevronRight, iconSize: GzIconSize.sm, label: l.clientVenuePackagesDetails, onPressed: onDetails),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The money text of an amount in the browse grammar (for accessible names).
String browseMoney(BuildContext context, int fils) => context.gzFormat.plain(context.gzFormat.money(fils, const MoneyOptions(mode: MoneyMode.browse)));
