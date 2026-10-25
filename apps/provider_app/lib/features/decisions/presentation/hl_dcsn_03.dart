// HL-DCSN-03 Propose another date (sheet; web `HL-DCSN-03.tsx`). Requirement IDs: HA-BOOK-05, HA-BOOK-04, HA-CAL-09, HA-AUTH-02.
// ADR 0008 D7, ADR 0033 D3: one to three other dates for the same hall and session on a PENDING request, sent as ONE card the client answers (48 h)
// through `requestActionsProvider.proposeDates`. The voucher price is always held: a date that normally costs more keeps the quoted voucher
// price and the venue absorbs the difference. A service request has no hall calendar, so a provider is sent to the chat.
// Text diet (ADR 0034): no intro sentence; three pips count the picks, `timer 48 h` is the client's reply window, the picked dates are glyph
// rows; the sentences sit behind the info glyph of the header. Params: `bookingId`, `from: decline` and `reason` (the hand-off from HL-DCSN-02).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/decisions_data.dart';
import 'hl_dcsn_01.dart' show hoursFig;
import 'widgets/dc_blocks.dart';
import 'widgets/dc_sheet.dart';
import 'widgets/multi_date_calendar.dart';
import 'widgets/proposal_list.dart';
import 'widgets/request_context.dart';

class HlDcsn03Screen extends ConsumerStatefulWidget {
  const HlDcsn03Screen({super.key});

  @override
  ConsumerState<HlDcsn03Screen> createState() => _State();
}

class _State extends ConsumerState<HlDcsn03Screen> {
  String? _hallId;
  YearMonth? _month;
  List<String> _picked = <String>[];
  List<String> _taken = <String>[];
  String _note = '';
  bool _loading = false;
  bool _sent = false;
  List<ProposalEntry> _sentEntries = const <ProposalEntry>[];

  YearMonth _monthOf(String iso) => YearMonth(int.parse(iso.substring(0, 4)), int.parse(iso.substring(5, 7)));

  void _toggle(String iso) => setState(() {
    if (_picked.contains(iso)) {
      _picked = _picked.where((d) => d != iso).toList();
    } else if (_picked.length < kMaxProposed) {
      _picked = [..._picked, iso]..sort();
    }
  });

