import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show NameStyle;

import '../core/core.dart';
import '../foundation.dart';
import 'hotel_bits.dart';
import 'hotel_c_kit.dart';

/// BusinessHoursRow: one weekday of the venue's office hours (HL-SETT-05, HA-SET-04): the day, an open switch and, when open, the
/// two times as 56 high buttons that open the custom time sheet (the screen shows it from [onPickFrom] / [onPickTo]). A closing time
/// before the opening time runs past midnight and says so ("next day"), it is not an error; the same time on both ends is.
/// "Copy to all days" sits under the row the person is editing. Times are Kuwait time, no device conversion.
class GzBusinessHoursRow extends StatelessWidget {
  const GzBusinessHoursRow({
    required this.weekday,
    required this.open,
    required this.from,
    required this.to,
    this.onOpenChange,
    this.onPickFrom,
    this.onPickTo,
    this.onCopy,
    this.invalid = false,
    this.anchor = '2026-11-15',
    this.last = false,
    super.key,
  }) : assert(weekday >= 0 && weekday <= 6);

  /// 0 = Sunday ... 6 = Saturday.
  final int weekday;
  final bool open;

  /// Venue-local `HH:MM`.
  final String from;
  final String to;
  final ValueChanged<bool>? onOpenChange;
  final VoidCallback? onPickFrom;
  final VoidCallback? onPickTo;

  /// Show "Copy to all days" under the row.
  final VoidCallback? onCopy;

  /// Same opening and closing time.
  final bool invalid;

  /// Any date, only to anchor the clock formatting.
  final String anchor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final day = f.weekdayName(weekday, NameStyle.long);
    String time(String hhmm) => f.time(gzClockInstant(f, anchor, hhmm));
    final nextDay = open && to.compareTo(from) < 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
      decoration: gzRuleBelow(c, last: last),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.rowMin),
            child: Row(
              children: [
                Expanded(
                  child: GzText(day, role: GzTextRole.title, color: c.textStrong),
                ),
                if (!open) ...[
                  GzText(l.uiHotelHoursClosed, role: GzTextRole.caption, color: c.textSecondary),
                  const SizedBox(width: GzSpace.s3),
                ],
                GzSwitch(checked: open, onChanged: onOpenChange, label: l.uiHotelHoursOpen(day)),
              ],
            ),
          ),
          if (open) ...[
            const SizedBox(height: GzSpace.s2),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TimeButton(what: l.uiHotelHoursFrom, time: time(from), plain: f.plain(time(from)), onPressed: onPickFrom),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: _TimeButton(
                      what: l.uiHotelHoursTo,
                      time: time(to),
                      plain: f.plain(time(to)),
                      invalid: invalid,
                      nextDay: nextDay ? l.uiHotelHoursNextDay : null,
                      onPressed: onPickTo,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (open && invalid) ...[
            const SizedBox(height: GzSpace.s2),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger),
                  const SizedBox(width: GzSpace.s1),
                  Expanded(
                    child: GzText(l.uiHotelHoursInvalid, role: GzTextRole.caption, color: c.textDanger),
                  ),
                ],
              ),
            ),
          ],
          if (open && onCopy != null) ...[
            const SizedBox(height: GzSpace.s2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzButton(label: l.uiHotelHoursCopy, variant: GzButtonVariant.tertiary, iconStart: GzIcons.copy, onPressed: onCopy),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.what,
    required this.time,
    required this.plain,
    required this.onPressed,
    this.invalid = false,
    this.nextDay,
  });

  final String what;
  final String time;
  final String plain;
  final bool invalid;
  final String? nextDay;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    return GzPressable(
      onPressed: onPressed ?? () {},
      semanticLabel: l.uiHotelHoursPick(what, plain),
      borderRadius: GzRadius.smAll,
      minHeight: GzSize.controlLg,
      builder: (context, st) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: GzSize.controlLg),
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s2, horizontal: GzSpace.s3),
        decoration: BoxDecoration(
          color: st.pressed ? c.surfaceQuiet : c.controlBg,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: invalid ? c.borderError : c.borderControl, width: GzStroke.hair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GzText(what, role: GzTextRole.caption, color: c.textSecondary),
            const SizedBox(height: GzSpace.s1),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s2,
              runSpacing: GzSpace.s1,
              children: [
                GzIcon(GzIcons.clock, size: GzIconSize.xs, color: invalid ? c.iconDanger : c.iconSecondary),
                GzText(time, figures: true, role: GzTextRole.bodyS, color: c.textStrong),
                if (nextDay != null) GzText(nextDay!, role: GzTextRole.caption, color: c.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
