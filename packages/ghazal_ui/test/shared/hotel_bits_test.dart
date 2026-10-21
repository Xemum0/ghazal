import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/hotel/hotel_shared.dart';

import '../core/core_harness.dart';
import 'shared_harness.dart';

void main() {
  setUpAll(loadUiFonts);
  final en = GzFormat(locale: const Locale('en'));
  final ar = GzFormat(locale: const Locale('ar'));
  final lEn = lookupGzL10n(const Locale('en'));
  final lAr = lookupGzL10n(const Locale('ar'));

  group('clock helpers', () {
    test('timeRangeText on one day and across midnight', () {
      expect(en.plain(gzTimeRangeText(en, '2026-11-03', '09:00', '14:00')), contains('9:00'));
      expect(gzClockInstant(en, '2026-11-03', '21:30').toUtc(), DateTime.utc(2026, 11, 3, 18, 30));
      final across = gzTimeRangeText(en, '2026-11-03', '21:00', '02:00');
      expect(en.plain(across), allOf(contains('9:00'), contains('2:00')));
    });

    test('splitTime separates figure and suffix', () {
      expect(gzSplitTime(en, '9:00 PM'), (figure: '9:00', suffix: 'PM'));
      expect(gzSplitTime(en, '21:00'), (figure: '21:00', suffix: ''));
      expect(gzSplitTime(en, '\u2066٩:٠٠\u2069 م').figure, isNotEmpty);
    });
  });

  group('gzTimeLeft', () {
    test('visual drops a zero-minute tail and spoken is the long form', () {
      final t = gzTimeLeft(en, lEn, 180);
      expect(en.plain(t.visual), '3 h');
      expect(t.spoken, '3 hours');
      final u = gzTimeLeft(en, lEn, 200);
      expect(en.plain(u.visual), '3 h 20 m');
      expect(u.spoken, '3 hours 20 minutes');
    });

    test('days show no minutes; zero reads 0 minutes; negative clamps', () {
      expect(gzTimeLeft(en, lEn, 1440 + 125).spoken, '1 day 2 hours');
      expect(gzTimeLeft(en, lEn, 0).spoken, '0 minutes');
      expect(gzTimeLeft(en, lEn, -5).spoken, '0 minutes');
      expect(gzTimeLeft(en, lEn, 45).spoken, '45 minutes');
    });

    test('Arabic spoken uses the dual and the joiner', () {
      expect(gzTimeLeft(ar, lAr, 120).spoken, 'ساعتان');
      expect(gzTimeLeft(ar, lAr, 200).spoken, '3 ساعات و20 دقيقة');
    });

    test('remainingShare clamps to 0..1', () {
      expect(gzRemainingShare(0.25), 0.75);
      expect(gzRemainingShare(1.4), 0);
      expect(gzRemainingShare(-0.2), 1);
    });
  });

  group('gzParseKdToFils', () {
    test('integer fils, never a float', () {
      expect(gzParseKdToFils(en, '52'), 52000);
      expect(gzParseKdToFils(en, '52.5'), 52500);
      expect(gzParseKdToFils(en, '1,250.125'), 1250125);
      expect(gzParseKdToFils(en, '52.'), 52000);
    });

    test('Eastern digits and separators', () {
      expect(gzParseKdToFils(ar, '٥٢٫٥'), 52500);
      expect(gzParseKdToFils(ar, '١٬٢٥٠'), 1250000);
    });

    test('refuses non numbers and extra decimals', () {
      expect(gzParseKdToFils(en, ''), isNull);
      expect(gzParseKdToFils(en, 'abc'), isNull);
      expect(gzParseKdToFils(en, '1.2345'), isNull);
      expect(gzParseKdToFils(en, '-3'), isNull);
    });
  });

  group('GzUserText', () {
    test('script and first strong direction', () {
      expect(gzScriptOf('Sara'), 'en');
      expect(gzScriptOf('سارة'), 'ar');
      expect(gzFirstStrongOr('123 سارة', TextDirection.ltr), TextDirection.rtl);
      expect(gzFirstStrongOr('123', TextDirection.rtl), TextDirection.rtl);
      expect(gzFirstStrongOr('Sara سارة', TextDirection.rtl), TextDirection.ltr);
    });

    testWidgets('an Arabic name in the English UI orders RTL, sits at the screen start and takes the Arabic scale', (tester) async {
      await pumpCore(tester, const GzUserText('سارة المطيري', role: GzTextRole.body));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.textDirection, TextDirection.rtl);
      expect(tester.widget<Align>(find.descendant(of: find.byType(GzUserText), matching: find.byType(Align))).alignment, AlignmentDirectional.centerStart);
      expect(tester.getRect(find.byType(Text)).left, 0);
      expect(text.style!.fontFamily, contains('Almarai'));
    });

    testWidgets('a Latin name in the Arabic UI keeps the English scale and sits at the right edge', (tester) async {
      await pumpCore(tester, const GzUserText('Sara', role: GzTextRole.body), lang: 'ar');
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.textDirection, TextDirection.ltr);
      expect(tester.getRect(find.byType(Text)).right, 390);
      expect(text.style!.fontFamily, contains('Manrope'));
    });
  });
}
