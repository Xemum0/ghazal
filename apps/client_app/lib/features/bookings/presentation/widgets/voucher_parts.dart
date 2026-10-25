import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'bk_common.dart';

GzStatus _voucherState(VoucherStatus s) => switch (s) {
  VoucherStatus.used => GzStatus.voucherUsed,
  VoucherStatus.expired => GzStatus.voucherExpired,
  VoucherStatus.forfeited => GzStatus.voucherForfeited,
  VoucherStatus.creditIssued => GzStatus.voucherCreditIssued,
  VoucherStatus.unpaid => GzStatus.voucherUnpaid,
  _ => GzStatus.voucherActive,
};

bool _attached(Voucher v) => v.status == VoucherStatus.bound || v.status == VoucherStatus.active;

/// The fact under a voucher code: the day it was used, else the day it lapses.
({IconData icon, String label, String value})? _voucherFact(BuildContext context, Voucher v) {
  final l = context.l10n;
  final f = context.gzFormat;
  if (v.status == VoucherStatus.used && v.usedAt != null) {
    return (icon: GzIcons.checkDouble, label: l.clientBookingsTicketUsedOn, value: bkDayYear(f, v.usedAt!));
  }
  if (v.validUntil != null) return (icon: GzIcons.calendar, label: l.clientBookingsTicketValidUntil, value: bkDayYear(f, v.validUntil!));
  return null;
}

/// VoucherLine: the KD 2 voucher of this request as one quiet row (a request not confirmed yet, or over): a ticket disk, the code as a
/// figure, one fact and a chevron; the row opens the voucher.
class VoucherLine extends StatelessWidget {
  const VoucherLine({required this.voucher, required this.onOpen, super.key});

  final Voucher voucher;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final v = voucher;
    final fact = _voucherFact(context, v);
    return GzPressable(
      onPressed: onOpen,
      semanticLabel: '${context.gzL10n.commonVoucher} ${v.code}',
      builder: (context, st) => Container(
        padding: GzSpace.panel,
        decoration: BoxDecoration(
          color: st.pressed ? c.surfaceQuiet : c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Row(
          children: [
            Container(
              width: GzSize.thumbMd,
              height: GzSize.thumbMd,
              decoration: BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: GzIcon(GzIcons.ticket, size: GzIconSize.md, color: c.iconPrimary),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: '${context.gzL10n.commonVoucherCode} ${v.code}',
                    excludeSemantics: true,
                    child: gzFigText(context, v.code, role: GzTextRole.figBody, color: c.textStrong),
                  ),
                  if (fact != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    GzFactChip(icon: fact.icon, label: fact.label, value: fact.value, small: true, tone: GzFactTone.muted),
                  ],
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            if (_attached(v))
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary)
            else
              GzStatusPill(status: _voucherState(v.status)),
          ],
        ),
      ),
    );
  }
}

/// VoucherTicket (a confirmed request): the voucher as a ticket, the QR on its own row and the code on a full-width row under it (the
/// partner reads this code out). A state pill appears only when the voucher changed.
class VoucherTicket extends StatelessWidget {
  const VoucherTicket({required this.voucher, required this.targetName, this.onShowFull, super.key});

