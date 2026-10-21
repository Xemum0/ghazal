import 'dart:ui' show Tristate;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/brand/brand.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/provider/provider.dart';

import '../inputs/inputs_harness.dart';

Map<String, Object?> _plan(String cycle, {int? fils}) => {
  'id': 'plan-$cycle',
  'cycle': cycle,
  'name': {'en': cycle, 'ar': cycle},
  'periodDays': cycle == 'weekly' ? 7 : 30,
  'ratesFils': fils,
  'currency': 'KWD',
  'exemptForMajorHotels': true,
  'active': true,
};

AdPlan _adPlan(String cycle, {int? fils}) => AdPlan.fromJson(_plan(cycle, fils: fils));

Map<String, Object?> _decision(String id, String? from, String to, String actor, String at, {String? name, List<String>? codes, String? note}) => {
  'id': id,
  'listingId': 'l1',
  'at': at,
  'from': from,
  'to': to,
  'actor': actor,
  'actorName': ?name,
  'codes': ?codes,
  'note': note == null ? null : {'en': note, 'ar': note},
};

Listing _listing(
  String status, {
  List<Map<String, Object?>> history = const [],
  String? planCycle,
  String? endsOn,
  List<String>? reasons,
  bool sponsored = false,
}) => Listing.fromJson({
  'id': 'l1',
  'providerId': 'p1',
  'partnerAccountId': 'a1',
  'categoryId': 'catering',
  'title': {'en': 'Zahra florals', 'ar': 'زهور زهرة'},
  'description': {'en': 'd', 'ar': 'd'},
  'packageIds': <String>[],
  'status': status,
  'planCycle': planCycle,
  'billing': {'status': 'rates_pending'},
  'endsOn': endsOn,
  'rejection': reasons == null
      ? null
      : {
          'codes': reasons,
          'note': {'en': 'Please fix it', 'ar': 'يرجى التعديل'},
        },
  'sponsored': sponsored,
  'history': history,
});

BillingView _billing(String mode, {String? cycle, String? summary}) => BillingView.fromJson({
  'mode': mode,
  'feeExempt': false,
  'majorHotel': false,
  'contractSummary': summary == null ? null : {'en': summary, 'ar': summary},
  'plan': cycle == null ? null : {'cycle': cycle},
  'plans': [_plan('weekly'), _plan('monthly'), _plan('annual')].map((p) => {'plan': p, 'announcedSoon': true}).toList(),
  'payable': false,
});

