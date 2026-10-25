// The header, the Booking Thread and the notices of Booking detail (web `DetailSections.tsx`, ADR 0034): status, voucher chip, the date and the
// one deadline that matters as a glyph and a figure, the thread as five glyph knots, and the few lines that explain why something is off.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/detail_model.dart';
import 'booking_actions.dart';
import 'bk_bits.dart';
import 'detail_parts.dart';

GzStatus pillStatusOf(Booking b) => switch (b.status) {
  BookingStatus.pending => GzStatus.pending,
  BookingStatus.approved => GzStatus.approved,
  BookingStatus.confirmed => GzStatus.confirmed,
  BookingStatus.redeemed => GzStatus.redeemed,
  BookingStatus.completed => GzStatus.completed,
  BookingStatus.declined => GzStatus.declined,
  BookingStatus.cancelled => GzStatus.cancelled,
  _ => b.expiredReason == ExpiredReason.clientNoConfirmation ? GzStatus.lapsed : GzStatus.missed,
};

enum _LeftState { neutral, gold, danger, success }

/// A glyph and a figure: the one fact the header carries (time left, days to go, the day it was redeemed).
class _Left extends StatelessWidget {
  const _Left({required this.icon, required this.label, required this.text, this.state = _LeftState.neutral});

  final IconData icon;
  final String label;
  final String text;
  final _LeftState state;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final color = switch (state) {
      _LeftState.gold => c.textGoldInk,
      _LeftState.danger => c.textDanger,
      _LeftState.success => c.textSuccess,
      _ => c.textSecondary,
    };
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(icon, size: GzIconSize.md, color: color),
            const SizedBox(width: GzSpace.s2),
            GzText(text, role: GzTextRole.figTitle, color: color, figures: true, softWrap: false),
          ],
        ),
      ),
    );
  }
}

/// The 2 dp bar: [share] of it is filled, depleting toward inline-start.
class _SlaBar extends StatelessWidget {
  const _SlaBar({required this.share, required this.color});

  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      height: GzStroke.thread,
      color: context.gz.colors.markTrack,
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: share.clamp(0.0, 1.0),
        heightFactor: 1,
        child: GzDrawOnce(child: ColoredBox(color: color, child: const SizedBox.expand())),
      ),
    ),
  );
}

class DetailHeader extends StatelessWidget {
  const DetailHeader({required this.m, super.key});

  final DetailModel m;

  @override
  Widget build(BuildContext context) {
    final b = m.booking;
    final voucher = m.voucher;
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.l10n;
    final cl = context.gzL10n;
    final now = f.now();
    final urgent = b.status == BookingStatus.pending && f.daysUntil(b.eventDate.toString()) <= 14;

    Widget? fact;
    Widget? bar;
    final proposal = b.proposal;
    if (b.status == BookingStatus.pending && proposal != null) {
      final left = durationOf(context, minutesBetween(now, proposal.expiresAt), lead: true);
      fact = _Left(icon: GzIcons.hourglass, state: _LeftState.gold, label: l.hotelBookingsAwaitingCouple, text: left.visual);
    } else if (b.status == BookingStatus.pending && b.respondBy != null) {
      final sla = m.detail.sla;
      final minutes = sla?.minutesLeft ?? minutesBetween(now, b.respondBy!);
      final left = durationOf(context, minutes);
      final st = sla?.state;
      final tone = switch (st) {
        SlaState.gold => c.statusSlaWarn,
        SlaState.danger => c.statusSlaAlert,
        SlaState.expired => c.borderStrong,
        _ => c.statusSlaOk,
      };
      if (sla != null) bar = _SlaBar(share: gzRemainingShare(sla.elapsed), color: tone);
      fact = _Left(
        icon: GzIcons.timer,
        state: st == SlaState.danger || st == SlaState.expired ? _LeftState.danger : (st == SlaState.gold ? _LeftState.gold : _LeftState.neutral),
        label: l.hotelBookingsReplyLeft(left.spoken),
        text: left.visual,
      );
    } else if (b.status == BookingStatus.approved && b.confirmBy != null) {
      final minutes = minutesBetween(now, b.confirmBy!);
      final left = durationOf(context, minutes);
      bar = _SlaBar(share: minutes / (24 * 60), color: c.statusSlaWarn);
      fact = _Left(icon: GzIcons.hourglass, state: _LeftState.gold, label: l.hotelBookingsConfirmLeft(left.spoken), text: left.visual);
    } else if (b.status == BookingStatus.confirmed) {
      final n = f.daysUntil(b.eventDate.toString());
      fact = n <= 0
          ? _Left(icon: GzIcons.calendarCheck, label: l.hotelBookingsEventToday, text: cl.commonLabelToday)
          : _Left(icon: GzIcons.calendarCheck, label: l.hotelBookingsDaysToGo, text: dayCountText(f, n));
    } else if (b.status == BookingStatus.redeemed && b.redeemedAt != null) {
      fact = _Left(icon: GzIcons.checkCircle, state: _LeftState.success, label: l.hotelBookingsRedeemedPlain, text: dayMonthShort(f, b.redeemedAt!));
    }

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ?bar,
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Wrap(
                    spacing: GzSpace.s2,
                    runSpacing: GzSpace.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GzStatusPill(status: pillStatusOf(b), audience: GzStatusAudience.hotel),
                      if (urgent) const GzStatusPill(status: GzStatus.urgent),
                      if (voucher != null) GzVoucherChip(code: voucher.code, tone: voucher.status == VoucherStatus.bound ? GzVoucherChipTone.bound : GzVoucherChipTone.quiet),
                    ],
                  ),
                ),
                const SizedBox(height: GzSpace.s3),
                GzText(f.date(b.eventDate.toString(), DateStyle.short), role: GzTextRole.uiXl, color: c.textStrong, figures: true, header: true),
                if (fact != null) ...[const SizedBox(height: GzSpace.s3), fact],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _knotLabel(AppL10n l, GzThreadKey k) => switch (k) {
  GzThreadKey.voucher => l.hotelBookingsKnotVoucher,
  GzThreadKey.request => l.hotelBookingsKnotRequest,
  GzThreadKey.approval => l.hotelBookingsKnotApproval,
  GzThreadKey.confirmation => l.hotelBookingsKnotConfirmed,
  GzThreadKey.redemption => l.hotelBookingsKnotRedeemed,
};

