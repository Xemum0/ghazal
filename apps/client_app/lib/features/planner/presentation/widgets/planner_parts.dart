import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, LocalizedText, Planner, PlannerPackage, PlannerTier, Venue;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/planner_data.dart';

/// The glyph of one inclusion on a package plate, by tier and position.
IconData tierGlyph(PlannerTier tier, int index) {
  const silver = [GzIcons.user, GzIcons.checklist, GzIcons.checkCircle, GzIcons.pin];
  const gold = [GzIcons.calendarCheck, GzIcons.receipt, GzIcons.image, GzIcons.usersThree];
  const royal = [GzIcons.decor, GzIcons.stage, GzIcons.document, GzIcons.team];
  final list = switch (tier) {
    PlannerTier.silver => silver,
    PlannerTier.gold => gold,
    PlannerTier.royal => royal,
    _ => silver,
  };
  return list[index.clamp(0, list.length - 1)];
}

/// The short label of one inclusion (two words), same positions as the glyphs.
String tierShortLabel(AppL10n l, PlannerTier tier, int index) {
  final i = index.clamp(0, 3);
  return switch (tier) {
    PlannerTier.silver => [l.clientPlannerIncSilver0, l.clientPlannerIncSilver1, l.clientPlannerIncSilver2, l.clientPlannerIncSilver3][i],
    PlannerTier.gold => [l.clientPlannerIncGold0, l.clientPlannerIncGold1, l.clientPlannerIncGold2, l.clientPlannerIncGold3][i],
    _ => [l.clientPlannerIncRoyal0, l.clientPlannerIncRoyal1, l.clientPlannerIncRoyal2, l.clientPlannerIncRoyal3][i],
  };
}

/// The short labels of the inclusions a plate shows: Silver lists its four;
/// Gold and Royal open with the carry-over row (the previous tier's name,
/// drawn with a plus) and then all four of their own short labels.
List<(String, bool)> tierPlateLabels(AppL10n l, PlannerTier tier) {
  final all = [for (var i = 0; i < 4; i++) tierShortLabel(l, tier, i)];
  if (tier == PlannerTier.silver) return [for (final s in all) (s, false)];
  return [(all[0], true), for (final s in all) (s, false)];
}

/// One, two or three thread beads: the tier mark (never a metal colour).
class TierMarks extends StatelessWidget {
  const TierMarks({required this.count, required this.label, super.key});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++) ...[if (i > 0) const SizedBox(width: 3), const GzThreadBead()],
          ],
        ),
      ),
    );
  }
}

/// The photograph of each tier, like the prototype's tierMedia override: the
/// fixture stills are phone-on-desk shots, so the flow draws three curated
/// wedding photographs instead (day-of candles, planning candelabras, the
/// Royal staircase). Silver's curated file (details-10) was never bundled
/// into the mock package (see requests.md): the closest bundled candle still
/// stands in meanwhile.
String tierPhotoSrc(PlannerTier tier) => switch (tier) {
  PlannerTier.silver => 'asset://ghazal_mock_api/images/details-09-candles-gold-geometric-lantern-roses',
  PlannerTier.gold => 'asset://ghazal_mock_api/images/context-54-hero-gold-candelabras-white-floral-tables',
  _ => 'asset://ghazal_mock_api/images/context-53-hero-staircase-blush-roses-copper-lanterns',
};

/// One planner package as a wall-label plate: a full-bleed photograph, then the
/// name in the display face with its marks, the from-price between two
/// hairlines (the terms behind its info glyph), the inclusions as glyph plus
/// short-label rows, and the suits line. Unframed, no card, no shadow.
class TierPlate extends StatelessWidget {
  const TierPlate({required this.pkg, this.previousName, super.key});

  final PlannerPackage pkg;

