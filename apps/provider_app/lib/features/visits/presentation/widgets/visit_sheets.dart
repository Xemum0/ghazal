// The small sheets of the Visits flow, opened from the queue, the detail and the chat (web `visits/_components/Sheets.tsx`): Propose another
// time, Decline (reason chips), the assigned representative, the three chat members and the attach menu. Each is plain content for
// `openSheetBuilder`; none is an inventory screen. Decisions are never queued offline.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, StaffMember, ThreadMember, ThreadRole, VisitAppointment, VisitSlotRule;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/visits_data.dart';
import 'visits_bits.dart';

/// The `HH:mm` slots of one date from the weekly rules (the API answers a taken one with VISIT_SLOT_TAKEN).
List<DateTime> slotsOf(GzFormat f, LocalDate day, List<VisitSlotRule> rules) {
  final out = <DateTime>[];
  for (final r in rules) {
    if (!r.days.contains(day.weekdayIndex)) continue;
    for (var m = r.from.minutesOfDay; m + r.slotMinutes <= r.to.minutesOfDay; m += r.slotMinutes) {
      out.add(f.kuwaitDate(day.year, day.month, day.day, hour: m ~/ 60, minute: m % 60));
    }
  }
  return out;
}

// ---------------------------------------------------------------- propose another time

class ProposeSheet extends ConsumerStatefulWidget {
  const ProposeSheet({required this.visit, required this.onSend, super.key});

  final VisitAppointment visit;
  final Future<void> Function(DateTime slotStart) onSend;

  @override
  ConsumerState<ProposeSheet> createState() => _ProposeSheetState();
}

class _ProposeSheetState extends ConsumerState<ProposeSheet> {
  LocalDate? _day;
  DateTime? _slot;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final now = ref.watch(clockProvider)();
    final today = LocalDate.parse(f.isoDay(now));
    final rules = ref.watch(visitAvailabilityProvider).value?.rules ?? const <VisitSlotRule>[];
    final days = <LocalDate>[
      for (var i = 1; i <= 14; i++)
        if (rules.any((r) => r.days.contains(today.addDays(i).weekdayIndex))) today.addDays(i),
    ].take(8).toList();
    final slots = _day == null ? const <DateTime>[] : slotsOf(f, _day!, rules);
    final need = _slot == null;
    return VisitSheetShell(
      title: l.hotelVisitsProposeTitle,
      footer: GzButton(
        label: l.hotelVisitsProposeCta,
        size: GzButtonSize.cta,
        fullWidth: true,
        spill: true,
        iconStart: GzIcons.calendarCheck,
        loading: _busy,
        reason: need ? l.hotelVisitsProposeNeed : null,
        onPressed: need
            ? null
            : () async {
                setState(() => _busy = true);
                await widget.onSend(_slot!);
                if (mounted) setState(() => _busy = false);
              },
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VisitFieldLabel(l.hotelVisitsProposeDay),
            const SizedBox(height: GzSpace.s2),
            GzChipGroup<String>(
              label: l.hotelVisitsProposeDay,
              value: _day?.toString(),
              onChanged: (v) => setState(() {
                _day = v == null ? null : LocalDate.parse(v);
                _slot = null;
              }),
              options: [for (final d in days) GzChipOption<String>(value: d.toString(), label: f.date(d.toString(), DateStyle.short))],
            ),
          ],
        ),
        if (_day != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VisitFieldLabel(l.hotelVisitsProposeTime),
              const SizedBox(height: GzSpace.s2),
              GzChipGroup<DateTime>(
                label: l.hotelVisitsProposeTime,
                value: _slot,
                onChanged: (v) => setState(() => _slot = v),
                options: [for (final s in slots) GzChipOption<DateTime>(value: s, label: f.time(s))],
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- decline

enum DeclineReason { unavailable, closed, other }

class DeclineSheet extends StatefulWidget {
  const DeclineSheet({required this.onConfirm, required this.onCancel, super.key});

  final Future<void> Function(DeclineReason reason, String note) onConfirm;
  final VoidCallback onCancel;

  @override
  State<DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<DeclineSheet> {
  DeclineReason? _reason;
  String _note = '';
  bool _tried = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final needNote = _reason == DeclineReason.other && _note.trim().isEmpty;
    return VisitSheetShell(
      title: l.hotelVisitsDeclineTitle,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzButton(
            label: l.hotelVisitsDeclineCta,
            variant: GzButtonVariant.destructive,
            size: GzButtonSize.cta,
            fullWidth: true,
            spill: true,
            loading: _busy,
            reason: _reason == null ? l.hotelVisitsDeclineNeed : null,
            onPressed: _reason == null
                ? null
                : () async {
                    if (needNote) {
                      setState(() => _tried = true);
                      return;
                    }
                    setState(() => _busy = true);
                    await widget.onConfirm(_reason!, _note.trim());
                    if (mounted) setState(() => _busy = false);
                  },
          ),
          const SizedBox(height: GzSpace.s3),
          GzButton(
            label: context.gzL10n.commonActionCancel,
            variant: GzButtonVariant.tertiary,
            fullWidth: true,
            spill: true,
            onPressed: widget.onCancel,
          ),
        ],
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VisitFieldLabel(l.hotelVisitsDeclineReason),
            const SizedBox(height: GzSpace.s2),
            GzChipGroup<DeclineReason>(
              label: l.hotelVisitsDeclineReason,
              value: _reason,
              onChanged: (v) => setState(() => _reason = v),
              options: [
                GzChipOption(value: DeclineReason.unavailable, label: l.hotelVisitsReasonUnavailable),
                GzChipOption(value: DeclineReason.closed, label: l.hotelVisitsReasonClosed),
                GzChipOption(value: DeclineReason.other, label: l.hotelVisitsReasonOther),
              ],
            ),
          ],
        ),
        if (_reason != null)
          GzTextArea(
            label: l.hotelVisitsDeclineNote,
            optional: _reason != DeclineReason.other,
            rows: 3,
            value: _note,
            onValueChange: (v) => setState(() => _note = v),
            error: _tried && needNote ? l.hotelVisitsDeclineNoteRequired : null,
          ),
      ],
    );
  }
}

