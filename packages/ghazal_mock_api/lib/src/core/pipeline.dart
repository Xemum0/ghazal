/// The HTTP pipeline of the mock: a shelf handler built from the contract's route table and the handlers by operation id. Order of a request:
/// scenario and latency, route match, app version, system jobs, bearer auth (or the persona), partner context, body and query validation,
/// idempotency replay, the handler, problem+json on any [ApiError]. Used by the in-process adapter and the standalone server alike.
library;

import 'localize.dart';

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart';

import '../db/mock_db.dart';
import '../domain/jobs.dart';
import '../engine/json.dart';
import 'app.dart';
import 'problem.dart';
import 'request.dart';
import 'validator.dart';

/// Thrown by the pipeline when the `offline` scenario is active: the in-process adapter turns it into a connection error (like a phone with no
/// network); the standalone server answers 503 with `X-Mock-Offline: 1`.
class MockOffline implements Exception {
  const MockOffline();
  @override
  String toString() => 'MockOffline: the mock is in the offline scenario';
}

class _Route {
  _Route(this.spec);
  final Json spec;
  String get id => spec.str('id');
  String get method => spec.str('method');
  String get path => spec.str('path');
  int get status => spec.integer('status');
  String get access => spec.str('access');
  bool get idempotent => spec.flag('idempotent');
  List<Json> get params => spec.list('params');
  Json? get body => spec.objOrNull('body');
  bool get bodyRequired => spec.flag('bodyRequired');
  bool get returnsNothing => spec.str('response') == 'none';
  bool get isPartnerPath => path.startsWith('/partner/') || path == '/partner';
}

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};
const _problemHeaders = {'content-type': 'application/problem+json; charset=utf-8'};

/// Operations of `/partner/*` that run without a venue or provider context (they establish or list it).
const _noContextOps = {'getPartnerMe', 'chooseAccountType', 'switchPartnerContext'};

/// Cross-app operations that serve a partner when a context header is present (chat, notifications, support).
const _optionalContextOps = {
  'listConversations',
  'getConversation',
  'listMessages',
  'sendMessage',
  'markConversationRead',
  'setConversationPinned',
  'saveReplyDraft',
  'createAttachmentUpload',
  'listNotifications',
  'getUnreadNotificationCount',
  'markNotificationRead',
  'markAllNotificationsRead',
  'getSupportConversation',
};

shelf.Handler buildHandler(MockApp app, Map<String, Handler> handlers) {
  final routes = [for (final r in app.seed.routes.list('routes')) _Route(r)];
  final missing = [
    for (final r in routes)
      if (!handlers.containsKey(r.id)) r.id,
  ];
  if (missing.isNotEmpty) throw StateError('operations without a handler: ${missing.join(', ')}');
  final validator = SchemaValidator(app.seed.routes.obj('schemas'));
  final byId = {for (final r in routes) r.id: r};
  final router = Router(notFoundHandler: (req) => _problem(ApiError.notFound('route ${req.url.path}'), req.headers['x-request-id']));
  // static paths first so `/venues/count` wins over `/venues/<venueId>`
  final ordered = [...routes]..sort((a, b) => '<'.allMatches(a.path).length.compareTo('<'.allMatches(b.path).length));
  for (final r in ordered) {
    final path = '/v1${r.path.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => '<${m[1]}>')}';
    router.add(r.method, path, (shelf.Request req) => _serve(app, byId[r.id]!, handlers[r.id]!, validator, req));
  }
  return (shelf.Request req) async {
    try {
      return await router(req);
    } on MockOffline {
      rethrow;
    }
  };
}

