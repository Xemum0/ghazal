// CL-ONBD-04 Wedding date (CA-ONB-03, CA-ONB-08, CA-ONB-09). Port of CL-ONBD-04.tsx.
// The full-screen form of the shared single-date calendar (Sunday-first, Thu to Sat peak band, closed past days) under a two-word title.
// A picked day shows as a fact strip: the date, the Hijri line in the Arabic UI only, and the time left as a glyph and a figure. The
// occasions around the visible month sit under the grid. Two honest alternatives: Undecided and Flexible (a 12-month sheet); when one is
// chosen it replaces the grid with a drawing, its name and the way back.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show DateMode, LocalDate, Occasion;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/onboarding_data.dart';
import '../application/onboarding_profile.dart';
import 'widgets/month_sheet.dart';
import 'widgets/step_bar.dart';
import 'widgets/step_head.dart';

const int _monthsAhead = 12;
const int _dayMs = 86400000;

enum _Mode { exact, undecided, flexibleMonth }

GzYm _monthOf(String iso) => GzYm(int.parse(iso.substring(0, 4)), int.parse(iso.substring(5, 7)));

class ClOnbd04Screen extends ConsumerStatefulWidget {
  const ClOnbd04Screen({super.key});

  @override
  ConsumerState<ClOnbd04Screen> createState() => _ClOnbd04State();
}

