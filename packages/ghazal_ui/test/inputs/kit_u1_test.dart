// KIT-U1: icon tabs, chips (expand, glyph, muted count, one label copy), steppers (hero, label widget, compact), field alignment,
// range values below, a rich checkbox label. The geometry numbers are the web ones (`pnpm probe`: HL-TODY-02 IconTabs, CL-ONBD-05 hero
// stepper and presets, the 350 dp gallery column).
import 'dart:ui' show CheckedState;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart';

import '../shared/shared_harness.dart';
import 'inputs_harness.dart';

void main() {
  setUpAll(loadUiFonts);

  Widget tabs({GzIconTabsLabels labels = GzIconTabsLabels.selected}) => GzIconTabs<String>(
    label: 'Filters',
    labels: labels,
    items: const [
      GzIconTabItem(value: 'a', icon: GzIcons.hall, label: 'All', count: 10),
      GzIconTabItem(value: 'b', icon: GzIcons.ticket, label: 'Requests', count: 6),
      GzIconTabItem(value: 'c', icon: GzIcons.calendar, label: 'Visits', count: 1),
      GzIconTabItem(value: 'd', icon: GzIcons.star, label: 'Reviews'),
      GzIconTabItem(value: 'e', icon: GzIcons.bell, label: 'Messages'),
      GzIconTabItem(value: 'f', icon: GzIcons.flower, label: 'Calendar'),
    ],
  );

  group('GzIconTabs', () {
    for (final lang in ['en', 'ar']) {
      for (final labels in GzIconTabsLabels.values) {
        testWidgets('$lang ${labels.name}: no overflow, item 58.33 x 56, the count badge on the physical right of the glyph', (tester) async {
          await pumpInputs(tester, tabs(labels: labels), lang: lang);
          expect(tester.takeException(), isNull);
          final item = find.descendant(of: find.byType(GzIconTabs<String>), matching: find.byType(GzPressable)).first;
          final r = tester.getRect(item);
          expect(r.width, closeTo(350 / 6, 0.01));
          expect(r.height, 56);
          // The list is the 56 item plus its 1 dp baseline (web probe: 57), and the 2 dp thread sits on the item's bottom edge, above the baseline.
          expect(tester.getSize(find.byType(GzIconTabs<String>)).height, 57);
          final thread = find.descendant(of: find.byType(GzIconTabs<String>), matching: find.byType(AnimatedPositionedDirectional));
          expect(tester.getRect(thread).bottom, closeTo(r.bottom, 0.01));
          // The glyph box is 40 wide (8 + 24 + 8); the badge's right edge is the glyph box's right edge in both languages (web probe).
          final icon = tester.getRect(find.descendant(of: item, matching: find.byType(GzIcon)));
          final badge = tester.getRect(find.descendant(of: item, matching: find.byType(GzCountBadge)));
          expect(badge.right, closeTo(icon.right + GzSpace.s2, 0.01));
          expect(badge.top, closeTo(icon.top, 0.01));
          // The label row starts 4 under the glyph box (web: label y = glyph y + 24 + 4) and is 16 high.
          if (labels == GzIconTabsLabels.all) {
            final label = tester.getRect(find.descendant(of: item, matching: find.text('All')));
            expect(label.top - icon.top, closeTo(24 + 4, 0.5));
          }
        });
      }
    }

    testWidgets('choosing a tab moves the thread by one cell and never resizes the row; the label is one widget', (tester) async {
      final picked = <String>[];
      await pumpInputs(tester, GzIconTabs<String>(label: 'F', onChanged: picked.add, items: const [
        GzIconTabItem(value: 'a', icon: GzIcons.hall, label: 'One'),
        GzIconTabItem(value: 'b', icon: GzIcons.flower, label: 'Two'),
      ]));
      final before = tester.getSize(find.byType(GzIconTabs<String>));
      expect(find.text('One'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Two'));
      await settle(tester);
      expect(picked, ['b']);
      expect(tester.getSize(find.byType(GzIconTabs<String>)), before);
      expect(find.text('Two'), findsOneWidget);
    });
  });

  group('GzChip', () {
    testWidgets('the label is drawn once: find.text finds one and a tap on it toggles', (tester) async {
      final taps = <bool>[];
      await pumpInputs(tester, GzFilterChip(label: 'Weekends', selected: false, onToggle: taps.add));
      expect(find.text('Weekends'), findsOneWidget);
      await tester.tap(find.text('Weekends'));
      expect(taps, [true]);
    });

    testWidgets('selecting never changes the chip width (the heavy width is a measured minimum)', (tester) async {
      var on = false;
      late StateSetter set;
      await pumpInputs(
        tester,
        StatefulBuilder(
          builder: (context, s) {
            set = s;
            return Align(alignment: AlignmentDirectional.centerStart, child: GzChip(label: 'Weekends', selected: on, onPressed: () {}));
          },
        ),
      );
      final off = tester.getSize(find.byType(GzChip));
      final labelOff = tester.getSize(find.byType(GzSteadyLabel));
      set(() => on = true);
      await settle(tester);
      // Selected = the 12 dp bead box and its 8 dp gap, 4 dp less start padding (web .gz-chip.is-selected): +16. The label box is the same.
      expect(tester.getSize(find.byType(GzChip)).width, closeTo(off.width + 12 + GzSpace.s2 - 4, 0.01));
      expect(tester.getSize(find.byType(GzSteadyLabel)), labelOff);
    });

    for (final lang in ['en', 'ar']) {
      testWidgets('$lang expand: three tiles fill a 350 row, 111.33 x 44, selected or not', (tester) async {
        await pumpInputs(
          tester,
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: GzSpace.s2),
                Expanded(child: GzChip(label: 'Tile $i', expand: true, selected: i == 1, onPressed: () {})),
              ],
            ],
          ),
          lang: lang,
        );
        expect(tester.takeException(), isNull);
        final chips = find.byType(GzChip);
        for (var i = 0; i < 3; i++) {
          final s = tester.getSize(chips.at(i));
          expect(s.width, closeTo(111.33, 0.01), reason: 'tile $i');
          expect(s.height, 44);
        }
        // Mirroring: the first tile is at the start edge.
        final first = tester.getRect(chips.at(0));
        final last = tester.getRect(chips.at(2));
        expect(lang == 'ar' ? first.left > last.left : first.left < last.left, isTrue);
      });
    }

    testWidgets('a muted count follows the label in the secondary tone; a glyph option carries its semantic name', (tester) async {
      await pumpInputs(
        tester,
        GzChipGroup<String>(
          label: 'Areas',
          options: const [
            GzChipOption(value: 'a', label: 'Salmiya', count: '12'),
            GzChipOption(value: 'b', label: '10', icon: GzIcons.sun, semanticLabel: 'Morning 10'),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Salmiya 12'), findsOneWidget);
      expect(find.bySemanticsLabel('Morning 10'), findsOneWidget);
      // One text for the count-bearing label, not two.
      expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Salmiya')).evaluate().length, 1);
    });

    testWidgets('a label widget replaces the words; the chip stays 44 high and reads as a toggle', (tester) async {
      await pumpInputs(tester, GzChip(label: 'Glyph', semanticLabel: 'Sun', labelWidget: const SizedBox(width: 24, height: 24), selected: true, onPressed: () {}));
      expect(find.text('Glyph'), findsNothing);
      expect(tester.getSize(find.byType(GzChip)).height, 44);
      expect(find.bySemanticsLabel('Sun'), findsOneWidget);
    });
  });

  group('GzStepper variants', () {
    testWidgets('hero: 44 + 16 + 64 + 16 + 44 = 184 wide controls centred in a 64 high row, the figure at fig-xl', (tester) async {
      await pumpInputs(tester, GzStepper(variant: GzStepperVariant.hero, semanticLabel: 'Guests', defaultValue: 350, min: 100, max: 1500, step: 50));
      final row = tester.getRect(find.byType(GzStepper));
      expect(row.height, 64);
      final buttons = find.byType(GzPressable);
      final minus = tester.getRect(buttons.at(0));
      final plus = tester.getRect(buttons.at(1));
      expect(plus.right - minus.left, closeTo(184, 0.01));
      // Web (a zero-width hidden title and its 16 gap before the controls): the 200 wide group is centred, so the controls start 91 from
      // the start edge and end 75 from the end edge (RTL probe: 95..279 in a 350 row at x 20).
      expect(minus.left - row.left, closeTo(91, 0.01));
      expect(row.right - plus.right, closeTo(75, 0.01));
      expect(find.textContaining('350'), findsOneWidget);
      expect(tester.getSize(find.ancestor(of: find.textContaining('350'), matching: find.byType(SizedBox)).first).width, 64);
    });

    testWidgets('hero in Arabic: the minus button is at the start (right), the group keeps its offset toward the end', (tester) async {
      await pumpInputs(tester, GzStepper(variant: GzStepperVariant.hero, semanticLabel: 'Guests', defaultValue: 350, min: 100, max: 1500, step: 50), lang: 'ar');
      final buttons = find.byType(GzPressable);
      expect(tester.getRect(buttons.at(0)).left > tester.getRect(buttons.at(1)).left, isTrue);
      final row = tester.getRect(find.byType(GzStepper));
      expect(row.right - tester.getRect(buttons.at(0)).right, closeTo(91, 0.01));
      expect(tester.getRect(buttons.at(1)).left - row.left, closeTo(75, 0.01));
    });

    testWidgets('a label widget names the group; compact is 44 high; press and hold still steps', (tester) async {
      var v = 350;
      await pumpInputs(
        tester,
        GzStepper(labelWidget: const SizedBox(width: 24, height: 24), semanticLabel: 'Guests', value: v, min: 0, max: 1000, step: 50, compact: true, onChanged: (n) => v = n),
      );
      expect(tester.getSize(find.byType(GzStepper)).height, 44);
      expect(find.bySemanticsLabel(RegExp('^Guests')), findsOneWidget);
      await tester.tap(find.byType(GzPressable).last);
      expect(v, 400);
    });

    testWidgets('compact without a title hugs its controls: 44 + 4 + 56 + 4 + 44 = 148 x 44', (tester) async {
      await pumpInputs(tester, Align(alignment: AlignmentDirectional.centerStart, child: GzStepper(compact: true, defaultValue: 2, max: 5)));
      final s = tester.getSize(find.byType(GzStepper));
      expect(s.height, 44);
      expect(s.width, closeTo(44 + 4 + 56 + 4 + 44, 0.01));
    });
  });

  group('fields', () {
    TextAlign alignOf(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText).first).textAlign;

    testWidgets('phone: the kit puts the digits at the screen start (the end of an LTR line in Arabic); chip keeps them against +965', (tester) async {
      await pumpInputs(tester, const GzPhoneField(defaultValue: '50001234'), lang: 'ar');
      expect(alignOf(tester), TextAlign.end);
      await pumpInputs(tester, const GzPhoneField(defaultValue: '50001234', valueAlign: GzPhoneValueAlign.chip), lang: 'ar');
      expect(alignOf(tester), TextAlign.start);
      await pumpInputs(tester, const GzPhoneField(defaultValue: '50001234'), lang: 'en');
      expect(alignOf(tester), TextAlign.start);
    });

    testWidgets('text field: textAlign overrides the LTR island rule', (tester) async {
      await pumpInputs(tester, const GzTextField(defaultValue: 'a@b.example', dir: GzFieldDir.ltr), lang: 'ar');
      expect(alignOf(tester), TextAlign.end);
      await pumpInputs(tester, const GzTextField(defaultValue: 'a@b.example', dir: GzFieldDir.ltr, textAlign: TextAlign.start), lang: 'ar');
      expect(alignOf(tester), TextAlign.start);
    });

    testWidgets('range: valuesAt below puts the value labels under the rail; the default keeps them above', (tester) async {
      Widget range(GzRangeValues at) => GzRangeSlider(min: 0, max: 100, label: 'B', defaultValue: (20, 70), showCaptions: false, valuesAt: at);
      await pumpInputs(tester, range(GzRangeValues.above));
      final railAbove = tester.getRect(find.descendant(of: find.byType(GzRangeSlider), matching: find.byType(GestureDetector)).first);
      final valueAbove = tester.getRect(find.textContaining('20'));
      expect(valueAbove.bottom <= railAbove.top, isTrue);
      await pumpInputs(tester, range(GzRangeValues.below));
      final railBelow = tester.getRect(find.descendant(of: find.byType(GzRangeSlider), matching: find.byType(GestureDetector)).first);
      final valueBelow = tester.getRect(find.textContaining('20'));
      expect(valueBelow.top >= railBelow.bottom, isTrue);
    });

    testWidgets('checkbox: a label widget is the whole row target; the accessible name is the label', (tester) async {
      final seen = <bool>[];
      await pumpInputs(
        tester,
        GzCheckbox(label: 'I agree', labelWidget: const Text.rich(TextSpan(text: 'I agree to the terms')), onChanged: seen.add),
      );
      await tester.tap(find.text('I agree to the terms'));
      expect(seen, [true]);
      final node = tester.getSemantics(find.byType(GzCheckbox));
      expect(node.label, 'I agree');
      expect(node.flagsCollection.isChecked, CheckedState.isFalse);
    });
  });

  group('text scale 1.3 and reduced motion', () {
    Widget scaled(Widget child) => Builder(
      builder: (context) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)), child: child),
    );

    for (final lang in ['en', 'ar']) {
      testWidgets('$lang at 1.3: icon tabs with every label, tiles with long words and the hero stepper lay out without errors', (tester) async {
        await pumpInputs(
          tester,
          scaled(
            Column(
              children: [
                tabs(labels: GzIconTabsLabels.all),
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: GzSpace.s2),
                      Expanded(child: GzChip(label: lang == 'ar' ? 'الصالة الكبرى' : 'The grand hall', expand: true, selected: i == 0, onPressed: () {})),
                    ],
                  ],
                ),
                GzStepper(variant: GzStepperVariant.hero, semanticLabel: 'Guests', defaultValue: 1500, min: 100, max: 1500, step: 50),
              ],
            ),
          ),
          lang: lang,
        );
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 3; i++) {
          expect(tester.getSize(find.byType(GzChip).at(i)).width, closeTo(111.33, 0.01));
        }
      });
    }

    testWidgets('reduced motion: choosing an icon tab and a chip jumps at once (no pending animation frames)', (tester) async {
      await pumpInputs(tester, Column(children: [tabs(), GzChip(label: 'Weekends', selected: false, onPressed: () {})]), reduceMotion: true);
      await tester.tap(find.bySemanticsLabel('Requests'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
