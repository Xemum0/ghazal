// The upload queue of the media manager (HL-VENU-01). A photo or video goes up through the repository (`createMediaUploadSession`, then
// `completeMediaUpload`); while the call is in flight the row shows in the queue, a refusal leaves it as failed with Retry, no connection leaves
// it queued. The device pickers (camera, library) have no package in the build yet: the file is described, not read (requests.md [P-H3]).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'venue_data.dart';

/// The video limit in MB (owner round 1, ADR 0035).
const int kVideoMaxMb = 500;
const int _mb = 1024 * 1024;

enum UploadStatus { uploading, queued, failed }

class UploadItem {
  const UploadItem({
    required this.id,
    required this.kind,
    required this.label,
    required this.input,
    this.alt,
    this.replaceId,
    this.status = UploadStatus.uploading,
    this.progress = 0,
    this.poster,
  });

  final String id;
  final MediaKind kind;
  final LocalizedText label;
  final MediaUploadInput input;
  final LocalizedText? alt;
  final String? replaceId;
  final UploadStatus status;

  /// 0 to 100.
  final int progress;
  final ImageRef? poster;

  UploadItem copyWith({UploadStatus? status, int? progress}) =>
      UploadItem(id: id, kind: kind, label: label, input: input, alt: alt, replaceId: replaceId, status: status ?? this.status, progress: progress ?? this.progress, poster: poster);
}

/// The description of a picked file: a photo of a few MB, or a video under the limit.
MediaUploadInput pickedFile({required MediaKind kind, required MediaZone zone, required int serial}) => MediaUploadInput(
  kind: kind,
  zone: zone,
  fileName: kind == MediaKind.video ? 'venue-video-$serial.mp4' : 'venue-photo-$serial.jpg',
  contentType: kind == MediaKind.video ? 'video/mp4' : 'image/jpeg',
  sizeBytes: kind == MediaKind.video ? 120 * _mb : 3 * _mb,
);

final NotifierProvider<UploadsNotifier, List<UploadItem>> venueUploadsProvider = NotifierProvider<UploadsNotifier, List<UploadItem>>(UploadsNotifier.new);

class UploadsNotifier extends Notifier<List<UploadItem>> {
  int _serial = 0;

  /// A running number for picked files (and the alternation of the over-limit demo of videos).
  int nextSerial() => ++_serial;

  /// The first camera shot of a session shows the face check (the library photo is an empty room).
  bool cameraWarned = false;

  @override
  List<UploadItem> build() => const <UploadItem>[];

  /// Queues and runs one upload; true when the library has the file at the end.
  Future<bool> start(UploadItem item) async {
    state = [
      for (final u in state)
        if (u.id != item.id) u,
      item,
    ];
    final res = await ref.read(venueActionsProvider.notifier).upload(item.input, alt: item.alt);
    return res.when(
      success: (_) async {
        final old = item.replaceId;
        if (old != null) await ref.read(venueActionsProvider.notifier).deleteMedia(old);
        _drop(item.id);
        return true;
      },
      failure: (p) {
        _set(item.id, p.code == ApiProblemCode.offline ? UploadStatus.queued : UploadStatus.failed);
        return false;
      },
      gated: () {
        _drop(item.id);
        return false;
      },
    );
  }

  Future<bool> retry(String id) {
    final item = state.where((u) => u.id == id).firstOrNull;
    return item == null ? Future<bool>.value(false) : start(item.copyWith(status: UploadStatus.uploading));
  }

  void _drop(String id) => state = [
    for (final u in state)
      if (u.id != id) u,
  ];

  void _set(String id, UploadStatus s) => state = [for (final u in state) u.id == id ? u.copyWith(status: s) : u];
}
