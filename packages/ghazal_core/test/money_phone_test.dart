import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart';

void main() {
  group('Money', () {
    test('integer fils, JSON round trip, arithmetic and compare', () {
      const a = Money.kwd(2000);
      expect(a.toJson(), {'fils': 2000, 'currency': 'KWD'});
      expect(Money.fromJson(a.toJson()), a);
      expect(Money.fromJson({'amount_fils': 500}), const Money.kwd(500));
      expect(a + const Money.kwd(500), const Money.kwd(2500));
      expect(a - const Money.kwd(2500), const Money.kwd(-500));
      expect(a * 350, const Money.kwd(700000));
      expect(-a, const Money.kwd(-2000));
      expect(Money.major(2), a);
      expect(a > const Money.kwd(1), isTrue);
      expect(Money.sum([a, a, a]), const Money.kwd(6000));
      expect([const Money.kwd(3), const Money.kwd(1)]..sort(), [const Money.kwd(1), const Money.kwd(3)]);
    });

    test('refuses floats and mixed currencies', () {
      expect(() => Money.fromJson({'fils': 18.5}), throwsFormatException);
      expect(() => Money.fromJson({'fils': 'x'}), throwsFormatException);
      expect(() => const Money.kwd(1) + const Money(1, CurrencyCode.sar), throwsArgumentError);
    });

    test('money formats through GzFormat.moneyOf with the value currency', () {
      final en = GzFormat(locale: const Locale('en'));
      expect(en.moneyOf(const Money.kwd(2000)), 'KD 2,000'.replaceAll('2,000', '2'));
      expect(en.moneyOf(const Money(1850, CurrencyCode.sar), mode: MoneyMode.exact), 'SAR 18.50');
    });
  });

  group('PhoneKw', () {
    test('normalises, validates, groups', () {
      expect(PhoneKw.normalizeInput('+965 5123 4567'), '51234567');
      expect(PhoneKw.normalizeInput('٠٠٩٦٥ ٥١٢٣ ٤٥٦٧'), '51234567');
      expect(PhoneKw.isValid('41234567'), isTrue);
      expect(PhoneKw.isValid('12345678'), isFalse);
      expect(PhoneKw.toE164('5123 4567'), '+96551234567');
      expect(PhoneKw.format('51234567'), '\u2066+965 5123 4567\u2069');
      expect(PhoneKw.whatsappHref('51234567'), 'https://wa.me/96551234567');
      expect(PhoneKw.telHref('1234'), isNull);
    });
  });

  group('DigitNormalizingFormatter', () {
    test('turns Arabic-Indic and Persian digits into ASCII and keeps the selection', () {
      const f = DigitNormalizingFormatter();
      final out = f.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '٥١٢۳٤٥٦٧', selection: TextSelection.collapsed(offset: 8)),
      );
      expect(out.text, '51234567');
      expect(out.selection.baseOffset, 8);
      const same = TextEditingValue(text: '123');
      expect(f.formatEditUpdate(TextEditingValue.empty, same), same);
    });
  });

  group('bidi and digit style', () {
    test('isolates, plain text and digit-only conversion', () {
      expect(plainText(isolateLtr('5')), '5');
      expect(isolateLtr('5'), '$kLri' '5' '$kPdi');
      expect(easternDigitsOnly('3 ضيوف, 12.5'), '٣ ضيوف, ١٢.٥');
      final ar = GzFormat(locale: const Locale('ar'), digitStyle: DigitStyle.easternArabic);
      expect(ar.digits('12'), '١٢');
      final en = GzFormat(locale: const Locale('en'), digitStyle: DigitStyle.easternArabic);
      expect(en.digitStyle, DigitStyle.western);
      expect(en.digits('12'), '12');
    });
  });
}
