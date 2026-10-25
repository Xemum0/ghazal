/// One request as the handlers see it: path and query parameters (typed on demand), the validated JSON body, the signed-in identity and the
/// partner context. Handlers return plain JSON (maps, lists) or null for 204.
library;

import 'dart:async';

import '../engine/json.dart';
import 'problem.dart';

/// The signed-in identity of a request.
class Identity {
  Identity({required this.userId, required this.sessionId, required this.user});
  final String userId;
  final String sessionId;

  /// A copy of the user document (`User` wire shape).
  final Json user;

  String get role => user.str('role');
  bool get isPartner => role == 'hotel_staff' || role == 'provider_staff';
}

/// The active partner context of a call (`X-Venue-Id` or `X-Provider-Id`) with the caller's role in it.
class PartnerCtx {
  PartnerCtx({this.venueId, this.providerId, required this.accountId, required this.role});
  final String? venueId;
  final String? providerId;
  final String accountId;

  /// admin, manager, reception, accountant or marketing.
  final String role;

  /// The id of the venue or provider (whichever is set).
  String get targetId => venueId ?? providerId!;
  bool get isVenue => venueId != null;
}

class Req {
  Req({
    required this.method,
    required this.path,
    required this.pathParams,
    required this.query,
    required this.headers,
    required this.body,
    required this.operationId,
    this.identity,
    this.partner,
    this.lang = 'en',
  });

  final String method;
  final String path;
  final String operationId;
  final Map<String, String> pathParams;
  final Map<String, List<String>> query;
  final Map<String, String> headers;
  final Json? body;
  Identity? identity;
  PartnerCtx? partner;
  final String lang;

  /// Response headers a handler wants to add (`ETag`, `Location`).
  final Map<String, String> out = {};

  /// `If-Match` header, unquoted (`"v7"` becomes `v7`), or null.
  String? get ifMatch => headers['if-match']?.replaceAll('"', '').replaceAll('W/', '');

  String p(String name) => pathParams[name] ?? (throw ApiError.notFound(name));

  String? q(String name) {
    final v = query[name];
    return v == null || v.isEmpty ? null : v.first;
  }

  int? qInt(String name) => int.tryParse(q(name) ?? '');
  num? qNum(String name) => num.tryParse(q(name) ?? '');
  bool? qBool(String name) => switch (q(name)) {
    'true' => true,
    'false' => false,
    _ => null,
  };

  /// A list parameter sent as repeated keys or comma-separated; empty list when absent.
  List<String> qList(String name) => [for (final v in query[name] ?? const <String>[]) ...v.split(',').where((s) => s.isNotEmpty)];

  /// The JSON body (validated against the contract before the handler runs).
  Json get b => body ?? (throw ApiError.validation('/', 'required'));

  /// The signed-in user id; the router guarantees an identity on bearer routes.
  String get userId => identity?.userId ?? (throw ApiError('AUTH_REQUIRED'));

  PartnerCtx get ctx => partner ?? (throw ApiError('VENUE_CONTEXT_REQUIRED'));

  /// Page size: `limit` clamped to 1..50, default 20.
  int get limit => (qInt('limit') ?? 20).clamp(1, 50);
}

/// What a handler may return besides JSON: raw bytes (the receipt PDF).
class RawBody {
  RawBody(this.bytes, this.contentType);
  final List<int> bytes;
  final String contentType;
}

typedef Handler = FutureOr<Object?> Function(Req r);
