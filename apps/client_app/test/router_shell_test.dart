// The client app's router composition and tab shell on the real inventory: tab bar present or absent exactly as the web chrome says
// (`chromeFor`), through the real `buildAppRouter`, the built screens (a stub for the rest) and the shared shell.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:client_app/app/client_router.dart';
import 'package:client_app/app/screen_registry.dart';

import 'support/flow_world.dart';

Future<void> open(WidgetTester tester, String id, {Locale locale = const Locale('en')}) => openScreen(tester, id, locale: locale);

bool get barVisible => find.byType(GzTabBar).hitTestable().evaluate().isNotEmpty;

void main() {
  // (id, tab bar visible, active tab or null)
  final cases = <(String, bool, String?)>[
    ('CL-DISC-01', true, 'discover'), // tab root
    ('CL-PROF-01', true, 'profile'), // another tab root
    ('CL-DISC-03', true, 'discover'), // tab flow screen (results)
    ('CL-BKNG-02', true, 'my-wedding'), // flow of another tab
    ('CL-VENU-01', false, null), // detail page with its own CTA bar
    ('CL-BOOK-01', false, null), // booking flow
    ('CL-DISC-02', false, null), // sheet
    ('CL-ONBD-01', false, null), // onboarding
    ('CL-AUTH-01', false, null), // auth sheet
    ('CL-MSGS-02', false, null), // chat composer
  ];
  for (final c in cases) {
    flowTest('${c.$1}: tab bar ${c.$2 ? 'present' : 'absent'}', (tester) async {
      await open(tester, c.$1);
      expect(nav(tester).currentId, c.$1, reason: '${c.$1} is the screen on top');
      expect(barVisible, c.$2);
      if (c.$3 != null) {
        expect(tester.widget<GzTabBar>(find.byType(GzTabBar)).activeId, c.$3);
      }
    });
  }

  flowTest('the five client tabs are in inventory order and mirror in Arabic', (tester) async {
    await open(tester, 'CL-DISC-01', locale: const Locale('ar'));
    final bar = tester.widget<GzTabBar>(find.byType(GzTabBar));
    expect(bar.items.map((i) => i.id), <String>['discover', 'saved', 'my-wedding', 'messages', 'profile']);
    expect(bar.items.map((i) => i.id), kAppTabs.map((t) => t.id));
    final first = tester.getCenter(find.byKey(const ValueKey<String>('gz:tab.discover'))).dx;
    final last = tester.getCenter(find.byKey(const ValueKey<String>('gz:tab.profile'))).dx;
    expect(first, greaterThan(last));
  });

  test('every screen that lives in a branch has its root twin, every screen its named route', () {
    final router = buildClientRouter();
    addTearDown(router.dispose);
    for (final e in kScreenRegistry.entries) {
      expect(router.namedLocation(e.key), e.value.path, reason: e.key);
      final chrome = kClientRouterSpec.chrome[e.key]!;
      if (chrome.inBranch && !kClientRouterSpec.isTabRoot(e.key)) {
        expect(router.namedLocation('${e.key}$kRootRouteSuffix'), '$kRootPathPrefix${e.value.path}', reason: e.key);
      }
    }
  });

  test('chrome facts of the registry: a screen with the bar has a tab; tab roots have the bar; sheets never live in a branch', () {
    for (final e in kScreenRegistry.entries) {
      if (e.value.tabBar) expect(e.value.tab, isNotNull, reason: e.key);
      if (e.value.kind == ScreenKind.tabRoot) expect(e.value.tabBar, isTrue, reason: e.key);
      if (e.value.kind == ScreenKind.sheet) expect(kClientRouterSpec.chrome[e.key]!.inBranch, isFalse, reason: e.key);
    }
    expect(kClientRouterSpec.homePath, kScreenRegistry[kAppTabs.first.rootScreen]!.path);
  });

  test('no guest mode: a signed-out client reaches only the first-run screens, a signed-in one is taken off the invisible start', () {
    final spec = kClientRouterSpec;
    expect(spec.requireSession, isTrue);
    String? redirect(String id, {required bool signedIn}) => gzRedirect(spec, signedIn: signedIn, location: kScreenRegistry[id]!.path);
    for (final id in <String>['CL-ONBD-01', 'CL-ONBD-02', 'CL-AUTH-01', 'CL-AUTH-02', 'CL-AUTH-03', 'CL-AUTH-04', 'CL-AUTH-05']) {
      expect(redirect(id, signedIn: false), isNull, reason: '$id is a first-run screen');
    }
    for (final id in kScreenRegistry.keys.where((k) => !k.startsWith('CL-AUTH-') && k != 'CL-ONBD-01' && k != 'CL-ONBD-02')) {
      expect(redirect(id, signedIn: false), kClientStartPath, reason: '$id is closed to a signed-out client');
      expect(redirect(id, signedIn: true), isNull, reason: '$id is open to a signed-in client');
    }
    expect(redirect('CL-ONBD-01', signedIn: true), isNull, reason: 'the first-run screens are never a redirect source: the stack under a code step survives the session flip');
    expect(redirect('CL-AUTH-01', signedIn: true), isNull);
    expect(gzRedirect(spec, signedIn: true, location: kClientStartPath), spec.homePath, reason: 'a signed-in client is taken off the start');
    expect(gzRedirect(spec, signedIn: false, location: kClientStartPath), isNull, reason: 'the start itself redirects on to the Language screen');
  });
}
