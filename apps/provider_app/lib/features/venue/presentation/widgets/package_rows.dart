// The rows of "Packages and extras" (web `Rows.tsx`): a package row (name, audience, the prices per set of days with the voucher price as the
// headline, guest range, language completeness, the active switch) and an extra row. The row body opens the editor; the switch is its own target.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/venue_pricing.dart';
import 'venue_fields.dart';
import 'venue_labels.dart';

/// One price as couples read it: the per-guest rate (unit always shown), a flat amount, or both.
class RateText extends StatelessWidget {
  const RateText({required this.basis, required this.tier, this.voucher = false, this.size = GzPriceSize.card, super.key});

  final PricingBasis basis;
  final TierDraft tier;
  final bool voucher;
  final GzPriceSize size;

  @override
  Widget build(BuildContext context) {
    final col = tier.column(voucher);
    final c = context.gz.colors;
    if (basis == PricingBasis.perGuest) return col.perGuest == null ? const SizedBox.shrink() : GzPrice(fils: col.perGuest!, size: size, unit: GzPriceUnit.perGuest);
    if (basis == PricingBasis.flat) return col.flat == null ? const SizedBox.shrink() : GzPrice(fils: col.flat!, size: size);
    if (col.flat == null || col.perGuest == null) return const SizedBox.shrink();
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: GzSpace.s1,
      children: [GzPrice(fils: col.flat!, size: size), GzText('+', role: GzTextRole.caption, color: c.textSecondary), GzPrice(fils: col.perGuest!, size: size, unit: GzPriceUnit.perGuest)],
    );
  }
}

class _Cap extends StatelessWidget {
  const _Cap(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(label: label, excludeSemantics: true, child: GzIcon(icon, size: GzIconSize.xs, color: context.gz.colors.iconSecondary));
}

/// The two prices of one set of days: the voucher price as the headline, the standard price quiet next to it.
class TierPrices extends StatelessWidget {
  const TierPrices({required this.basis, required this.tier, super.key});

  final PricingBasis basis;
  final TierDraft tier;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!tier.hasVoucher) {
      return Row(mainAxisSize: MainAxisSize.min, children: [_Cap(GzIcons.coins, l.commonStandardPrice), const SizedBox(width: GzSpace.s1), RateText(basis: basis, tier: tier, size: GzPriceSize.strong)]);
    }
    return Wrap(
      spacing: GzSpace.s5,
      runSpacing: GzSpace.s2,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [_Cap(GzIcons.ticket, l.commonVoucherPrice), const SizedBox(width: GzSpace.s2), RateText(basis: basis, tier: tier, voucher: true, size: GzPriceSize.strong)]),
        Row(mainAxisSize: MainAxisSize.min, children: [_Cap(GzIcons.coins, l.commonStandardPrice), const SizedBox(width: GzSpace.s2), RateText(basis: basis, tier: tier)]),
      ],
    );
  }
}

/// The two day tiers of a package, each with both prices (one block when the same prices hold every day); a bundle shows its parts.
class PriceLines extends StatelessWidget {
  const PriceLines({required this.pkg, required this.catalog, super.key});

  final PackageEditor pkg;
  final PackageCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final p = pkg.package;
    if (p.components != null && p.components!.isNotEmpty) {
      final parts = <Widget>[];
      for (final part in p.components!) {
        final other = catalog.packages.where((x) => x.package.id == part.packageId).firstOrNull;
        if (other == null) continue;
        final we = TierDraft.of(other, PriceTier.weekend);
        final tier = we.on ? we : TierDraft.of(other, PriceTier.weekday);
        if (parts.isNotEmpty) parts.add(GzText('+', role: GzTextRole.caption, color: c.textSecondary));
        parts.add(RateText(basis: other.package.pricingBasis, tier: tier, voucher: tier.hasVoucher));
      }
      return Wrap(spacing: GzSpace.s1, crossAxisAlignment: WrapCrossAlignment.center, children: parts);
    }
    final day = TierDraft.of(pkg, PriceTier.weekday);
    final end = TierDraft.of(pkg, PriceTier.weekend);
    final same = day.on && end.on && day.sameAs(end);
    final lines = same
        ? [(l.hotelVenueAllDays, day)]
        : [if (day.on) (l.commonTierWeekday, day), if (end.on) (l.commonTierWeekend, end)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: GzSpace.s3),
          GzText(lines[i].$1, role: GzTextRole.label, color: c.textSecondary),
          const SizedBox(height: GzSpace.s1),
          TierPrices(basis: p.pricingBasis, tier: lines[i].$2),
        ],
      ],
    );
  }
}

IconData _audIcon(Audience a) => switch (a) {
  Audience.men => GzIcons.sectionMen,
  Audience.mixed => GzIcons.sectionMixed,
  _ => GzIcons.sectionWomen,
};

class PackageRow extends StatelessWidget {
  const PackageRow({required this.pkg, required this.catalog, required this.onOpen, required this.onActive, this.last = false, super.key});

