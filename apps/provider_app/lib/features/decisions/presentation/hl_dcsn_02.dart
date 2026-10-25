// HL-DCSN-02 Decline request (sheet; web `HL-DCSN-02.tsx`). Requirement IDs: HA-BOOK-04, HA-AUTH-02.
// ADR 0008 D7: Decline = three taps (Decline, reason, confirm). The reason is required because it powers the couple's recovery path;
// "Suggest dates" is on by default and hands off to Propose date (HL-DCSN-03). There is no Undo for a decline. Declining releases the client's
// voucher back to them: there is no payment consequence. Gold is the one primary; nothing here is red. Params: `bookingId`.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/decisions_data.dart';
import 'widgets/dc_blocks.dart';
import 'widgets/dc_sheet.dart';
import 'widgets/request_context.dart';

class HlDcsn02Screen extends ConsumerStatefulWidget {
  const HlDcsn02Screen({super.key});

  @override
  ConsumerState<HlDcsn02Screen> createState() => _State();
}

class _State extends ConsumerState<HlDcsn02Screen> {
  RejectReason? _reason;
  String _note = '';
  bool _suggest = true;
  bool _tried = false;
  bool _loading = false;
  bool _done = false;

  Future<void> _submit(PartnerRequestDetail d) async {
    final reason = _reason;
    if (reason == null || _loading) return;
    final noteMissing = reason == RejectReason.other && _note.trim().isEmpty;
    if (noteMissing) {
      setState(() => _tried = true);
      return;
    }
    final nav = context.gzNav;
    if (_suggest) {
      // Hand-off: the reason travels with the proposal; the request stays pending until the proposal is sent.
      nav.closeSheet();
      nav.openSheet('HL-DCSN-03', options: GzSheetOptions(params: {'bookingId': d.booking.id, 'from': 'decline', 'reason': reason.value}));
      return;
    }
    setState(() => _loading = true);
    final res = await ref
        .read(requestActionsProvider.notifier)
        .decline(d.booking.id, reason, note: reason == RejectReason.other ? _note.trim() : null, version: d.booking.version);
    if (!mounted) return;
    res.when(
      success: (_) {
        setState(() {
          _loading = false;
          _done = true;
        });
        nav.toast(GzToastSpec(message: context.l10n.hotelDecisionsDeclinedTitle, icon: GzIcons.checkCircle));
        nav.closeSheet();
      },
      failure: (p) {
        setState(() => _loading = false);
        nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
      },
      gated: () => setState(() => _loading = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final nav = context.gzNav;
    final id = (nav.params['bookingId'] as String?) ?? kStoryBookingId;
    final async = ref.watch(decisionRequestProvider(id));
    final d = async.value;
    final reason = _reason;
    final needsNote = reason == RejectReason.other;
    final noteMissing = needsNote && _note.trim().isEmpty;

    final footer = d == null
        ? null
        : _done
        ? GzButton(
            label: cl.commonActionDone,
            variant: GzButtonVariant.secondary,
            size: GzButtonSize.cta,
            fullWidth: true,
            onPressed: () => nav.closeSheet(),
          )
        : GzButton(
            label: _suggest ? l.hotelDecisionsDeclineCtaNext : l.hotelDecisionsDeclineCta,
            fullWidth: true,
            loading: _loading,
            iconEnd: _suggest ? GzIcons.arrowRight : null,
            reason: reason == null ? l.hotelDecisionsPickReason : null,
            onPressed: reason == null ? null : () => _submit(d),
          );

    Widget body(PartnerRequestDetail d) {
      if (_done) {
        return DcState(
          success: true,
          illustration: GzIllustrationName.envelope,
          title: l.hotelDecisionsDeclinedTitle,
          detail: l.hotelDecisionsDeclinedBody,
          facts: DcFactLine(icon: GzIcons.ticket, text: l.hotelDecisionsDeclineVoucher),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DcSectionLabel(l.hotelDecisionsReason),
          DcReasonTiles<RejectReason>(
            label: l.hotelDecisionsReason,
            value: reason,
            onChanged: (v) => setState(() => _reason = v),
            options: [
              DcReason(RejectReason.dateUnavailable, GzIcons.calendarX, l.hotelDecisionsDeclineReasonDate),
              DcReason(RejectReason.capacityMismatch, GzIcons.usersThree, l.hotelDecisionsDeclineReasonCapacity),
              DcReason(RejectReason.packageNotOffered, GzIcons.package, l.hotelDecisionsDeclineReasonPackage),
              DcReason(RejectReason.other, GzIcons.more, l.hotelDecisionsDeclineReasonOther),
            ],
          ),
          if (needsNote) ...[
            const SizedBox(height: GzSpace.s4),
            GzTextArea(
              label: l.hotelDecisionsNote,
              helper: l.hotelDecisionsNoteHelper,
              error: _tried && noteMissing ? l.hotelDecisionsNoteRequired : null,
              value: _note,
              onValueChange: (v) => setState(() => _note = v),
              rows: 3,
              maxLength: 200,
            ),
          ],
          const SizedBox(height: GzSpace.s4),
          DcSwitchRow(
            icon: GzIcons.calendarPlus,
            title: l.hotelDecisionsDeclineSuggestTitle,
            checked: _suggest,
            onChanged: (v) => setState(() => _suggest = v),
          ),
          const SizedBox(height: GzSpace.s4),
          DcFactLine(icon: GzIcons.ticket, text: l.hotelDecisionsDeclineVoucher),
          if (!_suggest) ...[const SizedBox(height: GzSpace.s2), DcFactLine(icon: GzIcons.info, text: l.hotelDecisionsDeclineNoUndoShort)],
        ],
      );
    }

    return DcSheet(
      title: l.hotelDecisionsDeclineTitle,
      info: _done || d == null
          ? null
          : GzInfoButton(
              title: l.hotelDecisionsTermsTitle,
              paragraphs: [l.hotelDecisionsDeclineSuggestBody, l.hotelDecisionsDeclineVoucherInfo, l.hotelDecisionsDeclineNoUndo],
            ),
      context: d == null ? null : RequestContext(detail: d),
      footer: footer,
      children: [
        GzAsyncView<PartnerRequestDetail>(
          value: async,
          loading: const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 220),
          onRetry: () => ref.invalidate(decisionRequestProvider),
          data: body,
        ),
      ],
    );
  }
}
