import 'package:flutter/widgets.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_ui/src/foundation.dart';

/// The reference sample of a group gallery page: copy this file to `test/gallery/<page>_gallery_test.dart` and list your sections.
void main() => gzGalleryShots(
      page: 'sample',
      sections: () => [
        GzGallerySection(
          'Text roles',
          (context) => Padding(
            padding: const EdgeInsets.all(GzSpace.s4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const GzText('Aurelia Gulf Hotel', role: GzTextRole.title),
              const SizedBox(height: GzSpace.s2),
              const GzText('Hall, session and date are held while the hotel replies.', role: GzTextRole.bodyS),
              const SizedBox(height: GzSpace.s3),
              GzPressable(onPressed: () {}, semanticLabel: 'demo', child: const Padding(padding: EdgeInsets.all(GzSpace.s3), child: GzIcon(GzIcons.heart))),
            ]),
          ),
        ),
      ],
    );
