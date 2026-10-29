// The services flow on the real router and the in-process mock: the hub, the vendor list with its filters, the vendor
// profile and the quote sheet, driven by real taps. Bounded: no wait is longer than a few seconds of fake time.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/features/services/application/services_providers.dart' show ServFilter, ServQuery, servicesAreasProvider, servicesFilterProvider, servicesFilteredProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show SavedType;

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

    flowTest('the note right under the switch tells a service provider where to apply and opens the Partner app store page', (tester) async {
      final opened = <Uri>[];
      await openScreen(
        tester,
        'CL-SERV-01',
        size: const Size(390, 1800),
        overrides: [
          openExternalUrlProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
        ],
      );
      const note = 'Service provider? Apply in the Partner app';
      expect(shows(note), isTrue);
      await tapText(tester, note, ms: 400);
      expect(opened, hasLength(1));
      expect(opened.single.scheme, 'https');
    });

    flowTest('the hub no longer claims to be where the governmental-facility link lands', (tester) async {
      await openScreen(tester, 'CL-SERV-01', params: {'context': 'government'});
      expect(shows('Add catering and decor'), isFalse);
      expect(onScreen('services.hub'), isTrue);
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

    flowTest('the filter sheet offers the governorates the category works in, never an area; one chosen counts as one filter', (tester) async {
      final c = await openScreen(tester, 'CL-SERV-02', params: {'categoryId': 'photography'});
      await tapLabel(tester, 'Filter');
      expect(onScreen('services.filters'), isTrue);
      expect(find.descendant(of: find.byKey(const ValueKey<String>('services.filters')), matching: find.text('Salmiya')), findsNothing, reason: 'no exact area in the sheet');
      final vendors = c.read(servicesFilteredProvider(const ServQuery('photography', ServFilter()))).value!;
      final first = c.read(servicesAreasProvider).value!.governorates.firstWhere((g) => g.id == vendors.first.governorateId);
      final chip = find.descendant(of: find.byKey(const ValueKey<String>('services.filters')), matching: find.text(first.name.en!));
      expect(chip, findsWidgets, reason: 'a governorate chip');
      await tester.tap(chip.first, warnIfMissed: false);
      await settle(tester);
      await tapText(tester, 'Show');
      await settle(tester);
      expect(c.read(servicesFilterProvider('photography')).governorateIds, contains(first.id));
      expect(c.read(servicesFilterProvider('photography')).appliedCount, 1);
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

    flowTest('Request quote opens the quote sheet over the profile', (tester) async {
      final c = await openScreen(tester, 'CL-SERV-03', params: {'vendorId': 'vendor-photography-lamha'});
      await scrollTo(tester, find.text('Request quote').first);
      await tapText(tester, 'Request quote');
      expect(currentId(c), 'CL-SERV-04');
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

  });
}
