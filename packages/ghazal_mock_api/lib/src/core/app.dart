/// The state of one mock backend: the database, the story clock, the scheduler, the identity store and the control knobs (persona, scenario,
/// latency). Handlers get the app and read and write through it; nothing here knows HTTP.
library;

import '../db/mock_db.dart';
import '../db/seeding.dart';
import '../engine/catalog.dart';
import '../engine/dates.dart';
import '../engine/json.dart';
import '../seed/seed_data.dart';
import 'clock.dart';
import 'problem.dart';
import 'request.dart';
import 'scheduler.dart';

/// The image prefix of the seeds (see [MockApp.imageBase]).
const defaultImageBase = 'asset://ghazal_mock_api/images/';

/// Scenario names understood by `X-Mock-Scenario` and `MockControl.setScenario`.
abstract final class Scenario {
  static const none = 'none';
  static const slow = 'slow';
  static const error = 'error';
  static const offline = 'offline';
  static const empty = 'empty';
  static const expired = 'expired';
  static const all = [slow, error, offline, empty, expired];
}

class MockConfig {
  MockConfig({
    this.clock,
    this.latency = Duration.zero,
    this.scenario = Scenario.none,
    this.persona = 'guest',
    this.gatewayDelay = const Duration(milliseconds: 1500),
    this.botDelay = const Duration(milliseconds: 2500),
    this.autoRun = true,
  });

  /// Story time at start and after `reset` (default: the prototype clock, 2026-11-12T16:00+03:00).
  DateTime? clock;
  Duration latency;
  String scenario;

  /// Requests without a bearer token act as this persona (`guest` = anonymous, the real behaviour).
  String persona;

  /// How long the mock payment gateway takes before it settles a payment session by itself.
  Duration gatewayDelay;

  /// How long the scripted chat replies take.
  Duration botDelay;

  /// Fire gateway and chat-bot work on real timers (the demo); tests set false and call `MockControl.flush()`.
  bool autoRun;
}

/// A partner membership of a user (what `GET /partner/me` lists).
class Membership {
  Membership({required this.accountId, required this.accountType, required this.accountName, this.venueId, this.providerId, required this.role, required this.feeExempt, required this.status, this.pendingRequests});
  final String accountId;
  final String accountType;
  final Json accountName;
  final String? venueId;
  final String? providerId;
  final String role;
  final bool feeExempt;
  final String status;

  /// A stored count for a venue the mock keeps as state only (the sister venue); null counts the pending requests.
  final int? pendingRequests;
}

const rolePermissions = <String, List<String>>{
  'admin': ['request:respond', 'voucher:redeem', 'visit:manage', 'calendar:edit', 'venue:edit', 'staff:manage', 'listing:manage', 'reviews:reply', 'analytics:view', 'windows:manage', 'billing:view'],
  'manager': ['request:respond', 'voucher:redeem', 'visit:manage', 'calendar:edit', 'venue:edit', 'listing:manage', 'reviews:reply', 'analytics:view', 'windows:manage'],
  'reception': ['voucher:redeem', 'visit:manage', 'calendar:edit'],
  'accountant': ['analytics:view', 'billing:view'],
  'marketing': ['windows:manage', 'listing:manage', 'reviews:reply', 'analytics:view'],
};

class MockApp {
  MockApp({required this.seed, MockConfig? config}) : config = config ?? MockConfig() {
    scheduler = Scheduler(autoRun: this.config.autoRun);
    clock = MockClock(this.config.clock ?? DateTime.parse(seed.now));
    reset(clock: false);
  }

  final SeedData seed;
  final MockConfig config;
  final MockDb db = MockDb();
  late final MockClock clock;
  late final Scheduler scheduler;

  /// Emails the mock "sent" (staff invitations, partner codes, password resets, calendar files): `/__mock/outbox`.
  final List<Json> outbox = [];