  /// The previous tier's localized name (Gold and Royal open with it).
  final String? previousName;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final labels = tierPlateLabels(l, pkg.tier);
    return Column(
      key: ValueKey<String>('planner.plate.${pkg.tier.value}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzPhoto(src: tierPhotoSrc(pkg.tier), alt: '', aspectRatio: 16 / 9),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: GzSpace.s5),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GzText(pkg.name.of(lang), role: GzTextRole.d2, color: c.textStrong),
                            const SizedBox(height: GzSpace.s1),
                            TierMarks(count: pkg.marks, label: l.clientPlannerMarks(pkg.marks)),
                          ],
                        ),
                      ),
                      const SizedBox(width: GzSpace.s3),
                      GzPrice(fils: pkg.from.fils, size: GzPriceSize.display, prefix: l.clientPlannerFromPrefix),
                      GzInfoButton(title: l.clientPlannerPriceInfoTitle, paragraphs: [l.clientPlannerPriceInfo]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: GzSpace.s4),
              Semantics(
                label: l.clientPlannerIncludedLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < labels.length; i++) ...[
                      if (i > 0) const SizedBox(height: GzSpace.s3),
                      Semantics(
                        label: labels[i].$2 && previousName != null ? '${l.clientPlannerEverythingIn} $previousName' : null,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: GzSize.iconLg),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (labels[i].$2) ...[
                                const GzIcon(GzIcons.plus, size: GzIconSize.sm, tone: GzIconTone.accent),
                                const SizedBox(width: GzSpace.s3),
                                TierMarks(
                                  count: pkg.tier == PlannerTier.gold ? 1 : 2,
                                  label: l.clientPlannerMarks(pkg.tier == PlannerTier.gold ? 1 : 2),
                                ),
                                const SizedBox(width: GzSpace.s2),
                                Expanded(
                                  child: GzText(previousName ?? labels[i].$1, role: GzTextRole.bodyS, color: c.textStrong),
                                ),
                              ] else ...[
                                GzIcon(tierGlyph(pkg.tier, pkg.tier == PlannerTier.silver ? i : i - 1), size: GzIconSize.sm, color: c.iconSecondary),
                                const SizedBox(width: GzSpace.s3),
                                Expanded(
                                  child: GzText(labels[i].$1, role: GzTextRole.bodyS, color: c.textStrong),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: GzSpace.s2),
            ],
          ),
        ),
      ],
    );
  }
}

/// The ruled strip that says which wedding this is about: hall, date and, from
/// My Wedding, the days to go, as facts (icon + value, no labels on screen).
class PlannerContextLine extends ConsumerWidget {
  const PlannerContextLine({required this.venueId, required this.date, this.countdown = false, super.key});

  final String venueId;
  final LocalDate date;
  final bool countdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lg = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final venueAsync = ref.watch(plannerVenueProvider(venueId));
    final venue = venueAsync.value;
    final days = _daysUntil(f, date);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
        child: GzFactRow(
          label: l.clientPlannerWeddingLabel,
          children: [
            if (venue != null) GzFactChip(icon: GzIcons.hall, label: l.clientPlannerWeddingLabel, value: venue.name.of(lang)),
            GzFactChip(
              icon: GzIcons.calendar,
              label: l.clientPlannerWeddingLabel,
              valueWidget: gzFigText(context, _dayMonth(f, date), role: GzTextRole.figBodyS),
            ),
            if (countdown && days > 0)
              GzFactChip(
                icon: GzIcons.countdown,
                label: lg.commonCountdownDays(days),
                valueWidget: gzFigText(context, f.duration(days * 86400000), role: GzTextRole.figBodyS),
                tone: GzFactTone.accent,
              ),
          ],
        ),
      ),
    );
  }

  String _dayMonth(GzFormat f, LocalDate date) {
    final civil = f.civil(date.toString());
    return '${f.integer(civil.day)} ${f.monthName(civil.month, short: true)}';
  }

  int _daysUntil(GzFormat f, LocalDate date) {
    try {
      return f.daysUntil(date.toString());
    } on Object {
      return 0;
    }
  }
}

