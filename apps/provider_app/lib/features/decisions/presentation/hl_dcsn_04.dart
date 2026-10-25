// HL-DCSN-04 Cancel booking (sheet; web `HL-DCSN-04.tsx`). Requirement IDs: HA-BOOK-10, HA-AUTH-02.
// Voucher model (ADR 0033 D3, D4): the venue cancels a CONFIRMED booking (R13b), or withdraws an APPROVED one inside the client's 24 h window
// (R10b), with the consequence shown first. The consequence is about the voucher, never about money: the client's voucher goes back to them,
// a reliability strike is recorded, the date opens again. No refund amount, no gateway fee, no balance case. A softer way out comes first:
// agree the change in the chat. Admin and Manager only. The one action is destructive (never gold); a final dialog repeats the booking.
// Params: `bookingId` (default: the confirmed booking of the story).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/decisions_data.dart';
import 'widgets/dc_blocks.dart';
import 'widgets/dc_sheet.dart';
import 'widgets/request_context.dart';

enum _Reason { hall, safety, other }

CancelReason _code(_Reason r) => switch (r) {
  _Reason.hall => CancelReason.hallUnavailable,
  _Reason.safety => CancelReason.safetyOrMaintenance,
  _Reason.other => CancelReason.other,
};

class HlDcsn04Screen extends ConsumerStatefulWidget {
  const HlDcsn04Screen({super.key});

  @override
  ConsumerState<HlDcsn04Screen> createState() => _State();
}

class _State extends ConsumerState<HlDcsn04Screen> {
  _Reason? _reason;
  String _note = '';
  bool _tried = false;
  bool _loading = false;
  bool _done = false;

  /// An approved request is withdrawn, a confirmed booking is cancelled; latched on open (the request flips to cancelled on confirm).
  bool? _withdraw;

  Future<void> _ask(PartnerRequestDetail d, bool withdraw) async {
    final reason = _reason;
    if (reason == null || _loading) return;
    if (reason == _Reason.other && _note.trim().isEmpty) {
      setState(() => _tried = true);
      return;
    }
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = context.gzNav;
    final name = dcFirstName(d.booking.clientName);
    final r = await nav.openDialog(
      GzDialogSpec(
        title: withdraw ? l.hotelDecisionsCancelDialogTitleApproved : l.hotelDecisionsCancelDialogTitle,
        body: dcPlain(l.hotelDecisionsCancelDialogBody(name, f.date(d.booking.eventDate.toString(), DateStyle.short))),
        icon: GzIcons.warningCircle,
        confirmLabel: withdraw ? l.hotelDecisionsCancelCtaApproved : l.hotelDecisionsCancelCta,
        cancelLabel: context.gzL10n.commonActionBack,
        tone: GzDialogTone.destructive,
      ),
    );
    if (r != GzDialogResult.confirm || !mounted) return;
    setState(() => _loading = true);
    final res = await ref.read(requestActionsProvider.notifier).cancelByPartner(d.booking.id, reason: _code(reason), note: reason == _Reason.other ? _note.trim() : null, version: d.booking.version, status: d.booking.status);
    if (!mounted) return;
    res.when(
      success: (_) => setState(() {
        _loading = false;
        _done = true;
      }),
      failure: (p) {
        setState(() => _loading = false);
        nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
      },
      gated: () => setState(() => _loading = false),
    );
  }

