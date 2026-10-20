// The standalone Ghazal mock server.
//
//   dart run --no-pub ghazal_mock_api:serve [--port 4701] [--host 127.0.0.1] [--persona reem] [--scenario slow] [--latency 200] [--log]
//
// The default port is the reserved one of the `api` service: `node tools/ports.mjs url api`. Control endpoints: `/__mock/*` (docs/architecture/mock-api.md).
import 'dart:io';

import 'package:ghazal_mock_api/ghazal_mock_api.dart';

Future<void> main(List<String> args) async {
  String? option(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('usage: dart run --no-pub ghazal_mock_api:serve [--port N] [--host H] [--persona P] [--scenario S] [--latency MS] [--clock ISO] [--log]');
    return;
  }
  final backend = await MockBackend.create(
    persona: option('persona') ?? 'guest',
    scenario: option('scenario') ?? Scenario.none,
    latency: Duration(milliseconds: int.tryParse(option('latency') ?? '0') ?? 0),
    clock: option('clock') == null ? null : DateTime.parse(option('clock')!),
  );
  final server = await backend.serve(port: int.tryParse(option('port') ?? ''), host: option('host') ?? '127.0.0.1', logRequests: args.contains('--log'));
  stdout.writeln('ghazal_mock_api listening on ${server.url} (control: ${server.url.replaceFirst('/v1', '')}/__mock/state, identity: /__gz)');
  stdout.writeln('story clock ${backend.control.nowText}, persona ${backend.control.persona}, scenario ${backend.control.scenario}');
  ProcessSignal.sigint.watch().listen((_) async {
    await server.close(force: true);
    exit(0);
  });
  // `POST /__mock/shutdown` closes the server; the process ends when nothing is left to serve
  await server.closed;
  exit(0);
}
