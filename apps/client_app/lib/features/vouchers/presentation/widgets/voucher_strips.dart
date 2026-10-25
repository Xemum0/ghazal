import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/voucher_model.dart';
import '../../application/voucher_providers.dart' show VoucherView;
import '../voucher_fmt.dart';
import '../voucher_why.dart';
import 'voucher_detail_parts.dart';
import 'voucher_parts.dart';
import 'voucher_terms.dart';

/// The phase strip of a bound voucher (web `BoundDetail` switch): what the voucher is doing now, in a glyph or a drawing, a word, facts
/// and the info glyph that holds the one paragraph that survived the diet. [askSupport] opens the credit-voucher sheet; [openCredit]
/// opens the credit voucher support issued.
Widget phaseStripOf(
  BuildContext context, {
  required VoucherView view,
  required VoucherPhase phase,
  required String name,
  required VoidCallback askSupport,
  required void Function(String id) openCredit,
}) {
  final l = context.l10n;
  final cl = context.gzL10n;
  final f = context.gzFormat;
  final d = view.detail;
  final v = d.voucher as Voucher;
  final booking = d.booking;
  final saving = (v.quoteFils.standard - v.quoteFils.voucher).clamp(0, 1 << 40);
  final options = d.options;
  switch (phase) {
    case VoucherPhase.ready:
      return PhaseStrip(
        key: const ValueKey<String>('voucher.phase.ready'),
        infoTitle: l.clientVouchersTermsTitle,
        infoChildren: [VoucherTerms(name: name, config: view.config, replyHours: booking?.slaHours ?? view.config.defaultReplyHours)],
        child: saving > 0 ? Align(alignment: AlignmentDirectional.centerStart, child: VoucherSaving(fils: saving)) : null,
      );
    case VoucherPhase.pending:
      return PhaseStrip(illustration: GzIllustrationName.envelope, tone: PhaseTone.pending, title: l.clientVouchersPhaseWaiting, infoTitle: l.clientVouchersInfoRequest, infoParagraphs: [l.clientVouchersInfoWaiting(name)]);
    case VoucherPhase.approved:
      final by = booking?.confirmBy;
      if (by != null) return ConfirmLeftPanel(deadline: by);
      return PhaseStrip(icon: GzIcons.calendarCheck, tone: PhaseTone.pending, title: cl.commonStatusApproved, infoTitle: l.clientVouchersInfoWindow, infoParagraphs: [l.clientVouchersWindowBody]);
    case VoucherPhase.confirmed:
      return PhaseStrip(icon: GzIcons.receipt, tone: PhaseTone.success, title: l.clientVouchersPhaseDirect, infoTitle: l.clientVouchersInfoPay, infoParagraphs: [l.clientVouchersPayBody(name)]);
    case VoucherPhase.redeemed:
      return PhaseStrip(illustration: GzIllustrationName.seal, tone: PhaseTone.success, title: cl.commonVoucherStatusUsed);
    case VoucherPhase.consumed:
      return PhaseStrip(illustration: GzIllustrationName.hourglass, title: l.clientVouchersPhaseUsedUp, infoTitle: l.clientVouchersInfoUsedUp, infoParagraphs: [l.clientVouchersUsedUpBody]);
    case VoucherPhase.released:
      final why = voucherWhy(context, v.releaseReason, name);
      final reuse = v.reuseUntil == null ? '' : f.dayMon(v.reuseUntil.toString());
      final eligible = options?.creditEligible ?? v.creditEligible;
      return PhaseStrip(
        icon: why.icon,
        tone: PhaseTone.pending,
        title: why.word,
        infoTitle: l.clientVouchersInfoBack,
        infoParagraphs: [why.sentence, eligible ? l.clientVouchersBackCredit(reuse) : l.clientVouchersBackKept(reuse)],
        actions: eligible ? GzButton(label: cl.commonAskSupport, variant: GzButtonVariant.tertiary, iconStart: GzIcons.headset, onPressed: askSupport) : null,
        child: v.reuseUntil == null ? null : voucherFact(context, icon: GzIcons.calendar, label: l.clientVouchersLabelReuse, value: reuse, tone: GzFactTone.accent),
      );
    case VoucherPhase.expired:
      return PhaseStrip(
        illustration: GzIllustrationName.hourglass,
        title: cl.commonVoucherStatusExpired,
        infoTitle: cl.commonVoucherStatusExpired,
        infoParagraphs: [l.clientVouchersExpiredBody(f.dayMon(v.validUntil ?? ''))],
      );
    case VoucherPhase.forfeited:
      return PhaseStrip(
        icon: GzIcons.xCircle,
        tone: PhaseTone.danger,
        title: cl.commonVoucherStatusForfeited,
        infoTitle: cl.commonVoucherStatusForfeited,
        infoParagraphs: [l.clientVouchersForfeitedBody(f.digits(l.commonCountHours(view.config.confirmWindowHours)))],
        child: v.forfeitedAt == null ? null : voucherFact(context, icon: GzIcons.calendar, label: cl.commonVoucherStatusForfeited, value: f.dayMon(v.forfeitedAt!)),
      );
    case VoucherPhase.creditIssued:
      final creditId = d.refundRequest?.creditVoucherId;
      return PhaseStrip(
        icon: GzIcons.gift,
        tone: PhaseTone.success,
        title: cl.commonVoucherStatusCreditIssued,
        infoTitle: cl.commonVoucherCredit,
        infoParagraphs: [l.clientVouchersCreditIssuedBody],
        actions: creditId == null ? null : GzButton(label: cl.commonVoucherCredit, variant: GzButtonVariant.tertiary, iconStart: GzIcons.gift, onPressed: () => openCredit(creditId)),
      );
    case VoucherPhase.unpaid:
      return PhaseStrip(icon: GzIcons.hourglass, tone: PhaseTone.pending, title: cl.commonVoucherStatusUnpaid, infoTitle: l.clientVouchersInfoPaying, infoParagraphs: [l.clientVouchersPayingBody]);
  }
}

/// The strip of a ready credit voucher: a gift glyph, the credit word and the validity as a fact (web `CreditDetail`).
class PhaseStripCredit extends StatelessWidget {
  const PhaseStripCredit({required this.body, this.until, super.key});

  final String body;
  final String? until;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PhaseStrip(
      icon: GzIcons.gift,
      tone: PhaseTone.success,
      title: context.gzL10n.commonVoucherCredit,
      infoTitle: context.gzL10n.commonVoucherCredit,
      infoParagraphs: [body],
      child: until == null ? null : voucherFact(context, icon: GzIcons.calendar, label: l.clientVouchersLabelValid, value: until!),
    );
  }
}

/// The strip of an ended credit voucher: a drawing and the word.
class PhaseStripEnded extends StatelessWidget {
  const PhaseStripEnded({required this.used, required this.label, super.key});

  final bool used;
  final String label;

  @override
  Widget build(BuildContext context) => PhaseStrip(illustration: used ? GzIllustrationName.seal : GzIllustrationName.hourglass, title: label);
}