/// The five knots of ADR 0033, a glyph each, one word under the active one; the times of the tied knots are in the history.
class DetailThread extends StatelessWidget {
  const DetailThread({required this.b, super.key});

  final Booking b;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final model = gzThreadModel(status: b.status, recorded: b.thread, voucherAt: null, expiredReason: b.expiredReason);
    final steps = [
      for (final k in model)
        GzIconProgressStep(
          id: k.key.name,
          icon: gzThreadIcon(k.key),
          label: _knotLabel(l, k.key),
          state: k.state,
          endedIcon: k.endedIcon,
          endedTone: k.endedTone ?? GzKnotEndedTone.danger,
        ),
    ];
    final at = model.indexWhere((k) => k.state == GzKnotState.now || k.state == GzKnotState.ended);
    final i = at < 0 ? 0 : at;
    return GzIconProgress(
      steps: steps,
      label: l.hotelBookingsProgressLabel,
      describe: '${_knotLabel(l, model[i].key)}, ${l.hotelBookingsStepOf(f.integer(i + 1), f.integer(model.length))}',
    );
  }
}

/// The few lines that explain why something is off: offline, an issue reported, a held date, a competing request, a role that may only look.
Widget? detailNotices(BuildContext context, DetailModel m, BookingActions act) {
    final b = m.booking;
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final nav = context.gzNav;
    final notes = <Widget>[];
    if (b.overlays.issueReported == true) {
      notes.add(
        BkNote(
          icon: GzIcons.flag,
          tone: GzIconTone.danger,
          action: GzButton(label: l.hotelBookingsIssueLink, variant: GzButtonVariant.tertiary, onPressed: () => act.support()),
          child: GzText(l.hotelBookingsIssueReported, role: GzTextRole.bodyS, color: c.textPrimary),
        ),
      );
    }
    final barSaysWhy = (b.status == BookingStatus.pending && b.proposal == null && canDecide(m.role));
    if (b.status == BookingStatus.pending && b.proposal == null) {
      if (m.held && !barSaysWhy) {
        notes.add(BkNote(icon: GzIcons.lock, tone: GzIconTone.accent, child: GzText(l.hotelBookingsHeldLine, role: GzTextRole.bodyS, color: c.textPrimary)));
      } else if (m.others > 0) {
        notes.add(
          BkNote(
            icon: GzIcons.compare,
            tone: GzIconTone.accent,
            child: Semantics(
              label: l.hotelBookingsOthersSameDate(m.others),
              excludeSemantics: true,
              child: Align(alignment: AlignmentDirectional.centerStart, child: GzText('+${f.integer(m.others)}', role: GzTextRole.figBodyS, color: c.textPrimary, figures: true)),
            ),
          ),
        );
      }
    }
    if (m.params['offerPrompt'] == true && (b.status == BookingStatus.cancelled || b.status == BookingStatus.declined || b.status == BookingStatus.expired)) {
      notes.add(
        BkNote(
          icon: GzIcons.offer,
          tone: GzIconTone.accent,
          action: GzButton(label: l.hotelBookingsCreateWindow, variant: GzButtonVariant.tertiary, onPressed: () => nav.push('HL-GROW-02')),
          child: GzText(l.hotelBookingsDateFreeAgain, role: GzTextRole.bodyS, color: c.textPrimary),
        ),
      );
    }
    if (m.roleLimited) {
      notes.add(BkNote(icon: GzIcons.lock, child: GzText(l.hotelBookingsViewOnly, role: GzTextRole.bodyS, color: c.textPrimary)));
    }
    if (notes.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < notes.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s3), notes[i]]],
    );
}
