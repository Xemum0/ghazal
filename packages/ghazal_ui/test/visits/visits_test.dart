import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ThreadMember, VisitAppointment;
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/visits/visits.dart';

import '../voucher/voucher_harness.dart';

/// A text (plain or rich, isolates removed) that contains [s].
Finder _text(String s) => find.byWidgetPredicate((w) => w is Text && GzBidi.strip(w.data ?? w.textSpan?.toPlainText() ?? '').contains(s));

ThreadMember member(String id, String role, String name, String latin, String monogram, {Map<String, String>? org}) => ThreadMember.fromJson({
  'userId': id,
  'role': role,
  'name': name,
  'nameLatin': latin,
  'monogram': monogram,
  'chip': {'en': latin, 'ar': name},
  'organisation': org,
});

final List<ThreadMember> members = [
  member('user-lama', 'support', 'لمى الخالدي', 'Lama Al-Khalidi', 'ل'),
  member('user-reem', 'client', 'ريم الدوسري', 'Reem Al-Dosari', 'ر'),
  member('user-amal', 'hotel_representative', 'أمل البلوشي', 'Amal Al-Balushi', 'أ', org: {'en': 'Aurelia Gulf Hotel', 'ar': 'فندق أوريليا الخليج'}),
];

VisitAppointment visit({String status = 'confirmed', int visitors = 3}) => VisitAppointment.fromJson({
  'id': 'visit-aurelia-reem',
  'venueId': 'V01',
  'clientId': 'user-reem',
  'clientName': 'ريم الدوسري',
  'requestedAt': '2026-11-09T10:00:00+03:00',
  'slotStart': '2026-11-14T17:00:00+03:00',
  'slotEnd': '2026-11-14T17:30:00+03:00',
  'visitors': visitors,
  'note': null,
  'status': status,
  'representativeId': 'user-amal',
  'conversationId': 'conv-visit-1',
  'proposedSlotStart': null,
  'arrivedAt': null,
  'closedAt': null,
  'history': [],
});

