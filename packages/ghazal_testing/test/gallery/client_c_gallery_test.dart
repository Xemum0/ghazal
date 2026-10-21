import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/client_c_gallery.dart';

late ClientCData data;

/// Renders sections 13 to 19 of the client gallery (`build/gallery/client/NN-<id>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery client --sections 13,14,15,16,17,18,19` from the repo root.
void main() {
  setUpAll(() async => data = await ClientCData.load(await GzWorld.load()));
  gzGalleryShots(page: 'client', wrap: gzStoryWrap, sections: () => clientCGallerySections(() => data));
}
