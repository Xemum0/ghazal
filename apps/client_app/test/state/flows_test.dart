// The voucher and request flow of the client through the real providers and the in-process mock: checkout, payment, send request (R01),
// withdraw (R07), confirm (R08), cancel (R10a, R13a), the forfeit by the clock (R09), the credit-voucher ask, the guest gate.
import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'state_world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StateWorld world;
  setUpAll(() async => world = await StateWorld.load());
  setUp(() async => world.fresh());
  tearDown(StateWorld.disposeAll);

  /// A draft for Danah Ballroom on the first free evening of late January 2027 (the way the venue page leaves it before the voucher).
  Future<void> startDraft(ProviderContainer c) async {
    final days =
        (await world
                .repos('new_client')
                .venues
                .getVenueAvailability(
                  venueId: 'V01',
                  from: LocalDate.parse('2027-01-20'),
                  to: LocalDate.parse('2027-02-06'),
                  hallId: 'V01-danah',
                  guests: 300,
                  audience: Audience.women,
                ))
            .days;
    final free = days.firstWhere((d) => d.state == DayState.available && d.voucherPrice != null && d.packageId != null);
    c
        .read(bookingDraftProvider.notifier)
        .start(
          venueId: 'V01',
          hallId: 'V01-danah',
          sessionId: 'V01-danah-evening',
          packageId: free.packageId,
          eventDate: free.date,
          audience: Audience.women,
          guests: 300,
        );
  }

  test('an intent keeps its idempotency key until it is answered', () {
    final keys = IntentKeys();
    final a = keys.keyFor('send:v1');
    expect(keys.keyFor('send:v1'), a);
    expect(keys.keyFor('send:v2'), isNot(a));
    keys.done('send:v1');
    expect(keys.keyFor('send:v1'), isNot(a));
  });

  group('the guest gate', () {
    test('a guest who taps Get voucher or Send request gets the gate sheet with the reason and nothing is sent', () async {
      final nav = FakeNavigator('CL-VENU-01');
      final c = world.container(navigator: nav);
      await startDraft(c);
      final actions = c.read(voucherActionsProvider.notifier);

      final r = await actions.checkout(resume: const GateResume('CL-BOOK-03', {'step': 'review'}));
      expect(r, isA<ActionGated<VoucherCheckout>>());
      expect(nav.currentId, kGateSheetId);
      expect(c.read(gateProvider)!.reason, GateReason.voucher);
      expect(c.read(gateProvider)!.resume!.routeName, 'CL-BOOK-03');
      expect(c.read(bookingDraftProvider).voucherId, isNull);

      c.read(gateProvider.notifier).dismiss();
      expect(await actions.sendRequest(voucherId: 'v'), isA<ActionGated<Booking>>());
      expect(c.read(gateProvider)!.reason, GateReason.sendRequest);
    });
  });

  group('checkout, payment, send, withdraw', () {
    test('a new client buys the voucher, pays, sends the request and withdraws it; the voucher returns', () async {
      final c = world.container();
      await c.read(sessionProvider.notifier).loadPersona('new_client');
      await startDraft(c);
      final actions = c.read(voucherActionsProvider.notifier);
      final busySeen = <Set<String>>[];
      c.listen(voucherActionsProvider, (_, s) => busySeen.add(s.busy));

      final checkout = (await actions.checkout()).valueOrNull!;
      expect(checkout.amount.fils, 2000);
      expect(checkout.voucher.status, VoucherStatus.unpaid);
      expect(busySeen.any((b) => b.contains('voucher-checkout')), isTrue);
      expect(c.read(voucherActionsProvider).busy, isEmpty);
      expect(c.read(bookingDraftProvider).voucherId, checkout.voucher.id);
      var pay = c.read(paymentProvider);
      expect(pay.outcome, PaymentOutcome.idle);
      expect(pay.amount!.fils, 2000);
      expect(pay.methods, isNotEmpty);

      final rev = c.read(clientDataRevisionProvider);
      final begun = await c.read(paymentProvider.notifier).begin(GatewayMethod.knet);
      expect(begun.isSuccess, isTrue);
      pay = c.read(paymentProvider);
      expect(pay.outcome, PaymentOutcome.processing);
      expect(pay.paymentId, isNotNull);

      // the redirect decides nothing: until the server says succeeded the outcome is not success
      expect(await c.read(paymentProvider.notifier).refresh(), isNot(PaymentOutcome.success));
      await world.control.flush(); // the mock gateway answers
      expect(await c.read(paymentProvider.notifier).verify(interval: Duration.zero), PaymentOutcome.success);
      expect(c.read(clientDataRevisionProvider), greaterThan(rev));
      expect((await world.repos('new_client').vouchers.getVoucher(voucherId: checkout.voucher.id)).voucher.status, VoucherStatus.active);

      final sent = (await actions.sendRequest()).valueOrNull!;
      expect(sent.status, BookingStatus.pending);
      final d = c.read(bookingDraftProvider);
      expect(d.step, BookingStep.sent);
      expect(d.requestId, sent.id);

      final withdrawn = (await actions.cancelRequest(sent.id)).valueOrNull!;
      expect(withdrawn.status, BookingStatus.cancelled);
      final back = (await world.repos('new_client').vouchers.getVoucher(voucherId: checkout.voucher.id));
      expect(back.voucher.status, VoucherStatus.active);
      expect(back.options!.creditEligible, isFalse);
    });

    test('a failed or cancelled payment leaves the voucher unpaid; a gateway outage is a problem; reset stops a verification', () async {
      final c = world.container();
      await c.read(sessionProvider.notifier).loadPersona('new_client');
      await startDraft(c);
      final checkout = (await c.read(voucherActionsProvider.notifier).checkout()).valueOrNull!;
      final pay = c.read(paymentProvider.notifier);

      await pay.begin(GatewayMethod.card);
      world.control.settlePayment(c.read(paymentProvider).paymentId!, outcome: 'failed');
      expect(await pay.verify(interval: Duration.zero), PaymentOutcome.failed);
      expect((await world.repos('new_client').vouchers.getVoucher(voucherId: checkout.voucher.id)).voucher.status, VoucherStatus.unpaid);

      pay.prepare(voucherId: checkout.voucher.id, amount: checkout.amount, methods: checkout.methods);
      await pay.begin(GatewayMethod.knet);
      world.control.settlePayment(c.read(paymentProvider).paymentId!, outcome: 'cancelled');
      expect(await pay.verify(interval: Duration.zero), PaymentOutcome.cancelled);

      pay.prepare(voucherId: checkout.voucher.id, amount: checkout.amount, methods: checkout.methods);
      world.control.setGatewayDown(true);
      final down = await pay.begin(GatewayMethod.knet);
      world.control.setGatewayDown(false);
      expect(down.problem!.status, 502);
      expect(c.read(paymentProvider).outcome, PaymentOutcome.idle);
      expect(c.read(paymentProvider).problem, isNotNull);

      await pay.begin(GatewayMethod.knet);
      final slow = pay.verify(interval: const Duration(milliseconds: 5), maxAttempts: 200);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      pay.reset();
      await slow;
      expect(c.read(paymentProvider), PaymentFlowState.idle);
    });

    test('an incomplete draft is a programming error, not a server call', () async {
      final c = world.container();
      await c.read(sessionProvider.notifier).loadPersona('new_client');
      expect(() => c.read(voucherActionsProvider.notifier).checkout(), throwsStateError);
    });
  });

  group('the hero request (Reem, Danah Ballroom, 14 Jan 2027)', () {
    Future<ProviderContainer> asReem() async {
      final c = world.container();
      await c.read(sessionProvider.notifier).loadPersona('reem');
      return c;
    }

    test('the hotel approves; Reem confirms inside the window; a stale version is a 409 that refetches', () async {
      final c = await asReem();
      final hind = world.repos('hotel_manager', venueId: 'V01');
      final before = await hind.partnerRequests.getPartnerRequest(requestId: heroId);
      expect(before.booking.status, BookingStatus.pending);
      final approved = await hind.partnerRequests.acceptRequest(
        requestId: heroId,
        body: const AcceptRequestInput(),
        ifMatch: versionTag(before.booking.version),
      );

      final rev = c.read(clientDataRevisionProvider);
      final stale = await c.read(voucherActionsProvider.notifier).confirm(heroId, version: approved.version - 1);
      expect(stale.problem!.status, 409);
      expect(c.read(clientDataRevisionProvider), greaterThan(rev));
      expect(c.read(voucherActionsProvider).lastProblem, stale.problem);

      final confirmed = (await c.read(voucherActionsProvider.notifier).confirm(heroId)).valueOrNull!;
      expect(confirmed.status, BookingStatus.confirmed);
    });

    test('the clock passes the confirm window: the request expires, the voucher is forfeited, confirming is refused', () async {
      final c = await asReem();
      world.control.jumpToStory('approved');
      world.control.advance(const Duration(hours: 25));
      final late = await c.read(voucherActionsProvider.notifier).confirm(heroId);
      expect(late.isSuccess, isFalse);
      final detail = await world.repos('reem').requests.getRequest(requestId: heroId);
      expect(detail.booking.status, BookingStatus.expired);
      expect(detail.voucher!.status, VoucherStatus.forfeited);
      expect(detail.voucher!.creditEligible, isFalse);
    });

    test('cancelling picks the call by status: approved releases the voucher, confirmed consumes it', () async {
      final c = await asReem();
      world.control.jumpToStory('approved');
      final released = (await c.read(voucherActionsProvider.notifier).cancelRequest(heroId)).valueOrNull!;
      expect(released.status, BookingStatus.cancelled);
      expect((await world.repos('reem').requests.getRequest(requestId: heroId)).voucher!.status, VoucherStatus.active);

      world.control.jumpToStory('confirmed');
      final consumed = (await c.read(voucherActionsProvider.notifier).cancelRequest(heroId, reason: CancelReason.plansChanged)).valueOrNull!;
      expect(consumed.status, BookingStatus.cancelled);
      expect((await world.repos('reem').requests.getRequest(requestId: heroId)).voucher!.status, VoucherStatus.used);
    });

    test('after the hotel declines, Reem asks support for a credit voucher once; a second ask is refused', () async {
      final c = await asReem();
      final hind = world.repos('hotel_manager', venueId: 'V01');
      final before = await hind.partnerRequests.getPartnerRequest(requestId: heroId);
      await hind.partnerRequests.declineRequest(
        requestId: heroId,
        body: const DeclineRequestInput(reason: RejectReason.dateUnavailable),
        ifMatch: versionTag(before.booking.version),
      );
      final voucherId = before.voucher!.id;

      final ask = await c.read(voucherActionsProvider.notifier).askSupportCredit(voucherId);
      expect(ask.valueOrNull!.status, RefundRequestStatus.requested);
      final second = await c.read(voucherActionsProvider.notifier).askSupportCredit(voucherId);
      expect(second.problem!.status, 409);
      expect(second.problem!.code, ApiProblemCode.refundRequestExists);
    });
  });
}
