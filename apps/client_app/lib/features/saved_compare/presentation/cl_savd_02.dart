import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show VenueResult;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/saved_data.dart';
import 'widgets/saved_parts.dart';

/// CL-SAVD-02 Compare tray (sheet). Covers CA-CMP-01, CA-CMP-03, CA-CMP-11, CA-CMP-12.
///
/// The tray as a sheet (what the header badge of Venue detail opens, so the tray never covers the sticky price bar): the set as up to three
/// rows with a remove control each, one hairline empty slot while only one hall is in, and the one action, Compare, which says what is
/// missing when it cannot act. Nothing here nags: no push, no re-prompt after Clear.
class ClSavd02Screen extends ConsumerWidget {
  const ClSavd02Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final nav = context.gzNav;
    final ids = ref.watch(compareProvider.select((s) => s.venueIds));
    final roster = ref.watch(briefRosterProvider);
    final areas = ref.watch(savedAreaNamesProvider).value ?? const {};
    final byId = roster.value ?? const <String, VenueResult>{};
    final loading = roster.isLoading && !roster.hasValue;
    final rows = [
      for (final id in ids.take(kCompareMax))
        if (byId[id] != null) byId[id]!,
    ];
    final ready = rows.length >= 2;
    final empties = loading ? 0 : (kCompareMax - rows.length).clamp(0, 1);
    return Column(
      key: const ValueKey<String>('saved.tray'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: GzSheetHeader(title: l.clientSavedCompareTrayTitle, onClose: nav.closeSheet),
        ),
        const SizedBox(height: GzSpace.s3),
        if (loading)
          for (var i = 0; i < ids.length.clamp(1, kCompareMax); i++)
            const Padding(
              padding: EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
              child: GzSkeleton(variant: GzSkeletonVariant.block, blockSize: GzSize.thumbLg),
            )
        else
          for (final r in rows)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
                  child: Row(
                    key: ValueKey<String>('saved.tray.row.${r.venue.id}'),
                    children: [
                      ExcludeSemantics(
                        child: SavedThumb(venue: r.venue, width: GzSize.avatarMd, height: GzSize.thumbLg),
                      ),
                      const SizedBox(width: GzSpace.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GzText(r.venue.name.of(lang), role: GzTextRole.d1, color: c.textStrong, maxLines: 2),
                            if (areas[r.venue.areaId] != null) ...[
                              const SizedBox(height: GzSpace.s1),
                              GzText(areas[r.venue.areaId]!.of(lang), role: GzTextRole.caption, color: c.textSecondary),
                            ],
                            if (r.price != null) ...[
                              const SizedBox(height: GzSpace.s1),
                              GzCardPriceLine(price: r.price!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: GzSpace.s4),
                      GzIconButton(
                        key: ValueKey<String>('saved.tray.remove.${r.venue.id}'),
                        icon: GzIcons.close,
                        label: l.clientSavedCompareTrayRemove(r.venue.name.of(lang)),
                        onPressed: () => ref.read(compareProvider.notifier).remove(r.venue.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        for (var i = 0; i < empties; i++)
          Semantics(
            label: l.clientSavedCompareTrayAddOne,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.rowMin),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: GzRadius.smAll,
                          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
                        ),
                        child: SizedBox(
                          width: GzSize.avatarMd,
                          height: GzSize.thumbLg,
                          child: Center(
                            child: GzIcon(GzIcons.plus, size: GzIconSize.sm, color: c.iconSecondary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: GzSpace.s6),
        GzButton(
          key: const ValueKey<String>('saved.tray.compare'),
          label: l.clientSavedCompareTrayAction(rows.isEmpty ? ids.length : rows.length),
          fullWidth: true,
          onPressed: ready
              ? () {
                  nav.closeSheet();
                  nav.push('CL-SAVD-04');
                }
              : null,
          reason: ready || loading ? null : l.clientSavedCompareTrayAddOne,
        ),
        const SizedBox(height: GzSpace.s2),
        Center(
          child: GzButton(
            key: const ValueKey<String>('saved.tray.clear'),
            label: context.gzL10n.commonActionClear,
            variant: GzButtonVariant.tertiary,
            onPressed: () {
              ref.read(compareProvider.notifier).clear();
              nav.closeSheet();
            },
          ),
        ),
      ],
    );
  }
}