  Future<void> _send(PartnerRequestDetail d, String hallId, List<ProposalEntry> entries) async {
    final b = d.booking;
    final s = b.sections.first;
    setState(() => _loading = true);
    final res = await ref.read(requestActionsProvider.notifier).proposeDates(
      b.id,
      [for (final e in entries) ProposedDateInput(eventDate: LocalDate.parse(e.date), hallId: hallId, sessionId: s.sessionId)],
      version: b.version,
    );
    if (!mounted) return;
    res.when(
      success: (_) => setState(() {
        _loading = false;
        _sent = true;
        _sentEntries = entries;
      }),
      failure: (p) {
        setState(() {
          _loading = false;
          if (p.code == ApiProblemCode.slotUnavailable) _taken = [..._picked];
        });
        if (p.code != ApiProblemCode.slotUnavailable) context.gzNav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));
      },
      gated: () => setState(() => _loading = false),
    );
  }

  void _finish(String? bookingId) {
    final nav = context.gzNav;
    nav.closeSheet();
    nav.toast(GzToastSpec(message: context.l10n.hotelDecisionsToastProposed(hoursFig(context.gzFormat, kProposalHours)), tone: GzToastTone.success, icon: GzIcons.checkCircle));
    if (bookingId != null) nav.push('HL-BOOK-03', params: {'bookingId': bookingId});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
    final nav = context.gzNav;
    final lang = context.gz.locale.languageCode;
    final id = (nav.params['bookingId'] as String?) ?? kStoryBookingId;
    final async = ref.watch(decisionRequestProvider(id));
    final d = async.value;
    final b = d?.booking;
    final section = (b == null || b.sections.isEmpty) ? null : b.sections.first;
    final venueAsync = b?.venueId == null || section == null ? null : ref.watch(decisionVenueProvider(b!.venueId!));
    final venue = venueAsync?.value;
    final halls = (venue == null || b == null) ? const <Hall>[] : suitableHalls(venue, b);
    final hallId = _hallId ?? section?.hallId ?? '';
    final today = f.isoDay(f.now());
    final horizonLast = LocalDate.parse(today).addDays(kProposalHorizonDays).toString();
    final minMonth = _monthOf(today);
    final maxMonth = _monthOf(horizonLast);
    final original = b?.eventDate.toString() ?? '';
    final month = _month ?? (original.isEmpty ? minMonth : _clamp(_monthOf(original), minMonth, maxMonth));

    final freeKey = (b != null && section != null && b.venueId != null)
        ? (venueId: b.venueId!, hallId: hallId, sessionId: section.sessionId, original: original, today: today, guests: section.guests, audience: section.audience)
        : null;
    final freeAsync = freeKey == null ? null : ref.watch(freeDatesProvider(freeKey));
    final free = freeAsync?.value?.byDate ?? const <String, int>{};
    final noHall = d != null && section == null;
    final noDates = freeAsync != null && freeAsync.hasValue && free.isEmpty;

    final quoted = b?.totals.voucherTotal.fils ?? 0;
    final entries = [
      for (final date in [..._picked]..sort())
        () {
          final isTaken = _taken.contains(date);
          final raw = free[date] ?? 0;
          final fils = raw < quoted ? raw : quoted;
          return ProposalEntry(date: date, fils: isTaken ? 0 : fils, delta: isTaken ? 0 : fils - quoted, normally: !isTaken && raw > quoted ? raw - quoted : null, taken: isTaken);
        }(),
    ];
    final calendarFree = {for (final e in free.entries) e.key: e.value < quoted ? e.value : quoted};
    final blocked = _taken.isNotEmpty && _picked.any(_taken.contains);
    final window = hoursFig(f, kProposalHours);
    final replyFact = GzFactChip(icon: GzIcons.timer, tone: GzFactTone.muted, label: l.hotelDecisionsProposeReplyLabel, value: window);

    Widget? footer;
    if (d != null) {
      if (_sent) {
        footer = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GzButton(label: cl.commonActionDone, variant: GzButtonVariant.secondary, size: GzButtonSize.cta, fullWidth: true, onPressed: () => _finish(null)),
            const SizedBox(height: GzSpace.s3),
            Align(alignment: AlignmentDirectional.center, child: GzButton(label: l.hotelDecisionsViewBooking, variant: GzButtonVariant.tertiary, onPressed: () => _finish(id))),
          ],
        );
      } else if (noHall) {
        footer = GzButton(
          label: cl.commonActionMessage,
          fullWidth: true,
          iconStart: GzIcons.chat,
          onPressed: () {
            nav.closeSheet();
            nav.push('HL-TODY-05', params: {'bookingId': id, 'conversationId': d.conversationId});
          },
        );
      } else if (!noDates) {
        footer = GzButton(
          label: l.hotelDecisionsProposeCta,
          fullWidth: true,
          loading: _loading,
          reason: blocked ? l.hotelDecisionsProposeTakenBadge : (_picked.isEmpty ? l.hotelDecisionsProposePick : null),
          onPressed: (_picked.isEmpty || blocked) ? null : () => _send(d, hallId, entries),
        );
      }
    }

    Widget body(PartnerRequestDetail d) {
      if (noHall) return DcState(illustration: GzIllustrationName.chat, title: l.hotelDecisionsProposeNoHallTitle, detail: l.hotelDecisionsProposeNoHallBody);
      if (_sent) {
        final name = dcFirstName(d.booking.clientName);
        final deadline = f.dateTime(f.now().add(const Duration(hours: kProposalHours)));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            DcState(
              success: true,
              illustration: GzIllustrationName.successRequest,
              title: l.hotelDecisionsProposeSentTitle,
              detail: '${dcPlain(l.hotelDecisionsProposeAwaiting(name, deadline))}\n\n${l.hotelDecisionsProposeSentBody(cl.commonCountHours(kConfirmHours))}',
              facts: GzFactRow(label: l.hotelDecisionsProposeReplyLabel, children: [replyFact]),
            ),
            const SizedBox(height: GzSpace.s4),
            ProposalList(entries: _sentEntries, onRemove: (_) {}, readOnly: true),
          ],
        );
      }
      final hallName = halls.where((h) => h.id == hallId).map((h) => h.name.of(lang)).firstOrNull ?? d.halls.where((h) => h.id == hallId).map((h) => h.name.of(lang)).firstOrNull ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!noDates) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.touchMin),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [DcPickPips(count: _picked.length, max: kMaxProposed, label: l.hotelDecisionsProposeCount(_picked.length)), replyFact],
              ),
            ),
            const SizedBox(height: GzSpace.s4),
          ],
          if (halls.length > 1) ...[
            GzSegmentedControl<String>(
              label: l.hotelDecisionsProposeHallLabel,
              value: hallId,
              onChanged: (v) => setState(() {
                _hallId = v;
                _picked = <String>[];
                _taken = <String>[];
              }),
              options: [for (final h in halls) GzSegmentedOption<String>(value: h.id, label: h.name.of(lang))],
            ),
            const SizedBox(height: GzSpace.s4),
          ],
          if (freeAsync != null && freeAsync.isLoading && !freeAsync.hasValue)
            const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 320)
          else if (noDates)
            GzEmptyState(
              illustration: GzIllustrationName.calendar,
              title: l.hotelDecisionsProposeEmptyTitle,
              detail: l.hotelDecisionsProposeEmpty(cl.commonCountDays(kProposalHorizonDays)),
              detailTitle: cl.commonLabelDetails,
              fill: false,
              size: GzIllustrationSize.lg,
              action: GzStateAction(
                label: l.hotelDecisionsProposeEmptyAction,
                onPressed: () {
                  nav.closeSheet();
                  nav.switchTab('calendar');
                },
              ),
            )
          else
            MultiDateCalendar(
              month: month,
              onMonthChange: (m) => setState(() => _month = m),
              free: calendarFree,
              picked: _picked.where((x) => !_taken.contains(x)).toList(),
              max: kMaxProposed,
              onToggle: _toggle,
              original: original,
              taken: _taken,
              minMonth: minMonth,
              maxMonth: maxMonth,
              today: today,
              label: l.hotelDecisionsProposeCalendarLabel(f.plain(hallName)),
            ),
          if (!noDates && _picked.isNotEmpty) ...[
            const SizedBox(height: GzSpace.s4),
            ProposalList(
              entries: entries,
              onRemove: (date) => setState(() {
                _picked = _picked.where((x) => x != date).toList();
                _taken = _taken.where((x) => x != date).toList();
              }),
            ),
          ],
          if (!noDates) ...[
            const SizedBox(height: GzSpace.s4),
            GzTextField(label: l.hotelDecisionsNote, value: _note, maxLength: 80, onValueChange: (v) => setState(() => _note = v)),
          ],
        ],
      );
    }

    return DcSheet(
      title: l.hotelDecisionsProposeTitle,
      info: (d == null || noHall || _sent || noDates)
          ? null
          : GzInfoButton(
              title: l.hotelDecisionsTermsTitle,
              paragraphs: [
                l.hotelDecisionsProposeIntro(cl.commonCountHours(kProposalHours)),
                l.hotelDecisionsProposeHold(f.money(quoted, const MoneyOptions(mode: MoneyMode.exact))),
              ],
            ),
      context: d == null ? null : RequestContext(detail: d, end: DcPriceFact(fils: quoted, label: cl.commonVoucherPrice)),
      footer: footer,
      children: [
        GzAsyncView<PartnerRequestDetail>(
          value: async,
          loading: const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 360),
          onRetry: () => ref.invalidate(decisionRequestProvider),
          data: body,
        ),
      ],
    );
  }

  YearMonth _clamp(YearMonth m, YearMonth lo, YearMonth hi) => m.index < lo.index ? lo : (m.index > hi.index ? hi : m);
}
