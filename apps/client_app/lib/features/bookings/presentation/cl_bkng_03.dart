import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/bookings_data.dart';
import '../application/bookings_model.dart';
import 'widgets/bk_common.dart';

/// CL-BKNG-03 Cancel request (sheet). Covers CA-STAT-09, CA-STAT-06, CA-VCH-11.
///
/// The consequence first (ADR 0033): withdrawing a pending request or cancelling an approval returns the voucher for reuse at the same
/// venue; cancelling a confirmed booking uses the voucher up. Then a reason and an explicit confirm. No refund amount, no IBAN and no
/// arrival estimate: no event money moved through Ghazal. Done closes the sheet over 'CL-BKNG-02' (the detail that opened it).
/// Params: bookingId (else the hero request), variant (withdraw | approved |
/// confirmed, else from the request).
class ClBkng03Screen extends ConsumerStatefulWidget {
  const ClBkng03Screen({super.key});

  @override
  ConsumerState<ClBkng03Screen> createState() => _ClBkng03State();
}

enum _Step { consequence, reason, confirm, done }

enum _Reason { plans, venue, date, budget, other }

class _ClBkng03State extends ConsumerState<ClBkng03Screen> {
  _Step _step = _Step.consequence;
  _Reason? _reason;
  String _note = '';
  bool _busy = false;
  bool _failed = false;
  CancelKind? _locked;

  CancelKind _kind(BookingFacts? facts, BookingVariant? variant, String? param) {
    if (_locked != null) return _locked!;
    if (param == 'confirmed') return CancelKind.confirmed;
    if (param == 'approved') return CancelKind.approved;
    if (param == 'withdraw') return CancelKind.withdraw;
    if (facts == null || variant == null) return CancelKind.withdraw;
    return cancelKindOf(variant);
  }

  String _title(AppL10n l, CancelKind kind, bool done) => done
      ? switch (kind) {
          CancelKind.withdraw => l.clientBookingsCancelDoneWithdrawn,
          CancelKind.approved => l.clientBookingsCancelDoneApproved,
          CancelKind.confirmed => l.clientBookingsCancelDoneConfirmed,
        }
      : switch (kind) {
          CancelKind.withdraw => l.clientBookingsCancelTitleWithdraw,
          CancelKind.approved => l.clientBookingsCancelTitleApproved,
          CancelKind.confirmed => l.clientBookingsCancelTitleConfirmed,
        };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final id = nav.params['bookingId'] as String?;
    final variantParam = nav.params['variant'] as String?;
    final async = ref.watch(bookingFactsProvider(id));
    final now = ref.watch(clockProvider)();
    final facts = keepStale(async).value;
    final variant = facts == null ? null : bookingVariantOf(facts.booking, now);
    final kind = _kind(facts, variant, variantParam);
    // The kind of cancellation is read once: after a live cancel the request is cancelled under the open sheet.
    _locked ??= facts == null ? null : cancelKindOf(variant!);
    final locked = _locked ?? kind;
    final done = _step == _Step.done;

