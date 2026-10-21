import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/client_b_gallery.dart';

late ClientBGalleryData _data;

/// Renders sections 8 to 12 of the client gallery (`build/gallery/client/NN-<id>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery client --sections 8,9,10,11,12` from the repo root.
void main() {
  setUpAll(() async => _data = await ClientBGalleryData.load(await GzWorld.load()));
  gzGalleryShots(page: 'client', wrap: gzStoryWrap, sections: () => clientBGallerySections(() => _data));
}
