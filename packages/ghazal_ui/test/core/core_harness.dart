import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/app/gz_host.dart';

/// Pumps [child] under the real host (theme, l10n, MaterialApp) in [lang]; [reduceMotion] sets `disableAnimations`.
Future<void> pumpCore(WidgetTester tester, Widget child, {String lang = 'en', bool reduceMotion = false, Size size = const Size(390, 800)}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GzHost(
      locale: Locale(lang),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: Align(alignment: AlignmentDirectional.topStart, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}
