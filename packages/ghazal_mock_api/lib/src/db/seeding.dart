/// Loads the seeds into a fresh [MockDb]: every collection of the wire-mapped fixtures as it is, plus the documents the mock derives from them
/// (the media library from the venue galleries, per-user wedding data keyed by user, credit vouchers next to vouchers). Derivations add
/// nothing the fixtures do not already say.
library;

import '../engine/json.dart';
import '../seed/seed_data.dart';
import 'mock_db.dart';

/// Collections that stay read-only reference data (read straight from the seed, never copied into the database).
const referenceCollections = {
  'FilterTaxonomy',
  'AmenityDef',
  'Governorate',
  'Area',
  'ReferencePoint',
  'FaqItem',
  'AdPlan',
  'BudgetBand',
  'ServiceGroup',
  'ServiceCategory',
  'PlannerPackage',
  'Planner',
  'PlatformConfig',
  'VenueSummary',
  'ReviewDecision',
  'RequestItem',
};

void seedDatabase(MockDb db, SeedData seed) {
  db.clear();
  final clientUser = seed.extra.obj('meta').str('clientUserId');
  for (final entry in seed.collections.entries) {
    final name = entry.key;
    if (referenceCollections.contains(name)) continue;
    switch (name) {
      case 'ChecklistItem':
        db.putAll(name, entry.value.map((d) => {...deepCopy(d), '_userId': clientUser}));
      case 'SavedItem':
        db.putAll(name, entry.value.map((d) => {...deepCopy(d), '_userId': clientUser}), key: (d) => '$clientUser|${d['type']}|${d['id']}');
      case 'WeddingProfile':
        db.putAll(name, entry.value, key: (d) => d.str('userId'));
      case 'NotificationPreferences':
        db.putAll(name, entry.value, key: (d) => d.str('userId'));
      case 'Budget':
        for (final b in entry.value) {
          final copy = deepCopy(b);
          final expenses = (copy.remove('expenses') as List?)?.cast<Json>() ?? const <Json>[];
          db.put(name, {...copy, 'id': clientUser, '_userId': clientUser}, id: clientUser);
          db.putAll('Expense', expenses.map((e) => {...e, '_userId': clientUser}));
        }
      case 'Analytics':
        db.putAll(name, entry.value, key: (d) => d.str('venueId'));
      case 'Message':
        db.putAll(name, entry.value);
      case 'CreditVoucher':
        db.putAll('Voucher', entry.value);
      default:
        db.putAll(name, entry.value);
    }
  }
  _deriveMedia(db);
  // venue settings of the seeded hotel (hours, preferences, billing, calendar sync); the others get defaults on first use
  final hotel = seed.extra.obj('hotel');
  final settings = hotel.obj('settings');
  db.put('VenueSettings', {...deepCopy(settings), 'id': settings.str('venueId')}, id: settings.str('venueId'));
  db.put('SoftDates', {'id': settings.str('venueId'), 'dates': hotel.strings('softDates'), 'optedOut': hotel.strings('softDateOptOut')});
}

/// The partner media library: one item per gallery photo of each venue, plus a ready video when the venue has one.
void _deriveMedia(MockDb db) {
  for (final v in db.raw('Venue')) {
    final id = v.str('id');
    final gallery = v.list('gallery');
    final coverFile = v.objOrNull('cover')?['file'];
    var order = 0;
    for (final g in gallery) {
      order++;
      final image = {for (final e in g.entries) if (e.key != 'zone' && e.key != 'hallId') e.key: e.value};
      db.put('MediaItem', {
        'id': 'media-$id-$order',
        'kind': 'photo',
        'zone': g['zone'],
        'hallId': g['hallId'],
        'status': 'ready',
        'sizeBytes': 380000 + order * 1337,
        'isCover': g['file'] == coverFile && order == gallery.indexWhere((x) => x['file'] == coverFile) + 1,
        'order': order,
        'createdAt': '2026-06-02T10:00:00+03:00',
        'image': image,
        '_venueId': id,
      });
    }
    if (v.flag('hasVideo')) {
      order++;
      db.put('MediaItem', {
        'id': 'media-$id-video',
        'kind': 'video',
        'zone': 'hall',
        'hallId': null,
        'status': 'ready',
        'sizeBytes': 48000000,
        'durationSeconds': 62,
        'isCover': false,
        'order': order,
        'createdAt': '2026-06-02T10:30:00+03:00',
        'image': null,
        '_venueId': id,
      });
    }
  }
}
