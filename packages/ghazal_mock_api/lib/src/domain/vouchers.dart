/// The voucher lifecycle (docs/product/voucher-model.md, ADR 0033 and 0035): checkout and payment sessions, activation, binding to a request,
/// release with the reuse window, redemption, forfeiture, expiry, credit vouchers granted after a refund request. States: unpaid, active, bound,
/// used, expired, forfeited, credit_issued.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../engine/engine.dart';
import 'notify.dart';
import 'views.dart';

/// Creates the unpaid voucher of a checkout (the engine quote decides the price columns).
Json newUnpaidVoucher(
  MockApp app, {
  required String clientId,
  required String targetType,
  required String targetId,
  String? hallId,
  required String packageId,
  required String eventDate,
  int? guests,
  required Json quote,
}) {
  final seq = app.db.next('voucher');
  var code = voucherCode(app.now, ['vch', seq, clientId, targetId, eventDate]);
  var tries = 0;
  while (app.db.raw('Voucher').any((v) => v['code'] == code) && tries++ < 20) {
    code = voucherCode(app.now, ['vch', seq, tries, clientId, targetId, eventDate]);
  }
  final totals = quote.obj('totals');
  final doc = <String, dynamic>{
    'id': 'vch-$code',
    'kind': 'bound',
    'code': code,
    'clientId': clientId,
    'targetType': targetType,
    'venueOrProviderId': targetId,
    'hallId': hallId,
    'packageId': packageId,
    'eventDate': eventDate,
    'guests': guests,
    'quoteFils': {'standard': filsOf(totals.obj('standardTotal')), 'voucher': filsOf(totals.obj('voucherTotal'))},
    'priceFils': app.voucherFeeFils,
    'status': 'unpaid',
    'purchasedAt': null,
    'validUntil': null,
    'reuseUntil': null,
    'qr': qrPayload(code, targetId),
    'bookingId': null,
    'payment': null,
    'releasedAt': null,
    'releaseReason': null,
    'forfeitedAt': null,
    'creditEligible': false,
    'refundRequestId': null,
    'usedAt': null,
    'usedReason': null,
    'redeemedBy': null,
    '_checkoutAt': app.now,
    '_checkoutExpiresAt': app.clock.after(Duration(minutes: app.platformConfig.integer('voucherCheckoutMinutes'))),
  };
  app.db.put('Voucher', doc);
  app.logEvent('voucher_checkout', {'voucherId': doc['id'], 'code': code});
  return doc;
}

/// A payment session for an unpaid voucher; the gateway "answers" after [MockConfig.gatewayDelay] (or when the control endpoint settles it).
Json newPaymentSession(MockApp app, {required Json voucher, required String method, String? returnUrl}) {
  final seq = app.db.next('payment', 1000);
  final id = 'pay-$seq';
  final doc = <String, dynamic>{
    'id': id,
    'voucherId': voucher['id'],
    'method': method,
    'status': 'created',
    'amount': fils(voucher.integer('priceFils')),
    'redirectUrl': 'https://pay.ghazal.example/mock/$id',
    'expiresAt': app.clock.after(const Duration(minutes: 30)),
    'failureCode': null,
    '_returnUrl': returnUrl,
    '_kind': 'voucher',
  };
  app.db.put('Payment', doc);
  app.scheduler.after(app.config.gatewayDelay, () => settlePayment(app, id, 'succeeded'));
  return doc;
}

/// A payment session for a listing fee (only possible once the owner decided the plan rates).
Json newListingPaymentSession(MockApp app, {required Json listing, required String method, required int amountFils, String? returnUrl}) {
  final id = 'pay-${app.db.next('payment', 1000)}';
  final doc = <String, dynamic>{
    'id': id,
    'voucherId': listing['id'],
    'method': method,
    'status': 'created',
    'amount': fils(amountFils),
    'redirectUrl': 'https://pay.ghazal.example/mock/$id',
    'expiresAt': app.clock.after(const Duration(minutes: 30)),
    'failureCode': null,
    '_returnUrl': returnUrl,
    '_kind': 'listing',
    '_listingId': listing['id'],
  };
  app.db.put('Payment', doc);
  app.scheduler.after(app.config.gatewayDelay, () => settlePayment(app, id, 'succeeded'));
  return doc;
}

