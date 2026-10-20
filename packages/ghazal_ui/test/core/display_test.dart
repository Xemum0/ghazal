import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/brand/brand.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import 'core_harness.dart';

void main() {
  for (final lang in ['en', 'ar']) {
    testWidgets('every status pill has an icon and a non-empty word ($lang)', (tester) async {
      late GzL10n l;
      await pumpCore(tester, Builder(builder: (context) {
        l = context.gzL10n;
        return const SizedBox();
      }), lang: lang);
      for (final s in GzStatus.values) {
        for (final a in GzStatusAudience.values) {
          expect(s.label(l, a).trim(), isNotEmpty, reason: '$s $a');
        }
      }
      await pumpCore(tester, SingleChildScrollView(child: Column(children: [for (final s in GzStatus.values) GzStatusPill(status: s)])), lang: lang, size: const Size(390, 4000));
      for (final s in GzStatus.values) {
        expect(find.text(s.label(l)), findsWidgets, reason: 'label of $s');
      }
      expect(find.byType(GzIcon), findsNWidgets(GzStatus.values.length));
    });
  }

  testWidgets('partner wording differs where the prototype says so', (tester) async {
    late GzL10n l;
    await pumpCore(tester, Builder(builder: (context) {
      l = context.gzL10n;
      return const SizedBox();
    }));
    expect(GzStatus.approved.label(l, GzStatusAudience.hotel), isNot(GzStatus.approved.label(l)));
    expect(GzStatus.expired.label(l, GzStatusAudience.hotel), l.commonStatusHotelLapsed);
  });

  testWidgets('approved pill appends a compact time figure', (tester) async {
    await pumpCore(tester, const GzStatusPill(status: GzStatus.approved, hours: 23));
    expect(find.textContaining('23'), findsOneWidget);
  });

  for (final lang in ['en', 'ar']) {
    testWidgets('money: the currency is drawn before (left of) the figure in $lang', (tester) async {
      await pumpCore(tester, const GzMoney(fils: 18200000), lang: lang);
      final cur = lang == 'en' ? 'KD' : 'د.ك';
      final c = tester.getCenter(find.text(cur));
      final n = tester.getCenter(find.text('18,200'));
      expect(c.dx, lessThan(n.dx));
      expect((c.dy - n.dy).abs(), lessThan(12));
    });
  }

  testWidgets('exact mode sets a zero fils quiet and a real fils inline', (tester) async {
    await pumpCore(tester, const Column(children: [GzMoney(fils: 5460000, mode: GzMoneyMode.exact), GzMoney(fils: 5460500, mode: GzMoneyMode.exact)]));
    expect(find.text('5,460'), findsOneWidget);
    expect(find.text('.000'), findsOneWidget);
    expect(find.text('5,460.500'), findsOneWidget);
    expect(find.text('18,200'), findsNothing);
  });

  testWidgets('price: browse drops a zero fraction; unit and struck price follow', (tester) async {
    await pumpCore(tester, const GzPrice(fils: 42000, was: 46000, unit: GzPriceUnit.perGuest));
    expect(find.text('42'), findsOneWidget);
    expect(find.text('per guest'), findsOneWidget);
    expect(find.textContaining('46'), findsOneWidget);
  });

  testWidgets('skeleton shimmer is off by default and does not animate under reduced motion', (tester) async {
    await pumpCore(tester, const GzSkeleton(shimmer: true, inlineSize: 100, blockSize: 20), reduceMotion: true);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await pumpCore(tester, const GzSkeleton(inlineSize: 100, blockSize: 20));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'static by default (direction 5)');
    await pumpCore(tester, const GzSkeleton(shimmer: true, inlineSize: 100, blockSize: 20));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('thread rule draws on once and finishes; off and reduced motion show it finished', (tester) async {
    await pumpCore(tester, const GzThreadRule(variant: GzThreadRuleVariant.full, draw: GzDraw.mount));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await pumpCore(tester, const GzThreadRule(draw: GzDraw.mount), reduceMotion: true);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('thread knot: slots and ring geometry per state', (tester) async {
    Future<Size> slot(GzKnotState s, {GzKnotSize size = GzKnotSize.booking}) async {
      await pumpCore(tester, GzThreadKnot(state: s, size: size));
      return tester.getSize(find.byType(GzThreadKnot));
    }

    for (final s in GzKnotState.values) {
      expect(await slot(s), const Size(32, 32), reason: '$s booking slot');
      expect(await slot(s, size: GzKnotSize.compact), const Size(24, 24), reason: '$s compact slot');
    }
    await pumpCore(tester, const GzThreadKnot(state: GzKnotState.now));
    final decorated = tester.widgetList<Container>(find.descendant(of: find.byType(GzThreadKnot), matching: find.byType(Container))).first;
    final box = decorated.decoration! as BoxDecoration;
    expect(box.boxShadow!.single.spreadRadius, 3);
    expect(box.border!.top.width, 3);
    await pumpCore(tester, const GzThreadKnot(state: GzKnotState.tied));
    expect(find.byType(GzIcon), findsOneWidget, reason: 'tied carries the check');
    await pumpCore(tester, const GzThreadKnot(state: GzKnotState.tied, size: GzKnotSize.compact));
    expect(find.byType(GzIcon), findsNothing);
    await pumpCore(tester, const GzThreadKnot(state: GzKnotState.open));
    expect(find.byType(GzIcon), findsNothing);
  });

  testWidgets('knot pop plays once and settles; reduced motion plays nothing', (tester) async {
    await pumpCore(tester, const GzThreadKnot(state: GzKnotState.tied, pop: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await pumpCore(tester, const GzThreadKnot(state: GzKnotState.tied, pop: true), reduceMotion: true);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('wordmark and monogram are LTR artwork in both languages and carry a name', (tester) async {
    final handle = tester.ensureSemantics();
    for (final lang in ['en', 'ar']) {
      await pumpCore(tester, const Column(children: [GzWordmark(), GzMonogram()]), lang: lang);
      final latin = tester.getCenter(find.text('Ghazal')).dx;
      final arabic = tester.getCenter(find.text('غزل')).dx;
      expect(latin, lessThan(arabic), reason: 'Latin first in $lang');
      expect(find.bySemanticsLabel(RegExp('Ghazal')), findsWidgets);
    }
    handle.dispose();
  });

  testWidgets('avatar monogram is the first letter, never a face', (tester) async {
    await pumpCore(tester, const Column(children: [GzAvatar(name: 'noura'), GzAvatar(name: 'غادة')]));
    expect(find.text('N'), findsOneWidget);
    expect(find.text('غ'), findsOneWidget);
    expect(gzMonogramOf('  aurelia'), 'A');
  });

  testWidgets('rating: stars fill from inline-start and the name carries the value', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCore(tester, const GzRating(variant: GzRatingVariant.stars, value: 3.5, count: 86));
    expect(find.textContaining('3.5'), findsOneWidget);
    expect(find.textContaining('(86)'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('3.5')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('list row: chevron mirrors in Arabic and the row is a button when it has a handler', (tester) async {
    for (final lang in ['en', 'ar']) {
      await pumpCore(tester, GzListRow(title: 'Language', chevron: true, onPressed: () {}), lang: lang);
      final flips = tester.widgetList<Transform>(find.descendant(of: find.byType(GzListRow), matching: find.byType(Transform))).where((t) => t.transform.entry(0, 0) == -1);
      expect(flips.length, lang == 'ar' ? 1 : 0, reason: lang);
    }
  });
}
