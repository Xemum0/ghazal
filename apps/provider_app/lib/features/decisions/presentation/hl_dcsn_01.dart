// HL-DCSN-01 Accept request (sheet; web `HL-DCSN-01.tsx`). Requirement IDs: HA-BOOK-03, HA-DASH-03, HA-DASH-04, HA-AUTH-02.
// Voucher model (ADR 0033 D3, D4): accepting APPROVES the request at the voucher price and starts the fixed 24 hour window in which the client
// must confirm; the date is held until then. The usual Accept is inline (two taps, from the card, ADR 0008 D6). THIS sheet is the compact
// confirm: it opens when approving has side effects the manager must see (a competing request or an event within 14 days) and ends in Accept
// followed by the same 8-second Undo (`requestActionsProvider`). The venue may approve at a LOWER voucher price, never higher.
// Text diet (ADR 0034): glyphs and figures; the sentences live behind the info glyph of the header. Params: `bookingId` (default: the hero request).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode, DateStyle, GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/decisions_data.dart';
import 'widgets/dc_blocks.dart';
import 'widgets/dc_sheet.dart';
import 'widgets/request_context.dart';

enum _Phase { idle, loading, success, undone }

String hoursFig(GzFormat f, int hours) {
  final unit = RegExp(r'[^\d\s\u00a0\u2066-\u2069\u0660-\u0669]+').firstMatch(f.duration(3600000))?.group(0) ?? '';
  return '${f.integer(hours)} $unit';
}

class HlDcsn01Screen extends ConsumerStatefulWidget {
  const HlDcsn01Screen({super.key});

  @override
  ConsumerState<HlDcsn01Screen> createState() => _State();
}

class _State extends ConsumerState<HlDcsn01Screen> {
  _Phase _phase = _Phase.idle;
  bool _lowerOpen = false;
  String _reduction = '';
  bool _compareOpen = false;
  bool _conflict = false;
  Booking? _approved;

  Future<void> _accept(PartnerRequestDetail d, int voucherFils) async {
    final b = d.booking;
    final quoted = b.totals.voucherTotal;
    setState(() => _phase = _Phase.loading);
    final res = await ref
        .read(requestActionsProvider.notifier)
        .accept(
          b.id,
          version: b.version,
          lowerVoucherTotal: voucherFils < quoted.fils ? MoneyAmount(voucherFils, d.booking.totals.voucherTotal.currency) : null,
        );
    if (!mounted) return;
    res.when(
      success: (nb) => setState(() {
        _approved = nb;
        _phase = _Phase.success;
      }),
      failure: (p) {
        setState(() {
          _phase = _Phase.idle;
          _conflict = p.code == ApiProblemCode.slotUnavailable;
        });
        if (!_conflict) context.gzNav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
      },
      gated: () => setState(() => _phase = _Phase.idle),
    );
  }

  Future<void> _undo() async {
    final r = await ref.read(requestActionsProvider.notifier).undo();
    if (!mounted) return;
    r.when(
      success: (_) => setState(() => _phase = _Phase.undone),
      failure: (p) => context.gzNav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger)),
      gated: () {},
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
    final f = context.gzFormat;
    final c = context.gz.colors;

    // the sheet decided what to show from the request as it was when it opened
    final stale = d != null && _phase == _Phase.idle && d.booking.status != BookingStatus.pending;
    final released = d != null && _phase == _Phase.idle && d.voucher != null && d.voucher!.status != VoucherStatus.bound;
    final view = stale ? 'already' : (released ? 'released' : (_conflict ? 'conflict' : _phase.name));
    final hours = hoursFig(f, kConfirmHours);
    final duration = cl.commonCountHours(kConfirmHours);

    final quoted = d?.booking.totals.voucherTotal.fils ?? 0;
    final standard = d?.booking.totals.standardTotal.fils ?? 0;
    final typed = _lowerOpen ? gzParseKdToFils(f, _reduction) : null;
    final tooHigh = typed != null && typed >= quoted && quoted > 0;
    final applied = (typed == null || tooHigh) ? 0 : typed;
    final voucherFils = quoted - applied;
    final saving = standard > voucherFils ? standard - voucherFils : 0;

