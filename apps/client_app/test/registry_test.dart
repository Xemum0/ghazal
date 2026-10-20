// The route table must cover the inventory exactly: every live screen of docs/product/screens/client has a route (same name and
// path as the registry), no deprecated screen has one, and every tab root is reachable. Run from the app folder (flutter test).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:client_app/app/app_router.dart';
import 'package:client_app/app/screen_registry.dart';

void main() {
  final dir = Directory('../../docs/product/screens/client');
  final live = <String>{};
  final deprecated = <String>{};
  for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json') && !f.path.endsWith('_index.json'))) {
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    for (final s in (json['screens'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      (s['deprecated'] == true ? deprecated : live).add(s['id'] as String);
    }
  }

  test('registry equals the live inventory', () {
    expect(kScreenRegistry.keys.toSet(), live);
    expect(kScreenRegistry.keys.toSet().intersection(deprecated), isEmpty);
  });

  test('every registered screen has a named route at its path', () {
    final router = buildAppRouter();
    addTearDown(router.dispose);
    for (final e in kScreenRegistry.entries) {
      expect(router.namedLocation(e.key), e.value.path, reason: e.key);
    }
  });

  test('tab roots are registered as tab roots and the initial location exists', () {
    for (final t in kAppTabs) {
      expect(kScreenRegistry[t.rootScreen]?.kind, ScreenKind.tabRoot, reason: t.id);
    }
    expect(kScreenRegistry.values.map((e) => e.path), contains(kInitialLocation));
  });
}
