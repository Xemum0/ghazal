// J5 (client): a tour of the whole app in English and in Arabic, as a person using it everywhere.
//
//   every tab (data loaded, no error state, no skeleton left, the tab bar in reading order), the long lists (Home, Results) flung down and
//   up with frame timings printed, one sheet of each kind (Brief sheet, Filters, Sort, date picker), the full-screen gallery viewer, a dialog
//   (Sign out? with Stay), an undo toast, a text field with the keyboard open (a chat composer), and back navigation (the back button
//   sits at the inline-start edge; on an iPhone the edge swipe from that edge). The journey fails on any framework error, so an overflow or a
//   build error anywhere on the way is a failure.
// Run: `node apps/client_app/integration_test/headless.mjs j5` (both languages run), or on a simulator
// `flutter test integration_test/j5_tour_test.dart -d <id>` from apps/client_app (look at the printed [frames] lines there).
import 'package:client_app/l10n/generated/app_localizations.dart' show AppL10n;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'support/journey_world.dart';
import 'support/tour.dart';

void main() {
  journeySetUp();
  for (final lang in const ['en', 'ar']) {
    journey('J5 client tour ($lang): every tab, sheets, dialog, toast, keyboard, scroll, back', (j) async {
      await j.start(persona: 'reem');
      await j.useLanguage(lang);
      String t(String Function(AppL10n l) pick) => j.t(pick);
      Finder tab(String id) => find.byKey(ValueKey<String>('gz:tab.$id'));
      Finder key(String k) => find.byKey(ValueKey<String>(k));

      // ---------------------------------------------------------------------------------------------------------- tabs
      j.step('every tab loads its data and the bar reads in the language direction');
      for (final (id, root) in const [('discover', 'CL-DISC-01'), ('saved', 'CL-SAVD-01'), ('my-wedding', 'CL-WEDD-01'), ('messages', 'CL-MSGS-01'), ('profile', 'CL-PROF-01'), ('discover', 'CL-DISC-01')]) {
        final empty = await j.openTab(id, root);
        expect(empty, 0, reason: 'the hero couple has data on $root');
      }
      expect(j.startsBefore(tab('discover'), tab('profile')), isTrue, reason: 'Discover is the first tab at the inline-start edge');
      expect(Directionality.of(j.tester.element(find.byType(GzScreen).first)), lang == 'ar' ? TextDirection.rtl : TextDirection.ltr);

      // ---------------------------------------------------------------------------------------------------------- Home, Results, back
      j.step('Home: the long list flung down and up');
      await j.flingList('client home ($lang)');
      await j.tapKey('discover.cta', wait: const Duration(seconds: 2));
      await j.seeScreen('CL-DISC-03');
      await j.loaded();
      j.step('Results: the long list flung down and up');
      await j.flingList('client results ($lang)');
      final backX = j.tester.getCenter(key('gz:bar.back').first).dx;
      expect(lang == 'ar' ? backX > j.width / 2 : backX < j.width / 2, isTrue, reason: 'the back button sits at the inline-start edge');

      j.step('sheets: Filters (a form sheet), Sort (a small sheet), the date picker sheet; each dismissed by a tap on the dim');
      await j.tapKey('discover.chip.filters', wait: const Duration(seconds: 1));
      await j.seeScreen('CL-DISC-04');
      await j.loaded();
      await j.dismissSheet();
      await j.tapKey('discover.chip.sort', wait: const Duration(seconds: 1));
      await j.see(key('discover.sort'));
      await j.tapKey('discover.sort.voucherPrice', wait: const Duration(seconds: 1));
      await j.gone(key('discover.sort'));
      await j.tapKey('discover.chip.date', wait: const Duration(seconds: 1));
      await j.seeScreen('CL-DISC-06');
      await j.loaded();
      await j.dismissSheet();

      j.step('back: the way the person goes back ends on Home');
      await j.goBack();
      await j.seeScreen('CL-DISC-01');
      await j.loaded();

      j.step('the Brief sheet from Home');
      await j.tapKey('discover.row.guests', wait: const Duration(seconds: 1));
      await j.see(key('discover.brief.sheet'));
      await j.dismissSheet();

      // ---------------------------------------------------------------------------------------------------------- venue and gallery
      j.step('venue detail and the full-screen gallery viewer, closed by its Close button');
      await j.tapKey('discover.card.V01', wait: const Duration(seconds: 2));
      await j.seeScreen('CL-VENU-01');
      await j.loaded();
      await j.tester.tap(find.byType(GzPhoto).first, warnIfMissed: false);
      await j.seeScreen('CL-VENU-02');
      await j.see(find.byType(GzGalleryViewer));
      await j.tapNamed(t((l) => l.commonActionClose));
      await j.seeScreen('CL-VENU-01');
      await j.goBack();
      await j.seeScreen('CL-DISC-01');

      // ---------------------------------------------------------------------------------------------------------- toast and dialog
      j.step('toast: removing a saved hall shows the Removed toast with Undo, and Undo brings it back');
      await j.openTab('saved', 'CL-SAVD-01');
      await j.tapKey('saved.heart.V09', wait: const Duration(milliseconds: 600));
      await j.see(find.byType(GzUndoBar));
      await j.tapText(t((l) => l.commonActionUndo), wait: const Duration(seconds: 1));
      await j.see(key('saved.row.V09'));

      j.step('dialog: Sign out asks first, Stay keeps the person signed in');
      await j.openTab('profile', 'CL-PROF-01');
      await j.tapText(t((l) => l.clientProfileSharedSignOut));
      await j.see(find.byType(GzDialog));
      await j.tapText(t((l) => l.clientProfileSharedSignOutStay), wait: const Duration(seconds: 1));
      await j.gone(find.byType(GzDialog));
      expect(j.screen, 'CL-PROF-01');

      // ---------------------------------------------------------------------------------------------------------- keyboard
      j.step('keyboard: the chat composer with the keyboard up stays in view; Send; the reply arrives; the keyboard goes away');
      await j.openTab('messages', 'CL-MSGS-01');
      await j.tapKey('messages.row.conv-aurelia-reem', wait: const Duration(seconds: 2));
      await j.loaded();
      await j.openKeyboard(0);
      expect(find.byType(EditableText), findsWidgets);
      final hello = lang == 'ar' ? 'مرحبا بكم' : 'Hello there';
      await j.tester.enterText(find.byType(EditableText).first, hello);
      await j.pump(const Duration(milliseconds: 600));
      expect(j.focusedFieldVisible(), isTrue, reason: 'the composer is above the keyboard');
      await j.tap(find.byWidgetPredicate((w) => w is GzIconButton && w.icon == GzIcons.send), wait: const Duration(seconds: 1));
      await j.see(find.textContaining(hello, findRichText: true), why: 'the sent message in the thread');
      await j.pump(const Duration(milliseconds: 3500)); // the scripted reply arrives while the keyboard is still up
      await j.closeKeyboard();
      await j.goBack();
      await j.seeScreen('CL-MSGS-01');
    });
  }
}
