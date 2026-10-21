import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show Area, DateMode, LocalizedText, MoneyRange;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show SearchBrief;
import '../../../../l10n/l10n.dart';

/// An open budget as one figure: `KD 35,000+` / `+35,000 د.ك` (the plus sits inside the number's LTR isolate). The upper bound of an
/// open band is stored as 0 fils (the contract's `MoneyRange` has no null).
bool isOpenBudget(MoneyRange b) => b.max.fils == 0;

String briefBudgetText(GzFormat f, MoneyRange budget) {
  if (!isOpenBudget(budget)) return f.moneyRange(budget.min.fils, budget.max.fils);
  final m = f.moneyParts(budget.min.fils, const MoneyOptions(mode: MoneyMode.browse));
  return f.isArabic ? '${GzBidi.isolateLtr('${m.amount}+')} ${m.currency}' : '${m.currency} ${m.amount}+';
}

/// The date of a Brief as its row says it (`Thu 14 Jan 2027`, a flexible month `January 2027`), null when none is set or it is undecided.
String? briefDateText(GzFormat f, SearchBrief b) {
  if (b.date == null || b.dateMode == DateMode.undecided) return null;
  return f.date(b.date.toString(), b.dateMode == DateMode.flexibleMonth ? DateStyle.monthYear : DateStyle.short);
}

IconData briefDateIcon(SearchBrief b) => b.dateMode == DateMode.flexibleMonth && b.date != null ? GzIcons.calendarDots : GzIcons.calendar;

/// The names of the Brief's areas in the current language, in the order the Brief holds them.
List<String> briefAreaNames(Iterable<Area> areas, List<String> ids, String lang) => <String>[
  for (final id in ids) ...<String>[for (final a in areas) if (a.id == id) a.name.of(lang)],
];

/// The Area value of a half-width cell holds one line: both names when they are short, else the first and a count.
String? briefAreaText(BuildContext context, GzFormat f, List<String> names) {
  if (names.isEmpty) return null;
  final sep = f.isArabic ? '، ' : ', ';
  final joined = names.join(sep);
  final room = f.isArabic ? 18 : 16;
  return names.length == 1 || joined.length <= room ? joined : context.l10n.clientDiscoverBriefAreaMore(names.first, f.integer(names.length - 1));
}

LocalizedText? areaName(Iterable<Area> areas, String id) => areas.where((a) => a.id == id).firstOrNull?.name;

/// A Brief row: a glyph and its value (the row's name is the accessible name); a skipped answer is a muted one-word placeholder. 64 high,
/// quiet fill while pressed. [chevron] draws the disclosure glyph at inline-end (the Brief sheet's rows).
class BriefRowTile extends StatelessWidget {
  const BriefRowTile({
    required this.icon,
    required this.name,
    required this.value,
    required this.placeholder,
    required this.onPressed,
    this.border = false,
    this.chevron = false,
    this.extra,
    this.inset = GzSpace.s4,
    super.key,
  });

  final IconData icon;
  final String name;
  final String? value;
  final String placeholder;
  final VoidCallback? onPressed;
  final bool border;
  final bool chevron;

  /// A glyph after the value (the section of the guest count).
  final Widget? extra;

  /// The inline padding of the row (16 in a card, 0 in the sheet where the sheet brings the gutter).
  final double inset;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final empty = value == null;
    final shown = value ?? placeholder;
    final body = gz.text(GzTextRole.body);
    final style = body.copyWith(
      color: empty ? c.textSecondary : c.textStrong,
      fontWeight: empty ? body.fontWeight : gz.text(GzTextRole.title).fontWeight,
      decoration: TextDecoration.none,
    );
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: '$name: ${GzBidi.strip(shown)}',
      builder: (context, st) => Container(
        constraints: const BoxConstraints(minHeight: GzSize.briefRow),
        decoration: BoxDecoration(
          color: st.pressed ? c.surfaceQuiet : null,
          border: border ? Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair)) : null,
        ),
        padding: EdgeInsetsDirectional.symmetric(horizontal: inset, vertical: GzSpace.s3),
        child: Row(
          children: [
            GzIcon(icon, size: GzIconSize.md, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text.rich(
                      TextSpan(children: GzFigures.spans(context, shown, role: GzTextRole.body)),
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (extra != null) ...[const SizedBox(width: GzSpace.s2), extra!],
                ],
              ),
            ),
            if (chevron) GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
          ],
        ),
      ),
    );
  }
}
