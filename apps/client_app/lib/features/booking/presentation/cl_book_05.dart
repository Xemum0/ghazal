import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show ClientSession, gzProblemMessage, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode, GzFormat, clockProvider, gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/booking_actions.dart';
import '../application/booking_flow_local.dart';
import '../application/booking_flow_model.dart';
import '../application/booking_flow_providers.dart';
import 'booking_glyphs.dart';
import 'widgets/bar_total.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_layout.dart';
import 'widgets/booking_parts.dart';
import 'widgets/quote_lines.dart';
import 'widgets/review_parts.dart';
import 'widgets/state_note.dart';
import 'widgets/step_scaffold.dart';

/// CL-BOOK-05 Review (step 4 of 4): the voucher-bound request summary, the last screen before the request goes to the venue.
/// Covers CA-BOOK-09, CA-BOOK-10, CA-BOOK-14, CA-BOOK-17, CA-VDET-16, CA-VCH-08, CA-VCH-09.
///
/// Text diet (ADR 0034, hero screen): the request plate, rows with a glyph, one line and a chevron (each opens its step to edit), the
/// itemised price in both columns, the attached voucher, what happens next as four glyph knots, and the consent. One gold action: "Send
/// request" with the voucher total beside it. Nothing more to pay Ghazal; after the venue approves and the client confirms, the client pays
/// the venue directly (ADR 0033).
class ClBook05Screen extends ConsumerStatefulWidget {
  const ClBook05Screen({super.key});

  @override
  ConsumerState<ClBook05Screen> createState() => _ClBook05State();
}

class _ClBook05State extends ConsumerState<ClBook05Screen> {
  bool _sending = false;

  ({bool verified, String name, String phone}) _contact(FlowModel flow) {
    final f = ref.read(gzFormatProvider);
    final draft = ref.read(effectiveBookingDraftProvider);
    final s = ref.read(sessionProvider);
    final user = s is ClientSession ? s.user : null;
    final phone = f.normalizePhone(draft.personal.phone.isNotEmpty ? draft.personal.phone : (user?.phone ?? ''));
    final signed = s is ClientSession && s.phoneVerified ? f.normalizePhone(s.user.phone) : '';
    final v = ref.read(bookingFlowLocalProvider).verifiedPhone;
    return (
      verified: phone.isNotEmpty && (phone == signed || (v != null && phone == f.normalizePhone(v))),
      name: draft.personal.name.isNotEmpty ? draft.personal.name : (user?.name ?? ''),
      phone: phone,
    );
  }

  String? _blocked(AppL10n l10n, FlowModel flow, bool consent, bool verified) {
    final q = flow.quote;
    final v = flow.voucher;
    if (flow.openRequests >= flow.maxOpenRequests) return l10n.clientBookingReasonLimit;
    if (v == null) return l10n.clientBookingReasonVoucher;
    if (q != null && !q.voucherOffered) return l10n.clientBookingVoucherUneconomic;
    if (!verified) return l10n.clientBookingReasonPhone;
    if (!consent) return l10n.clientBookingReasonConsent;
    return null;
  }