void main() {
  group('GzParticipantStrip', () {
    testWidgets('three members in the fixed order Client, Hotel representative, Ghazal support, whatever order they arrive in', (tester) async {
      await pumpVoucher(tester, GzParticipantStrip(members: members));
      double x(String s) => tester.getCenter(_text(s).first).dx;
      expect(x('Client'), lessThan(x('Hotel representative')));
      expect(x('Hotel representative'), lessThan(x('Ghazal support')));
      expect(find.byType(GzAvatar), findsNWidgets(3));
    });

    testWidgets('the viewer is "You", names follow the viewer script, avatars are monograms', (tester) async {
      await pumpVoucher(tester, GzParticipantStrip(members: members, meId: 'user-reem'));
      expect(_text('You'), findsOneWidget);
      expect(_text('Client'), findsNothing);
      expect(_text('Reem Al-Dosari'), findsOneWidget);
      expect(_text('ريم الدوسري'), findsNothing);
      await pumpVoucher(tester, GzParticipantStrip(members: members, meId: 'user-reem'), lang: 'ar');
      expect(_text('ريم الدوسري'), findsOneWidget);
      expect(_text('Reem Al-Dosari'), findsNothing);
      expect(tester.widget<GzAvatar>(find.byType(GzAvatar).first).initial, isNotNull, reason: 'Arabic uses the member monogram');
    });

    testWidgets('with onOpen the whole strip is one 44 dp button; without it nothing is tappable', (tester) async {
      var opened = 0;
      await pumpVoucher(tester, GzParticipantStrip(members: members, onOpen: () => opened++));
      expect(tester.getSize(find.byType(GzPressable)).height, greaterThanOrEqualTo(44));
      await tester.tap(find.byType(GzPressable));
      expect(opened, 1);
      await pumpVoucher(tester, GzParticipantStrip(members: members));
      expect(find.byType(GzPressable), findsNothing);
    });

    testWidgets('the member sheet form shows the organisation under the representative only', (tester) async {
      await pumpVoucher(tester, GzParticipantStrip(members: members));
      expect(_text('Aurelia Gulf Hotel'), findsNothing);
      await pumpVoucher(tester, GzParticipantStrip(members: members, showOrganisation: true));
      expect(_text('Aurelia Gulf Hotel'), findsOneWidget);
    });

    testWidgets('semantics: the pressable strip is named by the shared "Show chat members"', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpVoucher(tester, GzParticipantStrip(members: members, onOpen: () {}));
      expect(find.bySemanticsLabel('Show chat members'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Arabic mirrors the order: the client sits at the inline-start (right) edge', (tester) async {
      await pumpVoucher(tester, GzParticipantStrip(members: members), lang: 'ar');
      double x(String s) => tester.getCenter(_text(s).first).dx;
      expect(x('العميل'), greaterThan(x('ممثل الفندق')));
      expect(x('ممثل الفندق'), greaterThan(x('دعم غزل')));
    });
  });

  group('GzVisitCard', () {
    testWidgets('client: status, party, date, arrival window and the venue; the chat action fires', (tester) async {
      var chat = 0;
      await pumpVoucher(tester, GzVisitCard(visit: visit(), venueName: 'Aurelia Gulf Hotel', representativeName: 'Amal Al-Balushi', onOpenChat: () => chat++));
      expect(_text('Confirmed'), findsOneWidget);
      expect(_text('3 guests'), findsOneWidget);
      expect(_text('Saturday 14 November 2026'), findsOneWidget);
      expect(_text('5:00'), findsOneWidget);
      expect(_text('Aurelia Gulf Hotel'), findsOneWidget);
      expect(_text('With Amal Al-Balushi'), findsOneWidget);
      expect(_text('Chat is read-only'), findsNothing);
      await tester.tap(_text('Open group chat'));
      expect(chat, 1);
    });

    testWidgets('partner: the client name, no representative line', (tester) async {
      await pumpVoucher(tester, GzVisitCard(visit: visit(status: 'requested'), audience: GzVisitAudience.hotel, venueName: 'Aurelia Gulf Hotel', representativeName: 'Amal', onOpenChat: () {}));
      expect(_text('ريم الدوسري'), findsOneWidget);
      expect(_text('Aurelia Gulf Hotel'), findsNothing);
      expect(_text('With Amal'), findsNothing);
      expect(_text('Requested'), findsOneWidget);
    });

    testWidgets('a finished visit says the chat is read-only, but only next to a chat action', (tester) async {
      for (final s in ['completed', 'cancelled', 'declined', 'missed']) {
        await pumpVoucher(tester, GzVisitCard(visit: visit(status: s), venueName: 'A', onOpenChat: () {}));
        expect(_text('Chat is read-only'), findsOneWidget, reason: s);
      }
      await pumpVoucher(tester, GzVisitCard(visit: visit(status: 'completed'), venueName: 'A'));
      expect(_text('Chat is read-only'), findsNothing);
    });

    testWidgets('every status has its pill word', (tester) async {
      const words = {
        'requested': 'Requested',
        'confirmed': 'Confirmed',
        'reschedule_proposed': 'New time',
        'arrived': 'Arrived',
        'completed': 'Done',
        'declined': 'Declined',
        'cancelled': 'Cancelled',
        'missed': 'Missed',
      };
      for (final e in words.entries) {
        await pumpVoucher(tester, GzVisitCard(visit: visit(status: e.key), venueName: 'A'));
        expect(find.byType(GzStatusPill), findsOneWidget, reason: e.key);
      }
    });

    testWidgets('onOpen makes the body one tappable target; the chat button is 44 dp or more', (tester) async {
      var opened = 0;
      await pumpVoucher(tester, GzVisitCard(visit: visit(), venueName: 'Aurelia', onOpen: () => opened++, onOpenChat: () {}));
      await tester.tap(_text('Aurelia'));
      expect(opened, 1);
      final chat = tester.getSize(find.ancestor(of: _text('Open group chat'), matching: find.byType(GzPressable)).first);
      expect(chat.height, greaterThanOrEqualTo(44));
    });

    testWidgets('semantics: one node named by the venue, status, date, window and party', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpVoucher(tester, GzVisitCard(visit: visit(), venueName: 'Aurelia Gulf Hotel', onOpen: () {}));
      final node = tester.getSemantics(find.byType(GzPressable).first);
      expect(node.label, allOf(contains('Aurelia Gulf Hotel'), contains('Confirmed'), contains('Saturday 14 November 2026')));
      handle.dispose();
    });

    testWidgets('Arabic: the window and the party figure stay left to right', (tester) async {
      await pumpVoucher(tester, GzVisitCard(visit: visit(), venueName: 'فندق أوريليا الخليج', onOpenChat: () {}), lang: 'ar');
      final window = tester.widgetList<Text>(find.byType(Text)).firstWhere((t) => (t.data ?? '').contains('5:00'));
      expect(window.data!.startsWith(GzBidi.lri), isTrue);
    });
  });
}
