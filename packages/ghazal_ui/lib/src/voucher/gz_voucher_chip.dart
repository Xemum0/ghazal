import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// `ready` (green), `bound` (gold tint: attached to a live request), `quiet` (used, expired).
enum GzVoucherChipTone { ready, bound, quiet }

/// VoucherChip: the small ticket chip beside a request or a price: a ticket glyph and the last four characters of the code
/// (`K7QM`); the word "Voucher" is its accessible name. Informative only (never a button, never a gold fill), so the 44 dp
/// target does not apply. 24 high, radius 4, the status-pill shape.
class GzVoucherChip extends StatelessWidget {
  const GzVoucherChip({required this.code, this.tone = GzVoucherChipTone.bound, super.key});

  /// The voucher code; only its last four characters show.
  final String code;
  final GzVoucherChipTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final last4 = code.length > 4 ? code.substring(code.length - 4) : code;
    final (Color? bg, Color? border, Color fg) = switch (tone) {
      GzVoucherChipTone.bound => (c.surfaceTint, null, c.textStrong),
      GzVoucherChipTone.ready => (c.statusSuccessBg, null, c.statusSuccessText),
      GzVoucherChipTone.quiet => (null, c.borderStrong, c.textSecondary),
    };
    return Semantics(
      label: '${context.gzL10n.uiSharedVoucher} $last4',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: GzRadius.xsAll, border: Border.all(color: border ?? c.scrimClear, width: GzStroke.hair)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.pillMin),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2 + GzStroke.hair, vertical: GzSpace.s1 + GzStroke.hair),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: fg),
                const SizedBox(width: GzSpace.s1),
                GzNum(last4, role: GzTextRole.figCaption, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
