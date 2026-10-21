import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart'
    show CardPriceExact, LocalDate, LocalizedText, MoneyAmount, PriceTier, Venue, VenueBadge, VenueDayState;

import '../client/client.dart' show GzVenueCard, GzVenueCardVariant, gzVenueSummaryOf;
import '../core/core.dart';
import '../foundation.dart';
import 'hotel_c_kit.dart';

/// VoucherWindowPreview: "what couples see" while the partner edits a voucher-price window (HL-GROW-02 / 03; HA-OFFR superseded by
/// ADR 0033). It is the client's own venue card, drawn with the draft window: the photo with the "Special voucher price" badge, the
/// wall label and the card price line with the voucher price as the headline and the standard price struck through (the real
/// standard price, never an invented anchor). Under it, the line a couple reads at checkout: the window title and the saving it
/// makes against the standard price, in exact money. It updates as values change, instantly: a changed figure swaps, it never
/// counts up (ADR 0017 D7).
class GzVoucherWindowPreview extends StatelessWidget {
  const GzVoucherWindowPreview({
    required this.venue,
    required this.standard,
    required this.voucher,
    required this.guests,
    required this.packageId,
    required this.date,
    required this.title,
    this.area,
    super.key,
  });

  final Venue venue;

  /// Standard and window voucher amounts for the example booking, integer fils, and the guests it is for.
  final int standard;
  final int voucher;
  final int guests;
  final String packageId;

  /// The date shown on the availability line.
  final LocalDate date;

  /// The area name of the venue (the screen resolves `venue.areaId`).
  final LocalizedText? area;

  /// The window title in the current language (the screen supplies it from the editor field).
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final saving = standard > voucher ? standard - voucher : 0;
    final cheaper = voucher < standard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzText(l.uiHotelWindowLabel, role: GzTextRole.label, color: c.textSecondary),
        const SizedBox(height: GzSpace.s3),
        GzVenueCard(
          venue: gzVenueSummaryOf(venue),
          area: area,
          variant: GzVenueCardVariant.list,
          badge: VenueBadge.window,
          availability: VenueDayState.available,
          date: date,
          price: CardPriceExact(
            amount: MoneyAmount(standard),
            guests: guests,
            packageId: packageId,
            tier: PriceTier.weekend,
            voucher: cheaper ? MoneyAmount(voucher) : null,
            savings: cheaper ? MoneyAmount(saving) : null,
          ),
        ),
        const SizedBox(height: GzSpace.s3),
        Container(
          padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: GzFigText('$title · ${l.uiHotelWindowSaving}'.trim(), role: GzTextRole.bodyS, color: c.textPrimary),
              ),
              const SizedBox(width: GzSpace.s4),
              GzMoney(fils: saving, mode: GzMoneyMode.exact, amountRole: GzTextRole.priceStrong),
            ],
          ),
        ),
      ],
    );
  }
}
