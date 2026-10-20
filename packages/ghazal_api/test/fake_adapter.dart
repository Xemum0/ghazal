import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A scripted network for the client tests: routes by method and path, answers in order (the last answer repeats), records every request.
class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final Map<String, List<FakeResponse Function(RequestOptions)>> _routes = {};
  final Map<String, int> _cursor = {};

  /// `on('GET', '/venues', (r) => FakeResponse.json({...}))`; call again for the next answer in the sequence.
  void on(String method, String path, FakeResponse Function(RequestOptions r) answer) => (_routes['$method $path'] ??= []).add(answer);

  Iterable<RequestOptions> to(String method, String path) => requests.where((r) => r.method == method && r.path == path);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final key = '${options.method} ${options.path}';
    final list = _routes[key];
    if (list == null) {
      return ResponseBody.fromString(jsonEncode({'type': 'about:blank', 'title': 'no route $key', 'status': 599, 'code': 'NOT_FOUND'}), 599, headers: {
        Headers.contentTypeHeader: ['application/problem+json'],
      });
    }
    final i = _cursor[key] ?? 0;
    _cursor[key] = i + 1;
    final answer = list[i < list.length ? i : list.length - 1](options);
    if (answer.delay != null) await Future<void>.delayed(answer.delay!);
    if (answer.networkError != null) {
      throw DioException(requestOptions: options, type: answer.networkError!, error: 'fake network failure');
    }
    final headers = {
      Headers.contentTypeHeader: [answer.contentType],
      ...answer.headers.map((k, v) => MapEntry(k, [v])),
    };
    if (answer.bytes != null) return ResponseBody.fromBytes(answer.bytes!, answer.status, headers: headers);
    return ResponseBody.fromString(answer.body ?? '', answer.status, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

class FakeResponse {
  FakeResponse.json(Object? body, {this.status = 200, this.headers = const {}, this.delay})
      : body = body == null ? null : jsonEncode(body),
        contentType = 'application/json',
        bytes = null,
        networkError = null;

  FakeResponse.problem(this.status, Map<String, Object?> body, {this.headers = const {}, this.delay})
      : body = jsonEncode(body),
        contentType = 'application/problem+json',
        bytes = null,
        networkError = null;

  FakeResponse.empty(this.status, {this.headers = const {}})
      : body = '',
        contentType = 'application/json',
        bytes = null,
        networkError = null,
        delay = null;

  FakeResponse.text(this.status, String text)
      : body = text,
        contentType = 'text/html',
        headers = const {},
        bytes = null,
        networkError = null,
        delay = null;

  FakeResponse.pdf(List<int> data)
      : bytes = data,
        status = 200,
        body = null,
        contentType = 'application/pdf',
        headers = const {},
        networkError = null,
        delay = null;

  FakeResponse.network(DioExceptionType type)
      : networkError = type,
        status = 0,
        body = null,
        contentType = 'application/json',
        headers = const {},
        bytes = null,
        delay = null;

  final int status;
  final String? body;
  final String contentType;
  final Map<String, String> headers;
  final List<int>? bytes;
  final DioExceptionType? networkError;
  final Duration? delay;
}

Map<String, Object?> problemBody(int status, String code, {Map<String, Object?>? extra}) => {
      'type': 'https://api.ghazal.example/problems/${code.toLowerCase().replaceAll('_', '-')}',
      'title': code,
      'status': status,
      'code': code,
      'requestId': 'req-1',
      ...?extra,
    };

/// A valid AuthSession body (the shape of POST /auth/refresh).
Map<String, Object?> sessionBody({String access = 'access-new', String refresh = 'refresh-new'}) => {
      'accessToken': access,
      'refreshToken': refresh,
      'tokenType': 'Bearer',
      'expiresInSeconds': 600,
      'isNewUser': false,
      'user': {
        'user': {
          'id': 'user-reem',
          'role': 'client',
          'name': 'ريم الدوسري',
          'monogram': 'ر',
          'phone': '+96550000012',
          'email': null,
          'locale': 'ar',
          'digitStyle': 'western',
          'createdAt': '2026-10-01T10:00:00+03:00',
        },
        'permissions': <Object?>[],
        'phoneVerified': true,
        'emailVerified': false,
        'hasPassword': true,
        'marketingOptIn': false,
      },
    };
