import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/client/client_shared.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import '../core/core_harness.dart';
import 'shared_harness.dart';

const _exact = CardPriceExact(
  voucher: MoneyAmount(15400000),
  savings: MoneyAmount(2800000),
  amount: MoneyAmount(18200000),
  guests: 350,
  packageId: 'p1',
  tier: PriceTier.weekend,
);
const _rental = CardPriceRentalFee(voucher: null, savings: null, amount: MoneyAmount(900000));

void main() {
  setUpAll(loadUiFonts);

  test('gzOpenBudget keeps the plus inside the number isolate', () {
    final en = GzFormat(locale: const Locale('en'));
    final ar = GzFormat(locale: const Locale('ar'));
    expect(en.plain(gzOpenBudget(en, 35000000)), 'KD 35,000+');
    expect(ar.plain(gzOpenBudget(ar, 35000000)), '35,000+ د.ك');
    expect(gzOpenBudget(ar, 35000000).startsWith('\u2066'), isTrue);
  });

  test('gzDayMonth uses formatter parts', () {
    final en = GzFormat(locale: const Locale('en'));
    expect(gzDayMonth(en, '2026-11-14'), '14 Nov');
  });

  testWidgets('member sees the voucher headline, struck standard price and the saving chip (web geometry at 280 dp)', (tester) async {
    await pumpCore(tester, const SizedBox(width: 280, child: GzCardPriceLine(price: _exact)));
    final line = tester.getRect(find.byKey(const ValueKey('gz-card-price-line')));
    expect(line.height, closeTo(48, 1.5)); // web 280x48: run 1 = price + guests (24), run 2 = saving chip (24)
    final chip = tester.getRect(find.byType(GzFactChip));
    expect(tester.getRect(find.byType(GzPrice)).width, closeTo(135.44, 1)); // web Price 135.44x24
    expect(chip.width, closeTo(46.05, 1)); // web FactChip 46.05 wide
    expect(chip.left - tester.getRect(find.byType(GzPrice)).right, closeTo(8, 0.5));
    expect(chip.top - line.top, closeTo(0, 1.5)); // web: chip top = line top (icon bottom on the price baseline)
    final save = find.bySemanticsLabel(RegExp('Save'));
    expect(save, findsOneWidget);
    expect(tester.getRect(save).top - line.top, closeTo(24, 1.5));
    expect(find.byIcon(GzIcons.lock), findsNothing);
  });

  testWidgets('guest sees the standard price headline, no saving, and the lock line', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCore(tester, const GzCardPriceLine(price: _exact, audience: GzPriceAudience.guest));
    expect(find.byKey(const ValueKey('gz-card-price-lock')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Voucher price after you sign up')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Save')), findsNothing);
    expect(find.textContaining('18,200'), findsOneWidget);
    expect(find.textContaining('15,400'), findsNothing);
    handle.dispose();
  });

  testWidgets('lean keeps headline and basis only; rental fee shows the key basis', (tester) async {
    await pumpCore(tester, const GzCardPriceLine(price: _exact, lean: true));
    expect(find.bySemanticsLabel(RegExp('Save')), findsNothing);
    expect(find.textContaining('18,200'), findsNothing);
    await pumpCore(tester, const GzCardPriceLine(price: _rental));
    expect(find.byIcon(GzIcons.key), findsOneWidget);
  });

  testWidgets('Arabic: the line starts at the right edge and the figures stay LTR', (tester) async {
    await pumpCore(tester, const SizedBox(width: 280, child: GzCardPriceLine(price: _exact, lean: true)), lang: 'ar');
        final price = tester.getRect(find.byType(GzPrice));
    final chip = tester.getRect(find.byType(GzFactChip));
    expect(price.right, closeTo(390, 1.5)); // pumpCore aligns the child to the start (right in RTL), view is 390 wide
    expect(chip.right, lessThan(price.left));
    expect(price.left - chip.right, closeTo(8, 0.5)); // column-gap 8
  });

  testWidgets('GzInlineSize hands the builder the available width', (tester) async {
    double? seen;
    await pumpCore(tester, SizedBox(width: 200, child: GzInlineSize(builder: (c, w) {
      seen = w;
      return const SizedBox();
    })));
    expect(seen, 200);
  });
}
