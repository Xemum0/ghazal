import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/ghazal_testing.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

({int w, int h}) _pngSize(File f) {
  final b = f.readAsBytesSync();
  int u32(int o) => (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
  return (w: u32(16), h: u32(20));
}

void main() {
  setUpAll(() async {
    final families = await loadAppFonts();
    expect(families, containsAll(['packages/ghazal_ui/ElMessiri', 'packages/ghazal_ui/Manrope', 'packages/ghazal_ui/Almarai']));
  });

  Widget app(Locale l) => Localizations(
        locale: l,
        delegates: gzLocalizationsDelegates,
        child: const GzStubScreen(id: 'TEST-01', titleEn: 'Title', titleAr: 'العنوان', kind: 'screen'),
      );

  for (final lang in ['ar', 'en']) {
    testWidgets('shoot writes a 780x1688 PNG ($lang)', (tester) async {
      await GzHarness.pump(tester, app: app(Locale(lang)), locale: Locale(lang));
      final file = await GzHarness.shoot(tester, '${Directory.systemTemp.path}/gz_harness_$lang.png');
      final size = _pngSize(file);
      expect((size.w, size.h), (780, 1688));
      expect(file.lengthSync(), greaterThan(5000));
      file.deleteSync();
    });
  }

  testWidgets('width and scale are honoured (360 at DPR 3 gives 1080x2532)', (tester) async {
    await GzHarness.pump(tester, app: app(const Locale('en')), locale: const Locale('en'), width: 360, dpr: 3);
    final file = await GzHarness.shoot(tester, '${Directory.systemTemp.path}/gz_harness_360.png');
    expect(_pngSize(file), (w: 1080, h: 2532));
    file.deleteSync();
  });
}
