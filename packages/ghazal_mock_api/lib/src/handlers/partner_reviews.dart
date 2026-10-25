/// partner-reviews: the review inbox of a venue, a single reply, drafts, reports and removal requests (hide or delete only through support).
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../engine/engine.dart';
import 'common.dart';

Json _own(MockApp app, Req r) {
  final id = r.ctx.venueId ?? (throw ApiError.forbidden('reviews belong to venues'));
  final v = app.db.get('Review', r.p('reviewId'));
  if (v == null || v['venueId'] != id) throw ApiError.notFound('review');
  return v;
}

Json _text(String text, String origin) => origin == 'ar' ? {'en': null, 'ar': text} : {'en': text, 'ar': null};

Map<String, Handler> partnerReviewsHandlers(MockApp app) => {
  'listPartnerReviews': (r) {
    final venueId = r.ctx.venueId;
    if (venueId == null) return {'items': <Json>[], 'nextCursor': null};
    var rows = app.db.raw('Review').where((x) => x['venueId'] == venueId).toList();
    if (r.q('filter') == 'awaiting_reply') rows = rows.where((x) => x['ownerReply'] == null).toList();
    return pageMap(r, stableSorted(rows, (a, b) => b.str('postedAt').compareTo(a.str('postedAt'))), wire);
  },
  'getPartnerReview': (r) => wire(_own(app, r)),
  'saveReviewReplyDraft': (r) {
    app.requirePermission(r, 'reviews:reply');
    final v = _own(app, r);
    v['replyDraft'] = _text(r.b.str('text'), r.lang);
    app.db.put('Review', v);
    return wire(v);
  },
  'replyToReview': (r) {
    app.requirePermission(r, 'reviews:reply');
    final v = _own(app, r);
    if (v['ownerReply'] != null) throw ApiError('REVIEW_ALREADY_REPLIED');
    v['ownerReply'] = {'text': _text(r.b.str('text'), r.b.strOrNull('origin') ?? r.lang), 'repliedAt': app.now, 'by': actorName(r)};
    v['replyDraft'] = null;
    app.db.put('Review', v);
    return wire(v);
  },
  'reportReview': (r) {
    _own(app, r);
    app.db.put('ReviewReport', {
      'id': 'rpt-${app.db.next('report')}',
      'reviewId': r.p('reviewId'),
      'reason': r.b['reason'],
      'note': r.b['note'],
      'at': app.now,
      'venueId': r.ctx.venueId,
    });
    app.logEvent('review_reported', {'reviewId': r.p('reviewId')});
    return null;
  },
  'requestReviewRemoval': (r) {
    app.requirePermission(r, 'reviews:reply');
    final v = _own(app, r);
    v['supportRequest'] = {'action': r.b['action'], 'requestedAt': app.now, 'status': 'requested'};
    app.db.put('Review', v);
    return wire(v);
  },
};
