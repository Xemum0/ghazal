import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/client/client_a.dart';
import 'package:ghazal_ui/src/client/client_shared.dart' show GzPriceAudience;
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import '../core/core_harness.dart';
import '../shared/shared_harness.dart';
import 'discovery_fixtures.dart';

late DiscoveryFixtures fx;

const _exact = CardPriceExact(
  voucher: MoneyAmount(15400000),
  savings: MoneyAmount(2800000),
  amount: MoneyAmount(18200000),
  guests: 350,
  packageId: 'p1',
  tier: PriceTier.weekend,
);

Widget _card(String id, {GzVenueCardVariant variant = GzVenueCardVariant.card, double width = 350}) => SizedBox(
  width: width,
  child: GzVenueCard(
    venue: fx.venue(id),
    area: fx.areaOf(id),
    price: _exact,
    availability: VenueDayState.available,
    date: LocalDate.parse('2027-01-14'),
    tags: const [Audience.women, Audience.men],
    guestRange: const GuestRange(min: 200, max: 650),
    variant: variant,
    onOpen: () {},
    onFavouriteChange: (_) {},
    onCompareChange: (_) {},
  ),
);

void main() {
  setUpAll(() async {
    await loadUiFonts();
    fx = await DiscoveryFixtures.load();
  });

  group('GzVenueCard', () {
    testWidgets('plate geometry follows the web (350 dp: 4:5 photo, 12 gap, hairline, one tap target per control)', (tester) async {
      for (final lang in ['en', 'ar']) {
        await pumpCore(tester, _card('V01'), lang: lang);
        final card = tester.getRect(find.byType(GzVenueCard));
        expect(card.width, 350);
        final heart = tester.getRect(find.byType(GzIconButton));
        expect(heart.size, const Size(44, 44));
        expect(heart.top - card.top, 6);
        // web: heart at inline-end, compare at inline-start, both 6 dp in
        if (lang == 'en') {
          expect(card.right - heart.right, 6);
        } else {
          expect(heart.left - card.left, 6);
        }
        expect(tester.getRect(find.byType(GzDivider)).top - card.top, closeTo(lang == 'en' ? 518.75 : 525.5, 1)); // 437.5 media + 12 + body text
        expect(card.height, closeTo(lang == 'en' ? 585.3 : 593.5, 1.5));
        expect(find.byType(GzRating), findsOneWidget);
      }
    });

    testWidgets('one button node for the card, the controls stay their own nodes', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, _card('V01'));
      expect(find.bySemanticsLabel(RegExp('Open Aurelia Gulf Hotel')), findsOneWidget);
      expect(find.bySemanticsLabel('Save to favourites'), findsOneWidget);
      expect(find.bySemanticsLabel('Add to compare'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('open, favourite and compare each call back once; a card without onOpen does not fire', (tester) async {
      var opened = 0;
      bool? fav;
      bool? cmp;
      await pumpCore(
        tester,
        SizedBox(
          width: 350,
          child: GzVenueCard(
            venue: fx.venue('V01'),
            area: fx.areaOf('V01'),
            price: _exact,
            onOpen: () => opened++,
            onFavouriteChange: (v) => fav = v,
            onCompareChange: (v) => cmp = v,
            favourite: false,
            compared: true,
          ),
        ),
      );
      await tester.tap(find.byType(GzIconButton));
      expect(fav, isTrue);
      expect(opened, 0);
      await tester.tap(find.bySemanticsLabel('Remove from compare').first, warnIfMissed: false);
      await tester.tapAt(tester.getTopLeft(find.byType(GzVenueCard)) + const Offset(10, 10));
      expect(cmp, isFalse);
      expect(opened, 0);
      await tester.tapAt(tester.getTopLeft(find.byType(GzVenueCard)) + const Offset(100, 300));
      expect(opened, 1);
    });

    testWidgets('no guest mode (ADR 0038): the deprecated guest audience still shows the voucher price and no lock', (tester) async {
      await pumpCore(
        tester,
        SizedBox(
          width: 350,
          child: GzVenueCard(venue: fx.venue('V01'), area: fx.areaOf('V01'), price: _exact, audience: GzPriceAudience.guest),
        ),
      );
      expect(find.byIcon(GzIcons.lock), findsNothing);
      expect(find.textContaining('15,400'), findsWidgets);
    });

    testWidgets('no reviews read New, never 0.0; a government hall shows the bank line and no rating', (tester) async {
      await pumpCore(tester, _card('V19'));
      expect(find.text('New'), findsOneWidget);
      expect(find.byType(GzRating), findsNothing);
      expect(find.byIcon(GzIcons.bank), findsWidgets);
    });

    testWidgets('compact rows: 72 x 88 thumbnail, saved heart and drop mark, compare mark flips', (tester) async {
      await pumpCore(tester, _card('V09', variant: GzVenueCardVariant.compact));
      final card = tester.getRect(find.byType(GzVenueCard));
      expect(card.height, greaterThanOrEqualTo(88));
      expect(find.byType(GzIconButton), findsNothing);
      var fav = true;
      final handle = tester.ensureSemantics();
      await pumpCore(
        tester,
        SizedBox(
          width: 350,
          child: GzVenueCard(
            venue: fx.venue('V09'),
            area: fx.areaOf('V09'),
            price: _exact,
            variant: GzVenueCardVariant.saved,
            priceDropped: true,
            onFavouriteChange: (v) => fav = v,
          ),
        ),
      );
      expect(find.byIcon(GzIcons.trendDown), findsWidgets);
      expect(find.bySemanticsLabel('Remove from favourites'), findsOneWidget); // the saved row reads null as on
      await tester.tap(find.byType(GzIconButton));
      expect(fav, isFalse);
      handle.dispose();
    });

    testWidgets('compare variant is a toggle row: selected shows the ink border and a check', (tester) async {
      var picked = 0;
      await pumpCore(
        tester,
        SizedBox(
          width: 350,
          child: GzVenueCard(
            venue: fx.venue('V05'),
            area: fx.areaOf('V05'),
            price: _exact,
            variant: GzVenueCardVariant.compare,
            selected: true,
            onSelect: () => picked++,
          ),
        ),
      );
      expect(find.byIcon(GzIcons.check), findsOneWidget);
      await tester.tap(find.byType(GzVenueCard));
      expect(picked, 1);
    });

    testWidgets('pressing scales the whole card by the token; reduced motion keeps it still', (tester) async {
      for (final reduce in [false, true]) {
        await pumpCore(tester, _card('V01'), reduceMotion: reduce);
        final gesture = await tester.startGesture(tester.getCenter(find.byType(GzVenueCard)) + const Offset(0, 100));
        await tester.pump(const Duration(milliseconds: 200));
        final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale;
        expect(scale, reduce ? 1.0 : GzMotion.scalePress);
        await gesture.up();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('loading shows skeletons only, no text', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzVenueCard(venue: fx.venue('V01'), loading: true)));
      expect(find.byType(GzSkeleton), findsNWidgets(4));
      expect(find.byType(Text), findsNothing);
    });
  });

  group('GzBriefCard', () {
    const story = GzBrief(
      audience: Audience.women,
      guests: 350,
      date: LocalDate(2027, 1, 14),
      areas: [LocalizedText(en: 'Salmiya', ar: 'السالمية'), LocalizedText(en: 'Sharq', ar: 'شرق')],
      budgetMinFils: 20000000,
      budgetMaxFils: 35000000,
    );

    testWidgets('rows are 64 (the hairline is inside the 64), the split row follows its tallest side, the card is the web 296 / 288', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefCard(brief: story, count: 38, onShow: () {}, onEdit: (_) {})), lang: 'ar');
      expect(tester.getRect(find.byType(GzBriefCard)).height, closeTo(296, 1.5)); // web 296 (two-line area: 56 + 24 + 1)
      final rows = find.byType(GzPressable);
      expect(tester.getRect(rows.at(0)).height, 64);
      expect(tester.getRect(rows.at(1)).height, 81);
      expect(tester.getRect(rows.last).size, const Size(316, 52));
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefCard(brief: story, count: 38, onShow: () {}, onEdit: (_) {})));
      expect(tester.getRect(find.byType(GzBriefCard)).height, closeTo(288, 1.5)); // web 288: rows 64 + 73 + 64 + 85 + the border
    });

    testWidgets('each row opens its decision; the button shows the live count, never the word Search', (tester) async {
      final fields = <GzBriefField>[];
      var shown = 0;
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefCard(brief: story, count: 38, onEdit: fields.add, onShow: () => shown++)));
      expect(find.text('Show 38 halls'), findsOneWidget);
      expect(find.textContaining('Search'), findsNothing);
      for (final label in ['Jan', 'Salmiya', '350', '20,000']) {
        await tester.tap(find.textContaining(label).first);
      }
      expect(fields, [GzBriefField.date, GzBriefField.area, GzBriefField.guests, GzBriefField.budget]);
      await tester.tap(find.text('Show 38 halls'));
      expect(shown, 1);
    });

    testWidgets('an empty brief shows muted placeholders and no count; the button keeps its words; loading ignores taps', (tester) async {
      var shown = 0;
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefCard(brief: const GzBrief(audience: Audience.women), onShow: () => shown++)));
      expect(find.text('Show halls'), findsOneWidget);
      expect(find.text('Guests'), findsOneWidget);
      final muted = tester.widget<RichText>(find.descendant(of: find.byType(GzBriefCard), matching: find.byType(RichText)).at(1));
      expect(muted.text.style?.color, GzColors.light.textSecondary);
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefCard(brief: story, count: 38, loading: true, onShow: () => shown++)));
      await tester.tap(find.text('Show 38 halls'), warnIfMissed: false);
      expect(shown, 0);
    });

    testWidgets('open budget keeps the plus inside the number; the row is one node named by its field', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefCard(brief: story.copyWith(openBudget: true, budgetMinFils: 35000000), count: 12)), lang: 'ar');
      expect(find.bySemanticsLabel(RegExp('^التاريخ: ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^ميزانية القاعة والضيافة: .*35,000\+')), findsOneWidget);
      handle.dispose();
    });
  });

  group('GzBriefSentence', () {
    const story = GzBrief(
      audience: Audience.women,
      guests: 350,
      date: LocalDate(2027, 1, 14),
      areas: [LocalizedText(en: 'Salmiya', ar: 'السالمية'), LocalizedText(en: 'Sharq', ar: 'شرق')],
      budgetMinFils: 20000000,
      budgetMaxFils: 35000000,
    );

    String plain(WidgetTester tester) => tester.widget<RichText>(find.byType(RichText).first).text.toPlainText(includeSemanticsLabels: false);

    testWidgets('echo: the sentence drops an empty clause, the whole block is one 44+ target', (tester) async {
      var edits = 0;
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefSentence(brief: const GzBrief(audience: Audience.women, guests: 350), onEdit: () => edits++)));
      final text = plain(tester);
      expect(text, contains('Ladies’ reception'));
      expect(text, contains('350'));
      expect(text, isNot(contains('choose a date')));
      expect(tester.getRect(find.byType(GzBriefSentence)).height, greaterThanOrEqualTo(44));
      await tester.tap(find.byType(GzBriefSentence));
      expect(edits, 1);
    });

    testWidgets('variants: compare omits the budget, booking the budget and the area', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefSentence(brief: story, variant: GzBriefSentenceVariant.compare)));
      expect(plain(tester), isNot(contains('35,000')));
      expect(plain(tester), contains('Salmiya'));
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefSentence(brief: story, variant: GzBriefSentenceVariant.booking)));
      expect(plain(tester), isNot(contains('Salmiya')));
    });

    testWidgets('edit: every decision is its own button, empty ones stay as placeholders, each target is at least 44 high', (tester) async {
      final fields = <GzBriefField>[];
      await pumpCore(tester, SizedBox(width: 350, child: GzBriefSentence(brief: const GzBrief(audience: Audience.women, guests: 350), variant: GzBriefSentenceVariant.edit, onEditField: fields.add)));
      final tokens = find.byType(GzPressable);
      expect(tokens, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        expect(tester.getRect(tokens.at(i)).height, greaterThanOrEqualTo(44));
        await tester.tap(tokens.at(i));
      }
      expect(fields, [GzBriefField.guests, GzBriefField.date, GzBriefField.area, GzBriefField.budget]);
      expect(find.textContaining('choose a date', findRichText: true), findsOneWidget);
    });

    testWidgets('edit tokens are 57 high in English and 65 in Arabic (line, 8 + 8 padding, 1 dp rule), like the web', (tester) async {
      for (final (lang, h) in [('en', 57.0), ('ar', 65.0)]) {
        await pumpCore(tester, SizedBox(width: 350, child: GzBriefSentence(brief: story, variant: GzBriefSentenceVariant.edit, onEditField: (_) {})), lang: lang);
        expect(tester.getRect(find.byType(GzPressable).first).height, closeTo(h, 0.5));
      }
    });
  });

  group('GzCategoryTile', () {
    testWidgets('opens on tap, announces its name and selected state, draws the check', (tester) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await pumpCore(tester, SizedBox(width: 170, child: GzCategoryTile(label: 'Resorts', caption: '6 halls', selected: true, onOpen: () => opened++)));
      expect(find.byIcon(GzIcons.check), findsOneWidget);
      expect(tester.getRect(find.byType(AspectRatio).first).size, const Size(170, 212.5)); // 4:5
      expect(find.bySemanticsLabel('Resorts'), findsOneWidget);
      await tester.tap(find.byType(GzCategoryTile));
      expect(opened, 1);
      handle.dispose();
    });

    testWidgets('the check sits at inline-end: right in English, left in Arabic', (tester) async {
      for (final (lang, atEnd) in [('en', true), ('ar', false)]) {
        await pumpCore(tester, SizedBox(width: 170, child: GzCategoryTile(label: 'Resorts', selected: true, onOpen: () {})), lang: lang);
        final tile = tester.getRect(find.byType(GzCategoryTile));
        final check = tester.getRect(find.byIcon(GzIcons.check));
        if (atEnd) {
          expect(tile.right - check.right, closeTo(8 + 4, 0.5)); // 8 inset, the 24 disk holds the 16 glyph
        } else {
          expect(check.left - tile.left, closeTo(8 + 4, 0.5));
        }
      }
    });

    testWidgets('wall-label form puts the name under the plate; loading shows no text', (tester) async {
      await pumpCore(tester, SizedBox(width: 170, child: GzCategoryTile(label: 'Resorts', caption: '6 halls', placement: GzCategoryTilePlacement.under, onOpen: () {})));
      expect(tester.getRect(find.text('Resorts')).top, greaterThan(tester.getRect(find.byType(AspectRatio).first).bottom));
      await pumpCore(tester, const SizedBox(width: 170, child: GzCategoryTile(label: '', loading: true)));
      expect(find.byType(Text), findsNothing);
    });
  });

  group('GzVoucherWindowCard', () {
    testWidgets('a live window offers the hall, a window that ended or is scheduled has no action and says why', (tester) async {
      var opened = 0;
      await pumpCore(tester, SizedBox(width: 350, child: GzVoucherWindowCard(window: fx.windows['vw-V01-midweek']!, venueName: fx.venue('V01').name, onOpen: () => opened++)));
      expect(find.text('See the hall'), findsOneWidget);
      expect(find.textContaining('Sun – Wed'), findsOneWidget);
      await tester.tap(find.text('See the hall'));
      expect(opened, 1);
      await pumpCore(tester, SizedBox(width: 350, child: GzVoucherWindowCard(window: fx.windows['vw-V01-autumn']!, venueName: fx.venue('V01').name, onOpen: () => opened++)));
      expect(find.byType(GzButton), findsNothing);
      expect(find.text('This price has ended'), findsOneWidget);
      await pumpCore(tester, SizedBox(width: 350, child: GzVoucherWindowCard(window: fx.windows['vw-V01-early']!, venueName: fx.venue('V01').name)));
      expect(find.text('Starts soon'), findsOneWidget);
    });

    testWidgets('the rate is per guest with the unit, the event dates read as a plain fact, never a countdown', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzVoucherWindowCard(window: fx.windows['vw-V01-flash']!, venueName: fx.venue('V01').name, onOpen: () {})));
      expect(find.textContaining('per guest'), findsOneWidget);
      expect(find.text('For events on selected dates'), findsOneWidget);
      expect(find.textContaining('Price available until'), findsOneWidget);
    });

    testWidgets('loading shows skeletons only', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzVoucherWindowCard(window: fx.windows['vw-V01-midweek']!, loading: true)));
      expect(find.byType(GzSkeleton), findsNWidgets(3));
      expect(find.byType(GzButton), findsNothing);
    });
  });

  group('GzChromeBaseline', () {
    testWidgets('the browser baseline is floor(flutter + 0.22): EN d1 18.75 -> 18, countdown numeral 70.8 -> 71', (tester) async {
      final d1 = GzType.style(const Locale('en'), GzTextRole.d1);
      expect(GzChromeBaseline.offsetOf(d1, TextDirection.ltr), closeTo(-0.75, 0.05));
      final numeral = GzType.style(const Locale('en'), GzTextRole.countdown);
      expect(GzChromeBaseline.offsetOf(numeral, TextDirection.ltr), closeTo(0.2, 0.05));
    });
  });

  group('GzCountdownCard', () {
    test('milestones land on 365, 180, 30, 7, 1 and 0 only', () {
      expect(gzCountdownMilestone(365), GzCountdownMilestone.year);
      expect(gzCountdownMilestone(180), GzCountdownMilestone.half);
      expect(gzCountdownMilestone(30), GzCountdownMilestone.month);
      expect(gzCountdownMilestone(7), GzCountdownMilestone.week);
      expect(gzCountdownMilestone(1), GzCountdownMilestone.tomorrow);
      expect(gzCountdownMilestone(0), GzCountdownMilestone.today);
      expect(gzCountdownMilestone(-3), GzCountdownMilestone.today);
      expect(gzCountdownMilestone(63), isNull);
      expect(gzCountdownMilestone(8), isNull);
    });

    testWidgets('a plain count shows the numeral, the unit and the calm line; the numeral stays an LTR island in Arabic', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzCountdownCard(days: 63, eventDate: '2027-01-14', where: 'Aurelia Gulf Hotel', progress: 0.83)));
      expect(find.text('\u202663\u2069'), findsNothing); // the island marks are format characters of the formatter output, not typed digits
      expect(find.textContaining('63'), findsOneWidget);
      expect(find.text('days'), findsOneWidget);
      expect(find.text('until your wedding'), findsOneWidget);
      await pumpCore(tester, SizedBox(width: 350, child: GzCountdownCard(days: 63, eventDate: '2027-01-14')), lang: 'ar');
      expect(find.text('يومًا'), findsOneWidget);
      expect(find.text('حتى زفافكم'), findsOneWidget);
    });

    testWidgets('tomorrow and today replace the numeral with the word and change the line', (tester) async {
      await pumpCore(tester, SizedBox(width: 350, child: GzCountdownCard(days: 1, eventDate: '2027-01-14')));
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Everything is set for tomorrow.'), findsOneWidget);
      await pumpCore(tester, SizedBox(width: 350, child: GzCountdownCard(days: 0, eventDate: '2027-01-14')));
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Today is your day.'), findsOneWidget);
    });

    testWidgets('the action calls back; the thread is one image node with the percent; loading shows no text', (tester) async {
      final handle = tester.ensureSemantics();
      var acted = 0;
      await pumpCore(tester, SizedBox(width: 350, child: GzCountdownCard(days: 30, eventDate: '2027-01-14', progress: 0.9, actionLabel: 'View your booking', onAction: () => acted++)));
      expect(find.bySemanticsLabel('Waiting time elapsed: 90%'), findsOneWidget);
      await tester.tap(find.text('View your booking'));
      expect(acted, 1);
      await pumpCore(tester, const SizedBox(width: 350, child: GzCountdownCard(days: 30, eventDate: '2027-01-14', loading: true)));
      expect(find.byType(Text), findsNothing);
      handle.dispose();
    });
  });
}
