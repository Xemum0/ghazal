import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

Widget _host(Widget child, {bool rtl = false}) => Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: GzTheme(locale: Locale(rtl ? 'ar' : 'en'), child: Center(child: child)),
      ),
    );

bool _flipped(WidgetTester tester) => tester.widgetList<Transform>(find.byType(Transform)).any((t) => t.transform.storage[0] == -1);

void main() {
  test('the icon registry has every glyph, codepoints are unique and in the private use area', () {
    expect(GzIcons.byName.length, 179);
    final points = GzIcons.byName.values.map((i) => i.codePoint).toSet();
    expect(points.length, 179);
    expect(points.every((p) => p >= 0xE000 && p <= 0xF8FF), isTrue);
    expect(GzIcons.back.fontFamily, 'GzIcons');
    expect(GzIcons.back.fontPackage, 'ghazal_ui');
    // the ADR 0014 set: directional glyphs mirror, everything else never
    expect(GzIcons.mirrorInRtl, containsAll(['back', 'forward', 'chevron-left', 'arrow-right', 'send', 'undo']));
    expect(GzIcons.mirrorInRtl.contains('search'), isFalse);
    expect(GzIcons.mirrorInRtl.contains('heart'), isFalse);
    for (final n in GzIcons.mirrorInRtl) {
      expect(GzIcons.byName[n]!.matchTextDirection, isTrue, reason: n);
    }
    expect(GzIcons.byName['check']!.matchTextDirection, isFalse);
  });

  testWidgets('GzIcon sizes follow the four icon tokens and the tone picks the icon colour role', (tester) async {
    await tester.pumpWidget(_host(const GzIcon(GzIcons.search, size: GzIconSize.lg, tone: GzIconTone.accent)));
    expect(tester.getSize(find.byType(GzIcon)), const Size(32, 32));
    expect(tester.widget<Icon>(find.byType(Icon)).color, GzColors.light.iconAccent);
    await tester.pumpWidget(_host(const GzIcon.named('heart', size: GzIconSize.xs)));
    expect(tester.getSize(find.byType(GzIcon)), const Size(16, 16));
    expect([GzIconSize.xs.dp, GzIconSize.sm.dp, GzIconSize.md.dp, GzIconSize.lg.dp], [16, 20, 24, 32]);
  });

  testWidgets('directional icons flip in RTL only; others never; mirror overrides', (tester) async {
    await tester.pumpWidget(_host(const GzIcon(GzIcons.back)));
    expect(_flipped(tester), isFalse);
    await tester.pumpWidget(_host(const GzIcon(GzIcons.back), rtl: true));
    expect(_flipped(tester), isTrue);
    await tester.pumpWidget(_host(const GzIcon(GzIcons.search), rtl: true));
    expect(_flipped(tester), isFalse);
    await tester.pumpWidget(_host(const GzIcon(GzIcons.back, mirror: false), rtl: true));
    expect(_flipped(tester), isFalse);
    await tester.pumpWidget(_host(const GzIcon(GzIcons.search, mirror: true), rtl: true));
    expect(_flipped(tester), isTrue);
  });

  testWidgets('GzIcon is decorative unless it has a semantic label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const GzIcon(GzIcons.search)));
    expect(find.bySemanticsLabel('Search'), findsNothing);
    await tester.pumpWidget(_host(const GzIcon(GzIcons.search, semanticLabel: 'Search')));
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    handle.dispose();
  });

  test('every illustration has its four size variants as assets, and the registry has 60 (39 spots, 21 compositions)', () {
    expect(GzIllustrationName.values.length, 60);
    expect(GzIllustrationName.values.where((n) => n.kind == GzIllustrationKind.spot).length, 39);
    for (final n in GzIllustrationName.values) {
      for (final s in GzIllustrationSize.values) {
        final f = File('assets/illustrations/${n.id}.${s.id}.svg');
        expect(f.existsSync(), isTrue, reason: f.path);
        final text = f.readAsStringSync();
        expect(text.contains('class='), isFalse, reason: 'no CSS classes in ${f.path}');
        expect(text.contains('vector-effect'), isFalse);
      }
    }
    expect(GzIllustrationName.byId('dallah'), GzIllustrationName.dallah);
    expect(GzIllustrationName.dallah.mirror, isTrue);
    expect(GzIllustrationName.doorway.mirror, isFalse);
    expect([for (final s in GzIllustrationSize.values) s.dp], [64, 96, 144, 200]);
  });

  test('size variants pre-compensate the stroke so the line is 1.5 dp at each size', () {
    double stroke(String size) {
      final svg = File('assets/illustrations/doorway.$size.svg').readAsStringSync();
      return double.parse(RegExp(r'stroke-width="([\d.]+)"').firstMatch(svg)!.group(1)!);
    }

    expect(stroke('sm') * 64 / 120, closeTo(1.5, 0.001));
    expect(stroke('md') * 96 / 120, closeTo(1.5, 0.001));
    expect(stroke('lg') * 144 / 120, closeTo(1.5, 0.001));
    expect(stroke('hero') * 200 / 120, closeTo(1.5, 0.001));
  });

  testWidgets('GzIllustration is sized by the token, flips only mirrored drawings in RTL, decorative by default', (tester) async {
    await tester.pumpWidget(_host(const GzIllustration(GzIllustrationName.dallah, size: GzIllustrationSize.md), rtl: true));
    expect(tester.getSize(find.byType(GzIllustration)), const Size(96, 96));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(_flipped(tester), isTrue);
    await tester.pumpWidget(_host(const GzIllustration(GzIllustrationName.dallah), rtl: false));
    expect(_flipped(tester), isFalse);
    await tester.pumpWidget(_host(const GzIllustration(GzIllustrationName.doorway), rtl: true));
    expect(_flipped(tester), isFalse);
    expect(tester.getSize(find.byType(GzIllustration)), const Size(144, 144));
  });
}
