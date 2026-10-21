import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions, gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/booking_flow_model.dart';
import '../booking_glyphs.dart';
import 'booking_fields.dart';
import 'booking_layout.dart';
import 'quote_lines.dart';

/// One package as the single decision of step 2 (web `PackageChoice`). A radio card: ink border and a check on the choice (never gold
/// alone), the serif name, the two prices of the same quote (the voucher total as the number that matters: a ticket for a member, a lock
/// for a guest, voucher-model 4.5; the standard total quiet and struck; the saving after the fee), the basis as facts, and what the
/// package includes as a row of glyphs with an info glyph that opens the package sheet. A package with no voucher price shows its
/// standard total alone and two words.
class BookingPackageChoice extends ConsumerWidget {
  const BookingPackageChoice({
    required this.option,
    required this.guests,
    required this.selected,
    required this.guest,
    required this.elsewhere,
    required this.onSelect,
    required this.onDetails,
    super.key,
  });

  final PricedPackage option;
  final int guests;
  final bool selected;
  final bool guest;
  final bool elsewhere;
  final VoidCallback onSelect;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    String money(int fils) => f.money(fils, const MoneyOptions(mode: MoneyMode.browse));
    final pkg = option.pkg;
    final per = option.perGuest;
    final glyphs = inclusionGlyphs(pkg.inclusions, context.bi);
    final billed = option.billed ?? guests;
    final head = <Widget>[
      GzText(context.bi(pkg.name), role: GzTextRole.d1, color: c.textStrong),
      if (option.hasVoucher)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s2,
          children: [
            GzIcon(
              guest ? GzIcons.lock : GzIcons.ticket,
              size: GzIconSize.md,
              color: guest ? c.iconSecondary : c.iconSuccess,
              semanticLabel: l10n.commonVoucherPrice,
            ),
            GzPrice(fils: option.voucher!, size: GzPriceSize.total),
          ],
        )
      else
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s2,
          children: [
            GzPrice(fils: option.standard, size: GzPriceSize.total),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s1),
                GzText(l10n.clientBookingPackageNoVoucher, role: GzTextRole.caption, color: c.textSecondary),
              ],
            ),
          ],
        ),
      if (option.hasVoucher)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s3,
          runSpacing: GzSpace.s1,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(GzIcons.offer, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: l10n.commonStandardPrice),
                  const SizedBox(width: GzSpace.s1),
                  BookingStruck(fils: option.standard),
                ],
              ),
            ),
            BookingSavePill(fils: option.net, semantic: l10n.commonYouSave(money(option.net))),
          ],
        ),
      GzFactRow(
        children: [
          if (per != null)
            GzFactChip(icon: GzIcons.perGuest, label: l10n.commonUnitPerGuest, value: money(per), small: true, tone: GzFactTone.muted)
          else
            GzFactChip(icon: GzIcons.package, label: l10n.clientBookingPackageFlat, small: true, tone: GzFactTone.muted),
          GzFactChip(
            icon: GzIcons.usersThree,
            label: l10n.clientBookingGuestsLabel,
            value: f.integer(billed > guests ? billed : guests),
            small: true,
            tone: GzFactTone.muted,
          ),
        ],
      ),
    ];
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: selected ? c.controlChipBorderSelected : c.borderStrong, width: GzStroke.hair),
      ),
      child: BookingGap(
        gap: GzSpace.s3,
        children: [
          GzPressable(
            onPressed: onSelect,
            semanticLabel:
                '${context.bi(pkg.name)}${selected ? ', ${l10n.clientBookingPackageSelected}' : ''}${elsewhere ? ', ${l10n.clientBookingPackageChangeVoucher}' : ''}',
            selected: selected,
            minWidth: 0,
            minHeight: 0,
            scale: 1,
            borderRadius: GzRadius.smAll,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsetsDirectional.only(top: GzSpace.s1),
                  child: SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
                  child: BookingMark(on: selected),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: BookingGap(gap: GzSpace.s2, cross: CrossAxisAlignment.start, children: head),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GzFactRow(
                    label: l10n.clientBookingPackageIncludes,
                    children: [for (final g in glyphs) GzFactChip(icon: g.icon, label: g.label, small: true, tone: GzFactTone.muted)],
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                EndBleed(
                  child: GzIconButton(icon: GzIcons.info, iconSize: GzIconSize.sm, label: l10n.clientBookingPackageDetails, onPressed: onDetails),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The skeleton of a package card.
class BookingPackageSkeleton extends StatelessWidget {
  const BookingPackageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: const BookingGap(
        gap: GzSpace.s3,
        cross: CrossAxisAlignment.start,
        children: [
          GzSkeleton(inlineSize: 200, blockSize: 28),
          GzSkeleton(inlineSize: 120, blockSize: 28),
          GzSkeleton(blockSize: 20),
          GzSkeleton(inlineSize: 160, blockSize: 20),
        ],
      ),
    );
  }
}
