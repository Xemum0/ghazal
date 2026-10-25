// PhotoStrip (web `PhotoStrip.tsx`): the listing's photographs as 104 x 128 tiles with a remove control, the first marked Cover, then an Add
// tile. Add runs the signed upload and attaches the photo as the cover (the API keeps one cover per listing: requests.md). Empty rooms,
// plates and arrangements; never faces.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ImageRef;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

const int kMaxPhotos = 8;

class PhotoStrip extends StatelessWidget {
  const PhotoStrip({required this.photos, required this.onAdd, required this.onRemove, this.adding = false, super.key});

  final List<ImageRef> photos;
  final VoidCallback onAdd;
  final ValueChanged<ImageRef> onRemove;
  final bool adding;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final canAdd = photos.length < kMaxPhotos && !adding;
    return Wrap(
      spacing: GzSpace.s3,
      runSpacing: GzSpace.s3,
      children: [
        for (var i = 0; i < photos.length; i++)
          ClipRRect(
            borderRadius: GzRadius.smAll,
            child: SizedBox(
              width: 104,
              height: 128,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: c.surfacePlaceholder, child: GzPhoto(src: photos[i].baseUrl ?? photos[i].file, alt: photos[i].alt.of(lang))),
                  if (i == 0)
                    PositionedDirectional(
                      bottom: GzSpace.s2,
                      start: GzSpace.s2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: c.surfaceDark, borderRadius: GzRadius.xsAll),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s1),
                          child: GzText(l.hotelProviderPhotoCover, role: GzTextRole.caption, color: c.textOnDark),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    top: GzSpace.s1,
                    end: GzSpace.s1,
                    child: GzPressable(
                      onPressed: () => onRemove(photos[i]),
                      semanticLabel: l.hotelProviderPhotoRemove,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(GzSpace.s1),
                          decoration: BoxDecoration(color: c.surfaceDark, shape: BoxShape.circle),
                          child: GzIcon(GzIcons.close, size: GzIconSize.xs, color: c.textOnDark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          width: 104,
          height: 128,
          child: GzPressable(
            onPressed: canAdd ? onAdd : null,
            semanticLabel: l.hotelProviderPhotoAdd,
            borderRadius: GzRadius.smAll,
            minHeight: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: GzRadius.smAll, border: Border.all(color: canAdd ? c.borderControl : c.borderStrong, width: GzStroke.hair)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GzIcon(GzIcons.camera, size: GzIconSize.md, color: canAdd ? c.textPrimary : c.textDisabled),
                  const SizedBox(height: GzSpace.s2),
                  GzText(l.hotelProviderPhotoAdd, role: GzTextRole.caption, color: canAdd ? c.textPrimary : c.textDisabled),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
