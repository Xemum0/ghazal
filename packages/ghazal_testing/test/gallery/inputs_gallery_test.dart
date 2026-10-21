import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/inputs_gallery.dart';

/// Renders the inputs gallery sections (`build/gallery/inputs/NN-<id>.<lang>.png`). Compare with
/// `node tools/parity/parity.mjs --gallery inputs` from the repo root.
void main() => gzGalleryShots(page: 'inputs', sections: inputsGallerySections, wrap: inputsGalleryWrap);
