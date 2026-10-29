import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show VenueResult;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/saved_data.dart';
import 'widgets/saved_parts.dart';

/// The winter-rate hall of the story: the incoming hall when the sheet opens with no params (a harness, a direct visit).
const String kReplaceDefaultIncoming = 'V09';

/// CL-SAVD-03 Replace which one? (sheet). Covers CA-CMP-02, CA-CMP-01.
///
/// Shown on the fourth add: Compare holds three halls, so nothing is dropped silently and the family picks which one to swap. The incoming
/// hall sits in a rose-tint card with the swap glyph above the three halls it can replace; each is a choice (an ink ring and a check, never
/// gold), choosing one replaces it, shows the check for a beat and closes the sheet. The header's close glyph leaves the set as it was.
class ClSavd03Screen extends ConsumerStatefulWidget {
  const ClSavd03Screen({super.key});

  @override
  ConsumerState<ClSavd03Screen> createState() => _ClSavd03ScreenState();
}

class _ClSavd03ScreenState extends ConsumerState<ClSavd03Screen> {
  String? _chosen;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _incomingId {
    final p = context.gzNav.params;
    final v = p['incoming'] ?? p['newId'];
    return v is String && v.isNotEmpty ? v : kReplaceDefaultIncoming;
  }

  void _choose(String oldId, String newId, String? incomingName) {
    if (_chosen != null) return;
    setState(() => _chosen = oldId);
    ref.read(compareProvider.notifier).replace(oldId, newId);
    final nav = context.gzNav;
    final done = context.l10n.clientSavedCompareReplaceDone;
    _timer = Timer(GzMotion.durationSlow, () {
      nav.closeSheet();
      if (incomingName != null) nav.toast(GzToastSpec(message: done, tone: GzToastTone.success));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final nav = context.gzNav;
    final ids = ref.watch(compareProvider.select((s) => s.venueIds));
    final roster = ref.watch(briefRosterProvider);
    final areas = ref.watch(savedAreaNamesProvider).value ?? const {};
    final incomingId = _incomingId;
    final byId = roster.value ?? const <String, VenueResult>{};
    final incoming = byId[incomingId];
    final rows = [
      for (final id in ids.take(kCompareMax))
        if (byId[id] != null) byId[id]!,
    ];
    final name = incoming?.venue.name.of(lang);
    return Column(
      key: const ValueKey<String>('saved.replace'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: GzSheetHeader(title: l.clientSavedCompareReplaceTitle, onClose: nav.closeSheet),
        ),
        Semantics(label: l.clientSavedCompareReplaceBody(kCompareMax, name ?? ''), child: const SizedBox.shrink()),
        const SizedBox(height: GzSpace.s4),
        if (roster.isLoading && !roster.hasValue)
          const Padding(
            padding: EdgeInsetsDirectional.only(bottom: GzSpace.s4),
            child: Column(
              children: [
                GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 88),
                SizedBox(height: GzSpace.s3),
                GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 88),
              ],
            ),
          )
        else ...[
          if (incoming != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
              child: Semantics(
                container: true,
                label: name,
                child: DecoratedBox(
                  key: const ValueKey<String>('saved.replace.new'),
                  decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
                  child: Padding(
                    padding: const EdgeInsets.all(GzSpace.s3),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: SavedThumb(venue: incoming.venue, width: GzSize.avatarMd, height: GzSize.thumbLg),
                        ),
                        const SizedBox(width: GzSpace.s4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GzText(name!, role: GzTextRole.d1, color: c.textStrong, maxLines: 2),
                              if (areas[incoming.venue.areaId] != null) ...[
                                const SizedBox(height: GzSpace.s1),
                                GzText(areas[incoming.venue.areaId]!.of(lang), role: GzTextRole.caption, color: c.textSecondary),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: GzSpace.s4),
                        ExcludeSemantics(
                          child: DecoratedBox(
                            decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceCanvas),
                            child: SizedBox.square(
                              dimension: GzSize.disk,
                              child: Center(
                                child: GzIcon(GzIcons.swap, size: GzIconSize.md, color: c.iconPrimary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Semantics(
            container: true,
            label: l.clientSavedCompareReplaceTitle,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: GzSpace.s3),
                  GzVenueCard(
                    key: ValueKey<String>('saved.replace.row.${rows[i].venue.id}'),
                    variant: GzVenueCardVariant.compare,
                    venue: rows[i].venue,
                    area: areas[rows[i].venue.areaId],
                    price: rows[i].price,
                    selected: _chosen == rows[i].venue.id,
                    onSelect: () => _choose(rows[i].venue.id, incomingId, name),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
