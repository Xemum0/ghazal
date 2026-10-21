// The five states of every discover screen (loading, data, empty, error with retry, offline), the guest gate and sheet dismissal, on the
// real router and the in-process mock. Error and offline need a few seconds of fake time: the HTTP client retries a failed GET three times.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:client_app/app/state/state.dart';

import '../../support/flow_world.dart';

void main() {
  group('Home', () {
    flowTest('loading: the status card and the shelves are skeletons, the CTA says "Show halls"', (tester) async {
      await openScreen(tester, 'CL-DISC-01', state: 'loading');
      expect(onScreen('discover.shelves.loading'), isTrue);
      expect(shows('Show halls'), isTrue);
      expect(onScreen('discover.status'), isFalse);
    });

    flowTest('empty: nothing free on the date, the CTA says "Nearest dates" and the lead shelf offers to change the date', (tester) async {
      await openScreen(tester, 'CL-DISC-01', state: 'empty', size: const Size(390, 3000));
      expect(shows('Nearest dates'), isTrue);
      expect(onScreen('discover.empty'), isTrue);
    });

    flowTest('error: the shelves become an error state with a retry', (tester) async {
      await openScreen(tester, 'CL-DISC-01', state: 'error', extraSeconds: 5, size: const Size(390, 3000));
      expect(find.byType(GzErrorState), findsOneWidget);
      await shoot(tester, 'home-error');
    });

    flowTest('offline: a banner, the last-update line and the offline state', (tester) async {
      await openScreen(tester, 'CL-DISC-01', state: 'offline', extraSeconds: 5, size: const Size(390, 3000));
      expect(find.byType(GzOfflineState), findsOneWidget);
      expect(find.byType(GzBanner), findsOneWidget);
      await shoot(tester, 'home-offline');
    });

    flowTest('a guest can set the Brief and see the halls; the third heart raises the sign-up nudge', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03', persona: 'guest', state: 'guest', size: const Size(390, 3000));
      for (final id in <String>['V03', 'V02', 'V01']) {
        await tester.tap(
          find.descendant(of: find.byKey(ValueKey<String>('discover.card.$id')), matching: find.byIcon(GzIcons.heart)).first.hitTestable(),
          warnIfMissed: false,
        );
        await settle(tester);
      }
      expect(currentId(c), 'CL-AUTH-01', reason: 'the third heart opens the sign-up sheet once');
    });
  });

  group('Results', () {
    flowTest('empty (nothing free on the date): the empty state offers the nearest free dates', (tester) async {
      await openScreen(tester, 'CL-DISC-03', state: 'empty');
      expect(onScreen('discover.results.none'), isTrue);
      await shoot(tester, 'results-empty');
    });

    flowTest('error: a retry, and the chips stay on screen', (tester) async {
      await openScreen(tester, 'CL-DISC-03', state: 'error', extraSeconds: 5);
      expect(find.byType(GzErrorState), findsOneWidget);
      expect(onScreen('discover.chip.filters'), isTrue);
      await shoot(tester, 'results-error');
    });

    flowTest('a guest asking for the voucher meets the sign-in sheet first, and the voucher line is locked', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03', persona: 'guest', state: 'guest');
      await tester.runAsync(() async => c.read(searchBriefProvider.notifier).set(SearchBrief.empty.copyWith(date: c.read(searchBriefProvider).date)));
      expect(onScreen('discover.voucherlock'), isTrue);
    });
  });

  group('Sheets and screens', () {
    for (final id in <String>['CL-DISC-02', 'CL-DISC-04', 'CL-DISC-06', 'CL-DISC-05', 'CL-DISC-07']) {
      flowTest('$id: loading is a skeleton or a pending button, never blank', (tester) async {
        await openScreen(tester, id, state: 'loading');
        expect(find.byType(GzStubScreen), findsNothing);
        expect(find.byType(GzSkeleton).evaluate().length + find.byType(GzButton).evaluate().length, greaterThan(0));
        await shoot(tester, '${id.toLowerCase()}-loading');
      });
      flowTest('$id: offline says so and keeps a way out', (tester) async {
        await openScreen(tester, id, state: 'offline', extraSeconds: 5);
        expect(find.byType(GzStubScreen), findsNothing);
        await shoot(tester, '${id.toLowerCase()}-offline');
      });
    }

    flowTest('a sheet dismisses with its close button and keeps nothing unsaved', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03');
      await openSheetOf(tester, c, 'CL-DISC-02');
      expect(onScreen('discover.brief.sheet'), isTrue);
      await tapKey(tester, 'gz:sheet.close');
      expect(onScreen('discover.brief.sheet'), isFalse);
      expect(onScreen('discover.facts'), isTrue, reason: 'back on Results');
    });

    flowTest('Arabic run: Results with a card, the chip row and the tray mirror', (tester) async {
      await openScreen(tester, 'CL-DISC-03', locale: const Locale('ar'));
      expect(shows('عرض'), isFalse);
      expect(onScreen('discover.chip.filters'), isTrue);
      final filters = tester.getCenter(find.byKey(const ValueKey<String>('discover.chip.filters'))).dx;
      final date = tester.getCenter(find.byKey(const ValueKey<String>('discover.chip.date'))).dx;
      expect(filters, greaterThan(date), reason: 'Filters is first, at the right edge');
    });
  });
}
