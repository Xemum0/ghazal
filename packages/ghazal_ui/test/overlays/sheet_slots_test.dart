import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/overlays/overlays.dart';

import '../nav/nav_harness.dart';

Widget _opener({Widget? header, bool fill = false, Widget? footer, Widget Function(BuildContext)? builder}) => Builder(
      builder: (context) => Center(
        child: GestureDetector(
          key: kOpen,
          onTap: () => showGzSheet<void>(context, header: header, fill: fill, footer: footer, builder: builder ?? (_) => const SizedBox(height: 120, child: Text('body'))),
          child: const Text('open'),
        ),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(kOpen));
  await tester.pumpAndSettle();
}

void main() {
  group('GzSheet header slot and fill', () {
    testWidgets('a header argument is pinned above the body with no gutter added; the body keeps the 20 gutter', (tester) async {
      await pumpNav(tester, _opener(header: const SizedBox(key: ValueKey('hdr'), height: 48, width: double.infinity)));
      await _open(tester);
      expect(tester.getRect(find.byKey(const ValueKey('hdr'))).left, 0);
      expect(tester.getRect(find.byKey(const ValueKey('hdr'))).width, 390);
      expect(tester.getTopLeft(find.text('body')).dx, GzSpace.gutter);
    });

    testWidgets('a GzSheetPinnedHeader inside the content leaves the scrolling body and stays put while the body scrolls', (tester) async {
      await pumpNav(
        tester,
        _opener(
          fill: true,
          builder: (_) => const Column(children: [GzSheetPinnedHeader(child: SizedBox(key: ValueKey('hdr'), height: 48, width: double.infinity)), SizedBox(height: 1600, child: Align(alignment: AlignmentDirectional.topStart, child: Text('body')))]),
        ),
      );
      await _open(tester);
      await tester.pump();
      final before = tester.getTopLeft(find.byKey(const ValueKey('hdr')));
      final bodyBefore = tester.getTopLeft(find.text('body')).dy;
      await tester.drag(find.text('body'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const ValueKey('hdr'))), before);
      expect(tester.getTopLeft(find.text('body')).dy, lessThan(bodyBefore));
    });

    testWidgets('fill: the sheet takes 90 % of the height (snapped to 4) even for a short body; the footer stays at the bottom', (tester) async {
      await pumpNav(tester, _opener(fill: true, footer: const SizedBox(key: ValueKey('ftr'), height: 52)));
      await _open(tester);
      final grab = tester.getTopLeft(find.byKey(const ValueKey('gz:sheet.grab'))).dy;
      // 800 * 0.9 = 720: the sheet top sits 80 below the frame top, plus the 12 sheet padding above the handle.
      expect(grab, closeTo(800 - 720 + GzSpace.sheetPadTop, 1));
      final footer = tester.getRect(find.byKey(const ValueKey('ftr')));
      expect(footer.bottom, closeTo(800 - 34 - GzSpace.sheetPadBottom, 1));
      expect(footer.left, GzSpace.gutter);
    });

    testWidgets('a GzSheetFill in the content asks for the fill; without it a short body sizes to its content', (tester) async {
      await pumpNav(tester, _opener());
      await _open(tester);
      final short = tester.getTopLeft(find.byKey(const ValueKey('gz:sheet.grab'))).dy;
      expect(short, greaterThan(800 - 720 + 100));
      await tester.tapAt(const Offset(195, 20)); // scrim
      await tester.pumpAndSettle();
      await pumpNav(tester, _opener(builder: (_) => const Column(children: [GzSheetFill(), Text('body')])));
      await _open(tester);
      expect(tester.getTopLeft(find.byKey(const ValueKey('gz:sheet.grab'))).dy, closeTo(800 - 720 + GzSpace.sheetPadTop, 1));
    });

    testWidgets('Arabic: the header slot and the body mirror; the same heights', (tester) async {
      await pumpNav(tester, _opener(fill: true, header: const Align(alignment: AlignmentDirectional.centerStart, child: SizedBox(key: ValueKey('hdr'), height: 48, width: 100))), lang: 'ar');
      await _open(tester);
      expect(tester.getRect(find.byKey(const ValueKey('hdr'))).right, 390);
      expect(tester.getTopRight(find.text('body')).dx, 390 - GzSpace.gutter);
    });
  });
}
