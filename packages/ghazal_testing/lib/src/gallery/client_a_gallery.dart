// The client gallery page, part A (agent C1): the Flutter twin of sections 1 to 7 of design/src/gallery/client.tsx (#/gallery/client):
// brief, category-tile, offer-card, countdown, venue-card, venue-compact, venue-stress. File slugs are the web section ids.
// Parity: `node tools/parity/parity.mjs --gallery client --sections 1,2,3,4,5,6,7` after `flutter test test/gallery/client_a_gallery_test.dart`.
import 'client_a_gallery_home.dart';
import 'client_a_gallery_kit.dart';
import 'client_a_gallery_venue.dart';
import 'gz_gallery.dart';
import '../world.dart';

export 'client_a_gallery_kit.dart' show clientAData;

/// Loads the story data (call from `setUpAll`, real async).
Future<void> loadClientAGallery(GzWorld world) async => clientAData = await ClientAData.load(world);

/// The sections of the client gallery page owned by part A, with their web numbers.
List<GzGallerySection> clientAGallerySections() => [
  GzGallerySection('brief', briefSection, number: 1),
  GzGallerySection('category-tile', categoryTileSection, number: 2),
  GzGallerySection('offer-card', offerSection, number: 3),
  GzGallerySection('countdown', countdownSection, number: 4),
  GzGallerySection('venue-card', venueCardSection, number: 5),
  GzGallerySection('venue-compact', venueCompactSection, number: 6),
  GzGallerySection('venue-stress', venueStressSection, number: 7),
];
