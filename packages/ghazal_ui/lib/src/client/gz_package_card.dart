import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, MoneyAmount, Package, PackageArchetype, PackageBriefPrice, PriceStructure, PricingBasis;

import '../brand/gz_thread_knot.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'client_bits.dart' show GzBaselineWrap, GzPriceAudience;

/// What the pricing engine says about one package on a date for the guests (the web `engine.PackagePrice`). The API sends the
/// totals ([PackageBriefPrice]); the per-guest and flat parts come from the engine (or the mock's `packagePrice`).
class GzPackagePrice {
  const GzPackagePrice({
    required this.standard,
    this.voucher,
    this.savings,
    this.voucherEligible = false,
    this.perGuest,
    this.flat,
    this.voucherPerGuest,
    this.voucherFlat,
  });

  /// The engine's JSON shape (`standard`, `voucher`, `savings`, `voucherEligible`, `perGuest`, `flat`, `voucherPerGuest`, `voucherFlat`).
  factory GzPackagePrice.fromJson(Map<String, Object?> j) {
    MoneyAmount? m(String k) => j[k] == null ? null : MoneyAmount.fromJson((j[k]! as Map).cast<String, Object?>());
    return GzPackagePrice(
      standard: m('standard')!,
      voucher: m('voucher'),
      savings: m('savings'),
      voucherEligible: j['voucherEligible'] == true,
      perGuest: m('perGuest'),
      flat: m('flat'),
      voucherPerGuest: m('voucherPerGuest'),
      voucherFlat: m('voucherFlat'),
    );
  }

  /// From the API's per-brief offer: the unit prices are the package's own (`standardFils`, `voucherFils`). A flat-plus-per-guest
  /// package shows its per-guest part only (its flat part is not on the wire).
  factory GzPackagePrice.fromOffer(Package pkg, PackageBriefPrice p) {
    final per = pkg.pricingBasis != PricingBasis.flat;
    MoneyAmount? std() => MoneyAmount(pkg.standardFils);
    MoneyAmount? vch() => pkg.voucherFils == null ? null : MoneyAmount(pkg.voucherFils!);
    return GzPackagePrice(
      standard: p.standard,
      voucher: p.voucher,
      savings: p.savings,
      voucherEligible: p.voucherOffered,
      perGuest: per ? std() : null,
      flat: per ? null : std(),
      voucherPerGuest: per ? vch() : null,
      voucherFlat: per ? null : vch(),
    );
  }

  final MoneyAmount standard;
  final MoneyAmount? voucher;
  final MoneyAmount? savings;
  final bool voucherEligible;
  final MoneyAmount? perGuest;
  final MoneyAmount? flat;
  final MoneyAmount? voucherPerGuest;
  final MoneyAmount? voucherFlat;
}

/// PackageCard (venue details, booking step 2; ADR 0004 D1, ADR 0033 D4): one priced package as a choice. Serif name, audience, the
/// structure and guest bounds, the VOUCHER price in the basis it is sold in with the standard price struck through and the saving; a
/// signed-out visitor ([audience] guest) sees the standard price and a locked voucher line. Choosing is ink and a gold bead, never a
/// gold fill: selected = ink border, the bead filled. [unavailable] is muted, with the reason, not a target.
class GzPackageCard extends StatefulWidget {
  const GzPackageCard({
    required this.pkg,
    this.price,
    this.audience = GzPriceAudience.member,
    this.guests,
    this.selected = false,
    this.onSelect,
    this.unavailable = false,
    this.collapsedCount = 5,
    this.loading = false,
    this.previewState,
    super.key,
  });

  final Package pkg;

  /// Null while loading or when the package has no rule for the date.
  final GzPackagePrice? price;
  final GzPriceAudience audience;

  /// The guest count the total is for; with it per-guest packages show the all-in total.
  final int? guests;
  final bool selected;
  final VoidCallback? onSelect;
  final bool unavailable;

  /// Inclusions shown before "Show all".
  final int collapsedCount;
  final bool loading;

  /// Gallery only.
  final GzPreviewState? previewState;

  @override
  State<GzPackageCard> createState() => _GzPackageCardState();
}

class _GzPackageCardState extends State<GzPackageCard> {
  bool _open = false;

