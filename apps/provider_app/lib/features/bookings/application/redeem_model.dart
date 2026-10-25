// The model of the redeem screens (web `redeem-model.ts`): the typed part of a voucher code and its grouping, and the outcome of a check as
// the one of the specific, calm cases of voucher-model 8.2. No client data is read until the code belongs to this partner.
import 'package:ghazal_domain/ghazal_domain.dart';

const String kCodePrefix = 'GV-';

/// `2611-K7QM` from anything typed or pasted: upper case, letters and digits only, a leading GV dropped, grouped 4 - 4.
String formatTyped(String raw) {
  var clean = raw.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  if (clean.startsWith('GV')) clean = clean.substring(2);
  if (clean.length > 8) clean = clean.substring(0, 8);
  return clean.length > 4 ? '${clean.substring(0, 4)}-${clean.substring(4)}' : clean;
}

bool isComplete(String typed) => typed.replaceAll('-', '').length == 8;

String fullCode(String typed) => '$kCodePrefix$typed';

String typedPart(String code) => formatTyped(code);

sealed class RedeemOutcome {
  const RedeemOutcome();
}

final class OutcomeReady extends RedeemOutcome {
  const OutcomeReady(this.voucher, this.booking);
  final Voucher voucher;
  final Booking booking;
}

final class OutcomeUnknown extends RedeemOutcome {
  const OutcomeUnknown();
}

/// The code exists but belongs to another partner: nothing about the other party is revealed.
final class OutcomeOtherPartner extends RedeemOutcome {
  const OutcomeOtherPartner();
}

final class OutcomeNotConfirmed extends RedeemOutcome {
  const OutcomeNotConfirmed(this.booking);
  final Booking? booking;
}

final class OutcomeAlreadyUsed extends RedeemOutcome {
  const OutcomeAlreadyUsed(this.usedAt);
  final DateTime? usedAt;
}

final class OutcomeExpired extends RedeemOutcome {
  const OutcomeExpired();
}

RedeemOutcome outcomeOf(RedeemCheck c) {
  if (c.ok && c.voucher != null && c.booking != null) return OutcomeReady(c.voucher!, c.booking!);
  switch (c.reason) {
    case RedeemFailure.otherPartner:
      return const OutcomeOtherPartner();
    case RedeemFailure.notConfirmed:
      final v = c.voucher;
      if (v != null && (v.status == VoucherStatus.expired || v.status == VoucherStatus.forfeited || v.status == VoucherStatus.creditIssued)) return const OutcomeExpired();
      return OutcomeNotConfirmed(c.booking);
    case RedeemFailure.alreadyUsed:
      return OutcomeAlreadyUsed(c.usedAt ?? c.voucher?.usedAt);
    default:
      return const OutcomeUnknown();
  }
}
