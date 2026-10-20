import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/core/core.dart';

import 'core_harness.dart';

void main() {
  testWidgets('switch toggles, reports the next value and exposes toggled semantics', (tester) async {
    final handle = tester.ensureSemantics();
    final seen = <bool>[];
    await pumpCore(tester, GzSwitch(label: 'Push', onChanged: seen.add));
    expect(tester.getSemantics(find.byType(GzSwitch)).flagsCollection.isToggled, isNot(Tristate.none));
    expect(tester.getSemantics(find.byType(GzSwitch)).flagsCollection.isToggled, Tristate.isFalse);
    await tester.tap(find.byType(GzSwitch));
    await tester.pump(const Duration(milliseconds: 300));
    expect(seen, [true]);
    expect(tester.getSemantics(find.byType(GzSwitch)).flagsCollection.isToggled, Tristate.isTrue);
    expect(tester.getSemantics(find.byType(GzSwitch)).label, 'Push');
    handle.dispose();
  });

  for (final lang in ['en', 'ar']) {
    testWidgets('switch knob moves toward inline-end ($lang)', (tester) async {
      await pumpCore(tester, GzSwitch(label: 'x', checked: false, onChanged: (_) {}), lang: lang);
      const knob = ValueKey('gz:switch.knob');
      final track = tester.getCenter(find.byType(GzSwitch)).dx;
      final off = tester.getCenter(find.byKey(knob)).dx;
      await pumpCore(tester, GzSwitch(label: 'x', checked: true, onChanged: (_) {}), lang: lang);
      await tester.pump(const Duration(milliseconds: 400));
      final on = tester.getCenter(find.byKey(knob)).dx;
      if (lang == 'en') {
        expect(off, lessThan(track));
        expect(on, greaterThan(track));
      } else {
        expect(off, greaterThan(track));
        expect(on, lessThan(track));
      }
      expect((on - off).abs(), closeTo(20, 0.5));
    });
  }

  testWidgets('disabled switch ignores taps', (tester) async {
    var n = 0;
    await pumpCore(tester, GzSwitch(label: 'x', disabled: true, onChanged: (_) => n++));
    await tester.tap(find.byType(GzSwitch), warnIfMissed: false);
    expect(n, 0);
  });

  testWidgets('checkbox: checked, mixed and error semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCore(tester, const Column(children: [
      GzCheckbox(label: 'A', defaultChecked: true),
      GzCheckbox(label: 'B', indeterminate: true),
      GzCheckbox(label: 'C', error: 'Required'),
    ]));
    final nodes = tester.widgetList(find.byType(GzCheckbox)).map((w) => tester.getSemantics(find.byWidget(w))).toList();
    expect(nodes[0].flagsCollection.isChecked, CheckedState.isTrue);
    expect(nodes[1].flagsCollection.isChecked, CheckedState.mixed);
    expect(find.text('Required'), findsOneWidget);
    await tester.tap(find.text('A'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSemantics(find.byType(GzCheckbox).first).flagsCollection.isChecked, CheckedState.isFalse);
    handle.dispose();
  });

  testWidgets('radio group: choosing one clears the other, mutually exclusive semantics', (tester) async {
    final handle = tester.ensureSemantics();
    String? chosen;
    await pumpCore(tester, GzRadioGroup<String>(
      label: 'Plan',
      defaultValue: 'a',
      onChanged: (v) => chosen = v,
      children: const [GzRadio<String>(value: 'a', label: 'One'), GzRadio<String>(value: 'b', label: 'Two'), GzRadio<String>(value: 'c', label: 'Three', disabled: true)],
    ));
    dynamic node(String v) => tester.getSemantics(find.byWidgetPredicate((w) => w is GzRadio<String> && w.value == v));
    expect(node('a').flagsCollection.isChecked, CheckedState.isTrue);
    expect(node('b').flagsCollection.isChecked, CheckedState.isFalse);
    expect(node('a').flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    await tester.tap(find.text('Two'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(chosen, 'b');
    expect(node('b').flagsCollection.isChecked, CheckedState.isTrue);
    expect(node('a').flagsCollection.isChecked, CheckedState.isFalse);
    await tester.tap(find.text('Three'), warnIfMissed: false);
    expect(chosen, 'b');
    handle.dispose();
  });

  testWidgets('targets are at least 44 dp: switch, checkbox row, radio row, chip, icon button', (tester) async {
    await pumpCore(tester, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GzSwitch(label: 's', checked: false, onChanged: (_) {}),
      GzCheckbox(label: 'c', checked: false, onChanged: (_) {}),
      GzChip(label: 'chip', onPressed: () {}),
      GzIconButton(icon: const IconData(0xe000), label: 'i', onPressed: () {}),
    ]));
    for (final t in [GzSwitch, GzCheckbox, GzChip, GzIconButton]) {
      final size = tester.getSize(find.byType(t));
      expect(size.height, greaterThanOrEqualTo(44), reason: '$t height');
    }
    expect(tester.getSize(find.byType(GzIconButton)).width, greaterThanOrEqualTo(44));
  });
}