/// Settles a payment session: `succeeded` activates the voucher, `failed` and `cancelled` leave it unpaid. A second call changes nothing.
Json settlePayment(MockApp app, String paymentId, String outcome) {
  final p = app.db.get('Payment', paymentId) ?? (throw ApiError.notFound('payment'));
  if (p['status'] == 'succeeded' || p['status'] == 'failed' || p['status'] == 'cancelled') return p;
  p['status'] = outcome;
  if (outcome != 'succeeded') p['failureCode'] = outcome == 'failed' ? 'declined' : 'cancelled_by_user';
  app.db.put('Payment', p);
  if (p['_kind'] == 'listing') {
    final l = app.db.get('Listing', p.str('_listingId'));
    if (l != null && outcome == 'succeeded') {
      l['billing'] = {'status': 'paid', 'amountFils': filsOf(p.obj('amount')), 'paidAt': app.now};
      if (l['status'] == 'payment_pending' || l['status'] == 'draft') {
        final from = l.str('status');
        l['status'] = 'pending_review';
        (l['history'] as List).add({
          'id': 'rev-m${app.db.next('decision').toString().padLeft(4, '0')}',
          'listingId': l['id'],
          'at': app.now,
          'from': from,
          'to': 'pending_review',
          'actor': 'system',
        });
        l['submittedAt'] ??= app.now;
      }
      app.db.put('Listing', l);
    }
    return p;
  }
  if (outcome == 'succeeded') {
    final v = app.db.get('Voucher', p.str('voucherId'));
    if (v != null && v['status'] == 'unpaid') {
      final cfg = app.platformConfig;
      v['status'] = 'active';
      v['purchasedAt'] = app.now;
      v['validUntil'] = voucherValidUntil(
        app.now,
        v.str('eventDate'),
        voucherValidityDays: cfg.integer('voucherValidityDays'),
        completionDelayHours: cfg.integer('completionDelayHours'),
      );
      v['payment'] = {
        'method': p['method'],
        'receiptNo': 'RC-${app.db.next('receipt', 60000).toString().padLeft(6, '0')}',
        'amount': fils(v.integer('priceFils')),
        'status': 'succeeded',
        'at': app.now,
      };
      v.remove('_checkoutAt');
      v.remove('_checkoutExpiresAt');
      app.db.put('Voucher', v);
      notify(
        app,
        userId: v.str('clientId'),
        kind: 'voucher_ready',
        audience: 'client',
        vars: {
          'venue': app.targetName(
            venueId: v['targetType'] == 'venue' ? v.str('venueOrProviderId') : null,
            providerId: v['targetType'] == 'provider' ? v.str('venueOrProviderId') : null,
          ),
          'code': v.str('code'),
        },
        params: {'code': v['code'], 'target': v['venueOrProviderId']},
        venueId: v['targetType'] == 'venue' ? v.str('venueOrProviderId') : null,
        voucherId: v.str('id'),
      );
    }
  }
  app.logEvent('payment_$outcome', {'paymentId': paymentId, 'voucherId': p['voucherId']});
  return p;
}

/// Discards unpaid vouchers whose checkout window (30 minutes) has lapsed: nothing was charged, nothing is kept.
void lapseCheckouts(MockApp app) {
  final nowMs = instantMs(app.now);
  for (final v in app.db.raw('Voucher').toList()) {
    if (v['status'] == 'unpaid' && v['_checkoutExpiresAt'] != null && nowMs > instantMs(v.str('_checkoutExpiresAt'))) {
      app.db.remove('Voucher', v.str('id'));
      app.db.put('LapsedCheckout', {'id': v['id']});
      app.logEvent('voucher_checkout_lapsed', {'voucherId': v['id']});
    }
  }
}

/// `active` vouchers past validity (and past any reuse window) become `expired`.
void expireVouchers(MockApp app) {
  for (final v in app.db.raw('Voucher').toList()) {
    if (v['status'] == 'active' && v['kind'] == 'bound' && isVoucherExpired(v.strOrNull('validUntil'), v.strOrNull('reuseUntil'), app.now)) {
      final c = deepCopy(v)..['status'] = 'expired';
      app.db.put('Voucher', c);
      app.logEvent('voucher_expired', {'voucherId': v['id']});
    } else if (v['status'] == 'active' && v['kind'] == 'credit' && v['validUntil'] != null && instantMs(app.now) > instantMs(v.str('validUntil'))) {
      app.db.put('Voucher', deepCopy(v)..['status'] = 'expired');
    }
  }
}

