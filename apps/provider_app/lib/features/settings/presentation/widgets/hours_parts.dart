// The pieces of Business hours (web `HoursParts.tsx`; text diet, ADR 0034): the day row (a short day name, the opening and closing time as two
// buttons with an arrow between them, the open switch), the custom time sheet (12-hour clock, Western digits, never the native picker), the
// add-closure sheet and the "Shown to couples as" lines. A time is its figure plus a glyph for the part of the day instead of the AM or PM
// word; the full reading ("9:00 AM") is the accessible name. Times are Kuwait time and never converted to the device's time zone.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat, NameStyle;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/settings_model.dart';

/// A clock reading as figure + part-of-day glyph (and "+1" when it is the next day).
class TimeFigure extends StatelessWidget {
  const TimeFigure({required this.hhmm, this.next = false, super.key});

  final String hhmm;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GzText(figureOf(f, hhmm), role: GzTextRole.figBodyS, color: c.textStrong, figures: true),
        const SizedBox(width: GzSpace.s1),
        GzIcon(dayPartOf(hhmm), size: GzIconSize.xs, color: c.iconSecondary),
        if (next) ...[const SizedBox(width: GzSpace.s1), GzText('+1', role: GzTextRole.figCaption, color: c.textSecondary, figures: true)],
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.child, required this.label, this.onPressed, this.invalid = false});

  final Widget child;
  final String label;
  final VoidCallback? onPressed;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final box = Container(
      constraints: const BoxConstraints(minHeight: GzSize.controlSm),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
      alignment: onPressed == null ? AlignmentDirectional.centerStart : Alignment.center,
      decoration: onPressed == null
          ? null
          : BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.smAll, border: Border.all(color: invalid ? c.borderError : c.borderStrong, width: GzStroke.hair)),
      child: ExcludeSemantics(child: FittedBox(fit: BoxFit.scaleDown, child: child)),
    );
    if (onPressed == null) return Semantics(label: label, child: box);
    return GzPressable(onPressed: onPressed, semanticLabel: label, minHeight: GzSize.controlSm, borderRadius: GzRadius.smAll, scale: 1, child: box);
  }
}

class HoursDayRow extends StatelessWidget {
  const HoursDayRow({
    required this.weekday,
    required this.day,
    this.invalid = false,
    this.onOpenChange,
    this.onPickFrom,
    this.onPickTo,
    this.onCopy,
    this.last = false,
    super.key,
  });

  final int weekday;
  final DayHours day;
  final bool invalid;
  final ValueChanged<bool>? onOpenChange;
  final VoidCallback? onPickFrom;
  final VoidCallback? onPickTo;
  final VoidCallback? onCopy;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final edit = onOpenChange != null;
    final name = f.weekdayName(weekday, NameStyle.header);
    final full = f.weekdayName(weekday, NameStyle.long);
    String reading(String hhmm) => f.plain(f.time(clockAt(f, hhmm)));
    final nextDay = day.open && day.to.compareTo(day.from) < 0;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline.withAlpha(last ? 0 : 255), width: GzStroke.hair))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.rowMin),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
              child: Row(
                children: [
                  SizedBox(width: GzSpace.s12, child: GzText(name, role: GzTextRole.title, color: day.open ? c.textStrong : c.textSecondary)),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: day.open
                        ? Row(
                            children: [
                              Expanded(child: _TimeBox(label: '${l.hotelSettingsHoursTimeFrom} ${reading(day.from)}', onPressed: edit ? onPickFrom : null, child: TimeFigure(hhmm: day.from))),
                              const SizedBox(width: GzSpace.s2),
                              GzIcon(GzIcons.arrowRight, size: GzIconSize.xs, color: c.iconSecondary, mirror: true),
                              const SizedBox(width: GzSpace.s2),
                              Expanded(
                                child: _TimeBox(label: '${l.hotelSettingsHoursTimeTo} ${reading(day.to)}', onPressed: edit ? onPickTo : null, invalid: invalid, child: TimeFigure(hhmm: day.to, next: nextDay)),
                              ),
                            ],
                          )
                        : Semantics(
                            label: l.hotelSettingsHoursClosedWord,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: GzSize.controlSm),
                              child: Align(alignment: AlignmentDirectional.centerStart, child: GzIcon(GzIcons.lock, size: GzIconSize.xs, color: c.iconDisabled)),
                            ),
                          ),
                  ),
                  if (edit) ...[const SizedBox(width: GzSpace.s3), GzSwitch(label: l.hotelSettingsHoursOpenOn(full), checked: day.open, onChanged: onOpenChange)],
                ],
              ),
            ),
          ),
          if (edit && day.open && invalid)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
              child: Row(
                children: [
                  GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger),
                  const SizedBox(width: GzSpace.s1),
                  Expanded(child: GzText(l.hotelSettingsHoursInvalid, role: GzTextRole.caption, color: c.textDanger)),
                ],
              ),
            ),
          if (edit && day.open && onCopy != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
              child: Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: l.hotelSettingsHoursCopy, variant: GzButtonVariant.tertiary, iconStart: GzIcons.copy, onPressed: onCopy)),
            ),
        ],
      ),
    );
  }
}

