import 'dart:async';

import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode, MoneyMode, MoneyOptions, clockProvider, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/booking_flow_local.dart';
import '../application/booking_flow_providers.dart';
import '../application/booking_request.dart';
import 'booking_glyphs.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_info.dart';
import 'widgets/booking_layout.dart';
import 'widgets/booking_parts.dart';
import 'widgets/confirm_clock.dart';
import 'widgets/review_parts.dart';
import 'widgets/sent_parts.dart';
import 'widgets/step_scaffold.dart';

const int _finalMinutes = 60;

/// CL-BOOK-08 Confirm your booking (24 h). Covers CA-STAT-11, CA-STAT-12, CA-STAT-13, CA-VCH-08, CA-BOOK-17.
///
/// The official confirmation the owner requires within 24 hours of the venue's approval, as a clock and a summary of glyphs and figures.
/// The title row says "Confirm" with the Approved status; the clock is a timer glyph and the absolute deadline, a gold bar of the time
/// left and an hourglass figure (mm:ss only in the final 60 minutes). The summary is the date, the hall with its section and guests, the
/// package, the voucher price and the saving after the fee, the attached voucher. The sentences are two info glyphs. One gold action:
/// Confirm booking. params: bookingId (else the client's first approved request).
class ClBook08Screen extends ConsumerStatefulWidget {
  const ClBook08Screen({super.key});

  @override
  ConsumerState<ClBook08Screen> createState() => _ClBook08State();
}

class _ClBook08State extends ConsumerState<ClBook08Screen> {
  Timer? _tick;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    // Seconds tick in the app (once a minute under reduced motion); the shot clock is fixed, so a shot never moves.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tick = Timer.periodic(GzReducedMotion.of(context) ? const Duration(minutes: 1) : const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _toEnded(String id, String reason) => context.gzNav.replace('CL-BOOK-10', params: <String, Object?>{'bookingId': id, 'reason': reason});

  void _updatedSheet(String bookingId) {
    final nav = context.gzNav;
    final l10n = context.l10n;
    nav.openSheetBuilder(
      (sheet) => Column(
        children: [
          const GzIllustration(GzIllustrationName.hourglass, size: GzIllustrationSize.lg),
          const SizedBox(height: GzSpace.s5),
          GzButton(
            label: l10n.clientBookingUpdatedAction,
            fullWidth: true,
            onPressed: () {
              nav.closeSheet();
              _toEnded(bookingId, 'revoked');
            },
          ),
        ],
      ),
      options: GzSheetOptions(title: l10n.clientBookingUpdatedTitle),
    );
  }

  Future<void> _confirm(RequestFacts facts, {required bool lapsed, required bool consent}) async {
    final nav = context.gzNav;
    final l10n = context.l10n;
    final b = facts.booking;
    if (lapsed) return _toEnded(b.id, 'lapsed');
    if (!consent) {
      nav.toast(GzToastSpec(message: l10n.clientBookingConfirmReasonConsent));
      return;
    }
    if (_confirming) return;
    setState(() => _confirming = true);
    final result = await ref.read(voucherActionsProvider.notifier).confirm(b.id, version: b.version);
    if (!mounted) return;
    setState(() => _confirming = false);
    result.when(
      success: (_) => nav.replace('CL-BOOK-09', params: <String, Object?>{'bookingId': b.id}),
      failure: (p) {
        if (p.code == ApiProblemCode.confirmWindowEnded) {
          _toEnded(b.id, 'lapsed');
        } else if (p.code == ApiProblemCode.bookingStateConflict) {
          _updatedSheet(b.id);
        } else {
          nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
        }
      },
      gated: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final async = ref.watch(bookingRequestProvider((id: nav.params['bookingId'] as String?, preferApproved: true)));
    final local = ref.watch(bookingFlowLocalProvider);
    final facts = keepStale(async).value;
    final failed = async.hasError && facts == null;
    final now = ref.watch(clockProvider)();
    final b = facts?.booking;
    final deadline = b?.confirmBy;
    final seconds = deadline == null ? 0 : (deadline.difference(now).inSeconds).clamp(0, 1 << 30);
    final lapsed = b != null && (b.status == BookingStatus.expired || (b.status == BookingStatus.approved && deadline != null && seconds <= 0));
    final isFinal = b != null && b.status == BookingStatus.approved && seconds > 0 && seconds <= _finalMinutes * 60;
    final consent = local.confirmConsent;
    if (b != null && lapsed && b.status == BookingStatus.expired) {
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _toEnded(b.id, 'lapsed') : null);
    }
    return GzScreen(
      top: GzTopBar(
        title: facts == null ? null : context.bi(facts.targetName),
        back: GzTopBarBack.auto,
        rule: false,
        actions: [
          GzTopBarAction(
            icon: GzIcons.chat,
            label: l10n.commonActionMessage,
            onPressed: () => nav.push('CL-MSGS-02', params: <String, Object?>{'venueId': facts?.venueId}),
          ),
          GzTopBarAction(
            icon: GzIcons.document,
            label: l10n.clientBookingConfirmViewRequest,
            onPressed: () => nav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': b?.id}),
          ),
        ],
      ),
      bottom: failed || facts == null
          ? null
          : GzActionBar(
              secondary: lapsed
                  ? null
                  : GzActionBarAction(
                      label: l10n.clientBookingConfirmCancel,
                      onPressed: () => nav.push('CL-BKNG-03', params: <String, Object?>{'bookingId': facts.booking.id}),
                    ),
              action: GzActionBarAction(
                label: lapsed ? l10n.clientBookingEndedNew : l10n.clientBookingConfirmAction,
                loading: _confirming,
                onPressed: () => _confirm(facts, lapsed: lapsed, consent: consent),
              ),
            ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s8),
        child: BookingAsync<RequestFacts>(
          value: async,
          offlineText: l10n.clientBookingConfirmOffline,
          onRetry: () => ref.invalidate(bookingRequestProvider),
          loading: const StepSection(gap: GzSpace.s5, children: [GzSkeleton(blockSize: 96), GzSkeleton(blockSize: 120), GzSkeleton(blockSize: 60)]),
          data: (facts) => _Confirm(facts: facts, lapsed: lapsed, seconds: seconds, isFinal: isFinal, consent: consent),
        ),
      ),
    );
  }
}

