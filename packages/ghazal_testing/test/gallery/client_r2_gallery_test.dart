import 'package:ghazal_testing/gallery.dart';
import 'package:ghazal_testing/src/gallery/client_r2_gallery.dart';

/// Renders section 26 of the client gallery (the sex choice; no web twin, so no parity reference): `build/gallery/client/26-sex-choice.<lang>.png`.
void main() => gzGalleryShots(page: 'client', wrap: gzStoryWrap, sections: clientR2GallerySections);
