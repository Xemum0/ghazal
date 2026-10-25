import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'bk_common.dart';

/// The quiet counter of open requests: a ruled strip, `[send] 1/3` at start, three beads at end (gold = an open request).
class BookingsLimitStrip extends StatelessWidget {
  const BookingsLimitStrip({required this.used, required this.limit, super.key});

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final hair = BorderSide(color: c.borderHairline, width: GzStroke.hair);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: GzSize.rowMin),
          padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
          decoration: BoxDecoration(
            border: Border(top: hair, bottom: hair),
          ),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GzFactChip(icon: GzIcons.send, label: l.clientBookingsLimitLabel, value: '${f.integer(used)}/${f.integer(limit)}'),
                ),
              ),
              const SizedBox(width: GzSpace.s4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < limit; i++) ...[
                    if (i > 0) const SizedBox(width: GzSpace.s2),
                    GzThreadBead(tone: i < used ? GzBeadTone.gold : GzBeadTone.hollow),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (used >= limit)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzIcon(GzIcons.info, size: GzIconSize.xs, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s2),
                  Expanded(
                    child: GzText(l.clientBookingsLimitReached, role: GzTextRole.caption, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The skeleton of the list: two request cards.
class BookingsListSkeleton extends StatelessWidget {
  const BookingsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    Widget card() => Container(
      padding: GzSpace.panel,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 56, blockSize: 56),
              SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzSkeleton(inlineSize: 180, blockSize: 28),
                    SizedBox(height: GzSpace.s1),
                    GzSkeleton(inlineSize: 120, blockSize: 20),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: GzSpace.s4),
          GzSkeleton(inlineSize: 96, blockSize: 24),
          SizedBox(height: GzSpace.s4),
          SizedBox(width: double.infinity, child: GzSkeleton(blockSize: 20)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(GzSpace.gutter, GzSpace.s4, GzSpace.gutter, GzSpace.section),
      child: BkGap(children: [card(), card()]),
    );
  }
}