Future<shelf.Response> _serve(MockApp app, _Route route, Handler handler, SchemaValidator validator, shelf.Request request) async {
  final requestId = request.headers['x-request-id'] ?? 'req-${app.db.next('request').toString().padLeft(6, '0')}';
  try {
    final headers = {for (final e in request.headers.entries) e.key.toLowerCase(): e.value};
    final scenario = headers['x-mock-scenario'] ?? app.config.scenario;
    if (scenario == Scenario.offline) throw const MockOffline();
    final latencyHeader = int.tryParse(headers['x-mock-latency'] ?? '');
    final latency = latencyHeader != null
        ? Duration(milliseconds: latencyHeader)
        : (scenario == Scenario.slow && app.config.latency == Duration.zero ? const Duration(milliseconds: 1500) : app.config.latency);
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (scenario == Scenario.error) {
      return shelf.Response(
        500,
        body: jsonEncode({
          'type': 'about:blank',
          'title': 'Injected failure',
          'status': 500,
          'code': internalError,
          'detail': 'X-Mock-Scenario: error',
          'requestId': requestId,
        }),
        headers: _problemHeaders,
      );
    }
    _checkAppVersion(app, headers['x-app-version']);
    sweep(app);

    final lang = (headers['accept-language'] ?? 'en').toLowerCase().startsWith('ar') ? 'ar' : 'en';
    final bodyText = await request.readAsString();
    Json? body;
    if (bodyText.isNotEmpty) {
      try {
        final decoded = jsonDecode(bodyText);
        if (decoded is Map) body = decoded.cast<String, dynamic>();
        if (decoded is! Map && route.body != null) throw ApiError.validation('/', 'invalid_type');
      } on FormatException {
        throw ApiError.validation('/', 'invalid_json');
      }
    }

    final req = Req(
      method: route.method,
      path: route.path,
      pathParams: {for (final e in request.params.entries) e.key: Uri.decodeComponent(e.value)},
      query: request.url.queryParametersAll,
      headers: headers,
      body: body,
      operationId: route.id,
      lang: lang,
    );
    _authenticate(app, route, req, headers['authorization'], scenario);
    _resolvePartner(app, route, req, headers);
    _validate(route, req, validator, body, bodyText.isNotEmpty);

    // idempotent replay
    final key = headers['idempotency-key'];
    String? replayKey;
    if (route.idempotent && key != null && key.isNotEmpty) {
      replayKey = '${req.identity?.userId ?? '-'}|${route.method} ${request.url.path}|$key';
      final prior = app.db.peek('Idempotency', replayKey);
      final fingerprint = '${route.id}|${jsonEncode(body)}|${req.pathParams}';
      if (prior != null) {
        if (prior['fingerprint'] != fingerprint) throw ApiError('IDEMPOTENCY_KEY_REUSED');
        return _json(prior.integer('status'), prior['body'], {
          'idempotent-replayed': 'true',
          'x-request-id': requestId,
          ...(prior['headers'] as Map).cast<String, String>(),
        }, app.imageBase);
      }
      replayKey = '$replayKey\u0000$fingerprint';
    }

    final result = await handler(req);
    var payload = result;
    if (scenario == Scenario.empty && route.method == 'GET') payload = _emptied(route.id, result);
    final out = <String, String>{'x-request-id': requestId, ...req.out};
    if (result is RawBody) {
      return shelf.Response(route.status, body: result.bytes, headers: {'content-type': result.contentType, ...out});
    }
    final status = route.status;
    final bodyOut = route.returnsNothing ? null : localizeNames(app, payload, req.lang, partner: route.isPartnerPath || req.partner != null);
    if (replayKey != null) {
      final parts = replayKey.split('\u0000');
      app.db.put('Idempotency', {
        'id': parts[0],
        'fingerprint': parts[1],
        'status': status,
        'body': bodyOut,
        'headers': {for (final e in req.out.entries) e.key: e.value},
      }, id: parts[0]);
    }
    return _json(status, bodyOut, out, app.imageBase);
  } on ApiError catch (e) {
    app.logEvent('error', {'operation': route.id, 'code': e.code, 'status': e.status});
    return _problem(e, requestId);
  } on NotInDb catch (e) {
    return _problem(ApiError.notFound('${e.collection} ${e.id}'), requestId);
  } on MockOffline {
    rethrow;
  } catch (e, st) {
    app.logEvent('internal_error', {'operation': route.id, 'error': e.toString()});
    return shelf.Response(
      500,
      body: jsonEncode({
        'type': 'about:blank',
        'title': 'Mock internal error',
        'status': 500,
        'code': internalError,
        'detail': '$e\n${st.toString().split('\n').take(6).join('\n')}',
        'requestId': requestId,
      }),
      headers: _problemHeaders,
    );
  }
}

shelf.Response _json(int status, Object? body, Map<String, String> headers, [String imageBase = defaultImageBase]) => shelf.Response(
  status,
  body: body == null || status == 204 ? null : _encode(body, imageBase),
  headers: {if (body != null && status != 204) ..._jsonHeaders, ...headers},
);

String _encode(Object body, String imageBase) {
  final text = jsonEncode(body);
  return imageBase == defaultImageBase ? text : text.replaceAll(defaultImageBase, imageBase);
}

shelf.Response _problem(ApiError e, String? requestId) => shelf.Response(
  e.status,
  body: jsonEncode(e.toJson(requestId: requestId)),
  headers: {..._problemHeaders, if (e.retryAfterSeconds != null) 'retry-after': '${e.retryAfterSeconds}', 'x-request-id': ?requestId},
);

void _checkAppVersion(MockApp app, String? version) {
  if (version == null) return;
  final min = app.seed.extra.strOrNull('minAppVersion') ?? '1.0.0';
  List<int> parse(String v) => v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final a = parse(version), b = parse(min);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) {
      if (x < y) throw ApiError('APP_UPDATE_REQUIRED', params: {'minVersion': min});
      return;
    }
  }
}

