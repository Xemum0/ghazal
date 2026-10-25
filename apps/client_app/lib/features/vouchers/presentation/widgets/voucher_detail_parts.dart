import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../voucher_fmt.dart';

final RegExp _unit = RegExp('[^\\d\\s\\u00a0\\u2066-\\u2069\\u0660-\\u0669]+');

String _unitOf(GzFormat f, int ms) => _unit.firstMatch(f.duration(ms))?.group(0) ?? '';

/// The 24 hour window to confirm an approved request, as one figure and one line (web `ConfirmLeft`): hours and minutes in the figures
/// voice (never seconds), the bar shows how much of the window has passed and never turns red; the sentence is behind the info glyph.
class ConfirmLeftPanel extends StatelessWidget {
  const ConfirmLeftPanel({required this.deadline, super.key});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final l = context.l10n;
    final left = gzConfirmLeft(f, context.gzL10n, deadline: deadline, now: f.now());
    if (left.ended) return const SizedBox.shrink();
    final hours = left.leftMin ~/ 60;
    final minutes = left.leftMin % 60;
    const nb = ' ';
    final value = hours > 0
        ? '${f.integer(hours)}$nb${_unitOf(f, 3600000)}${minutes > 0 ? ' ${f.integer(minutes)}$nb${_unitOf(f, 60000)}' : ''}'
        : '${f.integer(minutes)}$nb${_unitOf(f, 60000)}';
    final share = (left.passed * 1000).round();
    return Container(
      key: const ValueKey<String>('voucher.confirmLeft'),
      padding: const EdgeInsetsDirectional.fromSTEB(GzSpace.panelPad, GzSpace.panelPad, GzSpace.panelPad, GzSpace.s5),
      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: GzSize.touchMin,
                height: GzSize.touchMin,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surfaceRaised, shape: BoxShape.circle),
                child: ExcludeSemantics(child: GzIcon(left.lastHour ? GzIcons.timer : GzIcons.hourglass, size: GzIconSize.md, color: c.iconAccent)),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Semantics(
                  label: '${l.clientVouchersWindowLeft} $value',
                  excludeSemantics: true,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GzText(value, role: GzTextRole.kpi, color: c.textStrong, figures: true, softWrap: false),
                  ),
                ),
              ),
              GzInfoButton(title: l.clientVouchersInfoWindow, paragraphs: [l.clientVouchersWindowBody], bleed: true),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          Semantics(
            label: l.clientVouchersInfoWindow,
            value: value,
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: GzRadius.pillAll,
                child: SizedBox(
                  height: GzStroke.threadMax,
                  child: Row(
                    children: [
                      if (share > 0) Expanded(flex: share, child: ColoredBox(color: c.markKhayt)),
                      if (share < 1000) Expanded(flex: 1000 - share, child: ColoredBox(color: c.markTrack)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Event {
  const _Event({required this.key, required this.icon, required this.word, required this.at, this.ended = false, this.receipt = false});

  final String key;
  final IconData icon;
  final String word;
  final DateTime at;
  final bool ended;
  final bool receipt;
}

List<_Event> _eventsOf(BuildContext context, Voucher v, VoucherDetail d) {
  final l = context.l10n;
  final cl = context.gzL10n;
  final booking = d.booking;
  final rr = d.refundRequest;
  final paidAt = v.payment?.at ?? v.purchasedAt;
  final events = <_Event>[
    if (paidAt != null) _Event(key: 'paid', icon: GzIcons.receipt, word: l.clientVouchersHistPaid, at: paidAt, receipt: v.payment != null),
    if (booking != null) _Event(key: 'attached', icon: GzIcons.send, word: l.clientVouchersHistRequested, at: booking.createdAt),
    if (v.releasedAt != null) _Event(key: 'released', icon: GzIcons.undo, word: l.clientVouchersHistReturned, at: v.releasedAt!),
    if (v.usedAt != null)
      _Event(
        key: 'used',
        icon: GzIcons.checkDouble,
        word: v.usedReason == VoucherUsedReason.cancelledAfterConfirm ? l.clientVouchersPhaseUsedUp : cl.commonVoucherStatusUsed,
        at: v.usedAt!,
      ),
    if (rr != null) _Event(key: 'refund', icon: GzIcons.chat, word: cl.commonAskSupport, at: rr.requestedAt),
    if (rr != null && rr.decidedAt != null && rr.status == RefundRequestStatus.granted) _Event(key: 'refund-done', icon: GzIcons.gift, word: cl.commonVoucherStatusCreditIssued, at: rr.decidedAt!),
    if (v.status == VoucherStatus.forfeited && v.forfeitedAt != null) _Event(key: 'forfeited', icon: GzIcons.xCircle, word: cl.commonVoucherStatusForfeited, at: v.forfeitedAt!, ended: true),
    if (v.status == VoucherStatus.expired && v.validUntil != null) _Event(key: 'expired', icon: GzIcons.clockOff, word: cl.commonVoucherStatusExpired, at: v.validUntil!, ended: true),
  ];
  events.sort((a, b) => a.at.compareTo(b.at));
  return events;
}

/// What happened to a voucher, oldest first, each as a glyph, one word and a date (web `History`). A recorded event is a tied knot on one
/// thin rail; the end of a voucher is a quiet ended knot. The paid event IS the receipt: its row opens the receipt viewer (CA-VCH-14).
class VoucherHistory extends StatelessWidget {
  const VoucherHistory({required this.detail, this.onReceipt, super.key});

  final VoucherDetail detail;
  final VoidCallback? onReceipt;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final v = detail.voucher as Voucher;
    final events = _eventsOf(context, v, detail);
    return Semantics(
      container: true,
      label: context.l10n.clientVouchersHistoryLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < events.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: GzSpace.s6,
                    child: Column(
                      children: [
                        const SizedBox(height: GzSpace.s3),
                        ExcludeSemantics(
                          child: GzThreadKnot(
                            state: events[i].ended ? GzKnotState.ended : GzKnotState.tied,
                            size: GzKnotSize.compact,
                            endedIcon: GzIcons.clockOff,
                            endedTone: GzKnotEndedTone.neutral,
                          ),
                        ),
                        if (i < events.length - 1) Expanded(child: Container(width: GzStroke.hair, constraints: const BoxConstraints(minHeight: GzSpace.s3), color: c.borderStrong)),
                      ],
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(child: _row(context, events[i], f)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, _Event e, GzFormat f) {
    final c = context.gz.colors;
    final tappable = e.receipt && onReceipt != null;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      child: Row(
        children: [
          GzIcon(e.icon, size: GzIconSize.sm, color: c.iconSecondary),
          const SizedBox(width: GzSpace.s3),
          Expanded(child: GzText(e.word, role: GzTextRole.bodyS, color: c.textStrong)),
          const SizedBox(width: GzSpace.s3),
          GzText(f.dayMon(e.at), role: GzTextRole.caption, color: c.textSecondary, figures: true, softWrap: false),
          if (tappable) ...[const SizedBox(width: GzSpace.s3), GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary)],
        ],
      ),
    );
    if (!tappable) return row;
    return GzPressable(onPressed: onReceipt, semanticLabel: context.l10n.clientVouchersViewReceipt, borderRadius: GzRadius.smAll, expand: true, child: row);
  }
}

/// The full-screen voucher for the venue's scanner, opened as a sheet (web `QrFull`): the venue's name is the title, the QR sits on the
/// plain canvas at the largest size that fits, the code under it. The payload is never printed, only the code.
class QrFullBody extends StatelessWidget {
  const QrFullBody({required this.voucher, required this.name, super.key});

  final WalletVoucher voucher;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    return Column(
      key: const ValueKey<String>('voucher.qrFull'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SheetTitle(name: name),
        const SizedBox(height: GzSpace.s6),
        Container(
          padding: const EdgeInsets.all(GzSpace.s4),
          decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
          child: GzQrCode(payload: voucher.qr.payload, label: l.clientVouchersQrLabel(voucher.code), size: 248),
        ),
        const SizedBox(height: GzSpace.s6),
        Semantics(
          label: context.gzL10n.commonVoucherCode,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GzText(voucher.code, role: GzTextRole.figXl, color: c.textStrong, figures: true, softWrap: false),
          ),
        ),
        Semantics(label: l.clientVouchersQrAwake, child: const SizedBox.shrink()),
        const SizedBox(height: GzSpace.s4),
      ],
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      child: Row(
        children: [
          Expanded(child: GzText(name, role: GzTextRole.d1, color: c.textStrong, header: true)),
          const SizedBox(width: GzSpace.s1),
          GzBarButton(key: const ValueKey<String>('gz:sheet.close'), icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: context.gzNav.closeSheet),
        ],
      ),
    );
  }
}