/// The planner as a person: monogram, name, role, her package as thread marks
/// and a word. `action` sits at inline-end (the chat glyph).
class PlannerIdentity extends StatelessWidget {
  const PlannerIdentity({required this.planner, required this.tier, required this.tierName, this.action, super.key});

  final Planner planner;
  final PlannerTier tier;
  final String tierName;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: planner.name.of(lang),
      child: Row(
        children: [
          ExcludeSemantics(
            child: GzAvatar(name: planner.name.of(lang), initial: planner.monogram, size: GzAvatarSize.lg),
          ),
          const SizedBox(width: GzSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GzText(planner.name.of(lang), role: GzTextRole.title, color: c.textStrong),
                const SizedBox(height: 2),
                GzText(planner.role.of(lang), role: GzTextRole.caption, color: c.textSecondary),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TierMarks(
                      count: tier == PlannerTier.silver
                          ? 1
                          : tier == PlannerTier.gold
                          ? 2
                          : 3,
                      label: l.clientPlannerMarks(
                        tier == PlannerTier.silver
                            ? 1
                            : tier == PlannerTier.gold
                            ? 2
                            : 3,
                      ),
                    ),
                    const SizedBox(width: GzSpace.s2),
                    Flexible(
                      child: GzText(tierName, role: GzTextRole.caption, color: c.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: GzSpace.s4), action!],
        ],
      ),
    );
  }
}

/// What was asked: the package (thumb, name, marks) and the wedding as two facts.
class PlannerRequestSummary extends ConsumerWidget {
  const PlannerRequestSummary({required this.pkg, required this.venueId, required this.date, super.key});

