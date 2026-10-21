import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/hotel_a_gallery.dart';

late HotelAData _data;

/// Renders sections 1 to 5 of the partner gallery page (`build/gallery/hotel/NN-<id>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery hotel --sections 1,2,3,4,5` from the repo root.
void main() {
  setUpAll(() async => _data = await HotelAData.load(await GzWorld.load()));
  gzGalleryShots(page: 'hotel', wrap: hotelGalleryWrap, sections: () => hotelAGallerySections(() => _data));
}