    Widget? footer;
    switch (view) {
      case 'success':
        footer = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GzUndoBar(message: l.hotelDecisionsNotifying, onUndo: _undo, onExpire: () => nav.closeSheet()),
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
      case 'undone':
        footer = GzButton(
          label: cl.commonActionDone,
          variant: GzButtonVariant.secondary,
          size: GzButtonSize.cta,
          fullWidth: true,
          onPressed: () => nav.closeSheet(),
        );
      case 'already':
        footer = GzButton(label: l.hotelDecisionsRefresh, fullWidth: true, onPressed: () => nav.closeSheet());
      case 'released':
        footer = GzButton(
          label: cl.commonActionClose,
          variant: GzButtonVariant.secondary,
          size: GzButtonSize.cta,
          fullWidth: true,
          onPressed: () => nav.closeSheet(),
        );
      case 'conflict':
        footer = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GzButton(label: l.hotelDecisionsAcceptCta, fullWidth: true, iconStart: GzIcons.check),
            const SizedBox(height: GzSpace.s3),
            GzButton(
              label: l.hotelDecisionsProposeTitle,
              variant: GzButtonVariant.secondary,
              fullWidth: true,
              onPressed: () {
                nav.closeSheet();
                nav.openSheet('HL-DCSN-03', options: GzSheetOptions(params: {'bookingId': id}));
              },
            ),
          ],
        );
      default:
        footer = d == null
            ? null
            : GzButton(
                label: l.hotelDecisionsAcceptCta,
                fullWidth: true,
                iconStart: GzIcons.check,
                loading: _phase == _Phase.loading,
                onPressed: tooHigh ? null : () => _accept(d, voucherFils),
              );
    }

    Widget info() => GzInfoButton(
      title: l.hotelDecisionsTermsTitle,
      paragraphs: d == null
          ? const []
          : [
              dcPlain(
                l.hotelDecisionsAcceptConsequence(
                  f.date(d.booking.eventDate.toString(), DateStyle.short),
                  dcFirstName(d.booking.clientName),
                  duration,
                ),
              ),
              l.hotelDecisionsAcceptConfirmRule,
              l.hotelDecisionsAcceptPriceHint,
              l.hotelDecisionsAcceptLowerHint,
            ],
    );

    Widget body(PartnerRequestDetail d) {
      final b = d.booking;
      final name = dcFirstName(b.clientName);
      final date = f.date(b.eventDate.toString(), DateStyle.short);
      switch (view) {
        case 'already':
          return DcState(illustration: GzIllustrationName.emptyBookings, title: l.hotelDecisionsAlreadyTitle, detail: l.hotelDecisionsAlreadyBody);
        case 'released':
          return DcState(illustration: GzIllustrationName.voucher, title: l.hotelDecisionsReleasedTitle, detail: l.hotelDecisionsReleasedBody);
        case 'conflict':
          return DcState(
            illustration: GzIllustrationName.calendar,
            title: l.hotelDecisionsConflictTitle,
            detail: dcPlain(l.hotelDecisionsConflictBody(date)),
          );
        case 'success':
          final deadline = f.dateTime(_approved?.confirmBy ?? f.now().add(const Duration(hours: kConfirmHours)));
          return DcState(
            success: true,
            illustration: GzIllustrationName.successBooking,
            title: l.hotelDecisionsAcceptedTitle,
            detail: '${dcPlain(l.hotelDecisionsAcceptedBody(name, deadline))}\n\n${l.hotelDecisionsAcceptedUndoHint}',
            facts: GzFactRow(
              label: l.hotelDecisionsAcceptHoldLabel(duration),
              children: [
                GzFactChip(icon: GzIcons.hourglass, tone: GzFactTone.accent, label: l.hotelDecisionsAcceptHoldLabel(duration), value: hours),
                GzFactChip(icon: GzIcons.clock, label: l.hotelDecisionsAcceptDeadlineLabel, value: deadline),
              ],
            ),
          );
        case 'undone':
          return DcState(
            illustration: GzIllustrationName.hourglass,
            title: l.hotelDecisionsUndoneTitle,
            detail: l.hotelDecisionsUndoneBody,
            facts: const GzStatusPill(status: GzStatus.pending, audience: GzStatusAudience.hotel),
          );
        default:
      }
      final others = d.otherRequestsSameDate;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            label: l.hotelDecisionsAcceptHoldLabel(duration),
            child: Container(
              padding: const EdgeInsets.all(GzSpace.s4),
              decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: GzSize.avatarSm,
                      height: GzSize.avatarSm,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.surfaceRaised, shape: BoxShape.circle),
                      child: GzIcon(GzIcons.hourglass, size: GzIconSize.md, tone: GzIconTone.accent),
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzText(hours, role: GzTextRole.kpi, color: c.textStrong, figures: true, softWrap: false),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          const GzThreadKnot(state: GzKnotState.now, size: GzKnotSize.compact),
                          Expanded(
                            child: Container(height: GzStroke.thread, color: c.markKhayt),
                          ),
                          const GzThreadKnot(state: GzKnotState.open, size: GzKnotSize.compact),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (others > 0) ...[
            const SizedBox(height: GzSpace.s4),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.touchMin),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GzFactChip(
                    icon: GzIcons.usersThree,
                    tone: GzFactTone.accent,
                    label: l.hotelDecisionsAcceptOthersLine(others),
                    value: '+${f.integer(others)}',
                  ),
                  GzIconButton(
                    icon: GzIcons.compare,
                    iconSize: GzIconSize.sm,
                    variant: GzIconButtonVariant.outline,
                    label: l.hotelDecisionsAcceptCompare,
                    active: _compareOpen,
                    expanded: _compareOpen,
                    onPressed: () => setState(() => _compareOpen = !_compareOpen),
                  ),
                ],
              ),
            ),
            if (_compareOpen) ...[const SizedBox(height: GzSpace.s4), _Compare(booking: b)],
          ],
          const SizedBox(height: GzSpace.s4),
          Container(
            padding: const EdgeInsets.all(GzSpace.s4),
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: GzRadius.mdAll,
              border: Border.all(color: c.borderStrong, width: GzStroke.hair),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DcPriceFact(fils: voucherFils, label: cl.commonVoucherPrice, total: true),
                    GzFactChip(
                      icon: GzIcons.receipt,
                      tone: GzFactTone.muted,
                      small: true,
                      label: l.hotelDecisionsAcceptPriceHint,
                      valueWidget: GzText(l.hotelDecisionsAcceptOffApp, role: GzTextRole.caption, color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: GzSpace.s3),
                Container(
                  padding: const EdgeInsets.only(top: GzSpace.s3),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                    ),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: GzSpace.s4,
                    runSpacing: GzSpace.s2,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GzIcon(GzIcons.offer, size: GzIconSize.xs, tone: GzIconTone.secondary),
                          const SizedBox(width: GzSpace.s1),
                          GzStruckMoney(fils: standard, semanticLabel: cl.commonStandardPrice),
                        ],
                      ),
                      Semantics(
                        label: cl.commonYouSave(f.money(saving)),
                        excludeSemantics: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GzIcon(GzIcons.trendDown, size: GzIconSize.xs, tone: GzIconTone.success, mirror: false),
                            const SizedBox(width: GzSpace.s1),
                            GzText(f.money(saving), role: GzTextRole.bodyS, color: c.textSuccess, figures: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s3),
          DcDiscloseRow(
            icon: GzIcons.percent,
            title: l.hotelDecisionsAcceptLower,
            open: _lowerOpen,
            onToggle: () => setState(() => _lowerOpen = !_lowerOpen),
          ),
          if (_lowerOpen)
            Padding(
              padding: const EdgeInsets.only(top: GzSpace.s1, bottom: GzSpace.s2),
              child: GzTextField(
                label: l.hotelDecisionsAcceptLowerLabel,
                value: _reduction,
                dir: GzFieldDir.ltr,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onValueChange: (v) => setState(() => _reduction = v),
                startAdornment: GzText(f.moneyParts(0).currency, role: GzTextRole.label, color: c.textSecondary),
                error: tooHigh ? l.hotelDecisionsAcceptLowerTooHigh : null,
              ),
            ),
        ],
      );
    }

    return DcSheet(
      title: l.hotelDecisionsAcceptTitle,
      info: view == 'idle' && d != null ? info() : null,
      context: d == null
          ? null
          : RequestContext(
              detail: d,
              end: view == 'already'
                  ? GzStatusPill(status: pillOf(d.booking), audience: GzStatusAudience.hotel)
                  : (view == 'idle' && d.voucher != null ? GzVoucherChip(code: d.voucher!.code) : null),
            ),
      footer: footer,
      children: [
        GzAsyncView<PartnerRequestDetail>(
          value: async,
          loading: const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 240),
          onRetry: () => ref.invalidate(decisionRequestProvider),
          data: body,
        ),
      ],
    );
  }
}