    return Column(
      key: const ValueKey<String>('bookings.cancel'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: BkSheetTop(
            title: done ? null : _title(l, locked, false),
            info: _step == _Step.consequence && facts != null
                ? GzInfoButton(title: l.clientBookingsCancelInfoTitle, paragraphs: _terms(context, facts, locked))
                : null,
          ),
        ),
        BkAsync<BookingFacts>(
          value: async,
          onRetry: () => ref.invalidate(bookingFactsProvider),
          loading: const GzSkeleton(blockSize: 160),
          data: (f) => _body(context, f, locked, bookingVariantOf(f.booking, now)),
        ),
      ],
    );
  }

  List<String> _terms(BuildContext context, BookingFacts facts, CancelKind kind) {
    final l = context.l10n;
    final f = context.gzFormat;
    final name = context.bi(facts.target.name);
    return [
      kind == CancelKind.withdraw
          ? l.clientBookingsCancelDateWithdraw(name)
          : kind == CancelKind.approved
          ? l.clientBookingsCancelDateApproved(bkDayFull(f, facts.booking.eventDate))
          : l.clientBookingsCancelDateConfirmed(bkDayFull(f, facts.booking.eventDate), name),
      kind == CancelKind.confirmed
          ? l.clientBookingsCancelVoucherUsedBody
          : l.clientBookingsCancelVoucherBackBody(name, bkDayFull(f, facts.booking.eventDate)),
      if (kind == CancelKind.confirmed) l.clientBookingsCancelVenueMoney(name),
    ];
  }

  Widget _body(BuildContext context, BookingFacts facts, CancelKind kind, BookingVariant variant) {
    return switch (_step) {
      _Step.consequence => _consequence(context, facts, kind),
      _Step.reason => _reasonStep(context, facts, kind),
      _Step.confirm => _confirmStep(context, facts, kind, variant),
      _Step.done => _doneStep(context, facts, kind),
    };
  }

  List<BkFactLine> _consequenceLines(BuildContext context, BookingFacts facts, CancelKind kind) {
    final l = context.l10n;
    final f = context.gzFormat;
    final lines = <BkFactLine>[];
    if (kind != CancelKind.withdraw) {
      lines.add(
        BkFactLine(
          icon: GzIcons.calendarX,
          label: l.clientBookingsCancelDateLabel,
          value: l.clientBookingsCancelDateReleased,
          trailing: GzFactChip(icon: GzIcons.calendar, label: l.clientBookingsFactDate, value: bkDayMon(f, facts.booking.eventDate), small: true, tone: GzFactTone.muted),
        ),
      );
    }
    lines.add(
      kind == CancelKind.confirmed
          ? BkFactLine(
              icon: GzIcons.ticket,
              label: l.clientBookingsCancelVoucherLabel,
              value: l.clientBookingsCancelVoucherUsed,
              trailing: GzFactChip(icon: GzIcons.checkDouble, label: l.clientBookingsCancelVoucherUsed, value: l.clientBookingsCancelVoucherUsed, small: true, tone: GzFactTone.muted),
            )
          : () {
              final until = facts.voucher?.validUntil;
              return BkFactLine(
                icon: GzIcons.ticket,
                label: l.clientBookingsCancelVoucherLabel,
                value: l.clientBookingsCancelVoucherBack,
                trailing: until == null
                    ? null
                    : GzFactChip(icon: GzIcons.calendar, label: l.clientBookingsOutcomeUntil, value: bkDayMon(f, until), small: true, tone: GzFactTone.muted),
              );
            }(),
    );
    return lines;
  }

  Widget _consequence(BuildContext context, BookingFacts facts, CancelKind kind) {
    final l = context.l10n;
    final keep = kind == CancelKind.confirmed ? l.clientBookingsCancelKeepBooking : l.clientBookingsCancelKeep;
    return BkGap(
      gap: GzSpace.s5,
      children: [
        Semantics(container: true, label: l.clientBookingsCancelInfoTitle, child: BkFactLines(lines: _consequenceLines(context, facts, kind))),
        GzButton(variant: GzButtonVariant.tertiary, fullWidth: true, iconStart: GzIcons.chat, onPressed: _message, label: l.clientBookingsCancelAltAction),
        BkGap(
          gap: GzSpace.s3,
          children: [
            GzButton(variant: GzButtonVariant.primary, fullWidth: true, onPressed: () => setState(() => _step = _Step.reason), label: context.gzL10n.commonActionContinue),
            GzButton(variant: GzButtonVariant.secondary, fullWidth: true, onPressed: () => context.gzNav.closeSheet(), label: keep),
          ],
        ),
      ],
    );
  }

  void _message() {
    final nav = context.gzNav;
    final id = nav.params['bookingId'] as String?;
    final facts = ref.read(bookingFactsProvider(id)).value;
    nav.closeSheet();
    nav.push('CL-MSGS-02', params: <String, Object?>{'bookingId': facts?.booking.id ?? id ?? kBookingsHeroId, 'venueId': facts?.booking.venueId});
  }

  Widget _reasonStep(BuildContext context, BookingFacts facts, CancelKind kind) {
    final l = context.l10n;
    final reasons = <GzChipOption<_Reason>>[
      GzChipOption(value: _Reason.plans, label: l.clientBookingsCancelReasonPlans),
      GzChipOption(value: _Reason.venue, label: l.clientBookingsCancelReasonVenue),
      GzChipOption(value: _Reason.date, label: l.clientBookingsCancelReasonDate),
      GzChipOption(value: _Reason.budget, label: l.clientBookingsCancelReasonBudget),
      GzChipOption(value: _Reason.other, label: l.clientBookingsCancelReasonOther),
    ];
    return BkGap(
      children: [
        GzText(l.clientBookingsCancelReasonTitle, role: GzTextRole.title, color: context.gz.colors.textStrong, header: true),
        GzChipGroup<_Reason>(options: reasons, label: l.clientBookingsCancelReasonTitle, value: _reason, onChanged: (v) => setState(() => _reason = v)),
        GzTextArea(label: l.clientBookingsCancelNote, optional: true, value: _note, onValueChange: (v) => setState(() => _note = v), maxLength: 300),
        GzButton(variant: GzButtonVariant.primary, fullWidth: true, onPressed: () => setState(() => _step = _Step.confirm), label: context.gzL10n.commonActionContinue),
      ],
    );
  }

  CancelReason _code(CancelKind kind) => switch (_reason) {
    _Reason.plans => CancelReason.plansChanged,
    _Reason.venue => CancelReason.foundOtherVenue,
    _Reason.date => CancelReason.dateChanged,
    _Reason.budget => CancelReason.budget,
    _Reason.other || null => kind == CancelKind.withdraw ? CancelReason.withdrawn : CancelReason.other,
  };

  Future<void> _finish(BookingFacts facts, BookingVariant variant) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final res = await ref.read(voucherActionsProvider.notifier).cancelRequest(facts.booking.id, reason: _code(_kind(facts, variant, null)), version: facts.booking.version, status: facts.booking.status);
    if (!mounted) return;
    setState(() => _busy = false);
    res.when(
      success: (_) {
        _locked = _kind(facts, variant, null);
        setState(() => _step = _Step.done);
      },
      gated: () => context.gzNav.openSheet('CL-AUTH-01'),
      failure: (_) => setState(() => _failed = true),
    );
  }

  Widget _confirmStep(BuildContext context, BookingFacts facts, CancelKind kind, BookingVariant variant) {
    final l = context.l10n;
    final action = kind == CancelKind.withdraw
        ? l.clientBookingsCancelActionWithdraw
        : kind == CancelKind.approved
            ? l.clientBookingsCancelActionApproved
            : l.clientBookingsCancelActionConfirmed;
    if (_failed) {
      return GzErrorState(kind: GzErrorKind.generic, title: l.clientBookingsCancelErrorTitle, body: l.clientBookingsCancelErrorBody, onRetry: () => _finish(facts, variant), fill: false);
    }
    return BkGap(
      gap: GzSpace.s5,
      children: [
        BkFactLines(lines: [_consequenceLines(context, facts, kind).last]),
        GzButton(variant: GzButtonVariant.destructive, iconStart: GzIcons.close, loading: _busy, onPressed: () => _finish(facts, variant), label: action),
        GzButton(variant: GzButtonVariant.secondary, fullWidth: true, onPressed: () => context.gzNav.closeSheet(), label: kind == CancelKind.confirmed ? l.clientBookingsCancelKeepBooking : l.clientBookingsCancelKeep),
      ],
    );
  }

  Widget _doneStep(BuildContext context, BookingFacts facts, CancelKind kind) {
    final l = context.l10n;
    return BkStateStack(
      illustration: GzIllustrationName.seal,
      title: _title(l, kind, true),
      actions: [GzButton(variant: GzButtonVariant.primary, fullWidth: true, onPressed: () => context.gzNav.closeSheet(), label: context.gzL10n.commonActionDone)],
      children: [VoucherOutcome(voucher: facts.voucher, targetName: context.bi(facts.target.name), primary: kind != CancelKind.confirmed)],
    );
  }
}

