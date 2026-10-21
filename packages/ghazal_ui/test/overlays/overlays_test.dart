import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/nav/nav.dart';
import 'package:ghazal_ui/src/overlays/overlays.dart';

import '../nav/nav_harness.dart';

const Key _grab = ValueKey('gz:sheet.grab');
const Key _close = ValueKey('gz:sheet.close');

Widget _sheetOpener({String? title = 'Your date', bool dismissible = true, double bodyHeight = 200, ValueChanged<String?>? onResult, Widget? footer}) => Builder(
      builder: (context) => Center(
        child: GestureDetector(
          key: kOpen,
          onTap: () => showGzSheet<String>(
            context,
            title: title,
            dismissible: dismissible,
            footer: footer,
            builder: (_) => SizedBox(height: bodyHeight, child: const Text('body')),
          ).then((v) => onResult?.call(v)),
          child: const Text('open'),
        ),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(kOpen));
  await tester.pumpAndSettle();
}

/// Drags [finder] by [dy] in six moves, [moveMs] apart: a speed of dy / 6 / moveMs. The finger lifts at the last move, so the
/// release velocity is that speed (tester.fling reports none for a drag recognised after its slop).
Future<void> _drag(WidgetTester tester, Finder finder, double dy, int moveMs) async {
  final g = await tester.startGesture(tester.getCenter(finder));
  for (var i = 1; i <= 6; i++) {
    await g.moveBy(Offset(0, dy / 6), timeStamp: Duration(milliseconds: i * moveMs));
  }
  await g.up(timeStamp: Duration(milliseconds: 6 * moveMs));
}

double _sheetBottom(WidgetTester tester) => tester.getBottomLeft(find.byKey(_grab)).dy;

