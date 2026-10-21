import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/overlays/overlays.dart';

import '../nav/nav_harness.dart';

void main() {
  group('GzInfoButton', () {
    testWidgets('a 44 dp info glyph opens the sheet (title, paragraphs, Done), says expanded while it is up and closes on Done', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(tester, const Center(child: GzInfoButton(title: 'The voucher', paragraphs: ['Valid for two months.', 'Tied to one venue.'])));
      expect(tester.getSize(find.byType(GzInfoButton)), const Size(44, 44));
      final glyph = find.bySemanticsLabel('More info');
      expect(tester.getSemantics(glyph).flagsCollection.isExpanded, Tristate.isFalse);
      await tester.tap(find.byType(GzInfoButton));
      await tester.pumpAndSettle();
      expect(find.text('The voucher'), findsOneWidget);
      expect(find.text('Valid for two months.'), findsOneWidget);
      expect(find.text('Tied to one venue.'), findsOneWidget);
      // two paragraphs, 12 apart, on the 20 gutter that the sheet supplies
      expect(tester.getTopLeft(find.text('Valid for two months.')).dx, GzSpace.gutter);
      expect(tester.getTopLeft(find.text('Tied to one venue.')).dy - tester.getBottomLeft(find.text('Valid for two months.')).dy, closeTo(GzSpace.s3, 2));
      expect(tester.getSemantics(glyph).flagsCollection.isExpanded, Tristate.isTrue);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('The voucher'), findsNothing);
      expect(tester.getSemantics(glyph).flagsCollection.isExpanded, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('an action button in the sheet closes it first, then acts', (tester) async {
      var acted = 0;
      await pumpNav(
        tester,
        Center(
          child: GzInfoButton(
            title: 'Terms',
            label: 'Read the terms',
            paragraphs: const ['One idea.'],
            action: GzInfoAction(
              label: 'Read the terms',
              onPressed: () {
                acted++;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GzInfoButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read the terms').last);
      await tester.pumpAndSettle();
      expect(acted, 1);
      expect(find.text('One idea.'), findsNothing);
    });

    testWidgets('bleed pulls the glyph 10 dp toward the inline end: right in English, left in Arabic', (tester) async {
      for (final lang in ['en', 'ar']) {
        await pumpNav(tester, const Align(alignment: AlignmentDirectional.centerEnd, child: GzInfoButton(title: 'T', paragraphs: ['x'], bleed: true)), lang: lang);
        final r = tester.getRect(find.byType(GzIconButton));
        expect(lang == 'en' ? r.right : r.left, lang == 'en' ? 390 + 10 : -10, reason: lang);
      }
    });
  });

  group('GzAsideInfo', () {
    testWidgets('a quiet row: glyph, one word, the info glyph; the whole row is one button of at least 44 that opens the sheet', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(tester, const Padding(padding: EdgeInsets.all(20), child: GzAsideInfo(icon: GzIcons.lock, word: 'Private', title: 'Your privacy', paragraphs: ['Only the venue sees this.'])));
      expect(tester.getSize(find.byType(GzAsideInfo)).height, greaterThanOrEqualTo(44));
      expect(find.bySemanticsLabel('Private, Your privacy'), findsOneWidget);
      await tester.tap(find.text('Private'));
      await tester.pumpAndSettle();
      expect(find.text('Your privacy'), findsOneWidget);
      expect(find.text('Only the venue sees this.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Arabic: the row starts at the right edge', (tester) async {
      await pumpNav(tester, const Padding(padding: EdgeInsets.all(20), child: GzAsideInfo(icon: GzIcons.lock, word: 'خاص', title: 'خصوصيتكم', paragraphs: ['x'])), lang: 'ar');
      expect(tester.getRect(find.byType(GzAsideInfo)).right, 390 - 20);
    });
  });
}
