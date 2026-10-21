import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart';

import 'inputs_harness.dart';

void main() {
  group('GzRangeSlider', () {
    Widget slider({ValueChanged<GzRange>? onChanged, ValueChanged<GzRange>? onEnd}) => GzRangeSlider(
      label: 'Budget',
      min: 0,
      max: 100,
      step: 1,
      defaultValue: (20, 60),
      onChanged: onChanged,
      onChangeEnd: onEnd,
      showCaptions: false,
    );

    Finder rail() => find.descendant(of: find.byType(GzRangeSlider), matching: find.byType(GestureDetector)).first;

    testWidgets('a drag moves the grabbed handle, snaps to the step and settles with onChangeEnd', (tester) async {
      final seen = <GzRange>[];
      final ended = <GzRange>[];
      await pumpInputs(tester, slider(onChanged: seen.add, onEnd: ended.add));
      final r = tester.getRect(rail());
      // Usable length = width - 2 x 24; value 20 sits at 24 * 0.5 + 0.2 * usable from the start.
      final usable = r.width - 48;
      final from = Offset(r.left + 12 + 0.2 * usable, r.center.dy);
      final g = await tester.startGesture(from);
      await g.moveTo(Offset(r.left + 12 + 0.4 * usable, r.center.dy));
      await g.up();
      await tester.pump();
      expect(seen.last.$1, closeTo(40, 1));
      expect(seen.last.$2, 60);
      expect(ended, hasLength(1));
    });

    testWidgets('handles never cross: dragging the minimum past the maximum stops at it', (tester) async {
      final seen = <GzRange>[];
      await pumpInputs(tester, slider(onChanged: seen.add));
      final r = tester.getRect(rail());
      final usable = r.width - 48;
      final g = await tester.startGesture(Offset(r.left + 12 + 0.2 * usable, r.center.dy));
      await g.moveTo(Offset(r.right - 4, r.center.dy));
      await g.up();
      expect(seen.last.$1, lessThanOrEqualTo(seen.last.$2));
      expect(seen.last.$1, 60);
    });

    testWidgets('Arabic mirrors the handles: the minimum sits at the start edge (right); the far left end is the maximum', (tester) async {
      GzRange? last;
      await pumpInputs(tester, slider(onChanged: (v) => last = v), lang: 'ar');
      final r = tester.getRect(rail());
      // In Arabic the thumb of 20 is right of the thumb of 60.
      final knobs = find.descendant(
        of: find.byType(GzRangeSlider),
        matching: find.byWidgetPredicate((w) => w is AnimatedContainer && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle),
      );
      final lo = tester.getCenter(knobs.at(0));
      final hi = tester.getCenter(knobs.at(1));
      expect(lo.dx, greaterThan(hi.dx));
      await tester.tapAt(Offset(r.left + 2, r.center.dy));
      await tester.pump();
      expect(last!.$2, greaterThan(95)); // the nearest handle (the maximum) went to the left end
      expect(last!.$1, 20);
    }, semanticsEnabled: true);

    testWidgets('semantics: two sliders with their values; increase and decrease actions step', (tester) async {
      final seen = <GzRange>[];
      await pumpInputs(tester, slider(onChanged: seen.add));
      final node = tester.getSemantics(find.bySemanticsLabel('Minimum').first);
      expect(node.value, '20');
      expect(node.flagsCollection.isSlider, isTrue);
      tester.semantics.increase(find.semantics.byLabel('Minimum'));
      await tester.pump();
      expect(seen.last.$1, 21);
    }, semanticsEnabled: true);
  });

  group('GzSegmentedControl', () {
    Widget seg(ValueChanged<String> onChanged) => GzSegmentedControl<String>(
      label: 'View',
      defaultValue: 'a',
      onChanged: onChanged,
      options: const [
        GzSegmentedOption(value: 'a', label: 'Availability'),
        GzSegmentedOption(value: 'b', label: 'Prices'),
        GzSegmentedOption(value: 'c', label: 'Other', disabled: true),
      ],
    );

    Finder thumb() => find.descendant(of: find.byType(GzSegmentedControl<String>), matching: find.byType(AnimatedPositionedDirectional));

    testWidgets('selecting slides the thread-bearing pill over 320 ms toward the new option', (tester) async {
      final picked = <String>[];
      await pumpInputs(tester, seg(picked.add));
      final before = tester.getTopLeft(thumb()).dx;
      await tester.tap(find.text('Prices'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      final mid = tester.getTopLeft(thumb()).dx;
      await tester.pump(const Duration(milliseconds: 400));
      final after = tester.getTopLeft(thumb()).dx;
      expect(picked, ['b']);
      expect(mid, greaterThan(before));
      expect(mid, lessThan(after));
      final optionB = tester.getCenter(find.text('Prices')).dx;
      expect(tester.getCenter(thumb()).dx, closeTo(optionB, 2));
    });

    testWidgets('in Arabic the first option is at the right and the pill slides leftwards', (tester) async {
      await pumpInputs(tester, seg((_) {}), lang: 'ar');
      expect(tester.getCenter(find.text('Availability')).dx, greaterThan(tester.getCenter(find.text('Prices')).dx));
      final before = tester.getTopLeft(thumb()).dx;
      await tester.tap(find.text('Prices'));
      await settle(tester);
      expect(tester.getTopLeft(thumb()).dx, lessThan(before));
    });

    testWidgets('a disabled option cannot be chosen; the group is a radio group with a checked item', (tester) async {
      final picked = <String>[];
      final handle = tester.ensureSemantics();
      await pumpInputs(tester, seg(picked.add));
      await tester.tap(find.text('Other'), warnIfMissed: false);
      expect(picked, isEmpty);
      final n = tester.getSemantics(find.bySemanticsLabel('Availability'));
      expect(n.flagsCollection.isChecked, isNot(Tristate.none));
      handle.dispose();
    });

    testWidgets('reduced motion jumps the pill at once', (tester) async {
      await pumpInputs(tester, seg((_) {}), reduceMotion: true);
      await tester.tap(find.text('Prices'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.getCenter(thumb()).dx, closeTo(tester.getCenter(find.text('Prices')).dx, 2));
    });
  });

  group('GzTabs, chips, toggles, stepper', () {
    testWidgets('tabs: the gold thread slides under the chosen tab', (tester) async {
      final picked = <String>[];
      await pumpInputs(
        tester,
        GzTabs<String>(
          label: 'Sections',
          onChanged: picked.add,
          items: const [
            GzTabsItem(value: 'about', label: 'One'),
            GzTabsItem(value: 'halls', label: 'Two', count: '3'),
            GzTabsItem(value: 'reviews', label: 'Three'),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final thread = find.descendant(of: find.byType(GzTabs<String>), matching: find.byType(AnimatedPositionedDirectional));
      final x0 = tester.getTopLeft(thread).dx;
      await tester.tap(find.text('Three').last);
      await settle(tester); // the thread is measured after layout (one frame), then it slides
      await settle(tester);
      expect(picked, ['reviews']);
      expect(tester.getTopLeft(thread).dx, greaterThan(x0 + 100));
      expect(tester.getSize(thread).width, closeTo(350 / 3, 1));
    });

    testWidgets('chip group: single is exclusive and deselectable on demand; multiple toggles', (tester) async {
      String? single = 'a';
      List<String> multi = ['a'];
      await pumpInputs(
        tester,
        StatefulBuilder(
          builder: (context, set) => Column(
            children: [
              GzChipGroup<String>(
                label: 'One',
                value: single,
                deselectable: true,
                onChanged: (v) => set(() => single = v),
                options: const [
                  GzChipOption(value: 'a', label: 'Alpha'),
                  GzChipOption(value: 'b', label: 'Beta'),
                ],
              ),
              GzChipGroup<String>.multiple(
                label: 'Many',
                values: multi,
                onChanged: (v) => set(() => multi = v),
                options: const [
                  GzChipOption(value: 'a', label: 'Gamma'),
                  GzChipOption(value: 'b', label: 'Delta'),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Beta').last);
      await tester.pump();
      expect(single, 'b');
      await tester.tap(find.text('Beta').last);
      await tester.pump();
      expect(single, isNull);
      await tester.tap(find.text('Delta').last);
      await tester.pump();
      expect(multi, ['a', 'b']);
      await tester.tap(find.text('Gamma').last);
      await tester.pump();
      expect(multi, ['b']);
    });

    testWidgets('toggle row: the whole row toggles, a disabled row does not and shows its reason', (tester) async {
      final seen = <bool>[];
      await pumpInputs(
        tester,
        Column(
          children: [
            GzToggleRow(title: 'Updates', description: 'When the hotel replies.', onChanged: seen.add),
            const GzToggleRow(title: 'Reminders', disabled: true, disabledReason: 'Always on.', defaultChecked: true),
          ],
        ),
      );
      await tester.tap(find.text('When the hotel replies.'));
      await tester.pump();
      expect(seen, [true]);
      expect(find.text('Always on.'), findsOneWidget);
      await tester.tap(find.text('Reminders'));
      await tester.pump();
      expect(seen, [true]);
    });

    testWidgets('stepper: steps by the package step, clamps at the limits, press and hold repeats', (tester) async {
      final seen = <int>[];
      await pumpInputs(tester, GzStepper(label: 'Guests', min: 100, max: 200, step: 50, defaultValue: 100, onChanged: seen.add));
      await tester.tap(find.bySemanticsLabel('Increase'), warnIfMissed: false);
      await tester.pump();
      expect(seen, [150]);
      final plus = find.byType(GzPressable).last;
      final g = await tester.startGesture(tester.getCenter(plus));
      await tester.pump(const Duration(milliseconds: 1000)); // 400 ms delay then a repeat every 90 ms
      await g.up();
      expect(seen.last, 200); // clamped at max
      expect(seen.where((v) => v == 200).length, greaterThanOrEqualTo(1));
    }, semanticsEnabled: true);

    testWidgets('stepper: at the minimum the minus button is disabled', (tester) async {
      await pumpInputs(tester, const GzStepper(label: 'Guests', min: 100, defaultValue: 100));
      final pressables = tester.widgetList<GzPressable>(find.byType(GzPressable)).toList();
      expect(pressables.first.onPressed, isNull);
      expect(pressables.last.onPressed, isNotNull);
    });
  });
}
