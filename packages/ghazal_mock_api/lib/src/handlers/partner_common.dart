/// Helpers shared by the partner handlers: the venue of the context, per-venue settings, optimistic-concurrency ETags of settings documents.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart' show wire;
import '../engine/engine.dart';
import '../domain/requests.dart' as dom;

/// The venue document of the context (venue contexts only: providers have no halls, calendar or visits).
Json requireVenue(MockApp app, Req r) {
  final id = r.ctx.venueId ?? (throw ApiError.forbidden('this call needs a venue context'));
  return app.db.get('Venue', id) ?? (throw ApiError.notFound('venue'));
}

/// The application of a partner account (round 2, PA-ACC-07), or null for an account Ghazal assigned (those are accepted).
Json? applicationOfAccount(MockApp app, String accountId) => app.db.firstWhere('PartnerApplication', (a) => a['accountId'] == accountId);

/// Only an accepted account can create listings: an account with a pending or rejected application is refused (403 `APPLICATION_NOT_ACCEPTED`).
void requireAcceptedAccount(MockApp app, String accountId) {
  final a = applicationOfAccount(app, accountId);
  if (a != null && a['status'] != 'accepted') throw ApiError('APPLICATION_NOT_ACCEPTED', params: {'applicationStatus': a['status']});
}

/// The provider id of the context (provider contexts only).
String requireProviderId(Req r) => r.ctx.providerId ?? (throw ApiError.forbidden('this call needs a provider context'));

/// Per-venue settings, created from the venue on first use (the seeded hotel has its own).
Json venueSettings(MockApp app, String venueId) {
  final existing = app.db.get('VenueSettings', venueId);
  if (existing != null) return existing;
  final v = app.db.require('Venue', venueId);
  final doc = {
    'id': venueId,
    'venueId': venueId,
    'hours': v['hours'],
    'notificationPrefs': {'newRequestAlwaysOn': true, 'messages': true, 'reviews': true, 'vouchers': true, 'visits': true},
    'listingCompleteness': {'ar': 90, 'en': 80},
    'bookingRules': {
      'responseSlaHours': v.obj('policies').intOrNull('responseSlaHours') ?? 24,
      'confirmWindowHours': 24,
      'visitsEnabled': v.list('visitSlots').isNotEmpty,
    },
    'calendarSync': {'channel': 'email', 'address': '', 'ics': false},
    'reliabilityStrikes': 0,
  };
  app.db.put('VenueSettings', doc);
  return doc;
}

void saveSettings(MockApp app, Json s) => app.db.put('VenueSettings', s, id: s.str('venueId'));

/// ETag of a settings document: `"vN"`.
void setEtag(MockApp app, Req r, String key) => r.out['ETag'] = '"v${app.db.versionOf(key)}"';

/// Compare-and-swap on a settings document: a stale `If-Match` is a 412.
void checkDocMatch(MockApp app, Req r, String key) {
  final m = r.ifMatch;
  if (m != null && m != 'v${app.db.versionOf(key)}') throw ApiError('PRECONDITION_FAILED', currentVersion: app.db.versionOf(key));
}

void bumpDoc(MockApp app, Req r, String key) {
  app.db.bumpVersion(key);
  setEtag(app, r, key);
}

/// The request of the context (a venue's or a provider's), or 404.
Json ctxBooking(MockApp app, Req r) {
  final b = dom.requireBooking(app, r.p('requestId'));
  final c = r.ctx;
  if (c.venueId != null ? b['venueId'] != c.venueId : b['providerId'] != c.providerId) throw ApiError.notFound('request');
  return b;
}

/// Requests of the context.
List<Json> ctxBookings(MockApp app, Req r) {
  final c = r.ctx;
  return [
    for (final b in app.db.raw('Booking'))
      if (c.venueId != null ? b['venueId'] == c.venueId : b['providerId'] == c.providerId) b,
  ];
}

/// The inviter of a staff member or an invitation in both languages (`invitedByName`, next to the Latin `invitedBy` the contract has always carried):
/// the name of the staff member whose Latin name it is, else the Latin name in both slots. Null without an inviter.
Json? invitedByName(MockApp app, String? latin) {
  if (latin == null) return null;
  final m = app.db.firstWhere('StaffMember', (x) => x['nameLatin'] == latin);
  return {'en': latin, 'ar': m?['name'] ?? latin};
}

/// An invitation as the apps read it (with `invitedByName`).
Json invitationView(MockApp app, Json inv) => {...wire(inv), 'invitedByName': invitedByName(app, inv.strOrNull('invitedBy'))};
