// J5 (partner): a tour of the whole app in English and in Arabic, as a manager using it everywhere.
//
//   every tab (data loaded, no error state, no skeleton left, the tab bar in reading order), the long lists (Today, Bookings, the Calendar
//   in month and week view) flung down and up with frame timings printed, a day picked in the calendar, one sheet of each kind (Block
//   date, Decline request), a pushed screen and back (New price), the undo toast of an Accept, a dialog (Log out? with Cancel), and a text
//   field with the keyboard open (the chat composer, then Send). The back button sits at the inline-start edge; on an iPhone the edge
//   swipe from that edge goes back. The journey fails on any framework error: an overflow or a build error anywhere is a failure.
// Run: `node apps/provider_app/integration_test/headless.mjs j5` (both languages run), or on a simulator
// `flutter test integration_test/j5_tour_test.dart -d <id>` from apps/provider_app (look at the printed [frames] lines there).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerRequestsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus;
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:provider_app/l10n/generated/app_localizations.dart' show AppL10n;

import 'support/journey_world.dart';
import 'support/tour.dart';

const String kHero = 'bk-GZ-2611-0147';

void main() {
  journeySetUp();
  for (final lang in const ['en', 'ar']) {
    journey('J5 partner tour ($lang): every tab, sheets, dialog, toast, keyboard, scroll, back', (j) async {
      final c = await j.start(persona: 'hotel_manager');
      await j.useLanguage(lang);
      String t(String Function(AppL10n l) pick) => j.t(pick);
      Finder tab(String id) => find.byKey(ValueKey<String>('gz:tab.$id'));
      Finder key(String k) => find.byKey(ValueKey<String>(k));
      Future<BookingStatus> serverStatus() async => (await c.read(partnerRequestsRepositoryProvider).getPartnerRequest(requestId: kHero)).booking.status;

      // ---------------------------------------------------------------------------------------------------------- tabs
      j.step('every tab loads its data and the bar reads in the language direction');
      for (final (id, root) in const [('today', 'HL-TODY-01'), ('bookings', 'HL-BOOK-01'), ('calendar', 'HL-CALN-01'), ('messages', 'HL-TODY-04'), ('more', 'HL-SETT-01'), ('today', 'HL-TODY-01')]) {
        final empty = await j.openTab(id, root);
        expect(empty, 0, reason: 'the hotel has data on $root');
      }
      expect(j.startsBefore(tab('today'), tab('more')), isTrue, reason: 'Today is the first tab at the inline-start edge');
      expect(Directionality.of(j.tester.element(find.byType(GzScreen).first)), lang == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      // ---------------------------------------------------------------------------------------------------------- long lists
      j.step('Today: the long list flung down and up');
      await j.flingList('partner today ($lang)');
      j.step('Bookings: the long list flung down and up');
      await j.openTab('bookings', 'HL-BOOK-01');
      await j.flingList('partner bookings ($lang)');
      j.step('Calendar: a day picked by its name, the month and week views flung down and up');
      await j.openTab('calendar', 'HL-CALN-01');
      await j.tapNamed(RegExp('^${RegExp.escape(j.format.plain(j.format.date('2026-11-14', DateStyle.short)))}'), wait: const Duration(seconds: 1));
      await j.flingList('partner calendar month ($lang)');
      await j.tapText(t((l) => l.hotelCalendarViewWeek), wait: const Duration(seconds: 1));
      await j.loaded();
      await j.flingList('partner calendar week ($lang)');
      await j.tapText(t((l) => l.hotelCalendarViewMonth), wait: const Duration(seconds: 1));
      await j.loaded();

      // ---------------------------------------------------------------------------------------------------------- sheets, back
      j.step('sheet: Block date from Today, dismissed by a tap on the dim');
      await j.openTab('today', 'HL-TODY-01');
      await j.tapText(t((l) => l.hotelTodayBlockDate), wait: const Duration(seconds: 2));
      await j.seeScreen('HL-CALN-04');
      await j.loaded();
      await j.dismissSheet();
      j.step('pushed screen and back: New price opens a full screen, back returns to Today');
      await j.tapText(t((l) => l.hotelTodayNewPrice), wait: const Duration(seconds: 2));
      await j.seeScreen('HL-GROW-02');
      await j.loaded();
      final backX = j.tester.getCenter(key('gz:bar.back').first).dx;
      expect(lang == 'ar' ? backX > j.width / 2 : backX < j.width / 2, isTrue, reason: 'the back button sits at the inline-start edge');
      await j.goBack();
      await j.seeScreen('HL-TODY-01');

      j.step('request detail, the Decline sheet, and the Accept toast with Undo');
      await j.openTab('bookings', 'HL-BOOK-01');
      final card = key('triage.$kHero');
      await j.tap(find.descendant(of: card, matching: find.byType(GzPressable)).first, wait: const Duration(seconds: 2));
      await j.seeScreen('HL-BOOK-03');
      await j.loaded();
      await j.tapText(t((l) => l.commonActionDecline), wait: const Duration(seconds: 2));
      await j.seeScreen('HL-DCSN-02');
      await j.loaded();
      await j.dismissSheet();
      await j.tapText(t((l) => l.commonActionAccept), wait: const Duration(milliseconds: 1500));
      await j.see(find.byType(GzUndoBar), why: 'the Approved toast');
      await j.tapText(t((l) => l.commonActionUndo), wait: const Duration(seconds: 2));
      expect(await serverStatus(), BookingStatus.pending, reason: 'Undo took the approval back');
      await j.goBack();
      await j.seeScreen('HL-BOOK-01');

      // ---------------------------------------------------------------------------------------------------------- keyboard
      j.step('keyboard: the chat composer with the keyboard up stays in view; Send; the reply arrives; the keyboard goes away');
      await j.openTab('messages', 'HL-TODY-04');
      await j.tap(find.textContaining('ريم الدوسري', findRichText: true), wait: const Duration(seconds: 2));
      await j.seeScreen('HL-TODY-05');
      await j.loaded();
      await j.openKeyboard(0);
      final hello = lang == 'ar' ? 'أهلاً بكم' : 'Welcome to Aurelia';
      await j.tester.enterText(find.byType(EditableText).first, hello);
      await j.pump(const Duration(milliseconds: 600));
      expect(j.focusedFieldVisible(), isTrue, reason: 'the composer is above the keyboard');
      await j.tapNamed(t((l) => l.commonActionSend), wait: const Duration(seconds: 1));
      await j.see(find.textContaining(hello, findRichText: true), why: 'the sent message in the thread');
      await j.pump(const Duration(milliseconds: 3500));
      await j.closeKeyboard();
      await j.goBack();
      await j.seeScreen('HL-TODY-04');

      // ---------------------------------------------------------------------------------------------------------- dialog
      j.step('dialog: Log out asks first, Cancel keeps the manager signed in');
      await j.openTab('more', 'HL-SETT-01');
      await j.tapKey('more.logout', wait: const Duration(seconds: 1));
      await j.see(find.byType(GzDialog));
      await j.tapText(t((l) => l.commonActionCancel), wait: const Duration(seconds: 1));
      await j.gone(find.byType(GzDialog));
      expect(j.screen, 'HL-SETT-01');
    });
  }
}
