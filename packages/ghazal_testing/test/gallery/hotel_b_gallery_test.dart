import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/hotel_b_gallery.dart';

late HotelBData _data;

/// Renders sections 6 to 10 of the partner gallery (`build/gallery/hotel/NN-<id>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery hotel --sections 6,7,8,9,10` from the repo root.
void main() {
  setUpAll(() async => _data = await loadHotelBData(await GzWorld.load()));
  gzGalleryShots(page: 'hotel', wrap: hotelBGalleryWrap, sections: () => hotelBGallerySections(() => _data));
}
