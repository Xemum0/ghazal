// DateFilter (web `DateFilter.tsx`): the date filter sheet of the Bookings tab (HL-BOOK-02): a Sunday-first range calendar (no native picker)
// that filters the whole tab by event date or by request date. The choice between the two is two glyphs with their words; the range reads as one
// fact under the calendar. The applied range shows as a removable chip under the segments (RangeChip). Every day is selectable here: the venue
// looks back as well as forward.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/bookings_model.dart';
import 'bk_bits.dart';
import 'bk_sheet.dart';

Map<String, GzCalendarDayInfo> _openDays(String today) {
  final start = DateTime.parse(today).subtract(const Duration(days: 400));
  final out = <String, GzCalendarDayInfo>{};
  for (var i = 0; i <= 800; i++) {
    final d = start.add(Duration(days: i));
    out['${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'] = const GzCalendarDayInfo(status: GzDayStatus.available);
  }
  return out;
}

/// `19 Nov` for a single day, `19 Nov - 19 Dec` for a range.
String rangeText(BuildContext context, String start, String? end) {
  final f = context.gzFormat;
  if (end != null && end != start) return context.l10n.hotelBookingsRangeLine(dayMonthShort(f, start), dayMonthShort(f, end));
  return dayMonthShort(f, start);
}

class DateFilterContent extends StatefulWidget {
  const DateFilterContent({required this.field, required this.range, required this.onApply, required this.onClose, super.key});

  final DateField field;
  final FilterRange range;
  final void Function(FilterRange range, DateField field) onApply;
  final VoidCallback onClose;

  @override
  State<DateFilterContent> createState() => _DateFilterContentState();
}

class _DateFilterContentState extends State<DateFilterContent> {
  late DateField _field = widget.field;
  late GzDateRange _range = GzDateRange(start: widget.range.start, end: widget.range.end);
  Map<String, GzCalendarDayInfo>? _days;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
    final days = _days ??= _openDays(f.isoDay(f.now()));
    final ready = _range.start != null;
    return BkSheet(
      title: l.hotelBookingsFilterTitle,
      onClose: widget.onClose,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzButton(
            label: cl.commonActionApply,
            fullWidth: true,
            onPressed: ready ? () => widget.onApply(FilterRange(start: _range.start, end: _range.end ?? _range.start), _field) : null,
          ),
          const SizedBox(height: GzSpace.s3),
          GzButton(label: cl.commonActionClear, variant: GzButtonVariant.tertiary, onPressed: () => widget.onApply(FilterRange.none, _field)),
        ],
      ),
      children: [
        GzIconSegmented<DateField>(
          label: l.hotelBookingsFilterBy,
          labels: GzIconSegmentedLabels.all,
          value: _field,
          onChanged: (v) => setState(() => _field = v),
          options: [
            GzIconSegmentedOption(value: DateField.event, icon: GzIcons.calendarCheck, label: l.hotelBookingsFilterEvent),
            GzIconSegmentedOption(value: DateField.request, icon: GzIcons.send, label: l.hotelBookingsFilterRequest),
          ],
        ),
        GzCalendar.range(value: _range, onChanged: (r) => setState(() => _range = r), days: days, legend: false, isSelectable: (_, _) => true, label: l.hotelBookingsFilterTitle),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _range.start == null
                ? const SizedBox.shrink()
                : GzFactChip(icon: GzIcons.calendar, label: l.hotelBookingsFilterTitle, value: rangeText(context, _range.start!, _range.end)),
          ),
        ),
      ],
    );
  }
}

/// The applied range as a chip with a remove control (44 targets: the label opens the filter, the cross removes it).
class RangeChip extends StatelessWidget {
  const RangeChip({required this.range, required this.field, required this.onRemove, required this.onEdit, super.key});

  final FilterRange range;
  final DateField field;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final start = range.start;
    if (start == null) return const SizedBox.shrink();
    final text = rangeText(context, start, range.end);
    final word = field == DateField.event ? l.hotelBookingsFilterEvent : l.hotelBookingsFilterRequest;
    return Semantics(
      container: true,
      label: l.hotelBookingsRangeApplied,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.controlSm),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: c.controlChipBorderSelected, width: GzStroke.hair),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzPressable(
              onPressed: onEdit,
              semanticLabel: '$word $text',
              borderRadius: GzRadius.smAll,
              minHeight: GzSize.controlSm,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzIcon(field == DateField.event ? GzIcons.calendarCheck : GzIcons.send, size: GzIconSize.sm, tone: GzIconTone.secondary),
                    const SizedBox(width: GzSpace.s2),
                    GzText(text, role: GzTextRole.bodyS, color: c.textStrong, figures: true),
                  ],
                ),
              ),
            ),
            GzPressable(
              onPressed: onRemove,
              semanticLabel: '${context.gzL10n.commonActionRemove}: $text',
              borderRadius: GzRadius.smAll,
              minHeight: GzSize.controlSm,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: GzSize.touchMin, minHeight: GzSize.controlSm),
                child: Center(child: GzIcon(GzIcons.close, size: GzIconSize.sm)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