/// The voucher outcome after a cancellation: what happened to the voucher (ADR 0035 D4).
class VoucherOutcome extends StatelessWidget {
  const VoucherOutcome({required this.voucher, required this.targetName, this.primary = true, super.key});

  final Voucher? voucher;
  final String targetName;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    if (voucher == null) {
      return GzText(primary ? l.clientBookingsCancelVoucherBack : l.clientBookingsCancelVoucherUsed, role: GzTextRole.bodyS, color: c.textSecondary);
    }
    final v = voucher!;
    final until = v.validUntil == null ? null : bkDayMon(f, v.validUntil!);
    return Semantics(
      container: true,
      label: primary ? l.clientBookingsCancelVoucherBack : l.clientBookingsCancelVoucherUsed,
      child: BkFactLines(
        lines: [
          BkFactLine(icon: GzIcons.ticket, label: l.clientBookingsCancelVoucherLabel, value: primary ? l.clientBookingsCancelVoucherBack : l.clientBookingsCancelVoucherUsed),
          if (primary && until != null)
            BkFactLine(icon: GzIcons.calendar, label: l.clientBookingsOutcomeUntil, value: until, trailing: GzFactChip(icon: GzIcons.calendar, label: l.clientBookingsOutcomeUntil, value: until, small: true, tone: GzFactTone.muted)),
          BkFactLine(icon: GzIcons.hall, label: targetName, value: targetName, autoDir: true),
        ],
      ),
    );
  }
}
