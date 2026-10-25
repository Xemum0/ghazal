// HL-CALN-04 Block or open dates, sheet (web `HL-CALN-04.tsx`): take dates off sale (offline sales, maintenance, private events) or put them back on
// sale, for one date or a range, scoped by hall. A confirmed booking cannot be blocked: the sheet names the booking and links to its cancel flow.
// Pending requests are counted before anything changes (a request never claims the date). Text diet: the head is the Block | Open switch (a lock and
// a door), the dates are one line and a chevron, the hall and the reason are chips named by a glyph, the warnings are a bead or a pill and a figure;
// every sentence sits behind an (i). A block resolves to the toast "Hidden from couples" with Undo (8 s) and the calendar updates in place.
// Requirements: HA-CAL-04, HA-CAL-05, HA-CAL-08, HA-CAL-09, HA-AUTH-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage, partnerCalendarRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show BlockBatch, BlockReason, CalendarClaim, Hall, Occasion;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/calendar_data.dart';
import 'widgets/block_result.dart';
import 'widgets/calendar_agenda.dart';
import 'widgets/calendar_chrome.dart';
import 'widgets/sheet_bits.dart';

enum _Phase { idle, loading, success }

final RegExp _approx = RegExp(r'\s*[(（](approx\.|تقريبي)[)）]');

class HlCaln04Screen extends ConsumerStatefulWidget {
  const HlCaln04Screen({super.key});

  @override
  ConsumerState<HlCaln04Screen> createState() => _HlCaln04ScreenState();
}

class _HlCaln04ScreenState extends ConsumerState<HlCaln04Screen> {
  bool _init = false;
  bool _open = false;
  GzDateRange _range = GzDateRange.empty;
  String _scope = kAllHalls;
  BlockReason _reason = BlockReason.offlineBooking;
  String _note = '';
  bool _expanded = false;
  late GzYm _ym;
  String? _shortcut;
  String? _session;
  _Phase _phase = _Phase.idle;
  String? _error;
  List<String> _unchecked = const [];

  void _seed(GzNavigator nav, String today) {
    if (_init) return;
    _init = true;
    final p = nav.params;
    _open = p['mode'] == 'open';
    // Opened without params (the harness, a demo tool): the hero story, Thu 24 - Sat 26 Dec 2026. From a calendar view the key is always there.
    final demo = !p.containsKey('start');
    final s = demo ? '2026-12-24' : p['start'] as String?;
    final e = demo ? '2026-12-26' : ((p['end'] as String?) ?? s);
    _range = GzDateRange(start: s, end: e);
    final halls = p['hallIds'];
    if (halls is List && halls.length == 1) _scope = halls.first as String;
    _expanded = s == null && !_open;
    _ym = ymOf(s ?? today);
  }

  Future<ApiProblem?> _write(Future<void> Function() job) async {
    try {
      await job();
      return null;
    } on ApiProblem catch (p) {
      return p;
    }
  }

