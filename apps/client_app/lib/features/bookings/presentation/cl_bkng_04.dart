import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/bookings_data.dart';
import 'cl_bkng_03.dart' show VoucherOutcome;
import 'widgets/bk_common.dart';

/// CL-BKNG-04 Venue proposed another date (sheet). Covers CA-STAT-10, CA-STAT-02.
///
/// The client counterpart of the partner's "Propose another date": a counter-offer on a pending request (no reschedule of a confirmed
/// booking). The couple picks one of 1 to 3 dates or declines; the voucher price is held on every date; accepting starts the 24 h
/// confirm window; declining closes the request without a penalty and the voucher stays theirs. Done closes the sheet over 'CL-BKNG-02'
/// (the detail that opened it). Params: bookingId (else the hero request).
class ClBkng04Screen extends ConsumerStatefulWidget {
  const ClBkng04Screen({super.key});

  @override
  ConsumerState<ClBkng04Screen> createState() => _ClBkng04State();
}

enum _Step { choose, decline, accepted, declined, expired }

class _ClBkng04State extends ConsumerState<ClBkng04Screen> {
  _Step _step = _Step.choose;
  int? _picked;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final id = nav.params['bookingId'] as String?;
    final async = ref.watch(bookingFactsProvider(id));
    return Column(
      key: const ValueKey<String>('bookings.proposal'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: BkAsync<BookingFacts>(
            value: async,
            onRetry: () => ref.invalidate(bookingFactsProvider),
            loading: const GzSkeleton(blockSize: 24),
            data: (f) => BkSheetTop(title: _title(l, _step), info: _step == _Step.choose ? _info(context, f) : null),
          ),
        ),
        const SizedBox(height: GzSpace.s4),
        BkAsync<BookingFacts>(
          value: async,
          onRetry: () => ref.invalidate(bookingFactsProvider),
          loading: const GzSkeleton(blockSize: 200),
          data: (f) => _body(context, f),
        ),
      ],
    );
  }

  String _title(AppL10n l, _Step step) => switch (step) {
    _Step.accepted => l.clientBookingsProposalAcceptedTitle,
    _Step.declined => l.clientBookingsProposalClosedTitle,
    _Step.expired => l.clientBookingsProposalExpiredTitle,
    _Step.decline => l.clientBookingsProposalDeclineTitle,
    _Step.choose => l.clientBookingsProposalCounterTitle,
  };

  Widget _info(BuildContext context, BookingFacts facts) {
    final l = context.l10n;
    final f = context.gzFormat;
    final name = context.bi(facts.target.name);
    return GzInfoButton(
      title: l.clientBookingsProposalInfoTitle,
      paragraphs: [
        l.clientBookingsProposalCounterBody(name, bkDayFull(f, facts.booking.eventDate)),
        l.clientBookingsProposalHeld,
        l.clientBookingsNoPenalty,
      ],
    );
  }

  Widget _body(BuildContext context, BookingFacts facts) {
    final proposal = facts.booking.proposal;
    final expired = proposal == null || proposal.status == ProposalStatus.expired;
    final step = expired ? _Step.expired : _step;
    return switch (step) {
      _Step.choose => _choose(context, facts, proposal!),
      _Step.decline => _declineStep(context, facts),
      _Step.accepted => _acceptedStep(context, facts),
      _Step.declined => _declinedStep(context, facts),
      _Step.expired => _expiredStep(context, facts, proposal),
    };
  }

  Widget _choose(BuildContext context, BookingFacts facts, DateProposal proposal) {
    final l = context.l10n;
    final f = context.gzFormat;
    final common = context.gzL10n;
    final picked = _picked;
    return BkGap(
      children: [
        Row(
          children: [
            GzFactChip(
              icon: GzIcons.calendarX,
              label: l.clientBookingsProposedWas,
              value: bkDayMon(f, facts.booking.eventDate),
              tone: GzFactTone.muted,
            ),
            const SizedBox(width: GzSpace.s4),
            GzFactChip(icon: GzIcons.timer, label: l.clientBookingsProposalReplyBy, value: bkStamp(f, proposal.expiresAt), tone: GzFactTone.accent),
          ],
        ),
        Semantics(
          container: true,
          label: l.clientBookingsProposalDatesLabel,
          child: BkGap(
            gap: GzSpace.s3,
            children: [
              for (var i = 0; i < proposal.options.length; i++)
                _DateOption(
                  option: proposal.options[i],
                  selected: picked == i,
                  semanticLabel: l.clientBookingsProposalOptionLabel(
                    bkDayFull(f, proposal.options[i].eventDate),
                    f.money(proposal.options[i].quotedTotal.fils, const MoneyOptions(mode: MoneyMode.exact)),
                  ),
                  onSelect: () => setState(() => _picked = i),
                ),
            ],
          ),
        ),
        // A Container border insets its child (the web rule is part of the 137 high foot); a DecoratedBox border would not.
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.gz.colors.borderHairline, width: GzStroke.hair),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
            child: BkGap(
              gap: GzSpace.s3,
              children: [
                GzButton(
                  variant: GzButtonVariant.primary,
                  fullWidth: true,
                  loading: _busy,
                  onPressed: picked == null ? null : () => _accept(facts, proposal, picked),
                  label: l.clientBookingsProposalAccept,
                ),
                Row(
                  children: [
                    Expanded(
                      child: GzButton(
                        variant: GzButtonVariant.secondary,
                        fullWidth: true,
                        iconStart: GzIcons.chat,
                        onPressed: () => _message(facts),
                        label: common.commonActionMessage,
                      ),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: GzButton(
                        variant: GzButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: () => setState(() => _step = _Step.decline),
                        label: common.commonActionDecline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _accept(BookingFacts facts, DateProposal proposal, int index) async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await ref.read(voucherActionsProvider.notifier).acceptProposal(facts.booking.id, proposal.id, index, version: facts.booking.version);
    if (!mounted) return;
    setState(() => _busy = false);
    res.when(
      success: (_) => setState(() => _step = _Step.accepted),
      gated: () => context.gzNav.openSheet('CL-AUTH-01'),
      failure: (p) => context.gzNav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger)),
    );
  }

  Future<void> _decline(BookingFacts facts) async {
    final proposal = facts.booking.proposal;
    if (proposal == null) return;
    if (_busy) return;
    setState(() => _busy = true);
    final res = await ref.read(voucherActionsProvider.notifier).declineProposal(facts.booking.id, proposal.id, version: facts.booking.version);
    if (!mounted) return;
    setState(() => _busy = false);
    res.when(
      success: (_) => setState(() => _step = _Step.declined),
      gated: () => context.gzNav.openSheet('CL-AUTH-01'),
      failure: (p) => context.gzNav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger)),
    );
  }

  void _message(BookingFacts facts) {
    final nav = context.gzNav;
    nav.closeSheet();
    nav.push('CL-MSGS-02', params: <String, Object?>{'bookingId': facts.booking.id, 'venueId': facts.booking.venueId});
  }

  Widget _declineStep(BuildContext context, BookingFacts facts) {
    final l = context.l10n;
    return BkGap(
      children: [
        BkFactLines(
          lines: [
            BkFactLine(
              icon: GzIcons.ticket,
              label: l.clientBookingsCancelVoucherLabel,
              value: l.clientBookingsCancelVoucherBack,
              trailing: GzFactChip(
                icon: GzIcons.ticket,
                label: l.clientBookingsCancelVoucherLabel,
                value: l.clientBookingsCancelVoucherBack,
                small: true,
                tone: GzFactTone.muted,
              ),
            ),
          ],
        ),
        GzButton(
          variant: GzButtonVariant.destructive,
          fullWidth: true,
          iconStart: GzIcons.close,
          loading: _busy,
          onPressed: () => _decline(facts),
          label: l.clientBookingsProposalDeclineAction,
        ),
        GzButton(
          variant: GzButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => setState(() => _step = _Step.choose),
          label: l.clientBookingsProposalDeclineKeep,
        ),
      ],
    );
  }

  Widget _acceptedStep(BuildContext context, BookingFacts facts) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = context.gzNav;
    final option = _picked == null ? null : facts.booking.proposal?.options[_picked!];
    final date = option?.eventDate ?? facts.booking.eventDate;
    final confirmBy = facts.booking.confirmBy;
    return BkStateStack(
      illustration: GzIllustrationName.successBooking,
      title: l.clientBookingsProposalAcceptedTitle,
      actions: [
        GzButton(
          variant: GzButtonVariant.primary,
          onPressed: () {
            nav.closeSheet();
            nav.push('CL-BOOK-08', params: <String, Object?>{'bookingId': facts.booking.id});
          },
          label: context.gzL10n.commonConfirmBooking,
        ),
        GzButton(variant: GzButtonVariant.tertiary, onPressed: () => nav.closeSheet(), label: l.clientBookingsLater),
      ],
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GzFactChip(icon: GzIcons.calendarCheck, label: l.clientBookingsFactDate, value: bkDayYear(f, date)),
            if (confirmBy != null) ...[
              const SizedBox(width: GzSpace.s3),
              GzFactChip(icon: GzIcons.timer, label: l.clientBookingsProposalConfirmBy, value: bkStamp(f, confirmBy), tone: GzFactTone.accent),
            ],
          ],
        ),
      ],
    );
  }

  Widget _declinedStep(BuildContext context, BookingFacts facts) {
    final l = context.l10n;
    final nav = context.gzNav;
    return BkStateStack(
      illustration: GzIllustrationName.seal,
      title: l.clientBookingsProposalClosedTitle,
      actions: [GzButton(variant: GzButtonVariant.primary, onPressed: () => nav.closeSheet(), label: context.gzL10n.commonActionDone)],
      children: [VoucherOutcome(voucher: facts.voucher, targetName: context.bi(facts.target.name))],
    );
  }

  Widget _expiredStep(BuildContext context, BookingFacts facts, DateProposal? proposal) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = context.gzNav;
    final common = context.gzL10n;
    return BkStateStack(
      illustration: GzIllustrationName.hourglass,
      title: l.clientBookingsProposalExpiredTitle,
      actions: [
        GzButton(
          variant: GzButtonVariant.primary,
          onPressed: () {
            nav.closeSheet();
            nav.push('CL-BOOK-01', params: <String, Object?>{'voucherId': facts.voucher?.id, 'venueId': facts.booking.venueId});
          },
          label: l.clientBookingsSendNew,
        ),
        GzButton(
          variant: GzButtonVariant.secondary,
          fullWidth: true,
          iconStart: GzIcons.chat,
          onPressed: () => _message(facts),
          label: common.commonActionMessage,
        ),
      ],
      children: [
        if (proposal != null)
          GzFactChip(
            icon: GzIcons.clockOff,
            label: l.clientBookingsProposalReplyBy,
            value: bkStamp(f, proposal.expiresAt),
            small: true,
            tone: GzFactTone.muted,
          ),
        VoucherOutcome(voucher: facts.voucher, targetName: context.bi(facts.target.name)),
      ],
    );
  }
}