String declineWord(AppL10n l, String reason) => switch (reason) {
  'unavailable' => l.hotelVisitsReasonUnavailable,
  'closed' => l.hotelVisitsReasonClosed,
  _ => l.hotelVisitsReasonOther,
};

// ---------------------------------------------------------------- assigned representative

class RepSheet extends ConsumerWidget {
  const RepSheet({required this.currentId, required this.onPick, super.key});

  final String currentId;
  final void Function(StaffMember staff) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final staff = [
      ...(ref.watch(visitStaffProvider).value ?? const <StaffMember>[]).where((s) => canSeeVisits(s.role) && s.status.value == 'active'),
    ];
    return VisitSheetShell(
      title: l.hotelVisitsRepTitle,
      gap: 0,
      children: [
        Semantics(
          container: true,
          label: l.hotelVisitsRepTitle,
          child: Column(
            children: [
              for (var i = 0; i < staff.length; i++)
                VisitPickRow(
                  last: i == staff.length - 1,
                  selected: staff[i].userId == currentId,
                  leading: GzAvatar(
                    name: lang == 'ar' ? staff[i].name : staff[i].nameLatin,
                    initial: lang == 'ar' ? staff[i].monogram : null,
                    size: GzAvatarSize.sm,
                    voice: GzAvatarVoice.sans,
                  ),
                  title: GzUserText(lang == 'ar' ? staff[i].name : staff[i].nameLatin, role: GzTextRole.title, color: c.textStrong, maxLines: 1),
                  subtitle: staff[i].roleLabel.of(lang),
                  onPressed: () => onPick(staff[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- chat members

class MembersSheet extends StatelessWidget {
  const MembersSheet({required this.members, this.meId, super.key});

  final List<ThreadMember> members;
  final String? meId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    int order(ThreadRole r) => switch (r) {
      ThreadRole.client => 0,
      ThreadRole.hotelRepresentative => 1,
      _ => 2,
    };
    final sorted = [...members]..sort((a, b) => order(a.role).compareTo(order(b.role)));
    return VisitSheetShell(
      title: l.hotelVisitsMembersTitle,
      gap: 0,
      children: [
        Column(
          children: [
            for (var i = 0; i < sorted.length; i++)
              VisitPickRow(
                last: i == sorted.length - 1,
                leading: GzAvatar(
                  name: lang == 'ar' ? sorted[i].name : sorted[i].nameLatin,
                  initial: lang == 'ar' ? sorted[i].monogram : null,
                  size: GzAvatarSize.sm,
                  voice: GzAvatarVoice.sans,
                ),
                title: GzUserText(lang == 'ar' ? sorted[i].name : sorted[i].nameLatin, role: GzTextRole.title, color: c.textStrong, maxLines: 1),
                subtitle: sorted[i].organisation?.of(lang),
                trailing: GzRoleBadge(role: sorted[i].role, you: sorted[i].userId == meId),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- attach

class AttachSheet extends StatelessWidget {
  const AttachSheet({required this.onPick, super.key});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final rows = [
      (GzIcons.camera, l.hotelVisitsAttachCamera),
      (GzIcons.image, l.hotelVisitsAttachPhoto),
      (GzIcons.document, l.hotelVisitsAttachDocument),
    ];
    return VisitSheetShell(
      title: l.hotelVisitsAttachTitle,
      gap: 0,
      children: [
        for (var i = 0; i < rows.length; i++)
          VisitPickRow(
            last: i == rows.length - 1,
            leading: Container(
              width: GzSize.touchMin,
              height: GzSize.touchMin,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceQuiet),
              child: GzIcon(rows[i].$1, size: GzIconSize.md, color: c.iconPrimary),
            ),
            title: GzText(rows[i].$2, role: GzTextRole.body, color: c.textStrong),
            onPressed: onPick,
          ),
      ],
    );
  }
}