void main() {
  test('the listing pill states keep approved and live apart and cover every status', () {
    final states = {for (final s in ListingStatus.values) s: gzListingState(s)};
    expect(states[ListingStatus.approved], GzStatus.listingApproved);
    expect(states[ListingStatus.active], GzStatus.listingActive);
    expect(states[ListingStatus.pendingReview], GzStatus.listingReview);
    expect(states[ListingStatus.unknown], GzStatus.listingDraft);
    expect({for (final s in ListingStatus.values.where((s) => s != ListingStatus.unknown)) states[s]}.length, 8);
  });

  group('GzAdPlanCard', () {
    testWidgets('rates soon: no number, choosing fires onSelect, one radio-like node', (tester) async {
      final handle = tester.ensureSemantics();
      var picks = 0;
      await pumpInputs(tester, GzAdPlanCard(plan: _adPlan('weekly'), onSelect: () => picks++));
      expect(find.text('Rates announced soon'), findsOneWidget);
      expect(find.textContaining('KD'), findsNothing);
      await tester.tap(find.byType(GzAdPlanCard));
      expect(picks, 1);
      expect(find.bySemanticsLabel('Choose Weekly'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('selected reads as selected and the border grows to the focus stroke', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInputs(tester, GzAdPlanCard(plan: _adPlan('monthly'), selected: true, onSelect: () {}));
      final node = tester.getSemantics(find.bySemanticsLabel('Choose Monthly'));
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(node.flagsCollection.isButton, isTrue);
      final chosen = tester.getSize(find.byType(GzAdPlanCard)).height;
      await pumpInputs(tester, GzAdPlanCard(plan: _adPlan('monthly'), onSelect: () {}));
      // +2 for the thicker border (1 dp more per side): the web card is 140 resting and 142 selected.
      expect(chosen - tester.getSize(find.byType(GzAdPlanCard)).height, 2);
      handle.dispose();
    });

    testWidgets('disabled does not fire', (tester) async {
      var picks = 0;
      await pumpInputs(tester, GzAdPlanCard(plan: _adPlan('annual'), disabled: true, onSelect: () => picks++));
      await tester.tap(find.byType(GzAdPlanCard), warnIfMissed: false);
      expect(picks, 0);
    });

    testWidgets('exempt says Exempt and shows no rate; a set rate shows the price and the period', (tester) async {
      await pumpInputs(tester, GzAdPlanCard(plan: _adPlan('monthly', fils: 45000), exempt: true));
      expect(find.text('Exempt'), findsOneWidget);
      expect(find.text('No fee for major hotels'), findsOneWidget);
      expect(find.textContaining('45'), findsNothing);
      await pumpInputs(tester, GzAdPlanCard(plan: _adPlan('monthly', fils: 45000)));
      expect(find.text('per month'), findsOneWidget);
      expect(find.byType(GzPrice), findsOneWidget);
    });

    testWidgets('the card is at least 44 dp high and the radio ring sits at the inline-start (right in Arabic)', (tester) async {
      await pumpInputs(tester, GzAdPlanCard(plan: _adPlan('weekly'), onSelect: () {}), lang: 'ar');
      final card = tester.getRect(find.byType(GzAdPlanCard));
      expect(card.height, greaterThanOrEqualTo(44));
      final name = tester.getRect(find.text('أسبوعي'));
      expect(name.right, greaterThan(card.center.dx));
    });
  });

  group('GzMajorHotelBadge', () {
    testWidgets('chip: one semantic node, 32 dp high; note adds the sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInputs(tester, const Column(children: [GzMajorHotelBadge(), GzMajorHotelBadge(variant: GzMajorHotelVariant.note)]));
      expect(tester.getSize(find.byType(GzMajorHotelBadge).first).height, 32);
      expect(find.textContaining('Major hotels pay no listing'), findsOneWidget);
      expect(find.bySemanticsLabel('Major hotel, Fee exempt'), findsOneWidget);
      handle.dispose();
    });
  });

  group('GzBillingCard', () {
    testWidgets('contract shows the summary and never a price', (tester) async {
      await pumpInputs(tester, GzBillingCard(billing: _billing('contract', summary: 'Terms as agreed')));
      expect(find.text('Business contract'), findsOneWidget);
      expect(find.text('Terms as agreed'), findsOneWidget);
      expect(find.byType(GzPrice), findsNothing);
    });

    testWidgets('plan shows the cycle and Rates announced soon; a major hotel adds the badge', (tester) async {
      await pumpInputs(tester, GzBillingCard(billing: _billing('plan', cycle: 'annual')));
      expect(find.text('Annual'), findsOneWidget);
      expect(find.text('Rates announced soon'), findsOneWidget);
      expect(find.byType(GzMajorHotelBadge), findsNothing);
      await pumpInputs(tester, GzBillingCard(billing: _billing('contract'), majorHotel: true), width: 450);
      expect(find.byType(GzMajorHotelBadge), findsOneWidget);
      expect(find.text('Terms as contracted'), findsOneWidget);
    });
  });

  group('GzProviderListingCard', () {
    testWidgets('the whole card is one target with one semantic node naming status, title and plan', (tester) async {
      final handle = tester.ensureSemantics();
      var opens = 0;
      await pumpInputs(
        tester,
        GzProviderListingCard(listing: _listing('pending_review', planCycle: 'weekly'), categoryName: const LocalizedText.same('Floral'), onOpen: () => opens++),
      );
      await tester.tap(find.text('Zahra florals'));
      expect(opens, 1);
      expect(find.bySemanticsLabel(RegExp('In review.*Zahra florals.*Weekly.*Rates announced soon')), findsOneWidget);
      expect(find.text('With the review team'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a rejection shows the first reason; exempt replaces the rates line', (tester) async {
      await pumpInputs(tester, GzProviderListingCard(listing: _listing('rejected', planCycle: 'monthly', reasons: ['wrong_category', 'unclear_pricing']), exempt: true));
      expect(find.text('Wrong category'), findsOneWidget);
      expect(find.text('Pricing is unclear'), findsNothing);
      expect(find.textContaining('Exempt', findRichText: true), findsOneWidget);
      expect(find.textContaining('Rates announced soon', findRichText: true), findsNothing);
    });

    testWidgets('live and sponsored shows the badge; a plan with an end date shows the date', (tester) async {
      await pumpInputs(tester, GzProviderListingCard(listing: _listing('active', planCycle: 'annual', endsOn: '2027-08-01', sponsored: true)));
      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.textContaining('Ends', findRichText: true), findsOneWidget);
    });

    testWidgets('RTL: the thumb sits at the right and the chevron after the text on the left; no onOpen means no chevron', (tester) async {
      await pumpInputs(tester, GzProviderListingCard(listing: _listing('draft'), onOpen: () {}), lang: 'ar');
      final thumb = tester.getRect(find.byIcon(GzIcons.megaphone));
      final chevron = tester.getRect(find.byIcon(GzIcons.chevronRight));
      expect(thumb.center.dx, greaterThan(chevron.center.dx));
      await pumpInputs(tester, GzProviderListingCard(listing: _listing('draft')));
      expect(find.byIcon(GzIcons.chevronRight), findsNothing);
    });
  });

  group('GzReviewTimeline', () {
    final history = [
      _decision('r1', null, 'draft', 'provider', '2026-11-11T13:20:00+03:00'),
      _decision('r2', 'draft', 'pending_review', 'provider', '2026-11-11T14:20:00+03:00'),
    ];

    testWidgets('in review: two recorded knots, then the review knot that is now and the one still open', (tester) async {
      await pumpInputs(tester, GzReviewTimeline(listing: _listing('pending_review', history: history)));
      final states = tester.widgetList<GzThreadKnot>(find.byType(GzThreadKnot)).map((k) => k.state).toList();
      expect(states, [GzKnotState.tied, GzKnotState.tied, GzKnotState.now, GzKnotState.open]);
      expect(find.text('A person at Ghazal reviews it'), findsOneWidget);
      expect(find.textContaining('Paying never publishes it by itself'), findsOneWidget);
    });

    testWidgets('live: nothing ahead; the last decision is by the system', (tester) async {
      final live = [
        ...history,
        _decision('r3', 'pending_review', 'approved', 'moderator', '2026-11-12T11:00:00+03:00', name: 'Hessa'),
        _decision('r4', 'approved', 'active', 'system', '2026-11-12T11:01:00+03:00'),
      ];
      await pumpInputs(tester, GzReviewTimeline(listing: _listing('active', history: live)));
      expect(tester.widgetList<GzThreadKnot>(find.byType(GzThreadKnot)).every((k) => k.state == GzKnotState.tied), isTrue);
      expect(find.textContaining('Ghazal review team · Hessa', findRichText: true), findsOneWidget);
      expect(find.text('Live on Ghazal'), findsOneWidget);
    });

    testWidgets('a rejection lists its reasons and the note, and says how long the plan is kept', (tester) async {
      final rejected = [
        ...history,
        _decision('r3', 'pending_review', 'rejected', 'moderator', '2026-11-12T11:00:00+03:00', codes: ['wrong_category', 'unclear_pricing'], note: 'Please fix it'),
      ];
      await pumpInputs(tester, GzReviewTimeline(listing: _listing('rejected', history: rejected, reasons: ['wrong_category']), planKeptUntil: DateTime.parse('2026-12-01T12:00:00+03:00')));
      expect(find.text('Wrong category'), findsOneWidget);
      expect(find.text('Pricing is unclear'), findsOneWidget);
      expect(find.text('Please fix it'), findsOneWidget);
      expect(find.textContaining('kept until', findRichText: true), findsOneWidget);
      expect(tester.widgetList<GzThreadKnot>(find.byType(GzThreadKnot)).last.state, GzKnotState.ended);
    });

    testWidgets('RTL: the rail sits at the right, times stay left-to-right figures', (tester) async {
      await pumpInputs(tester, GzReviewTimeline(listing: _listing('draft', history: [history.first])), lang: 'ar');
      final knot = tester.getRect(find.byType(GzThreadKnot).first);
      final title = tester.getRect(find.text('تم حفظ المسودة'));
      expect(knot.center.dx, greaterThan(title.center.dx));
    });
  });
}