  Future<void> _send(FlowModel flow, String? reason, bool consentOnly) async {
    final l10n = context.l10n;
    final nav = context.gzNav;
    if (consentOnly) {
      if (reason != null) nav.toast(GzToastSpec(message: reason));
      return;
    }
    if (reason != null || _sending) return;
    if (!flow.dateOk) {
      nav.openSheet(
        'CL-BOOK-07',
        options: GzSheetOptions(
          params: <String, Object?>{'reason': 'date_taken', 'venueId': flow.venue.id, 'date': flow.date.toString(), 'from': 'CL-BOOK-05'},
        ),
      );
      return;
    }
    final voucher = flow.voucher!;
    final sec = flow.section;
    // What is sent is what the screens showed.
    patchBookingDraft(
      ref,
      (d) => d.copyWith(
        venueId: flow.venue.id,
        hallId: sec.hall.id,
        sessionId: sec.sessionId,
        eventDate: flow.date,
        audience: flow.audience,
        guests: sec.guests,
        packageId: sec.effective?.pkg.id,
        voucherId: voucher.id,
        step: BookingStep.review,
      ),
    );
    setState(() => _sending = true);
    final result = await ref.read(voucherActionsProvider.notifier).sendRequest(voucherId: voucher.id);
    if (!mounted) return;
    setState(() => _sending = false);
    result.when(
      success: (booking) {
        ref.read(bookingFlowLocalProvider.notifier).update((l) => l);
        // The request is sent: the steps behind it are history. The outcome goes on top of Discover, so Back never lands inside a finished request.
        nav.reset('CL-DISC-01');
        nav.push('CL-BOOK-06', params: <String, Object?>{'bookingId': booking.id});
      },
      failure: (p) {
        if (p.code == ApiProblemCode.slotUnavailable) {
          nav.openSheet(
            'CL-BOOK-07',
            options: GzSheetOptions(
              params: <String, Object?>{'reason': 'date_taken', 'venueId': flow.venue.id, 'date': flow.date.toString(), 'from': 'CL-BOOK-05'},
            ),
          );
        } else {
          nav.toast(
            GzToastSpec(
              message: p.code == ApiProblemCode.unknown ? l10n.clientBookingSendFailed : gzProblemMessage(context.gzL10n, p),
              tone: GzToastTone.danger,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final f = ref.watch(gzFormatProvider);
    final async = ref.watch(bookingFlowProvider);
    final local = ref.watch(bookingFlowLocalProvider);
    ref.watch(sessionProvider);
    final flow = keepStale(async).value;
    void retry() => ref.invalidate(bookingFlowProvider);
    final failed = async.hasError && flow == null;

    GzActionBarAction? action;
    Widget? summary;
    Widget? notice;
    if (!failed) {
      if (flow == null) {
        action = GzActionBarAction(label: l10n.clientBookingSend, loading: true, onPressed: retry);
      } else {
        final contact = _contact(flow);
        final consent = flow.demo ? true : local.consent;
        final reason = _blocked(l10n, flow, consent, contact.verified);
        final consentOnly =
            flow.bound &&
            !(flow.quote != null && !flow.quote!.voucherOffered) &&
            contact.verified &&
            !consent &&
            flow.openRequests < flow.maxOpenRequests;
        if (flow.total != null) {
          summary = BookingBarTotal(
            fils: flow.total!,
            icon: flow.hasVoucherPrice ? GzIcons.ticket : GzIcons.coins,
            label: flow.hasVoucherPrice ? l10n.clientBookingVoucherTotalLabel : l10n.commonMoneyTotal,
          );
        }
        action = GzActionBarAction(
          label: l10n.clientBookingSend,
          loading: _sending,
          disabled: !consentOnly && reason != null,
          reason: consentOnly ? null : reason,
          onPressed: () => _send(flow, reason, consentOnly),
        );
        notice = _notice(l10n, nav, f, flow, contact.verified, contact.phone);
      }
    }
    return BookingStepScaffold(
      step: 4,
      venueName: flow == null ? '' : context.bi(flow.venue.name),
      title: l10n.clientBookingReviewTitle,
      notice: notice,
      action: action,
      summary: summary,
      showBar: action != null,
      children: [
        BookingAsync<FlowModel>(
          value: async,
          onRetry: retry,
          loading: const StepSection(
            gap: GzSpace.s5,
            children: [GzSkeleton(blockSize: 88), GzSkeleton(blockSize: 60), GzSkeleton(blockSize: 60), GzSkeleton(blockSize: 160)],
          ),
          data: (flow) => _ReviewBody(flow: flow, contact: _contact(flow), consent: flow.demo ? true : local.consent),
        ),
      ],
    );
  }

  Widget? _notice(AppL10n l10n, GzNavigator nav, GzFormat f, FlowModel flow, bool verified, String phone) {
    final q = flow.quote;
    final v = flow.voucher;
    Widget pad(Widget w) => Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
      child: w,
    );
    if (flow.openRequests >= flow.maxOpenRequests) {
      return pad(
        BookingStateNote(
          icon: GzIcons.clipboard,
          text: l10n.clientBookingLimitBanner(f.integer(flow.openRequests), f.integer(flow.maxOpenRequests)),
          actionLabel: l10n.clientBookingLimitAction,
          onAction: () => nav.push('CL-BKNG-01'),
          infoTitle: l10n.clientBookingLimitInfoTitle,
          infoBody: l10n.clientBookingLimitInfo,
        ),
      );
    }
    if (v == null && q != null) {
      return pad(BookingVoucherNeed(feeFils: flow.voucherFeeFils, onGet: () => getBookingVoucher(nav, flow, 'CL-BOOK-05')));
    }
    if (!verified && v != null) {
      return pad(
        BookingStateNote(
          icon: GzIcons.whatsapp,
          text: l10n.clientBookingPhoneBanner,
          actionLabel: l10n.clientBookingPhoneVerify,
          onAction: () => nav.openSheet(
            'CL-AUTH-02',
            options: GzSheetOptions(
              params: const <String, Object?>{'presentation': 'sheet'},
              onClose: () => ref.read(bookingFlowLocalProvider.notifier).update((l) => l.copyWith(verifiedPhone: f.e164(phone) ?? phone)),
            ),
          ),
        ),
      );
    }
    if (v != null && q != null && !q.voucherOffered) {
      return pad(
        BookingStateNote(
          icon: GzIcons.warningCircle,
          danger: true,
          text: l10n.clientBookingVoucherUneconomic,
          infoTitle: l10n.clientBookingVoucherCardTitle,
          infoBody: l10n.clientBookingVoucherUneconomicInfo,
        ),
      );
    }
    return null;
  }
}

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({required this.flow, required this.contact, required this.consent});

  final FlowModel flow;
  final ({bool verified, String name, String phone}) contact;
  final bool consent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final local = ref.watch(bookingFlowLocalProvider);
    final draft = ref.watch(effectiveBookingDraftProvider);
    final sec = flow.section;
    final quote = flow.quote;
    final voucher = flow.voucher;
    final venueName = context.bi(flow.venue.name);
    final session = sec.session;
    final parts = f.dateWithHijri(flow.date.toString());
    final heroText = ref.watch(bookingHeroRequestTextProvider).value ?? '';
    final requests = (draft.requests.trim().isEmpty && flow.demo ? heroText : draft.requests).trim();
    final now = ref.watch(clockProvider)();
    final replyBy = f.dateTime(now.add(Duration(hours: flow.slaHours)));

    void edit(int step) => voucher != null && step <= 2 ? changeBookingVoucher(nav, flow, 'CL-BOOK-05') : goBookingStep(ref, nav, from: 4, to: step);
    final needAtTop = voucher == null && flow.openRequests < flow.maxOpenRequests && quote != null;

    if (quote == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepSection(
          tight: true,
          children: [
            BookingRequestPlate(
              cover: sec.hall.cover ?? flow.venue.cover,
              hallName: context.bi(sec.hall.name),
              facts: [
                GzFactChip(icon: audienceGlyph(sec.audience), label: hostingLabel(l10n, sec.audience)),
                GzFactChip(icon: GzIcons.usersThree, label: l10n.clientBookingGuestsLabel, value: f.integer(sec.guests)),
                if (session != null) GzFactChip(icon: sessionGlyph(session.start), label: context.bi(session.name)),
              ],
            ),
          ],
        ),
        StepSection(
          gap: GzSpace.s2,
          label: l10n.clientBookingReviewTitle,
          children: [
            GzIconListRow(
              flush: true,
              icon: GzIcons.calendar,
              title: parts.primary,
              facts: context.gz.isAr && parts.secondary != null
                  ? GzText(parts.secondary!, role: GzTextRole.caption, color: c.textSecondary, figures: true)
                  : null,
              chevron: true,
              onPressed: () => edit(1),
            ),
            GzIconListRow(
              flush: true,
              icon: GzIcons.package,
              title: sec.effective == null ? '' : context.bi(sec.effective!.pkg.name),
              autoDir: true,
              chevron: true,
              onPressed: () => edit(2),
            ),
            GzIconListRow(
              flush: true,
              last: requests.isEmpty,
              icon: GzIcons.user,
              title: contact.name,
              autoDir: true,
              // the web sub line is the fact chip plus 3 (caption baseline): 25 in Arabic (the kit's small chip is 19, requests.md; English measured at 22)
              facts: ConstrainedBox(
                constraints: BoxConstraints(minHeight: context.gz.isAr ? 25 : 22),
                child: Wrap(
                  spacing: GzSpace.s2,
                  runSpacing: GzSpace.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (contact.phone.isNotEmpty)
                      GzFactChip(
                        icon: GzIcons.phone,
                        label: l10n.clientBookingPhoneLabel,
                        value: f.phone(contact.phone),
                        small: true,
                        tone: GzFactTone.muted,
                      ),
                    if (local.forOther && local.otherName.isNotEmpty)
                      GzFactChip(
                        icon: GzIcons.userPlus,
                        label: l10n.clientBookingForOther,
                        value: local.otherName,
                        small: true,
                        tone: GzFactTone.muted,
                      ),
                  ],
                ),
              ),
              chevron: true,
              onPressed: () => edit(3),
            ),
            if (requests.isNotEmpty) BookingNoteRow(text: requests, onPressed: () => edit(3)),
          ],
        ),
        StepSection(
          gap: GzSpace.s1,
          label: l10n.clientBookingPriceTitle,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.touchMin),
              child: Row(
                children: [
                  Expanded(
                    child: GzText(l10n.clientBookingPriceTitle, role: GzTextRole.title, color: c.textStrong),
                  ),
                  GzInfoButton(
                    title: l10n.clientBookingPriceTitle,
                    paragraphs: [l10n.clientBookingReviewPriceNote, l10n.clientBookingNextVenueNote(venueName)],
                    bleed: true,
                  ),
                ],
              ),
            ),
            BookingQuoteLines(quote: quote),
          ],
        ),
        if (voucher != null || !needAtTop)
          StepSection(
            tight: true,
            label: l10n.clientBookingVoucherCardTitle,
            children: [
              if (voucher != null)
                BookingVoucherAttach(voucher: voucher, onChange: () => changeBookingVoucher(nav, flow, 'CL-BOOK-05'))
              else
                BookingVoucherNeed(feeFils: flow.voucherFeeFils, onGet: () => getBookingVoucher(nav, flow, 'CL-BOOK-05')),
            ],
          ),
        StepSection(
          gap: GzSpace.s4,
          label: l10n.clientBookingNextTitle,
          children: [BookingNextThread(replyBy: replyBy, confirmHoursLabel: f.digits(l10n.commonCountHours(flow.confirmWindowHours)))],
        ),
        StepSection(
          label: l10n.clientBookingConsentRead,
          children: [
            BookingConsentRow(
              checked: consent,
              onChanged: (v) {
                if (!flow.demo) ref.read(bookingFlowLocalProvider.notifier).update((l) => l.copyWith(consent: v));
              },
              bodies: [l10n.clientBookingConsentBody],
              onRead: () =>
                  nav.openSheet('CL-VENU-05', options: GzSheetOptions(params: <String, Object?>{'venueId': flow.venue.id, 'segment': 'terms'})),
            ),
          ],
        ),
      ],
    );
  }
}
