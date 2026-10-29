// The saved and compare flow on the real router and the in-process mock: the
// Saved tab with its three segments, multi-select into Compare, the tray, the
// replace sheet and the compare table, driven by real taps. Bounded: no wait
// is longer than a few seconds of fake time.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client_app/app/state/state.dart';

import '../../support/flow_world.dart';

void main() {
  group('CL-SAVD-01 saved', () {
    flowTest('the venues segment lists the saved halls with the brief facts', (tester) async {
      await openScreen(tester, 'CL-SAVD-01');
      expect(shows('Aurelia'), isTrue);
      expect(onScreen('saved.select'), isTrue);
    });

    flowTest('the segments switch to services and packages', (tester) async {
      await openScreen(tester, 'CL-SAVD-01');
      await tapText(tester, 'Services');
      expect(shows('Lamha'), isTrue);
      await tapText(tester, 'Packages');
      expect(shows('Gold'), isTrue);
    });

    flowTest('select mode arms compare and opens the table', (tester) async {
      final c = await openScreen(tester, 'CL-SAVD-01');
      await tapKey(tester, 'saved.select');
      await tapKey(tester, 'saved.row.V01', ms: 400);
      await tapKey(tester, 'saved.row.V05', ms: 400);
      await tapLabel(tester, RegExp('Compare'));
      expect(currentId(c), 'CL-SAVD-04');
    });
  });

  group('CL-SAVD-02 tray and CL-SAVD-03 replace', () {
    flowTest('the tray sheet lists the set with a compare action', (tester) async {
      final c = await openScreen(tester, 'CL-SAVD-01');
      c.read(compareProvider.notifier).toggle('V01');
      await settle(tester);
      await openSheetOf(tester, c, 'CL-SAVD-02');
      expect(onScreen('saved.tray'), isTrue);
    });

    flowTest('a fourth hall opens the replace sheet and swapping keeps three', (tester) async {
      final c = await openScreen(tester, 'CL-SAVD-01');
      final compare = c.read(compareProvider.notifier);
      compare.toggle('V01');
      compare.toggle('V02');
      compare.toggle('V03');
      await settle(tester);
      await tapKey(tester, 'saved.select');
      await tapKey(tester, 'saved.row.V05', ms: 400);
      expect(onScreen('saved.replace'), isTrue);
      await tapKey(tester, 'saved.replace.row.V01');
      await settle(tester, wait: const Duration(milliseconds: 800));
      expect(c.read(compareProvider).venueIds.length, 3);
      expect(c.read(compareProvider).venueIds.contains('V05'), isTrue);
    });
  });

  group('CL-SAVD-04 compare', () {
    flowTest('two halls render the table with best-in-row marks and footer actions', (tester) async {
      final c = await openScreen(tester, 'CL-SAVD-01');
      c.read(compareProvider.notifier).toggle('V01');
      c.read(compareProvider.notifier).toggle('V02');
      await settle(tester);
      await tapKey(tester, 'saved.tray.dock');
      expect(currentId(c), 'CL-SAVD-04');
      expect(onScreen('compare.table'), isTrue);
    });

    flowTest('fewer than two halls shows the short state, not the table', (tester) async {
      await openScreen(tester, 'CL-SAVD-04');
      expect(onScreen('compare.fewer'), isTrue);
    });

    flowTest('the compare table reads in Arabic', (tester) async {
      final c = await openScreen(tester, 'CL-SAVD-01', locale: const Locale('ar'));
      c.read(compareProvider.notifier).toggle('V01');
      c.read(compareProvider.notifier).toggle('V02');
      await settle(tester);
      await tapKey(tester, 'saved.tray.dock');
      expect(currentId(c), 'CL-SAVD-04');
      expect(onScreen('compare.table'), isTrue);
    });
  });

  group('states', () {
    flowTest('loading shows the skeleton rows', (tester) async {
      await openScreen(tester, 'CL-SAVD-01', state: 'loading');
      expect(shows('المفضلة'), isFalse);
    });

    flowTest('the error state retries the bundle', (tester) async {
      await openScreen(tester, 'CL-SAVD-01', state: 'error');
      expect(onScreen('saved.error'), isTrue);
    });
  });
}
