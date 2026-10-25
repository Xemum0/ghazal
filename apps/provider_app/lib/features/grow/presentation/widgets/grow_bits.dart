// Small shared pieces of the Grow screens (web `grow/_components/{Head,Note,Saving,StepThread,PickRow,bits}`): the section head, the quiet note, the
// signed saving, the two-step thread, the pick row with its checklist sheet, and the short date forms of the text diet. Every digit comes from the
// formatter; only the shape is shorter.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, MoneyMode, MoneyOptions, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show VoucherWindow;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

// ---------------------------------------------------------------- date shapes

/// `3 Dec` / `3 ديسمبر`: day and short month, no weekday, no year.
String dm(GzFormat f, String iso) {
  final c = f.civil(iso);
  return '${f.integer(c.day)} ${f.monthName(c.month, short: true)}';
}

/// `3 Dec`, or `3 Dec 2027` when the year is not the current one.
String dmy(GzFormat f, String iso, String today) => f.civil(iso).year == f.civil(today).year ? dm(f, iso) : f.date(iso, DateStyle.compact);

/// `3, 5 Dec · 2 Jan`: days grouped by month, the month named once.
String dayList(GzFormat f, List<String> isos) {
  final groups = <({int year, int month, List<int> days})>[];
  for (final iso in [...isos]..sort()) {
    final c = f.civil(iso);
    if (groups.isNotEmpty && groups.last.year == c.year && groups.last.month == c.month) {
      groups.last.days.add(c.day);
    } else {
      groups.add((year: c.year, month: c.month, days: [c.day]));
    }
  }
  final sep = f.lang.name == 'ar' ? '، ' : ', ';
  return groups.map((g) => '${g.days.map(f.integer).join(sep)} ${f.monthName(g.month, short: true)}').join(' · ');
}

/// `Sun–Wed` for a run of weekdays, else the names in a row.
String weekdayRun(GzFormat f, List<int> days) {
  final s = [...days]..sort();
  final run = s.asMap().entries.every((e) => e.key == 0 || e.value == s[e.key - 1] + 1);
  String name(int d) => f.weekdayName(d, NameStyle.short);
  return run && s.length > 2 ? '${name(s.first)}–${name(s.last)}' : s.map(name).join(f.lang.name == 'ar' ? '، ' : ', ');
}

// ---------------------------------------------------------------- head, note

/// The title of a section as a glyph in a quiet disk and one or two words; the trailing slot takes the (i) of that section.
class GrowHead extends StatelessWidget {
  const GrowHead({required this.icon, required this.title, this.trailing, super.key});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      child: Row(
        children: [
          Container(
            width: GzSize.disk,
            height: GzSize.disk,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceTintSoft, shape: BoxShape.circle),
            child: GzIcon(icon, size: GzIconSize.sm, color: c.iconPrimary),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Semantics(
              header: true,
              child: GzText(title, role: GzTextRole.uiTitle, color: c.textStrong),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A quiet in-flow line: a glyph, a fragment of a few words, an optional (i) with the sentence that explains it. Tint, never a border.
class GrowNote extends StatelessWidget {
  const GrowNote({required this.text, this.icon, this.info, this.danger = false, super.key});

  final Widget text;
  final IconData? icon;
  final Widget? info;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      liveRegion: danger,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
        padding: EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s2, start: GzSpace.s4, end: info != null ? GzSpace.s1 : GzSpace.s4),
        decoration: BoxDecoration(color: danger ? c.statusDangerBg : c.surfaceTintSoft, borderRadius: GzRadius.smAll),
        child: Row(
          children: [
            GzIcon(icon ?? (danger ? GzIcons.warningCircle : GzIcons.info), size: GzIconSize.sm, color: danger ? c.iconDanger : c.iconPrimary),
            const SizedBox(width: GzSpace.s3),
            Expanded(child: text),
            ?info,
          ],
        ),
      ),
    );
  }
}

/// The note's text in its tone.
class NoteText extends StatelessWidget {
  const NoteText(this.text, {this.danger = false, super.key});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzText(text, role: GzTextRole.bodyS, color: danger ? c.statusDangerText : c.textPrimary, figures: true);
  }
}

/// What a couple keeps, as a signed amount: the currency first, then the true minus inside the LTR island.
class GrowSaving extends StatelessWidget {
  const GrowSaving({required this.fils, required this.label, this.exact = false, super.key});

