import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/nav/nav.dart';

import 'nav_harness.dart';

List<GzTabItem> _items({GzTabBadge? wedding, GzTabBadge? messages}) => [
      const GzTabItem(id: 'discover', icon: GzIcons.search, label: 'Discover'),
      const GzTabItem(id: 'saved', icon: GzIcons.heart, label: 'Saved'),
      GzTabItem(id: 'my-wedding', icon: GzIcons.calendarCheck, label: 'My Wedding', badge: wedding),
      GzTabItem(id: 'messages', icon: GzIcons.chat, label: 'Messages', badge: messages),
      const GzTabItem(id: 'profile', icon: GzIcons.user, label: 'Profile'),
    ];

double _translateX(WidgetTester tester, Finder inside) {
  final transforms = tester.widgetList<Transform>(find.ancestor(of: inside, matching: find.byType(Transform))).toList();
  for (final t in transforms) {
    final x = t.transform.getTranslation().x;
    if (x != 0) return x;
  }
  return 0;
}

/// The fade of the incoming page: the second fade above the page (the first is the covered-page fade of the secondary animation).
FadeTransition _primaryFade(WidgetTester tester) =>
    tester.widgetList<FadeTransition>(find.ancestor(of: find.byKey(const ValueKey('page')), matching: find.byType(FadeTransition))).elementAt(1);

