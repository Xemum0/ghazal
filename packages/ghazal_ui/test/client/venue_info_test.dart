import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/app/gz_host.dart';
import 'package:ghazal_ui/src/client/client_b.dart';
import 'package:ghazal_ui/src/foundation.dart' show GzIcon;

List<Map<String, Object?>> _seed(String name) => (jsonDecode(File('../ghazal_mock_api/assets/seed/$name.seed.json').readAsStringSync()) as List)
    .map((e) => (e as Map).cast<String, Object?>())
    .toList();

late Venue _venue;
late List<AmenityDef> _defs;
late List<Review> _reviews;

Future<void> _pump(WidgetTester tester, Widget child, {String lang = 'en', double width = 390}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, 6000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GzHost(
      locale: Locale(lang),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() {
    _venue = Venue.fromJson(_seed('Venue').firstWhere((v) => v['id'] == 'V01'));
    _defs = _seed('AmenityDef').map(AmenityDef.fromJson).toList();
    _reviews = _seed('Review').map(Review.fromJson).where((r) => r.venueId == 'V01').toList();
  });

  group('GzAmenityGrid', () {
    testWidgets('collapsedCount shows that many, "Show all" reveals the rest and flips to "Show fewer"', (tester) async {
      await _pump(tester, GzAmenityGrid(amenities: _venue.amenities, defs: _defs, collapsedCount: 4), width: 1200);
      final collapsed = find.byType(GzIcon).evaluate().length;
      expect(find.textContaining('Show all'), findsOneWidget);
      await tester.tap(find.textContaining('Show all'));
      await tester.pump();
      expect(find.byType(GzIcon).evaluate().length, greaterThan(collapsed));
      expect(find.text('Show fewer'), findsOneWidget);
    });

    testWidgets('three states always carry icon and words; an extra shows its price anchor', (tester) async {
      await _pump(tester, GzAmenityGrid(amenities: _venue.amenities, defs: _defs), width: 1200);
      expect(find.text('Included'), findsWidgets);
      expect(find.textContaining('Extra'), findsWidgets);
      expect(find.textContaining('KD'), findsWidgets);
    });

    testWidgets('an amenity without a registry entry is skipped; groups have headings', (tester) async {
      await _pump(
        tester,
        GzAmenityGrid(
          amenities: const [VenueAmenity(amenityId: 'nope', state: AmenityState.included)],
          defs: _defs,
        ),
      );
      expect(find.text('Included'), findsNothing);
      await _pump(tester, GzAmenityGrid(amenities: _venue.amenities, defs: _defs), width: 1200);
      expect(find.text('Spaces'), findsOneWidget);
    });
  });

  group('GzPolicyList and GzFaqAccordion', () {
    testWidgets('policy rows are labelled facts, extra terms follow, and the semantics say label and value', (tester) async {
      final handle = tester.ensureSemantics();
      final facts = _venue.halls.first.sections.first.policy;
      await _pump(
        tester,
        GzPolicyList(
          facts: facts,
          extra: const [GzPolicyTerm(label: 'Dress code', value: 'Modest')],
        ),
        width: 1200,
      );
      expect(find.text('Photography'), findsOneWidget);
      expect(find.text('Dress code'), findsOneWidget);
      expect(find.text('Modest'), findsOneWidget);
      expect(find.bySemanticsLabel('Photography'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('FAQ: single open, the first one opens by default', (tester) async {
      final faq = _venue.faq;
      await _pump(tester, GzFaqAccordion(items: faq, defaultOpenId: faq.first.id));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(faq.first.answer.of('en')), findsOneWidget);
      await tester.tap(find.text(faq[1].question.of('en')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(faq[1].answer.of('en')), findsOneWidget);
    });
  });

  group('GzMapPreview', () {
    testWidgets('drive time from the origin, address, and Open in Maps calls back', (tester) async {
      var opened = 0;
      await _pump(
        tester,
        GzMapPreview(
          venue: _venue,
          areaName: 'Sharq',
          origin: const GzMapOrigin(id: 'ref-salmiya', name: 'Salmiya'),
          onOpen: () => opened++,
        ),
        width: 1200,
      );
      expect(find.textContaining('from Salmiya'), findsOneWidget);
      expect(find.textContaining('Sharq'), findsWidgets);
      await tester.tap(find.text('Open in Maps'));
      expect(opened, 1);
    });

    testWidgets('no origin or no drive time: no drive line', (tester) async {
      await _pump(tester, GzMapPreview(venue: _venue, areaName: 'Sharq'), width: 1200);
      expect(find.textContaining('from'), findsNothing);
    });

    testWidgets('the plate is 16:10 and names the venue for assistive tech', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, GzMapPreview(venue: _venue, areaName: 'Sharq'));
      expect(find.bySemanticsLabel(RegExp('^Location of ')), findsOneWidget);
      final plate = tester.getSize(find.byType(AspectRatio).first);
      expect(plate.width / plate.height, closeTo(1.6, 0.01));
      handle.dispose();
    });
  });

  group('reviews', () {
    Review plain() => _reviews.firstWhere((r) => r.ownerReply == null);

    testWidgets('long text collapses behind Read more and expands', (tester) async {
      final r = plain();
      final long = r.copyWith(
        text: LocalizedText(en: '${r.text.en} ${r.text.en} ${r.text.en}', ar: '${r.text.ar} ${r.text.ar} ${r.text.ar}'),
        origin: WireLang.en,
      );
      await _pump(tester, GzReviewCard(review: long), width: 1200);
      expect(find.text('Read more'), findsOneWidget);
      await tester.tap(find.text('Read more'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('a short review has no Read more; an anonymous guest has no monogram initial of the author', (tester) async {
      final short = plain().copyWith(
        text: const LocalizedText(en: 'Lovely hall.', ar: 'قاعة جميلة.'),
        origin: WireLang.en,
        anonymous: true,
      );
      await _pump(tester, GzReviewCard(review: short), width: 1200);
      expect(find.text('Read more'), findsNothing);
      expect(find.text('Anonymous guest'), findsOneWidget);
    });

    testWidgets('the owner reply is set apart with the venue name', (tester) async {
      final replied = _reviews.firstWhere((r) => r.ownerReply != null);
      await _pump(tester, GzReviewCard(review: replied, venueName: 'Aurelia Gulf Hotel'), width: 1200);
      expect(find.textContaining('Reply from Aurelia Gulf Hotel'), findsOneWidget);
    });

    testWidgets('a verified booking shows its mark; the text keeps its own direction (Arabic review in an English UI is RTL)', (tester) async {
      final r = plain().copyWith(
        verifiedBooking: true,
        origin: WireLang.ar,
        text: const LocalizedText(en: 'x', ar: 'قاعة جميلة جدا'),
      );
      await _pump(tester, GzReviewCard(review: r), width: 1200);
      expect(find.text('Verified booking'), findsOneWidget);
      final d = Directionality.of(tester.element(find.text('قاعة جميلة جدا')));
      expect(d, TextDirection.rtl);
    });

    testWidgets('RatingSummary: "New" with no reviews, never 0.0; with reviews the average, count and four bars', (tester) async {
      await _pump(tester, const GzRatingSummary(rating: RatingSummary(average: null, count: 0, categories: null)));
      expect(find.text('New'), findsOneWidget);
      expect(find.textContaining('0.0'), findsNothing);
      await _pump(tester, GzRatingSummary(rating: _venue.rating), width: 1200);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Venue'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
    });
  });
}
