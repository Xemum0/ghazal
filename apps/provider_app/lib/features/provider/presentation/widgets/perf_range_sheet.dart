// The custom range sheet of Listing performance: past days are selectable (every day with data is available), Apply needs both ends.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/perf_data.dart';

class PerfRangeSheet extends StatefulWidget {
  const PerfRangeSheet({required this.today, this.initial, required this.onApply, super.key});

  final LocalDate today;
  final (LocalDate, LocalDate)? initial;
  final void Function(LocalDate from, LocalDate to) onApply;

  @override
  State<PerfRangeSheet> createState() => _PerfRangeSheetState();
}

class _PerfRangeSheetState extends State<PerfRangeSheet> {
  late GzDateRange _range = widget.initial == null ? const GzDateRange() : GzDateRange(start: widget.initial!.$1.toJson(), end: widget.initial!.$2.toJson());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final ready = _range.start != null && _range.end != null;
    final from = widget.today.addDays(-kDataDays);
    final days = <String, GzCalendarDayInfo>{
      for (var i = 0; i <= kDataDays; i++) from.addDays(i).toJson(): const GzCalendarDayInfo(status: GzDayStatus.available),
    };
    final summary = ready
        ? '${f.date(_range.start!, DateStyle.short)} – ${f.date(_range.end!, DateStyle.compact)}'
        : _range.start != null
            ? f.date(_range.start!, DateStyle.short)
            : l.hotelProviderRangeHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzText(summary, role: GzTextRole.body, color: c.textStrong, figures: true),
        const SizedBox(height: GzSpace.s4),
        GzCalendar.range(
          value: _range,
          days: days,
          minDate: from.toJson(),
          maxDate: widget.today.toJson(),
          today: widget.today.toJson(),
          legend: false,
          label: l.hotelProviderRangeTitle,
          onChanged: (r) => setState(() => _range = r),
        ),
        const SizedBox(height: GzSpace.s4),
        GzSheetFooter(
          child: GzButton(
            label: l.hotelProviderRangeApply,
            fullWidth: true,
            onPressed: ready ? () => widget.onApply(LocalDate.parse(_range.start!), LocalDate.parse(_range.end!)) : null,
          ),
        ),
      ],
    );
  }
}
