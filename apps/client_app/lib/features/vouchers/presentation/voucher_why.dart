import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show VoucherReleaseReason;
import 'package:ghazal_ui/ghazal_ui.dart';

/// Why a released voucher came back: a glyph, one word for the screen and the sentence for the info sheet (web `useWhy`).
typedef VoucherWhy = ({IconData icon, String word, String sentence});

VoucherWhy voucherWhy(BuildContext context, VoucherReleaseReason? reason, String name) {
  final l = context.l10n;
  return switch (reason ?? VoucherReleaseReason.withdrawn) {
    VoucherReleaseReason.declined => (icon: GzIcons.xCircle, word: l.clientVouchersWordDeclined, sentence: l.clientVouchersWhyDeclined(name)),
    VoucherReleaseReason.venueNoResponse => (icon: GzIcons.clockOff, word: l.clientVouchersWordNoResponse, sentence: l.clientVouchersWhyNoResponse(name)),
    VoucherReleaseReason.slotTaken => (icon: GzIcons.calendarX, word: l.clientVouchersWordSlotTaken, sentence: l.clientVouchersWhySlotTaken),
    VoucherReleaseReason.approvalRevoked => (icon: GzIcons.warningCircle, word: l.clientVouchersWordRevoked, sentence: l.clientVouchersWhyRevoked(name)),
    VoucherReleaseReason.venueCancelled => (icon: GzIcons.calendarX, word: l.clientVouchersWordVenueCancelled, sentence: l.clientVouchersWhyVenueCancelled(name)),
    VoucherReleaseReason.partnerSuspended => (icon: GzIcons.pause, word: l.clientVouchersWordSuspended, sentence: l.clientVouchersWhySuspended(name)),
    _ => (icon: GzIcons.undo, word: l.clientVouchersWordWithdrawn, sentence: l.clientVouchersWhyWithdrawn),
  };
}
