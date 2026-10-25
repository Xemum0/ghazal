import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show SearchBrief;
import '../../../../l10n/l10n.dart';
import '../../application/saved_data.dart';
import 'saved_parts.dart';

/// The Brief echo of the Compare screen as facts (ADR 0034): the section symbol, the guests and the date as icon + value, and the pencil;
/// the whole row is one 44 button that opens the Brief sheet. Flow-local (a system `BriefFacts` is requested).
class CompareBriefFacts extends StatelessWidget {
  const CompareBriefFacts({required this.brief, this.onEdit, super.key});

  final SearchBrief brief;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final (icon, name) = switch (brief.audience) {
      Audience.women => (GzIcons.sectionWomen, l.clientSavedCompareFactWomen),
      Audience.men => (GzIcons.sectionMen, l.clientSavedCompareFactMen),
      Audience.mixed => (GzIcons.sectionMixed, l.clientSavedCompareFactMixed),
      _ => (null, ''),
    };
    // Web `.svd-echo`: a 44 target with 4 above and 8 below (56 in all).
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s1, bottom: GzSpace.s2),
      child: GzPressable(
        key: const ValueKey<String>('compare.brief'),
        onPressed: onEdit,
        semanticLabel: l.clientSavedCompareFactEdit,
        borderRadius: GzRadius.smAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: GzSpace.s3,
                  runSpacing: GzSpace.s2,
                  children: [
                    if (icon != null) GzFactChip(icon: icon, label: name),
                    if (brief.guests != null)
                      GzFactChip(icon: GzIcons.usersThree, label: l.clientSavedCompareFactGuests, value: f.integer(brief.guests!)),
                    if (brief.date != null)
                      GzFactChip(
                        icon: GzIcons.calendar,
                        label: l.clientSavedCompareFactDate,
                        value: f.date(brief.date.toString(), DateStyle.dayMonth),
                      ),
                  ],
                ),
              ),
              GzIcon(GzIcons.edit, size: GzIconSize.sm, color: c.iconSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fewer than two halls: the one hall that is in, the drawing and the way back to add another.
class CompareFewer extends ConsumerWidget {
  const CompareFewer({required this.venueId, required this.onBrowse, super.key});

  final String? venueId;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final row = venueId == null ? null : ref.watch(briefRosterProvider).value?[venueId];
    final area = row == null ? null : ref.watch(savedAreaNamesProvider).value?[row.venue.areaId];
    return Column(
      key: const ValueKey<String>('compare.fewer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (row != null)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
            child: Row(
              children: [
                SavedThumb(venue: row.venue, width: GzSize.avatarMd, height: GzSize.thumbLg),
                const SizedBox(width: GzSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GzText(row.venue.name.of(lang), role: GzTextRole.d1, color: c.textStrong, maxLines: 2),
                      if (area != null) GzText(area.of(lang), role: GzTextRole.caption, color: c.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        GzEmptyState(
          illustration: GzIllustrationName.onboardCompare,
          title: l.clientSavedCompareCompareFewerTitle,
          action: GzStateAction(label: l.clientSavedCompareCompareFewerAction, variant: GzButtonVariant.primary, onPressed: onBrowse),
          fill: false,
          size: GzIllustrationSize.hero,
        ),
      ],
    );
  }
}

/// Header and a few rows as static shapes in the same thirds: no shimmer, nothing loops.
class CompareSkeleton extends StatelessWidget {
  const CompareSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(GzSpace.s2),
                      child: Column(
                        children: [
                          GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120),
                          SizedBox(height: GzSpace.s2),
                          GzSkeleton(blockSize: 24),
                          SizedBox(height: GzSpace.s2),
                          GzSkeleton(inlineSize: 64, blockSize: 20),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            for (var r = 0; r < 5; r++)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzSkeleton(inlineSize: 96, blockSize: 16),
                    SizedBox(height: GzSpace.s2),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Expanded(
                            child: Padding(padding: EdgeInsets.all(GzSpace.s1), child: GzSkeleton(blockSize: 24)),
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

/// The key of the compare table (ADR 0034): the few marks a shape does not explain, one glyph and one word each, behind the info glyph.
class CompareKeySheet extends StatelessWidget {
  const CompareKeySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final nav = context.gzNav;
    final rows = <(Widget, String)>[
      (const GzThreadBead(), l.clientSavedCompareKeyBest),
      (GzIcon(GzIcons.starFill, size: GzIconSize.sm, color: c.iconAccent, mirror: false), l.clientSavedCompareCompareBadgeRated),
      (GzIcon(GzIcons.offer, size: GzIconSize.sm, color: c.iconPrimary, mirror: false), l.clientSavedCompareCompareBadgeLowest),
      (GzIcon(GzIcons.navigate, size: GzIconSize.sm, color: c.iconPrimary, mirror: false), l.clientSavedCompareCompareBadgeClosest),
      (GzIcon(GzIcons.trendDown, size: GzIconSize.sm, color: c.statusSuccessText, mirror: false), l.clientSavedCompareKeySave),
      (GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.statusSuccessText, mirror: false), l.clientSavedCompareCompareValIncluded),
      (GzIcon(GzIcons.coins, size: GzIconSize.sm, color: c.iconAccent, mirror: false), l.clientSavedCompareCompareValExtra),
      (GzIcon(GzIcons.minus, size: GzIconSize.sm, color: c.textDisabled, mirror: false), l.clientSavedCompareCompareValNotOffered),
      (GzIcon(GzIcons.ticket, size: GzIconSize.sm, color: c.iconPrimary, mirror: false), l.clientSavedCompareCompareActionVoucher),
      (GzIcon(GzIcons.bank, size: GzIconSize.sm, color: c.iconPrimary, mirror: false), l.clientSavedCompareCompareActionOfficial),
    ];
    return Column(
      key: const ValueKey<String>('compare.key'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: GzSheetHeader(title: l.clientSavedCompareKeyTitle, onClose: nav.closeSheet),
        ),
        for (final r in rows)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: GzSize.disk,
                    child: Center(child: r.$1),
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzText(r.$2, role: GzTextRole.title)),
              ],
            ),
          ),
      ],
    );
  }
}
