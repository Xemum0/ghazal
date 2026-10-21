import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart' show Booking, BookingStatus;

import '../brand/gz_thread_knot.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'gz_booking_thread_full.dart';
import 'gz_booking_thread_model.dart';
import 'gz_booking_thread_parts.dart';

export 'gz_booking_thread_model.dart';

enum GzBookingThreadVariant { full, compact, vertical }

/// `active` (default): one word under the active knot. `all`: every knot is labelled. `none`: glyphs only (full variant only).
enum GzThreadLabels { active, all, none }

/// BookingThread (direction section 4, ADR 0033 D3, ADR 0034): five knots on one gold thread, Voucher, Request, Approval,
/// Confirmed (24 h), Redeemed at the venue. A knot ties only when its event is recorded; times are absolute; the thread is never
/// the only signal (a glyph always sits beside it); it draws on once from inline-start over 480 ms and a knot pops once on a live
/// change. Reduced motion shows the finished thread.
///
/// - `full`: a glyph over each 20 dp knot, one word under the active knot, the deadline under the thread.
/// - `compact`: 12 dp knots, then ONE line (current glyph, word, time): list rows, the partner request card.
/// - `vertical`: rail and content (booking detail): glyph and two-word label per knot, at most two faint future knots.
/// - [onDark]: for an ink panel (confirmation hero, countdown).
///
/// Input is a [booking] (its recorded thread supplies the times; [voucherAt] is when its bound voucher was paid) or just a [status].
class GzBookingThread extends StatelessWidget {
  const GzBookingThread({
    this.booking,
    this.status,
    this.voucherAt,
    this.variant = GzBookingThreadVariant.full,
    this.labels = GzThreadLabels.active,
    this.onDark = false,
    this.draw = GzDraw.inview,
    this.pop,
    super.key,
  });

  final Booking? booking;

  /// Without a booking: just the status (a spec cell, a status filter preview). Default pending.
  final BookingStatus? status;

  /// When the bound voucher was purchased (the Voucher knot's time). The widget never fetches it.
  final DateTime? voucherAt;
  final GzBookingThreadVariant variant;
  final GzThreadLabels labels;
  final bool onDark;
  final GzDraw draw;

  /// The knot that just changed in view: it pops once.
  final GzThreadKey? pop;

  /// A tied or ended knot is named by its result; a knot still ahead by its step, so the thread never contradicts the status.
  String _label(GzL10n l, GzThreadKnotModel k) {
    final ahead = k.state == GzKnotState.now || k.state == GzKnotState.open;
    final long = variant == GzBookingThreadVariant.vertical;
    final step = ahead && (k.key == GzThreadKey.confirmation || k.key == GzThreadKey.redemption);
    return switch (k.key) {
      GzThreadKey.voucher => long ? l.uiClientThreadVoucherLong : l.uiClientThreadVoucher,
      GzThreadKey.request => long ? l.uiClientThreadRequestLong : l.uiClientThreadRequest,
      GzThreadKey.approval => long ? l.uiClientThreadApprovalLong : l.uiClientThreadApproval,
      GzThreadKey.confirmation =>
        step ? (long ? l.uiClientThreadConfirmationStepLong : l.uiClientThreadConfirmationStep) : (long ? l.uiClientThreadConfirmationLong : l.uiClientThreadConfirmation),
      GzThreadKey.redemption =>
        step ? (long ? l.uiClientThreadRedemptionStepLong : l.uiClientThreadRedemptionStep) : (long ? l.uiClientThreadRedemptionLong : l.uiClientThreadRedemption),
    };
  }

  /// `12 Nov 4:00 PM`: day, short month and time, no weekday and no comma (a figure, not a sentence).
  static String _stamp(GzFormat f, DateTime at) {
    final c = f.civil(at);
    final time = f.time(at).replaceAll(RegExp(r'\s'), ' ');
    return '${f.integer(c.day)} ${f.monthName(c.month, short: true)} $time';
  }

  /// The line under a knot's label: a recorded time, a deadline (timer glyph and time), or the reason a knot ended.
  GzThreadSub? _sub(GzFormat f, GzL10n l, GzThreadKnotModel k) {
    if (k.state == GzKnotState.ended && k.endedStatus != null) {
      if (k.endedStatus == BookingStatus.completed) return GzThreadSub(l.uiClientThreadNotRedeemed, GzThreadTone.muted);
      final danger = k.endedTone == GzKnotEndedTone.danger || k.endedTone == GzKnotEndedTone.dangerOutline;
      final text = switch (k.endedStatus!) {
        BookingStatus.declined => l.commonStatusDeclined,
        BookingStatus.expired => l.commonStatusExpired,
        _ => l.commonStatusCancelled,
      };
      return GzThreadSub(text, danger ? GzThreadTone.danger : GzThreadTone.muted);
    }
    if (k.state == GzKnotState.tied) return k.at == null ? null : GzThreadSub(_stamp(f, k.at!), GzThreadTone.muted);
    if (k.state == GzKnotState.now) {
      // Redemption in progress = the booking is Confirmed: the code is on the voucher below, so the thread names the step only.
      final by = switch (k.key) {
        GzThreadKey.approval => booking?.respondBy ?? k.at,
        GzThreadKey.confirmation => booking?.confirmBy ?? k.at,
        _ => null,
      };
      if (by != null) return GzThreadSub(_stamp(f, by), GzThreadTone.now, icon: GzIcons.timer);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final st = booking?.status ?? status ?? BookingStatus.pending;
    final model = gzThreadModel(
      status: st,
      recorded: booking?.thread,
      voucherAt: voucherAt,
      expiredReason: booking?.expiredReason,
    );
    final stepNow = model.indexWhere((k) => k.state == GzKnotState.now || k.state == GzKnotState.ended).clamp(0, model.length - 1);
    final hasCurrent = model.any((k) => k.state == GzKnotState.now || k.state == GzKnotState.ended);
    final current = hasCurrent ? model[stepNow] : model.last;
    final describe = '${_label(l, current)}, ${l.uiClientThreadStepOf(f.integer(stepNow + 1), f.integer(model.length))}';
    final currentSub = _sub(f, l, current);

    switch (variant) {
      case GzBookingThreadVariant.full:
        final showNote = currentSub != null && (current.state == GzKnotState.now || current.state == GzKnotState.ended);
        return GzThreadFull(
          model: model,
          labelOf: (k) => _label(l, k),
          semantics: '${l.uiClientThreadLabel}: $describe',
          labels: switch (labels) {
            GzThreadLabels.active => GzProgressLabels.active,
            GzThreadLabels.all => GzProgressLabels.all,
            GzThreadLabels.none => GzProgressLabels.none,
          },
          note: showNote ? currentSub : null,
          noteTone: currentSub?.tone ?? GzThreadTone.muted,
          onDark: onDark,
          draw: draw,
          pop: pop,
        );
      case GzBookingThreadVariant.vertical:
        return GzThreadVertical(
          model: model,
          labelOf: (k) => _label(l, k),
          subOf: (k) => _sub(f, l, k),
          semantics: '${l.uiClientThreadLabel}: $describe',
          onDark: onDark,
          draw: draw,
          pop: pop,
        );
      case GzBookingThreadVariant.compact:
        return GzThreadCompact(
          model: model,
          current: current,
          currentLabel: _label(l, current),
          currentSub: currentSub,
          semantics: '${l.uiClientThreadLabel}: $describe',
          onDark: onDark,
          draw: draw,
          pop: pop,
        );
    }
  }
}
