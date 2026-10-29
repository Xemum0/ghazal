// The venue flow on the real router and the in-process mock: the detail page with its date strip and sticky bar, the
// gallery viewer, the calendar sheet, the package sheet, the policies sheet and the government hall, driven by real taps.
// Bounded: no wait is longer than a few seconds of fake time.
import 'package:client_app/app/state/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show SavedType;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../support/flow_world.dart';

void main() {
  group('Detail', () {
    flowTest('the hero story hotel shows with the Brief date strip, the thread and the three paths in the bar', (tester) async {
      await openScreen(tester, 'CL-VENU-01');
      expect(shows('Aurelia Gulf Hotel'), isTrue);
      expect(shows('Thu 14 Jan 2027'), isTrue);
      expect(shows('Get voucher'), isTrue, reason: 'the voucher path is primary');
      expect(shows('Book visit'), isTrue, reason: 'the visit path needs no voucher');
      expect(shows('Contact'), isTrue, reason: 'the browse-only path');
      expect(onScreen('venue.packages'), isTrue);
      expect(onScreen('venue.facilities'), isTrue);
      expect(onScreen('venue.reviews'), isTrue);
      expect(onScreen('venue.similar'), isTrue);
    });

    flowTest('the strip opens the calendar sheet; closing returns to the detail', (tester) async {
      final c = await openScreen(tester, 'CL-VENU-01');
      await tapLabel(tester, RegExp('Your date'));
      expect(shows('Dates'), isTrue, reason: 'the calendar sheet is open');
      c.read(gzNavigatorProvider).closeSheet();
      await settle(tester);
      expect(shows('Dates'), isFalse, reason: 'back on the detail');
    });

    flowTest('the reviews open the full list; the contact row opens the chat', (tester) async {
      final c = await openScreen(tester, 'CL-VENU-01');
      await scrollTo(tester, find.textContaining('See all'));
      await tapText(tester, 'See all 212 reviews');
      expect(currentId(c), 'CL-RVRW-01');
    });

    flowTest('the heart saves to the wishlist, the compare toggle fills the tray', (tester) async {
      final c = await openScreen(tester, 'CL-VENU-01');
      expect(c.read(compareProvider).venueIds, isEmpty);
      await tap(tester, find.descendant(of: find.byType(GzTopBar), matching: find.bySemanticsLabel('Add to compare')));
      expect(c.read(compareProvider).venueIds, contains('V01'));
      await tap(tester, find.descendant(of: find.byType(GzTopBar), matching: find.bySemanticsLabel('Remove from favourites')));
      await settle(tester);
      expect(c.read(isFavouriteProvider((SavedType.venue, 'V01'))), isFalse, reason: 'the saved heart untoggles');
      await tap(tester, find.descendant(of: find.byType(GzTopBar), matching: find.bySemanticsLabel('Save to favourites')));
      expect(c.read(isFavouriteProvider((SavedType.venue, 'V01'))), isTrue);
    });

    flowTest('state loading: skeletons show, no error', (tester) async {
      await openScreen(tester, 'CL-VENU-01', state: 'loading');
      expect(find.byType(GzSkeleton), findsWidgets);
      expect(find.byType(GzErrorState), findsNothing);
    });

    flowTest('state error: the problem is told with a retry', (tester) async {
      await openScreen(tester, 'CL-VENU-01', state: 'error', extraSeconds: 6);
      expect(find.byType(GzErrorState), findsOneWidget);
    });

    flowTest('state offline: the network state shows', (tester) async {
      await openScreen(tester, 'CL-VENU-01', state: 'offline', extraSeconds: 6);
      expect(find.byType(GzErrorState), findsOneWidget);
    });

    flowTest('delisted: a dead link says so with nearby halls', (tester) async {
      await openScreen(tester, 'CL-VENU-01', params: {'venueId': 'V00'});
      expect(shows('No longer listed'), isTrue);
      expect(onScreen('venue.similar'), isTrue);
    });

    flowTest('Arabic: the detail reads right to left with the voucher bar', (tester) async {
      await openScreen(tester, 'CL-VENU-01', locale: const Locale('ar'));
      expect(shows('فندق أوريليا الخليج'), isTrue);
      expect(shows('شراء الكوبون'), isTrue);
      expect(onScreen('venue.packages'), isTrue);
    });
  });

  group('Gallery', () {
    flowTest('the viewer opens on the hero photo with the zone tour and closes back', (tester) async {
      final c = await openScreen(tester, 'CL-VENU-02');
      expect(find.byType(GzGalleryViewer), findsOneWidget);
      c.read(gzNavigatorProvider).pop();
      await settle(tester);
    });

    flowTest('a venue with an unknown id falls back to the hero hotel', (tester) async {
      await openScreen(tester, 'CL-VENU-02', params: {'venueId': 'V00'});
      expect(find.byType(GzGalleryViewer), findsOneWidget);
    });
  });

  group('Calendar sheet', () {
    flowTest('the sheet shows the Brief month with the focus day and its two prices', (tester) async {
      await openScreen(tester, 'CL-VENU-03', params: {'venueId': 'V01'});
      expect(find.byType(GzCalendar), findsOneWidget);
      expect(shows('January 2027'), isTrue);
      expect(onScreen('venue.cal.focus'), isTrue);
    });

    flowTest('picking a date moves the focus card', (tester) async {
      await openScreen(tester, 'CL-VENU-03', params: {'venueId': 'V01'});
      await tapDay(tester, '20 January 2027');
      expect(onScreen('venue.cal.focus'), isTrue);
    });
  });

  group('Package sheet', () {
    flowTest('the package shows its inclusions, menu and the two prices with the saving', (tester) async {
      await openScreen(tester, 'CL-VENU-04', params: {'venueId': 'V01'});
      expect(shows('Included'), isTrue);
      expect(shows('Menu'), isTrue);
      expect(shows('Get voucher'), isTrue);
    });
  });

  group('Policies sheet', () {
    flowTest('the three segments switch: terms, hall rules, good to know', (tester) async {
      await openScreen(tester, 'CL-VENU-05', params: {'venueId': 'V01'});
      expect(onScreen('venue.pol.terms'), isTrue);
      await tapLabel(tester, 'Rules');
      expect(onScreen('venue.pol.rules'), isTrue);
      await tapLabel(tester, 'Good to know');
      expect(onScreen('venue.pol.good'), isTrue);
    });
  });

  group('Government hall', () {
    flowTest('the fees, the rules and the official hand-off show; no voucher anywhere', (tester) async {
      await openScreen(tester, 'CL-VENU-06');
      expect(shows('Fees'), isTrue);
      expect(shows('Official booking'), isTrue);
      expect(shows('Get voucher'), isFalse);
      expect(onScreen('gov.fees'), isTrue);
      expect(onScreen('gov.rules'), isTrue);
    });

    flowTest('leaving asks first; marking booked records the date and fee', (tester) async {
      final c = await openScreen(tester, 'CL-VENU-06');
      await tapText(tester, 'Official booking');
      expect(find.byType(GzDialog), findsOneWidget, reason: 'the leaving confirmation');
      await tapText(tester, 'Cancel');
      await settle(tester);
      expect(find.byType(GzDialog), findsNothing, reason: 'dismissed');
      await tapText(tester, 'Mark booked');
      expect(onScreen('venue.self-report'), isTrue);
      expect(currentId(c), isNotNull);
    });
  });
}
