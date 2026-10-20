import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/core_gallery.dart';

/// Renders the core + brand gallery sections (`build/gallery/core/NN-<slug>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery core` from the repo root.
void main() {
  gzGalleryShots(page: 'core', sections: coreGallerySections);
  // The web references of the Arabic run are named after the Arabic titles: write the same files under those names.
  tearDownAll(() => coreGalleryAliasArabicFiles('build/gallery/core'));
}
