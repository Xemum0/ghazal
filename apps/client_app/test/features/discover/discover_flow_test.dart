// The discover flow on the real router and the in-process mock: Home, Results, the Brief sheet, Filters, the Map, the date sheet and the
// governorate chips, driven by real taps. Bounded: no wait is longer than a few seconds of fake time.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:client_app/app/state/state.dart';
import 'package:client_app/features/discover/application/discover_filters.dart';

import '../../support/flow_world.dart';

void main() {
  group('Home', () {
    flowTest('the Brief card says the couple\'s Brief, the CTA carries the live count and opens Results with the Brief as filters', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-01');
      expect(labelOf(tester, 'discover.row.date'), contains('Thu 14 Jan 2027'));
      expect(labelOf(tester, 'discover.row.area'), contains('Hawalli'), reason: 'the Brief names governorates, never areas');
      expect(labelOf(tester, 'discover.row.guests'), contains('350'));
      expect(shows('Show 6 halls'), isTrue);
      expect(onScreen('discover.status'), isTrue);
      await tapKey(tester, 'discover.cta');
      expect(onScreen('discover.facts'), isTrue, reason: 'Results is open');
      c.read(gzNavigatorProvider);
      expect(find.byKey(const ValueKey<String>('discover.card.V01')), findsOneWidget);
      expect(c.read(discoverStateProvider).filters.available, isTrue);
      expect(c.read(discoverStateProvider).filters.available, isTrue);
    });

    flowTest('each Brief row opens the Brief sheet on its picker', (tester) async {
      await openScreen(tester, 'CL-DISC-01');
      await tapKey(tester, 'discover.row.guests');
      expect(onScreen('discover.brief.sheet'), isTrue);
      expect(onScreen('discover.brief.guests'), isTrue, reason: 'the Guests picker is open');
    });

    flowTest('a category tile opens Results with that category as a removable chip', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-01', size: const Size(390, 4000));
      await tapKey(tester, 'discover.category.luxury-hotels');
      expect(onScreen('discover.applied.category'), isTrue);
      expect(c.read(discoverStateProvider).filters.category?.value, 'luxury-hotels');
      await tapKey(tester, 'discover.applied.category');
      expect(onScreen('discover.applied.category'), isFalse, reason: 'the chip removes its filter');
    });

    flowTest('the status card opens the request, the bell the notifications, the switch the services', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-01');
      await tapKey(tester, 'discover.status');
      expect(currentId(c), 'CL-BKNG-02');
      c.read(gzNavigatorProvider).pop();
      await settle(tester);
      await tapKey(tester, 'discover.bell');
      expect(currentId(c), 'CL-MSGS-04');
    });

    flowTest('the shelves: each has a chevron that opens Results with those halls; the Saved shelf lists the hearted halls', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-01', size: const Size(390, 4000));
      expect(find.byKey(const ValueKey<String>('discover.shelves')), findsOneWidget);
      await tapKey(tester, 'discover.seeall.Free Thu 14 Jan');
      expect(c.read(discoverStateProvider).filters.shelf?.value, 'free');
      expect(onScreen('discover.applied.shelf'), isTrue);
    });
  });

  group('Results', () {
    flowTest('hearts, compare and the voucher action behave as on the venue card', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03', size: const Size(390, 3600));
      expect(shows('Get voucher'), isTrue);
      expect(find.byKey(const ValueKey<String>('discover.card.V07')), findsOneWidget, reason: 'a held hall is listed');
      expect(c.read(compareProvider).venueIds, isEmpty);
      await tester.tap(find.byIcon(GzIcons.compare).first.hitTestable(), warnIfMissed: false);
      await settle(tester);
      expect(c.read(compareProvider).venueIds, hasLength(1), reason: 'the compare toggle fills the tray');
      await tapKey(tester, 'discover.action.V01');
      expect(currentId(c), 'CL-VCHR-01');
    });

    flowTest('Sort opens a small sheet; choosing an order applies it and closes', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03');
      await tapKey(tester, 'discover.chip.sort');
      expect(onScreen('discover.sort'), isTrue);
      await tapKey(tester, 'discover.sort.price');
      expect(onScreen('discover.sort'), isFalse, reason: 'the sheet closed');
      expect(c.read(discoverStateProvider).sort, DiscoverSort.price);
      expect(onScreen('discover.chip.sort'), isTrue);
    });

    flowTest('the Brief echo opens the Brief sheet; the Filters chip opens Filters; Map and Region open their screens', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03');
      await tapKey(tester, 'discover.facts');
      expect(onScreen('discover.brief.sheet'), isTrue);
      c.read(gzNavigatorProvider).closeSheet();
      await settle(tester);
      await tapKey(tester, 'discover.chip.filters');
      expect(onScreen('discover.filters'), isTrue);
      c.read(gzNavigatorProvider).closeSheet();
      await settle(tester);
      await tapKey(tester, 'discover.map.toggle');
      expect(onScreen('discover.map.screen'), isTrue);
    });

    flowTest('no results: the empty state names the filter whose removal brings halls back', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03');
      c.read(discoverStateProvider.notifier).replaceFilters(const DiscoverFilters(available: true, capacity: (1300, 1500)));
      await settle(tester);
      expect(onScreen('discover.results.none'), isTrue);
      expect(shows('Remove 1,300'), isTrue, reason: 'the relax action names the capacity filter');
    });

    flowTest('loading shows the skeleton that matches the list', (tester) async {
      await openScreen(tester, 'CL-DISC-03', state: 'loading');
      expect(onScreen('discover.results.loading'), isTrue);
    });

    flowTest('error shows the retry state', (tester) async {
      await openScreen(tester, 'CL-DISC-03', state: 'error', extraSeconds: 4);
      expect(find.byType(GzErrorState), findsWidgets);
    });

    flowTest('offline shows the offline state', (tester) async {
      await openScreen(tester, 'CL-DISC-03', state: 'offline', extraSeconds: 4);
      expect(find.byType(GzOfflineState), findsWidgets);
    });

    flowTest('typing in the search field shows the typeahead; an area narrows the list', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03');
      c.read(discoverStateProvider.notifier).setQuery('Mish');
      await settle(tester);
      expect(onScreen('discover.typeahead'), isTrue);
    });
  });

  group('Brief sheet', () {
    flowTest('the sheet edits a draft: nothing is applied until the gold button; Clear empties the draft', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-01');
      await openSheetOf(tester, c, 'CL-DISC-02');
      expect(onScreen('discover.brief.sheet'), isTrue);
      await tapKey(tester, 'discover.brief.clear');
      expect(c.read(searchBriefProvider).date, isNotNull, reason: 'the draft, not the Brief, was cleared');
      await tapKey(tester, 'discover.brief.cta');
      expect(c.read(searchBriefProvider).date, isNull, reason: 'applied');
    });

    flowTest('the Governorates picker: chips, nothing lit means every governorate; the count is in the title and applying writes the Brief', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-01');
      expect(c.read(searchBriefProvider).governorateIds, <String>['hawalli', 'capital'], reason: "Reem's profile seeded the Brief");
      await openSheetOf(tester, c, 'CL-DISC-02', const <String, Object?>{'focus': 'area'});
      expect(onScreen('discover.brief.area'), isTrue);
      expect(shows('Governorates · 2'), isTrue, reason: 'the count lives in the panel title');
      await tapText(tester, 'Farwaniya', ms: 400);
      expect(shows('Governorates · 3'), isTrue);
      await tapKey(tester, 'discover.brief.done');
      await tapKey(tester, 'discover.brief.cta');
      expect(c.read(searchBriefProvider).governorateIds, containsAll(<String>['hawalli', 'capital', 'farwaniya']));
    });

    flowTest('the Governorates picker keeps no exact area: the chips are the six governorates and no area is offered', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-01');
      await openSheetOf(tester, c, 'CL-DISC-02', const <String, Object?>{'focus': 'area'});
      for (final name in <String>['Capital', 'Hawalli', 'Farwaniya', 'Ahmadi', 'Jahra', 'Mubarak Al-Kabeer']) {
        expect(find.text(name), findsWidgets, reason: name);
      }
      expect(find.descendant(of: find.byKey(const ValueKey<String>('discover.brief.area')), matching: find.text('Salmiya')), findsNothing, reason: 'no exact area in the picker');
    });
  });

  group('Filters, date sheet, region chip and map', () {
    flowTest('Filters: a draft with a live count; applying returns to Results with removable chips', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03');
      await openSheetOf(tester, c, 'CL-DISC-04');
      expect(shows('Show 6 halls'), isTrue);
      await tapKey(tester, 'discover.group.type');
      expect(onScreen('discover.filters'), isTrue);
      await tapKey(tester, 'discover.filters.cta');
      expect(onScreen('discover.filters'), isFalse);
    });

    flowTest('the date sheet shows the density marks and applies a day to the Brief', (tester) async {
      final c = await openScreen(tester, 'CL-DISC-03');
      await openSheetOf(tester, c, 'CL-DISC-06');
      expect(onScreen('discover.dates.sheet'), isTrue);
      expect(shows('Show 6 halls'), isTrue);
      await tapKey(tester, 'discover.dates.cta');
      expect(c.read(searchBriefProvider).date.toString(), '2027-01-14');
    });

    flowTest('the Region chip of Results opens Filters on its Governorate group', (tester) async {
      await openScreen(tester, 'CL-DISC-03');
      await tapKey(tester, 'discover.chip.region');
      expect(onScreen('discover.filters'), isTrue);
    });

    flowTest('the map: pins for the halls, a card carousel, List returns', (tester) async {
      await openScreen(tester, 'CL-DISC-05');
      expect(find.byKey(const ValueKey<String>('discover.pin.V01')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('discover.map.card.V01')), findsOneWidget);
      await tapKey(tester, 'discover.pin.V01');
    });
  });

  flowTest('Arabic: the Home CTA and the Results chips read right to left', (tester) async {
    await openScreen(tester, 'CL-DISC-01', locale: const Locale('ar'));
    expect(shows('عرض 6 قاعات'), isTrue);
    final bar = tester.getRect(find.byKey(const ValueKey<String>('discover.briefcard')));
    final date = tester.getCenter(find.byKey(const ValueKey<String>('discover.row.date')));
    expect(date.dx, greaterThan(bar.center.dx - 1));
  });
}
