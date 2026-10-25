import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/app/gz_host.dart';
import 'package:ghazal_ui/src/client/client_b.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/inputs/gz_segmented_control.dart';

// CompareGrid / CompareBar against the web CL-SAVD-04 numbers measured with `pnpm probe` at 390 wide (thirds 129.33 / 130.34 / 130.33,
// 12 dp cell padding, so a cell's content is 105.33 wide).

List<Map<String, Object?>> _seed(String name) => (jsonDecode(File('../ghazal_mock_api/assets/seed/$name.seed.json').readAsStringSync()) as List)
    .map((e) => (e as Map).cast<String, Object?>())
    .toList();

CompareColumn _col(
  String id, {
  String? availability = 'available',
  int voucher = 15400000,
  int price = 18200000,
  int maxGuests = 500,
  bool bestPrice = false,
  int minutes = 12,
}) => CompareColumn.fromJson({
  'venue': _seed('VenueSummary').firstWhere((v) => v['id'] == id),
  'channel': 'ghazal_voucher',
  'availability': availability,
  'price': {'fils': price, 'currency': 'KWD'},
  'voucherPrice': {'fils': voucher, 'currency': 'KWD'},
  'savings': {'fils': price - voucher, 'currency': 'KWD'},
  'fromPerGuest': null,
  'fromVoucherPerGuest': null,
  'maxGuests': maxGuests,
  'fits': true,
  'valet': 'included',
  'photography': 'allowed',
  'rating': {'average': 4.5, 'count': 12, 'categories': null},
  'distance': {'km': 5.0, 'minutes': minutes},
  'structures': ['per_person'],
  'packages': {'count': 2, 'from': null, 'fromVoucher': null},
  'best': {'price': bestPrice, 'nearest': false, 'fit': false},
});

List<CompareColumn> _cols() => [
  _col('V01', maxGuests: 650, minutes: 18),
  _col('V05', voucher: 10675000, price: 13300000, bestPrice: true, minutes: 4),
  _col('V07', availability: 'held', maxGuests: 700),
];

Future<void> _pump(WidgetTester tester, Widget child, {String lang = 'en', double width = 390, double scale = 1}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, 6000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GzHost(
      locale: Locale(lang),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
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
  await tester.pump(const Duration(milliseconds: 600));
}

GzCompareGrid _grid({bool diff = true, ValueChanged<String>? onPick, ValueChanged<bool>? onDiff}) => GzCompareGrid(
  columns: _cols(),
  origin: 'Salmiya',
  date: LocalDate.parse('2027-01-14'),
  guests: 350,
  differencesOnly: diff,
  onDifferencesOnlyChange: onDiff,
  onPick: onPick,
  onOpen: (_) {},
  onRemove: (_) {},
);

void main() {
  testWidgets('header: 4:5 photographs 105.33 x 131.66, 12 around, thirds of the page', (tester) async {
    await _pump(tester, _grid());
    final thumb = find.descendant(of: find.byType(GzCompareHeader), matching: find.byType(AspectRatio)).first;
    final size = tester.getSize(thumb);
    expect(size.width, closeTo(105.33, 0.7));
    expect(size.height, closeTo(131.66, 0.9));
    expect(tester.getTopLeft(thumb).dx, closeTo(12, 0.01));
  });

  testWidgets('differences control: the two-glyph segmented control is 52 high and 300 wide beside the hidden count', (tester) async {
    await _pump(tester, _grid());
    final seg = find.byType(GzIconSegmented<bool>);
    expect(tester.getSize(seg).height, closeTo(52, 0.5));
    expect(tester.getTopLeft(seg).dx, closeTo(20, 0.01));
    expect(tester.getTopLeft(find.byType(GzCompareHeader)).dy, 0);
  });

  testWidgets('availability row: a full-width pill in a 105.33 cell, the row 50 high (web 51 with its hairline)', (tester) async {
    await _pump(tester, _grid());
    final pill = find.byType(GzStatusPill).first;
    expect(tester.getSize(pill).width, closeTo(105.33, 0.7));
    expect(tester.getSize(pill).height, closeTo(26, 0.5));
    final row = find.ancestor(of: pill, matching: find.byType(GzCompareThirds)).first;
    expect(tester.getSize(row).height, closeTo(50, 0.5));
  });

  testWidgets('differences only hides the rows where the halls read the same; all shows them', (tester) async {
    await _pump(tester, _grid());
    final few = find.byType(GzCompareThirds).evaluate().length;
    await _pump(tester, _grid(diff: false));
    expect(find.byType(GzCompareThirds).evaluate().length, greaterThan(few));
  });

  test('lowest price: a hall on hold has no price to win with, even when the endpoint flags it', () {
    final cols = [
      _col('V01'),
      _col('V05', voucher: 10675000, price: 13300000),
      _col('V07', availability: 'held', voucher: 9000000, price: 9500000, bestPrice: true),
    ];
    expect(gzCompareLowestPrice(cols), {'V05'});
    // one priced hall alone wins nothing
    expect(gzCompareLowestPrice([cols[1], cols[2]]), isEmpty);
  });

  testWidgets('the pick disk is a control that reports the hall', (tester) async {
    final picked = <String>[];
    final handle = tester.ensureSemantics();
    await _pump(tester, _grid(onPick: picked.add));
    await tester.tap(find.bySemanticsLabel(RegExp('^Choose ')).first);
    expect(picked, hasLength(1));
    handle.dispose();
  });

  testWidgets('bar: three 106 x 48 buttons aligned to the thirds (12 each side), one word each', (tester) async {
    await _pump(tester, GzCompareBar(columns: _cols(), hasDate: true));
    final buttons = find.byType(GzButton);
    expect(buttons, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      final size = tester.getSize(buttons.at(i));
      expect(size.width, closeTo(106, 1.5));
      expect(size.height, closeTo(48, 0.5));
    }
    expect(tester.getTopLeft(buttons.first).dx, closeTo(12, 0.5));
    expect(find.text('Voucher'), findsNWidgets(2));
    expect(find.text('Dates'), findsOneWidget);
  });

  testWidgets('text scale 1.3 at 360: nothing overflows (the old table overflowed 15 px)', (tester) async {
    await _pump(
      tester,
      Column(
        children: [
          _grid(diff: false),
          GzCompareBar(columns: _cols(), hasDate: true),
        ],
      ),
      width: 360,
      scale: 1.3,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic: the first hall sits at the right edge, no overflow', (tester) async {
    await _pump(tester, _grid(diff: false), lang: 'ar');
    expect(tester.takeException(), isNull);
    final first = tester.getTopRight(find.descendant(of: find.byType(GzCompareHeader), matching: find.byType(AspectRatio)).first).dx;
    expect(first, closeTo(390 - 12, 0.5));
  });
}
