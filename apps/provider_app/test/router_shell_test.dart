// The partner app's router composition and tab shell on the real inventory, signed in as the hotel manager, plus the access redirect
// of a signed-out person.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show PartnerAccountType, StaffRole;
import 'package:ghazal_testing/ghazal_testing.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:provider_app/app/app.dart';
import 'package:provider_app/app/app_router.dart';
import 'package:provider_app/app/screen_registry.dart';

class _SignedInManager extends SessionNotifier {
  @override
  AppSession build() => const PartnerSession(
        user: AuthUser(id: 'u-hind', name: 'Hind', phone: '+96550000001', monogram: 'H'),
        accountType: PartnerAccountType.venue,
        role: StaffRole.manager,
        venueId: 'V01',
      );
}

Future<void> open(WidgetTester tester, String id, {Locale locale = const Locale('en'), bool signedIn = true}) async {
  await GzHarness.pump(
    tester,
    app: const ProviderApp(),
    locale: locale,
    overrides: <Override>[
      partnerRouterOverride(initialLocation: kScreenRegistry[id]!.path),
      if (signedIn) sessionProvider.overrideWith(_SignedInManager.new),
    ],
  );
}

bool get barVisible => find.byType(GzTabBar).hitTestable().evaluate().isNotEmpty;

void main() {
  final cases = <(String, bool, String?)>[
    ('HL-TODY-01', true, 'today'), // tab root
    ('HL-BOOK-01', true, 'bookings'), // tab root
    ('HL-TODY-04', true, 'messages'), // the messages root lives in the Today flow
    ('HL-SETT-01', true, 'more'), // tab root
    ('HL-BOOK-02', true, 'bookings'), // tab flow screen
    ('HL-TODY-05', false, null), // chat composer
    ('HL-GROW-02', false, null), // offer stepper
    ('HL-DCSN-01', false, null), // sheet
  ];
  for (final c in cases) {
    testWidgets('${c.$1}: tab bar ${c.$2 ? 'present' : 'absent'}', (tester) async {
      await open(tester, c.$1);
      expect(find.text(c.$1), findsWidgets);
      expect(barVisible, c.$2);
      if (c.$3 != null) expect(tester.widget<GzTabBar>(find.byType(GzTabBar)).activeId, c.$3);
    });
  }

  testWidgets('a signed-in manager opening the access screen goes to Today', (tester) async {
    await open(tester, 'HL-ACCS-01');
    expect(find.text('HL-TODY-01'), findsWidgets);
    expect(barVisible, isTrue);
  });

  testWidgets('a signed-out person asking for a tab screen lands on the access flow', (tester) async {
    await open(tester, 'HL-TODY-01', signedIn: false);
    expect(find.text('HL-ACCS-01'), findsWidgets);
    expect(barVisible, isFalse);
  });

  testWidgets('the five partner tabs are in inventory order and mirror in Arabic', (tester) async {
    await open(tester, 'HL-TODY-01', locale: const Locale('ar'));
    final bar = tester.widget<GzTabBar>(find.byType(GzTabBar));
    expect(bar.items.map((i) => i.id), <String>['today', 'bookings', 'calendar', 'messages', 'more']);
    expect(bar.items.map((i) => i.id), kAppTabs.map((t) => t.id));
    final first = tester.getCenter(find.byKey(const ValueKey<String>('gz:tab.today'))).dx;
    final last = tester.getCenter(find.byKey(const ValueKey<String>('gz:tab.more'))).dx;
    expect(first, greaterThan(last));
  });

  test('every screen has its named route and the branch screens their root twin', () {
    final router = buildAppRouter();
    addTearDown(router.dispose);
    for (final e in kScreenRegistry.entries) {
      expect(router.namedLocation(e.key), e.value.path, reason: e.key);
      final chrome = kRouterSpec.chrome[e.key]!;
      if (chrome.inBranch && !kRouterSpec.isTabRoot(e.key)) {
        expect(router.namedLocation('${e.key}$kRootRouteSuffix'), '$kRootPathPrefix${e.value.path}', reason: e.key);
      }
    }
  });

  test('chrome facts: messages root owns HL-TODY-04 and HL-TODY-05, access has no tab, the guard keeps signed-out people in access', () {
    expect(kScreenRegistry['HL-TODY-04']!.tab, 'messages');
    expect(kScreenRegistry['HL-TODY-05']!.tab, 'messages');
    expect(kScreenRegistry['HL-TODY-05']!.tabBar, isFalse);
    expect(kScreenRegistry['HL-ACCS-01']!.tab, isNull);
    expect(kRouterSpec.requireSession, isTrue);
    expect(kRouterSpec.publicPrefixes, <String>['/access']);
    expect(kRouterSpec.startPath, kScreenRegistry['HL-ACCS-01']!.path);
  });
}
