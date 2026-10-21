import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart' show ThreadRole;
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/visits/visits_shared.dart';
import 'package:ghazal_ui/src/voucher/voucher_shared.dart';

import '../core/core_harness.dart';
import 'shared_harness.dart';

void main() {
  setUpAll(loadUiFonts);

  group('GzVoucherChip', () {
    testWidgets('shows only the last four characters, the word is the accessible name', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, const GzVoucherChip(code: 'GZ-2026-K7QM'));
      expect(find.textContaining('K7QM'), findsOneWidget);
      expect(find.textContaining('GZ-2026'), findsNothing);
      final node = tester.getSemantics(find.byType(GzVoucherChip));
      expect(node.label, 'Voucher K7QM');
      handle.dispose();
    });

    testWidgets('geometry matches the web chip (probe: icon 16 at 9, code 38.89 wide at 49, height 30)', (tester) async {
      await pumpCore(tester, const GzVoucherChip(code: 'K7QM'));
      final chip = tester.getRect(find.byType(GzVoucherChip));
      final icon = tester.getRect(find.byType(GzIcon));
      final code = tester.getRect(find.textContaining('K7QM'));
      expect(chip.height, closeTo(30, 1));
      expect(icon.left - chip.left, closeTo(9, 0.1));
      expect(code.left - chip.left, closeTo(29, 0.1)); // web code at x 49 - chip 20 = 29
      expect(code.width, closeTo(38.89, 1.5));
      expect(chip.width, closeTo(9 + 16 + 4 + 38.89 + 9, 1.5));
    });

    testWidgets('Arabic keeps the code an LTR island and mirrors the glyph side', (tester) async {
      await pumpCore(tester, const GzVoucherChip(code: 'K7QM'), lang: 'ar');
      final chip = tester.getRect(find.byType(GzVoucherChip));
      expect(tester.getRect(find.byType(GzIcon)).right, closeTo(chip.right - 9, 0.1));
      expect(chip.right, closeTo(390, 0.1));
    });

    testWidgets('every tone builds', (tester) async {
      for (final t in GzVoucherChipTone.values) {
        await pumpCore(tester, GzVoucherChip(code: 'AB12', tone: t));
        expect(find.textContaining('AB12'), findsOneWidget);
      }
    });
  });

  group('GzRoleBadge', () {
    testWidgets('names the role; "you" swaps the client chip', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, const GzRoleBadge(role: ThreadRole.client));
      expect(tester.getSemantics(find.byType(GzRoleBadge)).label, 'Client');
      await pumpCore(tester, const GzRoleBadge(role: ThreadRole.client, you: true));
      expect(tester.getSemantics(find.byType(GzRoleBadge)).label, 'You');
      await pumpCore(tester, const GzRoleBadge(role: ThreadRole.hotelRepresentative));
      expect(find.text('Hotel representative'), findsOneWidget);
      await pumpCore(tester, const GzRoleBadge(role: ThreadRole.support));
      expect(find.text('Ghazal support'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('24 high minimum, text only (no glyph), Arabic words', (tester) async {
      await pumpCore(tester, const GzRoleBadge(role: ThreadRole.hotelRepresentative), lang: 'ar');
      expect(find.byType(GzIcon), findsNothing);
      expect(find.text('ممثل الفندق'), findsOneWidget);
      expect(tester.getRect(find.byType(GzRoleBadge)).height, greaterThanOrEqualTo(24));
    });
  });

  group('gzConfirmLeft', () {
    final en = GzFormat(locale: const Locale('en'));
    final now = DateTime.utc(2026, 11, 3, 9);
    final l = lookupGzL10n(const Locale('en'));

    test('hours and minutes, rounded up to the minute', () {
      final r = gzConfirmLeft(en, l, deadline: now.add(const Duration(hours: 2, minutes: 4, seconds: 10)), now: now);
      expect(r.leftMin, 125);
      expect(r.text, '2 hours and 5 minutes remaining');
      expect(r.ended, isFalse);
      expect(r.lastHour, isFalse);
      expect(r.passed, closeTo(1 - 125 / 1440, 1e-9));
    });

    test('last hour says minutes only; exactly 60 is still the last hour', () {
      final r = gzConfirmLeft(en, l, deadline: now.add(const Duration(minutes: 60)), now: now);
      expect(r.lastHour, isTrue);
      expect(r.text, '1 hour remaining');
      expect(gzConfirmLeft(en, l, deadline: now.add(const Duration(minutes: 45)), now: now).text, '45 minutes remaining');
      expect(gzConfirmLeft(en, l, deadline: now.add(const Duration(minutes: 61)), now: now).lastHour, isFalse);
    });

    test('ended: empty text, passed = 1', () {
      final r = gzConfirmLeft(en, l, deadline: now.subtract(const Duration(minutes: 5)), now: now);
      expect(r.ended, isTrue);
      expect(r.leftMin, 0);
      expect(r.text, '');
      expect(r.passed, 1);
      expect(r.lastHour, isFalse);
    });

    test('a fresh 24 h window has passed = 0', () {
      final r = gzConfirmLeft(en, l, deadline: now.add(const Duration(hours: gzConfirmWindowHours)), now: now);
      expect(r.passed, 0);
      expect(r.text, '24 hours remaining');
    });

    test('Arabic uses the shared words', () {
      final ar = GzFormat(locale: const Locale('ar'));
      final r = gzConfirmLeft(ar, lookupGzL10n(const Locale('ar')), deadline: now.add(const Duration(hours: 3)), now: now);
      expect(ar.plain(r.text), contains('3 ساعات'));
    });
  });
}
