/// vouchers: the wallet, checkout, the mock payment gateway, rebinding a released voucher, receipts. The KD 2 voucher is the only thing a client
/// pays in the app (ADR 0033); everything else happens between the client and the venue, off-app.
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/requests.dart';
import '../domain/vouchers.dart';
import '../domain/views.dart';
import '../engine/engine.dart';

Json ownVoucher(MockApp app, Req r, String idOrCode) {
  final v = app.db.get('Voucher', idOrCode) ?? app.db.firstWhere('Voucher', (d) => d['code'] == idOrCode);
  if (v == null || v['clientId'] != r.userId) throw ApiError.notFound('voucher');
  return v;
}

/// The engine quote of one checkout or rebind (venue package with its hall, or a provider package).
({Json quote, String? hallId, int? guests}) quoteForVoucher(
  MockApp app, {
  required String targetType,
  required String targetId,
  String? hallId,
  required String packageId,
  required String eventDate,
  int? guests,
}) {
  final engine = app.engine();
  if (targetType == 'provider') {
    final provider = app.db.peek('ServiceProvider', targetId) ?? (throw ApiError.notFound('provider'));
    final pkg =
        provider.list('packages').cast<Json?>().firstWhere((p) => p!['id'] == packageId, orElse: () => null) ??
        (throw ApiError.validation('/packageId', 'unknown_package'));
    final qty = guests ?? pkg.intOrNull('minQuantity') ?? 1;
    return (quote: engine.quoteForProvider(providerId: targetId, packageId: packageId, qty: qty), hallId: null, guests: qty);
  }
  final venue = app.db.peek('Venue', targetId) ?? (throw ApiError.notFound('venue'));
  final pkg = app.db.peek('Package', packageId);
  if (pkg == null || pkg['venueId'] != targetId) throw ApiError.validation('/packageId', 'unknown_package');
  final hid = hallId ?? (pkg.strings('hallIds').isEmpty ? null : pkg.strings('hallIds').first) ?? venue.list('halls').first.str('id');
  final hall =
      venue.list('halls').cast<Json?>().firstWhere((h) => h!['id'] == hid, orElse: () => null) ?? (throw ApiError.validation('/hallId', 'unknown_hall'));
  final audience = pkg
      .strings('audiences')
      .firstWhere((a) => hall.list('sections').any((s) => s['audience'] == a), orElse: () => pkg.strings('audiences').first);
  final sec = hall.list('sections').cast<Json?>().firstWhere((s) => s!['audience'] == audience, orElse: () => null);
  final g = guests ?? effectiveMinGuests(pkg, sec?.integer('minGuests') ?? 0);
  final built = buildSections(app, targetId, eventDate, [
    {'hallId': hid, 'audience': audience, 'guests': g, 'packageId': packageId},
  ], sessionRequired: false);
  return (quote: engine.quoteFor(venueId: targetId, eventDate: eventDate, sections: built.quoteSections), hallId: hid, guests: g);
}

