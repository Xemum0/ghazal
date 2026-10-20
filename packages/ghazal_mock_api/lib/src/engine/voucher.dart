/// The voucher rules of docs/product/voucher-model.md sections 4 and 13 as pure functions: price columns of the seed, code and QR payload,
/// validity and reuse, the release and credit table (ADR 0035). Numbers come from the platform config, never from literals. Port of engine/voucher.ts.
library;

import 'dates.dart';
import 'json.dart';
import 'seeded.dart';

int voucherDiscountBps(String targetId, {required int min, required int max}) {
  final lo = min + 200;
  final hi = max - 200;
  return lo + (seeded(['voucher-discount', targetId]) * (hi - lo + 1)).floor();
}

/// Voucher price of a standard price: discount, rounded to [stepFils], clamped so the discount stays inside the bounds.
int voucherPrice(int standardFils, int bps, int stepFils, {required int min, required int max}) {
  final raw = (standardFils * (10000 - bps)) / 10000;
  var v = jsRound(raw / stepFils) * stepFils;
  final maxV = (((standardFils * (10000 - min)) / 10000) / stepFils).floor() * stepFils;
  final minV = (((standardFils * (10000 - max)) / 10000) / stepFils).ceil() * stepFils;
  if (v > maxV) v = maxV;
  if (v < minV) v = minV;
  return v;
}

/// Realised discount in basis points, half-up.
int discountBps(int standardFils, int voucherFils) => jsRound(((standardFils - voucherFils) * 10000) / standardFils);

const _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// Four Crockford base32 characters from the parts (never I, L, O or U).
String crockford4(List<Object> parts) {
  var h = hash32(['crockford', ...parts]);
  var out = '';
  for (var i = 0; i < 4; i++) {
    out += _crockford[h & 31];
    h >>= 5;
    if (i == 2) h ^= hash32(['c2', ...parts]) >> 3;
  }
  return out;
}

/// GV-YYMM-XXXX with the month of purchase.
String voucherCode(String purchasedAt, List<Object> parts) => 'GV-${purchasedAt.substring(2, 4)}${purchasedAt.substring(5, 7)}-${crockford4(parts)}';

final voucherCodePattern = RegExp(r'^GV-(\d{4})-([0-9A-HJKMNP-TV-Z]{4})$');

/// The payload the QR renders: version, code, target and a short check.
Json qrPayload(String code, String targetId) {
  final check = (hash32(['qr', code, targetId]) & 0xffff).toRadixString(16).toUpperCase().padLeft(4, '0');
  return {'payload': 'gz:v1:$code:$targetId:$check', 'version': 1};
}

/// Eligibility test of the voucher CTA: the saving must beat the fee (voucher-model section 4.1).
bool voucherPaysForItself(int savingsFils, int voucherFeeFils) => savingsFils > voucherFeeFils;

/// End of validity: payment plus 60 days, never later than the end of the event date plus 12 hours (A-02).
String voucherValidUntil(String purchasedAt, String eventDate, {required int voucherValidityDays, required int completionDelayHours}) {
  final byPolicy = addHours(purchasedAt, voucherValidityDays * 24);
  final eventEnd = addHours('${addDays(eventDate, 1)}T02:00:00+03:00', completionDelayHours);
  return instantMs(byPolicy) <= instantMs(eventEnd) ? byPolicy : eventEnd;
}

/// The reuse window opened by a release: 60 days at the same target.
String voucherReuseUntil(String releasedAt, {required int voucherReuseDays}) => addDays(kuwaitDateOf(releasedAt), voucherReuseDays);

/// What a release does to the voucher, by reason: `{reusable, creditEligible}`.
({bool reusable, bool creditEligible}) releaseOutcome(String reason) {
  switch (reason) {
    case 'declined':
    case 'venue_no_response':
    case 'slot_taken':
    case 'approval_revoked':
    case 'venue_cancelled':
    case 'partner_suspended':
      return (reusable: true, creditEligible: true);
    case 'withdrawn':
    default:
      return (reusable: true, creditEligible: false);
  }
}

/// Status after a request ends, from the voucher's side.
String voucherStatusAfter(String kind) {
  switch (kind) {
    case 'release':
      return 'active';
    case 'redeemed':
    case 'completed':
    case 'cancelled_after_confirm':
      return 'used';
    case 'validity_ended':
      return 'expired';
    case 'forfeited':
      return 'forfeited';
    case 'credit_issued':
      return 'credit_issued';
  }
  throw ArgumentError('unknown voucher outcome $kind');
}

/// Validity end of a credit voucher granted by support: 60 days from the grant, usable at any venue or service.
String creditVoucherValidUntil(String grantedAt, {required int creditVoucherValidityDays}) => '${addDays(kuwaitDateOf(grantedAt), creditVoucherValidityDays)}T23:59:00+03:00';

/// Whether an `active` voucher is past its validity at [now] (a reuse window keeps a released voucher alive).
bool isVoucherExpired(String? validUntil, String? reuseUntil, String now) {
  if (validUntil != null && instantMs(now) > instantMs(validUntil)) {
    return !(reuseUntil != null && kuwaitDateOf(now).compareTo(reuseUntil) <= 0);
  }
  return false;
}

/// The 24 h confirm deadline of an approval (owner rule, fixed).
String confirmByFor(String approvedAt, {required int confirmWindowHours}) => addHours(approvedAt, confirmWindowHours);

/// Days left of a validity or reuse window, for "valid for N more days".
int daysLeft(String until, String now) => diffDays(kuwaitDateOf(now), until);
