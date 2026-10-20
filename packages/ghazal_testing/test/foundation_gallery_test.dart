import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_testing/ghazal_testing.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The web gallery page sits in `.gz-gallery` (24 dp top padding, 20 dp inline); `top` and `inline` reproduce that shell so a chunk
/// lines up with the web render pixel for pixel.
///
/// Renders the foundation gallery in chunks (`build/foundation/<chunk>.<lang>.png`, 390 wide at DPR 2, no device chrome) so the
/// icon sheet and the illustration contact sheet can be read, and compared with the web gallery renders (tools/parity).
final _out = Directory('build/foundation');

Future<void> _settleAssets(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(seconds: 1));
}

Future<File> _shoot(WidgetTester tester, String name, String lang, Widget gallery, {double top = 24, double inline = 0}) async {
  const w = 390.0;
  const dpr = 2.0;
  final locale = Locale(lang);
  final key = GlobalKey();
  // flutter_test draws every shadow as a hard solid shape unless this is off (on by default); it must be off while the frame is
  // painted, and is restored before the invariant check at the end of the test.
  debugDisableShadows = false;
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = const Size(w * dpr, 15000 * dpr);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(w, 15000)),
        child: GzTheme(
          locale: locale,
          child: DefaultTextStyle(
            style: GzType.style(locale, GzTextRole.body),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: RepaintBoundary(
                key: key,
                child: SizedBox(width: w, child: ColoredBox(color: GzColors.light.surfaceCanvas, child: Padding(padding: EdgeInsetsDirectional.only(top: top, start: inline, end: inline), child: gallery))),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await _settleAssets(tester);
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  late List<int> bytes;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: dpr);
    bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    image.dispose();
  });
  debugDisableShadows = true;
  _out.createSync(recursive: true);
  final file = File('${_out.path}/$name.$lang.png')..writeAsBytesSync(bytes);
  return file;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  for (final lang in ['ar', 'en']) {
    group('foundation gallery ($lang)', () {
      testWidgets('colour', (tester) async {
        final f = await _shoot(tester, 'colour', lang, const GzFoundationGallery(sections: [GzFoundationSection.colour]));
        expect(f.lengthSync(), greaterThan(20000));
      });
      testWidgets('roles', (tester) async {
        await _shoot(tester, 'roles', lang, const GzFoundationGallery(sections: [GzFoundationSection.roles], header: false), top: 0);
      });
      testWidgets('type', (tester) async {
        await _shoot(tester, 'type', lang, const GzFoundationGallery(sections: [GzFoundationSection.type], header: false), top: 0);
      });
      testWidgets('metrics', (tester) async {
        await _shoot(tester, 'metrics', lang, const GzFoundationGallery(sections: [GzFoundationSection.metrics, GzFoundationSection.motion], header: false), top: 0);
      });
      testWidgets('icons (every glyph, name under each)', (tester) async {
        final f = await _shoot(tester, 'icons', lang, const GzFoundationGallery(sections: [GzFoundationSection.icons], header: false));
        expect(GzIcons.byName.length, 179);
        expect(f.lengthSync(), greaterThan(50000));
      });
      testWidgets('illustrations (all 60 at lg, as the web gallery only=spots,...)', (tester) async {
        final f = await _shoot(tester, 'illustrations', lang, const GzFoundationGallery(sections: [GzFoundationSection.illustrations], header: false), top: 40, inline: 20);
        expect(GzIllustrationName.values.length, 60);
        expect(f.lengthSync(), greaterThan(100000));
      });
      testWidgets('illustrations, compositions only (compare with the web only=onboarding,empty,success,partner)', (tester) async {
        final scenes = [for (final n in GzIllustrationName.values) if (n.kind == GzIllustrationKind.scene) n];
        expect(scenes.length, 21);
        await _shoot(tester, 'illustrations-scenes', lang, GzFoundationGallery(sections: const [GzFoundationSection.illustrations], header: false, illustrations: scenes), top: 40, inline: 20);
      });
    });
  }
}
