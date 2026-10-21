import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/app/gz_host.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/hotel/hotel_c.dart';
import 'package:ghazal_ui/src/inputs/inputs.dart' show GzDateRange, GzStepper;

import '../shared/shared_harness.dart';

/// The fixtures of the Aurelia Gulf Hotel read as the API would serve them (real rows of the mock seed, parsed by the generated models).
List<Map<String, Object?>> _seed(String name) {
  final file = File('../ghazal_mock_api/assets/seed/$name.seed.json');
  return (jsonDecode(file.readAsStringSync()) as List<dynamic>).cast<Map<String, Object?>>();
}

late Booking pending;
late List<StaffMember> staff;
late List<Review> reviews;
late Package weekend;
final DateTime _now = DateTime.parse('2026-11-12T16:00:00+03:00');

// 1x1 transparent PNG (MemoryImage: FileImage never completes under fake async).
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

Future<void> _pump(WidgetTester tester, Widget child, {String lang = 'en', bool reduceMotion = false, double width = 350}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width + 40, 1600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GzHost(
      locale: Locale(lang),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: GzFormatScope(
            format: GzFormat(locale: Locale(lang), now: () => _now),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

String _plain(RichText w) => w.text.toPlainText().replaceAll(RegExp('[\u2066-\u2069]'), '').replaceAll(RegExp('[\u00a0\u202f]'), ' ');

/// Text with its figures islands (U+2066 .. U+2069) stripped, whole or as a part.
Finder _t(String text) => find.byWidgetPredicate((w) => w is RichText && _plain(w) == text);
Finder _tc(String text) => find.byWidgetPredicate((w) => w is RichText && _plain(w).contains(text));

void main() {
  setUpAll(() async {
    await loadUiFonts();
    pending = Booking.fromJson(_seed('Booking').firstWhere((b) => b['id'] == 'bk-GZ-2611-0147'));
    staff = [for (final s in _seed('StaffMember').where((s) => s['venueId'] == 'V01')) StaffMember.fromJson(s)];
    reviews = [for (final r in _seed('Review').where((r) => r['venueId'] == 'V01')) Review.fromJson(r)];
    weekend = Package.fromJson(_seed('Package').firstWhere((p) => p['id'] == 'V01-ladies-weekend'));
  });

  group('GzGuestCard', () {
    testWidgets('Call, Chat and Voucher fire; the number is an LTR island', (tester) async {
      var call = 0, chat = 0, voucher = 0;
      await _pump(
        tester,
        GzGuestCard(booking: pending, onCall: () => call++, onChat: () => chat++, onVoucher: () => voucher++),
        lang: 'ar',
      );
      await tester.tap(find.bySemanticsLabel('اتصال'));
      await tester.tap(find.bySemanticsLabel('محادثة'));
      await tester.tap(find.bySemanticsLabel('الكوبون'));
      expect([call, chat, voucher], [1, 1, 1]);
      expect(find.textContaining('965', findRichText: true), findsOneWidget);
      final rect = tester.getRect(find.bySemanticsLabel('اتصال'));
      expect(rect.height, greaterThanOrEqualTo(64));
      expect(rect.width, greaterThanOrEqualTo(44));
    });

    testWidgets('a number that is not shared disables Call, says why and keeps Chat', (tester) async {
      var call = 0, chat = 0;
      final hidden = pending.copyWith(contact: pending.contact.copyWith(shared: false));
      await _pump(tester, GzGuestCard(booking: hidden, voucher: false, onCall: () => call++, onChat: () => chat++));
      await tester.tap(find.bySemanticsLabel(RegExp('^Call')), warnIfMissed: false);
      await tester.tap(find.bySemanticsLabel('Chat'));
      expect([call, chat], [0, 1]);
      expect(_t('The client has not shared the number'), findsOneWidget);
      expect(_t('Not shared yet. Message in chat.'), findsOneWidget);
      expect(find.bySemanticsLabel('Voucher'), findsNothing);
    });
  });

  group('GzBookingActionList', () {
    testWidgets('each row reports its action in order', (tester) async {
      final fired = <GzBookingAction>[];
      await _pump(
        tester,
        GzBookingActionList(
          actions: const [GzBookingAction.reschedule, GzBookingAction.revoke, GzBookingAction.cancel],
          onAction: fired.add,
        ),
      );
      for (final label in ['Propose another date', 'Revoke approval', 'Cancel booking']) {
        await tester.tap(find.textContaining(label));
      }
      expect(fired, [GzBookingAction.reschedule, GzBookingAction.revoke, GzBookingAction.cancel]);
      expect(_tc('Offer up to three dates'), findsOneWidget);
    });

    testWidgets('an action the role cannot use is not drawn', (tester) async {
      await _pump(tester, const GzBookingActionList(actions: [GzBookingAction.reschedule]));
      expect(find.textContaining('Revoke approval'), findsNothing);
      expect(find.textContaining('Cancel booking'), findsNothing);
    });
  });

  group('GzBookingStatusCard', () {
    testWidgets('approved: the calm 24 hour line shows the deadline and what is left, no Redeem', (tester) async {
      final approved = pending.copyWith(status: BookingStatus.approved, confirmBy: DateTime.parse('2026-11-13T12:40:00+03:00'));
      await _pump(tester, GzBookingStatusCard(booking: approved, canRedeem: true));
      expect(_tc('Waiting for the client to confirm by'), findsOneWidget);
      expect(_tc('remaining'), findsOneWidget);
      expect(find.text('Redeem voucher'), findsNothing);
    });

    testWidgets('confirmed: Redeem voucher is offered to the roles that may and fires', (tester) async {
      var redeemed = 0;
      final confirmed = pending.copyWith(status: BookingStatus.confirmed);
      await _pump(tester, GzBookingStatusCard(booking: confirmed, canRedeem: true, onRedeem: () => redeemed++));
      await tester.tap(find.text('Redeem voucher'));
      expect(redeemed, 1);
      expect(_tc('The client pays you directly'), findsOneWidget);
      expect(_tc('Standard price'), findsOneWidget);
      expect(_tc('Settled between you and the client, off the app.'), findsOneWidget);
    });

    testWidgets('confirmed without the right to redeem: no button', (tester) async {
      await _pump(tester, GzBookingStatusCard(booking: pending.copyWith(status: BookingStatus.confirmed)));
      expect(find.text('Redeem voucher'), findsNothing);
    });

    testWidgets('redeemed: who redeemed it and when', (tester) async {
      final done = pending.copyWith(
        status: BookingStatus.redeemed,
        redeemedAt: DateTime.parse('2027-01-03T12:20:00+03:00'),
        redeemedBy: 'Amal Al-Balushi',
      );
      await _pump(tester, GzBookingStatusCard(booking: done));
      expect(_tc('by Amal Al-Balushi'), findsOneWidget);
    });
  });

  group('GzValidityRange', () {
    testWidgets('a window chip reports its hours; the status line is absolute time', (tester) async {
      int? hours;
      await _pump(
        tester,
        GzValidityRange(
          value: const GzDateRange(start: '2026-12-03', end: '2026-12-05'),
          onDatesTap: () {},
          windowHours: 24,
          onWindowChange: (h) => hours = h,
          startsAt: DateTime.parse('2026-11-13T16:00:00+03:00'),
          endsAt: DateTime.parse('2026-11-14T16:00:00+03:00'),
          status: GzValidityStatus.scheduled,
        ),
      );
      await tester.tap(_t('12 hours').first);
      expect(hours, 12);
      expect(_t('Scheduled'), findsOneWidget);
      expect(_tc('Starts'), findsOneWidget);
    });

    testWidgets('an active window shows when it ends', (tester) async {
      await _pump(
        tester,
        GzValidityRange(value: const GzDateRange(), endsAt: DateTime.parse('2026-11-14T16:00:00+03:00'), status: GzValidityStatus.active),
      );
      expect(_t('Active'), findsOneWidget);
      expect(_tc('Ends'), findsOneWidget);
    });
  });

  group('GzPackageEditorRow', () {
    testWidgets('closed it shows the voucher price and the guests; the disclosure opens it', (tester) async {
      await _pump(tester, GzPackageEditorRow(pkg: weekend, priceFils: 52000, voucherFils: 44000));
      expect(_tc('200 to 650 guests'), findsOneWidget);
      expect(find.text('INCLUSIONS'), findsNothing);
      await tester.tap(find.bySemanticsLabel(RegExp('^Edit ')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('INCLUSIONS', skipOffstage: false), findsOneWidget);
    });

    testWidgets('a voucher price that is not lower is refused in words; a saving above the KD 2 fee is named', (tester) async {
      final drafts = <GzPackageDraft>[];
      await _pump(
        tester,
        GzPackageEditorRow(pkg: weekend, priceFils: 52000, voucherFils: 44000, defaultExpanded: true, onChange: drafts.add),
      );
      expect(_tc('Clients save'), findsOneWidget);
      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(1), '60');
      await tester.pump();
      expect(_t('The voucher price must be lower than the standard price.'), findsOneWidget);
      expect(drafts.last.voucherFils, 60000);
      await tester.enterText(fields.at(1), '51.5');
      await tester.pump();
      expect(_tc('which is not more than the voucher fee'), findsOneWidget);
      await tester.enterText(fields.at(0), 'abc');
      await tester.pump();
      expect(_t('Enter an amount such as 52 or 52.500.'), findsWidgets);
      expect(drafts.last.priceFils, isNull);
    });

    testWidgets('steppers move by the guest step and the maximum never drops under the minimum', (tester) async {
      final drafts = <GzPackageDraft>[];
      await _pump(
        tester,
        GzPackageEditorRow(pkg: weekend, priceFils: 52000, voucherFils: 44000, defaultExpanded: true, onChange: drafts.add),
      );
      expect(find.byType(GzStepper), findsNWidgets(2));
      await tester.tap(find.bySemanticsLabel('Increase').first);
      await tester.pump();
      expect(drafts.last.minGuests, 205);
      expect(drafts.last.maxGuests, 650);
    });

    testWidgets('removing an inclusion and switching the package off report the draft', (tester) async {
      final drafts = <GzPackageDraft>[];
      await _pump(
        tester,
        GzPackageEditorRow(pkg: weekend, priceFils: 52000, voucherFils: 44000, defaultExpanded: true, onChange: drafts.add),
      );
      final before = weekend.inclusions.length;
      await tester.tap(find.bySemanticsLabel(RegExp('^Remove ')).first);
      await tester.pump();
      expect(drafts.last.inclusions.length, before - 1);
      await tester.tap(find.bySemanticsLabel(RegExp(r' is active$')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(drafts.last.active, isFalse);
    });
  });

  group('GzPhotoManagerGrid', () {
    List<GzPhotoTile> tiles(int n, {Map<int, GzPhotoStatus> status = const {}}) => [
      for (var i = 0; i < n; i++)
        GzPhotoTile(
          id: 'p$i',
          src: 'x$i.jpg',
          alt: LocalizedText(en: 'Room $i', ar: 'قاعة $i'),
          zone: MediaZone.hall,
          status: status[i] ?? GzPhotoStatus.live,
        ),
    ];
    ImageProvider? image(GzPhotoTile t) => MemoryImage(_png);

    testWidgets('the first photo carries Cover; review and rejected carry their chip; the last cell adds', (tester) async {
      var added = 0;
      await _pump(
        tester,
        GzPhotoManagerGrid(
          items: tiles(4, status: {2: GzPhotoStatus.review, 3: GzPhotoStatus.rejected}),
          imageOf: image,
          onAdd: () => added++,
        ),
      );
      expect(find.text('Cover'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Hall'), findsNWidgets(4));
      await tester.tap(find.text('Add photos'));
      expect(added, 1);
      // 4:5 cells, three to a row, 8 apart
      final cell = tester.getRect(find.bySemanticsLabel(RegExp('^Photo 1:')));
      expect(cell.height / cell.width, closeTo(1.25, 0.01));
    });

    testWidgets('a tap opens the photo outside reorder mode', (tester) async {
      String? opened;
      await _pump(tester, GzPhotoManagerGrid(items: tiles(3), imageOf: image, onOpen: (id) => opened = id));
      await tester.tap(find.bySemanticsLabel(RegExp('^Photo 2:')));
      expect(opened, 'p1');
    });

    testWidgets('reorder mode: Move buttons report, the ends are disabled, a tap no longer opens', (tester) async {
      final moves = <String>[];
      String? opened;
      await _pump(
        tester,
        GzPhotoManagerGrid(
          items: tiles(3),
          reorder: true,
          imageOf: image,
          onOpen: (id) => opened = id,
          onMove: (id, by) => moves.add('$id:$by'),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Move 2 earlier'));
      await tester.tap(find.bySemanticsLabel('Move 2 later'));
      await tester.tap(find.bySemanticsLabel('Move 1 earlier'), warnIfMissed: false);
      await tester.tap(find.bySemanticsLabel(RegExp('^Photo 1:')), warnIfMissed: false);
      expect(moves, ['p1:-1', 'p1:1']);
      expect(opened, isNull);
      expect(find.bySemanticsLabel('Drag to reorder'), findsNWidgets(3));
    });

    testWidgets('reorder mode: dragging the handle lifts the photo and dropping it on another cell reports the new place', (tester) async {
      final drops = <String>[];
      await _pump(tester, GzPhotoManagerGrid(items: tiles(3), reorder: true, imageOf: image, onReorder: (id, to) => drops.add('$id>$to')));
      final grip = find.bySemanticsLabel('Drag to reorder').first;
      final target = tester.getCenter(find.bySemanticsLabel(RegExp('^Photo 3:')));
      final g = await tester.startGesture(tester.getCenter(grip));
      await g.moveBy(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 50));
      // the lifted copy is drawn (a second tile with the same zone tag) and the original leaves a quiet hole
      expect(find.text('Hall'), findsNWidgets(4));
      await g.moveTo(target);
      await tester.pump();
      await g.up();
      await tester.pump();
      expect(drops, ['p0>2']);
      expect(find.text('Hall'), findsNWidgets(3));
    });

    testWidgets('make cover and delete with undo: undo keeps the photo, the end of the window commits', (tester) async {
      final deleted = <String>[];
      String? cover;
      await _pump(tester, GzPhotoManagerGrid(items: tiles(3), imageOf: image, onSetCover: (id) => cover = id, onDelete: deleted.add));
      expect(find.text('Make cover'), findsNothing);
      await tester.tap(find.bySemanticsLabel(RegExp('^Photo 2:')));
      await tester.pump();
      await tester.tap(find.text('Make cover'));
      await tester.pump();
      expect(cover, 'p1');
      // the cover itself offers no Make cover
      await tester.tap(find.bySemanticsLabel(RegExp('^Photo 1:')));
      await tester.pump();
      expect(find.text('Make cover'), findsNothing);
      await tester.tap(find.bySemanticsLabel(RegExp('^Photo 3:')));
      await tester.pump();
      await tester.tap(find.text('Delete'));
      await tester.pump();
      expect(find.text('Hall'), findsNWidgets(2));
      expect(find.text('Photo deleted'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(find.text('Hall'), findsNWidgets(3));
      expect(deleted, isEmpty);
      await tester.tap(find.bySemanticsLabel(RegExp('^Photo 3:')));
      await tester.pump();
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 9));
      expect(deleted, ['p2']);
    });
  });

  group('GzBusinessHoursRow', () {
    testWidgets('closed: the word Closed and no times; the switch opens it', (tester) async {
      final changes = <bool>[];
      await _pump(tester, GzBusinessHoursRow(weekday: 6, open: false, from: '09:00', to: '22:00', onOpenChange: changes.add));
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Opens'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Open on Saturday'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(changes, [true]);
    });

    testWidgets('open: two 56 high time buttons that report; a closing time before the opening time says next day', (tester) async {
      var from = 0, to = 0, copy = 0;
      await _pump(
        tester,
        GzBusinessHoursRow(
          weekday: 0,
          open: true,
          from: '18:00',
          to: '02:00',
          onPickFrom: () => from++,
          onPickTo: () => to++,
          onCopy: () => copy++,
        ),
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^Opens at')));
      await tester.tap(find.bySemanticsLabel(RegExp('^Closes at')));
      await tester.tap(find.text('Copy to all days'));
      expect([from, to, copy], [1, 1, 1]);
      expect(find.text('next day'), findsOneWidget);
      expect(tester.getRect(find.bySemanticsLabel(RegExp('^Opens at'))).height, greaterThanOrEqualTo(56));
      expect(find.text('The closing time is before the opening time.'), findsNothing);
    });

    testWidgets('the same time on both ends is an error with a reason', (tester) async {
      await _pump(
        tester,
        const GzBusinessHoursRow(weekday: 4, open: true, from: '09:00', to: '09:00', invalid: true),
        lang: 'ar',
      );
      expect(find.text('وقت الإغلاق يسبق وقت الفتح.'), findsOneWidget);
      expect(find.text('اليوم التالي'), findsNothing);
    });
  });

  group('GzReviewReplyCard', () {
    Review pick(bool Function(Review) test) => reviews.firstWhere(test);

    testWidgets('needs reply: the staged draft is quoted, Reply and Report fire, a reply is public once', (tester) async {
      var reply = 0, report = 0;
      final r = pick((r) => r.ownerReply == null && r.replyDraft != null);
      await _pump(
        tester,
        GzReviewReplyCard(review: r, state: GzReviewReplyState.needsReply, onReply: () => reply++, onReport: () => report++),
      );
      expect(find.text('Needs reply'), findsOneWidget);
      expect(find.text('Your draft'), findsOneWidget);
      await tester.tap(find.text('Reply'));
      await tester.tap(find.text('Report'));
      expect([reply, report], [1, 1]);
      expect(find.text('A reply is public and can be sent once.'), findsOneWidget);
    });

    testWidgets('replied: the reply is signed and there is no second reply', (tester) async {
      final r = pick((r) => r.ownerReply != null);
      await _pump(tester, GzReviewReplyCard(review: r, state: GzReviewReplyState.replied));
      expect(_tc('Reply from ${r.ownerReply!.by}'), findsOneWidget);
      expect(find.text('Reply'), findsNothing);
      expect(find.text('Report'), findsNothing);
    });

    testWidgets('reported: a neutral pill and no actions', (tester) async {
      final r = pick((r) => r.ownerReply == null && r.replyDraft == null);
      await _pump(
        tester,
        GzReviewReplyCard(review: r, state: GzReviewReplyState.reported),
        lang: 'ar',
      );
      expect(find.text('تم الإبلاغ · قيد مراجعة غزل'), findsOneWidget);
      expect(find.text('إبلاغ'), findsNothing);
    });
  });

  group('GzStaffRow', () {
    testWidgets('closed: name in the UI language, role badge, You marker and the state line', (tester) async {
      final you = staff.firstWhere((s) => s.isYou);
      await _pump(tester, GzStaffRow(staff: you));
      expect(find.text(you.nameLatin), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(_tc('Active · last seen'), findsOneWidget);
      expect(find.text('Allowed'), findsNothing);
    });

    testWidgets('an invited member shows when the invitation expires', (tester) async {
      final invited = staff.firstWhere((s) => s.status == StaffStatus.invited);
      await _pump(tester, GzStaffRow(staff: invited));
      expect(_tc('Invite pending · expires'), findsOneWidget);
    });

    testWidgets('opened: the role matrix; Reception has the one switch an Admin can change', (tester) async {
      final reception = staff.firstWhere((s) => s.role == StaffRole.reception);
      final changes = <bool>[];
      await _pump(tester, GzStaffRow(staff: reception, defaultExpanded: true, onCanAcceptChange: changes.add));
      expect(find.text('Allowed'), findsNWidgets(2));
      expect(find.text('Not for this role'), findsNWidgets(4));
      expect(find.text('Can be switched off by the owner'), findsOneWidget);
      await tester.tap(find.byType(GzSwitch));
      await tester.pump(const Duration(milliseconds: 200));
      expect(changes, [false]);
    });

    testWidgets('the head toggles the permissions and reads as expanded', (tester) async {
      final admin = staff.firstWhere((s) => s.role == StaffRole.admin);
      await _pump(tester, GzStaffRow(staff: admin));
      expect(find.text('Allowed'), findsNothing);
      await tester.tap(find.bySemanticsLabel(RegExp('^Permissions of')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Allowed'), findsNWidgets(7));
      expect(find.text('Not for this role'), findsNothing);
    });
  });
  group('RTL and reduced motion', () {
    testWidgets('the guest card actions run from the right in Arabic and from the left in English', (tester) async {
      await _pump(tester, GzGuestCard(booking: pending), lang: 'ar');
      final arCall = tester.getRect(find.bySemanticsLabel('اتصال')).left;
      final arChat = tester.getRect(find.bySemanticsLabel('محادثة')).left;
      expect(arCall, greaterThan(arChat));
      await _pump(tester, GzGuestCard(booking: pending));
      expect(tester.getRect(find.bySemanticsLabel('Call')).left, lessThan(tester.getRect(find.bySemanticsLabel('Chat')).left));
    });

    testWidgets('Move earlier sits at the inline start (the right edge in Arabic)', (tester) async {
      final one = [
        GzPhotoTile(id: 'a', src: 'a.jpg', alt: const LocalizedText.same('A'), zone: MediaZone.hall),
        GzPhotoTile(id: 'b', src: 'b.jpg', alt: const LocalizedText.same('B'), zone: MediaZone.hall),
      ];
      await _pump(
        tester,
        GzPhotoManagerGrid(items: one, reorder: true, imageOf: (t) => MemoryImage(_png)),
        lang: 'ar',
      );
      final earlier = find.bySemanticsLabel(RegExp('للأمام')).at(1);
      final later = find.bySemanticsLabel(RegExp('للخلف')).at(1);
      expect(tester.getRect(earlier).left, greaterThan(tester.getRect(later).left));
    });

    testWidgets('reduced motion: a staff row opens at once and keeps no running animation', (tester) async {
      await _pump(tester, GzStaffRow(staff: staff.first), reduceMotion: true);
      await tester.tap(find.bySemanticsLabel(RegExp('^Permissions of')));
      await tester.pump();
      expect(find.text('Allowed'), findsWidgets);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
