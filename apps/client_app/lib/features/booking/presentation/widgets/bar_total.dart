import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The figure beside the primary action (web `BarTotal`): a glyph (the voucher ticket, or coins for a plain total; its word is the
/// accessible name) and the all-in total in the figures voice. An estimate keeps its one short word before the figure.
class BookingBarTotal extends StatelessWidget {
  const BookingBarTotal({required this.fils, required this.label, this.icon = GzIcons.ticket, this.estimate = false, this.after, super.key});

  final int fils;
  final IconData icon;

  /// The accessible name of the glyph ("Voucher price").
  final String label;
  final bool estimate;
  final Widget? after;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
          const SizedBox(width: GzSpace.s2),
          if (estimate) ...[
            GzText(context.l10n.clientBookingEstimateLabel, role: GzTextRole.caption, color: c.textSecondary),
            const SizedBox(width: GzSpace.s2),
          ],
          GzPrice(fils: fils, size: GzPriceSize.display),
          ?after,
        ],
      ),
    );
  }
}