/// One proposed date as a radio card: weekday, day and month on the first line, the re-quoted exact voucher price with its
/// ticket glyph on the second (web DateOption). The gold bead marks the chosen date; the radio sits at inline-end.
class _DateOption extends StatelessWidget {
  const _DateOption({required this.option, required this.selected, required this.semanticLabel, required this.onSelect});

  final DateProposalOption option;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final c = context.gz.colors;
    final civil = f.civil(option.eventDate.toString());
    final date = '${f.weekdayName(civil.weekday, NameStyle.short)} ${f.integer(civil.day)} ${f.monthName(civil.month, short: true)}';
    final ring = GzThreadBead(tone: selected ? GzBeadTone.gold : GzBeadTone.hollow);
    return Semantics(
      label: semanticLabel,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      child: GzPressable(
        onPressed: onSelect,
        builder: (context, st) => Container(
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: selected ? c.borderStrong : c.borderHairline, width: GzStroke.hair),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(GzSpace.panelPad, GzSpace.s2, GzSpace.panelPad, GzSpace.s2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzText(date, role: GzTextRole.title, color: c.textStrong, figures: true),
                      const SizedBox(height: GzSpace.s1),
                      Row(
                        children: [
                          GzIcon(GzIcons.ticket, size: GzIconSize.xs, color: c.iconSuccess, semanticLabel: context.gzL10n.commonVoucherPrice),
                          const SizedBox(width: GzSpace.s2),
                          GzPrice(fils: option.quotedTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                ring,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