  Future<void> _submit({required List<Hall> halls, required BlockAnalysis a, required List<CalendarClaim> blocked, required List<String> chosen}) async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final gzL = context.gzL10n;
    final repo = ref.read(partnerCalendarRepositoryProvider);
    final batches = ref.read(blockBatchesProvider.notifier);
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    final made = <BlockBatch>[];
    final undoOpen = <({String hallId, String date, BlockReason? reason})>[];
    ApiProblem? problem;
    if (!_open) {
      final byHall = <String, List<String>>{};
      for (final x in a.free) {
        byHall.putIfAbsent(x.hallId, () => []).add(x.date);
      }
      for (final e in byHall.entries) {
        problem = await _write(() async {
          final h = halls.firstWhere((x) => x.id == e.key);
          final sid = _scope != kAllHalls && h.sessions.length > 1 ? (_session ?? h.sessions.first.id) : null;
          made.add(await repo.createCalendarBlocks(body: blockInput([e.key], e.value, _reason, _reason == BlockReason.other ? _note : '', sessionIds: sid == null ? null : [sid])));
        });
        if (problem != null) break;
      }
    } else {
      final ids = <String>{};
      for (final cl in blocked) {
        if (!chosen.contains(cl.date.toString())) continue;
        undoOpen.add((hallId: cl.hallId, date: cl.date.toString(), reason: cl.blockReason));
        ids.add(ref.read(blockBatchesProvider)[cl.id] ?? cl.id);
      }
      for (final id in ids) {
        problem = await _write(() => repo.removeCalendarBlockBatch(batchId: id));
        if (problem != null) break;
      }
    }
    if (!mounted) return;
    ref.read(partnerDataRevisionProvider.notifier).bump();
    if (problem != null) {
      setState(() {
        _phase = _Phase.idle;
        _error = gzProblemMessage(gzL, problem!);
      });
      return;
    }
    for (final b in made) {
      batches.add(b);
    }
    final block = !_open;
    nav.closeSheet();
    nav.toast(
      GzToastSpec(
        message: block ? l.hotelCalendarToastBlocked : l.hotelCalendarToastOpened,
        tone: GzToastTone.success,
        icon: GzIcons.checkCircle,
        undo: true,
        action: GzToastAction(
          label: gzL.commonActionUndo,
          onPressed: () async {
            if (block) {
              for (final b in made) {
                await _write(() => repo.removeCalendarBlockBatch(batchId: b.id));
                batches.remove(b.id);
              }
            } else {
              for (final u in undoOpen) {
                await _write(() async => made.add(await repo.createCalendarBlocks(body: blockInput([u.hallId], [u.date], u.reason ?? BlockReason.offlineBooking, ''))));
              }
            }
            ref.read(partnerDataRevisionProvider.notifier).bump();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    final today = ref.watch(calendarTodayProvider);
    _seed(nav, today);
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final role = ref.watch(calendarRoleProvider);
    final hallsValue = ref.watch(calendarHallsProvider);
    final windows = sheetWindows(_ym, _range.start, _range.end, today);
    final values = [for (final w in windows) ref.watch(calendarClaimsProvider(w))];
    final occasions = ref.watch(calendarOccasionsProvider).value ?? const <Occasion>[];
    final halls = hallsValue.value ?? const <Hall>[];
    final ready = hallsValue.hasValue && values.every((v) => v.hasValue);
    final claims = [for (final v in values) ...?v.value];
    final short = shortHall(halls, lang);
    final scopeIds = _scope == kAllHalls ? [for (final h in halls) h.id] : [_scope];
    final dates = datesOfSpan(_range.start, _range.end);
    final a = analyse(dates, scopeIds, claims, today);
    final freeDates = {for (final x in a.free) x.date}.toList()..sort();
    final blocked = blockedIn(claims, scopeIds, dates, today);
    final blockedDates = {for (final x in blocked) x.date.toString()}.toList()..sort();
    final chosen = [for (final d in blockedDates) if (!_unchecked.contains(d)) d];
    final conflict = !_open && a.taken.isNotEmpty;
    final pendingTotal = a.pending.fold<int>(0, (n, x) => n + x.count);
    final count = _open ? chosen.length : freeDates.length;
    final mayBlock = canBlock(role);

    String? why;
    if (!_open && dates.isEmpty) {
      why = l.hotelCalendarReasonChoose;
    } else if (conflict) {
      why = l.hotelCalendarReasonConflict;
    } else if (!_open && freeDates.isEmpty) {
      why = l.hotelCalendarAlreadyBlocked;
    } else if (_open && chosen.isEmpty) {
      why = l.hotelCalendarOpenEmpty;
    } else if (!mayBlock) {
      why = l.hotelCalendarReadOnly;
    } else if (!_open && _reason == BlockReason.other && _note.trim().isEmpty) {
      why = l.hotelCalendarNote;
    }
    final done = _phase == _Phase.success;
    final summary = _range.start != null ? spanText(f, _range.start, _range.end) : (_open ? l.hotelCalendarOpenListTitle : l.hotelCalendarRangeNone);

    Widget dateChip(String iso) => GzFactChip(icon: GzIcons.calendar, label: l.hotelCalendarRangeSummary, value: dayMonthOf(f, iso));

    final head = GzSheetPinnedHeader(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.controlMd),
          child: Row(
            children: [
              Expanded(
                child: done
                    ? GzText(_open ? l.hotelCalendarSheetOpenTitle : l.hotelCalendarSheetBlockTitle, role: GzTextRole.uiTitle, color: c.textStrong, header: true)
                    : Align(alignment: AlignmentDirectional.centerStart, child: SizedBox(width: GzSpace.s12 * 5, child: GzIconSegmented<bool>(
                        label: l.hotelCalendarModeLabel,
                        value: _open,
                        labels: GzIconSegmentedLabels.all,
                        onChanged: (m) => setState(() {
                          _open = m;
                          _unchecked = const [];
                        }),
                        options: [GzIconSegmentedOption(value: false, icon: GzIcons.lock, label: l.hotelCalendarModeBlock), GzIconSegmentedOption(value: true, icon: GzIcons.door, label: l.hotelCalendarModeOpen)],
                      ))),
              ),
              if (!done)
                GzInfoButton(title: context.gzL10n.commonLabelDetails, paragraphs: [_open ? l.hotelCalendarOpenHint : l.hotelCalendarVisibilityHint, if (_expanded) l.hotelCalendarHintDrag, if (_expanded) l.hotelCalendarHintTap]),
              GzBarButton(key: const ValueKey('gz:sheet.close'), icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: nav.closeSheet),
            ],
          ),
        ),
      ),
    );

    // The web foot is a 1 px rule plus 12 of padding before the button; the kit slot leaves 12 from the rule: 1 dp more here.
    final footer = GzSheetFooter(
      child: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: done
          ? GzButton(label: context.gzL10n.commonActionDone, variant: GzButtonVariant.secondary, size: GzButtonSize.cta, fullWidth: true, onPressed: nav.closeSheet)
          : GzButton(
              label: _open ? l.hotelCalendarCtaOpen(count) : l.hotelCalendarCtaBlock(conflict ? 0 : count),
              fullWidth: true,
              loading: _phase == _Phase.loading,
              reason: why,
              onPressed: why != null || _phase != _Phase.idle ? null : () => _submit(halls: halls, a: a, blocked: blocked, chosen: chosen),
            ),
      ),
    );

