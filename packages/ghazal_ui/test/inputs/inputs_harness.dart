import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/app/gz_host.dart';

/// Pumps [child] (350 wide, the gallery column) under the real host in [lang]; [reduceMotion] sets `disableAnimations`.
Future<void> pumpInputs(WidgetTester tester, Widget child, {String lang = 'en', bool reduceMotion = false, double width = 350}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width + 40, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GzHost(
      locale: Locale(lang),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Lets a bounded animation finish (never `pumpAndSettle`: the activity indicator and focus blink loop).
Future<void> settle(WidgetTester tester, [Duration d = const Duration(milliseconds: 500)]) async {
  await tester.pump(); // the frame that starts an implicit animation
  await tester.pump(d);
  await tester.pump(const Duration(milliseconds: 16));
}
