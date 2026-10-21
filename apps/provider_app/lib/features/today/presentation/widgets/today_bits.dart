// Small pieces shared by the five Today screens (web `today/_components/bits.tsx`, `Facts.tsx`, `SectionLink.tsx`, `StatTile.tsx`): the day line,
// the time-left fact, the section head, the stat tile, the audience glyph. Everything numeric comes from the shared formatter.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, SlaState;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// `Thu 14 Jan` (the weekday, the day and the short month, never a year, so a request for next year stays one line).
String dayMonth(GzFormat f, String iso, {bool weekday = true}) {
  final day = iso.substring(0, 10);
  final parts = day.split('-').map(int.parse).toList();
  final base = '${f.integer(parts[2])} ${f.monthName(parts[1], short: true)}';
  if (!weekday) return base;
  final wd = DateTime.utc(parts[0], parts[1], parts[2]).weekday % 7;
  return '${f.weekdayName(wd, NameStyle.header)} $base';
}

IconData audienceIcon(Audience a) => switch (a) {
  Audience.men => GzIcons.sectionMen,
  Audience.mixed => GzIcons.sectionMixed,
  _ => GzIcons.sectionWomen,
};

String audienceWord(AppL10n l, Audience a) => switch (a) {
  Audience.men => l.hotelTodayAudienceMen,
  Audience.mixed => l.hotelTodayAudienceMixed,
  _ => l.hotelTodayAudienceWomen,
};

/// The compact duration of an SLA reading in the same two readings as the web `useDur`: the visual line and the spoken sentence.
({String visual, String spoken}) todayDuration(BuildContext context, int minutes) {
  final f = context.gzFormat;
  final l = context.l10n;
  final total = minutes < 0 ? 0 : minutes;
  var visual = f.duration(total * 60000);
  final tail = RegExp('[ \u00a0\u202f]\u2066?[0\u0660]\u2069?\u00a0(?:m|\u062f|h|\u0633)\$');
  for (var i = 0; i < 2; i++) {
    visual = visual.replaceFirst(tail, '');
  }
  final d = total ~/ 1440;
  final h = (total % 1440) ~/ 60;
  final m = total % 60;
  final parts = <String>[
    if (d > 0) l.hotelTodayDurDays(d),
    if (h > 0) l.hotelTodayDurHours(h),
    if (d == 0 && (m > 0 || total == 0)) l.hotelTodayDurMinutes(m),
  ];
  final spoken = parts.length > 1 ? l.hotelTodayDurJoin(parts[0], parts[1]) : (parts.isEmpty ? '' : parts.first);
  return (visual: visual, spoken: spoken);
}

enum LeftTone { neutral, gold, danger, expired }

LeftTone leftToneOf(SlaState? s) => switch (s) {
  SlaState.gold => LeftTone.gold,
  SlaState.danger => LeftTone.danger,
  SlaState.expired => LeftTone.expired,
  _ => LeftTone.neutral,
};

/// A glyph and a compact duration in the SLA tone: time left (timer) or time waited (hourglass). The sentence is the accessible name.
class TimeLeft extends StatelessWidget {
  const TimeLeft({
    required this.minutes,
    required this.say,
    this.tone = LeftTone.neutral,
    this.glyph = GzIcons.timer,
    this.onDark = false,
    this.large = false,
    super.key,
  });

  final int minutes;
  final String Function(String spoken) say;
  final LeftTone tone;
  final IconData glyph;
  final bool onDark;

  /// The band's figure (a 20 glyph and the body size); otherwise it sits in a row (16 and the caption).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final d = todayDuration(context, minutes);
    final Color color;
    if (onDark) {
      color = (tone == LeftTone.gold || tone == LeftTone.danger) ? c.textOnDarkGold : c.textOnDarkMuted;
    } else {
      color = switch (tone) {
        LeftTone.gold => c.textGoldInk,
        LeftTone.danger => c.textDanger,
        _ => c.textSecondary,
      };
    }
    return Semantics(
      container: true,
      label: say(d.spoken),
      excludeSemantics: true,
      child: GzGlyphBaseline(
        glyphSize: large ? GzSize.iconSm : GzSize.iconXs,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(glyph, size: large ? GzIconSize.sm : GzIconSize.xs, color: color),
            SizedBox(width: large ? GzSpace.s2 : GzSpace.s1),
            GzText(d.visual, role: large ? GzTextRole.body : GzTextRole.caption, color: color, figures: true, softWrap: false),
          ],
        ),
      ),
    );
  }
}

/// A fact whose value is a short day or time (a string from the formatter).
class TextFact extends StatelessWidget {
  const TextFact({required this.icon, required this.label, required this.text, this.muted = false, this.small = false, super.key});

  final IconData icon;
  final String label;
  final String text;
  final bool muted;
  final bool small;

  @override
  Widget build(BuildContext context) =>
      GzFactChip(icon: icon, label: label, value: text, tone: muted ? GzFactTone.muted : GzFactTone.normal, small: small);
}

/// The section head of the diet: the 24 x 1 gold khayt, the title, and when the section opens somewhere a count and a chevron at inline-end
/// in one 44 press target (`See all` is the chevron, not words).
class SectionLink extends StatelessWidget {
  const SectionLink({required this.title, this.count, this.onPressed, this.hint, super.key});

  final String title;
  final String? count;
  final VoidCallback? onPressed;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      child: Row(
        children: [
          Expanded(
            child: GzText(title, role: GzTextRole.uiTitle, color: c.textStrong, header: true),
          ),
          if (onPressed != null) ...[
            const SizedBox(width: GzSpace.s3),
            if (count != null) GzText(count!, role: GzTextRole.figBodyS, color: c.textPrimary, figures: true),
            if (count != null) const SizedBox(width: GzSpace.s1),
            GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(alignment: AlignmentDirectional.centerStart, child: GzThreadRule()),
        const SizedBox(height: GzSpace.s1),
        if (onPressed == null)
          row
        else
          GzPressable(
            onPressed: onPressed,
            semanticLabel: '$title. ${hint ?? l.commonActionSeeAll}',
            borderRadius: GzRadius.smAll,
            minHeight: GzSize.touchMin,
            child: row,
          ),
      ],
    );
  }
}

/// One count of the month as a hairline panel: a glyph in its tint disk, the figure, an optional second fact at inline-end and an optional unit.
class StatTile extends StatelessWidget {
  const StatTile({required this.icon, required this.value, required this.label, this.unit, this.aside, this.hero = false, this.onPressed, super.key});

  final IconData icon;
  final int value;
  final String label;
  final String? unit;
  final Widget? aside;
  final bool hero;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final panel = Container(
      constraints: BoxConstraints(minHeight: hero ? GzSize.controlLg : GzSize.rowMin),
      padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: hero ? GzSpace.s4 : GzSpace.s3),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            // The kit's inline stat does not shrink: at large text sizes the tile scales it down instead of overflowing.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: GzIconStat(icon: icon, value: f.integer(value), label: label, unit: unit, layout: GzFactLayout.inline),
            ),
          ),
          if (aside != null) ...[const SizedBox(width: GzSpace.s3), aside!],
        ],
      ),
    );
    if (onPressed == null) return panel;
    return GzPressable(onPressed: onPressed, semanticLabel: '$label ${f.integer(value)}', borderRadius: GzRadius.mdAll, minHeight: 0, child: panel);
  }
}
