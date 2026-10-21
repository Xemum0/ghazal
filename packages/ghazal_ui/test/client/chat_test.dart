import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ThreadRole;
import 'package:ghazal_ui/src/client/client_c.dart';
import 'package:ghazal_ui/src/client/gz_chat_parts.dart' show gzWaveform;
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/visits/gz_role_badge.dart';

import '../core/core_harness.dart';
import '../shared/shared_harness.dart';
import 'client_c_fixtures.dart';

const _hello = 'مرحبا، هل الموعد متاح؟';

Future<void> _pump(WidgetTester tester, Widget child, {String lang = 'en'}) =>
    pumpCore(tester, SingleChildScrollView(child: SizedBox(width: 350, child: child)), lang: lang, size: const Size(350, 1200));

void main() {
  setUpAll(loadUiFonts);

  test('waveform: 28 bars from the 4-pt scale, stable per message id', () {
    final a = gzWaveform('msg-019');
    expect(a.length, 28);
    expect(a.every((h) => const [4.0, 8.0, 12.0, 16.0, 20.0, 24.0].contains(h)), isTrue);
    expect(gzWaveform('msg-019'), a);
    expect(gzWaveform('msg-003'), isNot(a));
    expect(a.toSet().length, greaterThan(2)); // a real waveform, not a flat line
  });

  group('GzChatBubble', () {
    testWidgets('own sits at inline-end, received at inline-start, with the 48 reserve on the other side (LTR)', (tester) async {
      await _pump(tester, GzChatBubble(message: message(from: 'client', ar: _hello, en: 'Hello')));
      final own = tester.getRect(find.text(_hello));
      expect(own.right, lessThanOrEqualTo(350 - 16));
      expect(own.right, greaterThan(350 - 40));
      await _pump(tester, GzChatBubble(message: message(from: 'venue', ar: _hello, en: 'Hello')));
      final other = tester.getRect(find.text(_hello));
      expect(other.left, greaterThanOrEqualTo(16));
      expect(other.left, lessThan(40));
    });

    testWidgets('RTL mirrors: own hugs the left edge, received the right', (tester) async {
      await _pump(tester, GzChatBubble(message: message(from: 'client', ar: _hello, en: 'Hello')), lang: 'ar');
      expect(tester.getRect(find.text(_hello)).left, lessThan(40));
      await _pump(tester, GzChatBubble(message: message(from: 'venue', ar: _hello, en: 'Hello')), lang: 'ar');
      expect(tester.getRect(find.text(_hello)).right, greaterThan(350 - 40));
    });

    testWidgets('the time stays an LTR figure island in Arabic and the delivery tick only shows on own messages', (tester) async {
      await _pump(tester, GzChatBubble(message: message(from: 'client', ar: _hello, en: 'Hello')), lang: 'ar');
      final time = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').firstWhere((d) => d.contains(':'));
      expect(time.startsWith('\u2066'), isTrue);
      expect(find.byIcon(GzIcons.checkDouble), findsOneWidget);
      await _pump(tester, GzChatBubble(message: message(from: 'venue', ar: _hello, en: 'Hello')), lang: 'ar');
      expect(find.byIcon(GzIcons.checkDouble), findsNothing);
      expect(find.byIcon(GzIcons.check), findsNothing);
      await _pump(tester, GzChatBubble(message: message(from: 'client', ar: _hello, en: 'Hello', status: 'sent')));
      expect(find.byIcon(GzIcons.check), findsOneWidget);
    });

    testWidgets('showMeta false hides the time; a draft says Draft', (tester) async {
      await _pump(tester, GzChatBubble(message: message(ar: _hello, en: 'Hello'), showMeta: false));
      expect(find.byIcon(GzIcons.checkDouble), findsNothing);
      await _pump(tester, GzChatBubble(message: message(ar: _hello, en: 'Hello', draft: true)));
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('text is set in its own language: an Arabic message in an English thread keeps the Arabic face', (tester) async {
      await _pump(tester, GzChatBubble(message: message(origin: 'ar', ar: _hello, en: 'Hello')));
      expect(tester.widget<Text>(find.text(_hello)).style!.fontFamily, contains('Almarai'));
      await _pump(tester, GzChatBubble(message: message(origin: 'en', ar: 'مرحبا', en: 'Hello there')), lang: 'ar');
      expect(tester.widget<Text>(find.text('Hello there')).style!.fontFamily, contains('Manrope'));
    });

    testWidgets('a system line is centred; with group it follows the viewer language and carries a glyph', (tester) async {
      await _pump(tester, GzChatBubble(message: message(from: 'system', kind: 'system', origin: 'en', en: 'Handled by Hind', ar: 'يتابع هند')));
      final r = tester.getRect(find.text('Handled by Hind'));
      expect((r.center.dx - 175).abs(), lessThan(1));
      await _pump(tester, GzChatBubble(message: message(from: 'system', kind: 'system', origin: 'en', en: 'Handled by Hind', ar: 'يتابع هند'), group: true), lang: 'ar');
      expect(find.text('يتابع هند'), findsOneWidget);
      expect(find.byIcon(GzIcons.info), findsOneWidget);
    });

    testWidgets('group chat: the sender name and role badge sit above the bubble', (tester) async {
      await _pump(tester, GzChatBubble(message: message(from: 'venue', ar: _hello, en: 'Hello'), sender: const GzChatSender(name: 'Hind', role: ThreadRole.hotelRepresentative)));
      expect(find.text('Hind'), findsOneWidget);
      expect(find.byType(GzRoleBadge), findsOneWidget);
      expect(tester.getRect(find.text('Hind')).top, lessThan(tester.getRect(find.text(_hello)).top));
    });

    testWidgets('voice: one play button that toggles by name and fires onPlay; 44 dp target', (tester) async {
      final handle = tester.ensureSemantics();
      var plays = 0;
      final voice = message(from: 'venue', kind: 'voice', extra: {'voice': {'seconds': 21}});
      await _pump(tester, GzChatBubble(message: voice, onPlay: () => plays++));
      expect(find.bySemanticsLabel(RegExp('Play voice message')), findsOneWidget);
      expect(find.textContaining('0:21'), findsOneWidget);
      await tester.tap(find.byIcon(GzIcons.play));
      expect(plays, 1);
      await _pump(tester, GzChatBubble(message: voice, playing: true, progress: 0.4, onPlay: () => plays++));
      expect(find.bySemanticsLabel(RegExp('Pause voice message')), findsOneWidget);
      expect(find.byIcon(GzIcons.pause), findsOneWidget);
      handle.dispose();
    });

    testWidgets('document: file name as an LTR isolate with size; card: title and lines', (tester) async {
      await _pump(tester, GzChatBubble(message: message(from: 'vendor', kind: 'document', extra: {'document': {'name': 'Quotation-Lamha.pdf', 'sizeKb': 38, 'mime': 'application/pdf'}})));
      expect(find.text('Quotation-Lamha.pdf'), findsOneWidget);
      expect(find.textContaining('38'), findsWidgets);
      expect(find.byIcon(GzIcons.download), findsOneWidget);
      await _pump(tester, GzChatBubble(message: message(from: 'planner', kind: 'meeting_card', extra: {'card': {'kind': 'meeting', 'title': {'en': 'Video call', 'ar': 'مكالمة فيديو'}, 'lines': [{'en': 'Sun 15 Nov', 'ar': 'الأحد 15 نوفمبر'}]}})));
      expect(find.text('Video call'), findsOneWidget);
      expect(find.byIcon(GzIcons.calendar), findsOneWidget);
    });

    testWidgets('reduced motion: no transform is introduced by the bubble', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzChatBubble(message: message(ar: _hello, en: 'Hello'))), reduceMotion: true);
      expect(find.descendant(of: find.byType(GzChatBubble), matching: find.byType(AnimatedScale)), findsNothing);
    });
  });

  testWidgets('GzChatDateDivider says the day through the formatter', (tester) async {
    await _pump(tester, const GzChatDateDivider(date: '2026-11-12'));
    expect(find.byType(GzChatDateDivider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('GzConversationRow', () {
    testWidgets('unread shows the gold count with its spoken name; the row opens', (tester) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await _pump(tester, GzConversationRow(conversation: conversation(unread: 2), last: message(from: 'planner', ar: _hello, en: 'Hi'), onOpen: () => opened++));
      expect(find.byType(GzCountBadge), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('2 unread messages')), findsOneWidget);
      await tester.tap(find.byType(GzConversationRow));
      expect(opened, 1);
      handle.dispose();
    });

    testWidgets('read and pinned shows the pin, read and not pinned shows neither; own last message is prefixed "You:"', (tester) async {
      await _pump(tester, GzConversationRow(conversation: conversation(pinned: true), last: message(from: 'client', ar: _hello, en: 'Hi')));
      expect(find.byType(GzCountBadge), findsNothing);
      expect(find.byIcon(GzIcons.bookmark), findsOneWidget);
      expect(find.text('You:'), findsOneWidget);
      await _pump(tester, GzConversationRow(conversation: conversation(), last: message(from: 'planner', ar: _hello, en: 'Hi')));
      expect(find.byIcon(GzIcons.bookmark), findsNothing);
      expect(find.text('You:'), findsNothing);
    });

    testWidgets('no last message falls back to the subtitle; a voice note previews as "Voice message 0:21"', (tester) async {
      await _pump(tester, GzConversationRow(conversation: conversation()));
      expect(find.textContaining('Meeting Sun'), findsOneWidget);
      await _pump(tester, GzConversationRow(conversation: conversation(), last: message(from: 'venue', kind: 'voice', extra: {'voice': {'seconds': 21}})));
      expect(find.textContaining('Voice message'), findsOneWidget);
    });

    testWidgets('Arabic: the monogram is the Arabic letter and the time column hugs inline-end (left)', (tester) async {
      await _pump(tester, GzConversationRow(conversation: conversation(unread: 1)), lang: 'ar');
      expect(find.text('ن'), findsOneWidget);
      expect(tester.getRect(find.byType(GzCountBadge)).left, lessThan(60));
    });
  });
}