  final int fils;
  final String label;
  final bool exact;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final m = f.moneyParts(fils, exact ? const MoneyOptions(mode: MoneyMode.exact) : const MoneyOptions());
    return Semantics(
      label: '$label ${f.money(fils)}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(GzIcons.offer, size: GzIconSize.xs, color: c.iconAccent),
          const SizedBox(width: GzSpace.s1),
          GzText(m.currency, role: GzTextRole.caption, color: c.textStrong),
          const SizedBox(width: GzSpace.s1),
          Directionality(
            textDirection: TextDirection.ltr,
            child: GzText('−${m.integer}${m.fraction}', role: GzTextRole.priceStrong, color: c.textStrong),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- step thread

class StepThread extends StatelessWidget {
  const StepThread({required this.step, super.key});

  final int step;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s1, bottom: GzSpace.s3),
      child: GzIconProgress(
        label: l.hotelGrowStepsLabel,
        describe: l.commonCounter(step, 2),
        labels: GzProgressLabels.none,
        draw: GzDraw.mount,
        steps: [
          GzIconProgressStep(id: 'price', icon: GzIcons.coins, label: l.hotelGrowStepPrice, state: step == 1 ? GzKnotState.now : GzKnotState.tied),
          GzIconProgressStep(id: 'dates', icon: GzIcons.calendar, label: l.hotelGrowStepDates, state: step == 2 ? GzKnotState.now : GzKnotState.open),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- pick row

class PickOption {
  const PickOption(this.value, this.label);
  final String value;
  final String label;
}

/// Which packages or halls a window covers without printing them all: one field-sized row that opens a checklist. Empty selection means all.
class GrowPickRow extends StatelessWidget {
  const GrowPickRow({
    required this.icon,
    required this.label,
    required this.allLabel,
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String label;
  final String allLabel;
  final List<PickOption> options;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;

  void _open(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => _PickSheet(label: label, allLabel: allLabel, options: options, value: value, onChanged: onChanged),
      options: GzSheetOptions(title: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final chosen = [
      for (final o in options)
        if (value.contains(o.value)) o,
    ];
    return GzPressable(
      onPressed: () => _open(context),
      semanticLabel: label,
      minHeight: GzSize.controlLg,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.controlLg),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
        decoration: BoxDecoration(
          color: c.controlBg,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderControl, width: GzStroke.hair),
        ),
        child: Row(
          children: [
            GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: GzText(
                      chosen.isEmpty ? allLabel : chosen.first.label,
                      role: GzTextRole.body,
                      color: c.textStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chosen.length > 1) ...[
                    const SizedBox(width: GzSpace.s2),
                    GzText('+${f.integer(chosen.length - 1)}', role: GzTextRole.caption, color: c.textSecondary, figures: true),
                  ],
                ],
              ),
            ),
            GzIcon(GzIcons.chevronDown, size: GzIconSize.sm, color: c.iconSecondary),
          ],
        ),
      ),
    );
  }
}

class _PickSheet extends StatefulWidget {
  const _PickSheet({required this.label, required this.allLabel, required this.options, required this.value, required this.onChanged});

  final String label;
  final String allLabel;
  final List<PickOption> options;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_PickSheet> createState() => _PickSheetState();
}

class _PickSheetState extends State<_PickSheet> {
  late List<String> _v = [...widget.value];

  void _set(List<String> next) {
    final all = next.length == widget.options.length ? <String>[] : next;
    setState(() => _v = all);
    widget.onChanged(all);
  }

  @override
  Widget build(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzCheckbox(label: widget.allLabel, checked: _v.isEmpty, onChanged: (on) => on ? _set(const []) : null),
        for (final o in widget.options)
          GzCheckbox(
            label: o.label,
            checked: _v.contains(o.value),
            onChanged: (on) => _set(
              on
                  ? [..._v, o.value]
                  : [
                      for (final x in _v)
                        if (x != o.value) x,
                    ],
            ),
          ),
        const SizedBox(height: GzSpace.s3),
        GzButton(label: context.l10n.commonActionDone, fullWidth: true, onPressed: nav.closeSheet),
      ],
    );
  }
}

/// The venue's own title of a window in the UI language.
String windowTitle(BuildContext context, VoucherWindow w) => w.title.of(context.gz.locale.languageCode);
