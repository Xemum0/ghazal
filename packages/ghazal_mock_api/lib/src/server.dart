/// The standalone mock server: shelf_io over the same handler as the in-process adapter, plus CORS, the optimised photographs under `/images/`,
/// the Ghazal identity handshake of `tools/ports.mjs` (`GET /__gz`) and `/__mock/*`. Two apps (client and partner) talking to one server share state,
/// which is how the client-to-partner story propagates.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

import 'backend.dart';
import 'seed/seed_source_io.dart';

class MockServer {
  MockServer._(this.backend, this.server, this.url, this._closed);
  final Completer<void> _closed;

  /// Completes when the server was closed by `POST /__mock/shutdown`.
  Future<void> get closed => _closed.future;
  final MockBackend backend;
  final HttpServer server;

  /// Base URL of the API (`http://127.0.0.1:4701/v1`).
  final String url;

  int get port => server.port;

  Future<void> close({bool force = false}) => server.close(force: force);
}

/// Port of the standalone mock inside the Ghazal block: 4700 + 10 * slot + 1 (the `api` service of tools/ports.mjs).
int defaultMockPort() => 4701 + 10 * (int.tryParse(Platform.environment['GZ_SLOT'] ?? '0') ?? 0);

String _rootHash() {
  // the identity of this checkout, computed like tools/ports.mjs: sha1 of the repository root, first 8 hex digits
  final assets = Platform.environment['GZ_MOCK_ASSETS'];
  var dir = Directory.current.absolute.path;
  if (assets == null) {
    var d = Directory.current.absolute;
    for (var i = 0; i < 6; i++) {
      if (File(p.join(d.path, 'pnpm-workspace.yaml')).existsSync() || Directory(p.join(d.path, 'packages/contracts')).existsSync()) {
        dir = d.path;
        break;
      }
      d = d.parent;
    }
  }
  return sha1.convert(utf8.encode(Platform.environment['GZ_ROOT'] ?? dir)).toString().substring(0, 8);
}

class _ServerHolder {
  HttpServer? server;
  final Completer<void> closed = Completer<void>();
}

shelf.Middleware _cors() => (inner) => (request) async {
      const headers = {
        'access-control-allow-origin': '*',
        'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
        'access-control-allow-headers': 'authorization, content-type, accept, accept-language, idempotency-key, if-match, x-device-id, x-platform, x-app-version, x-request-id, x-venue-id, x-provider-id, x-mock-latency, x-mock-scenario',
        'access-control-expose-headers': 'etag, retry-after, x-request-id, idempotent-replayed',
      };
      if (request.method == 'OPTIONS') return shelf.Response(204, headers: headers);
      final r = await inner(request);
      return r.change(headers: headers);
    };

/// Starts the standalone server on [port] (default: the reserved Ghazal port of the `api` service). The result's [MockServer.url] is the API base URL.
Future<MockServer> serveMock({MockBackend? backend, int? port, String host = '127.0.0.1', bool logRequests = false}) async {
  final b = backend ?? await MockBackend.create();
  final src = b.seedSource;
  final assetsDir = src is DirectorySeedSource ? src.directory : (await defaultSeedSource()).directory;
  final imageHandler = createStaticHandler(p.join(assetsDir, 'images'));
  final startedAt = DateTime.now().toUtc().toIso8601String();
  final slot = int.tryParse(Platform.environment['GZ_SLOT'] ?? '0') ?? 0;
  final rootHash = _rootHash();
  final holder = _ServerHolder();
  Future<shelf.Response> app(shelf.Request request) async {
    final path = '/${request.url.path}';
    if (path == '/__gz') {
      return shelf.Response.ok(jsonEncode({'app': 'api', 'slot': slot, 'rootHash': rootHash, 'startedAt': startedAt, 'service': 'ghazal_mock_api'}), headers: {'content-type': 'application/json'});
    }
    if (path.startsWith('/images/')) return imageHandler(request.change(path: 'images'));
    if (path == '/__mock/shutdown' && request.method == 'POST') {
      // lets tools stop a server they started (the contract test, scripts) without signals
      Future<void>.delayed(const Duration(milliseconds: 50), () async {
        await holder.server?.close(force: true);
        holder.closed.complete();
      });
      return shelf.Response.ok(jsonEncode({'ok': true, 'closing': true}), headers: {'content-type': 'application/json'});
    }
    try {
      return await b.handler(request);
    } on MockOffline {
      return shelf.Response(503, body: jsonEncode({'type': 'about:blank', 'title': 'Offline scenario', 'status': 503, 'code': 'INTERNAL_ERROR', 'detail': 'X-Mock-Scenario: offline'}), headers: {'content-type': 'application/problem+json', 'x-mock-offline': '1'});
    }
  }

  var pipeline = const shelf.Pipeline();
  if (logRequests) pipeline = pipeline.addMiddleware(shelf.logRequests());
  final server = await io.serve(pipeline.addMiddleware(_cors()).addHandler(app), host, port ?? defaultMockPort());
  holder.server = server;
  final base = 'http://$host:${server.port}';
  b.app.baseUrl = base;
  b.app.imageBase = '$base/images/';
  // the standalone server hands out http image URLs: `asset://ghazal_mock_api/images/<id>` stays in the seeds, the UI maps it to `$base/images/<id>_480.jpg`
  return MockServer._(b, server, '$base/v1', holder.closed);
}

extension MockBackendServe on MockBackend {
  /// Serves this backend over HTTP on [port] (see [serveMock]).
  Future<MockServer> serve({int? port, String host = '127.0.0.1', bool logRequests = false}) => serveMock(backend: this, port: port, host: host, logRequests: logRequests);
}
