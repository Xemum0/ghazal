// The three sheets of the media manager (web `Media.tsx`): the photo menu with its edit view, the upload sheet with the face check and the
// video details. Each reads the media library itself, so it works in the navigator's sheet host.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/media_state.dart';
import '../../application/venue_data.dart';
import 'media_parts.dart';
import 'venue_bits.dart';
import 'venue_fields.dart';
import 'venue_labels.dart';

MediaItem? _find(MediaLibrary? lib, String id) => lib?.items.where((m) => m.id == id).firstOrNull;

Future<bool> _confirmDelete(BuildContext context, {required bool video}) async {
  final l = context.l10n;
  final answer = await GzNavigatorScope.of(context).openDialog(
    GzDialogSpec(
      title: video ? l.hotelVenueVideoDeleteTitle : l.hotelVenueDeleteTitle,
      body: video ? l.hotelVenueVideoDeleteBody : l.hotelVenueDeleteBody,
      icon: GzIcons.trash,
      confirmLabel: l.hotelVenueDeleteConfirm,
      cancelLabel: l.hotelVenueDeleteKeep,
      tone: GzDialogTone.destructive,
    ),
  );
  return answer == GzDialogResult.confirm;
}

/// A danger panel: the reason a photo or a video cannot go up.
class ReasonPanel extends StatelessWidget {
  const ReasonPanel({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
        decoration: BoxDecoration(color: c.statusDangerBg, borderRadius: GzRadius.mdAll),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
              child: GzIcon(GzIcons.warningCircle, size: GzIconSize.sm, color: c.iconDanger),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzText(title, role: GzTextRole.title, color: c.textStrong),
                  const SizedBox(height: GzSpace.s1),
                  GzText(body, role: GzTextRole.bodyS, color: c.textStrong, figures: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Disk extends StatelessWidget {
  const _Disk(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      width: GzSize.controlSm,
      height: GzSize.controlSm,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.surfaceQuiet, shape: BoxShape.circle),
      child: GzIcon(icon, size: GzIconSize.md, color: c.iconPrimary),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.src);

  final String? src;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ClipRRect(
      borderRadius: GzRadius.smAll,
      child: SizedBox(
        width: GzSize.thumbLg,
        child: AspectRatio(aspectRatio: GzLayout.aspect16x10, child: MediaThumb(src: src, icon: GzIcons.image)),
      ),
    ),
  );
}

// ---------------------------------------------------------------- photo sheet

/// The photo menu: set as cover, edit zone and alt text, delete. A photo that needs replacing leads with the reason and Replace.
class TileSheet extends ConsumerStatefulWidget {
  const TileSheet({required this.photoId, super.key});

  final String photoId;

  @override
  ConsumerState<TileSheet> createState() => _TileSheetState();
}

class _TileSheetState extends ConsumerState<TileSheet> {
  bool _edit = false;
  MediaZone? _zone;
  String _ar = '';
  String _en = '';
  bool _seeded = false;

  void _seed(MediaItem m) {
    if (_seeded) return;
    _seeded = true;
    _zone = m.zone;
    _ar = m.image?.alt.ar ?? '';
    _en = m.image?.alt.en ?? '';
  }

  Future<void> _cover(MediaItem m) async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final res = await ref.read(venueActionsProvider.notifier).updateMedia(m.id, const UpdateMediaInput(isCover: true));
    if (!mounted) return;
    toastResult(context, res, success: l.hotelVenueToastCover, then: (_) => nav.closeSheet());
  }

  Future<void> _delete(MediaItem m) async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    if (!await _confirmDelete(context, video: false) || !mounted) return;
    final res = await ref.read(venueActionsProvider.notifier).deleteMedia(m.id);
    if (!mounted) return;
    toastResult(context, res, success: l.hotelVenueToastDeleted, then: (_) => nav.closeSheet());
  }

  void _replace(MediaItem m) {
    final nav = GzNavigatorScope.of(context);
    final title = context.l10n.hotelVenueReplaceTitle;
    nav.closeSheet();
    nav.openSheetBuilder((_) => UploadSheet(replaceId: m.id), options: GzSheetOptions(title: title));
  }

