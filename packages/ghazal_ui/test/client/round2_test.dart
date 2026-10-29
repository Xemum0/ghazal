// Round 2 (ADR 0038) components: GzProviderNote and GzSexChoice. The numbers are the web's, measured with `pnpm probe` on the client
// gallery section `vendor-card` (ProviderNote) and on CL-AUTH-03 (SexChoice); real fonts so the wraps are the web's wraps.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Sex;
import 'package:ghazal_ui/src/app/gz_host.dart';
import 'package:ghazal_ui/src/client/client_r2.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart' show GzIconSegmented;

import '../core/core_harness.dart';
import '../shared/shared_harness.dart';

Future<void> _pump(WidgetTester tester, Widget child, {String lang = 'en', bool reduceMotion = false}) =>
    pumpCore(tester, SizedBox(width: 350, child: child), lang: lang, reduceMotion: reduceMotion, size: const Size(390, 900));

Widget _sex({Sex? value, ValueChanged<Sex>? onChanged, String? error, bool disabled = false}) => GzSexChoice(
  value: value,
  label: 'Sex',
  femaleLabel: 'Female',
  maleLabel: 'Male',
  onChanged: onChanged,
  error: error,
  disabled: disabled,
);

void main() {
  setUpAll(loadUiFonts);

  group('GzProviderNote', () {
    const sentence = 'Service provider? Apply in the Partner app';
    const sentenceAr = 'هل أنت مزوّد خدمة؟ قدّم طلبك في تطبيق الشريك';

    testWidgets('banner: a full-width rose card, 72 high (the web numbers): glyph, the whole sentence on two lines, "Apply" and a chevron', (tester) async {
      await _pump(tester, GzProviderNote(variant: GzProviderNoteVariant.banner, onOpen: () {}));
      final note = tester.getRect(find.byType(GzProviderNote));
      expect(note.size, const Size(350, 72));
      final glyphs = find.byType(GzIcon);
      expect(glyphs, findsNWidgets(2)); // the start glyph and the chevron: no info or external-link glyph hides words
      expect(tester.getRect(glyphs.at(0)).left - note.left, 12);
      expect(tester.getSize(glyphs.at(0)), const Size(24, 24));
      expect(note.right - tester.getRect(glyphs.at(1)).right, 12);
      expect(tester.getSize(glyphs.at(1)), const Size(20, 20));
      final sentenceText = tester.widget<GzText>(find.widgetWithText(GzText, sentence));
      expect(sentenceText.maxLines, isNull); // nothing is ellipsised: the whole sentence is there
      expect(sentenceText.overflow, isNull);
      expect(tester.getRect(find.text(sentence)).left - note.left, 48);
      expect(tester.getSize(find.text(sentence)).width, closeTo(214.5, 0.1));
      expect(tester.getSize(find.text(sentence)).height, 48); // two lines of 24
      final cta = tester.widget<GzText>(find.widgetWithText(GzText, 'Apply'));
      expect(cta.color, tester.element(find.byType(GzProviderNote)).gz.colors.actionTertiaryLabel);
      expect(tester.getRect(find.text('Apply')).left - note.left, closeTo(274.5, 0.1));
      expect(tester.getSize(find.text('Apply')).width, closeTo(39.5, 0.1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('banner in Arabic mirrors: 80 high, the glyph at the right edge, «تقديم» and the chevron at the left', (tester) async {
      await _pump(tester, GzProviderNote(variant: GzProviderNoteVariant.banner, onOpen: () {}), lang: 'ar');
      final note = tester.getRect(find.byType(GzProviderNote));
      expect(note.size, const Size(350, 80));
      final glyphs = find.byType(GzIcon);
      expect(note.right - tester.getRect(glyphs.at(0)).right, 12);
      expect(tester.getRect(glyphs.at(1)).left - note.left, 12);
      expect(find.text(sentenceAr), findsOneWidget);
      expect(tester.getSize(find.text(sentenceAr)).width, closeTo(214.9, 0.1));
      expect(tester.getSize(find.text(sentenceAr)).height, 56);
      expect(find.text('تقديم'), findsOneWidget);
      expect(tester.getRect(find.text('تقديم')).left - note.left, 36);
      expect(tester.getRect(find.text(sentenceAr)).right, lessThan(tester.getRect(glyphs.at(0)).left));
      expect(tester.takeException(), isNull);
    });

    testWidgets('row: the Profile list row, 73 high in English and 81 in Arabic (the web numbers), "Apply" and a chevron at the end', (tester) async {
      await _pump(tester, GzProviderNote(onOpen: () {}));
      final note = tester.getRect(find.byType(GzProviderNote));
      expect(note.size, const Size(350, 73));
      expect(tester.getRect(find.text(sentence)).left - note.left, 72);
      expect(tester.getSize(find.text(sentence)).width, closeTo(174.5, 0.1));
      expect(tester.getSize(find.text(sentence)).height, 48);
      expect(find.text('Apply'), findsOneWidget);
      expect(tester.getRect(find.text('Apply')).left - note.left, closeTo(258.5, 0.1));
      expect(note.right - tester.getRect(find.byType(GzIcon).last).right, 20);
      await _pump(tester, GzProviderNote(onOpen: () {}), lang: 'ar');
      final ar = tester.getRect(find.byType(GzProviderNote));
      expect(ar.size, const Size(350, 81));
      expect(tester.getSize(find.text(sentenceAr)).width, closeTo(174.9, 0.1));
      expect(find.text('تقديم'), findsOneWidget);
      expect(tester.getRect(find.text('تقديم')).left - ar.left, 52);
      expect(tester.getRect(find.byType(GzIcon).last).left - ar.left, 20);
      expect(tester.takeException(), isNull);
    });

    testWidgets('footer is the earlier name of banner: the same card, the same numbers', (tester) async {
      await _pump(tester, GzProviderNote(variant: GzProviderNoteVariant.footer, onOpen: () {}));
      expect(tester.getRect(find.byType(GzProviderNote)).size, const Size(350, 72));
      expect(tester.getSize(find.text('Service provider? Apply in the Partner app')).width, closeTo(214.5, 0.1));
    });

    testWidgets('row on the band (CL-PROF-01, 390 wide): a rose band edge to edge, 73 high in English and 81 in Arabic, the disk on the raised surface', (tester) async {
      await pumpCore(tester, SizedBox(width: 390, child: GzProviderNote(onOpen: () {}, band: true)), size: const Size(390, 900));
      final colors = tester.element(find.byType(GzProviderNote)).gz.colors;
      final band = tester.getRect(find.byType(GzProviderNote));
      expect(band.size, const Size(390, 73));
      final box = tester.widget<ColoredBox>(find.descendant(of: find.byType(GzProviderNote), matching: find.byType(ColoredBox)).first);
      expect(box.color, colors.surfaceTint);
      final disk = tester.widgetList<Container>(find.descendant(of: find.byType(GzProviderNote), matching: find.byType(Container))).where((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.shape == BoxShape.circle;
      });
      expect(disk, hasLength(1));
      expect((disk.single.decoration! as BoxDecoration).color, colors.surfaceRaised);
      expect(tester.getRect(find.text(sentence)).left - band.left, 72);
      expect(tester.getSize(find.text(sentence)).width, closeTo(214.5, 0.1));
      expect(tester.getRect(find.text('Apply')).left - band.left, closeTo(298.5, 0.1));
      expect(band.right - tester.getRect(find.byType(GzIcon).last).right, 20);
      await pumpCore(tester, SizedBox(width: 390, child: GzProviderNote(onOpen: () {}, band: true)), lang: 'ar', size: const Size(390, 900));
      expect(tester.getRect(find.byType(GzProviderNote)).size, const Size(390, 81));
      expect(tester.getSize(find.text(sentenceAr)).width, closeTo(214.9, 0.1));
      expect(tester.getRect(find.text('تقديم')).left - tester.getRect(find.byType(GzProviderNote)).left, 52);
      expect(tester.takeException(), isNull);
    });

    testWidgets('row without band keeps the list row look: no rose band behind it', (tester) async {
      await _pump(tester, GzProviderNote(onOpen: () {}));
      expect(find.descendant(of: find.byType(GzProviderNote), matching: find.byType(ColoredBox)), findsNothing);
    });

    for (final variant in GzProviderNoteVariant.values) {
      for (final lang in ['en', 'ar']) {
        testWidgets('${variant.name} ($lang): at text scale 1.3 the whole sentence wraps inside the note without overflow', (tester) async {
          tester.view
            ..devicePixelRatio = 1
            ..physicalSize = const Size(390, 900);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            GzHost(
              locale: Locale(lang),
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: Align(alignment: AlignmentDirectional.topStart, child: SizedBox(width: 350, child: GzProviderNote(variant: variant, onOpen: () {}))),
                ),
              ),
            ),
          );
          await tester.pump();
          final note = tester.getRect(find.byType(GzProviderNote));
          final words = find.text(lang == 'en' ? sentence : sentenceAr);
          expect(words, findsOneWidget);
          final box = tester.getRect(words);
          expect(box.left, greaterThanOrEqualTo(note.left));
          expect(box.right, lessThanOrEqualTo(note.right));
          expect(box.top, greaterThanOrEqualTo(note.top));
          expect(box.bottom, lessThanOrEqualTo(note.bottom));
          expect(note.height, greaterThan(44));
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final variant in GzProviderNoteVariant.values) {
      testWidgets('${variant.name}: the whole note is one tap target of at least 44 dp that calls onOpen', (tester) async {
        var opened = 0;
        await _pump(tester, GzProviderNote(variant: variant, onOpen: () => opened++));
        final target = tester.getSize(find.byType(GzPressable));
        expect(target.height, greaterThanOrEqualTo(44));
        expect(target.width, greaterThanOrEqualTo(44));
        await tester.tapAt(tester.getRect(find.byType(GzPressable)).center);
        expect(opened, 1);
        // the call to action and the sentence open it too: the Apply label is not a second target
        await tester.tapAt(tester.getRect(find.text('Apply')).center);
        expect(opened, 2);
      });

      testWidgets('${variant.name}: one Semantics node, announced as a link with the words', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, GzProviderNote(variant: variant, onOpen: () {}));
        final node = tester.getSemantics(find.byType(GzPressable));
        expect(node.label, 'Service provider? Apply in the Partner app');
        expect(node.flagsCollection.isLink, isTrue);
        expect(node.flagsCollection.isButton, isFalse);
        expect(find.byType(Semantics).evaluate().where((e) => (e.widget as Semantics).properties.link == true), hasLength(1));
        handle.dispose();
      });

      testWidgets('${variant.name}: without onOpen it is an inert note (no pressable, no link)', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, GzProviderNote(variant: variant));
        expect(find.byType(GzPressable), findsNothing);
        expect(find.bySemanticsLabel('Service provider? Apply in the Partner app'), findsOneWidget);
        handle.dispose();
      });
    }

    testWidgets('the Arabic words are the voucher-model voice', (tester) async {
      await _pump(tester, const GzProviderNote(variant: GzProviderNoteVariant.banner), lang: 'ar');
      expect(find.text('هل أنت مزوّد خدمة؟ قدّم طلبك في تطبيق الشريك'), findsOneWidget);
    });
  });

  group('GzSexChoice tiles', () {
    testWidgets('two equal tiles 169 wide, 12 apart; 102 high in English, the group 126; the check disk is 24 at the end', (tester) async {
      await _pump(tester, _sex(value: Sex.female, onChanged: (_) {}));
      final group = tester.getRect(find.byType(GzSexChoice));
      expect(group.size, const Size(350, 126));
      final tiles = find.byType(GzPressable);
      expect(tiles, findsNWidgets(2));
      final female = tester.getRect(tiles.at(0));
      final male = tester.getRect(tiles.at(1));
      expect(female.size, const Size(169, 102));
      expect(male.size, const Size(169, 102));
      expect(male.left - female.right, 12);
      expect(female.left, group.left);
      // top row: the symbol 32 at the start (1 border + 16 padding), the check disk 24 at the end, 4 dp lower to centre
      final glyph = tester.getRect(find.byType(GzIcon).at(0));
      expect(glyph.size, const Size(32, 32));
      expect(glyph.left - female.left, 17);
      expect(glyph.top - female.top, 17);
      final disk = tester.getRect(find.byType(GzIcon).at(1)); // the check of the chosen tile
      expect(disk.size, const Size(16, 16));
      expect(female.right - disk.right, 17 + 4);
    });

    testWidgets('Arabic: 106 high tiles, the group 134, female at the right (start), the symbol at the right edge of the tile', (tester) async {
      await _pump(tester, _sex(value: Sex.male, onChanged: (_) {}), lang: 'ar');
      expect(tester.getSize(find.byType(GzSexChoice)), const Size(350, 134));
      final tiles = find.byType(GzPressable);
      final female = tester.getRect(tiles.at(0));
      final male = tester.getRect(tiles.at(1));
      expect(female.size, const Size(169, 106));
      expect(female.left, greaterThan(male.left));
      expect(female.right, 350 + tester.getRect(find.byType(GzSexChoice)).left);
      final glyph = tester.getRect(find.byType(GzIcon).at(0));
      expect(female.right - glyph.right, 17);
    });

    testWidgets('choosing reports the sex; the chosen tile reads checked, the other not; nothing chosen reads neither', (tester) async {
      final handle = tester.ensureSemantics();
      final seen = <Sex>[];
      await _pump(tester, _sex(onChanged: seen.add));
      expect(tester.getSemantics(find.byType(GzPressable).at(0)).flagsCollection.isChecked.name, 'isFalse');
      await tester.tap(find.text('Male'));
      await tester.tap(find.text('Female'));
      expect(seen, [Sex.male, Sex.female]);
      await _pump(tester, _sex(value: Sex.male, onChanged: seen.add));
      expect(tester.getSemantics(find.byType(GzPressable).at(1)).flagsCollection.isChecked.name, 'isTrue');
      expect(tester.getSemantics(find.byType(GzPressable).at(0)).flagsCollection.isChecked.name, 'isFalse');
      expect(tester.getSemantics(find.byType(GzPressable).at(1)).label, 'Male');
      handle.dispose();
    });

    testWidgets('the selected tile has the ink border and an ink check disk; an empty required group shows the error border and message', (tester) async {
      final c = GzColors.light;
      BoxDecoration tileDeco(int i) => tester
          .widgetList<Container>(find.descendant(of: find.byType(GzPressable).at(i), matching: find.byType(Container)))
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.borderRadius == GzRadius.mdAll && d.border != null);
      await _pump(tester, _sex(value: Sex.female, onChanged: (_) {}));
      expect((tileDeco(0).border! as Border).top.color, c.controlChipBorderSelected);
      expect((tileDeco(1).border! as Border).top.color, c.borderStrong);
      expect(find.byIcon(GzIcons.check), findsOneWidget);
      await _pump(tester, _sex(onChanged: (_) {}, error: 'Required'));
      expect((tileDeco(0).border! as Border).top.color, c.borderError);
      expect((tileDeco(1).border! as Border).top.color, c.borderError);
      expect(find.text('Required'), findsOneWidget);
      expect(find.byIcon(GzIcons.warningCircle), findsOneWidget);
      expect(find.byIcon(GzIcons.check), findsNothing);
      // the error row: 8 under the tiles, 20 high (caption), the group grows by 28 over the plain 126
      expect(tester.getSize(find.byType(GzSexChoice)).height, 154);
    });

    testWidgets('the error is announced as a live region and the group is required and invalid', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _sex(onChanged: (_) {}, error: 'Required'));
      final group = tester.getSemantics(find.byType(GzSexChoice));
      expect(group.label, contains('Sex'));
      expect(group.flagsCollection.isRequired.name, 'isTrue');
      expect(find.bySemanticsLabel('Required'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('disabled: no taps get through, the words go quiet', (tester) async {
      final seen = <Sex>[];
      await _pump(tester, _sex(value: Sex.female, onChanged: seen.add, disabled: true));
      await tester.tap(find.text('Male'));
      expect(seen, isEmpty);
    });

    testWidgets('text scale 1.3 keeps the tiles whole: no overflow, both tiles still equal', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, _sex(value: Sex.female, onChanged: (_) {}, error: 'Required'));
      expect(tester.takeException(), isNull);
      final tiles = find.byType(GzPressable);
      expect(tester.getSize(tiles.at(0)), tester.getSize(tiles.at(1)));
    });

    testWidgets('reduced motion: the tiles hold no animated transform (a press never scales a tile)', (tester) async {
      await _pump(tester, _sex(value: Sex.female, onChanged: (_) {}), reduceMotion: true);
      final gesture = await tester.startGesture(tester.getCenter(find.byType(GzPressable).at(1)));
      await tester.pump(const Duration(milliseconds: 200));
      final scale = tester.widget<AnimatedScale>(find.descendant(of: find.byType(GzPressable).at(1), matching: find.byType(AnimatedScale)));
      expect(scale.scale, 1);
      await gesture.up();
    });
  });

  group('GzSexChoice.switcher (Personal info)', () {
    Widget sw({Sex? value, ValueChanged<Sex>? onChanged, bool disabled = false}) => GzSexChoice.switcher(
      value: value,
      label: 'Sex',
      femaleLabel: 'Female',
      maleLabel: 'Male',
      onChanged: onChanged,
      disabled: disabled,
    );

    testWidgets('a 44 dp glyph switch with both words; the tap reports the sex; nothing is drawn above it', (tester) async {
      final seen = <Sex>[];
      await _pump(tester, sw(value: Sex.female, onChanged: seen.add));
      expect(find.byType(GzIconSegmented<Sex>), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Sex'), findsNothing);
      expect(tester.getSize(find.byType(GzIconSegmented<Sex>)).height, greaterThanOrEqualTo(44));
      await tester.tap(find.text('Male'));
      expect(seen, [Sex.male]);
    });

    testWidgets('Arabic: female sits at the start (right); the group is named for assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        GzSexChoice.switcher(value: Sex.female, label: 'الجنس', femaleLabel: 'أنثى', maleLabel: 'ذكر', onChanged: (_) {}),
        lang: 'ar',
      );
      expect(tester.getCenter(find.text('أنثى')).dx, greaterThan(tester.getCenter(find.text('ذكر')).dx));
      expect(find.bySemanticsLabel('الجنس'), findsWidgets);
      handle.dispose();
    });
  });
}