  /// Everything noteworthy that happened (state changes, notifications, scheduled work): `/__mock/events`.
  final List<Json> eventLog = [];

  /// Where the mock is reachable (the host of signed upload URLs): the in-process adapter answers for `mock.ghazal.local`; the standalone server sets its own URL.
  String baseUrl = 'http://mock.ghazal.local';

  /// Prefix of every image `baseUrl` in responses. The seeds say `asset://ghazal_mock_api/images/<imageId>` (the UI resolves it to the bundled
  /// `images/<imageId>_480.jpg` / `_960.jpg`); the standalone server rewrites it to `http://host:port/images/<imageId>` and serves the files.
  String imageBase = defaultImageBase;

  /// Switches of the control surface that are not scenarios (for example `gatewayDown`).
  final Map<String, Object?> flags = {};

  String get now => clock.now;
  Json get platformConfig => seed.config;
  int get voucherFeeFils => platformConfig.integer('voucherFeeFils');

  /// Story reset: fresh seeds, the clock back at its start, no sessions, no pending work.
  void reset({bool clock = true}) {
    scheduler.clear();
    seedDatabase(db, seed);
    outbox.clear();
    eventLog.clear();
    flags.clear();
    if (clock) this.clock.set(config.clock ?? DateTime.parse(seed.now));
  }

  void logEvent(String type, Json data) {
    eventLog.add({'at': now, 'type': type, ...data});
    if (eventLog.length > 2000) eventLog.removeRange(0, 500);
  }

  /// A read-only view of the live catalog for the engine selectors (windows, packages and claims edited through the API show up at once).
  EngineData engine([String? at]) => EngineData(
        venues: db.raw('Venue'),
        packages: db.raw('Package'),
        priceRules: db.raw('PriceRule'),
        extras: db.raw('Extra'),
        windows: db.raw('VoucherWindow'),
        claims: db.raw('CalendarClaim'),
        overrides: seed.extra.list('dayOverrides'),
        areas: seed.rows('Area'),
        governorates: seed.rows('Governorate'),
        visits: db.raw('VisitAppointment'),
        providers: db.raw('ServiceProvider'),
        config: platformConfig,
        now: at ?? now,
        explicitClaimVenues: {for (final c in seed.rows('CalendarClaim')) c.str('venueId')},
      );

  // ---------------------------------------------------------------- people

  Json? user(String id) => db.get('User', id);
  Json requireUser(String id) => user(id) ?? (throw ApiError.notFound('user'));

  String userName(String id, [String lang = 'en']) {
    final u = db.peek('User', id);
    if (u == null) return id;
    return lang == 'en' ? (u.strOrNull('nameLatin') ?? u.str('name')) : u.str('name');
  }

  Json? personaOf(String key) {
    for (final p in seed.extra.list('personas')) {
      if (p['key'] == key) return p;
    }
    return null;
  }

  /// Partner memberships of a user: account owner (admin), the seeded hotel memberships, and staff rows.
  List<Membership> membershipsOf(String userId) {
    final out = <Membership>[];
    final seen = <String>{};
    void add(Json account, String role, {String? venueId, int? pending}) {
      final key = '${account['id']}|${venueId ?? account['providerId']}';
      if (!seen.add(key)) return;
      out.add(Membership(
        accountId: account.str('id'),
        accountType: account.str('type'),
        accountName: account.obj('name'),
        venueId: venueId,
        providerId: account.strOrNull('providerId'),
        role: role,
        feeExempt: account.flag('feeExempt'),
        status: account.str('status'),
        pendingRequests: pending,
      ));
    }

    Json? accountForVenue(String venueId) {
      for (final a in db.raw('PartnerAccount')) {
        if (a.strings('venueIds').contains(venueId)) return a;
      }
      return null;
    }

    for (final a in db.raw('PartnerAccount')) {
      if (a['ownerUserId'] == userId) add(a, 'admin', venueId: a.strings('venueIds').isNotEmpty ? a.strings('venueIds').first : null);
    }
    for (final m in seed.extra.obj('hotel').list('memberships')) {
      if (m['userId'] == userId) {
        final a = accountForVenue(m.str('venueId'));
        if (a != null) add(a, m.str('role'), venueId: m.str('venueId'));
      }
    }
    for (final m in db.raw('Membership')) {
      if (m['userId'] == userId) {
        final a = accountForVenue(m.str('venueId'));
        if (a != null) add(a, m.str('role'), venueId: m.str('venueId'), pending: m.intOrNull('pendingRequests'));
      }
    }
    for (final s in db.raw('StaffMember')) {
      if (s['userId'] == userId && s['status'] == 'active') {
        final a = accountForVenue(s.str('venueId'));
        if (a != null) add(a, s.str('role'), venueId: s.str('venueId'));
      }
    }
    return out;
  }