  final PackageEditor pkg;
  final PackageCatalog catalog;
  final VoidCallback onOpen;
  final ValueChanged<bool> onActive;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final p = pkg.package;
    final name = p.name.of(lang);
    final bundle = p.components != null && p.components!.isNotEmpty;
    final tiers = [TierDraft.of(pkg, PriceTier.weekday), TierDraft.of(pkg, PriceTier.weekend)];
    final noVoucher = !bundle && !tiers.any((t) => t.on && t.hasVoucher);
    int gaps(LocalizedText t, bool ar) => ((ar ? t.ar : t.en) ?? '').trim().isEmpty ? 1 : 0;
    final arGaps = gaps(p.name, true) + gaps(p.description, true);
    final enGaps = gaps(p.name, false) + gaps(p.description, false);
    final perPerson = structureOf(p.pricingBasis) == PriceStructure.perPerson;
    return Container(
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GzPressable(
              onPressed: onOpen,
              semanticLabel: l.hotelVenueEditPackage(name),
              minHeight: GzSize.rowMin,
              scale: 1,
              child: Container(
                constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzUserText(name, role: GzTextRole.title, color: p.active ? c.textStrong : c.textSecondary),
                    const SizedBox(height: GzSpace.s2),
                    PriceLines(pkg: pkg, catalog: catalog),
                    const SizedBox(height: GzSpace.s2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: GzSpace.s3,
                      runSpacing: GzSpace.s2,
                      children: [
                        _MetaIcon(perPerson ? GzIcons.perGuest : GzIcons.package, perPerson ? l.commonPricingPerPerson : l.commonPricingPackage),
                        for (final a in p.audiences) _MetaIcon(_audIcon(a), audienceLabel(l, a)),
                        if (noVoucher) _MetaIcon(GzIcons.ticket, l.hotelVenueNoVoucherTag, danger: true),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GzIcon(GzIcons.guests, size: GzIconSize.xs, color: c.iconSecondary),
                            const SizedBox(width: GzSpace.s2),
                            GzText(l.hotelVenueGuestRange(f.integer(p.minGuests), f.integer(p.maxGuests)), role: GzTextRole.caption, color: c.textSecondary, figures: true),
                          ],
                        ),
                        if (!p.active) _MetaIcon(GzIcons.eyeOff, l.hotelVenueHidden),
                      ],
                    ),
                    if (arGaps + enGaps > 0) ...[const SizedBox(height: GzSpace.s2), LangChip(arGaps: arGaps, enGaps: enGaps)],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          Container(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            margin: const EdgeInsetsDirectional.only(top: GzSpace.s3),
            alignment: Alignment.center,
            child: GzSwitch(label: l.hotelVenuePkgActiveLabel(name), checked: p.active, onChanged: onActive),
          ),
        ],
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon(this.icon, this.label, {this.danger = false});

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(label: label, excludeSemantics: true, child: GzIcon(icon, size: GzIconSize.sm, color: danger ? c.iconDanger : c.iconSecondary));
  }
}

String unitLabel(AppL10n l, Extra e, String lang) {
  final custom = e.unitLabel;
  if (custom != null && !custom.isEmpty) return custom.of(lang);
  return switch (e.pricingUnit) {
    PricingUnit.perGuest => l.commonUnitPerGuest,
    PricingUnit.perUnit => l.hotelVenueUnitUnit,
    _ => l.hotelVenueUnitEvent,
  };
}

class ExtraRow extends StatelessWidget {
  const ExtraRow({required this.extra, required this.onOpen, required this.onActive, this.last = false, super.key});

  final Extra extra;
  final VoidCallback onOpen;
  final ValueChanged<bool> onActive;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final name = extra.name.of(lang);
    final unit = unitLabel(l, extra, lang);
    final range = extra.priceMin != null && extra.priceMax != null;
    return Container(
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GzPressable(
              onPressed: onOpen,
              semanticLabel: l.hotelVenueEditPackage(name),
              minHeight: GzSize.rowMin,
              scale: 1,
              child: Container(
                constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzUserText(name, role: GzTextRole.title, color: extra.active ? c.textStrong : c.textSecondary),
                    const SizedBox(height: GzSpace.s2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: GzSpace.s4,
                      children: [
                        if (range) ...[
                          GzPrice(fils: extra.priceMin!.fils),
                          Row(mainAxisSize: MainAxisSize.min, children: [GzText('–', role: GzTextRole.caption, color: c.textSecondary), const SizedBox(width: GzSpace.s1), GzPrice(fils: extra.priceMax!.fils)]),
                        ] else
                          GzPrice(fils: extra.price.fils),
                        GzText(unit, role: GzTextRole.caption, color: c.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          Container(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            margin: const EdgeInsetsDirectional.only(top: GzSpace.s3),
            alignment: Alignment.center,
            child: GzSwitch(label: l.hotelVenuePkgActiveLabel(name), checked: extra.active, onChanged: onActive),
          ),
        ],
      ),
    );
  }
}
