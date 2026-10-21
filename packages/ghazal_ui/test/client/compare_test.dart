import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/app/gz_host.dart';
import 'package:ghazal_ui/src/client/client_b.dart';
import 'package:ghazal_ui/src/foundation.dart' show GzColors;

List<Map<String, Object?>> _seed(String name) => (jsonDecode(File('../ghazal_mock_api/assets/seed/$name.seed.json').readAsStringSync()) as List)
    .map((e) => (e as Map).cast<String, Object?>())
    .toList();

late List<VenueSummary> _venues;

VenueSummary _v(String id) => _venues.firstWhere((v) => v.id == id);

CompareColumn _col(
  String id, {
  String channel = 'ghazal_voucher',
  String? availability = 'available',
  int? voucher = 15400000,
  int? price = 18200000,
  int maxGuests = 500,
  bool fits = true,
  String? valet = 'included',
  bool bestPrice = false,
  double? rating = 4.5,
}) => CompareColumn.fromJson({
  'venue': _seed('VenueSummary').firstWhere((v) => v['id'] == id),
  'channel': channel,
  'availability': availability,
  'price': price == null ? null : {'fils': price, 'currency': 'KWD'},
  'voucherPrice': voucher == null ? null : {'fils': voucher, 'currency': 'KWD'},
  'savings': voucher == null || price == null ? null : {'fils': price - voucher, 'currency': 'KWD'},
  'fromPerGuest': null,
  'fromVoucherPerGuest': null,
  'maxGuests': maxGuests,
  'fits': fits,
  'valet': valet,
  'photography': 'allowed',
  'rating': {'average': rating, 'count': 12, 'categories': null},
  'distance': {'km': 5.0, 'minutes': 12},
  'structures': ['per_person'],
  'packages': {'count': 0, 'from': null, 'fromVoucher': null},
  'best': {'price': bestPrice, 'nearest': false, 'fit': false},
});

