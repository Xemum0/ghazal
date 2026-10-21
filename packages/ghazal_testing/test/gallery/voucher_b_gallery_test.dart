import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/voucher_b_gallery.dart';

late VoucherBData data;

/// Renders sections 9 to 12 of the voucher gallery (`build/gallery/voucher/NN-<id>.<lang>.png`: listing, review-timeline, ad-plan,
/// filters). Score: `node tools/parity/parity.mjs --gallery voucher --sections 9,10,11,12` from the repo root.
void main() {
  setUpAll(() async => data = await VoucherBData.load(await GzWorld.load()));
  gzGalleryShots(page: 'voucher', wrap: gzStoryWrap, sections: () => voucherBGallerySections(() => data));
}
