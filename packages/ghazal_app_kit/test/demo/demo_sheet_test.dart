import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/src/demo/demo.dart';
import 'package:ghazal_app_kit/src/session/session.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../data/kit_world.dart';

Widget host(Widget child, ProviderContainer container, {Locale locale = const Locale('en')}) => UncontrolledProviderScope(
  container: container,
  child: MediaQuery(
    data: const MediaQueryData(size: Size(390, 844)),
    child: Directionality(
      textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: GzTheme(
        locale: locale,
        child: GzFormatScope(
          format: container.read(gzFormatProvider),
          child: Localizations(
            locale: locale,
            delegates: const [GzL10n.delegate, DefaultWidgetsLocalizations.delegate],
            child: SizedBox(width: 390, height: 844, child: child),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  late KitWorld world;
  setUpAll(() async => world = await KitWorld.load());
  setUp(() async => world.fresh());
  tearDown(KitWorld.disposeAll);

  testWidgets('five taps inside the window activate the hotspot; four do not; slow taps do not count', (tester) async {
    var opened = 0;
    var now = DateTime.utc(2026, 11, 12, 13);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [GzDemoHotspot(onActivated: () => opened++, now: () => now)],
        ),
      ),
    );
    final spot = find.byType(GzDemoHotspot);
    expect(tester.getSize(find.descendant(of: spot, matching: find.byType(SizedBox)).first), const Size(44, 44));
    for (var i = 0; i < 4; i++) {
      await tester.tapAt(const Offset(10, 10));
    }
    expect(opened, 0);
    await tester.tapAt(const Offset(10, 10));
    expect(opened, 1);
    for (var i = 0; i < 5; i++) {
      now = now.add(const Duration(seconds: 2)); // each tap is 2 s after the last: never five inside 3 s
      await tester.tapAt(const Offset(10, 10));
    }
    expect(opened, 1);
  });

  testWidgets('the hotspot sits at the top-start corner in both directions', (tester) async {
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: dir,
          child: Stack(children: [GzDemoHotspot(onActivated: () {})]),
        ),
      );
      final rect = tester.getRect(find.descendant(of: find.byType(GzDemoHotspot), matching: find.byType(SizedBox)).first);
      expect(rect.top, 0);
      if (dir == TextDirection.ltr) {
        expect(rect.left, 0);
      } else {
        expect(rect.right, tester.view.physicalSize.width / tester.view.devicePixelRatio);
      }
    }
  });

  testWidgets('the sheet lists the personas, scenarios and story points and a persona chip switches the session', (tester) async {
    final c = world.container();
    await tester.pumpWidget(host(const GzDemoToolsSheet(), c));
    await tester.pump();
    for (final label in [
      'Guest',
      'Reem',
      'Hotel manager',
      'Service provider',
      'Slow',
      'Offline',
      'Awaiting reply',
      'Forfeited',
      'Advance one day',
      'Reset the story',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('In-process mock'), findsOneWidget);

    await tester.ensureVisible(find.text('Hotel manager').first);
    await tester.tap(find.text('Hotel manager').first);
    // the switch runs through the in-process mock: real time passes, then the fake-async microtasks continue on a pump
    for (var i = 0; i < 10 && c.read(sessionProvider) is! PartnerSession; i++) {
      await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(c.read(sessionProvider), isA<PartnerSession>());
    expect(c.read(demoProvider).persona, 'hotel_manager');
  });

  testWidgets('the sheet words are Arabic in Arabic', (tester) async {
    final c = world.container();
    await tester.pumpWidget(host(const GzDemoToolsSheet(), c, locale: const Locale('ar')));
    await tester.pump();
    expect(find.text('إعادة ضبط القصة'), findsOneWidget);
    expect(find.text('مدير الفندق'), findsWidgets);
    expect(find.text('سقط الكوبون'), findsWidgets);
  });
}
