import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/hotel/hotel_a.dart';

import '../core/core_harness.dart';

void main() {
  testWidgets('GzTimelineEvent.meta takes a widget: it sits 4 under the title row in the caption type, after the next-day mark; metaLabel is spoken', (tester) async {
    final handle = tester.ensureSemantics();
    final ids = <String>[];
    await pumpCore(
      tester,
      SizedBox(
        width: 350,
        child: GzDayTimeline(
          date: '2026-11-12',
          now: '19:00',
          onPressed: ids.add,
          events: const [
            GzTimelineEvent(
              id: 'a',
              time: '21:00',
              title: 'Najla',
              metaWidget: SizedBox(key: ValueKey('chips'), height: 24, width: 140),
              metaLabel: 'Danah Ballroom, 420 guests',
            ),
          ],
        ),
      ),
    );
    final title = tester.getRect(find.text('Najla'));
    final chips = tester.getRect(find.byKey(const ValueKey('chips')));
    expect(chips.top, greaterThanOrEqualTo(title.bottom));
    expect(chips.top - title.bottom, lessThan(16));
    expect(find.bySemanticsLabel('Najla, Danah Ballroom, 420 guests'), findsOneWidget);
    await tester.tap(find.text('Najla'));
    expect(ids, ['a']);
    handle.dispose();
  });

  testWidgets('Arabic: the meta widget starts at the inline start (right) of the content column', (tester) async {
    await pumpCore(
      tester,
      SizedBox(
        width: 350,
        child: GzDayTimeline(
          date: '2026-11-12',
          events: const [GzTimelineEvent(id: 'a', time: '21:00', title: 'نجلاء', metaWidget: SizedBox(key: ValueKey('chips'), height: 24, width: 100))],
        ),
      ),
      lang: 'ar',
    );
    final chips = tester.getRect(find.byKey(const ValueKey('chips')));
    final title = tester.getRect(find.text('نجلاء'));
    expect((chips.right - title.right).abs(), lessThan(1.5));
  });
}
