// HL-VENU-01 Photos and videos (web `HL-VENU-01.tsx`): upload, reorder, set the cover, tag by zone and delete the listing's photos and videos.
// Empty rooms and details only (the face check is in the upload sheet); video uploads continue in the background.
// Requirements: HA-VMGT-01, HA-VMGT-02, HA-VMGT-09, HA-AUTH-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/media_state.dart';
import '../application/venue_data.dart';
import 'widgets/media_parts.dart';
import 'widgets/media_sheets.dart';
import 'widgets/venue_bits.dart' show toastResult;
import 'widgets/venue_labels.dart';

enum _Tab { photos, videos }

const String _all = 'all';
const String _review = 'review';
const String _rejected = 'rejected';

GzPhotoStatus _statusOf(MediaStatus s) => switch (s) {
  MediaStatus.processing => GzPhotoStatus.review,
  MediaStatus.rejected => GzPhotoStatus.rejected,
  _ => GzPhotoStatus.live,
};

class HlVenu01Screen extends ConsumerStatefulWidget {
  const HlVenu01Screen({super.key});

  @override
  ConsumerState<HlVenu01Screen> createState() => _HlVenu01ScreenState();
}

class _HlVenu01ScreenState extends ConsumerState<HlVenu01Screen> {
  _Tab _tab = _Tab.photos;

  /// One filter at a time: everything, the photos under review, the ones that need replacing, or one zone (its wire value).
  String _view = _all;
  bool _reorder = false;

  void _openAdd() {
    final l = context.l10n;
    final video = _tab == _Tab.videos;
    GzNavigatorScope.of(context).openSheetBuilder(
      (_) => UploadSheet(kind: video ? MediaKind.video : MediaKind.photo),
      options: GzSheetOptions(title: video ? l.hotelVenueAddVideoTitle : l.hotelVenueAddPhotoTitle),
    );
  }

  void _openTile(String id) =>
      GzNavigatorScope.of(context).openSheetBuilder((_) => TileSheet(photoId: id), options: GzSheetOptions(title: context.l10n.hotelVenuePhotoSheetTitle));

  void _replace(String id) =>
      GzNavigatorScope.of(context).openSheetBuilder((_) => UploadSheet(replaceId: id), options: GzSheetOptions(title: context.l10n.hotelVenueReplaceTitle));

  Future<void> _move(List<GzPhotoTile> tiles, String id, int to) async {
    final ids = [for (final t in tiles) t.id];
    final from = ids.indexOf(id);
    if (from < 0) return;
    final target = to.clamp(0, ids.length - 1);
    if (target == from) return;
    ids
      ..removeAt(from)
      ..insert(target, id);
    final res = await ref.read(venueActionsProvider.notifier).reorder(ids);
    if (!mounted) return;
    toastResult(context, res);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final value = ref.watch(venueMediaProvider);
    final uploads = ref.watch(venueUploadsProvider);
    final venueName = ref.watch(partnerVenueProvider).value?.venue.name.of(lang);
    final lib = value.value;
    final photosAll = [
      for (final m in lib?.items ?? const <MediaItem>[])
        if (m.kind == MediaKind.photo && m.image != null) m,
    ];
    final videos = [
      for (final m in lib?.items ?? const <MediaItem>[])
        if (m.kind == MediaKind.video) m,
    ];
    final photoUploads = [
      for (final u in uploads)
        if (u.kind == MediaKind.photo) u,
    ];
    final videoUploads = [
      for (final u in uploads)
        if (u.kind == MediaKind.video) u,
    ];
    final empty = _tab == _Tab.photos && photosAll.isEmpty && photoUploads.isEmpty;
    final loaded = lib != null;
    return GzScreen(
      top: GzTopBar(title: l.hotelVenueMediaTitle, subtitle: venueName),
      bottom: !loaded || empty
          ? null
          : GzActionBar(
              action: GzActionBarAction(
                label: _reorder ? l.hotelVenueReorderDone : (_tab == _Tab.videos ? l.hotelVenueAddVideoCta : l.hotelVenueAddPhotosCta),
                iconEnd: _reorder ? null : GzIcons.plus,
                onPressed: _reorder ? () => setState(() => _reorder = false) : _openAdd,
              ),
            ),
      child: GzAsyncView<MediaLibrary>(
        value: value,
        loading: const _MediaSkeleton(),
        onRetry: () => ref.invalidate(venueMediaProvider),
        data: (_) => _body(context, photosAll, videos, photoUploads, videoUploads, empty),
      ),
    );
  }

