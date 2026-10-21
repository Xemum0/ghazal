import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/app/gz_host.dart';
import 'package:ghazal_ui/src/overlays/overlays.dart';

/// Pumps [child] as the home route of the real host (theme, l10n, MaterialApp, Navigator, Overlay) in [lang], on a 390 x 800 view with
/// a 47 / 34 safe area; [reduceMotion] sets `disableAnimations`; [toastHost] wraps the content in a [GzToastHost].
Future<void> pumpNav(
  WidgetTester tester,
  Widget child, {
  String lang = 'en',
  bool reduceMotion = false,
  bool toastHost = false,
  Size size = const Size(390, 800),
  double safeTop = 47,
  double safeBottom = 34,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  tester.view
    ..padding = FakeViewPadding(top: safeTop, bottom: safeBottom)
    ..viewPadding = FakeViewPadding(top: safeTop, bottom: safeBottom);
  addTearDown(tester.view.reset);
  if (reduceMotion) {
    // At the platform level so that routes (sheets, dialogs, pages) see it too, not only the home subtree.
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  Widget content = child;
  if (toastHost) content = GzToastHost(child: content);
  await tester.pumpWidget(
    GzHost(
      locale: Locale(lang),
      child: content,
    ),
  );
  await tester.pump();
}

/// The words used across the tests need the theme; this wraps a builder so a test can read `context.gz`.
Widget gzBuilder(Widget Function(BuildContext context) build) => Builder(builder: build);

/// A screen-sized box that gives a pump point for taps.
const Key kOpen = ValueKey('test:open');
