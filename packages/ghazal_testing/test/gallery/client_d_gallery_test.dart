import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/client_d_gallery.dart';

late ClientDData data;

/// Renders the client-d sections of the client gallery page (numbers 20 to 25) into `build/gallery/client/NN-<id>.<lang>.png`.
/// Compare: `node tools/parity/parity.mjs --gallery client --sections 20,21,22,23,24,25` from the repository root.
void main() {
  setUpAll(() async => data = await ClientDData.load(await GzWorld.load()));
  gzGalleryShots(page: 'client', wrap: gzStoryWrap, sections: () => clientDGallerySections(() => data));
}
