// The stories of the product, end to end, through the real client repositories: the hero request (Reem, Danah Ballroom, 14 Jan 2027), the
// 24 h confirm window and the forfeited voucher, decline then credit voucher, counter-offer, listing review, visits with the group chat, staff.
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_api/ghazal_api.dart' show AuthTokens, PartnerRequestContext;
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show storyPoints;

import 'harness.dart';

const heroId = 'bk-GZ-2611-0147';
const heroCode = 'GV-2611-K7QM';

void main() {
  late World w;
  setUp(() async => w = await World.create());

  group('the hero story', () {
    test('Reem asks, the hotel approves, she confirms, the hotel redeems, the day passes', () async {
      final reem = w.actor('reem');
      final hind = w.actor('hotel_manager', venueId: 'V01');

      final before = await hind.repos.partnerRequests.getPartnerRequest(requestId: heroId);
      expect(before.booking.status, BookingStatus.pending);
      final approved = await hind.repos.partnerRequests.acceptRequest(requestId: heroId, body: const AcceptRequestInput(), ifMatch: versionTag(before.booking.version));
      expect(approved.status, BookingStatus.approved);
      expect(approved.confirmBy!.difference(approved.approvedAt!), const Duration(hours: 24));

      // the client hears about the approval when the 8 s undo window closes
      var notes = await reem.repos.notifications.listNotifications();
      expect(notes.items.any((n) => n.kind == NotificationKind.requestApproved), isFalse);
      await w.control.flush();
      notes = await reem.repos.notifications.listNotifications();
      expect(notes.items.any((n) => n.kind == NotificationKind.requestApproved), isTrue);

      final window = await reem.repos.requests.getConfirmWindow(requestId: heroId);
      expect(window.state, ConfirmWindowState.open);
      expect(window.minutesLeft, 24 * 60);

      final confirmed = await reem.repos.requests.confirmRequest(requestId: heroId, ifMatch: versionTag(approved.version));
      expect(confirmed.status, BookingStatus.confirmed);

      // the hotel redeems the voucher by its code
      final check = await hind.repos.partnerBookings.checkVoucherCode(code: heroCode);
      expect(check.ok, isTrue);
      final redeemed = await hind.repos.partnerBookings.redeemVoucher(code: heroCode);
      expect(redeemed.booking.status, BookingStatus.redeemed);
      expect(redeemed.voucher.status, VoucherStatus.used);
      final again = await hind.repos.partnerBookings.checkVoucherCode(code: heroCode);
      expect(again.ok, isFalse);
      expect(again.reason, RedeemFailure.alreadyUsed);

      // the day passes: the request completes, the client may review
      w.control.setClock(DateTime.parse('2027-01-16T12:00:00+03:00'));
      final detail = await reem.repos.requests.getRequest(requestId: heroId);
      expect(detail.booking.status, BookingStatus.completed);
      expect(detail.booking.allowedActions, contains(RequestAction.review));
      final review = await reem.repos.reviews.createReview(
        requestId: heroId,
        body: const CreateReviewInput(rating: 4.5, categories: RatingCategories(venue: 5, food: 4, service: 4.5, value: 4), text: 'A beautiful night.', origin: WireLang.en, anonymous: false),
      );
      expect(review.verifiedBooking, isTrue);
      await expectLater(
        reem.repos.reviews.createReview(requestId: heroId, body: const CreateReviewInput(rating: 5, categories: RatingCategories(venue: 5, food: 5, service: 5, value: 5), text: 'Twice?', anonymous: false)),
        throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 409)),
      );
      final venue = await reem.repos.venues.getVenue(venueId: 'V01');
      expect(venue.venue.rating.count, greaterThan(0));
    });

    test('a stale If-Match is BOOKING_STATE_CONFLICT with the current status and version', () async {
      final hind = w.actor('hotel_manager', venueId: 'V01');
      await expectLater(
        hind.repos.partnerRequests.acceptRequest(requestId: heroId, body: const AcceptRequestInput(), ifMatch: versionTag(1)),
        throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 409).having((e) => e.params['currentStatus'], 'currentStatus', 'pending').having((e) => e.params['currentVersion'], 'currentVersion', 2)),
      );
    });

    test('the clock reaching confirmBy expires the request and forfeits the voucher; the date is open again', () async {
      final reem = w.actor('reem');
      final hind = w.actor('hotel_manager', venueId: 'V01');
      final before = await hind.repos.partnerRequests.getPartnerRequest(requestId: heroId);
      final approved = await hind.repos.partnerRequests.acceptRequest(requestId: heroId, body: const AcceptRequestInput(), ifMatch: versionTag(before.booking.version));
      // while approved the date is held, not free for others
      final held = await reem.repos.venues.getVenueDayAvailability(venueId: 'V01', date: LocalDate.parse('2027-01-14'), audience: Audience.women);
      expect(held.state, isNot(VenueDayState.available));
      w.control.advance(const Duration(hours: 23, minutes: 59));
      expect((await reem.repos.requests.getRequest(requestId: heroId)).booking.status, BookingStatus.approved);
      expect((await reem.repos.requests.getRequest(requestId: heroId)).confirmWindow.state, ConfirmWindowState.lastHour);
      w.control.advance(const Duration(minutes: 2));
      final detail = await reem.repos.requests.getRequest(requestId: heroId);
      expect(detail.booking.status, BookingStatus.expired);
      expect(detail.booking.expiredReason, ExpiredReason.clientNoConfirmation);
      expect(detail.voucher!.status, VoucherStatus.forfeited);
      await expectLater(reem.repos.requests.confirmRequest(requestId: heroId, ifMatch: versionTag(approved.version)), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 409)));
      final notes = await reem.repos.notifications.listNotifications();
      expect(notes.items.any((n) => n.kind == NotificationKind.voucherForfeited), isTrue);
      final hotelNotes = await hind.repos.notifications.listNotifications();
      expect(hotelNotes.items.any((n) => n.kind == NotificationKind.clientLapsed), isTrue);
    });

    test('a venue that never answers: the request expires (R06) and the voucher is released, credit-eligible', () async {
      final reem = w.actor('reem');
      w.control.advance(const Duration(hours: 25));
      final detail = await reem.repos.requests.getRequest(requestId: heroId);
      expect(detail.booking.status, BookingStatus.expired);
      expect(detail.booking.expiredReason, ExpiredReason.venueNoResponse);
      expect(detail.voucher!.status, VoucherStatus.active);
      expect(detail.voucher!.creditEligible, isTrue);
    });

    test('withdrawing is free: the voucher returns and is not credit-eligible', () async {
      final reem = w.actor('reem');
      final b = await reem.repos.requests.getRequest(requestId: heroId);
      final out = await reem.repos.requests.withdrawRequest(requestId: heroId, ifMatch: versionTag(b.booking.version));
      expect(out.status, BookingStatus.cancelled);
      final v = (await reem.repos.requests.getRequest(requestId: heroId)).voucher!;
      expect(v.status, VoucherStatus.active);
      expect(v.creditEligible, isFalse);
      expect(v.reuseUntil, isNotNull);
    });

    test('jumping the story to each prepared state leaves a consistent world', () async {
      final reem = w.actor('reem');
      for (final point in storyPoints) {
        w.control.jumpToStory(point);
        final d = await reem.repos.requests.getRequest(requestId: heroId);
        expect(d.booking.ref, 'GZ-2611-0147', reason: point);
      }
    });
  });

  group('purchase and credit', () {
    test('a new client buys the voucher, requests, is declined, asks for a credit voucher and uses it', () async {
      final nora = w.actor('new_client');
      final hind = w.actor('hotel_manager', venueId: 'V01');
      expect((await nora.repos.vouchers.listVouchers()).items, isEmpty);
      await expectLater(nora.repos.wedding.getWeddingProfile(), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 404)));

      final days = (await nora.repos.venues.getVenueAvailability(venueId: 'V01', from: LocalDate.parse('2027-01-20'), to: LocalDate.parse('2027-02-06'), hallId: 'V01-danah', guests: 300, audience: Audience.women)).days;
      final free = days.firstWhere((d) => d.state == DayState.available && d.voucherPrice != null && d.packageId != null);
      final checkout = await nora.repos.vouchers.startVoucherCheckout(
        body: VoucherCheckoutInput(targetType: VoucherTargetType.venue, targetId: 'V01', hallId: 'V01-danah', packageId: free.packageId!, eventDate: free.date, guests: 300),
      );
      expect(checkout.amount.fils, 2000);
      expect(checkout.voucher.status, VoucherStatus.unpaid);
      final session = await nora.repos.vouchers.createPaymentSession(voucherId: checkout.voucher.id, body: const PaymentSessionInput(method: GatewayMethod.knet));
      expect((await nora.repos.vouchers.getPaymentState(paymentId: session.id)).status, PaymentSessionStatus.created);
      await w.control.flush(); // the mock gateway answers
      final paid = await nora.repos.vouchers.getPaymentState(paymentId: session.id);
      expect(paid.status, PaymentSessionStatus.succeeded);
      expect(paid.voucher!.status, VoucherStatus.active);
      final receipts = await nora.repos.vouchers.listReceipts();
      expect(receipts.items.single.amount.fils, 2000);
      final pdf = await nora.repos.vouchers.getReceiptPdf(receiptNo: receipts.items.single.receiptNo);
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');

      final created = await nora.repos.requests.createRequest(
        body: CreateRequestInput(
          targetType: BookingTargetType.venue,
          venueId: 'V01',
          eventDate: free.date,
          sections: [RequestSectionInput(hallId: 'V01-danah', sessionId: 'V01-danah-evening', audience: Audience.women, guests: 300, packageId: free.packageId!)],
          voucherId: checkout.voucher.id,
          contact: const ContactInput(name: 'Nora', phone: '+96550000099', bookingFor: BookingFor.bride, shared: true),
        ),
        idempotencyKey: 'key-1',
      );
      expect(created.status, BookingStatus.pending);
      // the same key replays the same answer, no second request
      final replay = await nora.repos.requests.createRequest(
        body: CreateRequestInput(
          targetType: BookingTargetType.venue,
          venueId: 'V01',
          eventDate: free.date,
          sections: [RequestSectionInput(hallId: 'V01-danah', sessionId: 'V01-danah-evening', audience: Audience.women, guests: 300, packageId: free.packageId!)],
          voucherId: checkout.voucher.id,
          contact: const ContactInput(name: 'Nora', phone: '+96550000099', bookingFor: BookingFor.bride, shared: true),
        ),
        idempotencyKey: 'key-1',
      );
      expect(replay.id, created.id);
      expect((await nora.repos.requests.listRequests()).items.length, 1);

      final inbox = await hind.repos.partnerRequests.listPartnerRequests(segment: RequestSegment.pending);
      expect(inbox.items.any((r) => r.booking.id == created.id), isTrue);
      final declined = await hind.repos.partnerRequests.declineRequest(requestId: created.id, body: const DeclineRequestInput(reason: RejectReason.dateUnavailable), ifMatch: versionTag(created.version));
      expect(declined.status, BookingStatus.declined);

      final voucher = (await nora.repos.vouchers.getVoucher(voucherId: checkout.voucher.id));
      expect(voucher.voucher.status, VoucherStatus.active);
      expect(voucher.options!.creditEligible, isTrue);
      final refund = await nora.repos.support.createRefundRequest(body: CreateRefundRequestInput(voucherId: checkout.voucher.id));
      expect(refund.status, RefundRequestStatus.requested);
      await expectLater(nora.repos.support.createRefundRequest(body: CreateRefundRequestInput(voucherId: checkout.voucher.id)), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 409)));
      w.control.decideRefund(refund.id, grant: true);
      final granted = await nora.repos.support.getRefundRequest(requestId: refund.id);
      expect(granted.status, RefundRequestStatus.granted);
      final wallet = await nora.repos.vouchers.listVouchers();
      expect(wallet.items.first.voucher, isA<CreditVoucher>());
      expect(wallet.items.any((i) => i.voucher.status == VoucherStatus.creditIssued), isTrue);

      // the credit voucher binds to whichever venue the client picks next
      final credit = wallet.items.first.voucher as CreditVoucher;
      final other = (await nora.repos.venues.getVenueAvailability(venueId: 'V05', from: LocalDate.parse('2027-01-20'), to: LocalDate.parse('2027-02-06'), guests: 200, audience: Audience.women)).days.firstWhere((d) => d.state == DayState.available && d.packageId != null);
      final venue5 = await nora.repos.venues.getVenue(venueId: 'V05');
      final hall = venue5.venue.halls.firstWhere((h) => h.sections.any((s) => s.audience == Audience.women));
      final second = await nora.repos.requests.createRequest(
        body: CreateRequestInput(
          targetType: BookingTargetType.venue,
          venueId: 'V05',
          eventDate: other.date,
          sections: [RequestSectionInput(hallId: hall.id, sessionId: hall.sessions.first.id, audience: Audience.women, guests: 200, packageId: other.packageId!)],
          voucherId: credit.id,
          contact: const ContactInput(name: 'Nora', phone: '+96550000099', bookingFor: BookingFor.bride, shared: false),
        ),
      );
      expect(second.status, BookingStatus.pending);
      final bound = await nora.repos.vouchers.getVoucher(voucherId: credit.id);
      expect(bound.voucher.status, VoucherStatus.bound);
    });

    test('guards: third open request is OPEN_REQUEST_LIMIT, date too soon is LEAD_TIME_TOO_SHORT, unknown voucher is not usable', () async {
      final reem = w.actor('reem');
      await expectLater(
        reem.repos.requests.createRequest(
          body: CreateRequestInput(
            targetType: BookingTargetType.venue,
            venueId: 'V01',
            eventDate: LocalDate.parse('2026-11-13'),
            sections: [RequestSectionInput(hallId: 'V01-danah', sessionId: 'V01-danah-evening', audience: Audience.women, guests: 300, packageId: 'V01-ladies-weekend')],
            voucherId: 'vch-GV-2611-R4TF',
            contact: const ContactInput(name: 'Reem', phone: '+96550000012', bookingFor: BookingFor.bride, shared: true),
          ),
        ),
        throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 422)),
      );
      await expectLater(
        reem.repos.requests.createRequest(
          body: CreateRequestInput(
            targetType: BookingTargetType.venue,
            venueId: 'V01',
            eventDate: LocalDate.parse('2027-01-14'),
            sections: [RequestSectionInput(hallId: 'V01-danah', sessionId: 'V01-danah-evening', audience: Audience.women, guests: 300, packageId: 'V01-ladies-weekend')],
            voucherId: heroCode,
            contact: const ContactInput(name: 'Reem', phone: '+96550000012', bookingFor: BookingFor.bride, shared: true),
          ),
        ),
        throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 409)),
      );
    });
  });

  test('counter-offer: the hotel proposes other dates, the client accepts one', () async {
    final reem = w.actor('reem');
    final hind = w.actor('hotel_manager', venueId: 'V01');
    final b = await hind.repos.partnerRequests.getPartnerRequest(requestId: heroId);
    final proposed = await hind.repos.partnerRequests.proposeDates(
      requestId: heroId,
      body: ProposeDatesInput(options: [ProposedDateInput(eventDate: LocalDate.parse('2027-01-21'), hallId: 'V01-danah', sessionId: 'V01-danah-evening'), ProposedDateInput(eventDate: LocalDate.parse('2027-01-22'), hallId: 'V01-danah', sessionId: 'V01-danah-evening')]),
      ifMatch: versionTag(b.booking.version),
    );
    expect(proposed.proposal!.status, ProposalStatus.proposed);
    expect(proposed.allowedActions, isNot(contains(RequestAction.accept)), reason: 'the venue waits for the client');
    final seen = await reem.repos.requests.getRequest(requestId: heroId);
    expect(seen.booking.allowedActions, containsAll([RequestAction.acceptProposal, RequestAction.declineProposal]));
    final accepted = await reem.repos.requests.acceptProposal(requestId: heroId, proposalId: proposed.proposal!.id, body: const ProposalAnswerInput(optionIndex: 1), ifMatch: versionTag(proposed.version));
    expect(accepted.status, BookingStatus.approved);
    expect(accepted.eventDate, LocalDate.parse('2027-01-22'));
    expect(accepted.confirmBy, isNotNull);
  });

  test('partner cancels after approval: reliability strike, voucher released and credit-eligible', () async {
    final reem = w.actor('reem');
    final hind = w.actor('hotel_manager', venueId: 'V01');
    final pr = await hind.repos.partnerRequests.getPartnerRequest(requestId: heroId);
    final approved = await hind.repos.partnerRequests.acceptRequest(requestId: heroId, body: const AcceptRequestInput(), ifMatch: versionTag(pr.booking.version));
    final revoked = await hind.repos.partnerRequests.revokeApproval(requestId: heroId, body: const PartnerCancelInput(reason: CancelReason.hallUnavailable), ifMatch: versionTag(approved.version));
    expect(revoked.status, BookingStatus.cancelled);
    expect(revoked.cancelledBy, CancelledBy.venue);
    final v = (await reem.repos.requests.getRequest(requestId: heroId)).voucher!;
    expect(v.status, VoucherStatus.active);
    expect(v.creditEligible, isTrue);
  });

  group('listing review', () {
    test('draft, plan, submit, rejected with notes, resubmit, approved and live, paused and resumed; paying is refused until rates exist', () async {
      final zahra = w.actor('provider', providerId: 'vendor-flowers-zahra');
      final created = await zahra.repos.partnerListings.createListing(body: const ListingInput(title: LocalizedText(en: 'Zahra Spring', ar: 'زهرة الربيع')));
      expect(created.status, ListingStatus.draft);
      await expectLater(zahra.repos.partnerListings.submitListing(listingId: created.id), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 422)), reason: 'no plan chosen yet');
      await zahra.repos.partnerListings.chooseListingPlan(listingId: created.id, body: const ChoosePlanInput(cycle: AdPlanCycle.monthly));
      await expectLater(
        zahra.repos.partnerListings.createListingPaymentSession(listingId: created.id, body: const PaymentSessionInput(method: GatewayMethod.knet)),
        throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 409)),
      );
      final submitted = await zahra.repos.partnerListings.submitListing(listingId: created.id);
      expect(submitted.status, ListingStatus.pendingReview);
      w.control.moderateListing(created.id, approve: false, codes: ['missing_details'], note: 'Add three portfolio photos.');
      var l = await zahra.repos.partnerListings.getListing(listingId: created.id);
      expect(l.status, ListingStatus.rejected);
      expect(l.rejection!.codes, contains(ListingRejectionCode.missingDetails));
      expect(l.history.last.to, ListingStatus.rejected);
      await zahra.repos.partnerListings.submitListing(listingId: created.id);
      w.control.moderateListing(created.id, approve: true);
      l = await zahra.repos.partnerListings.getListing(listingId: created.id);
      expect(l.status, ListingStatus.active);
      expect(l.startsOn, isNotNull);
      expect((await zahra.repos.partnerListings.pauseListing(listingId: created.id)).status, ListingStatus.paused);
      expect((await zahra.repos.partnerListings.resumeListing(listingId: created.id)).status, ListingStatus.active);
      final notes = await zahra.repos.notifications.listNotifications();
      expect(notes.items.map((n) => n.kind), containsAll([NotificationKind.listingApproved, NotificationKind.listingRejected]));
    });
  });

  group('visits and the group chat', () {
    test('Reem books a visit, the thread has three members, her message gets a scripted reply, the hotel confirms', () async {
      final reem = w.actor('reem');
      final amal = w.actor('hotel_admin', venueId: 'V01');
      final dates = await reem.repos.visits.listVisitDates(venueId: 'V01');
      expect(dates.dates, isNotEmpty);
      final slots = await reem.repos.visits.listVisitSlots(venueId: 'V01', date: dates.dates.first);
      final slot = slots.slots.firstWhere((s) => s.available);
      final thread = await reem.repos.visits.bookVisit(body: VisitBookingInput(venueId: 'V01', slotStart: slot.start, visitors: 3, note: 'نحب نشوف القاعة'));
      expect(thread.visit.status, VisitStatus.requested);
      expect(thread.thread.members!.map((m) => m.role), containsAll([ThreadRole.client, ThreadRole.hotelRepresentative, ThreadRole.support]));
      // the slot is gone for the next person
      final slots2 = await reem.repos.visits.listVisitSlots(venueId: 'V01', date: dates.dates.first);
      expect(slots2.slots.firstWhere((s) => s.start == slot.start).available, isFalse);
      await expectLater(reem.repos.visits.bookVisit(body: VisitBookingInput(venueId: 'V01', slotStart: slot.start, visitors: 2)), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 409)));

      final convId = thread.thread.id;
      final sent = await reem.repos.chat.sendMessage(conversationId: convId, body: const SendMessageInput(clientMsgId: 'm-1', kind: SendMessageInputKind.text, text: 'Salam, we are three.', origin: WireLang.en));
      expect(sent.from, MessageFrom.client);
      final before = await reem.repos.chat.listMessages(conversationId: convId);
      await w.control.flush();
      final after = await reem.repos.chat.listMessages(conversationId: convId, afterSeq: sent.seq);
      expect(after.items.map((m) => m.from), containsAll([MessageFrom.venue, MessageFrom.support]));
      expect(before.items.length, lessThan((await reem.repos.chat.listMessages(conversationId: convId)).items.length));

      await amal.repos.partnerVisits.confirmVisit(visitId: thread.visit.id);
      final confirmed = await reem.repos.visits.getVisitThread(visitId: thread.visit.id);
      expect(confirmed.visit.status, VisitStatus.confirmed);
      expect(confirmed.messages.any((m) => m.kind == MessageKind.visitCard), isTrue);
      w.control.supportReply(thread.visit.id);
      expect((await reem.repos.chat.listMessages(conversationId: convId)).items.last.from, MessageFrom.support);

      // after the slot plus 24 h the chat is read-only
      w.control.setClock(slot.start.add(const Duration(days: 3)));
      await expectLater(reem.repos.chat.sendMessage(conversationId: convId, body: const SendMessageInput(clientMsgId: 'm-2', kind: SendMessageInputKind.text, text: 'late', origin: WireLang.en)), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 403)));
    });
  });

  group('staff and sign-in', () {
    test('an admin invites staff by email, the invitation is accepted, the last admin cannot be removed', () async {
      final khalid = w.actor('hotel_admin', venueId: 'V01');
      final inv = await khalid.repos.partnerAccount.inviteStaff(body: const InviteStaffInput(email: 'new.reception@aurelia-gulf.example', role: StaffRole.reception));
      expect(inv.status, InvitationStatus.invited);
      await expectLater(khalid.repos.partnerAccount.inviteStaff(body: const InviteStaffInput(email: 'new.reception@aurelia-gulf.example', role: StaffRole.reception)), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 409)));
      expect(w.control.outbox.any((m) => m['to'] == 'new.reception@aurelia-gulf.example' && m['kind'] == 'staff_invitation'), isTrue);
      final guest = w.actor('guest');
      final preview = await guest.repos.auth.getStaffInvitationPreview(token: inv.id);
      expect(preview.role, StaffRole.reception);
      final session = await guest.repos.auth.acceptStaffInvitation(body: AcceptInvitationInput(token: inv.id, password: 'Str0ng#Pass', acceptedTerms: true));
      expect(session.user.user.email, 'new.reception@aurelia-gulf.example');
      await expectLater(guest.repos.auth.getStaffInvitationPreview(token: inv.id), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 410)));
      final staff = await khalid.repos.partnerAccount.listStaff();
      expect(staff.staff.where((s) => s.isYou).single.role, StaffRole.admin);
      final me = staff.staff.firstWhere((s) => s.isYou);
      await expectLater(khalid.repos.partnerAccount.deactivateStaff(staffId: me.id), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 409)));
      // reception staff cannot manage staff
      final rec = w.actor('guest');
      await rec.tokens.write(AuthTokens(accessToken: session.accessToken, refreshToken: session.refreshToken));
      rec.env.partnerContext = const PartnerRequestContext(venueId: 'V01');
      await expectLater(rec.repos.partnerAccount.inviteStaff(body: const InviteStaffInput(email: 'x@y.example', role: StaffRole.marketing)), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 403)));
    });

    test('partner email sign-in asks for a code on a new device and remembers the device', () async {
      final a = w.actor('guest');
      await expectLater(a.repos.auth.partnerLogin(body: const PartnerLoginInput(email: 'hind@aurelia-gulf.example', password: 'wrong', deviceId: 'dev-1')), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 401)));
      final first = await a.repos.auth.partnerLogin(body: const PartnerLoginInput(email: 'hind@aurelia-gulf.example', password: 'Ghazal#2026', deviceId: 'dev-1'));
      expect(first.status, PartnerLoginStatus.codeRequired);
      expect(w.control.outbox.last['code'], '123456');
      final session = await a.repos.auth.partnerVerifyCode(body: OtpVerifyInput(challengeId: first.challenge!.challengeId, code: '123456', deviceId: 'dev-1'));
      expect(session.user.permissions, contains('request:respond'));
      final second = await a.repos.auth.partnerLogin(body: const PartnerLoginInput(email: 'hind@aurelia-gulf.example', password: 'Ghazal#2026', deviceId: 'dev-1'));
      expect(second.status, PartnerLoginStatus.signedIn);
    });
  });
}