GzStatus pillOf(Booking b) => switch (b.status) {
  BookingStatus.approved => GzStatus.approved,
  BookingStatus.confirmed => GzStatus.confirmed,
  BookingStatus.redeemed => GzStatus.redeemed,
  BookingStatus.completed => GzStatus.completed,
  BookingStatus.declined => GzStatus.declined,
  BookingStatus.cancelled => GzStatus.cancelled,
  BookingStatus.expired => GzStatus.missed,
  _ => GzStatus.pending,
};

/// The count-only comparison of ADR 0008 D5: this request beside the other one, details and no identities.
class _Compare extends ConsumerWidget {
  const _Compare({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final other = ref.watch(competingRequestProvider(booking)).value;
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    Widget col(Booking b, String title) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzText(title, role: GzTextRole.label, color: c.textSecondary),
          const SizedBox(height: GzSpace.s2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzFactChip(
              icon: GzIcons.usersThree,
              label: l.hotelDecisionsFactGuests,
              value: f.integer(b.sections.isEmpty ? 0 : b.sections.first.guests),
            ),
          ),
          const SizedBox(height: GzSpace.s2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: DcPriceFact(fils: b.totals.voucherTotal.fils, label: cl.commonVoucherPrice),
          ),
          const SizedBox(height: GzSpace.s2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzFactChip(icon: GzIcons.clock, tone: GzFactTone.muted, label: l.hotelDecisionsAcceptCompareReceived, value: f.time(b.createdAt)),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: l.hotelDecisionsAcceptCompare,
      child: Container(
        padding: const EdgeInsets.all(GzSpace.s4),
        decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.mdAll),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            col(booking, l.hotelDecisionsAcceptCompareThis),
            if (other != null) ...[const SizedBox(width: GzSpace.s4), col(other, l.hotelDecisionsAcceptCompareOther)],
          ],
        ),
      ),
    );
  }
}
