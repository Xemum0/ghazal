/// The public face of the mock: [MockBackend] owns one mock world (database, story clock, handlers) and offers it as a dio adapter (in-process,
/// no sockets) or a standalone server. [MockControl] steers it.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'control.dart';
import 'control_http.dart';
import 'core/app.dart';
import 'core/pipeline.dart';
import 'handlers/handlers.dart';
import 'seed/seed_data.dart';
import 'seed/seed_source_io.dart' show defaultSeedSource;
import 'seed/seed_source.dart';

export 'core/app.dart' show MockConfig, Scenario;
export 'core/pipeline.dart' show MockOffline;

class MockBackend {
  MockBackend._(this.app, this._api, this.seedSource) {
    control = MockControl(app);
  }

  /// The state behind the mock (tests and tools only; the app talks to [httpClientAdapter]).
  final MockApp app;
  final shelf.Handler _api;

  /// Where the seeds were read from (the standalone server serves the photographs from the same folder).
  final SeedSource seedSource;

  /// The control surface: reset, clock, persona, scenario, latency, payments, moderation, refunds, outbox and events.
  late final MockControl control;

  /// Builds a mock world.
  ///
  /// * [seed]: where the seeds are read (default: the package `assets` folder on the Dart VM; Flutter apps pass
  ///   `SeedSource.fromLoader((p) => rootBundle.loadString('packages/ghazal_mock_api/assets/$p'))`).
  /// * [clock]: story time at start and after reset (default 2026-11-12T16:00+03:00, the prototype clock).
  /// * [latency], [scenario], [persona]: initial control knobs (persona `guest` means requests need a token, like the real API).
  /// * [autoRun]: fire the gateway and chat replies on real timers (apps, demos); tests pass false and call `control.flush()`.
  static Future<MockBackend> create({
    SeedSource? seed,
    DateTime? clock,
    Duration latency = Duration.zero,
    String scenario = Scenario.none,
    String persona = 'guest',
    bool autoRun = true,
    Duration gatewayDelay = const Duration(milliseconds: 1500),
    Duration botDelay = const Duration(milliseconds: 2500),
  }) async {
    final source = seed ?? await defaultSeedSource();
    final data = await SeedData.load(source);
    final app = MockApp(
      seed: data,
      config: MockConfig(
        clock: clock,
        latency: latency,
        scenario: scenario,
        persona: persona,
        autoRun: autoRun,
        gatewayDelay: gatewayDelay,
        botDelay: botDelay,
      ),
    );
    final backend = MockBackend._(app, buildHandler(app, allHandlers(app)), source);
    if (persona != 'guest') app.personaTokens(persona);
    return backend;
  }

  /// A shelf handler over everything the mock serves: `/v1/*` (the contract) and `/__mock/*` (the control surface).
  shelf.Handler get handler => (request) async {
    final c = await handleControl(app, control, request);
    return c ?? await _api(request);
  };

  /// A dio adapter that answers requests in-process: no sockets, works on iOS, Android and desktop test VMs. Give it to `GzApiClient.create(adapter: ...)`.
  /// In the `offline` scenario it throws a connection error like a phone with no network.
  HttpClientAdapter get httpClientAdapter => MockHttpClientAdapter(this);
}

/// The in-process dio adapter: turns a dio request into a shelf request, runs the mock handler, and turns the response back.
class MockHttpClientAdapter implements HttpClientAdapter {
  MockHttpClientAdapter(this._backend);
  final MockBackend _backend;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    final headers = <String, String>{};
    options.headers.forEach((k, v) {
      if (v != null) headers[k.toLowerCase()] = v is List ? v.join(', ') : v.toString();
    });
    final request = shelf.Request(options.method, options.uri, headers: headers, body: bytes);
    final shelf.Response response;
    try {
      response = await _backend.handler(request);
    } on MockOffline {
      throw DioException.connectionError(requestOptions: options, reason: 'the mock is in the offline scenario', error: const MockOffline());
    }
    final out = await response.read().expand((c) => c).toList();
    final h = <String, List<String>>{};
    response.headersAll.forEach((k, v) => h[k] = v);
    return ResponseBody.fromBytes(Uint8List.fromList(out), response.statusCode, headers: h);
  }

  @override
  void close({bool force = false}) {}
}