/// Binds an active voucher to a request (R01). Credit vouchers are converted to bound ones at that moment (ADR 0035 D5).
Json bindVoucher(
  MockApp app,
  Json voucher, {
  required String bookingId,
  required String targetType,
  required String targetId,
  String? hallId,
  required String packageId,
  required String eventDate,
  int? guests,
  required Json quote,
}) {
  final v = deepCopy(voucher);
  if (v['kind'] == 'credit') {
    final cfgDays = app.platformConfig.integer('voucherValidityDays');
    v
      ..['kind'] = 'bound'
      ..['_creditOrigin'] = true
      ..['purchasedAt'] = v['grantedAt']
      ..['reuseUntil'] = null
      ..['payment'] = null
      ..['releasedAt'] = null
      ..['releaseReason'] = null
      ..['forfeitedAt'] = null
      ..['creditEligible'] = false
      ..['refundRequestId'] = null
      ..['validUntil'] = v['validUntil'] ?? addHours(app.now, cfgDays * 24);
    v.remove('grantedAt');
    v.remove('grantedFrom');
  }
  final totals = quote.obj('totals');
  v
    ..['targetType'] = targetType
    ..['venueOrProviderId'] = targetId
    ..['hallId'] = hallId
    ..['packageId'] = packageId
    ..['eventDate'] = eventDate
    ..['guests'] = guests
    ..['quoteFils'] = {'standard': filsOf(totals.obj('standardTotal')), 'voucher': filsOf(totals.obj('voucherTotal'))}
    ..['status'] = 'bound'
    ..['bookingId'] = bookingId
    ..['qr'] = qrPayload(v.str('code'), targetId)
    ..['releasedAt'] = null
    ..['releaseReason'] = null
    ..['reuseUntil'] = null
    ..['creditEligible'] = false;
  app.db.put('Voucher', v);
  return v;
}

/// Releases a bound voucher back to `active` with its 60-day reuse window; credit-eligible when the venue side was the reason (ADR 0035 D4).
Json releaseVoucher(MockApp app, String voucherId, String reason) {
  final v = app.db.require('Voucher', voucherId);
  final outcome = releaseOutcome(reason);
  v
    ..['status'] = 'active'
    ..['bookingId'] = null
    ..['releasedAt'] = app.now
    ..['releaseReason'] = reason
    ..['reuseUntil'] = voucherReuseUntil(app.now, voucherReuseDays: app.platformConfig.integer('voucherReuseDays'))
    ..['creditEligible'] = outcome.creditEligible;
  app.db.put('Voucher', v);
  app.logEvent('voucher_released', {'voucherId': voucherId, 'reason': reason});
  return v;
}

/// Consumes the voucher (`used`): redeemed by the partner, completed, or cancelled after confirm.
Json useVoucher(MockApp app, String voucherId, String reason, {String? by}) {
  final v = app.db.require('Voucher', voucherId);
  v
    ..['status'] = voucherStatusAfter(reason == 'redeemed' ? 'redeemed' : (reason == 'completed' ? 'completed' : 'cancelled_after_confirm'))
    ..['usedAt'] = app.now
    ..['usedReason'] = reason
    ..['redeemedBy'] = by ?? v['redeemedBy'];
  app.db.put('Voucher', v);
  return v;
}

/// The 24 h confirm window lapsed: the voucher is forfeited, never comes back.
Json forfeitVoucher(MockApp app, String voucherId) {
  final v = app.db.require('Voucher', voucherId);
  v
    ..['status'] = 'forfeited'
    ..['bookingId'] = null
    ..['forfeitedAt'] = app.now;
  app.db.put('Voucher', v);
  app.logEvent('voucher_forfeited', {'voucherId': voucherId});
  return v;
}

/// The credit voucher a granted refund request creates (usable at any venue or service for 60 days).
Json grantCreditVoucher(MockApp app, Json refund, {String grantedBy = 'Ghazal Support'}) {
  final src = app.db.require('Voucher', refund.str('voucherId'));
  final seq = app.db.next('credit');
  final code = voucherCode(app.now, ['credit', seq, refund.str('id'), src.str('code')]);
  final credit = <String, dynamic>{
    'id': 'vch-$code',
    'kind': 'credit',
    'code': code,
    'clientId': refund['clientId'],
    'priceFils': app.voucherFeeFils,
    'status': 'active',
    'validUntil': creditVoucherValidUntil(app.now, creditVoucherValidityDays: app.platformConfig.integer('creditVoucherValidityDays')),
    'qr': qrPayload(code, 'credit'),
    'usedAt': null,
    'usedReason': null,
    'redeemedBy': null,
    'grantedAt': app.now,
    'grantedFrom': {'requestId': refund['id'], 'voucherId': src['id'], 'grantedBy': grantedBy},
    'bookingId': null,
  };
  app.db.put('Voucher', credit);
  src['status'] = voucherStatusAfter('credit_issued');
  app.db.put('Voucher', src);
  return credit;
}

// ---------------------------------------------------------------- read models

int _rank(String status) => const {'bound': 0, 'active': 1, 'unpaid': 2, 'used': 3, 'expired': 4, 'forfeited': 5, 'credit_issued': 6}[status] ?? 9;

/// A voucher as the wallet shows it: an `active` voucher past its validity reads as `expired` even before the sweep persists it.
Json asSeen(MockApp app, Json v) {
  final c = deepCopy(v);
  if (c['status'] == 'active' && c['kind'] == 'bound' && isVoucherExpired(c.strOrNull('validUntil'), c.strOrNull('reuseUntil'), app.now)) {
    c['status'] = 'expired';
  }
  if (c['status'] == 'active' && c['kind'] == 'credit' && c['validUntil'] != null && instantMs(app.now) > instantMs(c.str('validUntil'))) {
    c['status'] = 'expired';
  }
  return wire(c);
}

