import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

Widget _host(Widget child, {bool reduced = false}) => Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: GzTheme(locale: const Locale('en'), child: Center(child: child)),
      ),
    );

double _scale(WidgetTester tester) => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

Color? _fill(WidgetTester tester) {
  final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
  return (box.decoration as BoxDecoration?)?.color;
}

void main() {
  const idle = GzColors.light;
  Widget button({VoidCallback? onPressed, GzHapticKind haptic = GzHapticKind.light}) => GzPressable(
        onPressed: onPressed,
        color: idle.actionPrimaryBg,
        pressedColor: idle.actionPrimaryBgPressed,
        disabledColor: idle.actionPrimaryBgDisabled,
        haptic: haptic,
        child: const SizedBox(width: 20, height: 20),
      );

  testWidgets('press scales to 0.985 and steps the tone in 120 ms, then returns', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(button(onPressed: () => taps++)));
    expect(_scale(tester), 1);
    expect(_fill(tester), idle.actionPrimaryBg);
    final g = await tester.startGesture(tester.getCenter(find.byType(GzPressable)));
    await tester.pump();
    expect(_scale(tester), GzMotion.scalePress);
    expect(_fill(tester), idle.actionPrimaryBgPressed);
    await tester.pump(GzMotion.durationFast);
    final box = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(box.duration, GzMotion.durationFast);
    expect(box.curve, GzMotion.easeStandard);
    await g.up();
    await tester.pump();
    expect(taps, 1);
    expect(_scale(tester), 1);
    expect(_fill(tester), idle.actionPrimaryBg);
    await tester.pumpAndSettle();
  });

  testWidgets('the target is at least 44 x 44 even for a 20 x 20 child', (tester) async {
    await tester.pumpWidget(_host(button(onPressed: () {})));
    final size = tester.getSize(find.byType(GzPressable));
    expect(size.width, greaterThanOrEqualTo(GzSize.touchMin));
    expect(size.height, greaterThanOrEqualTo(GzSize.touchMin));
  });

  testWidgets('reduced motion removes the scale and keeps the tone step', (tester) async {
    await tester.pumpWidget(_host(button(onPressed: () {}), reduced: true));
    final g = await tester.startGesture(tester.getCenter(find.byType(GzPressable)));
    await tester.pump();
    expect(_scale(tester), 1);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration, GzMotion.durationInstant);
    expect(_fill(tester), idle.actionPrimaryBgPressed);
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('disabled: no tap, no feedback, disabled fill, Semantics enabled false', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(button()));
    await tester.tap(find.byType(GzPressable));
    await tester.pump();
    expect(_scale(tester), 1);
    expect(_fill(tester), idle.actionPrimaryBgDisabled);
    final node = tester.getSemantics(find.byType(GzPressable));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('enabled is a labelled button, fires the haptic hook once per tap', (tester) async {
    final handle = tester.ensureSemantics();
    final fired = <GzHapticKind>[];
    GzHaptics.handler = fired.add;
    addTearDown(() => GzHaptics.handler = (_) {});
    await tester.pumpWidget(_host(GzPressable(onPressed: () {}, semanticLabel: 'Save', child: const SizedBox(width: 60, height: 60))));
    await tester.tap(find.byType(GzPressable));
    await tester.pumpAndSettle();
    expect(fired, [GzHapticKind.light]);
    final node = tester.getSemantics(find.byType(GzPressable));
    expect(node.label, 'Save');
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isEnabled, Tristate.isTrue);
    handle.dispose();
  });

  testWidgets('keyboard focus draws the 2 dp ring, Enter activates', (tester) async {
    var taps = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(_host(GzPressable(
      onPressed: () => taps++,
      focusNode: node,
      borderRadius: GzRadius.smAll,
      child: const SizedBox(width: 60, height: 60),
    )));
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    node.requestFocus();
    await tester.pump();
    final ring = find.byWidgetPredicate((w) => w is DecoratedBox && (w.decoration is BoxDecoration) && ((w.decoration as BoxDecoration).border?.top.width == GzStroke.focus));
    expect(ring, findsOneWidget);
    expect((tester.widget<DecoratedBox>(ring).decoration as BoxDecoration).border?.top.color, GzColors.light.focusRing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('GzFadeReveal fades and settles from 1.035; reduced motion keeps only the fade', (tester) async {
    Widget reveal(bool reduced) => _host(const GzFadeReveal(child: SizedBox(width: 40, height: 40)), reduced: reduced);
    await tester.pumpWidget(reveal(false));
    await tester.pump();
    double scaleNow() => tester.widget<Transform>(find.descendant(of: find.byType(GzFadeReveal), matching: find.byType(Transform))).transform.getMaxScaleOnAxis();
    expect(scaleNow(), greaterThan(1.0));
    expect(scaleNow(), lessThanOrEqualTo(GzMotion.scaleRevealFrom));
    await tester.pump(GzMotion.durationExpressive);
    expect(scaleNow(), closeTo(1.0, 1e-6));
    expect(tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value, closeTo(1.0, 1e-6));

    await tester.pumpWidget(reveal(true));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(reveal(true));
    await tester.pump(const Duration(milliseconds: 30));
    expect(scaleNow(), 1.0);
    await tester.pump(GzMotion.durationFast);
    expect(tester.widget<FadeTransition>(find.byType(FadeTransition)).opacity.value, closeTo(1.0, 1e-6));
  });

  test('GzReducedMotion helpers', () {
    expect(GzMotion.durationInstant, const Duration(milliseconds: 1));
  });
}
