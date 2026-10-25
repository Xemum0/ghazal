// VisitDayRow (web `VisitDayRow.tsx`): one weekday of the visit availability: the day, an open switch and, when open, the two times as 56-high
// buttons that open the time sheet (12-hour clock, never the native picker). The window must end after it starts.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/availability_draft.dart';

class VisitDayRow extends StatelessWidget {
  const VisitDayRow({
    required this.weekday,
    required this.day,
    required this.mistake,
    required this.onToggle,
    required this.onPickFrom,
    required this.onPickTo,
    this.last = false,
    super.key,
  });

  final int weekday;
  final DayWindow day;
  final DayMistake? mistake;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final name = f.weekdayName(weekday);
    String time(int h, int m) => f.time(f.kuwaitDate(2026, 11, 15, hour: h, minute: m));

    Widget button(String what, String text, VoidCallback onTap, {bool invalid = false}) => Expanded(
      child: GzPressable(
        onPressed: onTap,
        semanticLabel: l.hotelVisitsDayPick(what, f.plain(text)),
        borderRadius: GzRadius.smAll,
        scale: 1,
        minHeight: GzSize.controlLg,
        expand: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: GzSize.controlLg),
          padding: const EdgeInsets.symmetric(horizontal: GzSpace.s3, vertical: GzSpace.s2),
          decoration: BoxDecoration(
            color: c.controlBg,
            borderRadius: GzRadius.smAll,
            border: Border.all(color: invalid ? c.borderError : c.borderControl, width: GzStroke.hair),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GzText(what, role: GzTextRole.caption, color: c.textSecondary),
              const SizedBox(height: GzSpace.s1),
              Row(
                children: [
                  GzIcon(GzIcons.clock, size: GzIconSize.xs, color: invalid ? c.iconDanger : c.iconSecondary),
                  const SizedBox(width: GzSpace.s2),
                  Flexible(
                    child: GzText(text, role: GzTextRole.bodyS, color: c.textStrong, figures: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: last ? c.borderHairline.withAlpha(0) : c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.rowMin),
            child: Row(
              children: [
                Expanded(
                  child: GzText(name, role: GzTextRole.title, color: c.textStrong),
                ),
                if (!day.open) ...[
                  GzText(l.hotelVisitsDayNoVisits, role: GzTextRole.caption, color: c.textSecondary),
                  const SizedBox(width: GzSpace.s3),
                ],
                GzSwitch(label: l.hotelVisitsDayOpenLabel(name), checked: day.open, onChanged: onToggle),
              ],
            ),
          ),
          if (day.open) ...[
            const SizedBox(height: GzSpace.s2),
            Row(
              children: [
                button(l.hotelVisitsDayFrom, time(day.from.hour, day.from.minute), onPickFrom),
                const SizedBox(width: GzSpace.s3),
                button(l.hotelVisitsDayTo, time(day.to.hour, day.to.minute), onPickTo, invalid: mistake != null),
              ],
            ),
          ],
          if (day.open && mistake != null) ...[
            const SizedBox(height: GzSpace.s2),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger),
                  const SizedBox(width: GzSpace.s1),
                  GzText(l.hotelVisitsDayErrorOrder, role: GzTextRole.caption, color: c.textDanger),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
