import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart';

/// The hero story of the vouchers flow (web `STORY_*` codes of `design/src/screens/client/vouchers/_components/model.ts`): Reem's voucher
/// of the hero request, her released one (venue did not reply), the forfeited, the credit-issued and the credit voucher. A screen opened
/// without a route param shows these so the harness and the demo tools can open any frame.
const String kVoucherHeroId = 'vch-GV-2611-K7QM';
const String kVoucherReleasedId = 'vch-GV-2611-R4TF';
const String kVoucherCreditId = 'vch-GV-2611-C4RD';

/// The hero voucher as the static frames show it (web `readyVariantOf`): an
/// issued voucher that has not met a request yet (`active`, no booking, no
/// release). A screen opened WITHOUT a voucher param shows this; a real id
/// always shows its own record.
VoucherDetail readyVariantOf(VoucherDetail d) {
  final v = d.voucher;
  if (v is! Voucher) return d;
  return d.copyWith(voucher: v.copyWith(status: VoucherStatus.active, bookingId: null, releasedAt: null, releaseReason: null, reuseUntil: null, creditEligible: false), booking: null);
}

/// The days inside which a ready voucher says "Expires" in the gold ink (inventory CL-VCHR-02).
const int kExpiringDays = 7;

/// One word for where a voucher is (web `phaseOf`).
enum VoucherPhase { ready, pending, approved, confirmed, redeemed, consumed, released, expired, forfeited, creditIssued, unpaid }

VoucherPhase phaseOf(Voucher v, Booking? booking) => switch (v.status) {
  VoucherStatus.unpaid => VoucherPhase.unpaid,
  VoucherStatus.active => v.releaseReason != null || v.reuseUntil != null ? VoucherPhase.released : VoucherPhase.ready,
  VoucherStatus.bound => switch (booking?.status) {
    BookingStatus.approved => VoucherPhase.approved,
    BookingStatus.confirmed => VoucherPhase.confirmed,
    _ => VoucherPhase.pending,
  },
  VoucherStatus.used => v.usedReason == VoucherUsedReason.cancelledAfterConfirm ? VoucherPhase.consumed : VoucherPhase.redeemed,
  VoucherStatus.expired => VoucherPhase.expired,
  VoucherStatus.forfeited => VoucherPhase.forfeited,
  VoucherStatus.creditIssued => VoucherPhase.creditIssued,
  VoucherStatus.unknown => VoucherPhase.expired,
};

/// The three groups of the wallet (web `segmentOf`).
enum WalletSegment { ready, request, history }

WalletSegment segmentOf(WalletVoucher v) => switch (v.status) {
  VoucherStatus.active => WalletSegment.ready,
  VoucherStatus.bound || VoucherStatus.unpaid => WalletSegment.request,
  _ => WalletSegment.history,
};

/// The end of what a voucher can still do: the reuse window while released, else the validity end (an absolute date, Kuwait).
String? endsOnIso(GzFormat f, WalletVoucher v) {
  if (v is Voucher && v.status == VoucherStatus.active && v.reuseUntil != null) return v.reuseUntil.toString();
  return v.validUntil == null ? null : f.isoDay(v.validUntil!);
}

int? daysToEnd(GzFormat f, WalletVoucher v) {
  final end = endsOnIso(f, v);
  return end == null ? null : f.daysUntil(end);
}

/// The target a wallet row or detail names: venue or provider, hall, package and the thumbnail source.
class VoucherFacts {
  const VoucherFacts({required this.target, this.hallName, this.packageName});

  final TargetSummary? target;
  final LocalizedText? hallName;
  final LocalizedText? packageName;

  bool get isProvider => target?.kind == BookingTargetType.provider;
}
