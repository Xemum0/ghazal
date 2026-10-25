/// support: the support conversation, refund (credit voucher) requests, FAQ and legal documents. A refund request is decided by the control
/// surface (grant creates the credit voucher, decline carries a reason); the real service is the call centre.
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/chat.dart';
import '../domain/notify.dart';
import '../domain/vouchers.dart';
import '../domain/views.dart';
import '../engine/engine.dart';

/// Creates the refund request of a voucher the client may ask a credit for (never money: ADR 0035).
Json createRefundFor(MockApp app, String clientId, String voucherId, String? note) {
  final v = app.db.get('Voucher', voucherId);
  if (v == null || v['clientId'] != clientId) throw ApiError('VOUCHER_NOT_USABLE', detail: 'unknown voucher');
  if (v['refundRequestId'] != null) throw ApiError('REFUND_REQUEST_EXISTS');
  if (v['status'] != 'active' || v['kind'] != 'bound' || v['creditEligible'] != true) throw ApiError('CREDIT_NOT_ELIGIBLE');
  final support = ensureSupportConversation(app, clientId: clientId);
  final id = 'refund-m${app.db.next('refund').toString().padLeft(3, '0')}';
  final doc = <String, dynamic>{
    'id': id,
    'voucherId': voucherId,
    'clientId': clientId,
    'status': 'requested',
    'requestedAt': app.now,
    'note': note == null || note.isEmpty ? null : {'en': note, 'ar': note},
    'conversationId': support['id'],
    'decidedAt': null,
    'decidedBy': null,
    'creditVoucherId': null,
    'declineReason': null,
  };
  app.db.put('RefundRequest', doc);
  v['refundRequestId'] = id;
  app.db.put('Voucher', v);
  appendMessage(
    app,
    support.str('id'),
    from: 'client',
    senderName: app.userName(clientId),
    text: {'en': null, 'ar': note ?? 'أرغب بطلب كوبون رصيد بدل الكوبون ${v['code']}.'},
    origin: 'ar',
  );
  appendMessage(
    app,
    support.str('id'),
    from: 'system',
    kind: 'system',
    text: {
      'en': 'Your credit voucher request for ${v['code']} was sent to Ghazal support.',
      'ar': 'تم إرسال طلب كوبون الرصيد للكوبون ${v['code']} إلى دعم غزل.',
    },
  );
  return doc;
}

Map<String, Handler> supportHandlers(MockApp app) => {
  'getSupportConversation': (r) {
    final c = r.partner != null
        ? ensureSupportConversation(app, venueId: r.partner!.venueId ?? r.partner!.providerId)
        : ensureSupportConversation(app, clientId: r.userId);
    return wire(c);
  },
  'createRefundRequest': (r) => wire(createRefundFor(app, r.userId, r.b.str('voucherId'), r.b.strOrNull('note'))),
  'listRefundRequests': (r) {
    final rows = app.db.raw('RefundRequest').where((x) => x['clientId'] == r.userId).toList();
    return pageMap(r, stableSorted(rows, (a, b) => b.str('requestedAt').compareTo(a.str('requestedAt'))), wire);
  },
  'getRefundRequest': (r) {
    final x = app.db.get('RefundRequest', r.p('requestId'));
    if (x == null || x['clientId'] != r.userId) throw ApiError.notFound('refund request');
    return wire(x);
  },
  'listFaq': (r) => app.seed.rows('FaqItem'),
  'getLegalDocument': (r) => app.seed.extra.obj('legal').obj(r.p('kind')),
};

/// Grants or declines a refund request (the control endpoint calls this). Returns the updated request.
Json decideRefundRequest(MockApp app, String requestId, {required bool grant, String? reason}) {
  final x = app.db.get('RefundRequest', requestId) ?? (throw ApiError.notFound('refund request'));
  if (x['status'] != 'requested') throw ApiError('REFUND_REQUEST_EXISTS', detail: 'already decided');
  x['decidedAt'] = app.now;
  x['decidedBy'] = 'Ghazal Support';
  if (grant) {
    final credit = grantCreditVoucher(app, x);
    x['status'] = 'granted';
    x['creditVoucherId'] = credit['id'];
    appendMessage(
      app,
      x.str('conversationId'),
      from: 'support',
      senderName: 'Lama Al-Khalidi',
      kind: 'credit_card',
      text: {'en': 'Credit voucher issued', 'ar': 'تم إصدار كوبون رصيد'},
      card: {
        'kind': 'credit_voucher',
        'title': {'en': 'Credit voucher issued', 'ar': 'تم إصدار كوبون رصيد'},
        'lines': [
          {'en': credit['code'], 'ar': credit['code']},
        ],
        'refId': credit['id'],
      },
    );
    notify(
      app,
      userId: x.str('clientId'),
      kind: 'credit_voucher_issued',
      audience: 'client',
      params: {'code': credit['code'], 'from': app.db.peek('Voucher', x.str('voucherId'))?['code']},
      voucherId: credit.str('id'),
    );
  } else {
    x['status'] = 'declined';
    x['declineReason'] = {'en': reason ?? 'The request does not meet the credit conditions.', 'ar': reason ?? 'الطلب لا يستوفي شروط كوبون الرصيد.'};
    appendMessage(app, x.str('conversationId'), from: 'support', senderName: 'Lama Al-Khalidi', text: x['declineReason'] as Json);
  }
  app.db.put('RefundRequest', x);
  app.logEvent('refund_${grant ? 'granted' : 'declined'}', {'requestId': requestId});
  return x;
}
