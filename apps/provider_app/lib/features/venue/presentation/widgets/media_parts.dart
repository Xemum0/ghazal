// The media manager's local pieces (web `Media.tsx`): the upload queue row, the attention panel, the filtered grid, the video row and the zone
// picker. The photo and video sheets are in `media_sheets.dart`.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/media_state.dart';
import 'venue_labels.dart';

/// `m:ss` of a video length from the formatter's own digits.
String clockOf(BuildContext context, int seconds) {
  final f = context.gzFormat;
  final s = seconds % 60;
  return '${f.integer(seconds ~/ 60)}:${s < 10 ? f.integer(0) : ''}${f.integer(s)}';
}

String? posterSrc(ImageRef? i) => i == null ? null : gzImageSrc(i.file, i.baseUrl);

/// A photo-sized thumbnail that falls back to a glyph when the item has no picture (a video the mock stores without a poster).
class MediaThumb extends StatelessWidget {
  const MediaThumb({required this.src, required this.icon, this.alt = '', super.key});

  final String? src;
  final IconData icon;
  final String alt;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final s = src;
    return ColoredBox(
      color: c.surfacePlaceholder,
      child: s == null ? Center(child: GzIcon(icon, size: GzIconSize.md, color: c.iconSecondary)) : GzPhoto(src: s, alt: alt),
    );
  }
}

// ---------------------------------------------------------------- upload queue

class UploadRow extends StatelessWidget {
  const UploadRow({required this.item, this.onRetry, super.key});