  Future<void> _save(MediaItem m) async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final res = await ref
        .read(venueActionsProvider.notifier)
        .updateMedia(m.id, UpdateMediaInput(zone: _zone, alt: LocalizedText(ar: _ar.trim(), en: _en.trim())));
    if (!mounted) return;
    toastResult(context, res, success: l.hotelVenueToastPhotoSaved, then: (_) => nav.closeSheet());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final m = _find(ref.watch(venueMediaProvider).value, widget.photoId);
    if (m == null) return const SizedBox(height: GzSpace.s8);
    _seed(m);
    final alt = m.image?.alt;
    final src = posterSrc(m.image);
    final busy = ref.watch(venueActionsProvider).isBusy;
    if (_edit) {
      final ready = _zone != null && _ar.trim().isNotEmpty && _en.trim().isNotEmpty;
      return SheetColumn(
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzButton(
              label: l.commonActionSave,
              fullWidth: true,
              loading: busy,
              reason: _zone == null ? l.hotelVenueUploadZoneFirst : l.hotelVenueAltBothFirst,
              onPressed: ready ? () => _save(m) : null,
            ),
            const SizedBox(height: GzSpace.s2),
            GzButton(label: l.commonActionBack, variant: GzButtonVariant.tertiary, onPressed: () => setState(() => _edit = false)),
          ],
        ),
        children: [
          _Thumb(src),
          ZonePicker(value: _zone, onChanged: (z) => setState(() => _zone = z)),
          BilingualField(
            label: l.hotelVenueFieldAlt,
            ar: _ar,
            en: _en,
            onAr: (v) => setState(() => _ar = v),
            onEn: (v) => setState(() => _en = v),
            maxLength: 140,
            required: false,
          ),
          GzText(l.hotelVenueAltHelper, role: GzTextRole.caption, color: c.textSecondary),
        ],
      );
    }
    final needsReplace = m.status == MediaStatus.rejected;
    final review = m.status == MediaStatus.processing;
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GzSpace.s2),
        ClipRRect(
          borderRadius: GzRadius.mdAll,
          child: AspectRatio(aspectRatio: GzLayout.aspect16x10, child: MediaThumb(src: src, icon: GzIcons.image, alt: alt?.of(lang) ?? '')),
        ),
        const SizedBox(height: GzSpace.s4),
        Wrap(
          spacing: GzSpace.s2,
          runSpacing: GzSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GzText(zoneLabel(l, m.zone), role: GzTextRole.caption, color: c.textSecondary),
            if (review) GzStatusPill(status: GzStatus.requested, audience: GzStatusAudience.hotel, label: l.hotelVenueStatusReview),
            if (needsReplace) GzStatusPill(status: GzStatus.rejected, audience: GzStatusAudience.hotel, label: l.hotelVenueStatusRejected),
            if (m.isCover) GzStatusPill(status: GzStatus.available, audience: GzStatusAudience.hotel, label: l.hotelVenueCover),
          ],
        ),
        if (needsReplace) ...[const SizedBox(height: GzSpace.s4), ReasonPanel(title: l.hotelVenueReasonPerson, body: l.hotelVenueReasonPersonBody)],
        if (review) ...[const SizedBox(height: GzSpace.s4), FactLine(l.hotelVenueReviewNote, icon: GzIcons.clock)],
        const SizedBox(height: GzSpace.s4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LangChip(arGaps: (alt?.ar ?? '').trim().isEmpty ? 1 : 0, enGaps: (alt?.en ?? '').trim().isEmpty ? 1 : 0),
        ),
        const SizedBox(height: GzSpace.s4),
        if (!needsReplace && !m.isCover) GzListRow(flush: true, title: l.hotelVenueSetCover, leading: GzIcon(GzIcons.image, size: GzIconSize.md, color: c.iconPrimary), onPressed: () => _cover(m)),
        GzListRow(flush: true, title: l.hotelVenueEditPhoto, leading: GzIcon(GzIcons.edit, size: GzIconSize.md, color: c.iconPrimary), chevron: true, onPressed: () => setState(() => _edit = true)),
        GzListRow(
          flush: true,
          last: true,
          tone: GzListRowTone.danger,
          title: l.hotelVenueDeletePhoto,
          leading: GzIcon(GzIcons.trash, size: GzIconSize.md, color: c.iconDanger),
          onPressed: () => _delete(m),
        ),
        if (needsReplace) ...[
          const SizedBox(height: GzSpace.s4),
          GzButton(label: l.hotelVenueReplace, iconStart: GzIcons.upload, fullWidth: true, onPressed: () => _replace(m)),
        ],
      ],
    );
    return body;
  }
}

// ---------------------------------------------------------------- video sheet