  /// People who receive partner notifications of a venue or provider: owners, admins and managers.
  List<String> notifyTargets({String? venueId, String? providerId}) {
    final ids = <String>{};
    if (venueId != null) {
      for (final a in db.raw('PartnerAccount')) {
        if (a.strings('venueIds').contains(venueId) && a['ownerUserId'] != null) ids.add(a.str('ownerUserId'));
      }
      for (final m in seed.extra.obj('hotel').list('memberships')) {
        if (m['venueId'] == venueId && ['admin', 'manager'].contains(m['role'])) ids.add(m.str('userId'));
      }
      for (final s in db.raw('StaffMember')) {
        if (s['venueId'] == venueId && s['status'] == 'active' && ['admin', 'manager'].contains(s['role'])) ids.add(s.str('userId'));
      }
    }
    if (providerId != null) {
      for (final a in db.raw('PartnerAccount')) {
        if (a['providerId'] == providerId && a['ownerUserId'] != null) ids.add(a.str('ownerUserId'));
      }
    }
    return ids.toList();
  }

  /// The partner account (id) behind a venue or provider id.
  Json? accountOf({String? venueId, String? providerId}) {
    for (final a in db.raw('PartnerAccount')) {
      if (venueId != null && a.strings('venueIds').contains(venueId)) return a;
      if (providerId != null && a['providerId'] == providerId) return a;
    }
    return null;
  }

  bool can(Req r, String permission) {
    final role = r.partner?.role;
    return role != null && (rolePermissions[role]?.contains(permission) ?? false);
  }

  void requirePermission(Req r, String permission) {
    if (!can(r, permission)) throw ApiError.forbidden('permission $permission required');
  }

  // ---------------------------------------------------------------- sessions

  /// Opens a session for [userId] (a new device login) and returns the `AuthSession` JSON pieces: access and refresh token plus the session id.
  Json openSession(String userId, {String? deviceId, String? sessionId}) {
    final id = sessionId ?? 'sess-${db.next('session').toString().padLeft(4, '0')}';
    final existing = db.peek('Session', id);
    final session = existing != null
        ? {...deepCopy(existing), 'revoked': false}
        : {'id': id, 'userId': userId, 'deviceId': deviceId, 'gen': 1, 'rgen': 1, 'revoked': false, 'expiredGens': <int>[], 'skipExpire': false, 'createdAt': now};
    db.put('Session', session);
    return _tokensOf(session);
  }

  Json _tokensOf(Json s) => {'sessionId': s['id'], 'accessToken': 'gzm_at_${s['id']}_${s['gen']}', 'refreshToken': 'gzm_rt_${s['id']}_${s['rgen']}', 'tokenType': 'Bearer', 'expiresInSeconds': 600};

