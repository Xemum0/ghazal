import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/gallery.dart';

void main() {
  late GzWorld world;
  setUpAll(() async => world = await GzWorld.load());

  test('a guest searches venues through the real repositories', () async {
    final page = await world.repos('guest').venues.searchVenues(limit: 4);
    expect(page.items, isNotEmpty);
  });

  test('a signed-in client has a wallet and notifications', () async {
    final reem = world.repos('reem');
    final wallet = await reem.vouchers.listVouchers();
    expect(wallet.items, isNotNull);
    final feed = await reem.home.getHome();
    expect(feed, isNotNull);
  });
}