class _ClOnbd04State extends ConsumerState<ClOnbd04Screen> {
  late _Mode _mode;
  String? _date;
  GzYm? _flex;
  late GzYm _month;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(obdDraftProvider);
    final today = ref.read(gzFormatProvider).isoDay(ref.read(gzFormatProvider).now());
    final d = saved.weddingDate?.toString();
    _mode = switch (saved.dateMode) {
      DateMode.exact when d != null => _Mode.exact,
      DateMode.flexibleMonth when d != null => _Mode.flexibleMonth,
      DateMode.undecided => saved.weddingDate == null && saved.dateMode != null ? _Mode.undecided : _Mode.exact,
      _ => _Mode.exact,
    };
    _date = _mode == _Mode.exact ? d : null;
    _flex = _mode == _Mode.flexibleMonth && d != null ? _monthOf(d) : null;
    _month = _date != null ? _monthOf(_date!) : (_flex ?? _monthOf(today));
  }

  void _pickDay(String? iso) => setState(() {
    _date = iso;
    _mode = _Mode.exact;
    _flex = null;
  });

  void _decideLater() => setState(() {
    _mode = _mode == _Mode.undecided ? _Mode.exact : _Mode.undecided;
    _date = null;
    _flex = null;
  });

  Future<void> _openMonths(GzFormat f) async {
    final start = _monthOf(f.isoDay(f.now()));
    final months = <GzYm>[for (var i = 0; i < _monthsAhead; i++) GzYm(start.year + (start.month - 1 + i) ~/ 12, (start.month - 1 + i) % 12 + 1)];
    final picked = await showObdMonthSheet(context, months: months, initial: _flex ?? months.first, monthText: (m) => _monthText(f, m));
    if (picked == null || !mounted) return;
    setState(() {
      _flex = picked;
      _mode = _Mode.flexibleMonth;
      _date = null;
    });
  }

  String _monthText(GzFormat f, GzYm m) => f.date(f.kuwaitDate(m.year, m.month, 1), DateStyle.monthYear);

  void _next() => context.gzNav.push('CL-ONBD-05');

  void _confirm(GzFormat f) {
    if (_mode == _Mode.exact) {
      ref.commitDate(date: _date == null ? null : LocalDate.parse(_date!), mode: _date != null ? DateMode.exact : DateMode.undecided);
    } else if (_mode == _Mode.flexibleMonth && _flex != null) {
      ref.commitDate(date: LocalDate(_flex!.year, _flex!.month, 1), mode: DateMode.flexibleMonth);
    } else {
      ref.commitDate(date: null, mode: DateMode.undecided);
    }
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final config = ref.watch(onboardingConfigProvider).value;
    return GzScreen(
      top: ObdStepBar(step: 2, total: 3, onSkip: _next),
      bottom: GzActionBar(
        action: GzActionBarAction(label: l10n.commonActionContinue, onPressed: () => _confirm(f)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ObdStepHead(title: l10n.clientOnboardingDateTitle),
            const SizedBox(height: GzSpace.s6),
            if (_mode == _Mode.exact) ...[
              GzCalendar(
                value: _date,
                onChanged: _pickDay,
                month: _month,
                onMonthChange: (m) => setState(() => _month = m),
                maxDate: config?.availabilityWindow.to.toString(),
                summary: false,
                label: l10n.clientOnboardingDateTitle,
              ),
              const SizedBox(height: GzSpace.s6),
              _Strip(date: _date, format: f),
              ..._occasions(l10n, f, config?.occasions ?? const <Occasion>[]),
            ] else
              GzEmptyState(
                fill: false,
                flush: true,
                illustration: _mode == _Mode.undecided ? GzIllustrationName.hourglass : GzIllustrationName.calendar,
                title: _mode == _Mode.flexibleMonth && _flex != null ? _monthText(f, _flex!) : l10n.clientOnboardingDateNotDecided,
                action: GzStateAction(
                  label: l10n.clientOnboardingDatePickDate,
                  variant: GzButtonVariant.tertiary,
                  onPressed: () => setState(() => _mode = _Mode.exact),
                ),
              ),
            const SizedBox(height: GzSpace.s6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: GzSpace.s2,
                runSpacing: GzSpace.s2,
                children: [
                  GzChip(
                    label: l10n.clientOnboardingDateNotDecided,
                    iconStart: GzIcons.calendarDots,
                    selected: _mode == _Mode.undecided,
                    onPressed: _decideLater,
                  ),
                  GzChip(
                    label: _mode == _Mode.flexibleMonth && _flex != null ? _monthText(f, _flex!) : l10n.clientOnboardingDateFlexible,
                    iconStart: GzIcons.calendar,
                    menu: true,
                    selected: _mode == _Mode.flexibleMonth,
                    onPressed: () => _openMonths(f),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The occasions around the visible month, approximate until announced: quiet facts under the grid.
  List<Widget> _occasions(AppL10n l10n, GzFormat f, List<Occasion> all) {
    final v = _month.year * 12 + _month.month;
    final inMonth = all.where((o) => o.from.year * 12 + o.from.month <= v && v <= o.to.year * 12 + o.to.month).toList();
    if (inMonth.isEmpty) return const <Widget>[];
    return [
      const SizedBox(height: GzSpace.s6),
      Semantics(
        container: true,
        label: l10n.clientOnboardingDateOccasions,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < inMonth.length; i++) ...[
              if (i > 0) const SizedBox(height: GzSpace.s2),
              GzFactChip(
                icon: GzIcons.sparkle,
                small: true,
                tone: GzFactTone.muted,
                label: inMonth[i].name.of(f.lang.name),
                value: inMonth[i].from == inMonth[i].to
                    ? l10n.clientOnboardingDateOccasionOne(inMonth[i].name.of(f.lang.name), f.date(inMonth[i].from.toString(), DateStyle.short))
                    : l10n.clientOnboardingDateOccasionRange(
                        inMonth[i].name.of(f.lang.name),
                        f.date(inMonth[i].from.toString(), DateStyle.dayMonth),
                        f.date(inMonth[i].to.toString(), DateStyle.dayMonth),
                      ),
              ),
            ],
          ],
        ),
      ),
    ];
  }
}

/// The ruled "your date" strip (hairline above and below, not a panel). It keeps its height whether or not a day is chosen, so picking
/// never moves the controls under it.
class _Strip extends StatelessWidget {
  const _Strip({required this.date, required this.format});

  final String? date;
  final GzFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final f = format;
    final rule = BorderSide(color: c.borderHairline, width: GzStroke.hair);
    Widget body;
    if (date == null) {
      body = Row(
        children: [
          GzIcon(GzIcons.calendarPlus, size: GzIconSize.md, color: c.iconDisabled),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: GzText(l10n.clientOnboardingDatePickDate, role: GzTextRole.bodyS, color: c.textSecondary),
          ),
        ],
      );
    } else {
      final info = f.dateWithHijri(date!);
      final days = f.daysUntil(date!);
      // The time left is a figure and the formatter's own day unit (d, ي), read from the formatter, never typed, and after the figure.
      final dayUnit = f.duration(_dayMs.toDouble()).replaceAll(RegExp(r'[\d\u0660-\u0669\u2066\u2069\s\u00a0]', unicode: true), '');
      body = Row(
        children: [
          GzIcon(GzIcons.calendarCheck, size: GzIconSize.md, color: c.iconPrimary),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzText(f.date(date!, DateStyle.short), role: GzTextRole.title, color: c.textStrong, figures: true),
                if (info.secondary != null) GzText(info.secondary!, role: GzTextRole.caption, color: c.textSecondary, figures: true),
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          GzFactChip(
            icon: GzIcons.countdown,
            label: l10n.commonCountdownDays(days),
            value: days > 0 ? f.integer(days) : l10n.commonCountdownDays(0),
            unit: days > 0 ? dayUnit : null,
          ),
        ],
      );
    }
    return Container(
      constraints: const BoxConstraints(minHeight: GzSpace.s16),
      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
      decoration: BoxDecoration(
        border: Border(top: rule, bottom: rule),
      ),
      child: Align(alignment: AlignmentDirectional.centerStart, child: body),
    );
  }
}
