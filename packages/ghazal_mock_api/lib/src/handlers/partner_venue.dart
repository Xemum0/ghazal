/// partner-venue: the venue profile, halls, packages with their price rules and voucher prices, extras, policies, booking rules, hours and media.
/// Settings documents carry ETags; a stale `If-Match` is a 412.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../engine/engine.dart';
import 'chat.dart' show uploadSession;
import 'partner_common.dart';
import 'venues.dart' show publicVenue;

int _completeness(Json v, String lang) {
  var have = 0, total = 0;
  void chk(Object? lt) {
    total++;
    if (lt is Map && ((lt[lang] as String?) ?? '').trim().isNotEmpty) have++;
  }

  chk(v['name']);
  chk(v['tagline']);
  chk(v['description']);
  chk(v.obj('address')['street']);
  for (final h in v.list('halls')) {
    chk(h['name']);
    chk(h['description']);
  }
  total += 2;
  if (v.list('gallery').length >= 5) have++;
  if (v.list('amenities').length >= 5) have++;
  return total == 0 ? 0 : jsRound(have / total * 100);
}

Json _partnerVenue(MockApp app, Req r, Json v) {
  final s = venueSettings(app, v.str('id'));
  final account = app.accountOf(venueId: v.str('id'));
  return {
    'venue': publicVenue(v),
    'listingCompleteness': s.str('venueId') == 'V01' ? s['listingCompleteness'] : {'ar': _completeness(v, 'ar'), 'en': _completeness(v, 'en')},
    'feeExempt': account?['feeExempt'] ?? false,
  };
}

String _slug(Json name, int seq) {
  final en = (name['en'] as String?) ?? '';
  final s = en.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  return s.isEmpty ? 'hall$seq' : s;
}

Json _hallFrom(Json input, String venueId, String id, {Json? existing}) => {
      'id': id,
      'venueId': venueId,
      'name': input['name'],
      'setting': input['setting'],
      'capacity': input['capacity'],
      'exclusiveDay': input['exclusiveDay'],
      'sessions': [
        for (final (i, s) in input.list('sessions').indexed)
          {'id': s['id'] ?? '$id-s${i + 1}', 'name': s['name'], 'start': s['start'], 'end': s['end'], 'bufferBeforeMin': s['bufferBeforeMin'] ?? 0, 'bufferAfterMin': s['bufferAfterMin'] ?? 0, 'weekdays': s['weekdays']}
      ],
      'sections': input['sections'],
      'seasonMonths': input['seasonMonths'],
      'description': input['description'] ?? existing?['description'] ?? {'en': '', 'ar': ''},
      'cover': existing?['cover'],
    };

Json _editor(MockApp app, Json pkg) => {'package': wire(pkg), 'rules': [for (final x in app.db.raw('PriceRule')) if (x['scopeId'] == pkg['id']) wire(x)]};

void _validateVoucherNotHigher(List<Json> rules) {
  for (final (i, r) in rules.indexed) {
    for (final pair in [('flat', 'voucherFlat'), ('perGuest', 'voucherPerGuest')]) {
      final std = r.objOrNull(pair.$1), v = r.objOrNull(pair.$2);
      if (std != null && v != null && filsOf(v) > filsOf(std)) throw ApiError.validation('/rules/$i/${pair.$2}', 'voucher_price_above_standard');
    }
  }
}