Future<void> _pump(WidgetTester tester, Widget child, {String lang = 'en', bool reduceMotion = false, double width = 390}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, 6000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GzHost(
      locale: Locale(lang),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SingleChildScrollView(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  setUpAll(() => _venues = _seed('VenueSummary').map(VenueSummary.fromJson).toList());

  group('GzCompareTray', () {
    testWidgets('one hall: the hint, no action, a quiet plus in the first empty slot', (tester) async {
      var opened = 0;
      final handle = tester.ensureSemantics();
      await _pump(tester, GzCompareTray(venues: [_v('V01')], onOpen: () => opened++));
      await _settle(tester);
      expect(find.bySemanticsLabel('Add one more to compare'), findsOneWidget);
      expect(find.text('Compare (2)'), findsNothing);
      expect(find.bySemanticsLabel('Empty slot 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Empty slot 3'), findsOneWidget);
      expect(opened, 0);
      handle.dispose();
    });

    testWidgets('two halls: Compare (2) opens, remove and clear call back with the hall id', (tester) async {
      var opened = 0, cleared = 0;
      final removed = <String>[];
      await _pump(tester, GzCompareTray(venues: [_v('V01'), _v('V05')], onOpen: () => opened++, onClear: () => cleared++, onRemove: removed.add));
      await _settle(tester);
      await tester.tap(find.textContaining('Compare'));
      expect(opened, 1);
      await tester.tap(find.bySemanticsLabel(RegExp('^Remove .* from compare')).first);
      expect(removed, ['V01']);
      await tester.tap(find.bySemanticsLabel('Clear the comparison'));
      expect(cleared, 1);
    });

    testWidgets('the section carries the n/3 pair in its accessible name', (tester) async {
      await _pump(tester, GzCompareTray(venues: [_v('V01'), _v('V05'), _v('V07')]));
      await _settle(tester);
      expect(find.bySemanticsLabel(RegExp(r'Compare \(.*2.*/.*3.*\)|Compare \(.*3.*/.*3.*\)')), findsWidgets);
    });

    testWidgets('remove targets are 44 x 44', (tester) async {
      await _pump(tester, GzCompareTray(venues: [_v('V01'), _v('V05')], onRemove: (_) {}));
      await _settle(tester);
      final size = tester.getSize(find.bySemanticsLabel(RegExp('^Remove .* from compare')).first);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('collapsed pill shows the count and expands on tap', (tester) async {
      var expanded = 0;
      await _pump(tester, GzCompareTray(venues: [_v('V01'), _v('V05')], collapsed: true, onExpand: () => expanded++));
      await _settle(tester);
      expect(find.text('Compare'), findsOneWidget);
      expect(find.textContaining('2'), findsOneWidget);
      await tester.tap(find.text('Compare'));
      expect(expanded, 1);
      expect(tester.getSize(find.byType(GzCompareTray)).height, greaterThanOrEqualTo(44));
    });

    testWidgets('an empty tray draws nothing', (tester) async {
      await _pump(tester, const GzCompareTray(venues: []));
      expect(tester.getSize(find.byType(GzCompareTray)).height, 0);
    });

    testWidgets('RTL: the first slot sits at the start (right) edge, English at the left', (tester) async {
      await _pump(
        tester,
        GzCompareTray(venues: [_v('V01'), _v('V05')], onRemove: (_) {}),
        lang: 'ar',
      );
      await _settle(tester);
      final ar = tester.getCenter(find.bySemanticsLabel(RegExp('^إزالة .* من المقارنة')).first).dx;
      await _pump(tester, GzCompareTray(venues: [_v('V01'), _v('V05')], onRemove: (_) {}));
      await _settle(tester);
      final en = tester.getCenter(find.bySemanticsLabel(RegExp('^Remove .* from compare')).first).dx;
      expect(ar, greaterThan(195));
      expect(en, lessThan(195));
    });

    testWidgets('insertion rises 16 dp; reduced motion only fades', (tester) async {
      await _pump(tester, GzCompareTray(venues: [_v('V01'), _v('V05')]));
      double top() => tester.getTopLeft(find.descendant(of: find.byType(GzCompareTray), matching: find.byType(DecoratedBox)).first).dy;
      final start = top();
      await _settle(tester);
      final end = top();
      expect(start - end, closeTo(16, 1.5));
      await _pump(tester, GzCompareTray(venues: [_v('V01'), _v('V05')], key: const ValueKey('r')), reduceMotion: true);
      final reducedStart = top();
      await _settle(tester);
      expect(reducedStart, closeTo(top(), 0.01));
    });
  });

  group('compare parts', () {
    testWidgets('RangeBar is an image with its label unless decorative', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const GzRangeBar(value: 300, max: 650, mark: 350, markLabel: 'your 350', label: 'Up to 300 guests'));
      expect(find.bySemanticsLabel('Up to 300 guests'), findsOneWidget);
      expect(find.textContaining('350'), findsOneWidget);
      await _pump(tester, const GzRangeBar(value: 300, max: 650, label: 'Up to 300 guests', decorative: true));
      expect(find.bySemanticsLabel('Up to 300 guests'), findsNothing);
      handle.dispose();
    });

    testWidgets('RangeBar fills in proportion to the value and grows from the inline start', (tester) async {
      await _pump(tester, const GzRangeBar(value: 325, max: 650, label: 'half'));
      final box = tester.getRect(find.byType(GzRangeBar));
      final fill = tester.getRect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == GzColors.light.markKhayt));
      expect(fill.width, closeTo(box.width / 2, 1));
      expect(fill.left, closeTo(box.left, 0.5));
      await _pump(tester, const GzRangeBar(value: 325, max: 650, label: 'half'), lang: 'ar');
      final boxAr = tester.getRect(find.byType(GzRangeBar));
      final fillAr = tester.getRect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == GzColors.light.markKhayt));
      expect(fillAr.right, closeTo(boxAr.right, 0.5));
    });

    testWidgets('BestInRow says "Best in row" as its semantics value', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const GzBestInRow(child: Text('18,200')));
      expect(tester.getSemantics(find.text('18,200')).value, 'Best in row');
      handle.dispose();
    });

    testWidgets('DifferencesToggle reports the hidden rows and flips', (tester) async {
      bool? last;
      await _pump(tester, GzDifferencesToggle(checked: true, hidden: 3, onChanged: (v) => last = v));
      expect(find.text('Differences only'), findsOneWidget);
      expect(find.textContaining('hidden'), findsOneWidget);
      await tester.tap(find.text('Differences only'));
      expect(last, false);
      await _pump(tester, GzDifferencesToggle(checked: false, hidden: 3, onChanged: (_) {}));
      expect(find.text('All rows shown'), findsOneWidget);
    });

    testWidgets('ActionBar: the picked hall is the one primary, taps carry id and kind, nothing picked by default', (tester) async {
      (String, GzCompareActionKind)? tapped;
      final columns = [
        const GzCompareActionColumn(id: 'a', name: 'A hall', kind: GzCompareActionKind.voucher, label: 'Get voucher'),
        const GzCompareActionColumn(id: 'b', name: 'B hall', kind: GzCompareActionKind.dates, label: 'See dates'),
      ];
      await _pump(tester, GzCompareActionBar(columns: columns, pickedId: 'a', onAction: (id, kind) => tapped = (id, kind)));
      await tester.tap(find.text('See dates'));
      expect(tapped, ('b', GzCompareActionKind.dates));
      final height = tester.getSize(find.bySemanticsLabel('See dates')).height;
      expect(height, greaterThanOrEqualTo(44));
    });

    testWidgets('Header: remove and pick call back; a picked hall reads selected; compact hides remove', (tester) async {
      final removed = <String>[], picked = <String>[];
      final cols = [GzCompareHeaderColumn(venue: _v('V01')), GzCompareHeaderColumn(venue: _v('V05'))];
      await _pump(tester, GzCompareHeader(columns: cols, onRemove: removed.add, onPick: picked.add, pickedId: 'V05', onOpen: (_) {}));
      await tester.tap(find.bySemanticsLabel(RegExp('^Remove .* from compare')).first);
      expect(removed, ['V01']);
      await tester.tap(find.bySemanticsLabel(RegExp('^Choose ')).first);
      expect(picked, ['V01']);
      expect(find.bySemanticsLabel(RegExp('^Unchoose ')), findsOneWidget);
      await _pump(tester, GzCompareHeader(columns: cols, compact: true, onRemove: removed.add));
      expect(find.bySemanticsLabel(RegExp('^Remove .* from compare')), findsNothing);
    });
  });

  group('GzCompareTable', () {
    testWidgets('Differences only hides rows where every hall matches and says how many', (tester) async {
      final cols = [_col('V01'), _col('V05'), _col('V07')];
      var diff = true;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => GzCompareTable(
            columns: cols,
            origin: 'Salmiya',
            guests: 350,
            differencesOnly: diff,
            onDifferencesOnlyChange: (v) => set(() => diff = v),
          ),
        ),
        width: 1500,
      );
      expect(find.text('Valet'), findsNothing); // identical valet cells: hidden
      expect(find.textContaining('hidden'), findsOneWidget);
      await tester.tap(find.text('Differences only'));
      await tester.pump();
      expect(diff, false);
      expect(find.text('Valet'), findsOneWidget);
    });

    testWidgets('no date: price rows say "From", availability says "Pick a date"; official halls show dashes and Official', (tester) async {
      final cols = [_col('V01'), _col('V05', channel: 'external_link', availability: null, voucher: null, price: null)];
      await _pump(tester, GzCompareTable(columns: cols, origin: 'Salmiya', differencesOnly: false), width: 1500);
      expect(find.text('Voucher price from'), findsOneWidget);
      expect(find.text('Pick a date'), findsWidgets);
      expect(find.text('Official'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('with a date an unavailable hall turns its action into "See dates"; the picked hall is chosen only on tap', (tester) async {
      final cols = [_col('V01'), _col('V05', availability: 'unavailable')];
      String? picked;
      await _pump(
        tester,
        GzCompareTable(
          columns: cols,
          origin: 'Salmiya',
          date: LocalDate.parse('2027-01-14'),
          guests: 350,
          differencesOnly: false,
          onAction: (id, k) => picked = id,
        ),
        width: 1500,
      );
      expect(find.text('See dates'), findsOneWidget);
      expect(find.text('Get voucher'), findsOneWidget);
      await tester.tap(find.text('Get voucher'));
      expect(picked, 'V01');
    });

    testWidgets('the Best-in-row bead marks the lowest price only', (tester) async {
      final cols = [_col('V01', bestPrice: true), _col('V05', voucher: 16000000)];
      await _pump(tester, GzCompareTable(columns: cols, origin: 'Salmiya', guests: 350, differencesOnly: false), width: 1500);
      expect(find.byType(GzBestInRow), findsWidgets);
      expect(find.text('Lowest price'), findsOneWidget);
    });

    testWidgets('the columns are equal thirds with no sideways scroll', (tester) async {
      final cols = [_col('V01'), _col('V05'), _col('V07')];
      await _pump(tester, GzCompareTable(columns: cols, origin: 'Salmiya', guests: 350, differencesOnly: false), width: 1500);
      expect(find.byType(Scrollable), findsOneWidget); // only the test's own vertical scroller
      final widths = [for (final e in find.byType(GzCompareThirds).evaluate().take(1)) tester.getSize(find.byElementPredicate((x) => x == e)).width];
      expect(widths.single, 1500);
    });
  });
}
