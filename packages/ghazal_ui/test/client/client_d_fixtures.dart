import 'dart:convert';
import 'dart:io';

import 'package:ghazal_domain/ghazal_domain.dart';

/// Bookings from the shared contracts fixture (the data the mock serves): the stored bookings and the hero request in each state.
class ClientDFixtures {
  ClientDFixtures._(this.bookings, this.hero, this.heroVouchers, this.packages, this.notifications);

  final List<Booking> bookings;
  final Map<String, Booking> hero;
  final Map<String, Voucher> heroVouchers;
  final Map<String, Package> packages;
  final List<AppNotification> notifications;

  static const TargetSummary target = TargetSummary(
    kind: BookingTargetType.venue,
    id: 'V01',
    name: LocalizedText(en: 'Aurelia Gulf Hotel', ar: 'فندق أوريليا الخليج'),
    monogram: null,
    areaId: null,
    cover: null,
    phone: null,
    channel: null,
  );

  static ClientDFixtures? _cached;

  /// Real file IO: call from `setUpAll`, never inside a fake-async test body.
  static Future<ClientDFixtures> load() async {
    if (_cached != null) return _cached!;
    final file = File('../contracts/fixtures/bookings.json');
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    // The server adds `version` and `allowedActions`; the fixture rows lack them.
    Booking parse(Object? raw) => Booking.fromJson({'version': 1, 'allowedActions': <Object?>[], ...(raw as Map).cast<String, Object?>()});
    final bookings = [for (final b in json['bookings'] as List) parse(b)];
    final hero = <String, Booking>{for (final e in (json['heroVariants'] as Map<String, dynamic>).entries) e.key: parse((e.value as Map)['booking'])};
    final pending = bookings.firstWhere((b) => b.ref == 'GZ-2611-0147');
    hero['pending'] = pending;
    final vouchers = <String, Voucher>{
      for (final e in (json['heroVariants'] as Map<String, dynamic>).entries)
        e.key: Voucher.fromJson(((e.value as Map)['voucher'] as Map).cast<String, Object?>()),
    };
    final pkgJson = jsonDecode(await File('../contracts/fixtures/packages.json').readAsString());
    final pkgList = (pkgJson is List ? pkgJson : (pkgJson as Map).values.firstWhere((v) => v is List)) as List;
    final packages = <String, Package>{for (final x in pkgList) (x as Map)['id'] as String: Package.fromJson(x.cast<String, Object?>())};
    final client = jsonDecode(await File('../contracts/fixtures/client.json').readAsString()) as Map<String, dynamic>;
    final notifications = [
      for (final n in (client['notifications'] as List).take(8))
        AppNotification.fromJson({
          'tag': null,
          'bookingId': null,
          'venueId': null,
          'conversationId': null,
          'channel': 'transactional',
          'tone': 'neutral',
          'read': false,
          ...(n as Map).cast<String, Object?>(),
        }),
    ];
    return _cached = ClientDFixtures._(bookings, hero, vouchers, packages, notifications);
  }

  Booking byRef(String ref) => bookings.firstWhere((b) => b.ref == ref);
}
