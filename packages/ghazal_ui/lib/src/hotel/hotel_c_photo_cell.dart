import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show GalleryItem, LocalizedText, MediaZone;

import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';

/// The moderation state of a listing photo.
enum GzPhotoStatus { live, review, rejected }

/// One photo of the listing in the photo manager: an id, the image descriptor, its alt text, its zone tag and its status.
@immutable
class GzPhotoTile {
  const GzPhotoTile({required this.id, required this.src, required this.alt, required this.zone, this.status = GzPhotoStatus.live});

  /// A gallery item of the venue (`id` defaults to its file name, the web tile id).
  factory GzPhotoTile.fromGallery(GalleryItem g, {String? id, GzPhotoStatus status = GzPhotoStatus.live}) =>
      GzPhotoTile(id: id ?? g.file, src: g.baseUrl ?? g.file, alt: g.alt, zone: g.zone, status: status);

  final String id;

  /// The `GzPhoto` descriptor (`asset://...`, `https://...`, or a bundled file name).
  final String src;
  final LocalizedText alt;
  final MediaZone zone;
  final GzPhotoStatus status;
}

/// The zone word of a tile (`uiHotelPhotos<Zone>`).
String gzZoneLabel(GzL10n l, MediaZone zone) => switch (zone) {
  MediaZone.hall => l.uiHotelPhotosHall,
  MediaZone.stageKosha => l.uiHotelPhotosStageKosha,
  MediaZone.bridalSuite => l.uiHotelPhotosBridalSuite,
  MediaZone.buffet => l.uiHotelPhotosBuffet,
  MediaZone.outdoors => l.uiHotelPhotosOutdoors,
  MediaZone.entranceValet => l.uiHotelPhotosEntranceValet,
  MediaZone.layout => l.uiHotelPhotosLayout,
  MediaZone.unknown => '',
};

/// What the grid says about one cell.
class GzPhotoCellState {
  const GzPhotoCellState({
    required this.index,
    required this.total,
    this.reorder = false,
    this.selected = false,
    this.highlighted = false,
    this.dimmed = false,
    this.lifted = false,
  });

  final int index;
  final int total;
  final bool reorder;

  /// Chosen for Make cover / Delete.
  final bool selected;

  /// A dragged photo hovers over this cell.
  final bool highlighted;

  /// This cell's photo is the one being dragged (it leaves a quiet hole).
  final bool dimmed;

  /// The drag feedback: the same tile without controls, lifted.
  final bool lifted;
}

/// The photo cell of the manager (`.gz-pmg__tile`): a 4:5 cell with the photo, the zone tag, the status / cover chips and, in reorder
/// mode, the drag [grip] and the two Move buttons.
class GzPhotoCell extends StatelessWidget {
  const GzPhotoCell({required this.tile, required this.cell, this.image, this.onTap, this.onMove, this.grip, super.key});

  final GzPhotoTile tile;
  final GzPhotoCellState cell;
  final ImageProvider? image;
  final VoidCallback? onTap;
  final void Function(int by)? onMove;

