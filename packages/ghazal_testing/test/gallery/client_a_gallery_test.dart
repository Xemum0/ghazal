import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/client_a_gallery.dart';
import 'package:flutter_test/flutter_test.dart';

late GzWorld world;

/// Renders sections 1 to 7 of the client gallery page (`build/gallery/client/NN-<id>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery client --sections 1,2,3,4,5,6,7` from the repo root.
void main() {
  setUpAll(() async {
    world = await GzWorld.load();
    await loadClientAGallery(world);
  });
  gzGalleryShots(page: 'client', wrap: gzStoryWrap, sections: clientAGallerySections);
}
