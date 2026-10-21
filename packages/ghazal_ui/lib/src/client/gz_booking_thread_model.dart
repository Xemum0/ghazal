import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus, ExpiredReason, ThreadKnot, ThreadNodeKind, ThreadNodeState;

import '../brand/gz_thread_knot.dart';
import '../foundation.dart';

/// The five knots of the thread, in order (ADR 0033 D3): Voucher, Request, Approval, Confirmed (24 h), Redeemed at the venue.
enum GzThreadKey { voucher, request, approval, confirmation, redemption }

/// One glyph per knot (ADR 0034): the voucher, the request sent, the venue's answer, your date, the code at the venue.
IconData gzThreadIcon(GzThreadKey key) => switch (key) {
  GzThreadKey.voucher => GzIcons.ticket,
  GzThreadKey.request => GzIcons.send,
  GzThreadKey.approval => GzIcons.verified,
  GzThreadKey.confirmation => GzIcons.calendarCheck,
  GzThreadKey.redemption => GzIcons.qrCode,
};

class GzThreadKnotModel {
  const GzThreadKnotModel({required this.key, required this.state, this.endedIcon, this.endedTone, this.endedStatus, this.at});

  final GzThreadKey key;
  final GzKnotState state;

  /// `ended` knots only: the terminal glyph, tone and the status that ended the thread.
  final IconData? endedIcon;
  final GzKnotEndedTone? endedTone;
  final BookingStatus? endedStatus;

  /// The recorded absolute time of a tied knot, or the deadline of the one in progress.
  final DateTime? at;
}

const Map<BookingStatus, (IconData, GzKnotEndedTone)> _endedIcon = {
  BookingStatus.declined: (GzIcons.close, GzKnotEndedTone.danger),
  BookingStatus.expired: (GzIcons.clockOff, GzKnotEndedTone.neutral),
  BookingStatus.cancelled: (GzIcons.close, GzKnotEndedTone.neutral),
  BookingStatus.completed: (GzIcons.clockOff, GzKnotEndedTone.neutral),
};

ThreadNodeKind? _kindOf(GzThreadKey k) => switch (k) {
  GzThreadKey.voucher => null,
  GzThreadKey.request => ThreadNodeKind.request,
  GzThreadKey.approval => ThreadNodeKind.approval,
  GzThreadKey.confirmation => ThreadNodeKind.confirmation,
  GzThreadKey.redemption => ThreadNodeKind.redemption,
};

/// The knot states of every ADR 0033 status (the web `threadModel`). Pure: the partner app uses the same function.
/// [recorded] is the booking's recorded thread (times); [voucherAt] is when the bound voucher was paid; [reached] is how many knots
/// had tied before a cancel (default: from [recorded], else 3).
List<GzThreadKnotModel> gzThreadModel({
  required BookingStatus status,
  List<ThreadKnot>? recorded,
  DateTime? voucherAt,
  int? reached,
  ExpiredReason? expiredReason,
}) {
  ThreadKnot? node(GzThreadKey key) {
    final kind = _kindOf(key);
    if (kind == null || recorded == null) return null;
    for (final k in recorded) {
      if (k.node == kind) return k;
    }
    return null;
  }

  DateTime? at(GzThreadKey key) => key == GzThreadKey.voucher ? (voucherAt ?? node(GzThreadKey.request)?.at) : node(key)?.at;

  GzThreadKnotModel knot(GzThreadKey key, GzKnotState state, {BookingStatus? ended}) {
    final e = ended == null ? null : _endedIcon[ended];
    return GzThreadKnotModel(key: key, state: state, endedIcon: e?.$1, endedTone: e?.$2, endedStatus: ended, at: at(key));
  }

  // `through` = index of the last tied knot; `now` = the one after it (absent when the request ended).
  List<GzThreadKnotModel> run(int through, {int? nowAt, int? endAt, BookingStatus? endStatus}) => [
    for (var i = 0; i < GzThreadKey.values.length; i++)
      if (endAt == i)
        knot(GzThreadKey.values[i], GzKnotState.ended, ended: endStatus ?? status)
      else if (i <= through)
        knot(GzThreadKey.values[i], GzKnotState.tied)
      else if (nowAt == i)
        knot(GzThreadKey.values[i], GzKnotState.now)
      else
        knot(GzThreadKey.values[i], GzKnotState.open),
  ];

  switch (status) {
    case BookingStatus.pending:
      return run(1, nowAt: 2);
    case BookingStatus.approved:
      return run(2, nowAt: 3);
    case BookingStatus.confirmed:
      return run(3, nowAt: 4);
    case BookingStatus.redeemed:
      return run(4);
    case BookingStatus.completed:
      // Redeemed normally; a request that completed without a redemption ends its last knot quietly.
      final redeemed = node(GzThreadKey.redemption)?.state == ThreadNodeState.done || recorded == null;
      return redeemed ? run(4) : run(3, endAt: 4);
    case BookingStatus.declined:
      return run(1, endAt: 2);
    case BookingStatus.expired:
      // Venue silence ends Approval; a client who did not confirm in 24 h ends Confirmation. Earlier knots stay tied.
      return expiredReason == ExpiredReason.clientNoConfirmation ? run(2, endAt: 3) : run(1, endAt: 2);
    case BookingStatus.cancelled:
      final n = reached ?? (recorded != null ? recorded.where((k) => k.state == ThreadNodeState.done).length : 3);
      // Request is the first recorded knot; the Voucher knot is always tied before it.
      final end = (n + 1).clamp(2, 4);
      return run(end - 1, endAt: end);
    case BookingStatus.unknown:
      return run(0);
  }
}
