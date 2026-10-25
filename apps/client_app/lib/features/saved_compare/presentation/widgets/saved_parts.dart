import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ImageRef, VenueSummary;
import 'package:ghazal_ui/ghazal_ui.dart';

/// A rounded thumbnail of a hall's cover (its monogram on a tint when it has no photograph).
class SavedThumb extends StatelessWidget {
  const SavedThumb({this.venue, this.image, this.width = GzSize.thumbCompactWidth, this.height = GzSize.thumbCompactHeight, super.key});

  final VenueSummary? venue;
  final ImageRef? image;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final cover = image ?? venue?.cover;
    return ClipRRect(
      borderRadius: GzRadius.smAll,
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: c.surfacePlaceholder,
          child: cover != null
              ? GzPhoto(src: gzImageRefSrc(cover))
              : ColoredBox(
                  color: c.surfaceTintSoft,
                  child: const Center(child: GzMonogram(size: GzMonogramSize.sm)),
                ),
        ),
      ),
    );
  }
}
