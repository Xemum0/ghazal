import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/app/gz_host.dart';
import 'package:ghazal_ui/src/foundation.dart';

import '../fonts.dart';

/// One section of a design-system gallery page. The [title] must equal the web gallery's `data-gz-section` title (or its heading)
/// so `node tools/parity/gallery-ref.mjs` references pair with the Flutter render by file name (`NN-<slug>.<lang>.png`).
class GzGallerySection {
  const GzGallerySection(this.title, this.builder, {this.width = 350});

  final String title;
  final WidgetBuilder builder;

  /// Logical width of the section (the web gallery content column: 390 minus 2 x 20 gutter).
  final double width;

  /// The same slug rule as tools/parity/gallery-ref.mjs.
  String get slug {
    final s = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9؀-ۿ]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    final cut = s.length > 48 ? s.substring(0, 48) : s;
    return cut.isEmpty ? 'section' : cut;
  }
}

/// Registers one test per (language, section) that renders the section headless with the REAL fonts and writes
/// `build/gallery/<page>/<NN>-<slug>.<lang>.png` (350 wide at DPR 2 = 700 px, the size of the web references).
///
/// ```dart
/// void main() => gzGalleryShots(page: 'core', sections: () => [GzGallerySection('Button', (_) => const ButtonSamples())]);
/// ```
/// Compare with `node tools/parity/parity.mjs --gallery core`. Only import `package:ghazal_ui/src/foundation.dart` and your own
/// group barrel in the test file: never `ghazal_ui.dart`, so another group's compile error cannot stop you.
void gzGalleryShots({
  required String page,
  required List<GzGallerySection> Function() sections,
  List<String> langs = const ['ar', 'en'],
  List<LocalizationsDelegate<dynamic>> extraDelegates = const [],
  Widget Function(Widget child)? wrap,
}) {
  setUpAll(loadAppFonts);
  final all = sections();
  final out = Directory('build/gallery/$page');
  for (final lang in langs) {
    group('$page gallery ($lang)', () {
      for (var i = 0; i < all.length; i++) {
        final section = all[i];
        final n = (i + 1).toString().padLeft(2, '0');
        testWidgets('$n ${section.title}', (tester) async {
          const dpr = 2.0;
          final key = GlobalKey();
          tester.view
            ..devicePixelRatio = dpr
            ..physicalSize = Size(section.width * dpr, 30000 * dpr);
          addTearDown(tester.view.reset);
          final canvas = GzColors.light.surfaceCanvas;
          // Unbounded height (like the web page): a section sizes to its content, a Column(max) does not stretch to the view.
          Widget content = UnconstrainedBox(
            alignment: AlignmentDirectional.topStart,
            constrainedAxis: Axis.horizontal,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: section.width,
                child: ColoredBox(color: canvas, child: Builder(builder: section.builder)),
              ),
            ),
          );
          if (wrap != null) content = wrap(content);
          await tester.pumpWidget(GzHost(locale: Locale(lang), extraLocalizationsDelegates: extraDelegates, child: content));
          await _settle(tester);
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
          late List<int> bytes;
          debugDisableShadows = false; // real elevation in the capture (flutter_test would draw hard shapes); restored below
          try {
            boundary.markNeedsPaint();
            await tester.pump(const Duration(milliseconds: 16));
            await tester.runAsync(() async {
              final ui.Image image = await boundary.toImage(pixelRatio: dpr);
              bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
              image.dispose();
            });
          } finally {
            debugDisableShadows = true;
          }
          out.createSync(recursive: true);
          File('${out.path}/$n-${section.slug}.$lang.png').writeAsBytesSync(bytes);
          expect(bytes.length, greaterThan(500));
        });
      }
    });
  }
}

Future<void> _settle(WidgetTester tester) async {
  // Decode images and let entrance animations finish, bounded (looping animations simply run to the bound).
  for (var round = 0; round < 3; round++) {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
      await Future<void>.delayed(const Duration(milliseconds: 60));
    });
    await tester.pump();
    var elapsed = Duration.zero;
    while (elapsed < const Duration(seconds: 2) && tester.binding.hasScheduledFrame) {
      await tester.pump(const Duration(milliseconds: 100));
      elapsed += const Duration(milliseconds: 100);
    }
  }
  await tester.pump(const Duration(milliseconds: 16));
}
