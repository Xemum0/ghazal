import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, PlannerPackage, PlannerTier;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/planner_data.dart';
import 'plan_panel.dart';

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
                      const SizedBox(width: GzSpace.s1),
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
    final venue = ref.watch(plannerVenueProvider(venueId)).value;
    final f = context.gzFormat;
    final civil = f.civil(date.toString());
    return Semantics(
      container: true,
      label: pkg.name.of(lang),
      child: PlanPanel(
        child: Row(
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
                      const SizedBox(width: GzSpace.s3),
                      TierMarks(count: pkg.marks, label: l.clientPlannerMarks(pkg.marks)),
                    ],
                  ),
                  const SizedBox(height: GzSpace.s2),
                  GzFactRow(
                    label: l.clientPlannerWeddingLabel,
                    children: [
                      if (venue != null) GzFactChip(icon: GzIcons.hall, label: l.clientPlannerWeddingLabel, value: venue.name.of(lang)),
                      GzFactChip(
                        icon: GzIcons.calendar,
                        label: l.clientPlannerWeddingLabel,
                        valueWidget: gzFigText(
                          context,
                          '${f.integer(civil.day)} ${f.monthName(civil.month, short: true)}',
                          role: GzTextRole.figBodyS,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
