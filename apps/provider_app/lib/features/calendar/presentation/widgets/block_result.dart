// The finished state of the block sheet (web `HL-CALN-04.tsx`, `result`): a drawing, the words of the toast, the dates. A booked date can never be
// blocked here (the primary rests until the booking is cancelled), so the web's partial-fail frame has no live path.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'sheet_bits.dart';

class BlockSuccess extends StatelessWidget {
  const BlockSuccess({required this.block, required this.dates, required this.summary, super.key});

  final bool block;
  final List<String> dates;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    return CalOutcome(
      art: block ? GzIllustrationName.partnerCalendar : GzIllustrationName.doorway,
      title: block ? l.hotelCalendarToastBlocked : l.hotelCalendarToastOpened,
      children: [
        GzFactRow(
          label: l.hotelCalendarRangeSummary,
          children: [GzFactChip(icon: GzIcons.calendar, label: l.hotelCalendarRangeSummary, value: block ? summary : f.list([for (final d in dates) f.date(d, DateStyle.short)]))],
        ),
      ],
    );
  }
}
