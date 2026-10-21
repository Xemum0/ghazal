import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ServiceCategory;

import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';
import 'client_bits.dart' show GzBaselineWrap;

/// The `GzPhoto` descriptor of a catalogue photograph. Mock photographs are bundled flat (`images/<id>_480.jpg`), so the folder and
/// extension of the contract's `file` (`details/details-39-x.jpg`) are dropped; with a real `baseUrl` the photograph comes from it.
String gzImageSrc(String file, [String? baseUrl]) {
  if (baseUrl != null && baseUrl.isNotEmpty) return baseUrl;
  final name = file.split('/').last.replaceFirst(RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false), '');
  return 'asset://ghazal_mock_api/images/$name';
}

/// ServiceTile (CA-SVC): one of the 16 service categories, a 4:5 photograph and a wall label (name, price anchor with its unit).
/// One button for assistive technology. [previewState] and [loading] are the gallery states.
class GzServiceTile extends StatelessWidget {
  const GzServiceTile({required this.category, this.onOpen, this.loading = false, this.previewState, super.key});

  final ServiceCategory category;
  final VoidCallback? onOpen;
  final bool loading;
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    if (loading) {
      return Semantics(
        container: true,
        label: l.commonStateLoading,
        child: const _LoadingTile(),
      );
    }
    final name = category.name.of(lang);
    final label = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GzText(name, role: GzTextRole.title, color: c.textStrong),
        const SizedBox(height: GzStroke.hair),
        GzBaselineWrap(
          spacing: GzSpace.s1,
          runSpacing: GzSpace.s1,
          children: [
            GzPrice(fils: category.anchor.min.fils, size: GzPriceSize.strong, prefix: l.uiSharedFrom),
            GzText(category.anchor.unit.of(lang), role: GzTextRole.caption, color: c.textSecondary),
          ],
        ),
      ],
    );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: GzRadius.mdAll,
          child: GzPhoto(src: gzImageSrc(category.image.file, category.image.baseUrl), alt: category.image.alt.of(lang), aspectRatio: GzLayout.aspect4x5),
        ),
        const SizedBox(height: GzSpace.s2),
        label,
      ],
    );
    return Semantics(
      container: true,
      button: true,
      label: l.uiClientServiceOpen(name),
      excludeSemantics: true,
      onTap: onOpen,
      child: previewState == GzPreviewState.pressed
          ? gzPreview(previewState, body)
          : GzPressable(onPressed: onOpen, borderRadius: GzRadius.mdAll, minHeight: 0, minWidth: 0, child: body),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: c.surfacePlaceholder, borderRadius: GzRadius.mdAll),
          child: const AspectRatio(aspectRatio: GzLayout.aspect4x5),
        ),
        const SizedBox(height: GzSpace.s2),
        const Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 96, blockSize: 24)),
        const SizedBox(height: GzSpace.s2),
        const Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 120, blockSize: 20)),
      ],
    );
  }
}
