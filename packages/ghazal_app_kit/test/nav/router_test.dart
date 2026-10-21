import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'nav_fixture.dart';

void main() {
  group('tab bar visibility (ten representative ids)', () {
    // (id, location, bar visible)
    final cases = <(String, String, bool)>[
      ('tab root', '/discover/home', true),
      ('tab root, second tab', '/saved/home', true),
      ('tab flow screen', '/discover/list', true),
      ('another tab flow screen', '/saved/list', true),
      ('hidden-bar screen', '/discover/detail', false),
      ('first start screen (no tab)', '/onboarding/start', false),
      ('sheet as first route', '/discover/sheet', false),
      ('sheet with no tab', '/discover/sheet-two', false),
      ('profile tab root', '/profile/home', true),
    ];
    for (final c in cases) {
      testWidgets('${c.$1}: ${c.$2} bar=${c.$3}', (tester) async {
        final rig = await pumpNav(tester, initialLocation: c.$2);
        expect(rig.barVisible, c.$3);
      });
    }

    testWidgets('a hidden-bar screen pushed over a tab covers the bar and pop brings it back', (tester) async {
      final rig = await pumpNav(tester);
      expect(rig.barVisible, isTrue);
      rig.nav.push('T-DISC-03');
      await rig.settle();
      expect(rig.shows('T-DISC-03'), isTrue);
      expect(rig.barVisible, isFalse);
      expect(rig.nav.tabBarCovered, isTrue);
      rig.nav.pop();
      await rig.settle();
      expect(rig.barVisible, isTrue);
      expect(rig.shows('T-DISC-01'), isTrue);
      expect(rig.nav.tabBarCovered, isFalse);
    });
  });

  group('stack operations', () {
    testWidgets('push keeps the bar and goes on the active tab stack; pop returns', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.push('T-DISC-02', params: <String, Object?>{'venueId': 'V02'});
      await rig.settle();
      expect(rig.shows('T-DISC-02'), isTrue);
      expect(rig.barVisible, isTrue);
      expect(rig.nav.activeTab, 'discover');
      rig.nav.pop();
      await rig.settle();
      expect(rig.shows('T-DISC-01'), isTrue);
      expect(rig.shows('T-DISC-02'), isFalse);
    });

    testWidgets('a branch screen of another tab pushed from here stays in the active tab (highlight and stack)', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.push('T-SAVD-02');
      await rig.settle();
      expect(rig.shows('T-SAVD-02'), isTrue);
      expect(rig.nav.activeTab, 'discover');
      expect(rig.barVisible, isTrue);
      rig.nav.pop();
      await rig.settle();
      expect(rig.shows('T-DISC-01'), isTrue);
    });

    testWidgets('a bar-visible screen pushed from a screen above the bar uses its root twin and does not mount the shell twice', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.push('T-DISC-03');
      await rig.settle();
      rig.nav.push('T-SAVD-02');
      await rig.settle();
      expect(tester.takeException(), isNull);
      expect(rig.shows('T-SAVD-02'), isTrue);
      expect(rig.nav.currentId, 'T-SAVD-02');
      rig.nav.pop(count: 2);
      await rig.settle();
      expect(rig.shows('T-DISC-01'), isTrue);
      expect(rig.barVisible, isTrue);
    });

    testWidgets('params, currentId and canGoBack are the screen\'s own', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.push('T-DISC-02', params: <String, Object?>{'venueId': 'V02', 'guests': 350});
      await rig.settle();
      final root = rig.seen.of('T-DISC-01');
      final pushed = rig.seen.of('T-DISC-02');
      expect(root.currentId, 'T-DISC-01');
      expect(root.canGoBack, isFalse);
      expect(root.params, isEmpty);
      expect(pushed.currentId, 'T-DISC-02');
      expect(pushed.canGoBack, isTrue);
      expect(pushed.params, <String, Object?>{'venueId': 'V02', 'guests': 350});
      expect(pushed.activeTab, 'discover');
    });

    testWidgets('replace swaps the top of the active stack', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.push('T-DISC-02');
      await rig.settle();
      rig.nav.replace('T-SAVD-02');
      await rig.settle();
      expect(rig.shows('T-SAVD-02'), isTrue);
      rig.nav.pop();
      await rig.settle();
      expect(rig.shows('T-DISC-01'), isTrue);
    });

    testWidgets('replace of a screen above the bar by a branch screen is safe', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.push('T-DISC-03');
      await rig.settle();
      rig.nav.push('T-SHET-02');
      await rig.settle();
      rig.nav.closeSheet();
      await rig.settle();
      rig.nav.push('T-DISC-03');
      await rig.settle();
      rig.nav.replace('T-SAVD-02');
      await rig.settle();
      expect(tester.takeException(), isNull);
      expect(rig.shows('T-SAVD-02'), isTrue);
    });

    testWidgets('pop with a count stops at the root and never leaves it', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.push('T-DISC-02');
      await rig.settle();
      rig.nav.push('T-SAVD-02');
      await rig.settle();
      rig.nav.pop(count: 5);
      await rig.settle();
      expect(rig.shows('T-DISC-01'), isTrue);
      rig.nav.pop();
      await rig.settle();
      expect(rig.shows('T-DISC-01'), isTrue);
    });

    testWidgets('reset goes to one screen and drops the other stacks', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.push('T-DISC-02');
      await rig.settle();
      rig.nav.switchTab('saved');
      await rig.settle();
      rig.nav.push('T-SAVD-02');
      await rig.settle();
      rig.nav.reset('T-PROF-01');
      await rig.settle();
      expect(rig.shows('T-PROF-01'), isTrue);
      expect(rig.nav.activeTab, 'profile');
      rig.nav.switchTab('saved');
      await rig.settle();
      expect(rig.shows('T-SAVD-01'), isTrue);
      rig.nav.switchTab('discover');
      await rig.settle();
      expect(rig.shows('T-DISC-01'), isTrue);
      expect(rig.shows('T-DISC-02'), isFalse);
    });

    testWidgets('reset from the first-start screen enters the tabs', (tester) async {
      final rig = await pumpNav(tester, initialLocation: '/onboarding/start');
      expect(rig.nav.activeTab, isNull);
      rig.nav.reset('T-DISC-01');
      await rig.settle();
      expect(rig.shows('T-DISC-01'), isTrue);
      expect(rig.barVisible, isTrue);
      expect(rig.nav.activeTab, 'discover');
    });
  });

  group('tabs', () {
    testWidgets('switchTab restores each tab stack and does not rebuild the hidden branch', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.push('T-DISC-02');
      await rig.settle();
      rig.nav.switchTab('saved');
      await rig.settle();
      expect(rig.shows('T-SAVD-01'), isTrue);
      expect(rig.nav.activeTab, 'saved');
      final buildsOfDiscover = rig.seen.builds['T-DISC-02'];
      rig.nav.switchTab('discover');
      await rig.settle();
      expect(rig.shows('T-DISC-02'), isTrue);
      expect(rig.built('T-SAVD-01'), isTrue, reason: 'the visited tab stays mounted');
      expect(rig.seen.builds['T-DISC-02'], greaterThanOrEqualTo(buildsOfDiscover!));
      expect(find.byType(GzTabBar), findsOneWidget);
    });

    testWidgets('tapping a tab in the bar switches; re-tapping the active tab pops to its root and bumps the scroll signal', (tester) async {
      final rig = await pumpNav(tester);
      await tester.tap(find.byKey(const ValueKey<String>('gz:tab.saved')));
      await rig.settle();
      expect(rig.shows('T-SAVD-01'), isTrue);
      rig.nav.push('T-SAVD-02');
      await rig.settle();
      expect(rig.shows('T-SAVD-02'), isTrue);
      final before = rig.nav.scrollSignals[1].value;
      await tester.tap(find.byKey(const ValueKey<String>('gz:tab.saved')));
      await rig.settle();
      expect(rig.shows('T-SAVD-01'), isTrue);
      expect(rig.nav.scrollSignals[1].value, before + 1);
      expect(rig.nav.scrollSignals[0].value, 0);
    });

    testWidgets('system back on the root of a later tab goes to the first tab; on the first tab root it is not handled (the app exits)', (
      tester,
    ) async {
      final rig = await pumpNav(tester, initialLocation: '/saved/home');
      expect(rig.nav.activeTab, 'saved');
      final handled = await tester.binding.handlePopRoute();
      await rig.settle();
      expect(handled, isTrue);
      expect(rig.nav.activeTab, 'discover');
      expect(rig.shows('T-DISC-01'), isTrue);
      final again = await tester.binding.handlePopRoute();
      expect(again, isFalse);
    });

    testWidgets('system back inside a tab pops the screen first', (tester) async {
      final rig = await pumpNav(tester, initialLocation: '/saved/home');
      rig.nav.push('T-SAVD-02');
      await rig.settle();
      expect(await tester.binding.handlePopRoute(), isTrue);
      await rig.settle();
      expect(rig.shows('T-SAVD-01'), isTrue);
      expect(rig.nav.activeTab, 'saved');
    });

    testWidgets('the bar mirrors in RTL and keeps its order', (tester) async {
      final ltr = await pumpNav(tester, locale: const Locale('en'));
      final discoverLtr = tester.getCenter(find.byKey(const ValueKey<String>('gz:tab.discover'))).dx;
      final profileLtr = tester.getCenter(find.byKey(const ValueKey<String>('gz:tab.profile'))).dx;
      expect(discoverLtr, lessThan(profileLtr));
      expect(ltr.barVisible, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpNav(tester, locale: const Locale('ar'));
      final discoverRtl = tester.getCenter(find.byKey(const ValueKey<String>('gz:tab.discover'))).dx;
      final profileRtl = tester.getCenter(find.byKey(const ValueKey<String>('gz:tab.profile'))).dx;
      expect(discoverRtl, greaterThan(profileRtl), reason: 'first tab at inline-start (right in Arabic)');
    });
  });

  group('transitions', () {
    // The pushed page starts 24 dp toward the inline-end edge: right in LTR, left in RTL; reduced motion removes the travel.
    Future<(double, double)> pushedOffset(WidgetTester tester, {required Locale locale, bool reduced = false}) async {
      if (reduced) {
        tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      }
      final rig = await pumpNav(tester, locale: locale);
      rig.nav.push('T-DISC-02');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final early = tester.getCenter(find.text('screen:T-DISC-02')).dx;
      await rig.settle();
      final settled = tester.getCenter(find.text('screen:T-DISC-02')).dx;
      return (early, settled);
    }

    testWidgets('push travels in from the right in English', (tester) async {
      final (early, settled) = await pushedOffset(tester, locale: const Locale('en'));
      expect(early, greaterThan(settled + 1));
    });

    testWidgets('push travels in from the left in Arabic', (tester) async {
      final (early, settled) = await pushedOffset(tester, locale: const Locale('ar'));
      expect(early, lessThan(settled - 1));
    });

    testWidgets('reduced motion: no travel, the page only cross-fades', (tester) async {
      final (early, settled) = await pushedOffset(tester, locale: const Locale('ar'), reduced: true);
      expect(early, closeTo(settled, 0.01));
    });

    testWidgets('a tab switch cross-fades: both branches are drawn mid-switch, only the new one at the end', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.switchTab('saved');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('screen:T-DISC-01'), findsOneWidget, reason: 'the outgoing branch stays under the incoming one');
      expect(find.text('screen:T-SAVD-01'), findsOneWidget);
      await rig.settle();
      expect(find.text('screen:T-DISC-01'), findsNothing, reason: 'offstage once the fade is over');
      expect(rig.shows('T-SAVD-01'), isTrue);
    });
  });

  group('overlays', () {
    testWidgets('openSheet by id goes over the screen with its options; closeSheet closes it and calls onClose once', (tester) async {
      final rig = await pumpNav(tester);
      var closed = 0;
      final key = rig.nav.openSheet(
        'T-SHET-01',
        options: GzSheetOptions(params: <String, Object?>{'a': 1}, title: 'Sheet title', onClose: () => closed++),
      );
      await rig.settle();
      expect(key, isNotEmpty);
      expect(rig.shows('T-SHET-01'), isTrue);
      expect(find.text('Sheet title'), findsOneWidget);
      expect(rig.seen.of('T-SHET-01').params, <String, Object?>{'a': 1});
      rig.nav.closeSheet(key);
      await rig.settle();
      expect(rig.shows('T-SHET-01'), isFalse);
      expect(closed, 1);
      expect(rig.shows('T-DISC-01'), isTrue);
    });

    testWidgets('a sheet opened from inside a screen closes with the screen\'s own navigator', (tester) async {
      final rig = await pumpNav(tester);
      rig.seen.of('T-DISC-01').openSheet('T-SHET-01');
      await rig.settle();
      expect(rig.shows('T-SHET-01'), isTrue);
      rig.seen.of('T-SHET-01').closeSheet();
      await rig.settle();
      expect(rig.shows('T-SHET-01'), isFalse);
    });

    testWidgets('sheets stack: closeSheet without a key closes the top one', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.openSheet('T-SHET-01');
      await rig.settle();
      rig.nav.openSheetBuilder((context) => const Text('widget sheet'));
      await rig.settle();
      expect(find.text('widget sheet'), findsOneWidget);
      rig.nav.closeSheet();
      await rig.settle();
      expect(find.text('widget sheet'), findsNothing);
      expect(rig.shows('T-SHET-01'), isTrue);
      rig.nav.closeSheet();
      await rig.settle();
      expect(rig.shows('T-SHET-01'), isFalse);
    });

    testWidgets('a dismissible sheet closes on system back', (tester) async {
      final rig = await pumpNav(tester);
      rig.nav.openSheet('T-SHET-01');
      await rig.settle();
      expect(await tester.binding.handlePopRoute(), isTrue);
      await rig.settle();
      expect(rig.shows('T-SHET-01'), isFalse);
    });

    testWidgets('dialog resolves cancel on back', (tester) async {
      final rig = await pumpNav(tester);
      final result = rig.nav.openDialog(const GzDialogSpec(title: 'Sure?'));
      await rig.settle();
      expect(find.text('Sure?'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await rig.settle();
      expect(await result, GzDialogResult.cancel);
      expect(find.text('Sure?'), findsNothing);
    });

    testWidgets('toast shows above the bar, dismiss removes it, the bar height is told to the controller', (tester) async {
      final rig = await pumpNav(tester);
      final controller = rig.container.read(gzToastControllerProvider);
      expect(controller.bottomChrome.value, greaterThanOrEqualTo(GzTabBar.heightOf(0)));
      final key = rig.nav.toast(const GzToastSpec(message: 'Saved to your list'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Saved to your list'), findsOneWidget);
      rig.nav.dismissToast(key);
      await rig.settle();
      expect(find.text('Saved to your list'), findsNothing);
      rig.nav.push('T-DISC-03');
      await rig.settle();
      expect(controller.bottomChrome.value, 0, reason: 'a screen above the bar covers it: the toast drops');
    });
  });

  group('router redirect and the session', () {
    test('gzRedirect: a signed-in person leaves the first-start screen; a signed-out partner only sees the public flows', () {
      expect(gzRedirect(fixtureSpec, signedIn: true, location: '/onboarding/start'), '/discover/home');
      expect(gzRedirect(fixtureSpec, signedIn: false, location: '/onboarding/start'), isNull);
      expect(gzRedirect(fixtureSpec, signedIn: false, location: '/discover/home'), isNull, reason: 'the client app is open to guests');
      const partner = GzRouterSpec(
        app: GzAppKind.partner,
        tabs: <GzTabSpec>[],
        chrome: <String, GzScreenChrome>{},
        paths: <String, String>{},
        startPath: '/access/sign-in',
        homePath: '/today/home',
        requireSession: true,
        publicPrefixes: <String>['/access'],
      );
      expect(gzRedirect(partner, signedIn: false, location: '/today/home'), '/access/sign-in');
      expect(gzRedirect(partner, signedIn: false, location: '/access/code'), isNull);
      expect(gzRedirect(partner, signedIn: false, location: '/accessories'), '/access/sign-in');
      expect(gzRedirect(partner, signedIn: true, location: '/today/home'), isNull);
      expect(gzRedirect(partner, signedIn: true, location: '/access/sign-in'), '/today/home');
      expect(gzRedirect(partner, signedIn: true, location: '/__root/today/home'), isNull);
    });

    testWidgets('a signed-in session at the first-start location lands on the tab root; sign-in later re-evaluates', (tester) async {
      final rig = await pumpNav(tester, initialLocation: '/onboarding/start', useSession: true);
      expect(rig.shows('T-ONBD-01'), isTrue);
      rig.container
          .read(sessionProvider.notifier)
          .setSession(
            const ClientSession(
              user: AuthUser(id: 'u1', name: 'Reem', phone: '+96550000000', monogram: 'R'),
            ),
          );
      await rig.settle();
      expect(rig.shows('T-DISC-01'), isTrue);
      expect(rig.barVisible, isTrue);
    });
  });
}