  Widget _consequence(AppL10n l) => DcConsequenceRow(
    label: l.hotelDecisionsCancelConsequence,
    items: [
      DcConsequence(GzIcons.ticket, l.hotelDecisionsConsReturned),
      DcConsequence(GzIcons.flag, l.hotelDecisionsConsStrike, danger: true),
      DcConsequence(GzIcons.calendarCheck, l.hotelDecisionsConsReopens),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final nav = context.gzNav;
    final id = (nav.params['bookingId'] as String?) ?? kLulwaBookingId;
    final async = ref.watch(decisionRequestProvider(id));
    final d = async.value;
    final role = ref.watch(partnerContextProvider)?.role ?? StaffRole.manager;
    final allowed = role == StaffRole.admin || role == StaffRole.manager;
    if (d != null) _withdraw ??= d.booking.status == BookingStatus.approved;
    final withdraw = _withdraw ?? false;
    final reason = _reason;

    Widget? footer;
    if (d != null) {
      if (!allowed) {
        footer = GzButton(label: cl.commonActionBack, variant: GzButtonVariant.secondary, size: GzButtonSize.cta, fullWidth: true, onPressed: () => nav.closeSheet());
      } else if (_done) {
        footer = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GzButton(
              label: l.hotelDecisionsCancelledWindow,
              variant: GzButtonVariant.secondary,
              fullWidth: true,
              iconStart: GzIcons.offer,
              onPressed: () {
                nav.closeSheet();
                nav.push('HL-GROW-02', params: {'date': d.booking.eventDate.toString()});
              },
            ),
            const SizedBox(height: GzSpace.s3),
            Align(
              alignment: AlignmentDirectional.center,
              child: GzButton(
                label: l.hotelDecisionsViewBooking,
                variant: GzButtonVariant.tertiary,
                onPressed: () {
                  nav.closeSheet();
                  nav.push('HL-BOOK-03', params: {'bookingId': id});
                },
              ),
            ),
          ],
        );
      } else {
        footer = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GzButton(
              label: withdraw ? l.hotelDecisionsCancelCtaApproved : l.hotelDecisionsCancelCta,
              variant: GzButtonVariant.destructive,
              fullWidth: true,
              iconStart: GzIcons.xCircle,
              loading: _loading,
              reason: reason == null ? l.hotelDecisionsPickReason : null,
              onPressed: reason == null ? null : () => _ask(d, withdraw),
            ),
            const SizedBox(height: GzSpace.s3),
            Align(alignment: AlignmentDirectional.center, child: GzButton(label: withdraw ? l.hotelDecisionsCancelKeepApproved : l.hotelDecisionsCancelKeep, variant: GzButtonVariant.tertiary, onPressed: () => nav.closeSheet())),
          ],
        );
      }
    }

    Widget body(PartnerRequestDetail d) {
      if (!allowed) return DcState(illustration: GzIllustrationName.shield, title: l.hotelDecisionsCancelHiddenTitle, detail: l.hotelDecisionsCancelHiddenBody);
      if (_done) {
        return DcState(success: true, illustration: GzIllustrationName.doorway, title: withdraw ? l.hotelDecisionsCancelledTitleApproved : l.hotelDecisionsCancelledTitle, facts: _consequence(l));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DcLinkRow(
            icon: GzIcons.chat,
            title: l.hotelDecisionsCancelTalkTitle,
            onPressed: () {
              nav.closeSheet();
              nav.push('HL-TODY-05', params: {'bookingId': d.booking.id, 'conversationId': d.conversationId});
            },
          ),
          const SizedBox(height: GzSpace.s4),
          DcSectionLabel(l.hotelDecisionsReason),
          DcReasonTiles<_Reason>(
            label: l.hotelDecisionsReason,
            value: reason,
            onChanged: (v) => setState(() => _reason = v),
            options: [
              DcReason(_Reason.hall, GzIcons.calendarX, l.hotelDecisionsCancelReasonHall),
              DcReason(_Reason.safety, GzIcons.warning, l.hotelDecisionsCancelReasonSafety),
              DcReason(_Reason.other, GzIcons.more, l.hotelDecisionsCancelReasonOther),
            ],
          ),
          if (reason == _Reason.other) ...[
            const SizedBox(height: GzSpace.s4),
            GzTextArea(label: l.hotelDecisionsNote, error: _tried && _note.trim().isEmpty ? l.hotelDecisionsNoteRequired : null, value: _note, onValueChange: (v) => setState(() => _note = v), rows: 3, maxLength: 200),
          ],
          const SizedBox(height: GzSpace.s4),
          Semantics(
            liveRegion: true,
            container: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [DcSectionLabel(l.hotelDecisionsCancelConsequence), _consequence(l)]),
          ),
        ],
      );
    }

    return DcSheet(
      title: withdraw ? l.hotelDecisionsCancelTitleApproved : l.hotelDecisionsCancelTitle,
      info: (!allowed || _done || d == null)
          ? null
          : GzInfoButton(title: l.hotelDecisionsCancelConsequence, paragraphs: [l.hotelDecisionsCancelVoucherInfo, l.hotelDecisionsCancelStrikeInfo, l.hotelDecisionsCancelNoMoney, l.hotelDecisionsCancelTalkBody]),
      context: d == null ? null : RequestContext(detail: d, end: allowed ? DcPriceFact(fils: d.booking.totals.voucherTotal.fils, label: cl.commonVoucherPrice) : null),
      footer: footer,
      children: [
        GzAsyncView<PartnerRequestDetail>(
          value: async,
          loading: const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 260),
          onRetry: () => ref.invalidate(decisionRequestProvider),
          data: body,
        ),
      ],
    );
  }
}
