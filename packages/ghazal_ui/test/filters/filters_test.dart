import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Governorate;
import 'package:ghazal_ui/src/core/core.dart' show GzBeadBox;
import 'package:ghazal_ui/src/filters/filters.dart';
import 'package:ghazal_ui/src/foundation.dart';

import 'package:ghazal_ui/src/inputs/inputs.dart' show GzChipLayout;

import '../inputs/inputs_harness.dart';
import '../shared/shared_harness.dart';

Governorate _gov(String id, String en, String ar) => Governorate.fromJson({
  'id': id,
  'name': {'en': en, 'ar': ar},
});

final _govs = [
  _gov('capital', 'Capital', 'العاصمة'),
  _gov('hawalli', 'Hawalli', 'حولي'),
  _gov('farwaniya', 'Farwaniya', 'الفروانية'),
  _gov('ahmadi', 'Ahmadi', 'الأحمدي'),
  _gov('jahra', 'Jahra', 'الجهراء'),
  _gov('mubarak-al-kabeer', 'Mubarak Al-Kabeer', 'مبارك الكبير'),
];

void main() {
  setUpAll(loadUiFonts);

  group('GzGovernorateFilter', () {
    Finder chips() => find.byType(GzPressable);

    testWidgets('wrapping multi-select: nothing is lit (every governorate), a tap adds, a second tap removes; no "All" chip', (tester) async {
      final seen = <List<String>>[];
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs, onChanged: seen.add));
      expect(find.text('All Kuwait'), findsNothing);
      expect(chips(), findsNWidgets(6));
      await tester.tap(find.text('Hawalli'));
      await tester.pump();
      await tester.tap(find.text('Capital'));
      await tester.pump();
      await tester.tap(find.text('Hawalli'));
      await tester.pump();
      expect(seen, [
        ['hawalli'],
        ['hawalli', 'capital'],
        ['capital'],
      ]);
    });

    testWidgets('web geometry (gallery filters, 350 wide): chips 44 high, 8 apart, wrapping onto rows; Capital is 111.73 wide', (tester) async {
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs));
      final capital = tester.getRect(chips().at(0));
      expect(capital.height, 44);
      expect(capital.width, closeTo(111.73, 0.2));
      final hawalli = tester.getRect(chips().at(1));
      expect(hawalli.left - capital.right, 8);
      // the web wraps the six into three rows in English (the fifth chip starts the third row)
      final rows = {for (var i = 0; i < 6; i++) tester.getRect(chips().at(i)).top.round()};
      expect(rows.length, greaterThan(1));
      for (final top in rows) {
        expect(top % 52, 0, reason: 'rows are 44 + 8 apart');
      }
    });

    testWidgets('Arabic (350 wide): the first chip sits at the right edge and is 116.86 wide, three rows of two, 148 high in all', (tester) async {
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs), lang: 'ar');
      final box = tester.getRect(find.byType(GzGovernorateFilter));
      final first = tester.getRect(chips().at(0));
      expect(box.right - first.right, 0);
      expect(first.width, closeTo(116.86, 0.6));
      expect(box.height, 148);
    });

    testWidgets('each chip carries the pin glyph at 16 dp, 8 before the name', (tester) async {
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs));
      final pins = find.byIcon(GzIcons.pin);
      expect(pins, findsNWidgets(6));
      expect(tester.getSize(pins.first), const Size(16, 16));
      final pin = tester.getRect(pins.first);
      final name = tester.getRect(find.text('Capital'));
      expect(name.left - pin.right, 8);
    });

    testWidgets('controlled values light the chip (ink border + bead, one more bead); names come in the UI language', (tester) async {
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs, values: const ['hawalli']), lang: 'ar');
      expect(find.text('حولي'), findsWidgets);
      expect(find.text('الجهراء'), findsWidgets);
      expect(find.byType(GzBeadBox), findsOneWidget);
    });

    testWidgets('only: offers just those governorates, in the list order', (tester) async {
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs, only: const ['jahra', 'capital']));
      expect(chips(), findsNWidgets(2));
      expect(tester.getRect(find.text('Capital')).left, lessThan(tester.getRect(find.text('Jahra')).left));
    });

    testWidgets('rail layout: one scrolling line', (tester) async {
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs, layout: GzChipLayout.rail));
      expect(tester.getSize(find.byType(GzGovernorateFilter)).height, 44);
    });

    testWidgets('semantics: the group is named "Governorate" (or the given label); a lit chip reads selected; 44 dp targets', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs, values: const ['capital'], label: 'Governorates · 1'));
      expect(find.bySemanticsLabel('Governorates · 1'), findsOneWidget);
      final capital = tester.getSemantics(chips().first);
      expect(capital.flagsCollection.isSelected.name, 'isTrue');
      expect(capital.label, 'Capital');
      for (var i = 0; i < 6; i++) {
        expect(tester.getSize(chips().at(i)).height, greaterThanOrEqualTo(44));
      }
      handle.dispose();
    });

    testWidgets('text scale 1.3: the chips still wrap with no overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpInputs(tester, GzGovernorateFilter(governorates: _govs), lang: 'ar');
      expect(tester.takeException(), isNull);
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
