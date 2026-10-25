import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/hotel/hotel.dart';
import 'package:ghazal_ui/src/nav/nav.dart';

import '../shared/shared_harness.dart';
import 'nav_harness.dart';

void main() {
  setUpAll(loadUiFonts);

  testWidgets('GzActionBar: a long secondary label and a long primary spill instead of overflowing (web border-box buttons)', (tester) async {
    await pumpNav(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: GzActionBar(
          action: GzActionBarAction(label: 'Redeem voucher now please', onPressed: () {}),
          secondary: GzActionBarAction(label: 'Another method', onPressed: () {}),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('GzTopBar takes three actions', (tester) async {
    await pumpNav(
      tester,
      GzTopBar(
        title: 'Bookings',
        back: GzTopBarBack.hide,
        actions: [
          for (final n in ['One', 'Two', 'Three']) GzTopBarAction(icon: GzIcons.search, label: n, onPressed: () {}),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Three'), findsOneWidget);
  });

  testWidgets('GzKpiTile survives IntrinsicHeight (equal-height tile row)', (tester) async {
    await pumpNav(
      tester,
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: GzKpiTile(label: 'Requests', value: const GzKpiValue.count(12), delta: 8)),
            Expanded(child: GzKpiTile(label: 'Visits', value: const GzKpiValue.count(3))),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('GzTopBar with a subtitle at text scale 1.3 does not overflow (ar and en)', (tester) async {
    for (final lang in ['ar', 'en']) {
      await pumpNav(
        tester,
        MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.3,
          maxScaleFactor: 1.3,
          child: GzTopBar(title: 'Bookings', subtitle: 'Hall details', back: GzTopBarBack.hide),
        ),
        lang: lang,
      );
      expect(tester.takeException(), isNull, reason: lang);
    }
  });
}