Json _savePackage(MockApp app, Req r, Json venue, Json input, {Json? existing}) {
  final venueId = venue.str('id');
  final rules = input.list('rules');
  _validateVoucherNotHigher(rules);
  for (final h in input.strings('hallIds')) {
    if (!venue.list('halls').any((x) => x['id'] == h)) throw ApiError.validation('/hallIds', 'unknown_hall');
  }
  final seq = app.db.next('package');
  final id = existing?.str('id') ?? '$venueId-${_slug(input.obj('name'), seq)}-m$seq';
  // headline columns: the cheapest rule's per-guest (or flat) price in both columns
  int std = 0;
  int? vch;
  for (final x in rules) {
    final s = filsOf(x.objOrNull('perGuest') ?? x.objOrNull('flat'));
    final v = x.objOrNull('voucherPerGuest') ?? x.objOrNull('voucherFlat');
    if (std == 0 || s < std) {
      std = s;
      vch = v == null ? null : filsOf(v);
    }
  }
  final pkg = <String, dynamic>{
    'id': id,
    'venueId': venueId,
    'hallIds': input['hallIds'],
    'name': input['name'],
    'archetype': input['archetype'],
    'audiences': input['audiences'],
    'pricingBasis': input['pricingBasis'],
    'priceStructure': input['priceStructure'],
    'priceUnit': input['priceUnit'],
    'standardFils': std,
    'voucherFils': vch,
    'voucherDiscountBps': vch == null || std == 0 ? null : discountBps(std, vch),
    'minGuests': input['minGuests'],
    'maxGuests': input['maxGuests'],
    'guestStep': input['guestStep'],
    'complimentaryBps': input['complimentaryBps'],
    'description': input['description'] ?? existing?['description'] ?? {'en': '', 'ar': ''},
    'inclusions': input['inclusions'] ?? existing?['inclusions'] ?? <Json>[],
    'notes': input['notes'] ?? existing?['notes'] ?? <Json>[],
    'components': input['components'],
    'active': input['active'] ?? existing?['active'] ?? true,
    'sortOrder': existing?['sortOrder'] ?? (app.db.raw('Package').where((p) => p['venueId'] == venueId).length + 1),
  };
  app.db.put('Package', pkg);
  for (final x in app.db.raw('PriceRule').toList()) {
    if (x['scopeId'] == id) app.db.remove('PriceRule', x.str('id'));
  }
  for (final (i, x) in rules.indexed) {
    final rid = x['id'] as String? ?? '$id-r${i + 1}';
    app.db.put('PriceRule', {
      'id': rid,
      'scope': 'package',
      'scopeId': id,
      'tier': x['tier'],
      'weekdays': x['weekdays'],
      'validFrom': x['validFrom'],
      'validTo': x['validTo'],
      'specialDate': x['specialDate'],
      'priority': x['priority'],
      'flat': x['flat'],
      'perGuest': x['perGuest'],
      'voucherFlat': x['voucherFlat'],
      'voucherPerGuest': x['voucherPerGuest'],
      if (x['label'] != null) 'label': x['label'],
    });
  }
  return pkg;
}

Json _extraFrom(Json input, String venueId, String id, {Json? existing}) => {
      'id': id,
      'venueId': venueId,
      'category': input['category'],
      'name': input['name'],
      'description': input['description'] ?? existing?['description'] ?? {'en': '', 'ar': ''},
      'pricingUnit': input['pricingUnit'],
      'price': input['price'],
      'priceMin': input['priceMin'],
      'priceMax': input['priceMax'],
      'maxQty': input['maxQty'],
      'includedInPackageIds': input['includedInPackageIds'] ?? existing?['includedInPackageIds'] ?? <String>[],
      'audiences': input['audiences'] ?? existing?['audiences'] ?? <String>[],
      'unitLabel': input['unitLabel'],
      'active': input['active'] ?? existing?['active'] ?? true,
    };

Json _library(MockApp app, String venueId) {
  final items = stableSorted(app.db.raw('MediaItem').where((m) => m['_venueId'] == venueId), (a, b) => a.integer('order') - b.integer('order'));
  return {'items': items.map(wire).toList(), 'limits': {'videoMaxBytes': 500 * 1024 * 1024, 'photoMaxBytes': 25 * 1024 * 1024}};
}

Json _media(MockApp app, Req r) {
  final m = app.db.get('MediaItem', r.p('mediaId'));
  if (m == null || m['_venueId'] != r.ctx.venueId) throw ApiError.notFound('media');
  return m;
}