  Widget _body(BuildContext context, List<MediaItem> photosAll, List<MediaItem> videos, List<UploadItem> photoUploads, List<UploadItem> videoUploads, bool empty) {
    final l = context.l10n;
    final c = context.gz.colors;
    final status = _view == _review || _view == _rejected ? _view : _all;
    final zone = status == _all ? _view : _all;
    final counts = <MediaZone, int>{for (final z in kZones) z: photosAll.where((m) => m.zone == z).length};
    final reviewCount = photosAll.where((m) => m.status == MediaStatus.processing).length;
    final rejectedCount = photosAll.where((m) => m.status == MediaStatus.rejected).length;
    GzPhotoTile tile(MediaItem m) => GzPhotoTile(id: m.id, src: gzImageSrc(m.image!.file, m.image!.baseUrl), alt: m.image!.alt, zone: m.zone, status: _statusOf(m.status));
    final all = [for (final m in photosAll) tile(m)];
    final filtered = [
      for (final m in photosAll)
        if ((status == _all || (status == _review ? m.status == MediaStatus.processing : m.status == MediaStatus.rejected)) && (zone == _all || m.zone.value == zone)) tile(m),
    ];
    final cover = photosAll.where((m) => m.isCover).firstOrNull ?? photosAll.firstOrNull;
    const pad = EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter);
    final photos = _tab == _Tab.photos;
    final children = <Widget>[
      Padding(
        padding: pad,
        child: GzSegmentedControl<_Tab>(
          label: l.hotelVenueMediaTabs,
          value: _tab,
          onChanged: (v) => setState(() {
            _tab = v;
            _reorder = false;
          }),
          options: [
            GzSegmentedOption(value: _Tab.photos, label: l.hotelVenueMediaTabPhotos(photosAll.length)),
            GzSegmentedOption(value: _Tab.videos, label: l.hotelVenueMediaTabVideos(videos.length)),
          ],
        ),
      ),
    ];
    if (photos) {
      if (photoUploads.isNotEmpty) {
        children.add(
          Padding(
            padding: pad,
            child: Column(
              children: [for (final u in photoUploads) UploadRow(item: u, onRetry: () => ref.read(venueUploadsProvider.notifier).retry(u.id))],
            ),
          ),
        );
      }
      if (empty) {
        children.add(
          Padding(
            padding: pad,
            child: GzEmptyState(
              fill: false,
              icon: GzIcons.image,
              title: l.hotelVenueMediaEmptyTitle,
              action: GzStateAction(label: l.hotelVenueAddPhotosCta, iconStart: GzIcons.plus, onPressed: _openAdd),
            ),
          ),
        );
      } else {
        if (_view == _all && !_reorder) {
          children.add(Padding(padding: pad, child: AttentionPanel(rejected: rejectedCount, onRejected: () => setState(() => _view = _rejected))));
        }
        if (status == _rejected) {
          children.add(
            Padding(
              padding: pad,
              child: Row(
                children: [
                  Expanded(child: GzText(l.hotelVenueAttentionRejected(rejectedCount), role: GzTextRole.title, color: c.textStrong)),
                  GzButton(label: l.hotelVenueShowAll, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: () => setState(() => _view = _all)),
                ],
              ),
            ),
          );
        } else if (!_reorder) {
          children.add(
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter),
              child: GzChipGroup<String>(
                label: l.hotelVenueZoneFilter,
                layout: GzChipLayout.rail,
                value: _view,
                onChanged: (v) => setState(() => _view = v ?? _all),
                options: [
                  GzChipOption<String>(value: _all, label: l.hotelVenueZoneAll(photosAll.length)),
                  if (reviewCount > 0) GzChipOption<String>(value: _review, label: l.hotelVenueChipReview(reviewCount)),
                  for (final z in kZones) GzChipOption<String>(value: z.value, disabled: counts[z] == 0, label: l.hotelVenueZoneCount(zoneLabel(l, z), counts[z] ?? 0)),
                ],
              ),
            ),
          );
        }
        if (status != _rejected) {
          children.add(
            Padding(
              padding: pad,
              child: Container(
                constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                child: Row(
                  children: [
                    Expanded(child: GzText(_reorder ? l.hotelVenueReorderHint : l.hotelVenuePhotoCount(filtered.length), role: GzTextRole.caption, color: c.textSecondary, figures: true)),
                    if (!_reorder && _view == _all)
                      GzButton(
                        label: l.hotelVenueReorder,
                        variant: GzButtonVariant.tertiary,
                        iconStart: GzIcons.swap,
                        flushInline: true,
                        onPressed: () => setState(() => _reorder = true),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
        children.add(
          Padding(
            padding: pad,
            child: _view == _all
                ? GzPhotoManagerGrid(
                    items: all,
                    reorder: _reorder,
                    onOpen: _openTile,
                    onMove: (id, by) => _move(all, id, all.indexWhere((t) => t.id == id) + by),
                    onReorder: (id, to) => _move(all, id, to),
                    onAdd: _openAdd,
                  )
                : FilteredGrid(items: filtered, coverId: cover?.id, onOpen: _openTile, onReplace: _replace),
          ),
        );
      }
    } else {
      if (videoUploads.isNotEmpty) {
        children.add(
          Padding(
            padding: pad,
            child: Column(
              children: [for (final u in videoUploads) UploadRow(item: u, onRetry: () => ref.read(venueUploadsProvider.notifier).retry(u.id))],
            ),
          ),
        );
      }
      children.add(
        Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final v in videos)
                VideoRow(
                  video: v,
                  onOpen: () => GzNavigatorScope.of(context).openSheetBuilder((_) => VideoSheet(videoId: v.id), options: GzSheetOptions(title: l.hotelVenueVideoSheetTitle)),
                ),
              if (videos.isEmpty && videoUploads.isEmpty) GzEmptyState(fill: false, icon: GzIcons.video, title: l.hotelVenueVideoEmptyTitle),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s4), children[i]],
        ],
      ),
    );
  }
}

class _MediaSkeleton extends StatelessWidget {
  const _MediaSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    Widget cell() => Expanded(
      child: AspectRatio(
        aspectRatio: GzLayout.aspect4x5,
        child: DecoratedBox(decoration: BoxDecoration(color: c.surfacePlaceholder, borderRadius: GzRadius.mdAll)),
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 52),
          const SizedBox(height: GzSpace.s4),
          const Row(
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 96, blockSize: 44),
              SizedBox(width: GzSpace.s2),
              GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 112, blockSize: 44),
              SizedBox(width: GzSpace.s2),
              GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 96, blockSize: 44),
            ],
          ),
          for (var r = 0; r < 3; r++) ...[
            const SizedBox(height: GzSpace.s2),
            Row(children: [cell(), const SizedBox(width: GzSpace.s2), cell(), const SizedBox(width: GzSpace.s2), cell()]),
          ],
        ],
      ),
    );
  }
}
