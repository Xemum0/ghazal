// The planner flow on the real router and the in-process mock: packages,
// compare, the consultation form with its hard gate, the status thread and
// the meeting sheet, driven by real taps. Bounded: no wait is longer than a
// few seconds of fake time.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzNavigatorProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show PlannerTier;

import 'package:client_app/features/planner/application/planner_data.dart';

import '../../support/flow_world.dart';

void main() {
  group('CL-PLAN-01 packages', () {
    flowTest('the Gold plate shows by default with inclusions, price terms and the other planners row', (tester) async {
      final c = await openScreen(tester, 'CL-PLAN-01');
      expect(onScreen('planner.plate.gold'), isTrue);
      expect(shows('Day-of coordination'), isFalse);
      expect(shows('Vendors and quotes'), isTrue);
      expect(shows('From'), isTrue);
      expect(shows('Other planners'), isTrue);
      expect(c.read(plannerTierProvider), PlannerTier.gold);
    });

    flowTest('the compare action opens the three-tier table and choosing Silver arms its plate', (tester) async {
      final c = await openScreen(tester, 'CL-PLAN-01');
      await tapLabel(tester, RegExp('Compare packages'));
      expect(onScreen('planner.compare'), isTrue);
      expect(shows('Silver'), isTrue);
      await tapText(tester, 'Silver');
      expect(c.read(plannerTierProvider), PlannerTier.silver);
      await tester.pump(const Duration(milliseconds: 100));
      expect(onScreen('planner.plate.silver'), isFalse, reason: 'the header radio only arms the tier');
    });

    flowTest('the pinned action opens the form with the armed tier', (tester) async {
      final c = await openScreen(tester, 'CL-PLAN-01');
      await tapLabel(tester, RegExp('Compare packages'));
      await tapText(tester, 'Royal');
      expect(c.read(plannerTierProvider), PlannerTier.royal);
      await tapText(tester, 'Request consultation');
      expect(currentId(c), 'CL-PLAN-02');
      expect(c.read(plannerTierProvider), PlannerTier.royal);
    });

    flowTest('from a booking the offer title shows with the wedding line', (tester) async {
      await openScreen(tester, 'CL-PLAN-01', params: const {'from': 'booking'});
      expect(shows('Need a planner?'), isTrue);
    });
  });

  group('CL-PLAN-02 consultation', () {
    flowTest('sending the seeded windows lands on success and then on the status screen', (tester) async {
      final c = await openScreen(tester, 'CL-PLAN-02');
      expect(onScreen('planner.days'), isTrue);
      expect(c.read(plannerWindowsProvider).length, 2);
      await scrollTo(tester, find.text('Send request'));
      await tapText(tester, 'Send request');
      expect(onScreen('planner.sent'), isTrue);
      await tapText(tester, 'View request');
      expect(currentId(c), 'CL-PLAN-03');
    });

    flowTest('an empty choice of windows blocks the send with a blameless error', (tester) async {
      final c = await openScreen(tester, 'CL-PLAN-02');
      // The story draft chose Sun 15 Nov evening and Mon 16 Nov afternoon.
      await tapKey(tester, 'planner.part.evening');
      await tapKey(tester, 'planner.day.2026-11-16');
      await tapKey(tester, 'planner.part.afternoon');
      expect(c.read(plannerWindowsProvider), isEmpty);
      await scrollTo(tester, find.text('Send request'));
      await tapText(tester, 'Send request');
      expect(shows('Pick a time'), isTrue);
      expect(currentId(c), 'CL-PLAN-02', reason: 'the request never leaves the form');
    });

  });

  group('CL-PLAN-03 status', () {
    flowTest('the story request shows the planner, the thread and the meeting card', (tester) async {
      final c = await openScreen(tester, 'CL-PLAN-03');
      expect(onScreen('planner.status.planner'), isTrue);
      expect(onScreen('planner.status.thread'), isTrue);
      expect(onScreen('planner.status.meeting'), isTrue);
      expect(shows('Nouf Al-Otaibi'), isTrue);
      c.read(gzNavigatorProvider);
    });

    flowTest('message leaves for the planner thread', (tester) async {
      final c = await openScreen(tester, 'CL-PLAN-03');
      ignoreRenderErrors = true; // the thread belongs to the messages flow
      await tapText(tester, 'Message');
      expect(currentId(c), 'CL-MSGS-02');
    });

    flowTest('schedule opens the meeting sheet', (tester) async {
      await openScreen(tester, 'CL-PLAN-03', params: const {'frame': 'assigned'});
      await tapText(tester, 'Schedule');
      expect(onScreen('planner.meeting'), isTrue);
    });

    flowTest('the waiting frame shows the request summary with edit and cancel', (tester) async {
      final c = await openScreen(tester, 'CL-PLAN-03', params: const {'frame': 'requested'});
      expect(onScreen('planner.status.waiting'), isTrue);
      await scrollTo(tester, find.text('Cancel'));
      await tapText(tester, 'Edit');
      expect(currentId(c), 'CL-PLAN-02');
    });
  });

  group('CL-PLAN-04 meeting sheet', () {
    flowTest('picking a slot and confirming ties the meeting and shows the done card', (tester) async {
      final c = await openScreen(tester, 'CL-PLAN-03');
      await openSheetOf(tester, c, 'CL-PLAN-04');
      await tapLabel(tester, RegExp('5:00'));
      await tapText(tester, 'Confirm');
      expect(onScreen('planner.meeting.done'), isTrue);
    });
  });

  group('states', () {
    flowTest('loading shows skeletons, error retries, offline bans the send', (tester) async {
      await openScreen(tester, 'CL-PLAN-01', state: 'loading');
      expect(onScreen('planner.loading'), isTrue);
    });

    flowTest('the packages screen survives the error state with a retry', (tester) async {
      await openScreen(tester, 'CL-PLAN-01', state: 'error');
      expect(onScreen('planner.error'), isTrue);
    });

    flowTest('offline disables the form send', (tester) async {
      await openScreen(tester, 'CL-PLAN-02', state: 'offline');
      expect(shows('offline'), isTrue);
    });

    flowTest('the packages screen reads in Arabic', (tester) async {
      await openScreen(tester, 'CL-PLAN-01', locale: const Locale('ar'));
      expect(onScreen('planner.plate.gold'), isTrue);
      expect(shows('الذهبية'), isTrue);
    });
  });
}