Map<String, Handler> partnerVenueHandlers(MockApp app) => {
      'getPartnerVenue': (r) {
        final v = requireVenue(app, r);
        setEtag(app, r, 'venue:${v['id']}');
        return _partnerVenue(app, r, v);
      },
      'updatePartnerVenue': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        final key = 'venue:${v['id']}';
        checkDocMatch(app, r, key);
        for (final k in ['name', 'tagline', 'description', 'phone', 'address', 'geo']) {
          if (r.b.containsKey(k)) v[k] = r.b[k];
        }
        app.db.put('Venue', v);
        bumpDoc(app, r, key);
        return _partnerVenue(app, r, v);
      },
      'listPartnerHalls': (r) => {'halls': requireVenue(app, r)['halls']},
      'createHall': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        final seq = app.db.next('hall');
        final id = '${v['id']}-${_slug(r.b.obj('name'), seq)}-m$seq';
        final hall = _hallFrom(r.b, v.str('id'), id);
        v['halls'] = [...v.list('halls'), hall];
        app.db.put('Venue', v);
        return hall;
      },
      'updateHall': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        final key = 'hall:${r.p('hallId')}';
        checkDocMatch(app, r, key);
        final halls = v.list('halls');
        final i = halls.indexWhere((h) => h['id'] == r.p('hallId'));
        if (i < 0) throw ApiError.notFound('hall');
        halls[i] = _hallFrom(r.b, v.str('id'), r.p('hallId'), existing: halls[i]);
        v['halls'] = halls;
        app.db.put('Venue', v);
        bumpDoc(app, r, key);
        return halls[i];
      },
      'setVenueAmenities': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        v['amenities'] = r.b['amenities'];
        app.db.put('Venue', v);
        return {'amenities': v['amenities']};
      },
      'listPartnerPackages': (r) {
        final v = requireVenue(app, r);
        final pk = stableSorted(app.db.raw('Package').where((p) => p['venueId'] == v['id']), (a, b) => (a.intOrNull('sortOrder') ?? 0) - (b.intOrNull('sortOrder') ?? 0));
        return {'packages': [for (final p in pk) _editor(app, p)], 'extras': app.db.raw('Extra').where((e) => e['venueId'] == v['id']).map(wire).toList()};
      },
      'createPackage': (r) {
        app.requirePermission(r, 'venue:edit');
        return _editor(app, _savePackage(app, r, requireVenue(app, r), r.b));
      },
      'updatePackage': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        final existing = app.db.get('Package', r.p('packageId'));
        if (existing == null || existing['venueId'] != v['id']) throw ApiError.notFound('package');
        final key = 'package:${existing['id']}';
        checkDocMatch(app, r, key);
        final out = _editor(app, _savePackage(app, r, v, r.b, existing: existing));
        bumpDoc(app, r, key);
        return out;
      },
      'createExtra': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        final e = _extraFrom(r.b, v.str('id'), '${v['id']}-extra-m${app.db.next('extra')}');
        app.db.put('Extra', e);
        return e;
      },
      'updateExtra': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        final existing = app.db.get('Extra', r.p('extraId'));
        if (existing == null || existing['venueId'] != v['id']) throw ApiError.notFound('extra');
        final e = _extraFrom(r.b, v.str('id'), existing.str('id'), existing: existing);
        app.db.put('Extra', e);
        return e;
      },
      'getVenuePolicies': (r) {
        final v = requireVenue(app, r);
        setEtag(app, r, 'policies:${v['id']}');
        return v['policies'];
      },
      'putVenuePolicies': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        final key = 'policies:${v['id']}';
        checkDocMatch(app, r, key);
        v['policies'] = r.b;
        app.db.put('Venue', v);
        bumpDoc(app, r, key);
        return r.b;
      },
      'getBookingRules': (r) {
        final v = requireVenue(app, r);
        setEtag(app, r, 'rules:${v['id']}');
        return venueSettings(app, v.str('id')).obj('bookingRules');
      },
      'putBookingRules': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        final key = 'rules:${v['id']}';
        checkDocMatch(app, r, key);
        final s = venueSettings(app, v.str('id'));
        s['bookingRules'] = {'responseSlaHours': r.b['responseSlaHours'], 'confirmWindowHours': 24, 'visitsEnabled': r.b['visitsEnabled']};
        saveSettings(app, s);
        final policies = v.obj('policies');
        policies['responseSlaHours'] = r.b['responseSlaHours'];
        v['policies'] = policies;
        app.db.put('Venue', v);
        bumpDoc(app, r, key);
        return s.obj('bookingRules');
      },
      'getBusinessHours': (r) => requireVenue(app, r)['hours'],
      'putBusinessHours': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        v['hours'] = r.b;
        app.db.put('Venue', v);
        return r.b;
      },
      'listVenueMedia': (r) => _library(app, requireVenue(app, r).str('id')),
      'createMediaUploadSession': (r) {
        requireVenue(app, r);
        final kind = r.b.str('kind');
        return uploadSession(app, {...r.b, 'purpose': kind == 'video' ? 'venue_video' : 'venue_photo'});
      },
      'completeMediaUpload': (r) {
        app.requirePermission(r, 'venue:edit');
        final v = requireVenue(app, r);
        final up = app.db.get('Upload', r.p('uploadId')) ?? (throw ApiError.notFound('upload'));
        if (up['completed'] == true) throw ApiError.validation('/uploadId', 'already_completed');
        up['completed'] = true;
        app.db.put('Upload', up);
        final isVideo = up['purpose'] == 'venue_video';
        final order = app.db.raw('MediaItem').where((m) => m['_venueId'] == v['id']).length + 1;
        // the mock stores nothing: the photo reuses a venue photo so the library renders; a video has no image
        final gallery = v.list('gallery');
        final src = gallery.isEmpty ? null : gallery[order % gallery.length];
        final alt = r.body?['alt'];
        final item = <String, dynamic>{
          'id': 'media-${v['id']}-m${app.db.next('media')}',
          'kind': isVideo ? 'video' : 'photo',
          'zone': 'hall',
          'hallId': null,
          'status': 'ready',
          'sizeBytes': up['sizeBytes'],
          if (isVideo) 'durationSeconds': 45,
          'isCover': false,
          'order': order,
          'createdAt': app.now,
          'image': isVideo || src == null ? null : {for (final e in src.entries) if (e.key != 'zone' && e.key != 'hallId') e.key: e.value, 'alt': ?alt},
          '_venueId': v['id'],
        };
        app.db.put('MediaItem', item);
        return wire(item);
      },
      'reorderMedia': (r) {
        final v = requireVenue(app, r);
        final ids = r.b.strings('ids');
        var n = 0;
        for (final id in ids) {
          final m = app.db.get('MediaItem', id);
          if (m == null || m['_venueId'] != v['id']) throw ApiError.notFound('media');
          m['order'] = ++n;
          app.db.put('MediaItem', m);
        }
        for (final m in app.db.raw('MediaItem').where((m) => m['_venueId'] == v['id'] && !ids.contains(m['id'])).toList()) {
          app.db.put('MediaItem', {...deepCopy(m), 'order': ++n});
        }
        return _library(app, v.str('id'));
      },
      'updateMediaItem': (r) {
        app.requirePermission(r, 'venue:edit');
        final m = _media(app, r);
        for (final k in ['zone', 'hallId']) {
          if (r.b.containsKey(k)) m[k] = r.b[k];
        }
        if (r.b['alt'] != null && m['image'] != null) (m['image'] as Map)['alt'] = r.b['alt'];
        if (r.b['isCover'] == true) {
          for (final o in app.db.raw('MediaItem').where((o) => o['_venueId'] == m['_venueId'] && o['isCover'] == true).toList()) {
            app.db.put('MediaItem', {...deepCopy(o), 'isCover': false});
          }
          m['isCover'] = true;
          final v = requireVenue(app, r);
          if (m['image'] != null) {
            v['cover'] = m['image'];
            app.db.put('Venue', v);
          }
        } else if (r.b['isCover'] == false) {
          m['isCover'] = false;
        }
        app.db.put('MediaItem', m);
        return wire(m);
      },
      'deleteMediaItem': (r) {
        app.requirePermission(r, 'venue:edit');
        final m = _media(app, r);
        app.db.remove('MediaItem', m.str('id'));
        return null;
      },
    };
