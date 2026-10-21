import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/nav/nav.dart';

import 'nav_harness.dart';

void main() {
  group('GzActionBar note as a widget', () {
    Widget bar({String? note, Widget? noteWidget}) => Align(
          alignment: Alignment.bottomCenter,
          child: GzActionBar(action: GzActionBarAction(label: 'Continue', onPressed: () {}), note: note, noteWidget: noteWidget, safeBottom: false),
        );

    testWidgets('a widget under the primary: 8 below the button, full width, caption type; the string form still works', (tester) async {
      var taps = 0;
      await pumpNav(tester, bar(noteWidget: Center(child: GestureDetector(key: const ValueKey('link'), onTap: () => taps++, child: const Text('Sign in', key: ValueKey('t'))))));
      final button = tester.getRect(find.byType(GzButton));
      expect(tester.getRect(find.byKey(const ValueKey('link'))).top, closeTo(button.bottom + GzSpace.s2, 0.5));
      // the web bar: 12 + 52 + 8 + note + 12; the note's height is the link's own
      final style = DefaultTextStyle.of(tester.element(find.byKey(const ValueKey('t')))).style;
      expect(style.fontSize, tester.element(find.byKey(const ValueKey('t'))).gz.text(GzTextRole.caption).fontSize);
      await tester.tap(find.byKey(const ValueKey('link')));
      expect(taps, 1);
      await pumpNav(tester, bar(note: 'Nothing is charged now'));
      expect(find.text('Nothing is charged now'), findsOneWidget);
    });

    testWidgets('the widget wins over the string and the bar is as tall as 12 + 52 + 8 + note + 12', (tester) async {
      await pumpNav(tester, bar(note: 'string', noteWidget: const SizedBox(height: 24, width: 10)));
      expect(find.text('string'), findsNothing);
      expect(tester.getSize(find.byType(GzActionBar)).height, closeTo(12 + 52 + 8 + 24 + 12, 1));
    });
  });

  group('GzTopBar extras', () {
    testWidgets('titleWidget replaces the title text and sits between back and the end slot', (tester) async {
      await pumpNav(
        tester,
        const Align(alignment: Alignment.topCenter, child: GzTopBar(back: GzTopBarBack.show, titleWidget: SizedBox(key: ValueKey('who'), width: 120, height: 24))),
      );
      final who = tester.getRect(find.byKey(const ValueKey('who')));
      expect(who.center.dx, closeTo(195, 1));
      expect(who.center.dy, closeTo(47 + 28, 1));
    });

    testWidgets('a text action sits at the end with its word on the 20 gutter (right in English, left in Arabic); the icon action comes before it', (tester) async {
      for (final lang in ['en', 'ar']) {
        var skipped = 0;
        await pumpNav(
          tester,
          Align(
            alignment: Alignment.topCenter,
            child: GzTopBar(
              back: GzTopBarBack.show,
              titleWidget: const SizedBox(key: ValueKey('thread'), height: 8),
              actions: [GzTopBarAction(icon: GzIcons.info, label: 'Info', onPressed: () {})],
              textAction: GzTopBarTextAction(label: 'Skip', onPressed: () => skipped++),
            ),
          ),
          lang: lang,
        );
        final en = lang == 'en';
        final skip = tester.getRect(find.text('Skip'));
        final info = tester.getRect(find.byTooltip('Info').evaluate().isEmpty ? find.bySemanticsLabel('Info') : find.byTooltip('Info'));
        expect(en ? skip.right : skip.left, closeTo(en ? 390 - GzSpace.gutter : GzSpace.gutter, 1.5), reason: lang);
        expect(en ? info.right <= skip.left + 8 : info.left >= skip.right - 8, isTrue, reason: lang);
        final thread = tester.getRect(find.byKey(const ValueKey('thread')));
        expect(en ? thread.right <= info.left : thread.left >= info.right, isTrue, reason: lang);
        await tester.tap(find.text('Skip'));
        expect(skipped, 1);
        expect(tester.getSize(find.byType(GzTopBar)).height, 47 + 56);
      }
    });

    testWidgets('the search field reports focus gained and lost', (tester) async {
      final focus = <bool>[];
      await pumpNav(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: GzTopBar(variant: GzTopBarVariant.search, back: GzTopBarBack.show, search: GzTopBarSearch(placeholder: 'Search halls', onChanged: (_) {}, onFocusChange: focus.add)),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(focus, [true]);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(focus, [true, false]);
    });
  });
}
