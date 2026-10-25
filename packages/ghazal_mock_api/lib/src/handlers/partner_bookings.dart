/// partner-bookings: voucher redemption by code or QR and the lists of redeemable and redeemed vouchers (voucher-model section 8.2).
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/requests.dart' as dom;
import '../domain/vouchers.dart';
import '../domain/views.dart';
import '../engine/engine.dart';
import 'common.dart';
import 'partner_common.dart';

Json _voucherAndRequest(MockApp app, Json b, Json v) => {'voucher': asSeen(app, v), 'booking': dom.viewBooking(b, role: 'partner'), 'halls': hallRefs(app, b)};

String _normalizeCode(String raw) {
  final s = raw.trim();
  if (s.toLowerCase().startsWith('gz:v1:')) {
    final parts = s.split(':');
    if (parts.length > 2) return parts[2].toUpperCase();
  }
  return s.toUpperCase();
}

/// The redemption checks of voucher-model section 8.2, each with its own calm error.
({String? reason, Json? voucher, Json? booking}) _check(MockApp app, Req r, String rawCode) {
  final code = _normalizeCode(rawCode);
  final v = app.db.firstWhere('Voucher', (d) => d['code'] == code && d['kind'] != 'credit');
  if (v == null) return (reason: 'unknown_code', voucher: null, booking: null);
  if (v['venueOrProviderId'] != r.ctx.targetId) return (reason: 'other_partner', voucher: null, booking: null);
  if (v['status'] == 'used') return (reason: 'already_used', voucher: v, booking: v['bookingId'] == null ? null : app.db.get('Booking', v.str('bookingId')));
  final bid = v.strOrNull('bookingId');
  final b = bid == null ? null : app.db.get('Booking', bid);
  if (b == null || b['status'] != 'confirmed' || v['status'] != 'bound') return (reason: 'not_confirmed', voucher: v, booking: b);
  return (reason: null, voucher: v, booking: b);
}

Map<String, Handler> partnerBookingsHandlers(MockApp app) => {
  'listRedeemableVouchers': (r) {
    final rows = <Json>[];
    for (final b in ctxBookings(app, r)) {
      final v = app.db.peek('Voucher', b.str('voucherId'));
      if (b['status'] == 'confirmed' && v != null && v['status'] == 'bound') rows.add(_voucherAndRequest(app, b, v));
    }
    return pageMap(r, stableSorted(rows, (a, b) => a.obj('booking').str('eventDate').compareTo(b.obj('booking').str('eventDate'))), (x) => x);
  },
  'listRedeemedVouchers': (r) {
    final rows = <Json>[];
    for (final b in ctxBookings(app, r)) {
      final v = app.db.peek('Voucher', b.str('voucherId'));
      if ({'redeemed', 'completed'}.contains(b['status']) && v != null && v['status'] == 'used') rows.add(_voucherAndRequest(app, b, v));
    }
    return pageMap(
      r,
      stableSorted(rows, (a, b) => (b.obj('voucher').strOrNull('usedAt') ?? '').compareTo(a.obj('voucher').strOrNull('usedAt') ?? '')),
      (x) => x,
    );
  },
  'checkVoucherCode': (r) {
    final c = _check(app, r, r.p('code'));
    return {
      'ok': c.reason == null,
      'reason': c.reason,
      'usedAt': (c.reason == 'already_used' && c.voucher != null) ? c.voucher!['usedAt'] : null,
      'voucher': (c.reason == null || c.reason == 'already_used' || c.reason == 'not_confirmed') ? (c.voucher == null ? null : asSeen(app, c.voucher!)) : null,
      'booking': c.booking == null || c.reason == 'unknown_code' || c.reason == 'other_partner' ? null : dom.viewBooking(c.booking!, role: 'partner'),
    };
  },
  'redeemVoucher': (r) {
    app.requirePermission(r, 'voucher:redeem');
    final c = _check(app, r, r.p('code'));
    switch (c.reason) {
      case 'unknown_code':
        throw ApiError('VOUCHER_UNKNOWN');
      case 'other_partner':
        throw ApiError('VOUCHER_OTHER_PARTNER');
      case 'already_used':
        throw ApiError('VOUCHER_ALREADY_USED', params: {'usedAt': c.voucher == null ? null : c.voucher!['usedAt']});
      case 'not_confirmed':
        throw ApiError('VOUCHER_NOT_CONFIRMED');
    }
    final b = dom.redeemBooking(app, c.booking!.str('id'), actorName: actorName(r));
    return _voucherAndRequest(app, b, app.db.require('Voucher', b.str('voucherId')));
  },
};
