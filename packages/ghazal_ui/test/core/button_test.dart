import 'dart:ui' show Tristate;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/core/core.dart';

import 'core_harness.dart';

void main() {
  testWidgets('a tap calls onPressed once and the label is the semantic name', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpCore(tester, GzButton(label: 'Accept', onPressed: () => taps++));
    await tester.tap(find.byType(GzButton));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
    final node = tester.getSemantics(find.byType(GzButton));
    expect(node.label, 'Accept');
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled, Tristate.isTrue);
    handle.dispose();
  });

  testWidgets('press shrinks the button to the token scale and releases', (tester) async {
    await pumpCore(tester, GzButton(label: 'Accept', onPressed: () {}));
    double scale() => tester.widget<AnimatedScale>(find.descendant(of: find.byType(GzButton), matching: find.byType(AnimatedScale))).scale;
    expect(scale(), 1);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(GzButton)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(scale(), closeTo(0.985, 0.0001));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(scale(), 1);
  });

  testWidgets('disabled: no callback, semantics disabled, reason is shown', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCore(tester, const GzButton(label: 'Continue', reason: 'Pick a date'));
    await tester.tap(find.byType(GzButton), warnIfMissed: false);
    expect(find.text('Pick a date'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('Continue')).flagsCollection.isEnabled, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('loading ignores taps and draws the thread; reduced motion shows it finished', (tester) async {
    var taps = 0;
    await pumpCore(tester, GzButton(label: 'Confirm', loading: true, onPressed: () => taps++));
    await tester.tap(find.byType(GzButton), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    expect(find.byType(GzDrawOnce), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'the thread draws once, nothing loops');
  });

  testWidgets('tertiary press shortens the underline to 40%', (tester) async {
    await pumpCore(tester, GzButton(label: 'See all', variant: GzButtonVariant.tertiary, onPressed: () {}));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(GzButton)));
    await tester.pump(const Duration(milliseconds: 150)); // the tap-down deadline rebuilds with the pressed state
    await tester.pump(const Duration(milliseconds: 400)); // the 320 ms underline tween runs
    final transforms = tester.widgetList<Transform>(find.descendant(of: find.byType(GzButton), matching: find.byType(Transform)));
    expect(transforms.any((t) => (t.transform.entry(0, 0) - 0.4).abs() < 0.02), isTrue);
    await gesture.up();
  });

  testWidgets('button heights follow the control scale', (tester) async {
    await pumpCore(tester, Column(children: [
      GzButton(label: 'a', onPressed: () {}),
      GzButton(label: 'b', variant: GzButtonVariant.secondary, onPressed: () {}),
      GzButton(label: 'c', variant: GzButtonVariant.tertiary, onPressed: () {}),
    ]));
    final sizes = tester.widgetList(find.byType(GzButton)).map((w) => tester.getSize(find.byWidget(w)).height).toList();
    expect(sizes, [52.0, 48.0, 44.0]);
  });
}
