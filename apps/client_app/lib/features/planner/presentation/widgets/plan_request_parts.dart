import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show DayPart, LocalDate, PlannerTier;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/planner_data.dart';
import 'planner_parts.dart';

/// The session glyphs of the diet: sun for the morning, sunset for the afternoon, moon for the evening.
const Map<DayPart, IconData> kPlanPartGlyph = {DayPart.morning: GzIcons.sun, DayPart.afternoon: GzIcons.sunset, DayPart.evening: GzIcons.moon};

/// The package row's wedding facts: hall and date.
class PlanPackageFacts extends ConsumerWidget {
  const PlanPackageFacts({required this.venueId, required this.date, super.key});

  final String venueId;
  final LocalDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final f = context.gzFormat;
    final venue = ref.watch(plannerVenueProvider(venueId)).value;
    final civil = f.civil(date.toString());
    // The web row is its own flex wrap: 12 between chips, 4 between wrapped rows (the shared GzFactRow keeps 16 and 8).
    return Semantics(
      container: true,
      label: l.clientPlannerWeddingLabel,
      child: Wrap(
        spacing: GzSpace.s3,
        runSpacing: GzSpace.s1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (venue != null) GzFactChip(icon: GzIcons.hall, label: l.clientPlannerWeddingLabel, value: venue.name.of(lang), small: true),
          GzFactChip(
            icon: GzIcons.calendar,
            label: l.clientPlannerWeddingLabel,
            valueWidget: gzFigText(context, '${f.integer(civil.day)} ${f.monthName(civil.month, short: true)}', role: GzTextRole.figCaption),
            small: true,
          ),
        ],
      ),
    );
  }
}

/// One session button: sun, sunset or moon; the word shows only when chosen.
class PlanPartButton extends StatelessWidget {
  const PlanPartButton({required this.part, required this.on, required this.disabled, required this.onTap, super.key});

  final DayPart part;
  final bool on;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final word = switch (part) {
      DayPart.morning => l.clientPlannerRequestWindowMorning,
      DayPart.afternoon => l.clientPlannerRequestWindowAfternoon,
      _ => l.clientPlannerRequestWindowEvening,
    };
    return GzPressable(
      key: ValueKey<String>('planner.part.${part.value}'),
      onPressed: disabled ? null : onTap,
      semanticLabel: word,
      selected: on,
      minWidth: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: on ? c.surfaceRaised : null,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: on ? c.controlChipBorderSelected : c.controlChipBorder, width: on ? GzStroke.thread : GzStroke.hair),
        ),
        child: SizedBox(
          height: GzSize.controlLg,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(kPlanPartGlyph[part]!, size: GzIconSize.md, color: on ? c.iconPrimary : c.iconSecondary),
                if (on) ...[const SizedBox(height: GzStroke.thread), GzText(word, role: GzTextRole.caption, color: c.textStrong)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The package sheet: three radio rows (thumb, name and marks, from-price), one tap chooses and closes.
class PlanPackagePicker extends ConsumerWidget {
  const PlanPackagePicker({required this.tiers, super.key});

  final List<PlannerTier> tiers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final chosen = ref.watch(plannerTierProvider);
    final pkgs = ref.watch(plannerPackagesProvider).value ?? const [];
    final byTier = {for (final p in pkgs) p.tier: p};
    final nav = context.gzNav;
    return Column(
      key: const ValueKey<String>('planner.picker'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: GzSheetHeader(title: l.clientPlannerTierPickerLabel, onClose: nav.closeSheet),
        ),
        Semantics(
          container: true,
          label: l.clientPlannerTierPickerLabel,
          child: Column(
            children: [
              for (final tier in tiers) ...[
                if (byTier[tier] != null)
                  GzPressable(
                    key: ValueKey<String>('planner.pick.${tier.value}'),
                    onPressed: () {
                      ref.read(plannerTierProvider.notifier).set(tier);
                      nav.closeSheet();
                    },
                    semanticLabel: tier == chosen
                        ? l.clientPlannerCompareChosen(byTier[tier]!.name.of(lang))
                        : l.clientPlannerCompareChoose(byTier[tier]!.name.of(lang)),
                    selected: tier == chosen,
                    minWidth: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: SizedBox.square(
                              dimension: GzSize.avatarMd,
                              child: GzPhoto(src: tierPhotoSrc(tier), alt: '', borderRadius: GzRadius.smAll),
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
                                      child: GzText(byTier[tier]!.name.of(lang), role: GzTextRole.d1, color: c.textStrong),
                                    ),
                                    const SizedBox(width: GzSpace.s2),
                                    TierMarks(count: byTier[tier]!.marks, label: l.clientPlannerMarks(byTier[tier]!.marks)),
                                  ],
                                ),
                                const SizedBox(height: GzSpace.s1),
                                GzPrice(fils: byTier[tier]!.from.fils, size: GzPriceSize.card, prefix: l.clientPlannerFromPrefix),
                              ],
                            ),
                          ),
                          if (tier == chosen) const GzBeadBox(),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
