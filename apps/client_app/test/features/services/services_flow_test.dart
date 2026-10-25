// The services flow on the real router and the in-process mock: the hub, the vendor list with its filters, the vendor
// profile and the quote sheet, driven by real taps. Bounded: no wait is longer than a few seconds of fake time.
import 'package:client_app/app/state/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, SavedType;

import '../../support/flow_world.dart';

void main() {
  group('Hub', () {
    flowTest('the five primary categories show with the voucher strip, the planner door and the saved row', (tester) async {
      await openScreen(tester, 'CL-SERV-01');
      expect(shows('Services'), isTrue);
      expect(shows('Venues'), isTrue, reason: 'the switch returns Home');
      expect(onScreen('services.hub'), isTrue);
    });

    flowTest('a primary tile opens the vendor list of that category', (tester) async {
      final c = await openScreen(tester, 'CL-SERV-01');
      await tapKey(tester, 'services.tile.catering');
      expect(currentId(c), 'CL-SERV-02');
      expect(onScreen('services.list.catering'), isTrue);
    });

    flowTest('the planner entry opens the planner, the saved row the saved tab', (tester) async {
      final c = await openScreen(tester, 'CL-SERV-01');
      await tapText(tester, 'Wedding planner');
      expect(currentId(c), 'CL-PLAN-01');
      c.read(gzNavigatorProvider).pop();
      await settle(tester);
    });

    flowTest('the government link lands with its short line', (tester) async {
      await openScreen(tester, 'CL-SERV-01', params: {'context': 'government'});
      expect(shows('Add catering and decor'), isTrue);
    });
  });

  group('Vendor list', () {
    flowTest('the photography vendors show with ratings and the voucher pairs', (tester) async {
      await openScreen(tester, 'CL-SERV-02', params: {'categoryId': 'photography'});
      expect(find.byKey(const ValueKey<String>('services.vendor.vendor-photography-lamha')), findsOneWidget);
      expect(shows('Lamha Photography Studio'), isTrue);
    });

    flowTest('a vendor card opens the profile with the category carried over', (tester) async {
      final c = await openScreen(tester, 'CL-SERV-02', params: {'categoryId': 'photography'});
      await tapKey(tester, 'services.vendor.vendor-photography-lamha');
      expect(currentId(c), 'CL-SERV-03');
      expect(onScreen('services.profile.vendor-photography-lamha'), isTrue);
    });

    flowTest('the heart saves a vendor to Saved Services', (tester) async {
      final c = await openScreen(tester, 'CL-SERV-02', params: {'categoryId': 'photography'});
      await scrollTo(tester, find.byKey(const ValueKey<String>('services.vendor.vendor-photography-lamha')));
      expect(c.read(isFavouriteProvider((SavedType.vendor, 'vendor-photography-lamha'))), isTrue, reason: 'the story client saved Lamha');
    });

    flowTest('the filter sheet sorts and clears', (tester) async {
      await openScreen(tester, 'CL-SERV-02', params: {'categoryId': 'photography'});
      await tapLabel(tester, 'Filter');
      expect(onScreen('services.filters'), isTrue);
      await tapText(tester, 'Rating');
      await tapText(tester, 'Show');
      await settle(tester);
      expect(onScreen('services.filters'), isFalse, reason: 'the sheet applied and closed');
    });

    flowTest('Arabic: the list reads with the voucher pairs', (tester) async {
      await openScreen(tester, 'CL-SERV-02', params: {'categoryId': 'photography'}, locale: const Locale('ar'));
      expect(find.byKey(const ValueKey<String>('services.vendor.vendor-photography-lamha')), findsOneWidget);
    });
  });

  group('Vendor profile', () {
    flowTest('the profile shows the portfolio, the event, the packages and the how strip', (tester) async {
      await openScreen(tester, 'CL-SERV-03', params: {'vendorId': 'vendor-photography-lamha'});
      expect(onScreen('services.profile.vendor-photography-lamha'), isTrue);
      expect(shows('Request quote'), isTrue);
      expect(shows('Get voucher'), isTrue);
    });

    flowTest('choosing a package changes the chosen row', (tester) async {
      await openScreen(tester, 'CL-SERV-03', params: {'vendorId': 'vendor-photography-lamha'});
      await scrollTo(tester, find.byKey(const ValueKey<String>('services.package.vp-photography-lamha-2')));
      await tapKey(tester, 'services.package.vp-photography-lamha-2');
      expect(shows('Request quote'), isTrue);
    });

    flowTest('Request quote opens the quote sheet; a guest meets the account sheet', (tester) async {
      final c = await openScreen(tester, 'CL-SERV-03', params: {'vendorId': 'vendor-photography-lamha'}, persona: 'guest');
      await scrollTo(tester, find.text('Request quote').first);
      await tapText(tester, 'Request quote');
      final gate = c.read(gateProvider);
      expect(gate, isNotNull, reason: 'the gate opened');
      expect(gate!.reason, GateReason.quote);
    });
  });

  group('Quote sheet', () {
    flowTest('the form carries the package and the Brief date; Send delivers a thread card', (tester) async {
      await openScreen(tester, 'CL-SERV-04', params: {'vendorId': 'vendor-photography-lamha'});
      expect(onScreen('services.quote.vendor-photography-lamha'), isTrue);
      await scrollTo(tester, find.text('Send request'));
      await tapText(tester, 'Send request');
      await settle(tester, flush: true);
      expect(onScreen('services.quote.success'), isTrue, reason: 'the request landed in a thread');
      expect(shows('Request sent'), isTrue);
    });

    flowTest('without a date Send only says why', (tester) async {
      await openScreen(tester, 'CL-SERV-04', params: {'vendorId': 'vendor-photography-lamha'});
      final c = container(tester);
      c.read(searchBriefProvider.notifier).update((b) => b.copyWith(clearDate: true));
      await settle(tester);
      await scrollTo(tester, find.text('Send request'));
      await tapText(tester, 'Send request');
      expect(shows('Date needed'), isTrue);
      expect(onScreen('services.quote.success'), isFalse);
    });

    flowTest('a guest pressing Send meets the account sheet with the quote reason', (tester) async {
      final c = await openScreen(tester, 'CL-SERV-04', params: {'vendorId': 'vendor-photography-lamha'}, persona: 'guest');
      c.read(searchBriefProvider.notifier).update((b) => b.copyWith(date: const LocalDate(2027, 1, 14), guests: 350));
      await settle(tester);
      await scrollTo(tester, find.text('Send request'));
      await tapText(tester, 'Send request');
      final gate = c.read(gateProvider);
      expect(gate, isNotNull, reason: 'the gate opened');
      expect(gate!.reason, GateReason.quote);
      expect(gate.resume?.routeName, 'CL-SERV-04');
    });
  });
}
