import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ghazal_core/ghazal_core.dart' show RetryPolicy;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:uuid/uuid.dart';

import 'client_environment.dart';
import 'token_store.dart';

/// `RequestOptions.extra` keys used between the client and its interceptors.
abstract final class GzExtra {
  static const idempotent = 'gz.idempotent';
  static const idempotencyKey = 'gz.idempotencyKey';
  static const requestId = 'gz.requestId';
  static const attempt = 'gz.attempt';
  static const authRetried = 'gz.authRetried';
  static const noAuth = 'gz.noAuth';
}

/// Accept-Language, X-Device-Id, X-Platform, X-App-Version, X-Request-Id and the Partner context headers (api-conventions section 3).
final class HeadersInterceptor extends Interceptor {
  HeadersInterceptor(this._env, this._uuid);

  final GzClientEnvironment _env;
  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final h = options.headers;
    h['Accept'] = 'application/json, application/problem+json';
    h['Accept-Language'] = _env.languageCode;
    h['X-Device-Id'] = _env.deviceId;
    h['X-Platform'] = _env.platform;
    h['X-App-Version'] = _env.appVersion;
    // one id per call, kept across automatic retries so the server log and a support case quote the same value
    h['X-Request-Id'] = options.extra.putIfAbsent(GzExtra.requestId, () => _uuid.v4()) as String;
    final ctx = _env.partnerContext;
    if (ctx != null && !options.path.startsWith('/auth/')) {
      if (ctx.venueId != null) h['X-Venue-Id'] = ctx.venueId;
      if (ctx.providerId != null) h['X-Provider-Id'] = ctx.providerId;
    }
    handler.next(options);
  }
}

/// Adds `Idempotency-Key` to operations flagged idempotent. The key is generated once per call and stored in `extra`, so an automatic
/// replay (token refresh) reuses it; a user-initiated retry passes the same key explicitly (api-conventions section 7).
final class IdempotencyInterceptor extends Interceptor {
  IdempotencyInterceptor(this._uuid);

  final Uuid _uuid;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[GzExtra.idempotent] == true) {
      final key = (options.extra[GzExtra.idempotencyKey] as String?) ?? _uuid.v4();
      options.extra[GzExtra.idempotencyKey] = key;
      options.headers['Idempotency-Key'] = key;
    }
    handler.next(options);
  }
}

/// Bearer token, and the single-flight refresh (a plain [Interceptor], not a QueuedInterceptor: replaying through the same Dio from a queued
/// interceptor would wait behind itself): when several calls hit 401 TOKEN_EXPIRED together, exactly one `POST /auth/refresh` runs,
/// then every waiting call is replayed once with the new token. A failed refresh (SESSION_REVOKED, reuse detection, network) ends the session:
/// the store is cleared and [onSessionEnded] fires (sign out, clear caches).
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.dio, required this.refreshDio, required this.tokens, required this.environment, this.onSessionEnded});

  /// The client that replays requests (all interceptors apply again).
  final Dio dio;

  /// A bare client for `/auth/refresh` (no auth interceptor, so a failing refresh can never loop).
  final Dio refreshDio;
  final TokenStore tokens;
  final GzClientEnvironment environment;
  final void Function()? onSessionEnded;

  Future<AuthTokens?>? _inflight;

  static bool _isPublicAuthPath(String path) => path.startsWith('/auth/') && path != '/auth/logout' && path != '/auth/step-up';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[GzExtra.noAuth] != true && !_isPublicAuthPath(options.path)) {
      final t = await tokens.read();
      if (t != null) options.headers['Authorization'] = 'Bearer ${t.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final res = err.response;
    final req = err.requestOptions;
    if (res?.statusCode != 401 || _isPublicAuthPath(req.path) || req.extra[GzExtra.authRetried] == true) return handler.next(err);

    final code = res!.data is Map ? (res.data as Map)['code'] : null;
    if (code == 'SESSION_REVOKED') {
      await _endSession();
      return handler.next(err);
    }
    if (code != 'TOKEN_EXPIRED') return handler.next(err); // AUTH_REQUIRED: the guest gate, not a refresh

    final current = await tokens.read();
    if (current == null) return handler.next(err);
    final sentWith = req.headers['Authorization'];
    // another call already refreshed while this one was in flight: just replay with the token in the store
    if (sentWith != null && sentWith != 'Bearer ${current.accessToken}') return _replay(req, current, handler, err);

    final fresh = await (_inflight ??= _refresh(current).whenComplete(() => _inflight = null));
    if (fresh == null) return handler.next(err);
    return _replay(req, fresh, handler, err);
  }

  Future<void> _replay(RequestOptions req, AuthTokens t, ErrorInterceptorHandler handler, DioException err) async {
    req.extra[GzExtra.authRetried] = true;
    req.headers['Authorization'] = 'Bearer ${t.accessToken}';
    try {
      handler.resolve(await dio.fetch<Object?>(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<AuthTokens?> _refresh(AuthTokens current) async {
    try {
      final res = await refreshDio.post<Object?>(
        '/auth/refresh',
        data: RefreshInput(refreshToken: current.refreshToken, deviceId: environment.deviceId).toJson(),
        options: Options(headers: {'X-Device-Id': environment.deviceId, 'Accept': 'application/json'}),
      );
      final session = AuthSession.fromJson(asMap(res.data));
      final fresh = AuthTokens(accessToken: session.accessToken, refreshToken: session.refreshToken);
      await tokens.write(fresh);
      return fresh;
    } on DioException catch (e) {
      final offline = e.response == null; // a network failure keeps the session; the user retries when back online
      if (!offline) await _endSession();
      return null;
    } on FormatException {
      await _endSession();
      return null;
    }
  }

  Future<void> _endSession() async {
    await tokens.clear();
    onSessionEnded?.call();
  }
}

/// Retries idempotent GETs per the global [RetryPolicy] of `ghazal_core` (network errors and 5xx, at most `maxRetries` retries with backoff).
/// Everything else passes through untouched.
final class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, required this.policy});

  final Dio dio;
  final RetryPolicy policy;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final retried = (req.extra[GzExtra.attempt] as int?) ?? 0;
    final status = err.response?.statusCode;
    if (err.type == DioExceptionType.cancel || !policy.shouldRetry(method: req.method, status: err.response == null ? null : status, attempt: retried)) {
      return handler.next(err);
    }
    final delay = policy.delayFor(retried);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    req.extra[GzExtra.attempt] = retried + 1;
    try {
      handler.resolve(await dio.fetch<Object?>(req));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
