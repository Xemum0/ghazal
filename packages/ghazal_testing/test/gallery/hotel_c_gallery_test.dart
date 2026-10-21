import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/hotel_c_gallery.dart';
import 'package:ghazal_testing/src/gallery/hotel_c_gallery_data.dart';

late HotelCData data;

/// Renders sections 11 to 15 of the hotel gallery (`build/gallery/hotel/NN-<id>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery hotel --sections 11,12,13,14,15` from the repo root.
void main() {
  setUpAll(() async => data = await HotelCData.load(await GzWorld.load()));
  gzGalleryShots(page: 'hotel', wrap: gzStoryWrap, sections: () => hotelCGallerySections(() => data));
}
