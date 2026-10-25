// The chrome the three calendar views share (web `calendar/_components/Chrome.tsx`, `calBits.tsx`): the top bar with its icon actions, the
// Month / Week / Day switch (three glyphs), the hall chips (only when the venue has more than one hall, one word each) and the period header
// (the title, then Today only when the view is away from today, an optional (i), and the two arrows that mirror with the week).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart' show Hall;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/calendar_data.dart';

enum CalViewKind { month, week, day }

/// A hall as one word: `Danah Ballroom` is `Danah`, `قاعة الدانة` is `الدانة`. The generic word goes; a name that would collide keeps its full form.
final RegExp _generic = RegExp(r'(^|\s)(Ballroom|Hall)(?=\s|$)|(^|\s)قاعة(?=\s|$)');

String shortOf(String name) {
  final out = name.replaceAll(_generic, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  return out.isEmpty ? name : out;
}

String Function(String id) shortHall(List<Hall> halls, String lang) {
  final shorts = [for (final h in halls) shortOf(h.name.of(lang))];
  final clash = shorts.toSet().length != shorts.length || halls.length < 2;
  final byId = <String, String>{for (var i = 0; i < halls.length; i++) halls[i].id: clash ? halls[i].name.of(lang) : shorts[i]};
  return (id) => byId[id] ?? '';
}

/// `Thu 24 Dec` for one date; `24 – 26 Dec` (or `24 Dec – 3 Jan`) for a range: no weekdays, the dates are the facts.
String spanText(GzFormat f, String? a, String? b) {
  if (a == null) return '';
  final x = b != null && b.compareTo(a) < 0 ? b : a;
  final y = b != null && b.compareTo(a) < 0 ? a : (b ?? a);
  if (x == y) return f.date(x, DateStyle.short);
  final dx = f.integer(int.parse(x.substring(8)));
  final dy = f.integer(int.parse(y.substring(8)));
  final mx = int.parse(x.substring(5, 7));
  final my = int.parse(y.substring(5, 7));
  if (x.substring(0, 7) == y.substring(0, 7)) return '$dx – $dy ${f.monthName(my, short: true)}';
  return '$dx ${f.monthName(mx, short: true)} – $dy ${f.monthName(my, short: true)}';
}

String dayMonthOf(GzFormat f, String iso) => '${f.integer(int.parse(iso.substring(8)))} ${f.monthName(int.parse(iso.substring(5, 7)), short: true)}';

class CalTop extends StatelessWidget {
  const CalTop({this.offline = false, this.onSelect, this.selecting = false, this.onBlock, this.onEmail, super.key});

  final bool offline;
  final bool selecting;
  final VoidCallback? onSelect;
  final VoidCallback? onBlock;
  final VoidCallback? onEmail;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzTopBar(
          title: l.hotelCalendarTitle,
          actions: [
            if (onSelect != null) GzTopBarAction(icon: GzIcons.calendarPlus, label: l.hotelCalendarActionSelect, pressed: selecting, onPressed: onSelect),
            if (onBlock != null) GzTopBarAction(icon: GzIcons.lock, label: l.hotelCalendarActionBlock, onPressed: onBlock),
            if (onEmail != null) GzTopBarAction(icon: GzIcons.mail, label: l.hotelCalendarEmailTitle, onPressed: onEmail),
          ],
        ),
        if (offline) GzBanner(message: l.hotelCalendarOfflineStamp(f.time(DateTime.now())), tone: GzBannerTone.offline),
      ],
    );
  }
}

/// Switching the view moves along the inventory edges: Month pushes Week or Day, Week and Day replace each other, and Month from either goes
/// back to the tab root, so Back always lands somewhere sensible.
class ViewSwitch extends ConsumerWidget {
  const ViewSwitch({required this.view, super.key});

  final CalViewKind view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final selected = ref.watch(calViewProvider).selected;
    void go(CalViewKind to) {
      if (to == view) return;
      final target = to == CalViewKind.week ? 'HL-CALN-02' : 'HL-CALN-03';
      final params = to == CalViewKind.day ? <String, Object?>{'date': selected} : const <String, Object?>{};
      if (to == CalViewKind.month) {
        nav.switchTab('calendar');
      } else if (view == CalViewKind.month) {
        nav.push(target, params: params);
      } else {
        nav.replace(target, params: params);
      }
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3),
      child: GzIconSegmented<CalViewKind>(
        label: l.hotelCalendarViewLabel,
        value: view,
        labels: GzIconSegmentedLabels.all,
        onChanged: go,
        options: [
          GzIconSegmentedOption(value: CalViewKind.month, icon: GzIcons.calendarDots, label: l.hotelCalendarViewMonth),
          GzIconSegmentedOption(value: CalViewKind.week, icon: GzIcons.list, label: l.hotelCalendarViewWeek),
          GzIconSegmentedOption(value: CalViewKind.day, icon: GzIcons.clock, label: l.hotelCalendarViewDay),
        ],
      ),
    );
  }
}

/// The hall filter: a rail of chips, shown only because this venue has more than one hall. One word each: All, then the halls by short name.
class HallChips extends ConsumerWidget {
  const HallChips({required this.halls, super.key});

  final List<Hall> halls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (halls.length < 2) return const SizedBox.shrink();
    final l = context.l10n;
    final short = shortHall(halls, context.gz.locale.languageCode);
    final hall = ref.watch(calViewProvider).hall;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, top: GzSpace.s3),
      child: GzChipGroup<String>(
        label: l.hotelCalendarHallsLabel,
        layout: GzChipLayout.rail,
        value: hall,
        onChanged: (v) => ref.read(calViewProvider.notifier).setHall(v ?? kAllHalls),
        options: [GzChipOption<String>(value: kAllHalls, label: l.hotelCalendarHallsAll), for (final h in halls) GzChipOption<String>(value: h.id, label: short(h.id))],
      ),
    );
  }
}

/// The title at the start; Today, the (i) and the two arrows (the registry mirrors them in Arabic) at the end.
class PeriodHead extends StatelessWidget {
  const PeriodHead({required this.title, required this.prevLabel, required this.nextLabel, required this.onPrev, required this.onNext, required this.onToday, this.away = false, this.info, super.key});

  final String title;
  final String prevLabel;
  final String nextLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final bool away;
  final Widget? info;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2, top: GzSpace.s2),
      child: Row(
        children: [
          Expanded(child: Semantics(header: true, liveRegion: true, child: GzText(title, role: GzTextRole.uiTitle, color: c.textStrong, figures: true))),
          if (away) GzButton(label: context.gzL10n.commonCalendarToday, variant: GzButtonVariant.tertiary, onPressed: onToday),
          ?info,
          GzIconButton(icon: GzIcons.chevronLeft, label: prevLabel, onPressed: onPrev),
          GzIconButton(icon: GzIcons.chevronRight, label: nextLabel, onPressed: onNext),
        ],
      ),
    );
  }
}

/// Opens the block sheet (HL-CALN-04) the way the three views do.
void openBlockSheet(GzNavigator nav, {String? start, String? end, String? hallId, String mode = 'block'}) =>
    nav.openSheet('HL-CALN-04', options: GzSheetOptions(params: <String, Object?>{'mode': mode, 'start': start, 'end': end, if (hallId != null) 'hallIds': <String>[hallId]}));