class VideoSheet extends ConsumerWidget {
  const VideoSheet({required this.videoId, super.key});

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final nav = GzNavigatorScope.of(context);
    final v = _find(ref.watch(venueMediaProvider).value, videoId);
    if (v == null) return const SizedBox(height: GzSpace.s8);
    final title = v.image?.alt.of(lang) ?? l.hotelVenueNewVideoTitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GzSpace.s2),
        ClipRRect(
          borderRadius: GzRadius.mdAll,
          child: AspectRatio(
            aspectRatio: GzLayout.aspect16x10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaThumb(src: posterSrc(v.image), icon: GzIcons.video, alt: title),
                PositionedDirectional(
                  bottom: GzSpace.s3,
                  start: GzSpace.s3,
                  child: Container(
                    width: GzSize.controlSm,
                    height: GzSize.controlSm,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.surfaceCanvas, shape: BoxShape.circle),
                    child: GzIcon(GzIcons.play, size: GzIconSize.md, color: c.iconPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: GzSpace.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: GzText(title, role: GzTextRole.title, color: c.textStrong)),
            const SizedBox(width: GzSpace.s3),
            GzIcon(GzIcons.clock, size: GzIconSize.xs, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s1),
            GzText(clockOf(context, v.durationSeconds ?? 0), role: GzTextRole.caption, color: c.textSecondary, figures: true),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        FactLine(l.hotelVenueVideoNote),
        const SizedBox(height: GzSpace.s4),
        GzListRow(
          flush: true,
          last: true,
          tone: GzListRowTone.danger,
          title: l.hotelVenueVideoDelete,
          leading: GzIcon(GzIcons.trash, size: GzIconSize.md, color: c.iconDanger),
          onPressed: () async {
            if (!await _confirmDelete(context, video: true)) return;
            final res = await ref.read(venueActionsProvider.notifier).deleteMedia(videoId);
            if (!context.mounted) return;
            toastResult(context, res, success: l.hotelVenueToastVideoDeleted, then: (_) => nav.closeSheet());
          },
        ),
        const SizedBox(height: GzSpace.s4),
        GzButton(label: l.commonActionDone, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: nav.closeSheet),
      ],
    );
  }
}

// ---------------------------------------------------------------- upload sheet

/// Add a photo or a video: Camera or Library, then a required zone tag, bilingual alt text and the empty-room line.
class UploadSheet extends ConsumerStatefulWidget {
  const UploadSheet({this.kind = MediaKind.photo, this.replaceId, this.initialFace = false, super.key});

  final MediaKind kind;

  /// Replacing the photo that was not approved.
  final String? replaceId;

  /// The face check shown at once (a frame for review).
  final bool initialFace;

