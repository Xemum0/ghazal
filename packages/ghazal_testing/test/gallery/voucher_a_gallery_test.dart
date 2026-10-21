import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/voucher_a_gallery.dart';

late VoucherAData data;

/// Renders sections 1 to 8 of the voucher gallery (`build/gallery/voucher/NN-<id>.<lang>.png`: voucher-card, qr, price-compare,
/// purchase-summary, confirm-window, role-badge, group-chat, visit-card). Score:
/// `node tools/parity/parity.mjs --gallery voucher --sections 1,2,3,4,5,6,7,8` from the repo root.
void main() {
  setUpAll(() async => data = await VoucherAData.load(await GzWorld.load()));
  gzGalleryShots(page: 'voucher', wrap: gzStoryWrap, sections: () => voucherAGallerySections(() => data));
}