Map<String, Handler> vouchersHandlers(MockApp app) => {
  'listVouchers': (r) {
    final status = r.qList('status');
    final rows = walletOf(app, r.userId).where((v) => status.isEmpty || status.contains(v['status'])).toList();
    return pageMap(r, rows, (v) => walletItem(app, v));
  },
  'getVoucher': (r) {
    final raw = ownVoucher(app, r, r.p('voucherId'));
    final v = asSeen(app, raw);
    final bookingId = raw.strOrNull('bookingId');
    Json? booking;
    if (bookingId != null) {
      final b = app.db.get('Booking', bookingId);
      if (b != null) booking = viewBooking(b);
    }
    Json? refund;
    final rid = raw.strOrNull('refundRequestId');
    if (rid != null) refund = app.db.get('RefundRequest', rid);
    final item = walletItem(app, v);
    return {
      'voucher': v,
      'hallName': item['hallName'],
      'packageName': item['packageName'],
      'options': voucherOptions(v),
      'booking': booking,
      'refundRequest': refund,
      'target': item['target'],
    };
  },
  'startVoucherCheckout': (r) {
    final who = r.identity!.user;
    if (app.db.peek('User', who.str('id'))?['_phoneVerified'] == false) throw ApiError('PHONE_VERIFICATION_REQUIRED');
    final b = r.b;
    final targetType = b.str('targetType');
    final targetId = b.str('targetId');
    final q = quoteForVoucher(
      app,
      targetType: targetType,
      targetId: targetId,
      hallId: b.strOrNull('hallId'),
      packageId: b.str('packageId'),
      eventDate: b.str('eventDate'),
      guests: b.intOrNull('guests'),
    );
    final totals = q.quote.obj('totals');
    if (q.quote['voucherEligible'] != true) {
      throw ApiError('VOUCHER_NOT_OFFERED', params: {'savingsFils': filsOf(totals.obj('savings')), 'feeFils': app.voucherFeeFils});
    }
    final qid = b.strOrNull('quoteId');
    if (qid != null) {
      final snap = app.db.peek('Quote', qid);
      if (snap == null || instantMs(app.now) > instantMs(snap.str('expiresAt'))) throw ApiError('QUOTE_EXPIRED');
      if (snap['voucherTotal'] != filsOf(totals.obj('voucherTotal')) || snap['standardTotal'] != filsOf(totals.obj('standardTotal'))) {
        throw ApiError('QUOTE_CHANGED');
      }
    }
    final voucher = newUnpaidVoucher(
      app,
      clientId: who.str('id'),
      targetType: targetType,
      targetId: targetId,
      hallId: q.hallId,
      packageId: b.str('packageId'),
      eventDate: b.str('eventDate'),
      guests: q.guests,
      quote: q.quote,
    );
    final platform = (r.headers['x-platform'] ?? '').toLowerCase();
    final methods = platform == 'ios' ? ['apple_pay', 'knet', 'card'] : (platform == 'android' ? ['google_pay', 'knet', 'card'] : ['knet', 'card']);
    return {
      'voucher': wire(voucher),
      'amount': fils(app.voucherFeeFils),
      'expiresAt': voucher['_checkoutExpiresAt'],
      'methods': methods,
      'quote': wireQuote(
        q.quote,
        targetType: targetType,
        targetId: targetId,
        quoteId: null,
        expiresAt: voucher.str('_checkoutExpiresAt'),
        eventDate: b.strOrNull('eventDate') ?? app.today(),
      ),
    };
  },
  'createPaymentSession': (r) {
    final id = r.p('voucherId');
    if (!app.db.has('Voucher', id) && app.db.has('LapsedCheckout', id)) throw ApiError('VOUCHER_CHECKOUT_EXPIRED');
    final v = ownVoucher(app, r, id);
    if (v['status'] != 'unpaid') throw ApiError('VOUCHER_NOT_USABLE', params: {'status': v['status']});
    if (instantMs(app.now) > instantMs(v.str('_checkoutExpiresAt'))) throw ApiError('VOUCHER_CHECKOUT_EXPIRED');
    if (app.flags['gatewayDown'] == true) throw ApiError('PAYMENT_GATEWAY_ERROR', retryAfterSeconds: 30);
    return wire(newPaymentSession(app, voucher: v, method: r.b.str('method'), returnUrl: r.b.strOrNull('returnUrl')));
  },
  'getPaymentState': (r) {
    final p = app.db.get('Payment', r.p('paymentId')) ?? (throw ApiError.notFound('payment'));
    final v = p['_kind'] == 'listing' ? null : app.db.get('Voucher', p.str('voucherId'));
    if (p['_kind'] == 'listing' && !app.membershipsOf(r.userId).any((m) => m.accountId == app.db.get('Listing', p.str('_listingId'))?['partnerAccountId'])) {
      throw ApiError.notFound('payment');
    }
    if (v != null && v['clientId'] != r.userId) throw ApiError.notFound('payment');
    return {'id': p['id'], 'status': p['status'], 'voucher': p['status'] == 'succeeded' && v != null ? asSeen(app, v) : null, 'failureCode': p['failureCode']};
  },
  'rebindVoucher': (r) {
    final raw = ownVoucher(app, r, r.p('voucherId'));
    final v = asSeen(app, raw);
    if (v['status'] != 'active' || v['kind'] != 'bound') throw ApiError('VOUCHER_NOT_USABLE', params: {'status': v['status']});
    final b = r.b;
    // The voucher stays tied to its venue or provider: only the date, the package, the hall and the guests may move. What the body leaves out
    // keeps its value (the hall when the new package sells in it, the guest count always), as the web's `rebindVoucherDate` does.
    final pkg = v.str('targetType') == 'venue' ? app.db.peek('Package', b.str('packageId')) : null;
    final keepHall = v.strOrNull('hallId');
    final hall = b.strOrNull('hallId') ?? (keepHall != null && (pkg == null || pkg.strings('hallIds').contains(keepHall)) ? keepHall : null);
    final q = quoteForVoucher(
      app,
      targetType: v.str('targetType'),
      targetId: v.str('venueOrProviderId'),
      hallId: hall,
      packageId: b.str('packageId'),
      eventDate: b.str('eventDate'),
      guests: b.intOrNull('guests') ?? v.intOrNull('guests'),
    );
    if (q.quote['voucherEligible'] != true) throw ApiError('VOUCHER_NOT_OFFERED');
    final t = q.quote.obj('totals');
    raw
      ..['packageId'] = b['packageId']
      ..['eventDate'] = b['eventDate']
      ..['hallId'] = q.hallId
      ..['guests'] = q.guests
      ..['quoteFils'] = {'standard': filsOf(t.obj('standardTotal')), 'voucher': filsOf(t.obj('voucherTotal'))};
    app.db.put('Voucher', raw);
    return wire(raw);
  },
  'listReceipts': (r) => pageMap(r, receiptsOf(app, r.userId), (x) => x),
  'getReceiptPdf': (r) {
    final no = r.p('receiptNo');
    final rec = receiptsOf(app, r.userId).cast<Json?>().firstWhere((x) => x!['receiptNo'] == no, orElse: () => null) ?? (throw ApiError.notFound('receipt'));
    return RawBody(receiptPdf(rec), 'application/pdf');
  },
};
