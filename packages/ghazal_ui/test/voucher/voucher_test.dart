import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show PriceStructure;
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/voucher/voucher.dart';

import 'voucher_harness.dart';

/// A Text (plain or rich, isolates removed) that contains [s].
Finder _text(String s) => find.byWidgetPredicate((w) => w is Text && GzBidi.strip(w.data ?? w.textSpan?.toPlainText() ?? '').contains(s));

void main() {
  group('GzQrCode', () {
    test('encodes the signed payload exactly like the web generator (29 modules, error correction M)', () {
      final m = gzQrModules('gz:v1:GV-2611-K7QM:V01:CBDA');
      expect(m.count, 29);
      String row(int r) => [for (var c = 0; c < m.count; c++) m.dark[r * m.count + c] ? '#' : '.'].join();
      expect(row(0), '#######..###...###.#..#######');
      expect(row(1), '#.....#....##....##.#.#.....#');
    });

    test('the payload carries the voucher code, so a scan resolves the voucher', () {
      final v = boundVoucher();
      expect(v.qr.payload, contains(v.code));
    });

    testWidgets('is one image named by the label and never exposes the payload', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpVoucher(tester, const GzQrCode(payload: 'gz:v1:GV-2611-K7QM:V01:CBDA', label: 'QR code of voucher GV-2611-K7QM'));
      final node = tester.getSemantics(find.byType(GzQrCode));
      expect(node.label, 'QR code of voucher GV-2611-K7QM');
      expect(node.label, isNot(contains('gz:v1')));
      handle.dispose();
    });

    testWidgets('draws at the requested size, muted or not', (tester) async {
      await pumpVoucher(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzQrCode(payload: 'gz:v1:A:V01:1', label: 'a', size: 96),
            GzQrCode(payload: 'gz:v1:A:V01:1', label: 'a', muted: true),
          ],
        ),
      );
      final sizes = tester.widgetList<GzQrCode>(find.byType(GzQrCode)).map((w) => tester.getSize(find.byWidget(w))).toList();
      expect(sizes.first, const Size(96, 96));
      expect(sizes.last, const Size(144, 144));
    });
  });

  group('GzVoucherCard', () {
    testWidgets('full: the code is a left-to-right figure, the quote shows both prices and the state is the pill word', (tester) async {
      await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(), targetName: 'Aurelia Gulf Hotel', packageName: 'Ladies’ Reception, Weekend'));
      expect(_text('GV-2611-K7QM'), findsOneWidget);
      expect(_text('Aurelia Gulf Hotel'), findsOneWidget);
      expect(_text('In request'), findsOneWidget);
      expect(find.byType(GzStruckMoney), findsOneWidget);
      expect(find.byType(GzQrCode), findsOneWidget);
      final code = tester.widget<Text>(_text('GV-2611-K7QM'));
      expect(code.data!.startsWith(GzBidi.lri) && code.data!.endsWith(GzBidi.pdi), isTrue);
    });

    testWidgets('Copy always fires; Full screen is only for a live voucher', (tester) async {
      var copied = 0, full = 0;
      await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(), targetName: 'A', onCopy: () => copied++, onShowFull: () => full++));
      await tester.tap(_text('Copy'));
      await tester.tap(_text('Full screen'));
      expect((copied, full), (1, 1));
      await pumpVoucher(
        tester,
        GzVoucherCard(voucher: boundVoucher(status: 'used', usedAt: '2026-11-20T10:00:00+03:00'), targetName: 'A', onCopy: () => copied++, onShowFull: () => full++),
      );
      expect(_text('Full screen'), findsNothing);
      expect(_text('Copy'), findsOneWidget);
    });

    testWidgets('every state has its pill word; forfeited says why, a credit voucher is unbound', (tester) async {
      const words = {
        'unpaid': 'Paying',
        'active': 'Ready',
        'bound': 'In request',
        'used': 'Used',
        'expired': 'Expired',
        'forfeited': 'Not valid',
        'credit_issued': 'Credit issued',
      };
      for (final e in words.entries) {
        await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(status: e.key), targetName: 'A'));
        expect(_text(e.value), findsWidgets, reason: e.key);
        expect(_text('Not confirmed within 24 hours'), e.key == 'forfeited' ? findsOneWidget : findsNothing);
      }
      await pumpVoucher(tester, GzVoucherCard(voucher: creditVoucher()));
      expect(_text('Credit voucher'), findsWidgets);
      expect(_text('Any hall, hotel or service'), findsOneWidget);
      expect(find.byType(GzStruckMoney), findsNothing, reason: 'a credit voucher has no quote');
    });

    testWidgets('compact: one 64 dp target when opened, not a button without onOpen', (tester) async {
      var opened = 0;
      await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(), variant: GzVoucherCardVariant.compact, targetName: 'Aurelia', onOpen: () => opened++));
      expect(tester.getSize(find.byType(GzVoucherCard)).height, greaterThanOrEqualTo(64));
      expect(find.byType(GzQrCode), findsNothing);
      await tester.tap(_text('Aurelia'));
      expect(opened, 1);
      await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(), variant: GzVoucherCardVariant.compact, targetName: 'Aurelia'));
      expect(find.byType(GzPressable), findsNothing);
    });

    testWidgets('slim: QR, code and two actions, a state pill only when the voucher is no longer live', (tester) async {
      await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(), variant: GzVoucherCardVariant.slim, targetName: 'A', onCopy: () {}, onShowFull: () {}));
      expect(find.byType(GzStatusPill), findsNothing);
      await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(status: 'expired'), variant: GzVoucherCardVariant.slim, targetName: 'A'));
      expect(find.byType(GzStatusPill), findsOneWidget);
    });

    testWidgets('the two actions are 44 dp targets at least', (tester) async {
      await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(), targetName: 'A', onCopy: () {}, onShowFull: () {}));
      for (final label in ['Copy', 'Full screen']) {
        final size = tester.getSize(find.ancestor(of: _text(label), matching: find.byType(GzPressable)).first);
        expect(size.height, greaterThanOrEqualTo(44), reason: label);
        expect(size.width, greaterThanOrEqualTo(44), reason: label);
      }
    });

    testWidgets('semantics: one node named by the voucher, its code, target and state; actions stay buttons', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(), targetName: 'Aurelia Gulf Hotel', onCopy: () {}));
      final label = tester.getSemantics(find.byType(GzVoucherCard)).label;
      expect(label, allOf(contains('Voucher'), contains('GV-2611-K7QM'), contains('Aurelia Gulf Hotel'), contains('In request')));
      expect(find.bySemanticsLabel('Copy'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Arabic: the card mirrors, the code and the figures stay left to right', (tester) async {
      await pumpVoucher(tester, GzVoucherCard(voucher: boundVoucher(), targetName: 'فندق أوريليا الخليج'), lang: 'ar');
      final qr = tester.getTopRight(find.byType(GzQrCode));
      final card = tester.getRect(find.byType(GzVoucherCard));
      expect(card.right - qr.dx, lessThan(40), reason: 'the QR sits at the inline-start (right) edge');
      final code = tester.widget<Text>(_text('GV-2611-K7QM'));
      expect(code.data!.startsWith(GzBidi.lri), isTrue);
    });
  });

  group('GzPriceCompare', () {
    const standard = 18200000;
    const voucherFils = 15400000;
    Widget pc({
      int? voucher = voucherFils,
      GzPriceCompareAudience audience = GzPriceCompareAudience.member,
      GzPriceCompareVariant variant = GzPriceCompareVariant.stack,
      VoidCallback? onRegister,
    }) => GzPriceCompare(
      standard: standard,
      voucher: voucher,
      structure: PriceStructure.package,
      guests: 350,
      audience: audience,
      variant: variant,
      onRegister: onRegister,
    );

    testWidgets('member: the voucher price is the headline, the standard price struck, the saving a figure', (tester) async {
      await pumpVoucher(tester, pc());
      expect(find.byType(GzPrice), findsOneWidget);
      expect(find.byType(GzStruckMoney), findsOneWidget);
      expect(_text('2,800'), findsOneWidget);
      expect(find.byType(GzIconButton), findsOneWidget, reason: 'the net-saving info glyph');
    });

    testWidgets('guest: the voucher price is locked behind sign-up and the action fires', (tester) async {
      var signed = 0;
      await pumpVoucher(tester, pc(audience: GzPriceCompareAudience.guest, onRegister: () => signed++));
      expect(find.byType(GzPrice), findsNothing, reason: 'no voucher headline for a guest');
      expect(find.byType(GzStruckMoney), findsOneWidget, reason: 'the standard price stays visible');
      await tester.tap(_text('Sign up'));
      expect(signed, 1);
    });

    testWidgets('no voucher price: the standard price alone, no strike, no saving, no lock', (tester) async {
      await pumpVoucher(tester, pc(voucher: null));
      expect(find.byType(GzPrice), findsOneWidget);
      expect(find.byType(GzStruckMoney), findsNothing);
      expect(find.byType(GzIconButton), findsNothing);
      expect(_text('18,200'), findsOneWidget);
    });

    testWidgets('the info glyph opens the net saving after the KD 2 voucher and meets the 44 dp target', (tester) async {
      await pumpVoucher(tester, pc());
      final size = tester.getSize(find.byType(GzIconButton));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      await tester.tap(find.byType(GzIconButton));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_text('after the'), findsOneWidget);
    });

    testWidgets('inline: one wrapped line without the info glyph', (tester) async {
      await pumpVoucher(tester, pc(variant: GzPriceCompareVariant.inline));
      expect(find.byType(GzIconButton), findsNothing);
      expect(find.byType(GzStruckMoney), findsOneWidget);
    });
  });

  group('GzVoucherPurchaseSummary', () {
    testWidgets('one amount paid to Ghazal, the rest off-app, no deposit, balance or refund wording', (tester) async {
      await pumpVoucher(
        tester,
        GzVoucherPurchaseSummary(
          targetName: 'Aurelia Gulf Hotel',
          packageName: 'Ladies’ Reception, Weekend',
          eventDate: boundVoucher().eventDate,
          guests: 350,
          standardFils: 18200000,
          voucherFils: 15400000,
        ),
      );
      expect(_text('You pay Ghazal today'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is GzPrice && w.fils == 2000 && w.mode == GzMoneyMode.exact), findsOneWidget, reason: 'KD 2.000, once');
      expect(_text('directly'), findsOneWidget);
      for (final banned in ['deposit', 'balance', 'refund', 'back']) {
        expect(find.byWidgetPredicate((w) => w is Text && RegExp(banned, caseSensitive: false).hasMatch(w.data ?? w.textSpan?.toPlainText() ?? '')), findsNothing, reason: banned);
      }
      expect(_text('credit voucher'), findsOneWidget);
      expect(_text('60 days'), findsOneWidget);
      expect(_text('days days'), findsNothing);
    });
  });

  group('GzConfirmWindow', () {
    final deadline = DateTime.parse('2026-11-13T16:00:00+03:00');
    DateTime at(String s) => DateTime.parse(s);

    testWidgets('open: hours and minutes left, the held line and the one primary action', (tester) async {
      var confirmed = 0;
      await pumpVoucher(tester, GzConfirmWindow(deadline: deadline, now: at('2026-11-12T16:20:00+03:00'), onConfirm: () => confirmed++));
      expect(_text('23 hours and 40 minutes remaining'), findsOneWidget);
      expect(_text('The date is held for you'), findsOneWidget);
      await tester.tap(_text('Confirm booking'));
      expect(confirmed, 1);
    });

    testWidgets('the last hour speaks in minutes only and never in seconds', (tester) async {
      await pumpVoucher(tester, GzConfirmWindow(deadline: deadline, now: at('2026-11-13T15:15:00+03:00')));
      expect(_text('45 minutes remaining'), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && RegExp('second', caseSensitive: false).hasMatch(w.data ?? w.textSpan?.toPlainText() ?? '')), findsNothing);
      expect(_text('Confirm booking'), findsNothing, reason: 'no action unless the screen asks for one');
    });

    testWidgets('lapsed: the window closed and the voucher is no longer valid, never free to reuse', (tester) async {
      await pumpVoucher(tester, GzConfirmWindow(deadline: deadline, now: at('2026-11-13T16:30:00+03:00'), onConfirm: () {}));
      expect(_text('The confirm window ended'), findsOneWidget);
      expect(_text('no longer valid'), findsOneWidget);
      expect(_text('Confirm booking'), findsNothing);
    });

    testWidgets('confirmed: says when, and offers no action', (tester) async {
      await pumpVoucher(tester, GzConfirmWindow(deadline: deadline, confirmedAt: at('2026-11-12T18:05:00+03:00'), onConfirm: () {}));
      expect(_text('You confirmed this booking'), findsOneWidget);
      expect(_text('Confirmed on'), findsOneWidget);
      expect(_text('Confirm booking'), findsNothing);
    });

    testWidgets('the thread bar reports the passed share and is never an alarm colour', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpVoucher(tester, GzConfirmWindow(deadline: deadline, now: at('2026-11-13T04:00:00+03:00')));
      expect(find.bySemanticsLabel('Share of the confirm window that has passed'), findsOneWidget);
      final colors = tester.widgetList<ColoredBox>(find.descendant(of: find.byType(GzConfirmWindow), matching: find.byType(ColoredBox))).map((b) => b.color).toSet();
      final c = GzColors.light;
      expect(colors, isNot(contains(c.statusDangerBg)));
      expect(colors, contains(c.markKhayt));
      handle.dispose();
    });

    testWidgets('Arabic and reduced motion render the same calm block', (tester) async {
      await pumpVoucher(tester, GzConfirmWindow(deadline: deadline, now: at('2026-11-12T16:20:00+03:00')), lang: 'ar', reduceMotion: true);
      expect(find.byType(GzConfirmWindow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
