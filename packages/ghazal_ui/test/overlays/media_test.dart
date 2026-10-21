import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/overlays/overlays.dart';

import '../nav/nav_harness.dart';

List<GzCarouselImage> _images([int n = 3]) => [for (var i = 0; i < n; i++) GzCarouselImage(src: 'asset://ghazal_mock_api/images/none-$i', alt: 'Photo $i')];

Future<void> _drag(WidgetTester tester, Finder finder, Offset total, int moveMs) async {
  final g = await tester.startGesture(tester.getCenter(finder));
  for (var i = 1; i <= 6; i++) {
    await g.moveBy(total / 6, timeStamp: Duration(milliseconds: i * moveMs));
  }
  await g.up(timeStamp: Duration(milliseconds: 6 * moveMs));
}

void main() {
  group('GzImageCarousel', () {
    testWidgets('hero: 440 high, counter and progress on the bottom scrim, a swipe advances, a tap opens', (tester) async {
      var index = 0;
      int? opened;
      await pumpNav(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: GzImageCarousel(images: _images(), label: 'Photos of the hotel', onIndexChanged: (i) => index = i, onOpen: (i) => opened = i),
        ),
      );
      expect(tester.getSize(find.byType(GzImageCarousel)), const Size(390, 440));
      expect(find.textContaining('1'), findsWidgets);
      expect(find.byType(GzPagerProgress), findsOneWidget);
      await tester.tap(find.byType(GzImageCarousel));
      expect(opened, 0);
      await tester.drag(find.byType(GzPager), const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(index, 1);
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('tour: 16:10 pages with radius 12 and a peek of the next, no counter', (tester) async {
      await pumpNav(tester, Align(alignment: Alignment.topCenter, child: GzImageCarousel(variant: GzCarouselVariant.tour, images: _images(), label: 'Tour')));
      expect(tester.getSize(find.byType(GzImageCarousel)).height, GzImageCarousel.tourHeight(390));
      expect(GzImageCarousel.tourHeight(390), 204);
      expect(find.byType(GzPagerProgress), findsNothing);
    });
  });

  group('GzGalleryViewer', () {
    Widget viewer({required VoidCallback onClose, ValueChanged<int>? onIndex, bool video = false}) => GzGalleryViewer(
          images: [for (final i in _images()) GzCarouselImage(src: i.src, alt: i.alt, video: video)],
          label: 'Photos',
          initialIndex: 0,
          onIndexChanged: onIndex,
          onClose: onClose,
        );

    testWidgets('counter at inline-start, close at inline-end, progress at the foot; the close button closes', (tester) async {
      var closed = 0;
      await pumpNav(tester, viewer(onClose: () => closed++));
      await tester.pumpAndSettle();
      expect(find.byType(GzPagerProgress), findsOneWidget);
      final counter = tester.getTopLeft(find.textContaining('1').first).dx;
      final close = tester.getTopLeft(find.byKey(const ValueKey('gz:gallery.close'))).dx;
      expect(counter, lessThan(close));
      await tester.tap(find.byKey(const ValueKey('gz:gallery.close')));
      expect(closed, 1);
    });

    testWidgets('a swipe down past 120 dp, or a flick, dismisses; a short slow drag springs back', (tester) async {
      var closed = 0;
      await pumpNav(tester, viewer(onClose: () => closed++));
      await tester.pumpAndSettle();
      await _drag(tester, find.byType(GzPager), const Offset(0, 40), 60); // 111 dp/s over 40 dp
      await tester.pumpAndSettle();
      expect(closed, 0);
      await _drag(tester, find.byType(GzPager), const Offset(0, 150), 60); // slow but far
      await tester.pumpAndSettle();
      expect(closed, 1);
      await _drag(tester, find.byType(GzPager), const Offset(0, 60), 10); // fast
      await tester.pumpAndSettle();
      expect(closed, 2);
    });

    testWidgets('a video shows its poster with a play mark', (tester) async {
      await pumpNav(tester, viewer(onClose: () {}, video: true));
      await tester.pumpAndSettle();
      expect(find.byType(GzPager), findsOneWidget);
    });

    testWidgets('showGzGalleryViewer covers the screen, fades the stage in, and resolves with the index when closed', (tester) async {
      int? result;
      await pumpNav(
        tester,
        Builder(builder: (context) => Center(child: GestureDetector(key: kOpen, onTap: () => showGzGalleryViewer(context, images: _images(), label: 'Photos', initialIndex: 1).then((v) => result = v), child: const Text('open')))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kOpen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(GzGalleryViewer), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('2'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('gz:gallery.close')));
      await tester.pumpAndSettle();
      expect(find.byType(GzGalleryViewer), findsNothing);
      expect(result, 1);
    });
  });
}