  final Voucher voucher;
  final String targetName;
  final VoidCallback? onShowFull;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final v = voucher;
    final live = _attached(v);
    final fact = _voucherFact(context, v);
    return Semantics(
      container: true,
      label: '${context.gzL10n.commonVoucher} ${v.code}',
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: GzSpace.panel,
              child: Row(
                children: [
                  GzIcon(GzIcons.ticket, size: GzIconSize.md, color: c.iconSecondary, semanticLabel: context.gzL10n.commonVoucher),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: GzText(targetName, role: GzTextRole.d1, color: c.textStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  if (!live) GzStatusPill(status: _voucherState(v.status)),
                ],
              ),
            ),
            _Perforation(color: c.borderHairline),
            Padding(
              padding: GzSpace.panel,
              child: Column(
                children: [
                  GzQrCode(payload: v.qr.payload, label: l.clientBookingsTicketQr(v.code), size: 144, muted: !live),
                  const SizedBox(height: GzSpace.s4),
                  Semantics(
                    label: '${context.gzL10n.commonVoucherCode} ${v.code}',
                    excludeSemantics: true,
                    child: gzFigText(context, v.code, role: GzTextRole.figXl, color: c.textStrong),
                  ),
                  if (fact != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    GzFactChip(icon: fact.icon, label: fact.label, value: fact.value, small: true, tone: GzFactTone.muted),
                  ],
                  if (onShowFull != null && live) ...[
                    const SizedBox(height: GzSpace.s4),
                    GzButton(
                      label: l.clientBookingsTicketShowFull,
                      variant: GzButtonVariant.secondary,
                      iconStart: GzIcons.qrCode,
                      fullWidth: true,
                      onPressed: onShowFull,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: GzSpace.s3,
    child: Center(
      child: SizedBox(
        height: GzStroke.hair,
        child: ColoredBox(color: color),
      ),
    ),
  );
}

/// VoucherOutcome: what became of the KD 2 voucher once its request ended (CA-VCH-11): a glyph and a title of at most four words; the
/// reuse date and "ask support" are facts; the sentence is behind the info glyph. A released voucher is reusable at the same venue; a
/// forfeited one (24 h not confirmed) is gone for good. The action opens CL-VCHR-05.
class VoucherOutcome extends StatelessWidget {
  const VoucherOutcome({required this.voucher, required this.targetName, this.primary = false, this.action = true, super.key});

  final Voucher? voucher;
  final String targetName;
  final bool primary;
  final bool action;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final v = voucher;
    IconData icon = GzIcons.undo;
    String title = l.clientBookingsOutcomeBackTitle;
    String body = l.clientBookingsOutcomeBackPlain;
    LocalDate? until;
    var askable = false;
    String? actionLabel;
    switch (v?.status) {
      case VoucherStatus.used:
        icon = GzIcons.checkDouble;
        title = l.clientBookingsOutcomeUsedTitle;
        body = l.clientBookingsOutcomeUsedBody;
      case VoucherStatus.forfeited:
        icon = GzIcons.xCircle;
        title = l.clientBookingsOutcomeForfeitedTitle;
        body = l.clientBookingsOutcomeForfeitedBody(targetName, 24);
      case VoucherStatus.creditIssued:
        icon = GzIcons.gift;
        title = l.clientBookingsOutcomeCreditTitle;
        body = l.clientBookingsOutcomeCreditBody;
      case VoucherStatus.expired:
        icon = GzIcons.clockOff;
        title = l.clientBookingsOutcomeExpiredTitle;
        body = l.clientBookingsOutcomeExpiredBody;
      default:
        if (v != null && v.reuseUntil != null) {
          until = v.reuseUntil;
          askable = v.creditEligible;
          final date = bkDayFull(f, until!);
          body = askable ? l.clientBookingsOutcomeBackCredit(targetName, date) : l.clientBookingsOutcomeBackReusable(targetName, date);
          actionLabel = l.clientBookingsOutcomeAction;
        }
    }
    return Container(
      padding: GzSpace.panel,
      decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: GzSize.touchMin, minHeight: GzSize.touchMin),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
                decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.pillAll),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GzIcon(GzIcons.ticket, size: GzIconSize.sm, color: c.iconSecondary),
                    const SizedBox(width: GzSpace.s1),
                    GzIcon(icon, size: GzIconSize.sm, color: c.iconPrimary),
                  ],
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: GzText(title, role: GzTextRole.title, color: c.textStrong),
              ),
              GzInfoButton(title: l.clientBookingsOutcomeInfoTitle, paragraphs: [body]),
            ],
          ),
          if (until != null || askable) ...[
            const SizedBox(height: GzSpace.s4),
            GzFactRow(
              children: [
                if (until != null) GzFactChip(icon: GzIcons.calendar, label: l.clientBookingsOutcomeUntil, value: bkDayMon(f, until)),
                if (askable)
                  GzFactChip(
                    icon: GzIcons.gift,
                    label: l.clientBookingsOutcomeAskSupport,
                    value: l.clientBookingsOutcomeAskSupport,
                    tone: GzFactTone.muted,
                  ),
              ],
            ),
          ],
          if (actionLabel != null && action && v != null) ...[
            const SizedBox(height: GzSpace.s4),
            GzButton(
              label: actionLabel,
              variant: primary ? GzButtonVariant.primary : GzButtonVariant.secondary,
              iconStart: GzIcons.ticket,
              fullWidth: true,
              onPressed: () => context.gzNav.openSheet('CL-VCHR-05', options: GzSheetOptions(params: <String, Object?>{'voucherId': v.id})),
            ),
          ],
        ],
      ),
    );
  }
}