class _Confirm extends ConsumerWidget {
  const _Confirm({required this.facts, required this.lapsed, required this.seconds, required this.isFinal, required this.consent});

  final RequestFacts facts;
  final bool lapsed;
  final int seconds;
  final bool isFinal;
  final bool consent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final b = facts.booking;
    final voucher = facts.voucher;
    final section = facts.section;
    final deadline = b.confirmBy;
    const exact = MoneyOptions(mode: MoneyMode.exact);
    final hall = facts.hall;
    final pkg = facts.packageName;
    final chips = <Widget>[
      if (section != null) GzFactChip(icon: audienceGlyph(section.audience), label: hostingLabel(l10n, section.audience)),
      if (facts.guests > 0) GzFactChip(icon: GzIcons.usersThree, label: l10n.clientBookingGuestsLabel, value: f.integer(facts.guests)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingHead(
          title: l10n.clientBookingConfirmHeading,
          info: GzStatusPill(status: lapsed ? GzStatus.expired : GzStatus.approved),
        ),
        if (lapsed)
          if (deadline != null)
            StepSection(
              tight: true,
              label: l10n.clientBookingConfirmWindowLabel,
              children: [
                GzFactRow(
                  children: [
                    GzFactChip(
                      icon: GzIcons.clockOff,
                      label: l10n.clientBookingConfirmLapsedLabel,
                      value: f.dateTime(deadline),
                      tone: GzFactTone.muted,
                    ),
                  ],
                ),
              ],
            )
          else
            const SizedBox.shrink()
        else if (deadline != null)
          StepSection(
            tight: true,
            label: l10n.clientBookingConfirmWindowLabel,
            children: [BookingConfirmClock(deadline: deadline, seconds: seconds, final_: isFinal)],
          ),
        StepSection(
          label: l10n.clientBookingConfirmSummary,
          children: [
            BookingDateLine(date: b.eventDate),
            if (facts.cover != null && hall != null)
              BookingRequestPlate(cover: facts.cover, hallName: context.bi(hall.name), facts: chips)
            else
              GzFactRow(
                children: [
                  if (hall != null) GzFactChip(icon: GzIcons.hall, label: l10n.clientBookingSentHall, value: context.bi(hall.name)),
                  ...chips,
                ],
              ),
            if (pkg != null)
              GzFactRow(
                children: [GzFactChip(icon: GzIcons.package, label: l10n.clientBookingReviewPackage, value: context.bi(pkg))],
              ),
            BookingGap(
              gap: GzSpace.s1,
              children: [
                Row(
                  children: [
                    GzIcon(GzIcons.ticket, size: GzIconSize.md, color: c.iconSuccess, semanticLabel: l10n.clientBookingSentVoucherPrice),
                    const SizedBox(width: GzSpace.s2),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: GzPrice(fils: b.totals.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.total),
                      ),
                    ),
                    BookingInfoButton(title: l10n.clientBookingConfirmPayTitle, paragraphs: [l10n.clientBookingConfirmPay]),
                  ],
                ),
                Semantics(
                  label: '${l10n.clientBookingConfirmSaveNet}: ${f.money(b.totals.netSavings, exact)}',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzIcon(GzIcons.trendDown, size: GzIconSize.sm, color: c.iconSuccess, mirror: false),
                      const SizedBox(width: GzSpace.s2),
                      GzText(f.money(b.totals.netSavings, exact), role: GzTextRole.bodyS, color: c.textSuccess, figures: true),
                    ],
                  ),
                ),
              ],
            ),
            if (voucher != null)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: GzSpace.s3,
                runSpacing: GzSpace.s2,
                children: [
                  GzVoucherChip(code: voucher.code, tone: GzVoucherChipTone.bound),
                  GzFactChip(icon: GzIcons.document, label: l10n.clientBookingSentReference, value: b.ref, small: true, tone: GzFactTone.muted),
                ],
              ),
          ],
        ),
        if (!lapsed)
          StepSection(
            label: l10n.clientBookingConsentRead,
            children: [
              BookingConsentRow(
                checked: consent,
                onChanged: (v) => ref.read(bookingFlowLocalProvider.notifier).update((l) => l.copyWith(confirmConsent: v)),
                bodies: [l10n.clientBookingConfirmConsentBody, l10n.clientBookingConfirmNoteCancel],
                onRead: () =>
                    nav.openSheet('CL-VENU-05', options: GzSheetOptions(params: <String, Object?>{'venueId': facts.venueId, 'segment': 'terms'})),
              ),
            ],
          ),
      ],
    );
  }
}