  final UploadItem item;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final failed = item.status == UploadStatus.failed;
    final queued = item.status == UploadStatus.queued;
    final pct = item.kind == MediaKind.video ? 35 : 60;
    final status = failed ? l.hotelVenueUploadFailed : queued ? l.hotelVenueUploadQueued : l.hotelVenueUploading(context.gzFormat.percent(pct));
    return Semantics(
      container: true,
      label: '${item.label.of(lang)}. $status',
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: GzRadius.smAll,
              child: SizedBox(
                width: GzSize.thumbMd,
                height: GzSize.thumbMd,
                child: MediaThumb(src: posterSrc(item.poster), icon: item.kind == MediaKind.video ? GzIcons.video : GzIcons.image),
              ),
            ),
            const SizedBox(width: GzSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzText(item.label.of(lang), role: GzTextRole.title, color: c.textStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (!failed && !queued) ...[
                    const SizedBox(height: GzSpace.s1),
                    _Thread(percent: pct, label: l.hotelVenueUploadingLabel),
                  ],
                  const SizedBox(height: GzSpace.s1),
                  Row(
                    children: [
                      GzIcon(failed ? GzIcons.warningCircle : queued ? GzIcons.offline : GzIcons.upload, size: GzIconSize.xs, color: failed ? c.iconDanger : c.iconSecondary),
                      const SizedBox(width: GzSpace.s1),
                      Expanded(
                        child: GzText(status, role: GzTextRole.caption, color: failed ? c.textDanger : c.textSecondary, figures: true),
                      ),
                    ],
                  ),
                  if (failed)
                    GzButton(label: l.hotelVenueUploadRetry, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: onRetry),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The progress line: a gold thread over the track, fill and rest share the width by flex.
class _Thread extends StatelessWidget {
  const _Thread({required this.percent, required this.label});

  final int percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      label: label,
      value: '$percent',
      child: ClipRRect(
        borderRadius: GzRadius.pillAll,
        child: SizedBox(
          height: GzStroke.thread,
          child: Row(
            children: [
              Expanded(flex: percent, child: ColoredBox(color: c.markKhayt, child: const SizedBox.expand())),
              Expanded(flex: 100 - percent, child: ColoredBox(color: c.markTrack, child: const SizedBox.expand())),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- attention

/// The one thing that needs a person: photos that moderation did not approve.
class AttentionPanel extends StatelessWidget {
  const AttentionPanel({required this.rejected, required this.onRejected, super.key});

  final int rejected;
  final VoidCallback onRejected;

  @override
  Widget build(BuildContext context) {
    if (rejected == 0) return const SizedBox.shrink();
    final c = context.gz.colors;
    final title = context.l10n.hotelVenueAttentionRejected(rejected);
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      // Flow-local row: GzListRow's title is a plain string, the web title is a `Figures` run (the count is a figures island; request filed).
      child: GzPressable(
        onPressed: onRejected,
        semanticLabel: title,
        scale: 1,
        minHeight: 0,
        child: Container(
          constraints: const BoxConstraints(minHeight: GzSize.rowMin),
          padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
          // The web row keeps its 1 px rule box under a `last` row (transparent): the panel is that much taller.
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.scrimClear, width: GzStroke.hair))),
          child: Row(
            children: [
              Container(
                width: GzSize.controlSm,
                height: GzSize.controlSm,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.statusDangerBg, shape: BoxShape.circle),
                child: GzIcon(GzIcons.warningCircle, size: GzIconSize.md, color: c.iconDanger),
              ),
              const SizedBox(width: GzSpace.s4),
              Expanded(child: GzText(title, role: GzTextRole.title, color: c.textStrong, figures: true)),
              const SizedBox(width: GzSpace.s4),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- filtered grid

/// The grid of a filtered view: three 4:5 columns 8 apart; marks the real cover only (the shared grid marks its first tile).
class FilteredGrid extends StatelessWidget {
  const FilteredGrid({required this.items, required this.coverId, required this.onOpen, this.onReplace, super.key});

  final List<GzPhotoTile> items;
  final String? coverId;
  final ValueChanged<String> onOpen;
  final ValueChanged<String>? onReplace;

  @override
  Widget build(BuildContext context) {
    final rows = <List<GzPhotoTile>>[for (var i = 0; i < items.length; i += 3) items.sublist(i, i + 3 > items.length ? items.length : i + 3)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: GzSpace.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: col < rows[r].length
                      ? _Cell(tile: rows[r][col], cover: rows[r][col].id == coverId, onOpen: onOpen, onReplace: onReplace)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.tile, required this.cover, required this.onOpen, this.onReplace});

  final GzPhotoTile tile;
  final bool cover;
  final ValueChanged<String> onOpen;
  final ValueChanged<String>? onReplace;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final rejected = tile.status == GzPhotoStatus.rejected;
    final zone = zoneLabel(l, tile.zone, short: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: GzLayout.aspect4x5,
          child: Container(
            foregroundDecoration: rejected ? BoxDecoration(borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderError, width: GzStroke.icon)) : null,
            decoration: BoxDecoration(color: c.surfacePlaceholder, borderRadius: GzRadius.mdAll),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GzPressable(
                  onPressed: () => onOpen(tile.id),
                  semanticLabel: '${zoneLabel(l, tile.zone)}: ${tile.alt.of(lang)}',
                  minWidth: 0,
                  minHeight: 0,
                  child: GzPhoto(src: tile.src),
                ),
                PositionedDirectional(
                  top: GzSpace.s2,
                  start: GzSpace.s2,
                  end: GzSpace.s2,
                  child: IgnorePointer(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
                        decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.xsAll),
                        child: GzText(zone, role: GzTextRole.caption, color: c.textStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
                if (tile.status != GzPhotoStatus.live || cover)
                  PositionedDirectional(
                    bottom: GzSpace.s2,
                    start: GzSpace.s2,
                    end: GzSpace.s2,
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tile.status == GzPhotoStatus.review) GzStatusPill(status: GzStatus.requested, audience: GzStatusAudience.hotel, label: l.hotelVenueStatusReview),
                          if (rejected) GzStatusPill(status: GzStatus.rejected, audience: GzStatusAudience.hotel, label: l.hotelVenueStatusRejected),
                          if (cover) ...[
                            if (tile.status != GzPhotoStatus.live) const SizedBox(height: GzSpace.s1),
                            Container(
                              constraints: const BoxConstraints(minHeight: GzSize.pillMin),
                              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
                              decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.xsAll),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GzIcon(GzIcons.image, size: GzIconSize.xs, color: c.iconPrimary),
                                  const SizedBox(width: GzSpace.s1),
                                  Flexible(child: GzText(l.hotelVenueCover, role: GzTextRole.pill, color: c.textStrong)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (rejected)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
              child: GzButton(label: l.hotelVenueReplaceShort, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: () => onReplace?.call(tile.id)),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- videos

class VideoRow extends StatelessWidget {
  const VideoRow({required this.video, required this.onOpen, super.key});

  final MediaItem video;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final title = video.image?.alt.of(lang) ?? l.hotelVenueNewVideoTitle;
    final review = video.status == MediaStatus.processing;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
      ),
      child: GzPressable(
        onPressed: onOpen,
        semanticLabel: l.hotelVenueVideoOpen(title),
        minHeight: GzSize.rowQueue,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: GzRadius.smAll,
                child: SizedBox(
                  width: GzSize.thumbLg,
                  child: AspectRatio(
                    aspectRatio: GzLayout.aspect16x10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MediaThumb(src: posterSrc(video.image), icon: GzIcons.video),
                        Center(
                          child: Container(
                            width: GzSize.disk,
                            height: GzSize.disk,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.surfaceCanvas, shape: BoxShape.circle),
                            child: GzIcon(GzIcons.play, size: GzIconSize.sm, color: c.iconPrimary),
                          ),
                        ),
                        PositionedDirectional(
                          bottom: GzSpace.s1,
                          end: GzSpace.s1,
                          child: Container(
                            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
                            decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.xsAll),
                            child: GzText(clockOf(context, video.durationSeconds ?? 0), role: GzTextRole.pill, color: c.textStrong, figures: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: GzSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzText(title, role: GzTextRole.title, color: c.textStrong),
                    const SizedBox(height: GzSpace.s1),
                    review
                        ? GzStatusPill(status: GzStatus.requested, audience: GzStatusAudience.hotel, label: l.hotelVenueStatusReview)
                        : GzStatusPill(status: GzStatus.available, audience: GzStatusAudience.hotel, label: l.hotelVenueStatusLive),
                  ],
                ),
              ),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary, mirror: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- zone picker

/// Zone chips with the required mark: every photo is tagged by zone before it goes up.
class ZonePicker extends StatelessWidget {
  const ZonePicker({required this.value, required this.onChanged, super.key});

  final MediaZone? value;
  final ValueChanged<MediaZone> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: GzText(l.hotelVenueFieldZone, role: GzTextRole.label, color: c.textSecondary)),
            GzText(l.hotelVenueRequired, role: GzTextRole.caption, color: c.textSecondary),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        GzChipGroup<MediaZone>(
          label: l.hotelVenueFieldZone,
          value: value,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          options: [for (final z in kZones) GzChipOption<MediaZone>(value: z, label: zoneLabel(l, z))],
        ),
      ],
    );
  }
}