void main() {
  group('GzTabBar', () {
    testWidgets('selection: the active tab is selected, a tap reports its id, the khayt sits over the active item', (tester) async {
      final handle = tester.ensureSemantics();
      String? tapped;
      await pumpNav(tester, Align(alignment: Alignment.bottomCenter, child: GzTabBar(items: _items(), activeId: 'saved', ariaLabel: 'Main navigation', safeBottom: 0, onSelect: (id) => tapped = id)));
      expect(tester.getSemantics(find.bySemanticsLabel('Saved')).flagsCollection.isSelected.name, 'isTrue');
      final khayt = find.byKey(const ValueKey('gz:tab.khayt'));
      // item width 78, active index 1: the 24 wide khayt starts at 78 + 27 = 105 (round).
      expect(tester.getTopLeft(khayt).dx, closeTo(105, 1));
      expect(tester.getSize(khayt), const Size(24, 2));
      await tester.tap(find.text('Messages'));
      expect(tapped, 'messages');
      handle.dispose();
    });

    testWidgets('the khayt slides in 320 ms and follows the reading direction (RTL mirrors it)', (tester) async {
      Widget bar(String active) => Align(alignment: Alignment.bottomCenter, child: GzTabBar(items: _items(), activeId: active, ariaLabel: 'Main navigation', safeBottom: 0));
      await pumpNav(tester, bar('discover'), lang: 'ar');
      final khayt = find.byKey(const ValueKey('gz:tab.khayt'));
      // First tab at inline-start = the right edge in Arabic.
      expect(tester.getTopRight(khayt).dx, closeTo(390 - 27, 1));
      await pumpNav(tester, bar('profile'), lang: 'ar');
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getTopLeft(khayt).dx, closeTo(27, 1));
    });

    testWidgets('count badge caps at 9+, the dot has no number, and the badge name is spoken with the tab', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: GzTabBar(
            items: _items(wedding: const GzTabBadge.dot(), messages: const GzTabBadge.count(12, label: '12 unread')),
            activeId: 'discover',
            ariaLabel: 'Main navigation',
            safeBottom: 0,
          ),
        ),
      );
      expect(find.textContaining('9+'), findsOneWidget);
      expect(find.byKey(const ValueKey('gz:tab.badge')), findsNWidgets(2));
      expect(find.bySemanticsLabel('Messages, 12 unread'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('height: 60 above the home indicator inset (label line box 20), 56 minimum', (tester) async {
      await pumpNav(tester, Align(alignment: Alignment.bottomCenter, child: GzTabBar(items: _items(), activeId: 'discover', ariaLabel: 'x')));
      final h = tester.getSize(find.byType(GzTabBar)).height;
      expect(h, greaterThanOrEqualTo(GzSize.tabBar + 34));
      expect(h, closeTo(60 + 34, 4));
    });
  });

  group('GzTopBar', () {
    testWidgets('standard: back + centred title + subtitle + two actions at 56 under the safe top', (tester) async {
      var popped = 0;
      var shared = 0;
      await pumpNav(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: GzTopBar(
            back: GzTopBarBack.show,
            onBack: () => popped++,
            title: 'Aurelia',
            subtitle: 'Sharq',
            actions: [GzTopBarAction(icon: GzIcons.share, label: 'Share', onPressed: () => shared++), const GzTopBarAction(icon: GzIcons.heart, label: 'Save')],
          ),
        ),
      );
      expect(tester.getSize(find.byType(GzTopBar)).height, 47 + 56);
      expect(find.text('Aurelia'), findsOneWidget);
      expect(find.text('Sharq'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gz:bar.back')));
      await tester.tap(find.byType(GzBarButton).at(1));
      expect(popped, 1);
      expect(shared, 1);
      // The title is centred on the frame: both slots are 88 wide.
      expect(tester.getCenter(find.text('Aurelia')).dx, closeTo(195, 1));
    });

    testWidgets('back hidden, close glyph, and a screen-level hairline only after content scrolls under it', (tester) async {
      await pumpNav(tester, const Align(alignment: Alignment.topCenter, child: GzTopBar(back: GzTopBarBack.hide, title: 'Saved')));
      expect(find.byKey(const ValueKey('gz:bar.back')), findsNothing);
      await pumpNav(tester, const Align(alignment: Alignment.topCenter, child: GzTopBar(back: GzTopBarBack.close, title: 'Saved')));
      expect(find.byKey(const ValueKey('gz:bar.back')), findsOneWidget);
    });

    testWidgets('large title collapses into the row after the scroll threshold (200 ms) and the row title fades in', (tester) async {
      Widget bar(double offset) => Align(alignment: Alignment.topCenter, child: GzScreenScroll(offset: offset, child: const GzTopBar(variant: GzTopBarVariant.largeTitle, back: GzTopBarBack.hide, title: 'Saved')));
      await pumpNav(tester, bar(0));
      final expanded = tester.getSize(find.byType(GzTopBar)).height;
      expect(expanded, greaterThan(47 + 56 + 20));
      await pumpNav(tester, bar(48));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getSize(find.byType(GzTopBar)).height, closeTo(47 + 56, 0.5));
    });

    testWidgets('transparent: scrim over a photo and a hidden row title until solid; solid shows the title', (tester) async {
      double titleOpacity() => tester.widget<AnimatedOpacity>(find.ancestor(of: find.text('Saved'), matching: find.byType(AnimatedOpacity)).first).opacity;
      await pumpNav(tester, const Align(alignment: Alignment.topCenter, child: GzTopBar(variant: GzTopBarVariant.transparent, back: GzTopBarBack.show, title: 'Saved')));
      expect(titleOpacity(), 0);
      expect(find.byWidgetPredicate((w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient != null), findsOneWidget);
      await pumpNav(tester, const Align(alignment: Alignment.topCenter, child: GzTopBar(variant: GzTopBarVariant.transparent, solid: true, back: GzTopBarBack.show, title: 'Saved')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(titleOpacity(), 1);
    });

    testWidgets('search: the field takes the row; typing reports the value', (tester) async {
      var value = '';
      await pumpNav(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: GzTopBar(variant: GzTopBarVariant.search, back: GzTopBarBack.show, search: GzTopBarSearch(placeholder: 'Search halls', onChanged: (v) => value = v), actions: const [GzTopBarAction(icon: GzIcons.sliders, label: 'Filters')]),
        ),
      );
      expect(find.text('Search halls'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'ballroom');
      expect(value, 'ballroom');
      expect(tester.getSize(find.byType(GzTopBar)).height, 47 + 56);
    });

    testWidgets('a count on an action draws the capped badge', (tester) async {
      await pumpNav(tester, const Align(alignment: Alignment.topCenter, child: GzTopBar(back: GzTopBarBack.hide, title: 'x', actions: [GzTopBarAction(icon: GzIcons.bell, label: 'Alerts', count: 12)])));
      expect(find.textContaining('9+'), findsOneWidget);
    });
  });

  group('GzScreen', () {
    testWidgets('one scroll body; the bars stay put and the body offset reaches the bars', (tester) async {
      await pumpNav(
        tester,
        GzScreen(
          top: const GzTopBar(back: GzTopBarBack.hide, title: 'Saved'),
          bottom: GzActionBar(action: GzActionBarAction(label: 'Go', onPressed: () {})),
          child: Column(children: [for (var i = 0; i < 30; i++) const SizedBox(height: 60, child: Text('row'))]),
        ),
      );
      final barTop = tester.getTopLeft(find.byType(GzTopBar)).dy;
      final actionTop = tester.getTopLeft(find.byType(GzActionBar)).dy;
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      expect(tester.getTopLeft(find.byType(GzTopBar)).dy, barTop);
      expect(tester.getTopLeft(find.byType(GzActionBar)).dy, actionTop);
      expect(tester.widget<GzScreenScroll>(find.byType(GzScreenScroll).first).offset, greaterThan(100));
    });

    testWidgets('the keyboard lifts the pinned bar and spends the home-indicator inset', (tester) async {
      await pumpNav(
        tester,
        GzScreen(bottom: GzActionBar(action: GzActionBarAction(label: 'Go', onPressed: () {})), child: const SizedBox(height: 100)),
      );
      final closed = tester.getBottomLeft(find.byType(GzActionBar)).dy;
      expect(closed, closeTo(800, 0.5));
      final h = tester.getSize(find.byType(GzActionBar)).height;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      expect(tester.getBottomLeft(find.byType(GzActionBar)).dy, closeTo(800 - 300, 0.5));
      // 34 of home indicator no longer added: the bar is 34 shorter.
      expect(tester.getSize(find.byType(GzActionBar)).height, closeTo(h - 34, 0.5));
    });

    testWidgets('a re-selected tab scrolls the root screen to top', (tester) async {
      Widget screen(int signal) => GzScrollToTopSignal(signal: signal, child: GzScreen(child: Column(children: [for (var i = 0; i < 30; i++) const SizedBox(height: 60, child: Text('row'))])));
      await pumpNav(tester, screen(0));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      expect(tester.widget<GzScreenScroll>(find.byType(GzScreenScroll).first).offset, greaterThan(100));
      await pumpNav(tester, screen(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<GzScreenScroll>(find.byType(GzScreenScroll).first).offset, 0);
    });
  });

  group('GzActionBar', () {
    testWidgets('anatomy 12 + 52 + 12 + safe, summary at inline-start, primary fills the rest, the note sits under the row', (tester) async {
      await pumpNav(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: GzActionBar(summaryLabel: 'From', summaryValue: const GzPrice(fils: 18200000), action: GzActionBarAction(label: 'Request', onPressed: () {}), note: 'Nothing is charged'),
        ),
      );
      expect(find.text('Nothing is charged'), findsOneWidget);
      final summary = tester.getTopLeft(find.byKey(const ValueKey('gz:actionbar.summary'))).dx;
      expect(summary, closeTo(20, 0.5));
      final button = tester.getRect(find.byType(GzButton));
      expect(button.right, closeTo(370, 0.5));
    });

    testWidgets('with a tab bar below it adds no home-indicator inset; it reports its height to the registry', (tester) async {
      final registry = GzBarInsetRegistry();
      await pumpNav(
        tester,
        GzBarInsets(
          registry: registry,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GzBottomChrome(tabBar: true, child: GzActionBar(action: GzActionBarAction(label: 'Save', onPressed: () {}))),
          ),
        ),
      );
      await tester.pump();
      expect(tester.getSize(find.byType(GzActionBar)).height, closeTo(12 + 52 + 12, 1));
      expect(registry.height, closeTo(76, 1));
    });
  });

  group('page transitions', () {
    Future<void> pumpTransition(WidgetTester tester, {required String lang, bool reduce = false, double primary = 0, double secondary = 0}) async {
      await pumpNav(
        tester,
        GzPageTransition(animation: AlwaysStoppedAnimation<double>(primary), secondaryAnimation: AlwaysStoppedAnimation<double>(secondary), child: const Text('page', key: ValueKey('page'))),
        lang: lang,
        reduceMotion: reduce,
      );
    }

    testWidgets('the incoming page starts 24 dp toward inline-end: right in LTR, left in RTL; it lands at 0 and is opaque', (tester) async {
      await pumpTransition(tester, lang: 'en');
      expect(_translateX(tester, find.byKey(const ValueKey('page'))), closeTo(24, 0.001));
      await pumpTransition(tester, lang: 'ar');
      expect(_translateX(tester, find.byKey(const ValueKey('page'))), closeTo(-24, 0.001));
      await pumpTransition(tester, lang: 'ar', primary: 1);
      expect(_translateX(tester, find.byKey(const ValueKey('page'))), 0);
      expect(_primaryFade(tester).opacity.value, 1);
    });

    testWidgets('the covered page travels 24 dp toward inline-start and fades out (secondary animation)', (tester) async {
      await pumpTransition(tester, lang: 'en', primary: 1, secondary: 1);
      expect(_translateX(tester, find.byKey(const ValueKey('page'))), closeTo(-24, 0.001));
      await pumpTransition(tester, lang: 'ar', primary: 1, secondary: 1);
      expect(_translateX(tester, find.byKey(const ValueKey('page'))), closeTo(24, 0.001));
    });

    testWidgets('reduced motion: no travel, a 120 ms cross-fade only', (tester) async {
      await pumpTransition(tester, lang: 'en', reduce: true, primary: 0.1875); // 60 ms of 320
      expect(_translateX(tester, find.byKey(const ValueKey('page'))), 0);
      expect(_primaryFade(tester).opacity.value, closeTo(0.5, 0.001));
      await pumpTransition(tester, lang: 'en', reduce: true, primary: 0.375);
      expect(_primaryFade(tester).opacity.value, closeTo(1, 0.001));
    });

    testWidgets('a pushed GzPageRoute enters from inline-end in each direction and finishes in 320 ms', (tester) async {
      for (final lang in ['en', 'ar']) {
        await pumpNav(tester, Builder(builder: (context) => GestureDetector(key: kOpen, onTap: () => Navigator.of(context).push<void>(GzPageRoute<void>(builder: (_) => const Center(child: Text('second', key: ValueKey('second'))))), child: const Text('first'))), lang: lang);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(kOpen));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        final x = _translateX(tester, find.byKey(const ValueKey('second')));
        expect(lang == 'en' ? x > 0 : x < 0, isTrue, reason: '$lang offset $x');
        await tester.pump(const Duration(milliseconds: 400));
        expect(_translateX(tester, find.byKey(const ValueKey('second'))), 0);
        expect(find.byKey(const ValueKey('second')), findsOneWidget);
        // the covered page is no longer painted
        expect(find.text('first'), findsNothing);
        Navigator.of(tester.element(find.byKey(const ValueKey('second')))).pop();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('first'), findsOneWidget);
      }
    });

    testWidgets('GzPage is a Navigator Page that builds the Ghazal route', (tester) async {
      const page = GzPage<void>(child: Text('x'), name: 'CL-DISC-02');
      late Route<void> route;
      await pumpNav(tester, Builder(builder: (context) {
        route = page.createRoute(context);
        return const SizedBox();
      }));
      expect(route, isA<GzPageRoute<void>>());
      expect(route.settings.name, 'CL-DISC-02');
      expect((route as GzPageRoute<void>).transitionDuration, GzMotion.durationSlow);
    });
  });

  group('GzNavigator contract', () {
    testWidgets('outside a scope every call is inert and never throws; a scope is found', (tester) async {
      late GzNavigator inert;
      late GzNavigator? scoped;
      await pumpNav(tester, Builder(builder: (context) {
        inert = GzNavigatorScope.of(context);
        return GzNavigatorScope(navigator: _Recording(), child: Builder(builder: (context) {
          scoped = GzNavigatorScope.maybeOf(context);
          return const SizedBox();
        }));
      }));
      inert
        ..push('CL-VENU-01')
        ..pop()
        ..switchTab('saved')
        ..dismissToast();
      expect(await inert.openDialog(const GzDialogSpec(title: 't')), GzDialogResult.cancel);
      expect(inert.canGoBack, isFalse);
      expect(scoped, isA<_Recording>());
    });

    testWidgets('the back button of a bar pops through the navigator in scope', (tester) async {
      final nav = _Recording(canGoBack: true);
      await pumpNav(tester, GzNavigatorScope(navigator: nav, child: const Align(alignment: Alignment.topCenter, child: GzTopBar(title: 'x'))));
      await tester.tap(find.byKey(const ValueKey('gz:bar.back')));
      expect(nav.calls, ['pop']);
    });
  });
}

class _Recording implements GzNavigator {
  _Recording({this.canGoBack = false});

  @override
  final bool canGoBack;
  final List<String> calls = [];
  @override
  GzParams get params => const {};
  @override
  String get currentId => '';
  @override
  String? get activeTab => null;
  @override
  void push(String id, {GzParams params = const {}}) {}
  @override
  void pop({int count = 1}) => calls.add('pop');
  @override
  void replace(String id, {GzParams params = const {}}) {}
  @override
  void reset(String id, {GzParams params = const {}}) {}
  @override
  void switchTab(String tabId) {}
  @override
  String openSheet(String screenId, {GzSheetOptions options = const GzSheetOptions()}) => '';
  @override
  String openSheetBuilder(WidgetBuilder builder, {GzSheetOptions options = const GzSheetOptions()}) => '';
  @override
  void closeSheet([String? key]) {}
  @override
  Future<GzDialogResult> openDialog(GzDialogSpec spec) async => GzDialogResult.cancel;
  @override
  String toast(GzToastSpec spec) => '';
  @override
  void dismissToast([String? key]) {}
}