  @override
  ConsumerState<UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends ConsumerState<UploadSheet> {
  late bool _details = widget.initialFace;
  late bool _face = widget.initialFace;
  bool _large = false;
  MediaZone? _zone;
  String _ar = '';
  String _en = '';
  bool _touched = false;
  ImageRef? _picked;

  List<ImageRef> get _pool => [
    for (final m in ref.read(venueMediaProvider).value?.items ?? const <MediaItem>[])
      if (m.image != null) m.image!,
  ];

  void _choose(bool camera) {
    final notifier = ref.read(venueUploadsProvider.notifier);
    if (widget.kind == MediaKind.video) {
      // The prototype has no real file: every second pick shows the over-limit state.
      if (notifier.nextSerial().isEven) {
        setState(() => _large = true);
        return;
      }
      _submitVideo();
      return;
    }
    final pool = _pool;
    final n = ref.read(venueMediaProvider).value?.items.where((m) => m.kind == MediaKind.photo).length ?? 0;
    setState(() {
      _picked = pool.isEmpty ? null : pool[n % pool.length];
      _details = true;
      if (camera && !notifier.cameraWarned) {
        notifier.cameraWarned = true;
        _face = true;
      }
    });
  }

  void _pickZone(MediaZone z) {
    final l = context.l10n;
    setState(() {
      _zone = z;
      if (!_touched) {
        final name = ref.read(partnerVenueProvider).value?.venue.name;
        final ar = zoneLabel(lookupAppL10n(const Locale('ar')), z);
        final en = zoneLabel(lookupAppL10n(const Locale('en')), z);
        _ar = name == null ? ar : '${name.ar} · $ar';
        _en = name == null ? en : '${name.en} · $en';
      }
    });
    assert(l.localeName.isNotEmpty);
  }

  Future<void> _run(UploadItem item, {required String done}) async {
    final nav = GzNavigatorScope.of(context);
    final started = context.l10n.hotelVenueToastUploadStarted;
    nav.closeSheet();
    nav.toast(GzToastSpec(message: started, icon: GzIcons.upload));
    final ok = await ref.read(venueUploadsProvider.notifier).start(item);
    if (ok) nav.toast(GzToastSpec(message: done, icon: GzIcons.checkCircle));
  }

  void _submitPhoto() {
    final l = context.l10n;
    final z = _zone;
    if (z == null) return;
    final notifier = ref.read(venueUploadsProvider.notifier);
    final serial = notifier.nextSerial();
    final label = l.hotelVenueUploadDemoPhoto;
    _run(
      UploadItem(
        id: 'up-$serial',
        kind: MediaKind.photo,
        label: LocalizedText(ar: label, en: label),
        input: pickedFile(kind: MediaKind.photo, zone: z, serial: serial),
        alt: LocalizedText(ar: _ar.trim(), en: _en.trim()),
        replaceId: widget.replaceId,
        poster: _picked,
      ),
      done: widget.replaceId != null ? l.hotelVenueToastReplaced : l.hotelVenueToastPhotoAdded,
    );
  }

  void _submitVideo() {
    final l = context.l10n;
    final notifier = ref.read(venueUploadsProvider.notifier);
    final serial = notifier.nextSerial();
    final label = l.hotelVenueNewVideoTitle;
    _run(
      UploadItem(
        id: 'up-$serial',
        kind: MediaKind.video,
        label: LocalizedText(ar: label, en: label),
        input: pickedFile(kind: MediaKind.video, zone: MediaZone.hall, serial: serial),
        alt: LocalizedText(ar: label, en: label),
        poster: _pool.firstOrNull,
      ),
      done: l.hotelVenueToastVideoAdded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final video = widget.kind == MediaKind.video;
    if (!_details) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: GzSpace.s2),
          if (!video) GzListRow(flush: true, title: l.hotelVenueSourceCamera, leading: const _Disk(GzIcons.camera), chevron: true, onPressed: () => _choose(true)),
          GzListRow(
            flush: true,
            last: true,
            title: video ? l.hotelVenueSourceVideo : l.hotelVenueSourceLibrary,
            leading: _Disk(video ? GzIcons.video : GzIcons.image),
            chevron: true,
            onPressed: () => _choose(false),
          ),
          if (video && _large) ...[const SizedBox(height: GzSpace.s4), ReasonPanel(title: l.hotelVenueVideoTooLarge, body: l.hotelVenueVideoTooLargeBody(kVideoMaxMb))],
          const SizedBox(height: GzSpace.s4),
          FactLine(video ? l.hotelVenueVideoLimits(kVideoMaxMb) : l.hotelVenueEmptyRoomOnly, icon: video ? GzIcons.video : GzIcons.info),
        ],
      );
    }
    final ready = _zone != null && !_face && _ar.trim().isNotEmpty && _en.trim().isNotEmpty;
    return SheetColumn(
      footer: GzButton(
        label: widget.replaceId != null ? l.hotelVenueReplace : l.hotelVenueUploadCta,
        iconStart: GzIcons.upload,
        fullWidth: true,
        reason: _face ? l.hotelVenueFaceFirst : (_zone == null ? l.hotelVenueUploadZoneFirst : l.hotelVenueAltBothFirst),
        onPressed: ready ? _submitPhoto : null,
      ),
      children: [
        _Thumb(posterSrc(_picked)),
        if (_face)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReasonPanel(title: l.hotelVenueFaceTitle, body: l.hotelVenueFaceBody),
              const SizedBox(height: GzSpace.s3),
              Row(
                children: [
                  Expanded(
                    child: GzButton(
                      label: l.hotelVenueFaceRetake,
                      variant: GzButtonVariant.secondary,
                      onPressed: () => setState(() {
                        _face = false;
                        _picked = null;
                        _details = false;
                      }),
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: GzButton(label: l.hotelVenueFaceCrop, variant: GzButtonVariant.secondary, onPressed: () => setState(() => _face = false)),
                  ),
                ],
              ),
            ],
          )
        else
          FactLine(l.hotelVenueEmptyRoomOnly, icon: GzIcons.checkCircle),
        ZonePicker(value: _zone, onChanged: _pickZone),
        BilingualField(
          label: l.hotelVenueFieldAlt,
          ar: _ar,
          en: _en,
          onAr: (v) => setState(() {
            _touched = true;
            _ar = v;
          }),
          onEn: (v) => setState(() {
            _touched = true;
            _en = v;
          }),
          maxLength: 140,
          required: false,
        ),
        GzText(l.hotelVenueAltHelper, role: GzTextRole.caption, color: c.textSecondary),
      ],
    );
  }
}