  final PlannerPackage pkg;
  final String venueId;
  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final l = context.l10n;
    final venueAsync = ref.watch(plannerVenueProvider(venueId));
    final venue = venueAsync.value;
    return Semantics(
      container: true,
      label: pkg.name.of(lang),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderHairline, width: GzStroke.hair),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GzSpace.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: GzSize.thumbLg,
                  child: GzPhoto(src: tierPhotoSrc(pkg.tier), alt: '', borderRadius: GzRadius.smAll),
                ),
              ),
              const SizedBox(width: GzSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GzText(pkg.name.of(lang), role: GzTextRole.d1, color: c.textStrong),
                        ),
                        const SizedBox(width: GzSpace.s2),
                        TierMarks(count: pkg.marks, label: l.clientPlannerMarks(pkg.marks)),
                      ],
                    ),
                    const SizedBox(height: GzSpace.s2),
                    GzFactRow(
                      label: l.clientPlannerWeddingLabel,
                      children: [
                        if (venue != null)
                          GzFactChip(icon: GzIcons.hall, label: l.clientPlannerWeddingLabel, value: venue.name.of(lang), small: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The next two weeks as a Sunday-first calendar strip: the month once above
/// it, seven weekday initials (drawn, not read), then the days as 44+ cells
/// with up to three marks under the figure (session glyphs for chosen
/// windows, one bead for a day with free times). One day is selected (gold
/// fill); a day with nothing to offer is disabled, never greyed away.
class PlannerDayGrid extends StatelessWidget {
  const PlannerDayGrid({
    required this.days,
    required this.value,
    required this.onPick,
    required this.name,
    required this.labelOf,
    this.marksFor,
    this.enabledFor,
    this.disabled = false,
    this.aside,
    super.key,
  });

  final List<LocalDate> days;
  final LocalDate? value;
  final ValueChanged<LocalDate> onPick;

  /// The group's accessible name.
  final String name;

  /// The accessible name of a day: the full date, plus what it holds.
  final String Function(LocalDate day) labelOf;

  /// Under the figure, up to three marks: an [IconData] glyph, or null for the bead.
  final List<IconData?> Function(LocalDate day)? marksFor;

  /// A day that cannot be chosen (no free times). Default: all can.
  final bool Function(LocalDate day)? enabledFor;
  final bool disabled;
  final Widget? aside;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final months = <String>[];
    for (final d in days) {
      final m = f.monthName(d.month, short: true);
      if (months.isEmpty || months.last != m) months.add(m);
    }
    final lead = days.isEmpty ? 0 : DateTime.utc(days.first.year, days.first.month, days.first.day).weekday % 7;
    final cells = <LocalDate?>[...List<LocalDate?>.filled(lead, null), ...days];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return Column(
      key: const ValueKey<String>('planner.days'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  for (var i = 0; i < months.length; i++) ...[
                    if (i > 0) ...[const SizedBox(width: GzSpace.s2), GzIcon(GzIcons.arrowRight, size: GzIconSize.xs, color: c.iconSecondary)],
                    GzText(months[i], role: GzTextRole.title, color: c.textStrong),
                  ],
                ],
              ),
            ),
            if (aside != null)
              DefaultTextStyle(
                style: TextStyle(color: c.textSecondary),
                child: aside!,
              ),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        Row(
          children: [
            for (var i = 0; i < f.weekdayHeaders().length; i++) ...[
              if (i > 0) const SizedBox(width: GzStroke.thread),
              Expanded(
                child: Center(
                  child: ExcludeSemantics(
                    child: GzText(f.weekdayHeaders()[i], role: GzTextRole.caption, color: c.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        Semantics(
          container: true,
          label: name,
          child: Column(
            children: [
              for (var r = 0; r < cells.length / 7; r++)
                Padding(
                  padding: EdgeInsetsDirectional.only(top: r == 0 ? 0 : GzStroke.thread),
                  child: Row(
                    children: [
                      for (var ci = 0; ci < 7; ci++) ...[
                        if (ci > 0) const SizedBox(width: GzStroke.thread),
                        Expanded(child: _cell(context, cells[r * 7 + ci])),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, LocalDate? day) {
    final c = context.gz.colors;
    if (day == null) return const SizedBox(height: GzSize.calCellHeight);
    final f = context.gzFormat;
    final on = !(disabled || (enabledFor != null && !enabledFor!(day)));
    final active = day == value;
    final marks = (marksFor?.call(day) ?? const <IconData?>[]).take(3).toList();
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        gzFigText(context, f.integer(day.day), role: GzTextRole.calDay, color: active ? c.textOnGold : (on ? c.textStrong : c.textDisabled)),
        SizedBox(
          height: GzSpace.s3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < marks.length; i++) ...[
                if (i > 0) const SizedBox(width: 1),
                if (marks[i] == null)
                  Transform.rotate(
                    angle: 0.785,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: active ? c.textOnGold : c.textGoldInk),
                      child: const SizedBox.square(dimension: 6),
                    ),
                  )
                else
                  GzIcon(marks[i]!, sizeDp: 12, color: active ? c.textOnGold : c.textGoldInk),
              ],
            ],
          ),
        ),
      ],
    );
    final box = active
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: c.markKhayt,
              borderRadius: GzRadius.smAll,
              border: Border.all(color: c.markDecor, width: GzStroke.hair),
            ),
            child: SizedBox(
              height: GzSize.calCellHeight,
              child: Center(child: content),
            ),
          )
        : SizedBox(
            height: GzSize.calCellHeight,
            child: Center(child: content),
          );
    return GzPressable(
      key: ValueKey<String>('planner.day.$day'),
      onPressed: on ? () => onPick(day) : null,
      semanticLabel: labelOf(day),
      selected: active,
      minWidth: 0,
      minHeight: GzSize.calCellHeight,
      borderRadius: GzRadius.smAll,
      child: box,
    );
  }
}

/// The venue name of a localized venue, for cells outside a consumer.
String venueNameOf(Venue? venue, String lang) => venue?.name.of(lang) ?? '';

/// Localized text helper for cells that already resolved the venue.
String textOf(LocalizedText text, String lang) => text.of(lang);
