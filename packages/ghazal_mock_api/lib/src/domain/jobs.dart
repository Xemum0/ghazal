/// System jobs of docs/architecture/backend-handoff.md section 7, run lazily at the start of every request and after every clock move:
/// expire pending (R06), expire approval (R09), complete (R12), counter-offer expiry, voucher validity, checkout lapse, undo window, visit
/// chat read-only. No timers: the story clock decides, so advancing it by a day is the whole "wait" of a demo.
library;

import '../core/app.dart';
import '../engine/engine.dart';
import 'requests.dart';
import 'vouchers.dart';
import 'visits.dart';

void sweep(MockApp app) {
  final now = app.now;
  final nowMs = instantMs(now);
  var guard = 0;
  // requests: copy the ids first, transitions edit the collection
  for (final b in app.db.raw('Booking').toList()) {
    if (guard++ > 5000) break;
    final id = b.str('id');
    switch (b['status']) {
      case 'pending':
        final respondBy = b.strOrNull('respondBy');
        if (respondBy != null && nowMs >= instantMs(respondBy)) {
          expirePending(app, id);
        } else {
          final prop = b.objOrNull('proposal');
          if (prop != null && prop['status'] == 'proposed' && nowMs >= instantMs(prop.str('expiresAt'))) expireProposal(app, id);
        }
      case 'approved':
        final confirmBy = b.strOrNull('confirmBy');
        if (confirmBy != null && nowMs >= instantMs(confirmBy)) {
          expireApproval(app, id);
        } else {
          closeUndoWindowIfDue(app, id);
        }
      case 'confirmed':
      case 'redeemed':
        if (nowMs >= instantMs(eventEndOf(app, b))) completeRequest(app, id);
    }
  }
  expireVouchers(app);
  lapseCheckouts(app);
  progressVisits(app);
}