/// The wallet of a client in the order of the prototype: credit vouchers ready, bound vouchers by state, ended credit vouchers.
List<Json> walletOf(MockApp app, String clientId) {
  final mine = [
    for (final v in app.db.raw('Voucher'))
      if (v['clientId'] == clientId) asSeen(app, v),
  ];
  final credit = stableSorted(mine.where((v) => v['kind'] == 'credit'), (a, b) => b.str('grantedAt').compareTo(a.str('grantedAt')));
  final bound = stableSorted(mine.where((v) => v['kind'] != 'credit'), (a, b) {
    final c = _rank(a.str('status')) - _rank(b.str('status'));
    return c != 0 ? c : (b.strOrNull('purchasedAt') ?? '').compareTo(a.strOrNull('purchasedAt') ?? '');
  });
  return [...credit.where((c) => c['status'] == 'active'), ...bound, ...credit.where((c) => c['status'] != 'active')];
}

Json walletItem(MockApp app, Json v) {
  final bound = v['kind'] == 'bound';
  Json? target;
  Json? hallName;
  Json? packageName;
  if (bound && v['venueOrProviderId'] != null) {
    final isVenue = v['targetType'] == 'venue';
    target = targetSummary(app, venueId: isVenue ? v.str('venueOrProviderId') : null, providerId: isVenue ? null : v.str('venueOrProviderId'));
    if (isVenue) {
      final venue = app.db.peek('Venue', v.str('venueOrProviderId'));
      for (final h in venue?.list('halls') ?? const <Json>[]) {
        if (h['id'] == v['hallId']) hallName = h.obj('name');
      }
      packageName = app.db.peek('Package', v.str('packageId'))?.obj('name');
    } else {
      final prov = app.db.peek('ServiceProvider', v.str('venueOrProviderId'));
      for (final p in prov?.list('packages') ?? const <Json>[]) {
        if (p['id'] == v['packageId']) packageName = p.obj('name');
      }
    }
  }
  return {'voucher': v, 'target': target, 'hallName': hallName, 'packageName': packageName};
}

Json voucherOptions(Json v) {
  if (v['status'] != 'active' || v['kind'] == 'credit') return {'reusable': false, 'creditEligible': false, 'reusableUntil': null};
  final reason = v.strOrNull('releaseReason');
  final outcome = reason != null ? releaseOutcome(reason) : (reusable: true, creditEligible: false);
  return {'reusable': outcome.reusable, 'creditEligible': v.flag('creditEligible') && v['refundRequestId'] == null, 'reusableUntil': v['reuseUntil']};
}

/// `Receipt` rows derived from the paid vouchers of a client, newest first.
List<Json> receiptsOf(MockApp app, String clientId) {
  final rows = <Json>[];
  for (final v in app.db.raw('Voucher')) {
    final pay = v.objOrNull('payment');
    if (v['clientId'] != clientId || pay == null) continue;
    final isVenue = v['targetType'] == 'venue';
    rows.add({
      'receiptNo': pay['receiptNo'],
      'voucherId': v['id'],
      'voucherCode': v['code'],
      'amount': pay['amount'],
      'method': pay['method'],
      'status': pay['status'],
      'at': pay['at'],
      'target': targetSummary(app, venueId: isVenue ? v.str('venueOrProviderId') : null, providerId: isVenue ? null : v.str('venueOrProviderId')),
    });
  }
  return stableSorted(rows, (a, b) => b.str('at').compareTo(a.str('at')));
}

/// A tiny valid one-page PDF of a receipt (ASCII only; the mock's stand-in for the invoice renderer).
List<int> receiptPdf(Json receipt) {
  final text =
      'Ghazal receipt ${receipt['receiptNo']}  Voucher ${receipt['voucherCode']}  KD ${(filsOf(receipt.obj('amount')) / 1000).toStringAsFixed(3)}  ${receipt['method']}  ${receipt['at']}';
  final stream = 'BT /F1 14 Tf 48 780 Td (${text.replaceAll('(', '[').replaceAll(')', ']')}) Tj ET';
  final objs = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
    '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  final b = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objs.length; i++) {
    offsets.add(b.length);
    b.write('${i + 1} 0 obj\n${objs[i]}\nendobj\n');
  }
  final xref = b.length;
  b.write('xref\n0 ${objs.length + 1}\n0000000000 65535 f \n');
  for (final o in offsets) {
    b.write('${o.toString().padLeft(10, '0')} 00000 n \n');
  }
  b.write('trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n');
  return b.toString().codeUnits;
}