  /// A price stacked in a column (amount, then unit, then the struck previous price), the way the card's price column sets it.
  Widget _stack(BuildContext context, int fils, {String? unit, int? was}) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    String? struck;
    if (was != null) {
      final p = f.moneyParts(was, const MoneyOptions(mode: MoneyMode.browse));
      struck = '${p.integer}${p.fraction}';
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GzMoney(fils: fils),
        if (unit != null) GzText(unit, role: GzTextRole.caption, color: c.textSecondary),
        if (struck != null) ExcludeSemantics(child: gzFigText(context, struck, role: GzTextRole.figCaption, color: c.textSecondary, decoration: TextDecoration.lineThrough)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    final pkg = widget.pkg;
    final unavailable = widget.unavailable;

    Widget panel(Widget child, {bool pressed = false}) => Container(
      padding: GzSpace.panel,
      decoration: BoxDecoration(
        color: unavailable ? c.surfaceCanvas : (pressed ? c.surfaceQuiet : c.surfaceRaised),
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: unavailable ? c.borderHairline : (widget.selected ? c.controlChipBorderSelected : c.borderStrong), width: GzStroke.hair),
      ),
      child: child,
    );

    if (widget.loading) {
      return panel(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GzSkeleton(inlineSize: 200, blockSize: 28),
            SizedBox(height: GzSpace.s4),
            GzSkeleton(inlineSize: 140, blockSize: 20),
            SizedBox(height: GzSpace.s4),
            SizedBox(width: double.infinity, child: GzSkeleton(blockSize: 20)),
            SizedBox(height: GzSpace.s4),
            SizedBox(width: double.infinity, child: GzSkeleton(blockSize: 20)),
            SizedBox(height: GzSpace.s4),
            GzSkeleton(inlineSize: 160, blockSize: 20),
          ],
        ),
      );
    }

    final price = widget.price;
    final bounds = pkg.minGuests > 0
        ? f.minGuests(pkg.minGuests)
        : pkg.maxGuests > 0
            ? l.uiClientPackageUpTo(f.guests(pkg.maxGuests))
            : '';
    final inclusions = pkg.inclusions;
    final shown = _open ? inclusions : inclusions.take(widget.collapsedCount).toList();
    final audienceText = pkg.audiences
        .map((a) => switch (a) {
              Audience.women => l.uiClientPackageLadies,
              Audience.men => l.uiClientPackageMen,
              _ => l.uiClientPackageMixed,
            })
        .join(' · ');
    final structure = pkg.priceStructure == PriceStructure.package ? l.commonPricingPackage : l.commonPricingPerPerson;
    final sub = [audienceText, structure, bounds].where((s) => s.isNotEmpty).join(' · ');

    final member = widget.audience == GzPriceAudience.member;
    final voucherOn = price != null && price.voucherEligible && price.voucher != null && member;
    final lockedOn = price != null && price.voucherEligible && widget.audience == GzPriceAudience.guest;
    final basis = pkg.pricingBasis;
    final unitPrice = voucherOn ? (price.voucherPerGuest ?? price.perGuest) : price?.perGuest;
    final flatPrice = voucherOn ? (price.voucherFlat ?? price.flat) : price?.flat;
    final wasUnit = voucherOn ? price.perGuest : null;
    final wasFlat = voucherOn ? price.flat : null;
    final total = voucherOn ? price.voucher : price?.standard;
    final guests = widget.guests;
    final showTotal = price != null && total != null && guests != null && guests > 0 && basis != PricingBasis.flat;

    Widget? priceBlock;
    if (price != null) {
      if (basis == PricingBasis.flatPlusPerGuest && flatPrice != null && unitPrice != null) {
        priceBlock = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GzMoney(fils: flatPrice.fils),
            const SizedBox(height: GzSpace.s1),
            GzText(l.uiClientPackagePlus, role: GzTextRole.caption, color: c.textSecondary),
            const SizedBox(height: GzSpace.s1),
            _stack(context, unitPrice.fils, unit: l.commonUnitPerGuest),
          ],
        );
      } else if (basis == PricingBasis.perGuest && unitPrice != null) {
        priceBlock = _stack(context, unitPrice.fils, unit: l.commonUnitPerGuest, was: wasUnit?.fils);
      } else if (flatPrice != null) {
        priceBlock = pkg.archetype == PackageArchetype.hallOnly
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _stack(context, flatPrice.fils, was: wasFlat?.fils),
                  const SizedBox(height: GzSpace.s1),
                  GzText(l.uiClientPackageHallOnly, role: GzTextRole.caption, color: c.textSecondary),
                ],
              )
            : _stack(context, flatPrice.fils, unit: l.commonUnitPerNight, was: wasFlat?.fils);
      }
    }

    final nameColor = unavailable ? c.textSecondary : c.textPrimary;
    final head = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: GzSpace.s6, child: Padding(padding: const EdgeInsets.only(top: GzSpace.s1), child: Center(child: GzThreadBead(tone: widget.selected ? GzBeadTone.gold : GzBeadTone.hollow)))),
        const SizedBox(width: GzSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GzText(pkg.name.of(lang), role: GzTextRole.d1, color: nameColor),
              const SizedBox(height: GzSpace.s1),
              GzText(sub, role: GzTextRole.caption, color: c.textSecondary, figures: true),
            ],
          ),
        ),
        if (priceBlock != null) ...[
          const SizedBox(width: GzSpace.s3),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: GzSize.weekStrip), child: Padding(padding: const EdgeInsets.only(top: GzSpace.s1), child: priceBlock)),
        ],
      ],
    );

    final saving = voucherOn ? price.savings : null;
    final totalLine = showTotal
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.s6),
            child: GzBaselineWrap(
              spacing: GzSpace.s2,
              runSpacing: GzSpace.s2,
              children: [
                GzPrice(fils: total.fils, size: GzPriceSize.strong, was: voucherOn ? price.standard.fils : null),
                GzText(l.uiClientPackageForGuests(f.guests(guests, afterPreposition: gz.isAr)), role: GzTextRole.caption, color: c.textSecondary),
                if (saving != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: GzSize.pillMin),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: c.statusSuccessBg, borderRadius: GzRadius.xsAll),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
                        child: Center(widthFactor: 1, child: GzText(l.commonSaveAmount(f.money(saving.fils, const MoneyOptions(mode: MoneyMode.browse))), role: GzTextRole.pill, color: c.statusSuccessText)),
                      ),
                    ),
                  ),
              ],
            ),
          )
        : null;
    final lockLine = lockedOn
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.s6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.lock, size: GzIconSize.xs, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s1),
                Flexible(child: GzText(l.uiSharedLockedVoucher, role: GzTextRole.caption, color: c.textSecondary)),
              ],
            ),
          )
        : null;
    final chooseColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        head,
        if (totalLine != null) ...[const SizedBox(height: GzSpace.s2), totalLine],
        if (lockLine != null) ...[const SizedBox(height: GzSpace.s2), lockLine],
      ],
    );
    final interactive = widget.onSelect != null && !unavailable;
    final spoken = [pkg.name.of(lang), sub, if (total != null) f.money(total.fils, const MoneyOptions(mode: MoneyMode.browse)), if (widget.selected) l.uiClientPackageSelected].join(', ');
    // The choosing region is the radio (head, total, lock); the inclusions and the "show all" button stay separate for assistive technology.
    final Widget choose = !interactive && !widget.selected
        ? Semantics(container: true, label: spoken, child: chooseColumn)
        : Semantics(
            container: true,
            inMutuallyExclusiveGroup: true,
            checked: widget.selected,
            enabled: interactive,
            label: spoken,
            onTap: interactive ? widget.onSelect : null,
            excludeSemantics: true,
            child: GzPressable(
              onPressed: interactive ? widget.onSelect : null,
              borderRadius: GzRadius.smAll,
              scale: 1,
              minHeight: 0,
              child: chooseColumn,
            ),
          );

    Widget list(List<Widget> rows, {required double top, required String label}) => Semantics(
      container: true,
      label: label,
      child: Container(
        padding: EdgeInsets.only(top: top),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s2), rows[i]]]),
      ),
    );
    Widget item(IconData icon, Color iconColor, Widget text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: GzStroke.thread), child: GzIcon(icon, size: GzIconSize.xs, color: iconColor)),
        const SizedBox(width: GzSpace.s3),
        Expanded(child: text),
      ],
    );

    Widget body(bool pressed) => panel(
      pressed: pressed,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          choose,
          if (unavailable) ...[
            const SizedBox(height: GzSpace.s4),
            Row(
              children: [
                GzIcon(GzIcons.calendarX, size: GzIconSize.xs, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s2),
                Flexible(child: GzText(l.uiClientPackageUnavailable, role: GzTextRole.caption, color: c.textSecondary)),
              ],
            ),
          ],
          if (shown.isNotEmpty) ...[
            const SizedBox(height: GzSpace.s4),
            list(
              [for (final inc in shown) item(GzIcons.check, c.iconAccent, GzText(inc.of(lang), role: GzTextRole.bodyS, color: unavailable ? c.textSecondary : c.textPrimary, figures: true))],
              top: GzSpace.s4,
              label: l.uiClientPackageIncluded,
            ),
          ],
          if (inclusions.length > widget.collapsedCount) ...[
            const SizedBox(height: GzSpace.s4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzButton(
                label: _open ? l.uiClientPackageShowLess : l.uiClientPackageShowAll(f.integer(inclusions.length)),
                variant: GzButtonVariant.tertiary,
                iconEnd: _open ? GzIcons.chevronUp : GzIcons.chevronDown,
                onPressed: () => setState(() => _open = !_open),
              ),
            ),
          ],
          if (pkg.notes.isNotEmpty) ...[
            const SizedBox(height: GzSpace.s4),
            list(
              [for (final n in pkg.notes) item(GzIcons.info, c.iconSecondary, GzText(n.of(lang), role: GzTextRole.caption, color: c.textSecondary))],
              top: GzSpace.s3,
              label: l.uiClientPackageNotCovered,
            ),
          ],
        ],
      ),
    );

    return RepaintBoundary(child: gzPreview(widget.previewState, body(widget.previewState == GzPreviewState.pressed), radius: GzRadius.md));
  }
}
