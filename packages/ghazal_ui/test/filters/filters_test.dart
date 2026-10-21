import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Governorate;
import 'package:ghazal_ui/src/filters/filters.dart';
import 'package:ghazal_ui/src/foundation.dart';

import '../inputs/inputs_harness.dart';

Governorate _gov(String id, String en, String ar) => Governorate.fromJson({
  'id': id,
  'name': {'en': en, 'ar': ar},
});

final _govs = [_gov('capital', 'Capital', 'العاصمة'), _gov('hawalli', 'Hawalli', 'حولي'), _gov('ahmadi', 'Al Ahmadi', 'الأحمدي')];

void main() {
  group('GzGovernorateFilter', () {
    testWidgets('All Kuwait is first and chosen; picking a governorate drops it, picking All clears the rest', (tester) async {
      final seen = <List<String>>[];
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs, onChanged: seen.add));
      expect(find.text('All Kuwait'), findsWidgets);
      await tester.ensureVisible(find.text('Hawalli').last);
      await tester.tap(find.text('Hawalli').last);
      await tester.pump();
      await tester.ensureVisible(find.text('Capital').last);
      await tester.tap(find.text('Capital').last);
      await tester.pump();
      expect(seen, [
        ['hawalli'],
        ['hawalli', 'capital'],
      ]);
      await tester.ensureVisible(find.text('All Kuwait').last);
      await tester.tap(find.text('All Kuwait').last);
      await tester.pump();
      expect(seen.last, isEmpty);
    });

    testWidgets('controlled values show as selected chips; the names are the data in the UI language', (tester) async {
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs, values: const ['hawalli']), lang: 'ar');
      expect(find.text('كل الكويت'), findsWidgets);
      expect(find.text('حولي'), findsWidgets);
      // the chosen chip carries a bead and is taller than nothing: every chip is 44 dp high
      expect(tester.getSize(find.byType(GzGovernorateFilter)).height, 44);
    });
  });

  group('GzVenueTypeChips', () {
    testWidgets('multi-select: toggling adds and removes, the default is chosen, chips are 44 dp high', (tester) async {
      final seen = <List<GzVenueType>>[];
      await pumpInputs(tester, GzVenueTypeChips(defaultValues: const [GzVenueType.hotel], onChanged: seen.add), width: 800);
      final chip = tester.getSize(find.ancestor(of: find.text('Private hall').first, matching: find.byType(GzPressable)).first);
      expect(chip.height, 44);
      await tester.tap(find.text('Private hall').last);
      await tester.pump();
      await tester.tap(find.text('Hotel').last);
      await tester.pump();
      expect(seen, [
        [GzVenueType.hotel, GzVenueType.privateHall],
        [GzVenueType.privateHall],
      ]);
    });

    testWidgets('semantics: a selected chip reads selected; RTL puts the first type at the right', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInputs(tester, const GzVenueTypeChips(values: [GzVenueType.hotel]), lang: 'ar', width: 800);
      final hotel = tester.getSemantics(find.ancestor(of: find.text('فندق').first, matching: find.byType(GzPressable)).first);
      expect(hotel.flagsCollection.isSelected.name, 'isTrue');
      expect(tester.getCenter(find.text('قاعة خاصة').first).dx, greaterThan(tester.getCenter(find.text('منشأة حكومية').first).dx));
      handle.dispose();
    });
  });

  group('GzCapacityRange', () {
    testWidgets('the summary states the range and follows the value', (tester) async {
      var value = (250.0, 500.0);
      late StateSetter set;
      await pumpInputs(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return GzCapacityRange(min: 60, max: 1200, value: value);
          },
        ),
      );
      expect(find.textContaining('250', findRichText: true), findsWidgets);
      expect(find.textContaining('guests', findRichText: true), findsOneWidget);
      set(() => value = (100.0, 900.0));
      await tester.pump();
      expect(find.textContaining('900', findRichText: true), findsWidgets);
    });

    testWidgets('RTL: the lower value sits at the inline-start (right)', (tester) async {
      await pumpInputs(tester, const GzCapacityRange(min: 60, max: 1200, defaultValue: (250, 500)), lang: 'ar');
      Finder figure(String n) => find.byWidgetPredicate((w) => w is Text && w.data == '\u2066$n\u2069');
      final lo = tester.getCenter(figure('250')).dx;
      final hi = tester.getCenter(figure('500')).dx;
      expect(lo, greaterThan(hi));
    });
  });

  group('GzPricingStructureToggle', () {
    testWidgets('per person is the default, choosing Packages reports it, includeAll adds All first', (tester) async {
      final seen = <GzPricingStructure>[];
      await pumpInputs(tester, GzPricingStructureToggle(onChanged: seen.add));
      expect(find.text('All'), findsNothing);
      await tester.tap(find.text('Packages'));
      await tester.pump();
      expect(seen, [GzPricingStructure.package]);
      await pumpInputs(tester, const GzPricingStructureToggle(includeAll: true));
      expect(find.text('All'), findsOneWidget);
      expect(tester.getCenter(find.text('All')).dx, lessThan(tester.getCenter(find.text('Per person')).dx));
    });
  });
}
