// Geometry of the core components measured against the web (`pnpm probe`), phase C parity fix wave. Real fonts (loadUiFonts), so
// every number is a box the prototype also has: sizes are the web's computed boxes in dp.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show CardPriceExact, MoneyAmount, PriceTier, ThreadRole;
import 'package:ghazal_ui/src/brand/brand.dart';
import 'package:ghazal_ui/src/client/client_bits.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/inputs/gz_segmented_control.dart';
import 'package:ghazal_ui/src/overlays/gz_accordion.dart';
import 'package:ghazal_ui/src/visits/gz_role_badge.dart';

import '../shared/shared_harness.dart';
import 'core_harness.dart';

double _baseline(WidgetTester tester, Finder f) {
  final ro = tester.renderObject<RenderBox>(f.first);
  RenderObject.debugCheckingIntrinsics = true;
  final b = ro.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true);
  RenderObject.debugCheckingIntrinsics = false;
  return b!;
}

void main() {
  setUpAll(loadUiFonts);

  group('GzFactChip height is the figures line of its role (strut), Arabic words included', () {
    const cases = {
      // (lang, small, value): web .gz-fchip box height
      ('en', true, '350'): 20.0,
      ('ar', true, '350'): 22.0,
      ('en', false, '350'): 24.0,
      ('ar', false, '350'): 26.0,
      ('ar', false, 'من 9:00 م'): 26.0,
      ('en', false, 'من 9:00 م'): 24.0,
    };
    cases.forEach((k, h) {
      testWidgets('$k', (tester) async {
        await pumpCore(tester, GzFactChip(icon: GzIcons.starFill, label: 'g', value: k.$3, small: k.$2), lang: k.$1);
        expect(tester.getSize(find.byType(GzFactChip)).height, h);
      });
    });
    testWidgets('its baseline is the bottom edge of its icon', (tester) async {
      await pumpCore(tester, const GzFactChip(icon: GzIcons.starFill, label: 'g', value: '350', small: true));
      expect(_baseline(tester, find.byType(GzFactChip)), (20 + 16) / 2);
    });
  });

  group('GzPrice with a quiet fils inherits the page line like the web .gz-money__fils', () {
    testWidgets('exact card price: 25 in English, 28 in Arabic; browse and strong stay 24 and 26', (tester) async {
      await pumpCore(tester, const GzPrice(fils: 5460000, mode: GzMoneyMode.exact));
      expect(tester.getSize(find.byType(GzPrice)).height, 25);
      await pumpCore(tester, const GzPrice(fils: 5460000, mode: GzMoneyMode.exact), lang: 'ar');
      expect(tester.getSize(find.byType(GzPrice)).height, 28);
      await pumpCore(tester, const GzPrice(fils: 18200000, size: GzPriceSize.strong));
      expect(tester.getSize(find.byType(GzPrice)).height, 24);
      await pumpCore(tester, const GzPrice(fils: 18200000, size: GzPriceSize.strong), lang: 'ar');
      expect(tester.getSize(find.byType(GzPrice)).height, 26);
    });
    testWidgets('the total price with its quiet fils is 28 / 32', (tester) async {
      await pumpCore(tester, const GzPrice(fils: 5460000, size: GzPriceSize.total, mode: GzMoneyMode.exact));
      expect(tester.getSize(find.byType(GzPrice)).height, 28);
      await pumpCore(tester, const GzPrice(fils: 5460000, size: GzPriceSize.total, mode: GzMoneyMode.exact), lang: 'ar');
      expect(tester.getSize(find.byType(GzPrice)).height, 32);
    });
  });

  group('baseline of a glyph-first item is its glyph bottom, and a web block adds its strut', () {
    testWidgets('GzRating reports the star bottom (20 in a 24 box)', (tester) async {
      await pumpCore(tester, const GzRating(value: 4.8, count: 212));
      expect(_baseline(tester, find.byType(GzRating)), 20);
    });
    testWidgets('GzInlineStrut: price 25, rating 27, plain text 24 (the compare cell value block)', (tester) async {
      await pumpCore(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzInlineStrut(child: GzPrice(fils: 8400000, size: GzPriceSize.strong)),
            GzInlineStrut(child: GzRating(value: 4.8, count: 212)),
            GzInlineStrut(child: GzText('Up to 500', role: GzTextRole.bodyS)),
          ],
        ),
      );
      final s = find.byType(GzInlineStrut);
      expect(tester.getSize(s.at(0)).height, 25);
      expect(tester.getSize(s.at(1)).height, 27);
      expect(tester.getSize(s.at(2)).height, 24);
    });
    testWidgets('GzInlineStrut with the body role of Arabic holds a 26 dp price to 28 (the voucher dd)', (tester) async {
      await pumpCore(tester, const GzInlineStrut(role: GzTextRole.body, child: GzPrice(fils: 8400000, size: GzPriceSize.strong)), lang: 'ar');
      expect(tester.getSize(find.byType(GzInlineStrut)).height, 28);
    });
    testWidgets('GzChromeBaseline: the browser baseline of the Arabic title is 19, of the English body-s 17', (tester) async {
      late GzThemeData ar;
      late GzThemeData en;
      await pumpCore(tester, Builder(builder: (c) {
          ar = c.gz;
          return const SizedBox();
        }), lang: 'ar');
      await pumpCore(tester, Builder(builder: (c) {
          en = c.gz;
          return const SizedBox();
        }));
      expect(GzChromeBaseline.baselineOf(ar.text(GzTextRole.title), TextDirection.rtl), 19);
      expect(GzChromeBaseline.baselineOf(ar.text(GzTextRole.bodyS), TextDirection.rtl), 18);
      expect(GzChromeBaseline.baselineOf(en.text(GzTextRole.bodyS), TextDirection.ltr), 17);
      expect(GzChromeBaseline.baselineOf(en.text(GzTextRole.d1), TextDirection.ltr), 18);
    });
  });

  group('GzText figures keeps the role line (web strut)', () {
    testWidgets('a lone figures run is one full caption line: 20 in English, 22 in Arabic', (tester) async {
      await pumpCore(tester, const GzText('2026', role: GzTextRole.caption, figures: true));
      expect(tester.getSize(find.byType(GzText)).height, 20);
      await pumpCore(tester, const GzText('2026', role: GzTextRole.caption, figures: true), lang: 'ar');
      expect(tester.getSize(find.byType(GzText)).height, 22);
    });
    testWidgets('a wrapped caption of two lines is two full lines (Arabic 44)', (tester) async {
      await pumpCore(tester, const SizedBox(width: 60, child: GzText('الخميس 14 يناير 2026', role: GzTextRole.caption, figures: true)), lang: 'ar');
      expect(tester.getSize(find.byType(GzText)).height % 22, 0);
    });
  });

  group('GzIconProgress', () {
    GzIconProgress progress({GzProgressLabels labels = GzProgressLabels.active}) => GzIconProgress(
      label: 'p',
      labels: labels,
      draw: GzDraw.off,
      steps: const [
        GzIconProgressStep(id: 'a', icon: GzIcons.check, label: 'Sent', state: GzKnotState.tied),
        GzIconProgressStep(id: 'b', icon: GzIcons.clock, label: 'Review', state: GzKnotState.now),
        GzIconProgressStep(id: 'c', icon: GzIcons.check, label: 'Done', state: GzKnotState.open),
      ],
    );

    testWidgets('its label survives an unbounded-height parent (a scroll view)', (tester) async {
      await pumpCore(tester, SizedBox(width: 300, child: SingleChildScrollView(child: Column(children: [progress()]))));
      expect(tester.takeException(), isNull);
      expect(find.text('Review'), findsOneWidget);
    });
    testWidgets('no label means no trailing gap: glyph 24 + 4 + knot row, nothing below', (tester) async {
      await pumpCore(tester, SizedBox(width: 300, child: progress(labels: GzProgressLabels.none)));
      final none = tester.getSize(find.byType(GzIconProgress)).height;
      await pumpCore(tester, SizedBox(width: 300, child: progress()));
      final active = tester.getSize(find.byType(GzIconProgress)).height;
      expect(active - none, 4 + 20, reason: 'the 4 dp gap and the caption line only appear with a label');
    });
  });

  testWidgets('GzSegmentedControl paints the 2 dp gold thread under the selected option', (tester) async {
    await pumpCore(
      tester,
      SizedBox(
        width: 300,
        child: GzSegmentedControl<int>(
          label: 'seg',
          defaultValue: 0,
          options: const [GzSegmentedOption(value: 0, label: 'One'), GzSegmentedOption(value: 1, label: 'Two')],
        ),
      ),
    );
    final thread = find.byWidgetPredicate((w) => w is ColoredBox && w.color == GzColors.light.markKhayt);
    expect(thread, findsOneWidget);
    final size = tester.getSize(thread);
    expect(size.height, GzStroke.thread);
    expect(size.width, greaterThan(40));
  });

  testWidgets('GzAccordion rows are their content plus the 1 dp hairline (65 for a 64 head)', (tester) async {
    await pumpCore(
      tester,
      const SizedBox(
        width: 300,
        child: GzAccordion(items: [GzAccordionItem(id: 'a', title: 'Q', content: SizedBox(height: 10)), GzAccordionItem(id: 'b', title: 'R', content: SizedBox(height: 10))]),
      ),
    );
    final rows = find.byKey(const ValueKey('gz:accordion.a'));
    final head = tester.getSize(rows).height;
    expect(head, GzSize.rowMin + GzStroke.hair, reason: 'a 64 min head plus its hairline (the web 65)');
    expect(tester.getSize(find.byType(GzAccordion)).height, 2 * head);
  });

  group('GzButton options', () {
    testWidgets('compact trims the inline padding to 8 + hairline (a secondary button)', (tester) async {
      await pumpCore(tester, const GzButton(label: 'Compare', variant: GzButtonVariant.secondary));
      final normal = tester.getSize(find.byType(GzButton)).width;
      await pumpCore(tester, const GzButton(label: 'Compare', variant: GzButtonVariant.secondary, compact: true));
      expect(normal - tester.getSize(find.byType(GzButton)).width, 2 * (24 - 8));
    });
    testWidgets('spill centres content wider than the box instead of overflowing', (tester) async {
      await pumpCore(tester, const SizedBox(width: 60, child: GzButton(label: 'Full screen', iconStart: GzIcons.qrCode, variant: GzButtonVariant.secondary, fullWidth: true, spill: true)));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(GzButton)).width, 60);
    });
    testWidgets('figures: a digit run of the label is drawn in the figures face', (tester) async {
      await pumpCore(tester, const GzButton(label: 'Show 3 halls', figures: true));
      final rich = tester.widgetList<RichText>(find.byType(RichText)).where((r) => r.text.toPlainText().contains('halls')).first;
      final fonts = <String?>{};
      rich.text.visitChildren((s) {
        if (s is TextSpan && s.text != null) fonts.add(s.style?.fontFamily);
        return true;
      });
      expect(fonts.whereType<String>().any((f) => f.contains('Manrope')), isTrue);
      expect(fonts.length, greaterThan(1), reason: 'the digits are their own span');
    });
    testWidgets('ellipsize cuts a long label on one line in a narrow box', (tester) async {
      await pumpCore(tester, const SizedBox(width: 80, child: GzButton(label: 'A very long compare label', variant: GzButtonVariant.secondary, compact: true, ellipsize: true, fullWidth: true)));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(GzButton)).width, 80);
    });
  });

  testWidgets('GzStatusPill compact trims the inline padding by 4 per side', (tester) async {
    await pumpCore(tester, const GzStatusPill(status: GzStatus.available));
    final normal = tester.getSize(find.byType(GzStatusPill)).width;
    await pumpCore(tester, const GzStatusPill(status: GzStatus.available, compact: true));
    expect(normal - tester.getSize(find.byType(GzStatusPill)).width, 8);
  });

  group('GzRoleBadge', () {
    testWidgets('a label wider than its cell spills (no clip) and the chip keeps its cell width', (tester) async {
      await pumpCore(tester, const SizedBox(width: 78.5, child: GzRoleBadge(role: ThreadRole.hotelRepresentative)));
      final text = tester.widget<Text>(find.descendant(of: find.byType(GzRoleBadge), matching: find.byType(Text)));
      expect(text.overflow, TextOverflow.visible);
      expect(text.softWrap, false);
      expect(tester.getSize(find.byType(GzRoleBadge)).width, 78.5);
    });
    testWidgets('wrap lets the words break onto two lines', (tester) async {
      await pumpCore(tester, const SizedBox(width: 78.5, child: GzRoleBadge(role: ThreadRole.hotelRepresentative, wrap: true)));
      expect(tester.getSize(find.byType(GzRoleBadge)).height, greaterThan(26));
    });
  });

  group('GzCardPriceLine aligns on whole-pixel baselines like Chrome', () {
    const exact = CardPriceExact(voucher: MoneyAmount(15400000), savings: MoneyAmount(2800000), amount: MoneyAmount(18200000), guests: 350, packageId: 'p', tier: PriceTier.weekend);
    testWidgets('the member line is 26 high in English and 27 in Arabic (the saving chip sits on its glyph bottom)', (tester) async {
      await pumpCore(tester, const SizedBox(width: 340, child: GzCardPriceLine(price: exact)));
      expect(tester.getSize(find.byType(GzBaselineWrap)).height, 26);
      await pumpCore(tester, const SizedBox(width: 340, child: GzCardPriceLine(price: exact)), lang: 'ar');
      expect(tester.getSize(find.byType(GzBaselineWrap)).height, 27);
    });
  });
}