void _authenticate(MockApp app, _Route route, Req req, String? authorization, String scenario) {
  final bearer = authorization != null && authorization.toLowerCase().startsWith('bearer ') ? authorization.substring(7).trim() : null;
  if (route.access != 'guest' || bearer != null) {
    if (bearer != null && route.access != 'guest') {
      req.identity = app.authenticate(bearer);
      if (scenario == Scenario.expired && app.expireOnce(req.identity!, bearer)) throw ApiError('TOKEN_EXPIRED');
    } else if (bearer == null && app.config.persona != 'guest' && route.access != 'guest') {
      final tokens = app.personaTokens(app.config.persona);
      req.identity = app.authenticate(tokens['accessToken'] as String);
    }
  }
  if (route.access == 'bearer' && req.identity == null) throw ApiError('AUTH_REQUIRED');
}

void _resolvePartner(MockApp app, _Route route, Req req, Map<String, String> headers) {
  final id = req.identity;
  final venueHeader = headers['x-venue-id'];
  final providerHeader = headers['x-provider-id'];
  final wants =
      (route.isPartnerPath && !_noContextOps.contains(route.id)) || (_optionalContextOps.contains(route.id) && (venueHeader != null || providerHeader != null));
  if (route.isPartnerPath && id != null && !id.isPartner) throw ApiError.forbidden('partner account required');
  if (!wants || id == null) return;
  final memberships = app.membershipsOf(id.userId);
  Membership? m;
  if (venueHeader != null || providerHeader != null) {
    m = memberships.cast<Membership?>().firstWhere(
      (x) => (venueHeader != null && x!.venueId == venueHeader) || (providerHeader != null && x!.providerId == providerHeader),
      orElse: () => null,
    );
    if (m == null) throw ApiError.forbidden('no membership for this context');
  } else {
    final ctx = app.db.peek('Session', id.sessionId)?.objOrNull('context');
    if (ctx != null) {
      m = memberships.cast<Membership?>().firstWhere(
        (x) => x!.accountId == ctx['accountId'] && x.venueId == ctx['venueId'] && x.providerId == ctx['providerId'],
        orElse: () => null,
      );
    }
    m ??= memberships.length == 1 ? memberships.first : null;
    if (m == null) throw ApiError('VENUE_CONTEXT_REQUIRED');
  }
  req.partner = PartnerCtx(venueId: m.venueId, providerId: m.venueId == null ? m.providerId : null, accountId: m.accountId, role: m.role);
}

void _validate(_Route route, Req req, SchemaValidator v, Json? body, bool hasBody) {
  final errs = <Json>[];
  for (final p in route.params) {
    if (p['in'] != 'query') continue;
    final name = p['name'] as String;
    final raw = req.query[name];
    if (raw == null || raw.isEmpty) {
      if (p['required'] == true) errs.add({'path': '/$name', 'code': 'required'});
      continue;
    }
    final schema = p['schema'];
    // `limit` is clamped to 1..50 by the handlers (`Req.limit`), never refused: an integer of any size is valid, only a non-integer is a 422.
    if (name == 'limit' && int.tryParse(raw.first) != null) continue;
    if (schema is Map && schema['type'] == 'array') {
      for (final item in raw.expand((s) => s.split(','))) {
        errs.addAll(v.validate(SchemaValidator.coerce(item, schema['items']), schema['items'], '/$name'));
      }
    } else {
      errs.addAll(v.validate(SchemaValidator.coerce(raw.first, schema), schema, '/$name'));
    }
  }
  for (final p in route.params) {
    if (p['in'] != 'path') continue;
    final schema = p['schema'];
    final raw = req.pathParams[p['name']];
    if (raw != null && schema is Map) errs.addAll(v.validate(SchemaValidator.coerce(Uri.decodeComponent(raw), schema), schema, '/${p['name']}'));
  }
  if (route.body != null) {
    if (body == null) {
      if (route.bodyRequired || hasBody) errs.add({'path': '/', 'code': 'required'});
    } else {
      errs.addAll(v.validate(body, route.body));
    }
  }
  if (errs.isNotEmpty) throw ApiError('VALIDATION_FAILED', errors: errs);
}

/// `empty` scenario: lists and pages come back empty (everything else is untouched).
Object? _emptied(String operationId, Object? result) {
  if (result is List) return const [];
  if (result is Map) {
    final m = result.cast<String, dynamic>();
    if (m.containsKey('items') && m['items'] is List) return {...m, 'items': const [], 'nextCursor': null};
    const keys = {'shelves', 'needsYou', 'events', 'windows', 'listings', 'staff', 'invitations', 'nearestFreeDates', 'halls', 'dates', 'slots'};
    if (const {
      'getHome',
      'getPartnerToday',
      'listVoucherWindows',
      'listListings',
      'listStaff',
      'listPartnerHalls',
      'listVisitDates',
      'listVisitSlots',
      'getVenueAvailability',
    }.contains(operationId)) {
      return {for (final e in m.entries) e.key: keys.contains(e.key) && e.value is List ? const [] : e.value};
    }
  }
  return result;
}
