import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/charts_gallery.dart';

/// Renders the charts gallery (`build/gallery/charts/NN-<slug>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery charts` from the repo root.
void main() => gzGalleryShots(page: 'charts', sections: chartsGallerySections);