/// Sun-Thu, Fri and Sat, a single day, or every day: the days of one run in words.
String runDays(AppL10n l, GzFormat f, HoursRun run) {
  String name(int d) => f.weekdayName(d, NameStyle.long);
  if (run.count == 7) return l.hotelSettingsHoursEveryDay;
  if (run.count == 1) return name(run.first);
  if (run.count == 2) return l.hotelSettingsHoursDaysPair(name(run.first), name(run.last));
  return l.hotelSettingsHoursDaysRange(name(run.first), name(run.last));
}

/// The "Shown to couples as" lines of a week.
List<String> previewLines(AppL10n l, GzFormat f, List<DayHours> week) {
  final runs = runsOf(week);
  if (runs.every((r) => !r.open)) return [l.hotelSettingsHoursAllClosed];
  return [
    for (final r in runs)
      r.open ? l.hotelSettingsHoursLine(runDays(l, f, r), f.time(clockAt(f, r.from)), f.time(clockAt(f, r.to))) : l.hotelSettingsHoursLineClosed(runDays(l, f, r)),
  ];
}

// ------------------------------------------------------------------------------------------------ sheets

class TimeContent extends StatefulWidget {
  const TimeContent({required this.title, required this.initial, required this.onSet, super.key});

  final String title;
  final String initial;
  final ValueChanged<String> onSet;

  @override
  State<TimeContent> createState() => _TimeContentState();
}

class _TimeContentState extends State<TimeContent> {
  late int _hour = splitClock(widget.initial).hour;
  late int _minute = splitClock(widget.initial).minute;
  late bool _pm = splitClock(widget.initial).pm;

  Widget _pick(BuildContext context, String text, bool on, VoidCallback onTap, {double minWidth = GzSize.controlMd}) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onTap,
      semanticLabel: text,
      selected: on,
      minHeight: GzSize.controlSm,
      borderRadius: GzRadius.smAll,
      scale: 1,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth, minHeight: GzSize.controlSm),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? c.actionSelectedBg : c.surfaceRaised,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: on ? c.actionSelectedBg : c.borderStrong, width: GzStroke.hair),
        ),
        child: ExcludeSemantics(child: GzText(text, color: on ? c.actionSelectedLabel : c.textStrong, figures: true)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final value = joinClock(_hour, _minute, _pm);
    final minutes = kMinutes.contains(_minute) ? kMinutes : [...kMinutes, _minute]..sort();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzText(f.time(clockAt(f, value)), role: GzTextRole.uiXl, color: c.textStrong, figures: true),
        const SizedBox(height: GzSpace.s4),
        Semantics(
          container: true,
          label: l.hotelSettingsHoursHour,
          child: Wrap(spacing: GzSpace.s2, runSpacing: GzSpace.s2, children: [for (final h in kHours12) _pick(context, f.integer(h), h == _hour, () => setState(() => _hour = h))]),
        ),
        const SizedBox(height: GzSpace.s4),
        Semantics(
          container: true,
          label: l.hotelSettingsHoursMinute,
          child: Wrap(
            spacing: GzSpace.s2,
            runSpacing: GzSpace.s2,
            children: [for (final m in minutes) _pick(context, ':${m.toString().padLeft(2, '0')}', m == _minute, () => setState(() => _minute = m), minWidth: GzSpace.s16)],
          ),
        ),
        const SizedBox(height: GzSpace.s4),
        GzSegmentedControl<String>(
          label: widget.title,
          value: _pm ? 'pm' : 'am',
          onChanged: (v) => setState(() => _pm = v == 'pm'),
          options: [GzSegmentedOption(value: 'am', label: l.hotelSettingsHoursAm), GzSegmentedOption(value: 'pm', label: l.hotelSettingsHoursPm)],
        ),
        GzSheetFooter(child: GzButton(label: l.hotelSettingsHoursSetTime, fullWidth: true, onPressed: () => widget.onSet(value))),
      ],
    );
  }
}

class ClosureContent extends StatefulWidget {
  const ClosureContent({required this.onAdd, super.key});

  final void Function(String label, String from, String to) onAdd;

  @override
  State<ClosureContent> createState() => _ClosureContentState();
}

class _ClosureContentState extends State<ClosureContent> {
  GzDateRange _range = GzDateRange.empty;
  String _label = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ready = _range.start != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzCalendar.range(value: _range, onChanged: (r) => setState(() => _range = r), legend: false, label: l.hotelSettingsHoursAddTitle),
        const SizedBox(height: GzSpace.s4),
        GzTextField(label: l.hotelSettingsHoursAddLabel, optional: true, onValueChange: (v) => _label = v),
        GzSheetFooter(
          child: GzButton(
            label: l.hotelSettingsHoursAddConfirm,
            fullWidth: true,
            onPressed: ready ? () => widget.onAdd(_label.trim(), _range.start!, _range.end ?? _range.start!) : null,
          ),
        ),
      ],
    );
  }
}