    final body = <Widget>[];
    if (_error != null) body.add(CalNotice(tone: NoticeTone.danger, actionLabel: context.gzL10n.commonActionRetry, onAction: () => setState(() => _error = null), children: [GzText(_error!, role: GzTextRole.bodyS, color: c.statusDangerText)]));
    if (_phase == _Phase.success) {
      body.add(BlockSuccess(block: !_open, dates: chosen, summary: spanText(f, _range.start, _range.end)));
    } else {
      body.add(
        GzPressable(
          onPressed: () => setState(() => _expanded = !_expanded),
          semanticLabel: '$summary, ${l.hotelCalendarSumEdit}',
          borderRadius: GzRadius.mdAll,
          scale: 1,
          minHeight: GzSize.controlLg,
          expand: true,
          builder: (context, st) => Container(
            constraints: const BoxConstraints(minHeight: GzSize.controlLg),
            padding: const EdgeInsets.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s2),
            decoration: BoxDecoration(color: c.surfaceRaised, border: Border.all(color: c.borderStrong, width: GzStroke.hair), borderRadius: GzRadius.mdAll),
            child: Row(
              children: [
                GzIcon(GzIcons.calendar, size: GzIconSize.md, color: c.iconPrimary),
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzText(summary, role: GzTextRole.title, color: c.textStrong, figures: true)),
                if (_open && _range.start == null) ...[GzText(f.integer(blockedDates.length), role: GzTextRole.figBodyS, color: c.textGoldInk, figures: true), const SizedBox(width: GzSpace.s3)],
                GzIcon(_expanded ? GzIcons.chevronUp : GzIcons.chevronDown, size: GzIconSize.sm, color: c.iconSecondary),
              ],
            ),
          ),
        ),
      );
      if (!_open && a.pending.isNotEmpty) {
        body.add(
          CalNotice(
            tone: NoticeTone.warning,
            lead: const GzThreadBead(),
            head: Row(children: [GzText(l.hotelCalendarRequestedLabel, role: GzTextRole.bodyS, color: c.textStrong), const SizedBox(width: GzSpace.s2), GzText(f.integer(pendingTotal), role: GzTextRole.figBodyS, color: c.textStrong, figures: true)]),
            info: GzInfoButton(title: l.hotelCalendarRequestedLabel, paragraphs: [for (final x in a.pending) l.hotelCalendarPendingWarn(x.count, f.date(x.date, DateStyle.short))]),
            children: [GzFactRow(children: [for (final x in a.pending.take(3)) dateChip(x.date)])],
          ),
        );
      }
      if (conflict) {
        final bookingId = a.taken.where((x) => x.bookingId != null).firstOrNull?.bookingId;
        body.add(
          CalNotice(
            tone: NoticeTone.danger,
            head: const Align(alignment: AlignmentDirectional.centerStart, child: GzStatusPill(status: GzStatus.booked)),
            info: GzInfoButton(title: l.hotelCalendarWhyTitle, paragraphs: [l.hotelCalendarConflictBody, if (_scope == kAllHalls && halls.length > 1) l.hotelCalendarConflictTip]),
            actionLabel: l.hotelCalendarConflictCancel,
            onAction: () {
              if (bookingId != null) nav.openSheet('HL-DCSN-04', options: GzSheetOptions(params: <String, Object?>{'bookingId': bookingId}));
            },
            children: [
              for (final x in a.taken.take(3))
                GzFactRow(children: [dateChip(x.date.toString()), GzFactChip(icon: GzIcons.hall, label: l.hotelCalendarHallFact, value: short(x.hallId)), if (x.clientName != null) GzUserText(x.clientName!, role: GzTextRole.caption, color: c.statusDangerText, maxLines: 1)]),
            ],
          ),
        );
      }
      if (_expanded) {
        body.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzHotelMonthGrid(
                halls: halls,
                claims: claims,
                month: _ym,
                onMonthChange: (y) => setState(() => _ym = y),
                mode: GzHotelMonthMode.select,
                range: _range,
                onRangeChange: (r) => setState(() {
                  _range = r;
                  _shortcut = null;
                }),
                legend: false,
                label: l.hotelCalendarRangeSummary,
              ),
              if (occasions.isNotEmpty) ...[
                const SizedBox(height: GzSpace.s4),
                CalChipRow(
                  icon: GzIcons.sparkle,
                  child: GzChipGroup<String>(
                    label: l.hotelCalendarShortcuts,
                    value: _shortcut,
                    deselectable: true,
                    onChanged: (id) => setState(() {
                      _shortcut = id;
                      final o = occasions.where((x) => x.id == id).firstOrNull;
                      if (o != null) {
                        _range = GzDateRange(start: o.from.toString(), end: o.to.toString());
                        _ym = ymOf(o.from.toString());
                      }
                    }),
                    options: [for (final o in occasions) GzChipOption<String>(value: o.id, label: '${o.approximate ? '≈ ' : ''}${o.name.of(lang).replaceAll(_approx, '')}')],
                  ),
                ),
              ],
            ],
          ),
        );
      }
      if (halls.length > 1) {
        body.add(
          CalChipRow(
            icon: GzIcons.hall,
            child: GzChipGroup<String>(
              label: l.hotelCalendarHallsLabel,
              value: _scope,
              onChanged: (v) {
                if (v != null) setState(() => _scope = v);
              },
              options: [GzChipOption<String>(value: kAllHalls, label: l.hotelCalendarHallsAll), for (final h in halls) GzChipOption<String>(value: h.id, label: short(h.id))],
            ),
          ),
        );
      }
      final sel = halls.where((h) => h.id == _scope).firstOrNull;
      if (sel != null && sel.sessions.length > 1) {
        body.add(
          CalChipRow(
            icon: GzIcons.sun,
            child: GzChipGroup<String>(
              label: l.hotelCalendarSession,
              value: _session ?? sel.sessions.first.id,
              onChanged: (v) => setState(() => _session = v),
              options: [for (final s in sel.sessions) GzChipOption<String>(value: s.id, label: s.name.of(lang))],
            ),
          ),
        );
      }
      if (!_open) {
        body.add(
          CalChipRow(
            icon: GzIcons.notes,
            child: GzChipGroup<BlockReason>(
              label: l.hotelCalendarReason,
              value: _reason,
              onChanged: (v) {
                if (v != null) setState(() => _reason = v);
              },
              options: [
                for (final r in const [BlockReason.offlineBooking, BlockReason.maintenance, BlockReason.privateEvent, BlockReason.other]) GzChipOption<BlockReason>(value: r, label: reasonWord(l, r)),
              ],
            ),
          ),
        );
        if (_reason == BlockReason.other) body.add(GzTextField(label: l.hotelCalendarNote, value: _note, onValueChange: (v) => setState(() => _note = v), maxLength: 80));
      } else if (blockedDates.isEmpty) {
        body.add(CalOutcome(art: GzIllustrationName.partnerCalendar, title: l.hotelCalendarOpenEmpty));
      } else {
        body.add(
          Semantics(
            container: true,
            label: l.hotelCalendarOpenListTitle,
            child: Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
              child: Column(
                children: [
                  for (var i = 0; i < blockedDates.length; i++)
                    Container(
                      decoration: BoxDecoration(border: i == blockedDates.length - 1 ? null : Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                      child: _OpenItem(
                        date: blockedDates[i],
                        rows: [for (final x in blocked) if (x.date.toString() == blockedDates[i]) x],
                        hallCount: halls.length,
                        short: short,
                        checked: !_unchecked.contains(blockedDates[i]),
                        onChanged: (on) => setState(() => _unchecked = on ? [for (final x in _unchecked) if (x != blockedDates[i]) x] : [..._unchecked, blockedDates[i]]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        GzAsyncView<List<Hall>>(
          value: ready ? AsyncValue.data(halls) : (hallsValue.hasError ? AsyncValue.error(hallsValue.error!, hallsValue.stackTrace ?? StackTrace.empty) : const AsyncValue.loading()),
          loading: const Padding(padding: EdgeInsets.only(bottom: GzSpace.s6), child: GzSkeleton(blockSize: 160)),
          onRetry: () => ref.invalidate(calendarHallsProvider),
          data: (_) => Padding(
            padding: const EdgeInsets.only(top: GzSpace.s3),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var i = 0; i < body.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s4), body[i]]]),
          ),
        ),
        footer,
      ],
    );
  }
}

class _OpenItem extends StatelessWidget {
  const _OpenItem({required this.date, required this.rows, required this.hallCount, required this.short, required this.checked, required this.onChanged});

  final String date;
  final List<CalendarClaim> rows;
  final int hallCount;
  final String Function(String) short;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    return GzCheckbox(
      label: f.date(date, DateStyle.short),
      checked: checked,
      onChanged: onChanged,
      labelWidget: Padding(
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzText(f.date(date, DateStyle.short), role: GzTextRole.title, color: c.textStrong, figures: true),
            const SizedBox(height: GzSpace.s1),
            GzFactRow(
              children: [
                GzFactChip(small: true, icon: GzIcons.lock, label: l.hotelCalendarReason, value: reasonWord(l, rows.first.blockReason)),
                if (rows.length < hallCount) GzFactChip(small: true, icon: GzIcons.hall, label: l.hotelCalendarHallFact, value: rows.map((x) => short(x.hallId)).join(' · ')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
