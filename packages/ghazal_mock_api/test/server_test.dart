// The standalone server over real sockets: identity handshake, API, CORS, control endpoints, shutdown, and the photographs served over HTTP
// (the seeds' asset:// image bases become http URLs).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart';
import 'package:ghazal_mock_api/src/seed/seed_source_io.dart';
import 'package:path/path.dart' as p;

import 'support.dart';

Future<(int, Object?, HttpHeaders)> get(HttpClient c, String url, {Map<String, String> headers = const {}}) async {
  final req = await c.getUrl(Uri.parse(url));
  headers.forEach(req.headers.set);
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  Object? json;
  try {
    json = jsonDecode(body);
  } catch (_) {}
  return (res.statusCode, json ?? body, res.headers);
}

void main() {
  test('standalone server: identity, API, CORS, images over HTTP, control endpoints, shutdown', () async {
    final backend = await MockBackend.create(seed: DirectorySeedSource(p.join(repoRoot(), 'packages/ghazal_mock_api/assets')), autoRun: false);
    final server = await serveMock(backend: backend, port: 0);
    final base = 'http://127.0.0.1:${server.port}';
    final c = HttpClient();
    try {
      var (status, body, _) = await get(c, '$base/__gz');
      expect(status, 200);
      expect((body as Map)['app'], 'api');
      expect(body['rootHash'], hasLength(8));

      (status, body, _) = await get(c, '${server.url}/venues?limit=1');
      expect(status, 200);
      final cover = ((body as Map)['items'] as List).first['venue']['cover'] as Map;
      expect(cover['baseUrl'], startsWith('$base/images/'));
      final img = await c.getUrl(Uri.parse('${cover['baseUrl']}_480.jpg'));
      final res = await img.close();
      expect(res.statusCode, 200);
      expect(res.headers.contentType?.mimeType, 'image/jpeg');
      expect((await res.fold<int>(0, (n, b) => n + b.length)), greaterThan(5000));

      final pre = await (await c.openUrl('OPTIONS', Uri.parse('${server.url}/venues'))).close();
      expect(pre.statusCode, 204);
      expect(pre.headers.value('access-control-allow-origin'), '*');

      // control: the persona acts without a token, the clock moves
      final post = await c.postUrl(Uri.parse('$base/__mock/persona'));
      post.headers.contentType = ContentType.json;
      post.write(jsonEncode({'persona': 'reem'}));
      expect((await post.close()).statusCode, 200);
      (status, body, _) = await get(c, '${server.url}/me');
      expect(status, 200);
      expect(((body as Map)['user'] as Map)['id'], 'user-reem');
      (status, body, _) = await get(c, '$base/__mock/state');
      expect((body as Map)['persona'], 'reem');

      final stop = await c.postUrl(Uri.parse('$base/__mock/shutdown'));
      expect((await stop.close()).statusCode, 200);
      await server.closed.timeout(const Duration(seconds: 5));
    } finally {
      c.close(force: true);
      await server.close(force: true);
    }
  });

  test('the images the seeds name all exist in two sizes, within the size budget', () async {
    final seed = await loadSeed();
    final images = (seed.manifest['images'] as Map).keys.cast<String>();
    expect(images.length, greaterThan(100));
    var bytes = 0;
    for (final id in images) {
      for (final n in [480, 960]) {
        final f = File(p.join(repoRoot(), 'packages/ghazal_mock_api/assets/images/${id}_$n.jpg'));
        expect(f.existsSync(), isTrue, reason: '${id}_$n.jpg');
        bytes += f.lengthSync();
      }
    }
    expect(bytes, lessThan(35 * 1024 * 1024));
    // every seeded image descriptor follows the convention
    final text = File(p.join(repoRoot(), 'packages/ghazal_mock_api/assets/seed/Venue.seed.json')).readAsStringSync();
    expect(text, contains('"baseUrl":"asset://ghazal_mock_api/images/'));
  });

  test('a Flutter app reads the seeds through a loader (rootBundle in the apps) and gets the same world', () async {
    final dir = p.join(repoRoot(), 'packages/ghazal_mock_api/assets');
    final loaded = <String>[];
    final mock = await MockBackend.create(
      seed: SeedSource.fromLoader((path) async {
        loaded.add(path);
        return File(p.join(dir, path)).readAsString();
      }),
      autoRun: false,
    );
    expect(loaded, contains('spec/routes.json'));
    expect(loaded.where((x) => x.startsWith('seed/')).length, greaterThan(40));
    expect(mock.control.nowText, '2026-11-12T16:00:00+03:00');
    final pubspec = File(p.join(repoRoot(), 'packages/ghazal_mock_api/pubspec.yaml')).readAsStringSync();
    for (final asset in ['assets/seed/', 'assets/spec/', 'assets/images/']) {
      expect(pubspec, contains('- $asset'));
    }
  });
}
