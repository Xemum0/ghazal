import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/brand/brand.dart';
import 'package:ghazal_ui/src/client/client_c.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/overlays/gz_photo.dart';

import '../core/core_harness.dart';
import '../shared/shared_harness.dart';
import 'client_c_fixtures.dart';

void main() {
  setUpAll(loadUiFonts);

  group('GzPlannerTierCard', () {
    testWidgets('one bead per mark, the from price and every inclusion; the consultation button only when asked for', (tester) async {
      await pumpCore(tester, SingleChildScrollView(child: SizedBox(width: 350, child: GzPlannerTierCard(pkg: plannerPackage(marks: 3)))), size: const Size(350, 1200));
      expect(find.byType(GzThreadBead), findsNWidgets(3));
      expect(find.text('Everything in Silver'), findsOneWidget);
      expect(find.text('Two planning meetings'), findsOneWidget);
      expect(find.byType(GzPrice), findsOneWidget);
      expect(find.byType(GzButton), findsNothing);
      var asked = 0;
      await pumpCore(tester, SingleChildScrollView(child: SizedBox(width: 350, child: GzPlannerTierCard(pkg: plannerPackage(), onRequest: () => asked++))), size: const Size(350, 1200));
      await tester.tap(find.byType(GzButton));
      expect(asked, 1);
    });

    testWidgets('choosing: the head is one radio that reports selection; selected has the ink border', (tester) async {
      final handle = tester.ensureSemantics();
      var picked = 0;
      await pumpCore(tester, SingleChildScrollView(child: SizedBox(width: 350, child: GzPlannerTierCard(pkg: plannerPackage(), onSelect: () => picked++))), size: const Size(350, 1200));
      await tester.tap(find.text('Planning and styling'));
      expect(picked, 1);
      final c = GzColors.light;
      BoxDecoration deco() => tester.widgetList<Container>(find.byType(Container)).map((w) => w.decoration).whereType<BoxDecoration>().firstWhere((d) => d.border is Border && d.borderRadius == GzRadius.mdAll);
      expect((deco().border! as Border).top.color, c.borderStrong);
      await pumpCore(tester, SingleChildScrollView(child: SizedBox(width: 350, child: GzPlannerTierCard(pkg: plannerPackage(), selected: true, onSelect: () {}))), size: const Size(350, 1200));
      expect((deco().border! as Border).top.color, c.controlChipBorderSelected);
      handle.dispose();
    });

    testWidgets('loading shows skeletons and no content', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzPlannerTierCard(pkg: plannerPackage(), loading: true)));
      expect(find.byType(GzSkeleton), findsNWidgets(4));
      expect(find.text('Gold'), findsNothing);
    });
  });

  group('GzServiceTile', () {
    testWidgets('one button named "Open <name>" that fires onOpen; the plate is 4:5', (tester) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await pumpCore(tester, SizedBox(width: 169, child: GzServiceTile(category: serviceCategory(), onOpen: () => opened++)));
      expect(find.bySemanticsLabel('Open Hospitality and catering'), findsOneWidget);
      final photo = tester.getSize(find.byType(GzPhoto));
      expect(photo.height / photo.width, closeTo(1.25, 0.01));
      await tester.tap(find.byType(GzServiceTile));
      expect(opened, 1);
      handle.dispose();
    });

    testWidgets('pressed preview scales the tile; the unit follows the price; loading is skeletons', (tester) async {
      await pumpCore(tester, SizedBox(width: 169, child: GzServiceTile(category: serviceCategory(), previewState: GzPreviewState.pressed)));
      expect(find.byType(Transform), findsWidgets);
      expect(find.text('per guest'), findsOneWidget);
      await pumpCore(tester, SizedBox(width: 169, child: GzServiceTile(category: serviceCategory(), loading: true)));
      expect(find.byType(GzSkeleton), findsNWidgets(2));
    });

    testWidgets('Arabic: the name is the Arabic name and the unit is Arabic', (tester) async {
      await pumpCore(tester, SizedBox(width: 169, child: GzServiceTile(category: serviceCategory())), lang: 'ar');
      expect(find.text('الضيافة والتموين'), findsOneWidget);
      expect(find.text('للضيف الواحد'), findsOneWidget);
    });
  });

  group('GzVendorCard', () {
    Future<void> pump(WidgetTester tester, Widget card, {String lang = 'en'}) =>
        pumpCore(tester, SingleChildScrollView(child: SizedBox(width: 350, child: card)), size: const Size(350, 1200), lang: lang);

    testWidgets('the heart toggles through the callback with the flipped value and the name follows the state', (tester) async {
      final handle = tester.ensureSemantics();
      final calls = <bool>[];
      await pump(tester, GzVendorCard(vendor: vendor(), onFavouriteChange: calls.add));
      expect(find.bySemanticsLabel('Save to favourites'), findsOneWidget);
      await tester.tap(find.byType(GzIconButton));
      expect(calls, [true]);
      await pump(tester, GzVendorCard(vendor: vendor(), favourite: true, onFavouriteChange: calls.add));
      expect(find.bySemanticsLabel('Remove from favourites'), findsOneWidget);
      await tester.tap(find.byType(GzIconButton));
      expect(calls, [true, false]);
      handle.dispose();
    });

    testWidgets('rated shows the rating, a vendor without one says New; verified and female team are shown', (tester) async {
      await pump(tester, GzVendorCard(vendor: vendor()));
      expect(find.byType(GzRating), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Female team for ladies’ halls'), findsOneWidget);
      expect(find.textContaining('Usually replies within'), findsOneWidget);
      await pump(tester, GzVendorCard(vendor: vendor(rated: false, female: false, verified: false)));
      expect(find.byType(GzRating), findsNothing);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Verified'), findsNothing);
    });

    testWidgets('member sees the voucher price headline with the standard price struck; guest sees the lock line', (tester) async {
      await pump(tester, GzVendorCard(vendor: vendor()));
      expect(tester.widget<GzPrice>(find.byType(GzPrice)).fils, 5500);
      expect(tester.widget<GzPrice>(find.byType(GzPrice)).was, 7500);
      await pump(tester, GzVendorCard(vendor: vendor(), audience: GzVendorAudience.guest));
      expect(tester.widget<GzPrice>(find.byType(GzPrice)).fils, 7500);
      expect(find.text('Voucher price after you sign up'), findsOneWidget);
      expect(find.byIcon(GzIcons.lock), findsOneWidget);
    });

    testWidgets('the row variant drops the portfolio strip and the facts; the card opens on tap', (tester) async {
      var opened = 0;
      await pump(tester, GzVendorCard(vendor: vendor(), onOpen: () => opened++));
      expect(find.byType(GzPhoto), findsNWidgets(3));
      await tester.tap(find.text('From'));
      expect(opened, 1);
      await pump(tester, GzVendorCard(vendor: vendor(), variant: GzVendorVariant.row));
      expect(find.byType(GzPhoto), findsNothing);
      expect(find.byType(GzTag), findsNothing);
    });

    testWidgets('the heart sits at inline-end (right in English, left in Arabic) and is a 44 dp target', (tester) async {
      await pump(tester, GzVendorCard(vendor: vendor(), onFavouriteChange: (_) {}));
      expect(tester.getTopRight(find.byType(GzIconButton)).dx, 330);
      expect(tester.getSize(find.byType(GzIconButton)).width, greaterThanOrEqualTo(44));
      await pump(tester, GzVendorCard(vendor: vendor(), onFavouriteChange: (_) {}), lang: 'ar');
      expect(tester.getTopLeft(find.byType(GzIconButton)).dx, 20);
    });
  });
}
