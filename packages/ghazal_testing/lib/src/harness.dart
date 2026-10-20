import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'device_chrome.dart';

/// The prototype's fixed clock (2026-11-12 16:00 Asia/Kuwait): countdowns and the status-bar time match the design.
final DateTime gzFixedClock = DateTime.parse('2026-11-12T16:00:00+03:00');

/// Renders any app or screen headless at a prototype device size and writes PNGs at the prototype's scale.
///
/// Device model (identical to `design/src/shell/device`): 390x844 logical, DPR 2 (so a shot is 780x1688), safe area 47 top and
/// 34 bottom, a drawn status bar (4:00) and a drawn home indicator above the app. Parity tooling ignores those two bands.
abstract final class GzHarness {
  /// Key of the root repaint boundary that [shoot] captures.
  static final GlobalKey rootKey = GlobalKey(debugLabel: 'gz-harness-root');

  /// Sets the test view up and pumps the app. Provide [app] (a full widget, for example `ClientApp(router: r)`) or a [router]
  /// (wrapped in the shared `GzApp`). [overrides] are Riverpod overrides; `localeProvider` is always overridden with [locale].
  static Future<void> pump(
    WidgetTester tester, {
    Widget? app,
    RouterConfig<Object>? router,
    Locale locale = const Locale('ar'),
    double width = 390,
    double height = 844,
    double dpr = 2,
    double safeTop = 47,
    double safeBottom = 34,
    double textScale = 1,
    GzChromeTone chromeTone = GzChromeTone.dark,
    List<Override> overrides = const <Override>[],
    DateTime? fixedClock,
    bool settle = true,
  }) async {
    assert(app != null || router != null, 'GzHarness.pump needs an app or a router');
    final view = tester.view;
    view
      ..devicePixelRatio = dpr
      ..physicalSize = Size(width * dpr, height * dpr)
      ..padding = FakeViewPadding(top: safeTop * dpr, bottom: safeBottom * dpr)
      ..viewPadding = FakeViewPadding(top: safeTop * dpr, bottom: safeBottom * dpr);
    addTearDown(view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final clock = (fixedClock ?? gzFixedClock).toUtc().add(const Duration(hours: 3));
    final hour = clock.hour % 12 == 0 ? 12 : clock.hour % 12;
    final time = '$hour:${clock.minute.toString().padLeft(2, '0')}';

    final content = app ?? GzApp(routerConfig: router!, locale: locale);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[localeProvider.overrideWith(() => LocaleNotifier(locale)), ...overrides],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: rootKey,
            child: Stack(
              children: [
                Positioned.fill(child: content),
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  child: GzHarnessStatusBar(time: time, tone: chromeTone, height: safeTop),
                ),
                PositionedDirectional(
                  bottom: 0,
                  start: 0,
                  end: 0,
                  child: GzHarnessHomeIndicator(tone: chromeTone, height: safeBottom),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (settle) await GzHarness.settle(tester);
  }

  /// Bounded settle (never an unbounded `pumpAndSettle`): lets assets and images decode in real time, then pumps at most
  /// [max] of fake time and stops early once no frame is scheduled. Looping animations (skeleton shimmer) simply run to the bound.
  static Future<void> settle(WidgetTester tester, {Duration max = const Duration(seconds: 4)}) async {
    const step = Duration(milliseconds: 100);
    var elapsed = Duration.zero;
    for (var round = 0; round < 3; round++) {
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          final image = element.widget as Image;
          await precacheImage(image.image, element);
        }
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pump();
      while (elapsed < max && tester.binding.hasScheduledFrame) {
        await tester.pump(step);
        elapsed += step;
      }
      if (elapsed >= max) break;
    }
    await tester.pump(const Duration(milliseconds: 16));
  }

  /// Writes the PNG of the root repaint boundary at the view's device pixel ratio (390x844 at DPR 2 gives 780x1688).
  static Future<File> shoot(WidgetTester tester, String path) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(rootKey));
    final dpr = tester.view.devicePixelRatio;
    late final List<int> bytes;
    // flutter_test paints every shadow as a hard solid shape unless this flag is off; it must be off while the captured frame is
    // painted (so elevation looks like the real app) and is restored right after, because the test binding checks it at test end.
    debugDisableShadows = false;
    try {
      boundary.markNeedsPaint();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.runAsync(() async {
        final ui.Image image = await boundary.toImage(pixelRatio: dpr);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        bytes = data!.buffer.asUint8List();
        image.dispose();
      });
    } finally {
      debugDisableShadows = true;
    }
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    return file;
  }
}
