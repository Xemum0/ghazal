import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show AppNotification, Booking, BookingStatus, MoneyAmount, NotificationChannel, PackageBriefPrice;
import 'package:ghazal_ui/src/brand/gz_thread_knot.dart';
import 'package:ghazal_ui/src/client/client_bits.dart' show GzPriceAudience;
import 'package:ghazal_ui/src/client/client_d.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import '../core/core_harness.dart';
import '../shared/shared_harness.dart';
import 'client_d_fixtures.dart';

late ClientDFixtures fx;

Widget _thread(
  Booking b, {
  GzBookingThreadVariant variant = GzBookingThreadVariant.full,
  GzDraw draw = GzDraw.off,
  bool onDark = false,
  GzThreadKey? pop,
}) => SizedBox(
  width: 350,
  child: GzBookingThread(booking: b, variant: variant, draw: draw, onDark: onDark, pop: pop),
);

void main() {
  setUpAll(() async {
    await loadUiFonts();
    fx = await ClientDFixtures.load();
  });

  group('GzBookingThread model', () {
    List<GzKnotState> states(BookingStatus s, {Booking? b}) => [
      for (final k in gzThreadModel(status: s, recorded: b?.thread, expiredReason: b?.expiredReason)) k.state,
    ];

    test('every ADR 0033 status ties the knots it has reached', () {
      const T = GzKnotState.tied, N = GzKnotState.now, O = GzKnotState.open, E = GzKnotState.ended;
      expect(states(BookingStatus.pending), [T, T, N, O, O]);
      expect(states(BookingStatus.approved), [T, T, T, N, O]);
      expect(states(BookingStatus.confirmed), [T, T, T, T, N]);
      expect(states(BookingStatus.redeemed), [T, T, T, T, T]);
      expect(states(BookingStatus.declined), [T, T, E, O, O]);
      expect(states(BookingStatus.expired), [T, T, E, O, O]);
    });

    test('a lapsed confirmation ends the Confirmation knot, a cancel ends after the reached ones', () {
      expect(states(BookingStatus.expired, b: fx.hero['lapsed']), [
        GzKnotState.tied,
        GzKnotState.tied,
        GzKnotState.tied,
        GzKnotState.ended,
        GzKnotState.open,
      ]);
      final cancelled = gzThreadModel(status: BookingStatus.cancelled, reached: 2);
      expect(cancelled[3].state, GzKnotState.ended);
      expect(cancelled[3].endedTone, GzKnotEndedTone.neutral);
    });

    test('the declined knot is danger, an expired one neutral', () {
      expect(gzThreadModel(status: BookingStatus.declined)[2].endedTone, GzKnotEndedTone.danger);
      expect(gzThreadModel(status: BookingStatus.expired)[2].endedTone, GzKnotEndedTone.neutral);
    });
  });

  group('GzBookingThread widget', () {
    testWidgets('full: five knots, one word under the active knot, a deadline note, one semantics node', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, _thread(fx.hero['approved']!));
      expect(find.byType(GzThreadKnot), findsNWidgets(5));
      expect(find.text('Confirm'), findsOneWidget); // the step form while the booking is Approved
      expect(find.text('Request'), findsNothing); // tied knots carry no word
      expect(find.byIcon(GzIcons.timer), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Booking progress: Confirm, Step 4 of 5')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('full: labels all names every knot, none names none', (tester) async {
      await pumpCore(
        tester,
        SizedBox(
          width: 350,
          child: GzBookingThread(booking: fx.hero['confirmed'], draw: GzDraw.off, labels: GzThreadLabels.all),
        ),
      );
      expect(find.text('Voucher'), findsOneWidget);
      expect(find.text('At venue'), findsOneWidget);
      await pumpCore(
        tester,
        SizedBox(
          width: 350,
          child: GzBookingThread(booking: fx.hero['confirmed'], draw: GzDraw.off, labels: GzThreadLabels.none),
        ),
      );
      expect(find.text('At venue'), findsNothing);
    });

    testWidgets('declined ends Approval in a danger knot with its reason as the note', (tester) async {
      await pumpCore(tester, _thread(fx.hero['declined']!));
      expect(find.text('Declined'), findsOneWidget);
    });

    testWidgets('RTL: the thread starts at the right edge, numbers stay LTR', (tester) async {
      await pumpCore(tester, _thread(fx.hero['approved']!), lang: 'ar');
      final knots = find.byType(GzThreadKnot);
      expect(tester.getCenter(knots.first).dx, greaterThan(tester.getCenter(knots.last).dx));
      expect(find.textContaining(String.fromCharCode(0x2066), findRichText: true), findsWidgets);
    });

    testWidgets('draw-on plays 480 ms once; reduced motion shows the finished thread at once', (tester) async {
      await pumpCore(tester, _thread(fx.hero['approved']!, draw: GzDraw.mount));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 1200));
      expect(tester.hasRunningAnimations, isFalse);
      await pumpCore(tester, _thread(fx.hero['approved']!, draw: GzDraw.mount), reduceMotion: true);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('pop: the named knot pops once, then settles', (tester) async {
      await pumpCore(tester, _thread(fx.hero['approved']!, pop: GzThreadKey.approval));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('compact: five 12 dp knots then one line with the current glyph and word', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, _thread(fx.hero['pending']!, variant: GzBookingThreadVariant.compact));
      expect(find.byType(GzThreadKnot), findsNWidgets(5));
      expect(find.text('Approval'), findsOneWidget);
      expect(find.byIcon(GzIcons.verified), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Booking progress: Approval, Step 3 of 5')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('vertical: past knots with absolute times, nothing after a terminal knot, labels in long form', (tester) async {
      await pumpCore(tester, _thread(fx.hero['declined']!, variant: GzBookingThreadVariant.vertical));
      expect(find.byType(GzThreadKnot), findsNWidgets(3));
      expect(find.text('Voucher bought'), findsOneWidget);
      expect(find.text('Venue approval'), findsOneWidget);
      await pumpCore(tester, _thread(fx.hero['approved']!, variant: GzBookingThreadVariant.vertical));
      expect(find.byType(GzThreadKnot), findsNWidgets(5));
      expect(find.text('Your confirmation'), findsOneWidget); // a step still ahead names the step, not a result
    });

    testWidgets('on dark: renders on the ink knot tokens without error', (tester) async {
      await pumpCore(tester, _thread(fx.hero['confirmed']!, onDark: true));
      expect(find.byType(GzThreadKnot), findsNWidgets(5));
    });
  });

  group('GzBookingCard', () {
    Widget card(Booking b, {GzBookingCardVariant variant = GzBookingCardVariant.card, VoidCallback? onOpen, bool loading = false}) => SizedBox(
      width: 350,
      child: GzBookingCard(
        booking: b,
        target: ClientDFixtures.target,
        voucherCode: 'GV-2611-K7QM',
        variant: variant,
        onOpen: onOpen,
        loading: loading,
      ),
    );

    testWidgets('card: name, status, three facts, compact thread and the reference; one tappable node', (tester) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await pumpCore(tester, card(fx.hero['pending']!, onOpen: () => opened++));
      expect(find.text('Aurelia Gulf Hotel'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.textContaining('K7QM'), findsOneWidget);
      expect(find.text('Voucher price'), findsOneWidget);
      expect(find.textContaining('15,400'), findsOneWidget);
      expect(find.byType(GzBookingThread), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Aurelia Gulf Hotel, Open booking GZ-2611-0147')), findsOneWidget);
      await tester.tap(find.byType(GzBookingCard));
      expect(opened, 1);
      handle.dispose();
    });

    testWidgets('row: thumbnail, name, date and status only (no facts, no thread)', (tester) async {
      await pumpCore(tester, card(fx.hero['declined']!, variant: GzBookingCardVariant.row));
      expect(find.byType(GzBookingThread), findsNothing);
      expect(find.text('Voucher price'), findsNothing);
      expect(find.byIcon(GzIcons.calendar), findsOneWidget);
    });

    testWidgets('an approved request carries the calm confirm line, a pending one does not', (tester) async {
      await pumpCore(tester, card(fx.hero['approved']!));
      expect(find.byIcon(GzIcons.hourglass), findsWidgets);
      expect(find.textContaining('Confirm by'), findsOneWidget);
      await pumpCore(tester, card(fx.hero['pending']!));
      expect(find.textContaining('Confirm by'), findsNothing);
    });

    testWidgets('a date proposed by the venue adds a second pill beside the status', (tester) async {
      await pumpCore(tester, card(fx.hero['counter_offer']!));
      expect(find.byType(GzStatusPill), findsNWidgets(2));
    });

    testWidgets('loading shows skeletons and no content; Arabic keeps the reference as an LTR run', (tester) async {
      await pumpCore(tester, card(fx.hero['pending']!, loading: true));
      expect(find.text('Aurelia Gulf Hotel'), findsNothing);
      expect(find.byType(GzSkeleton), findsWidgets);
      await pumpCore(tester, card(fx.hero['pending']!), lang: 'ar');
      expect(find.textContaining('GZ-2611-0147', findRichText: true), findsOneWidget);
      expect(find.text('فندق أوريليا الخليج'), findsOneWidget);
    });
  });

  group('GzPackageCard', () {
    GzPackagePrice price({bool voucher = true}) => GzPackagePrice.fromJson({
      'standard': {'fils': 18200000, 'currency': 'KWD'},
      'voucher': voucher ? {'fils': 15400000, 'currency': 'KWD'} : null,
      'savings': voucher ? {'fils': 2800000, 'currency': 'KWD'} : null,
      'voucherEligible': voucher,
      'perGuest': {'fils': 52000, 'currency': 'KWD'},
      'flat': null,
      'voucherPerGuest': voucher ? {'fils': 44000, 'currency': 'KWD'} : null,
      'voucherFlat': null,
    });
    Widget card({
      bool selected = false,
      VoidCallback? onSelect,
      bool unavailable = false,
      GzPriceAudience audience = GzPriceAudience.member,
      bool loading = false,
    }) => SizedBox(
      width: 350,
      child: GzPackageCard(
        pkg: fx.packages['V01-ladies-weekend']!,
        price: loading ? null : price(),
        guests: 350,
        selected: selected,
        onSelect: onSelect,
        unavailable: unavailable,
        audience: audience,
        loading: loading,
      ),
    );

    testWidgets('a member sees the voucher total, the struck standard price and the saving', (tester) async {
      await pumpCore(tester, card(onSelect: () {}));
      expect(find.textContaining('44'), findsWidgets);
      expect(find.textContaining('Save'), findsOneWidget);
      expect(find.byIcon(GzIcons.lock), findsNothing);
    });

    testWidgets('no guest mode (ADR 0038): the deprecated guest audience shows the voucher total and the saving, never a lock', (tester) async {
      await pumpCore(tester, card(onSelect: () {}, audience: GzPriceAudience.guest));
      expect(find.byIcon(GzIcons.lock), findsNothing);
      expect(find.textContaining('44'), findsWidgets);
      expect(find.textContaining('Save'), findsOneWidget);
    });

    testWidgets('selecting calls back; unavailable does not and shows the reason', (tester) async {
      var picked = 0;
      await pumpCore(tester, card(onSelect: () => picked++));
      await tester.tap(find.text('Ladies\u2019 Reception, Weekend'));
      expect(picked, 1);
      await pumpCore(tester, card(onSelect: () => picked++, unavailable: true));
      await tester.tap(find.text('Ladies\u2019 Reception, Weekend'));
      expect(picked, 1);
      expect(find.text('Not available on your date'), findsOneWidget);
    });

    testWidgets('selected is a checked radio with the word for assistive technology; the choice is a 44 dp target', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, card(selected: true, onSelect: () {}));
      expect(find.bySemanticsLabel(RegExp('Selected')), findsOneWidget);
      expect(tester.getSize(find.byType(GzPackageCard)).height, greaterThan(GzSize.touchMin));
      handle.dispose();
    });

    testWidgets('inclusions collapse to five and "Show all" expands them', (tester) async {
      await pumpCore(tester, card(onSelect: () {}));
      final before = find.byIcon(GzIcons.check).evaluate().length;
      expect(before, 5);
      await tester.tap(find.textContaining('Show all'));
      await tester.pump();
      expect(find.byIcon(GzIcons.check).evaluate().length, greaterThan(5));
      expect(find.text('Show fewer'), findsOneWidget);
    });

    testWidgets('loading shows skeletons only', (tester) async {
      await pumpCore(tester, card(loading: true));
      expect(find.byType(GzSkeleton), findsWidgets);
      expect(find.text('Ladies\u2019 Reception, Weekend'), findsNothing);
    });

    test('fromOffer keeps the package unit prices and the offer totals', () {
      final p = GzPackagePrice.fromOffer(
        fx.packages['V01-ladies-weekend']!,
        PackageBriefPrice(
          standard: const MoneyAmount(18200000),
          voucher: const MoneyAmount(15400000),
          savings: const MoneyAmount(2800000),
          voucherOffered: true,
          unit: fx.packages['V01-ladies-weekend']!.priceUnit,
        ),
      );
      expect(p.perGuest!.fils, 48000);
      expect(p.voucherPerGuest!.fils, 40500);
      expect(p.voucherEligible, isTrue);
    });
  });

  group('GzPriceBreakdown', () {
    Widget bd(
      Booking b, {
      GzBreakdownStage stage = GzBreakdownStage.review,
      bool showLines = true,
      bool showSettlement = true,
      bool loading = false,
    }) => SizedBox(
      width: 350,
      child: GzPriceBreakdown(
        lines: b.lines,
        totals: b.totals,
        stage: stage,
        venueName: 'Aurelia Gulf Hotel',
        showLines: showLines,
        showSettlement: showSettlement,
        loading: loading,
      ),
    );

    testWidgets('lines, totals and who is paid: the KD 2 voucher to Ghazal and the voucher total to the venue', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCore(tester, bd(fx.hero['pending']!));
      expect(find.text('Voucher price'), findsOneWidget);
      expect(find.text('You save'), findsOneWidget);
      expect(find.text('Who you pay'.toUpperCase()), findsOneWidget);
      expect(find.text('Aurelia Gulf Hotel · directly'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'KD\s2\.000')), findsOneWidget); // the KD 2 voucher, paid to Ghazal once
      expect(find.bySemanticsLabel(RegExp(r'KD\s15,400\.000')), findsWidgets);
      expect(find.text('Nothing more to pay Ghazal.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('no deposit, balance or refund wording anywhere (ADR 0033)', (tester) async {
      await pumpCore(tester, bd(fx.hero['confirmed']!, stage: GzBreakdownStage.confirmed));
      for (final w in ['Deposit', 'Balance', 'Refund', 'Commission', 'VAT']) {
        expect(find.textContaining(w, findRichText: true), findsNothing, reason: w);
      }
      expect(find.text('Pay the venue directly, then show your voucher code.'), findsOneWidget);
    });

    testWidgets('redeemed drops the reassurance note; showLines and showSettlement hide their blocks', (tester) async {
      await pumpCore(tester, bd(fx.hero['redeemed']!, stage: GzBreakdownStage.redeemed, showLines: false));
      expect(find.text('Nothing more to pay Ghazal.'), findsNothing);
      expect(find.text('Settled with the venue. The voucher was redeemed.'), findsOneWidget);
      await pumpCore(tester, bd(fx.hero['redeemed']!, stage: GzBreakdownStage.redeemed, showLines: false, showSettlement: false));
      expect(find.text('Who you pay'.toUpperCase()), findsNothing);
    });

    testWidgets('loading shows skeleton rows', (tester) async {
      await pumpCore(tester, bd(fx.hero['pending']!, loading: true));
      expect(find.byType(GzSkeleton), findsNWidgets(7));
      expect(find.text('Voucher price'), findsNothing);
    });

    testWidgets('Arabic puts amounts in LTR islands and keeps the settlement sentence', (tester) async {
      await pumpCore(tester, bd(fx.hero['pending']!), lang: 'ar');
      expect(find.text('لا مبلغ إضافي لغزل.'), findsOneWidget);
    });
  });

  group('GzNotificationRow', () {
    testWidgets('unread: gold bead and the word for assistive technology; tapping opens', (tester) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      final n = fx.notifications.firstWhere((x) => !x.read);
      await pumpCore(
        tester,
        SizedBox(
          width: 350,
          child: GzNotificationRow(notification: n, onOpen: () => opened++),
        ),
      );
      expect(find.byType(GzThreadBead), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Unread')), findsOneWidget);
      await tester.tap(find.byType(GzNotificationRow));
      expect(opened, 1);
      handle.dispose();
    });

    testWidgets('read: no bead; marketing carries the quiet Offer tag; the row is at least 64 dp', (tester) async {
      final base = fx.notifications.first;
      final read = AppNotification.fromJson({...base.toJson(), 'read': true, 'channel': NotificationChannel.marketing.value});
      await pumpCore(
        tester,
        SizedBox(
          width: 350,
          child: GzNotificationRow(notification: read, onOpen: () {}),
        ),
      );
      expect(find.byType(GzThreadBead), findsNothing);
      expect(find.text('Offer'), findsOneWidget);
      expect(tester.getSize(find.byType(GzNotificationRow)).height, greaterThanOrEqualTo(GzSize.rowMin));
    });

    testWidgets('last row has no hairline; Arabic body keeps its number isolates', (tester) async {
      await pumpCore(
        tester,
        SizedBox(
          width: 350,
          child: GzNotificationRow(notification: fx.notifications.first, last: true, onOpen: () {}),
        ),
        lang: 'ar',
      );
      expect(find.textContaining(String.fromCharCode(0x2066), findRichText: true), findsWidgets);
    });
  });
}