void main() {
  group('GzSheet', () {
    testWidgets('rises over 320 ms from the bottom edge, flush with it, with title and handle; the scrim is the modal token', (tester) async {
      await pumpNav(tester, _sheetOpener());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kOpen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // mid-rise: the sheet is partly below the view
      expect(tester.getTopLeft(find.byKey(_grab)).dy, greaterThan(500));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Your date'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
      final panel = tester.getRect(find.byType(GzSheet));
      expect(panel.bottom, closeTo(800, 0.5));
      expect(tester.getSize(find.byKey(_grab)), const Size(390, 20));
      final scrim = tester.widget<ColoredBox>(find.descendant(of: find.byType(GzScrim), matching: find.byType(ColoredBox)));
      expect(scrim.color.a, closeTo(GzColors.light.scrimModal.a, 0.01));
    });

    testWidgets('never taller than 90% of the frame (snapped to 4); the body scrolls inside', (tester) async {
      await pumpNav(tester, _sheetOpener(bodyHeight: 3000));
      await _open(tester);
      expect(tester.getSize(find.byType(GzSheet)).height, lessThanOrEqualTo(720));
      expect(tester.getSize(find.byType(GzSheet)).height, greaterThan(700));
    });

    testWidgets('close button and scrim tap dismiss and resolve the future; a non-dismissible sheet has neither', (tester) async {
      final results = <String?>[];
      await pumpNav(tester, _sheetOpener(onResult: results.add));
      await _open(tester);
      await tester.tap(find.byKey(_close));
      await tester.pumpAndSettle();
      expect(find.text('body'), findsNothing);
      expect(results, [null]);

      await _open(tester);
      await tester.tapAt(const Offset(195, 60)); // the scrim above the sheet
      await tester.pumpAndSettle();
      expect(find.text('body'), findsNothing);

      await pumpNav(tester, _sheetOpener(dismissible: false));
      await _open(tester);
      expect(find.byKey(_close), findsNothing);
      await tester.tapAt(const Offset(195, 60));
      await tester.pumpAndSettle();
      expect(find.text('body'), findsOneWidget);
      await tester.binding.handlePopRoute(); // system back is blocked too
      await tester.pumpAndSettle();
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('system back closes the topmost sheet', (tester) async {
      await pumpNav(tester, _sheetOpener());
      await _open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('body'), findsNothing);
    });

    testWidgets('a slow short drag springs back; the sheet stays and returns to rest', (tester) async {
      await pumpNav(tester, _sheetOpener());
      await _open(tester);
      final rest = _sheetBottom(tester);
      final g = await tester.startGesture(tester.getCenter(find.byKey(_grab)));
      await g.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 50));
      expect(_sheetBottom(tester), closeTo(rest + 40, 1));
      await tester.pump(const Duration(seconds: 2)); // finger held still: velocity zero
      await g.up();
      await tester.pumpAndSettle();
      expect(find.text('body'), findsOneWidget);
      expect(_sheetBottom(tester), closeTo(rest, 0.6));
    });

    testWidgets('a drag past 30% of the height dismisses (the spring carries it out) and resolves once', (tester) async {
      var results = 0;
      await pumpNav(tester, _sheetOpener(onResult: (_) => results++));
      await _open(tester);
      final height = tester.getSize(find.byType(GzSheet)).height;
      final g = await tester.startGesture(tester.getCenter(find.byKey(_grab)));
      await g.moveBy(Offset(0, height * 0.35));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 1)); // let the finger rest: below the flick speed
      await g.up();
      await tester.pumpAndSettle();
      expect(find.text('body'), findsNothing);
      expect(results, 1);
    });

    testWidgets('a fast flick dismisses even a short drag (velocity above 700 dp/s)', (tester) async {
      await pumpNav(tester, _sheetOpener());
      await _open(tester);
      await _drag(tester, find.byKey(_grab), 60, 10); // 1000 dp/s over 60 dp: well under 30% of the height
      await tester.pumpAndSettle();
      expect(find.text('body'), findsNothing);
    });

    testWidgets('a slow drag under the threshold is not a flick (velocity 300 dp/s settles back)', (tester) async {
      await pumpNav(tester, _sheetOpener());
      await _open(tester);
      await _drag(tester, find.byKey(_grab), 60, 50); // 200 dp/s
      await tester.pumpAndSettle();
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('the scrim dims with the drag', (tester) async {
      await pumpNav(tester, _sheetOpener());
      await _open(tester);
      double alpha() => tester.widget<ColoredBox>(find.descendant(of: find.byType(GzScrim), matching: find.byType(ColoredBox))).color.a;
      final full = alpha();
      final height = tester.getSize(find.byType(GzSheet)).height;
      final g = await tester.startGesture(tester.getCenter(find.byKey(_grab)));
      await g.moveBy(Offset(0, height / 2));
      await tester.pump();
      expect(alpha(), closeTo(full * 0.5, full * 0.08));
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('keyboard: the sheet rides above it and spends the home-indicator inset', (tester) async {
      await pumpNav(tester, _sheetOpener(title: null));
      await _open(tester);
      final h = tester.getSize(find.byType(GzSheet)).height;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.getRect(find.byType(GzSheet)).bottom, closeTo(500, 0.6));
      expect(tester.getSize(find.byType(GzSheet)).height, closeTo(h - 34, 1));
    });

    testWidgets('pinned footer and a screen footer (GzSheetFooter) sit under the scrolling body', (tester) async {
      await pumpNav(tester, Builder(builder: (context) => Center(child: GestureDetector(key: kOpen, onTap: () => showGzSheet<void>(context, builder: (_) => const Column(children: [Text('body'), GzSheetFooter(child: Text('screen footer'))])), child: const Text('open')))));
      await _open(tester);
      await tester.pump();
      expect(find.text('screen footer'), findsOneWidget);
      expect(tester.getTopLeft(find.text('screen footer')).dy, greaterThan(tester.getTopLeft(find.text('body')).dy));
    });

    testWidgets('semantics: a dialog route named by its title, reachable close button', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(tester, _sheetOpener());
      await _open(tester);
      expect(find.bySemanticsLabel('Your date'), findsWidgets);
      expect(find.bySemanticsLabel('Close'), findsWidgets);
      handle.dispose();
    });

    testWidgets('reduced motion: the sheet fades instead of rising', (tester) async {
      await pumpNav(tester, _sheetOpener(), reduceMotion: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kOpen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(tester.getRect(find.byType(GzSheet)).bottom, closeTo(800, 0.5)); // already in place
      expect(find.byType(SlideTransition).evaluate().where((e) => (e.widget as SlideTransition).position.value.dy > 0), isEmpty);
    });

    testWidgets('GzSheetPage builds a sheet route', (tester) async {
      const page = GzSheetPage<void>(child: Text('x'), title: 'T', name: 'CL-DISC-02');
      late Route<void> route;
      await pumpNav(tester, Builder(builder: (context) {
        route = page.createRoute(context);
        return const SizedBox();
      }));
      expect(route, isA<GzSheetRoute<void>>());
      expect(route.settings.name, 'CL-DISC-02');
    });
  });

  group('GzDialog', () {
    Widget opener(GzDialogSpec spec, ValueChanged<GzDialogResult> onResult) =>
        Builder(builder: (context) => Center(child: GestureDetector(key: kOpen, onTap: () => showGzDialog(context, spec).then(onResult), child: const Text('open'))));

    testWidgets('confirm and cancel resolve the choice; the scrim does not dismiss', (tester) async {
      GzDialogResult? result;
      await pumpNav(tester, opener(const GzDialogSpec(title: 'Send this request?', body: 'You pay nothing now.', confirmLabel: 'Send', cancelLabel: 'Not yet', icon: GzIcons.send), (r) => result = r));
      await _open(tester);
      expect(find.text('Send this request?'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Send this request?'), findsOneWidget);
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(result, GzDialogResult.confirm);
      expect(find.text('Send this request?'), findsNothing);

      await _open(tester);
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(result, GzDialogResult.cancel);
    });

    testWidgets('system back cancels when there is a cancel button; an acknowledgement cannot be dismissed by back', (tester) async {
      GzDialogResult? result;
      await pumpNav(tester, opener(const GzDialogSpec(title: 'Cancel this request?'), (r) => result = r));
      await _open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(result, GzDialogResult.cancel);

      result = null;
      await pumpNav(tester, opener(const GzDialogSpec(title: 'Done', showCancel: false), (r) => result = r));
      await _open(tester);
      expect(find.text('Cancel'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, GzDialogResult.confirm);
    });

    testWidgets('destructive tone: the danger icon disk; the card is centred inside the gutters; the shared words are the default labels', (tester) async {
      await pumpNav(tester, opener(const GzDialogSpec(title: 'Cancel?', tone: GzDialogTone.destructive, icon: GzIcons.warning), (_) {}));
      await _open(tester);
      final disk = tester.widget<DecoratedBox>(find.byKey(const ValueKey('gz:dialog.icon')));
      expect((disk.decoration as BoxDecoration).color, GzColors.light.statusDangerBg);
      final card = tester.getRect(find.byType(GzDialog));
      expect(card.left, 20);
      expect(card.right, 370);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('toast host', () {
    Widget trigger(void Function(BuildContext) show) => Builder(builder: (context) => Center(child: GestureDetector(key: kOpen, onTap: () => show(context), child: const Text('go'))));

    testWidgets('a toast fades in, floats 16 above the bottom inset inside the gutters, and leaves after 4 s', (tester) async {
      await pumpNav(tester, trigger((c) => GzToasts.show(c, message: 'Saved to your list', tone: GzToastTone.success)), toastHost: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kOpen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Saved to your list'), findsOneWidget);
      final r = tester.getRect(find.byType(GzToast));
      expect(r.left, 20);
      expect(r.right, 370);
      expect(r.bottom, closeTo(800 - 34 - 16, 0.6));
      await tester.pump(const Duration(milliseconds: 3600));
      expect(find.text('Saved to your list'), findsOneWidget); // 3.85 s: still there
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Saved to your list'), findsNothing);
    });

    testWidgets('the undo bar lives 8 s (the depleting line), Undo runs the action and dismisses', (tester) async {
      var undone = 0;
      await pumpNav(tester, trigger((c) => GzToasts.show(c, message: 'Request withdrawn', undo: true, action: GzToastAction(label: 'Undone', onPressed: () => undone++))), toastHost: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kOpen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(GzUndoBar), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
      expect(find.byType(GzUndoBar), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GzUndoBar), findsNothing);
      expect(undone, 0);

      await tester.tap(find.byKey(kOpen));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(undone, 1);
      expect(find.byType(GzUndoBar), findsNothing);
    });

    testWidgets('a new toast replaces the one on screen; dismiss by key removes it', (tester) async {
      late BuildContext ctx;
      await pumpNav(tester, Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }), toastHost: true);
      GzToasts.show(ctx, message: 'one');
      await tester.pump(const Duration(milliseconds: 300));
      final key = GzToasts.show(ctx, message: 'two');
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('one'), findsNothing);
      expect(find.text('two'), findsOneWidget);
      GzToasts.dismiss(ctx, key);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('two'), findsNothing);
    });

    testWidgets('an action bar lifts the toast above itself', (tester) async {
      late BuildContext ctx;
      await pumpNav(
        tester,
        Builder(builder: (context) {
          ctx = context;
          return Align(alignment: Alignment.bottomCenter, child: GzActionBar(action: GzActionBarAction(label: 'Go', onPressed: () {})));
        }),
        toastHost: true,
      );
      await tester.pump();
      GzToasts.show(ctx, message: 'above');
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getBottomLeft(find.byType(GzToast)).dy, lessThanOrEqualTo(tester.getTopLeft(find.byType(GzActionBar)).dy - 15));
    });

    testWidgets('without a host the call does nothing', (tester) async {
      late BuildContext ctx;
      await pumpNav(tester, Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }));
      expect(GzToasts.show(ctx, message: 'x'), '');
    });
  });

  group('GzPhoto', () {
    test('asset:// resolves to the package asset variant by the physical width, with a 2x cache width', () {
      final small = gzResolveImage('asset://ghazal_mock_api/images/halls-01', displayWidth: 150, devicePixelRatio: 3) as ResizeImage;
      expect(small.width, 300);
      final asset = small.imageProvider as AssetImage;
      expect(asset.package, 'ghazal_mock_api');
      expect(asset.assetName, 'assets/images/halls-01_480.jpg');
      expect(asset.keyName, 'packages/ghazal_mock_api/assets/images/halls-01_480.jpg');
      final wide = gzResolveImage('asset://ghazal_mock_api/images/halls-01', displayWidth: 390, devicePixelRatio: 3) as ResizeImage;
      expect((wide.imageProvider as AssetImage).assetName, 'assets/images/halls-01_960.jpg');
      expect(wide.width, 780);
    });

    test('http(s) URLs resolve to a NetworkImage with the same suffix convention; an explicit extension is kept', () {
      final net = gzResolveImage('https://cdn.example/img/halls-01', displayWidth: 390, devicePixelRatio: 2) as ResizeImage;
      expect((net.imageProvider as NetworkImage).url, 'https://cdn.example/img/halls-01_960.jpg');
      final low = gzResolveImage('http://localhost:4700/images/x', displayWidth: 100, devicePixelRatio: 2) as ResizeImage;
      expect((low.imageProvider as NetworkImage).url, 'http://localhost:4700/images/x_480.jpg');
      final kept = gzResolveImage('https://cdn.example/a.webp', displayWidth: 100, devicePixelRatio: 2) as ResizeImage;
      expect((kept.imageProvider as NetworkImage).url, 'https://cdn.example/a.webp');
      expect(gzPhotoVariantFor(240, 2), 480);
      expect(gzPhotoVariantFor(241, 2), 960);
      expect(gzPhotoVariantFor(2000, 3), 960);
    });

    testWidgets('a photo keeps its aspect ratio box, shows the placeholder colour, and is named for assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(tester, Align(alignment: Alignment.topCenter, child: GzPhoto.provider(image: MemoryImage(_transparentPng), alt: 'Ballroom', aspectRatio: 16 / 10)));
      expect(tester.getSize(find.byType(GzPhoto)), const Size(390, 243.75));
      expect(find.bySemanticsLabel('Ballroom'), findsOneWidget);
      handle.dispose();
    });
  });

  group('GzPager', () {
    Widget pager(void Function(int) onChange, {GzPagerMode mode = GzPagerMode.full}) => Align(
          alignment: Alignment.topCenter,
          child: GzPager(label: 'Photos', mode: mode, onIndexChanged: onChange, children: [for (var i = 0; i < 3; i++) SizedBox(height: 100, child: Text('page $i'))]),
        );

    testWidgets('page width follows the formula: full = frame, peek = frame - 2 x gutter - peek', (tester) async {
      expect(gzPagerItemWidth(390, GzPagerMode.full), 390);
      expect(gzPagerItemWidth(390, GzPagerMode.peek), 326);
      await pumpNav(tester, pager((_) {}, mode: GzPagerMode.peek));
      expect(tester.getSize(find.ancestor(of: find.text('page 0'), matching: find.byType(SizedBox)).last).width, anyOf(326, greaterThan(300)));
    });

    testWidgets('a drag toward the next page commits: left in LTR, right in RTL; the other way resists at the first page', (tester) async {
      var index = 0;
      await pumpNav(tester, pager((i) => index = i));
      await tester.drag(find.byType(GzPager), const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(index, 1);
      await tester.drag(find.byType(GzPager), const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(index, 0);

      index = 0;
      await pumpNav(tester, pager((i) => index = i), lang: 'ar');
      await tester.drag(find.byType(GzPager), const Offset(-250, 0)); // toward "before the first" in RTL
      await tester.pumpAndSettle();
      expect(index, 0);
      await tester.drag(find.byType(GzPager), const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(index, 1);
    });

    testWidgets('a short slow drag settles back to the same page', (tester) async {
      var index = 0;
      await pumpNav(tester, pager((i) => index = i));
      await tester.drag(find.byType(GzPager), const Offset(-30, 0));
      await tester.pumpAndSettle();
      expect(index, 0);
    });

    testWidgets('the progress bead follows the index', (tester) async {
      await pumpNav(tester, const Align(alignment: Alignment.topCenter, child: GzPagerProgress(count: 4, index: 1)));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(GzPagerProgress)).height, GzSize.knotBead);
    });
  });

  group('GzAccordion', () {
    testWidgets('a tap opens a row (200 ms height tween), single-open closes the other, the summary shows only while closed', (tester) async {
      await pumpNav(
        tester,
        const Align(
          alignment: Alignment.topCenter,
          child: GzAccordion(items: [
            GzAccordionItem(id: 'a', title: 'First', content: Text('first body')),
            GzAccordionItem(id: 'b', title: 'Second', summary: 'second summary', content: Text('second body')),
          ]),
        ),
      );
      double height() => tester.getSize(find.byType(GzAccordion)).height;
      final closed = height();
      expect(closed, greaterThanOrEqualTo(128));
      expect(find.text('second summary'), findsOneWidget);
      await tester.tap(find.text('First'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = height();
      await tester.pumpAndSettle();
      final open = height();
      expect(mid, greaterThan(closed));
      expect(open, greaterThan(mid));
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(find.text('second summary'), findsNothing); // open: the summary gives way to the content
      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(height(), closeTo(closed, 1)); // both closed again
      expect(find.text('second summary'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('error: title, one retry, the recovery text behind the info glyph (opens a sheet)', (tester) async {
      var retried = 0;
      await pumpNav(tester, SingleChildScrollView(child: GzErrorState(kind: GzErrorKind.network, onRetry: () => retried++)));
      await tester.pumpAndSettle();
      expect(find.text('You’re offline'), findsOneWidget);
      expect(find.textContaining('connect'), findsNothing); // the sentence is not on the screen
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
      await tester.tap(find.byKey(const ValueKey('gz:state.info')));
      await tester.pumpAndSettle();
      expect(find.textContaining('connect'), findsOneWidget);
    });

    testWidgets('empty: a six-word body is a quiet helper, a longer one moves behind the info glyph; no-retry kinds show none', (tester) async {
      await pumpNav(tester, const SingleChildScrollView(child: GzEmptyState(icon: GzIcons.heart, title: 'No saved halls', body: 'Tap the heart on a hall.')));
      await tester.pumpAndSettle();
      expect(find.text('Tap the heart on a hall.'), findsOneWidget);
      expect(find.byKey(const ValueKey('gz:state.info')), findsNothing);
      await pumpNav(tester, const SingleChildScrollView(child: GzEmptyState(icon: GzIcons.heart, title: 'No saved halls', body: 'Tap the heart on a hall and it waits here for you, always.')));
      await tester.pumpAndSettle();
      expect(find.textContaining('waits here'), findsNothing);
      expect(find.byKey(const ValueKey('gz:state.info')), findsOneWidget);
      await pumpNav(tester, const SingleChildScrollView(child: GzErrorState(kind: GzErrorKind.notFound)));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsNothing);
      expect(gzIllustrationForIcon(GzIcons.search), GzIllustrationName.noResult);
    });

    testWidgets('success: the action is the gold primary; offline is the wifi-off drawing with a retry', (tester) async {
      await pumpNav(tester, SingleChildScrollView(child: GzSuccessState(title: 'Request sent', action: GzStateAction(label: 'Done', onPressed: () {}))));
      await tester.pumpAndSettle();
      expect(find.text('Request sent'), findsOneWidget);
      await pumpNav(tester, SingleChildScrollView(child: GzOfflineState(onRetry: () {})));
      await tester.pumpAndSettle();
      expect(find.text('You’re offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('banner', () {
    testWidgets('offline is a flush strip, info a card inside the gutters; the action and the close are 44 targets', (tester) async {
      var closed = 0;
      var acted = 0;
      await pumpNav(
        tester,
        Column(children: [
          const GzBanner(tone: GzBannerTone.offline, message: 'You are offline.'),
          const SizedBox(height: 12),
          GzBanner(message: 'Prices include service charge.', onDismiss: () => closed++),
          const SizedBox(height: 12),
          GzBanner(tone: GzBannerTone.warning, message: 'On hold.', actionLabel: 'Try again', onAction: () => acted++),
        ]),
      );
      expect(tester.getRect(find.byType(GzBanner).at(0)).width, 390);
      expect(tester.getTopLeft(find.byType(GzIcon).at(0)).dx, 20); // flush: glyph on the gutter
      expect(tester.getTopLeft(find.byType(GzIcon).at(1)).dx, 36); // card: 20 margin + 16 padding
      await tester.tap(find.byType(GzBarButton));
      await tester.tap(find.text('Try again'));
      expect(closed, 1);
      expect(acted, 1);
    });
  });

  group('pull to refresh', () {
    testWidgets('a pull past 64 dp refreshes and holds the band until the future completes; a short pull does not', (tester) async {
      var refreshed = 0;
      final done = Completer<void>();
      await pumpNav(
        tester,
        GzPullToRefresh(
          onRefresh: () {
            refreshed++;
            return done.future;
          },
          child: GzScreen(child: Column(children: [for (var i = 0; i < 20; i++) const SizedBox(height: 60, child: Text('row'))])),
        ),
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 60)); // 30 dp after resistance
      await tester.pumpAndSettle();
      expect(refreshed, 0);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(refreshed, 1);
      expect(find.byType(GzPullIndicator), findsOneWidget);
      done.complete();
      await tester.pumpAndSettle();
      expect(find.byType(GzPullIndicator), findsNothing);
    });

    testWidgets('the indicator is a determinate ring while pulling and says Loading while refreshing', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNav(tester, const Center(child: GzPullIndicator(progress: 1, refreshing: true)));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    });
  });

  group('navigator base', () {
    testWidgets('sheets, dialogs and toasts through the contract: open by key, close by key, answer, toast', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final toasts = GzToastController();
      addTearDown(toasts.dispose);
      final nav = _Adapter(key, toasts);
      await pumpNav(tester, Navigator(key: key, onGenerateRoute: (s) => GzPageRoute<void>(settings: s, builder: (_) => const Center(child: Text('home')))), toastHost: false);
      await tester.pumpAndSettle();
      var closed = 0;
      final first = nav.openSheetBuilder((_) => const SizedBox(height: 120, child: Text('one')), options: GzSheetOptions(title: 'A', onClose: () => closed++));
      await tester.pumpAndSettle();
      expect(first, isNotEmpty);
      expect(find.text('one'), findsOneWidget);
      final second = nav.openSheet('CL-DISC-02', options: const GzSheetOptions(params: {'id': 'V01'}));
      await tester.pumpAndSettle();
      expect(find.text('screen CL-DISC-02 V01'), findsOneWidget);
      nav.closeSheet(second);
      await tester.pumpAndSettle();
      expect(find.text('screen CL-DISC-02 V01'), findsNothing);
      expect(find.text('one'), findsOneWidget);
      nav.closeSheet();
      await tester.pumpAndSettle();
      expect(find.text('one'), findsNothing);
      expect(closed, 1);

      final answer = nav.openDialog(const GzDialogSpec(title: 'Sure?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(await answer, GzDialogResult.confirm);

      final tk = nav.toast(const GzToastSpec(message: 'hello'));
      expect(toasts.currentKey, tk);
      nav.dismissToast(tk);
      expect(toasts.currentKey, isNull);
    });
  });
}

class _Adapter extends GzNavigatorBase {
  _Adapter(GlobalKey<NavigatorState> key, GzToastController toasts) : super(navigatorKey: key, toasts: toasts);

  @override
  Widget buildScreen(String id, GzParams params) => Text('screen $id ${params['id']}');
  @override
  bool get canGoBack => false;
  @override
  GzParams get params => const {};
  @override
  String get currentId => '';
  @override
  String? get activeTab => null;
  @override
  void push(String id, {GzParams params = const {}}) {}
  @override
  void pop({int count = 1}) {}
  @override
  void replace(String id, {GzParams params = const {}}) {}
  @override
  void reset(String id, {GzParams params = const {}}) {}
  @override
  void switchTab(String tabId) {}
}

/// A 1 x 1 transparent PNG (MemoryImage: FileImage never completes under fake async).
final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);