  /// Tokens of the always-on session of a persona (no OTP): the demo tools and `autoAuth` use it.
  Json personaTokens(String key) {
    final p = personaOf(key);
    final uid = p?['userId'] as String?;
    if (p == null || uid == null) throw StateError('persona $key has no user');
    if (db.peek('User', uid) == null && p['isNew'] == true) {
      // the brand-new client has no history: a verified phone and nothing else
      db.put('User', {'id': uid, 'role': 'client', 'name': p['nameAr'], 'nameLatin': p['name'], 'monogram': String.fromCharCode((p['nameAr'] as String).runes.first), 'phone': p['phone'], 'email': null, 'locale': 'ar', 'digitStyle': 'western', 'createdAt': now});
    }
    final sid = 'sess-persona-$key';
    final existing = db.peek('Session', sid);
    return existing != null && existing['revoked'] != true ? _tokensOf(existing) : openSession(uid, sessionId: sid);
  }

  /// Rotates the refresh token (reuse of an old one revokes the session). Returns new tokens.
  Json refreshSession(String refreshToken) {
    final m = RegExp(r'^gzm_rt_(.+)_(\d+)$').firstMatch(refreshToken);
    final s = m == null ? null : db.get('Session', m[1]!);
    if (s == null || s['revoked'] == true) throw ApiError('SESSION_REVOKED');
    if (int.parse(m![2]!) != s.integer('rgen')) {
      s['revoked'] = true;
      db.put('Session', s);
      throw ApiError('SESSION_REVOKED');
    }
    s['gen'] = s.integer('gen') + 1;
    s['rgen'] = s.integer('rgen') + 1;
    s['skipExpire'] = true;
    db.put('Session', s);
    return _tokensOf(s);
  }

  void revokeSession(String id) {
    final s = db.get('Session', id);
    if (s == null) return;
    s['revoked'] = true;
    db.put('Session', s);
  }

  /// The identity behind an access token, or an [ApiError] (AUTH_REQUIRED / TOKEN_EXPIRED / SESSION_REVOKED).
  Identity authenticate(String token) {
    final m = RegExp(r'^gzm_at_(.+)_(\d+)$').firstMatch(token);
    final s = m == null ? null : db.peek('Session', m[1]!);
    if (s == null) throw ApiError('AUTH_REQUIRED');
    if (s['revoked'] == true) throw ApiError('SESSION_REVOKED');
    final gen = int.parse(m![2]!);
    if ((s['expiredGens'] as List).contains(gen)) throw ApiError('TOKEN_EXPIRED');
    final user = db.get('User', s.str('userId'));
    if (user == null) throw ApiError('AUTH_REQUIRED');
    return Identity(userId: s.str('userId'), sessionId: s.str('id'), user: user);
  }

  /// `expired` scenario: expires the presented access token once (the client refreshes, replays and goes on).
  bool expireOnce(Identity id, String token) {
    final s = db.get('Session', id.sessionId);
    if (s == null) return false;
    if (s['skipExpire'] == true) {
      s['skipExpire'] = false;
      db.put('Session', s);
      return false;
    }
    final gen = int.parse(RegExp(r'_(\d+)$').firstMatch(token)![1]!);
    (s['expiredGens'] as List).add(gen);
    db.put('Session', s);
    return true;
  }

  /// The ad plans with the rates the control surface set (undecided rates stay `null`: the pay step is disabled and no number exists).
  List<Json> adPlans() {
    final rates = (flags['planRates'] as Map?)?.cast<String, int?>() ?? const <String, int?>{};
    return [for (final p in seed.rows('AdPlan')) rates.containsKey(p['cycle']) ? {...deepCopy(p), 'ratesFils': rates[p['cycle']]} : p];
  }

  // ---------------------------------------------------------------- misc helpers

  /// Resolves the display name of a venue or provider (LocalizedText).
  Json targetName({String? venueId, String? providerId}) {
    if (venueId != null) return db.peek('Venue', venueId)?.obj('name') ?? {'en': venueId, 'ar': venueId};
    final p = db.peek('ServiceProvider', providerId ?? '');
    return p?.obj('name') ?? {'en': providerId ?? '', 'ar': providerId ?? ''};
  }

  String today() => kuwaitDateOf(now);
}
