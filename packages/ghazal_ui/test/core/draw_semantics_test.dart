// The draw-on lines are decoration. A `Transform` that changes every frame marks its semantics dirty every frame, and Flutter 3.47.5
// breaks the semantics tree of a scroll view when that happens below the fold (outside the viewport's semantics clip, 250 dp past the
// edge): `Null check operator used on a null value` in `PipelineOwner.flushSemantics`, then `'node.built': is not true` on every later
// frame, for a screen-reader user only (found by journey J1 in Arabic, whose lines are a few dp taller than English). The fix keeps the
// animated transform out of the semantics tree: these tests pin that, and run the scene (a Booking Thread preview below the fold whose
// state changes while the page comes back) with the semantics tree on in both languages.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/src/brand/gz_thread_knot.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/nav/nav.dart';

import '../nav/nav_harness.dart';

GzIconProgress _thread({required bool owned, GzDraw draw = GzDraw.inview}) {
  GzKnotState state(int i) => owned ? (i == 0 ? GzKnotState.tied : (i == 1 ? GzKnotState.now : GzKnotState.open)) : (i == 0 ? GzKnotState.now : GzKnotState.open);
  return GzIconProgress(
    label: 'Booking progress',
    draw: draw,
    steps: [
      GzIconProgressStep(id: 'voucher', icon: GzIcons.ticket, label: 'Voucher', state: state(0)),
      GzIconProgressStep(id: 'request', icon: GzIcons.send, label: 'Request', state: state(1)),
      GzIconProgressStep(id: 'approval', icon: GzIcons.verified, label: 'Approval', state: state(2)),
    ],
  );
}

/// A screen the way the apps build one: a scroll view whose content has a spacer, then the thread preview well below the fold.
class _Page extends StatelessWidget {
  const _Page({required this.owned, required this.above});

  final ValueNotifier<bool> owned;
  final double above;

  @override
  Widget build(BuildContext context) => GzScreen(
        bottom: const SizedBox(height: 80),
        child: ValueListenableBuilder<bool>(
          valueListenable: owned,
          builder: (context, isOwned, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: above),
              Padding(padding: const EdgeInsets.symmetric(horizontal: GzSpace.gutter), child: _thread(owned: isOwned)),
              for (var i = 0; i < 8; i++) const SizedBox(height: 90),
            ],
          ),
        ),
      );
}

void main() {
  group('the draw-on lines stay out of the semantics tree', () {
    testWidgets('GzDrawOnce hides its child from semantics, in the middle of the draw and when finished', (tester) async {
      await pumpNav(tester, Center(child: SizedBox(width: 200, height: 4, child: GzDrawOnce(child: Semantics(label: 'a line', child: const SizedBox.expand())))));
      expect(find.bySemanticsLabel('a line'), findsNothing, reason: 'at the start of the draw');
      await tester.pump(const Duration(milliseconds: 240));
      expect(find.bySemanticsLabel('a line'), findsNothing, reason: 'in the middle of the draw');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('a line'), findsNothing, reason: 'when the line is whole');
    });

    testWidgets('the thread of GzIconProgress animates its lines under an ExcludeSemantics, not in the thread\'s own semantics', (tester) async {
      await pumpNav(tester, Center(child: SizedBox(width: 320, child: _thread(owned: true))));
      final lines = find.byType(GzDrawOnce);
      expect(lines, findsOneWidget, reason: 'one reached step: one line draws on');
      expect(find.descendant(of: lines, matching: find.byType(Transform)), findsOneWidget);
      expect(find.ancestor(of: find.descendant(of: lines, matching: find.byType(Transform)), matching: find.byType(ExcludeSemantics)), findsWidgets);
      // the thread is still one named group for a screen reader
      expect(find.bySemanticsLabel(RegExp('Booking progress')), findsWidgets);
    });
  });

  for (final lang in ['ar', 'en']) {
    testWidgets('a thread preview below the fold changes while the page below a removed page comes back ($lang, semantics on)', semanticsEnabled: true, (tester) async {
      final owned = ValueNotifier<bool>(false);
      addTearDown(owned.dispose);
      final errors = <Object>[];
      final previous = FlutterError.onError;
      addTearDown(() => FlutterError.onError = previous);
      await pumpNav(tester, const SizedBox.shrink(), lang: lang);
      FlutterError.onError = (d) => errors.add(d.exception);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(GzPageRoute<void>(builder: (_) => _Page(owned: owned, above: 1000)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      // a page covers it (the sign-in screens), is removed at once, and the account changes what the preview says a moment later
      final covering = GzPageRoute<void>(builder: (_) => const GzScreen(child: SizedBox(height: 900)));
      navigator.push(covering);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      navigator.removeRoute(covering);
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (i == 2) owned.value = true;
      }
      expect(errors, isEmpty, reason: 'no framework error while the semantics tree is on: $errors');
    });
  }
}
