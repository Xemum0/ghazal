import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, RetryPolicy;
import 'package:uuid/uuid.dart';

import '../api_config.dart';
import 'client_environment.dart';
import 'interceptors.dart';
import 'token_store.dart';

/// The one HTTP client of both apps (ADR 0036): base URL and timeouts from [GzApiConfig], bearer auth with a single-flight refresh, the
/// locale, device, platform and Partner-context headers, `Idempotency-Key` on flagged operations, a GET-only retry policy, and
/// problem+json mapped to `ApiProblem` of `ghazal_core`. The generated REST repositories sit on [send] and [sendBytes]; they hold no rules.
///
/// Switching to the real backend changes only `API_BASE_URL` and `USE_MOCK`: with the mock, the app passes an in-process
/// `HttpClientAdapter` (from `ghazal_mock_api`) as [adapter]; nothing above this class changes.
class GzApiClient {
  GzApiClient._(this.dio, this._uuid);

  /// Builds the client with its interceptors. [adapter] replaces the network (the in-process mock, or a fake in tests).
  factory GzApiClient.create({
    required GzApiConfig config,
    required GzClientEnvironment environment,
    required TokenStore tokens,
    HttpClientAdapter? adapter,
    RetryPolicy retry = const RetryPolicy(),
    void Function()? onSessionEnded,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 25),
    Duration sendTimeout = const Duration(seconds: 25),
    Uuid uuid = const Uuid(),
  }) {
    final base = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      responseType: ResponseType.json,
      listFormat: ListFormat.multi,
      contentType: Headers.jsonContentType,
    );
    final dio = Dio(base);
    final refreshDio = Dio(base.copyWith());
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
      refreshDio.httpClientAdapter = adapter;
    }
    dio.interceptors.addAll([
      HeadersInterceptor(environment, uuid),
      IdempotencyInterceptor(uuid),
      AuthInterceptor(dio: dio, refreshDio: refreshDio, tokens: tokens, environment: environment, onSessionEnded: onSessionEnded),
      RetryInterceptor(dio: dio, policy: retry),
    ]);
    return GzApiClient._(dio, uuid);
  }

  /// The underlying client (tests, and the upload helpers that talk to signed URLs outside the API).
  final Dio dio;
  final Uuid _uuid;

  /// A fresh `Idempotency-Key`. Generate one when the user taps the CTA, keep it until the outcome is known and pass it on every retry of that
  /// same intent; a new intent gets a new key (api-conventions section 7).
  String newIdempotencyKey() => _uuid.v4();

  /// Calls the API and returns the decoded JSON (`null` for 204). Throws `ApiProblem` (ghazal_core): the problem+json of an HTTP error, or its `offline` / `timeout` form when there was
  /// no answer. Null query values and empty lists are dropped; lists go as repeated keys.
  Future<Object?> send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool idempotent = false,
    String? idempotencyKey,
    String? ifMatch,
  }) async {
    try {
      final res = await dio.request<Object?>(
        path,
        data: body,
        queryParameters: _clean(query),
        options: _options(method, idempotent: idempotent, idempotencyKey: idempotencyKey, ifMatch: ifMatch),
      );
      return res.data;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Like [send] for binary answers (receipt PDFs).
  Future<List<int>> sendBytes(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    bool idempotent = false,
    String? idempotencyKey,
    String? ifMatch,
  }) async {
    try {
      final res = await dio.request<List<int>>(
        path,
        data: body,
        queryParameters: _clean(query),
        options: _options(method, idempotent: idempotent, idempotencyKey: idempotencyKey, ifMatch: ifMatch, bytes: true),
      );
      return res.data ?? const [];
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Options _options(String method, {required bool idempotent, String? idempotencyKey, String? ifMatch, bool bytes = false}) => Options(
        method: method,
        responseType: bytes ? ResponseType.bytes : ResponseType.json,
        headers: {'If-Match': ?ifMatch},
        extra: {
          if (idempotent) GzExtra.idempotent: true,
          GzExtra.idempotencyKey: ?idempotencyKey,
        },
      );

  static Map<String, Object?>? _clean(Map<String, Object?>? query) {
    if (query == null) return null;
    final out = <String, Object?>{};
    query.forEach((k, v) {
      if (v == null) return;
      if (v is List) {
        if (v.isNotEmpty) out[k] = v.map((e) => e.toString()).toList();
      } else {
        out[k] = v.toString();
      }
    });
    return out.isEmpty ? null : out;
  }
}

/// Maps a transport failure to `ApiProblem` of `ghazal_core` (one error type for the UI: `messageKey` plus `params`). problem+json bodies keep
/// their `code`, `params`, `errors`, `alternatives` and `Retry-After`; BOOKING_STATE_CONFLICT's `currentStatus` and `currentVersion` are
/// exposed in `params` so the "already updated" sheet needs no second call. No answer becomes `ApiProblem.offline()` / `.timeout()`.
ApiProblem mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.badResponse:
      final res = e.response;
      final status = res?.statusCode ?? 0;
      var data = res?.data;
      if (data is Map) {
        final map = data.map((k, v) => MapEntry(k.toString(), v));
        final params = <String, Object?>{...(map['params'] is Map ? (map['params'] as Map).map((k, v) => MapEntry(k.toString(), v)) : const <String, Object?>{})};
        if (map['currentStatus'] != null) params['currentStatus'] = map['currentStatus'];
        if (map['currentVersion'] != null) params['currentVersion'] = map['currentVersion'];
        map['params'] = params;
        data = map;
      }
      return ApiProblem.fromResponse(
        status: status,
        body: data,
        headers: {for (final h in (res?.headers.map ?? const <String, List<String>>{}).entries) h.key: h.value.join(', ')},
      );
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const ApiProblem.timeout();
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return const ApiProblem.offline();
  }
}