  /// The drag handle (a 44 dp target holding the 32 disk), supplied by the grid in reorder mode.
  final Widget? grip;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final n = context.gzFormat.integer(cell.index + 1);
    final zone = gzZoneLabel(l, tile.zone);
    final rejected = tile.status == GzPhotoStatus.rejected;
    final isCover = cell.index == 0;
    final alt = tile.alt.of(lang);
    final photo = image != null ? GzPhoto.provider(image: image!, alt: alt, fadeIn: false) : GzPhoto(src: tile.src, alt: alt);
    final inner = Stack(
      fit: StackFit.expand,
      children: [
        GzPressable(
          onPressed: cell.reorder || cell.lifted ? null : (onTap ?? () {}),
          semanticLabel: l.uiHotelPhotosOpen(n, zone),
          selected: cell.selected ? true : null,
          borderRadius: GzRadius.mdAll,
          minWidth: 0,
          minHeight: 0,
          child: photo,
        ),
        PositionedDirectional(
          top: GzSpace.s2,
          start: GzSpace.s2,
          end: GzSpace.s2,
          child: IgnorePointer(
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: GzSpace.s2),
                    decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.xsAll),
                    child: GzText(
                      zone,
                      role: GzTextRole.caption,
                      color: c.textStrong,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (tile.status != GzPhotoStatus.live || isCover)
          PositionedDirectional(
            bottom: cell.reorder ? GzSpace.s12 : GzSpace.s2,
            start: GzSpace.s2,
            end: GzSpace.s2,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tile.status != GzPhotoStatus.live)
                    // the web pill keeps its natural width and the cell clips it (a long Arabic label is wider than the 8 dp insets allow)
                    SizedBox(
                      height: 30, // the pill's own height (20 line + 2 x 5)
                      child: OverflowBox(
                        alignment: AlignmentDirectional.topStart,
                        minWidth: 0,
                        maxWidth: double.infinity,
                        child: GzStatusPill(
                          status: tile.status == GzPhotoStatus.review ? GzStatus.requested : GzStatus.rejected,
                          label: tile.status == GzPhotoStatus.review ? l.uiHotelPhotosReview : l.uiHotelPhotosRejected,
                        ),
                      ),
                    ),
                  if (tile.status != GzPhotoStatus.live && isCover) const SizedBox(height: GzSpace.s1),
                  if (isCover) _CoverChip(label: l.uiHotelPhotosCover),
                ],
              ),
            ),
          ),
        if (cell.reorder && !cell.lifted) ...[
          if (grip != null) PositionedDirectional(top: GzSpace.s2 - 6, end: GzSpace.s2 - 6, child: grip!),
          PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GzIconButton(
                  variant: GzIconButtonVariant.overImage,
                  icon: GzIcons.chevronLeft,
                  label: l.uiHotelPhotosEarlier(n),
                  onPressed: cell.index == 0 ? null : () => onMove?.call(-1),
                ),
                GzIconButton(
                  variant: GzIconButtonVariant.overImage,
                  icon: GzIcons.chevronRight,
                  label: l.uiHotelPhotosLater(n),
                  onPressed: cell.index == cell.total - 1 ? null : () => onMove?.call(1),
                ),
              ],
            ),
          ),
        ],
        if (cell.dimmed) Positioned.fill(child: ColoredBox(color: c.surfaceCanvas.withAlpha(166))),
        if (cell.selected || cell.highlighted)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: GzRadius.mdAll,
                  border: Border.all(color: c.borderFocus, width: GzStroke.focus),
                ),
              ),
            ),
          ),
      ],
    );
    final box = AspectRatio(
      aspectRatio: GzLayout.aspect4x5,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfacePlaceholder,
          borderRadius: GzRadius.mdAll,
          border: rejected ? Border.all(color: c.borderError, width: GzStroke.icon) : null,
          boxShadow: cell.lifted ? GzElevation.e2 : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: inner,
      ),
    );
    return box;
  }
}

/// The drag handle disk of reorder mode: 32 canvas disk with the grip glyph.
class GzPhotoGripDisk extends StatelessWidget {
  const GzPhotoGripDisk({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      width: GzSize.disk,
      height: GzSize.disk,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceCanvas),
      child: GzIcon(GzIcons.dragHandle, size: GzIconSize.xs, color: c.iconPrimary),
    );
  }
}

class _CoverChip extends StatelessWidget {
  const _CoverChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.pillMin),
      padding: const EdgeInsets.symmetric(horizontal: GzSpace.s2),
      decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.xsAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(GzIcons.image, size: GzIconSize.xs, color: c.textStrong),
          const SizedBox(width: GzSpace.s1),
          GzText(label, role: GzTextRole.pill, color: c.textStrong, softWrap: false),
        ],
      ),
    );
  }
}
