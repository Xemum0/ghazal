// DatePick (web `DatePick.tsx`): a date field of the window editor (Starts, Ends) with a compact value (`15 Nov`, with the year only when it is not the
// current one) beside the calendar glyph, a one-word label above, and the calendar in a sheet. Flow-local twin until the shared date field takes a
// compact format.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'grow_bits.dart';

class DatePick extends StatelessWidget {
  const DatePick({required this.label, required this.value, required this.onChanged, required this.today, this.minDate, this.error, super.key});

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String today;
  final String? minDate;
  final String? error;

  void _open(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => _CalendarSheet(initial: value, minDate: minDate, today: today, label: label, onApply: onChanged),
      options: GzSheetOptions(title: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final text = value == null ? '–' : dmy(f, value!, today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzText(label, role: GzTextRole.label, color: c.textStrong),
        const SizedBox(height: GzSpace.s2),
        GzPressable(
          onPressed: () => _open(context),
          semanticLabel: value == null ? label : '$label: ${f.plain(f.date(value!))}',
          minHeight: GzSize.controlLg,
          child: Container(
            constraints: const BoxConstraints(minHeight: GzSize.controlLg),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
            decoration: BoxDecoration(
              color: c.controlBg,
              borderRadius: GzRadius.mdAll,
              border: Border.all(color: error != null ? c.borderError : c.borderControl, width: GzStroke.hair),
            ),
            child: Row(
              children: [
                GzIcon(GzIcons.calendar, size: GzIconSize.sm, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzText(text, role: GzTextRole.body, color: value == null ? c.textSecondary : c.textStrong, figures: true),
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: GzSpace.s1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
                child: GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger),
              ),
              const SizedBox(width: GzSpace.s1),
              Expanded(
                child: GzText(error!, role: GzTextRole.caption, color: c.textDanger),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({required this.initial, required this.minDate, required this.today, required this.label, required this.onApply});

  final String? initial;
  final String? minDate;
  final String today;
  final String label;
  final ValueChanged<String?> onApply;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late String? _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzCalendar(
          minDate: widget.minDate,
          today: widget.today,
          summary: true,
          legend: false,
          label: widget.label,
          value: _draft,
          onChanged: (v) => setState(() => _draft = v),
        ),
        const SizedBox(height: GzSpace.s3),
        GzButton(
          label: l.commonActionConfirm,
          fullWidth: true,
          reason: null,
          onPressed: _draft == null
              ? null
              : () {
                  widget.onApply(_draft);
                  nav.closeSheet();
                },
        ),
        const SizedBox(height: GzSpace.s2),
        GzButton(
          label: l.commonActionClear,
          variant: GzButtonVariant.tertiary,
          fullWidth: true,
          onPressed: _draft == null ? null : () => setState(() => _draft = null),
        ),
      ],
    );
  }
}
