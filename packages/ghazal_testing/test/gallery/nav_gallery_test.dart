import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/nav_gallery.dart';

/// Renders the nav gallery sections (`build/gallery/nav/NN-<id>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery nav` from the repo root.
void main() => gzGalleryShots(page: 'nav', sections: navGallerySections);
