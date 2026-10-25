/// Shared helpers of the handlers: the `Me` document, public users, the actor name of a request, paging of lists and cursors.
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../engine/engine.dart';

/// `User` as sent on the wire (internal fields stripped).
Json publicUser(Json u) => wire(u);

/// `Me` of a user: user, permissions (partner roles map to permission keys), verification flags.
Json meOf(MockApp app, String userId) {
  final u = app.requireUser(userId);
  final memberships = app.membershipsOf(userId);
  final perms = <String>{for (final m in memberships) ...?rolePermissions[m.role]};
  return {
    'user': publicUser(u),
    'permissions': perms.toList()..sort(),
    'phoneVerified': u['_phoneVerified'] != false,
    'emailVerified': u['email'] != null,
    'hasPassword': u['_password'] != null || u['role'] == 'client' || u['role'] == 'hotel_staff' || u['role'] == 'provider_staff',
    'marketingOptIn': u['_marketingOptIn'] == true || (app.db.peek('NotificationPreferences', userId)?['marketing'] == true),
  };
}

/// Latin display name of the acting user (for event logs and chat sender names).
String actorName(Req r) {
  final u = r.identity?.user;
  return u == null ? '' : (u.strOrNull('nameLatin') ?? u.str('name'));
}

/// Opens a session for the user and returns the `AuthSession` JSON.
Json authSession(MockApp app, String userId, {bool isNew = false, String? deviceId}) {
  final t = app.openSession(userId, deviceId: deviceId);
  return {
    'accessToken': t['accessToken'],
    'refreshToken': t['refreshToken'],
    'tokenType': 'Bearer',
    'expiresInSeconds': 600,
    'isNewUser': isNew,
    'user': meOf(app, userId),
  };
}

/// The partner account JSON of the active context.
Json partnerAccountOf(MockApp app, Req r) {
  final c = r.ctx;
  return app.db.get('PartnerAccount', c.accountId) ?? (throw ApiError.notFound('account'));
}

/// A page of [list] sorted by [compare] (copies go out; the list is the caller's).
Json pageSorted<T>(Req r, List<T> list, int Function(T, T) compare, Object? Function(T) build) {
  final sorted = stableSorted(list, compare);
  final start = _cursorStart(r);
  final slice = sorted.skip(start).take(r.limit).map(build).toList();
  return {'items': slice, 'nextCursor': start + r.limit < sorted.length ? _enc(start + r.limit) : null};
}

int _cursorStart(Req r) {
  final c = r.q('cursor');
  if (c == null || c.isEmpty) return 0;
  return decodeCursor(c);
}

String _enc(int n) => encodeCursor(n);
