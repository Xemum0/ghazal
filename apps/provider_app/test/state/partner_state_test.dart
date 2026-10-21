// The partner context, the request actions (accept with the 8 s undo, decline, propose dates, revoke, cancel, redeem) and the tab badges,
// through the real providers and the in-process mock. The hero story: Reem asked Aurelia Gulf Hotel (V01) for 14 Jan 2027.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzCountTone;
import 'package:provider_app/app/state/state.dart';

import 'state_world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StateWorld world;
  setUpAll(() async => world = await StateWorld.load());
  setUp(() async => world.fresh());
  tearDown(StateWorld.disposeAll);

  Future<ProviderContainer> asPartner(String persona, {List<Override> overrides = const <Override>[]}) async {
    final c = world.container(overrides: overrides);
    await c.read(sessionProvider.notifier).loadPersona(persona);
    return c;
  }

  Future<Booking> status(String id) async => (await world.repos('reem').requests.getRequest(requestId: id)).booking;

  group('partner context', () {
    test('nobody is signed in: no context', () {
      expect(world.container().read(partnerContextProvider), isNull);
    });

    test('the hotel manager works in venue V01 and may redeem but not manage staff', () async {
      final c = await asPartner('hotel_manager');
      final ctx = c.read(partnerContextProvider)!;
      expect(ctx.isVenue, isTrue);
      expect(ctx.venueId, 'V01');
      expect(ctx.targetId, 'V01');
      expect(ctx.role, StaffRole.manager);
      expect(ctx.can(PartnerPermission.voucherRedeem), isTrue);
      expect(ctx.can(PartnerPermission.staffWrite), isFalse);
      expect(ctx.permissions, isNotEmpty);
    });

    test('a service provider has a provider context and no venue', () async {
      final c = await asPartner('provider');
      final ctx = c.read(partnerContextProvider)!;
      expect(ctx.isProvider, isTrue);
      expect(ctx.providerId, isNotNull);
      expect(ctx.venueId, isNull);
      expect(ctx.targetId, ctx.providerId);
    });

    test('memberships list the accounts of the staff member; signing out drops the context', () async {
      final c = await asPartner('hotel_admin');
      final memberships = await c.read(partnerMembershipsProvider.future);
      expect(memberships, isNotEmpty);
      expect(memberships.any((m) => m.venueId == 'V01'), isTrue);
      final switched = await c
          .read(partnerContextProvider.notifier)
          .switchTo(memberships.first.accountId, venueId: memberships.first.venueId, providerId: memberships.first.providerId);
      expect(switched.isSuccess, isTrue);
      await c.read(sessionProvider.notifier).signOut();
      expect(c.read(partnerContextProvider), isNull);
    });
  });

  group('request actions: the hero request', () {
    test('the manager sees the pending request, accepts it, undoes inside the window, then accepts for good', () async {
      final c = await asPartner('hotel_manager');
      final inbox = await c.read(partnerRequestsRepositoryProvider).listPartnerRequests(segment: RequestSegment.pending);
      expect(inbox.items.any((r) => r.booking.id == heroId), isTrue);

      final actions = c.read(requestActionsProvider.notifier);
      final rev = c.read(partnerDataRevisionProvider);
      final accepted = (await actions.accept(heroId)).valueOrNull!;
      expect(accepted.status, BookingStatus.approved);
      expect(accepted.confirmBy!.difference(accepted.approvedAt!), const Duration(hours: 24));
      expect(c.read(requestActionsProvider).canUndo, isTrue);
      expect(c.read(requestActionsProvider).last!.requestId, heroId);
      expect(c.read(partnerDataRevisionProvider), greaterThan(rev));

      final undone = (await actions.undo()).valueOrNull!;
      expect(undone.status, BookingStatus.pending);
      expect(c.read(requestActionsProvider).last, isNull);
      expect((await status(heroId)).status, BookingStatus.pending);

      await actions.accept(heroId);
      actions.commit(); // the toast closed
      expect(c.read(requestActionsProvider).last, isNull);
      expect((await status(heroId)).status, BookingStatus.approved);
    });

    test('the undo bar commits by itself when the window ends; nothing is left to undo', () async {
      final c = await asPartner('hotel_manager', overrides: [undoWindowProvider.overrideWithValue(const Duration(milliseconds: 40))]);
      final actions = c.read(requestActionsProvider.notifier);
      await actions.accept(heroId);
      expect(c.read(requestActionsProvider).canUndo, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(c.read(requestActionsProvider).last, isNull);
      await expectLater(actions.undo(), throwsStateError); // committed: nothing to undo
    });

    test('an undo after the server window is a problem and the bar goes away', () async {
      final c = await asPartner('hotel_manager');
      final actions = c.read(requestActionsProvider.notifier);
      await actions.accept(heroId);
      world.control.advance(const Duration(seconds: 9));
      final late = await actions.undo();
      expect(late.problem, isNotNull);
      expect(late.problem!.code, ApiProblemCode.undoWindowEnded);
      expect(c.read(requestActionsProvider).last, isNull);
      expect((await status(heroId)).status, BookingStatus.approved);
    });

    test('the clock passes the confirm window: the request lapses and the voucher is forfeited', () async {
      final c = await asPartner('hotel_manager');
      await c.read(requestActionsProvider.notifier).accept(heroId);
      world.control.advance(const Duration(hours: 25));
      final detail = await world.repos('reem').requests.getRequest(requestId: heroId);
      expect(detail.booking.status, BookingStatus.expired);
      expect(detail.booking.expiredReason, ExpiredReason.clientNoConfirmation);
      expect(detail.voucher!.status, VoucherStatus.forfeited);
    });

    test('decline releases the voucher and cannot be undone; a second action finds the request already answered (409)', () async {
      final c = await asPartner('hotel_manager');
      final actions = c.read(requestActionsProvider.notifier);
      final declined = (await actions.decline(heroId, RejectReason.dateUnavailable)).valueOrNull!;
      expect(declined.status, BookingStatus.declined);
      expect(c.read(requestActionsProvider).canUndo, isFalse);
      expect(c.read(requestActionsProvider).last!.kind, PartnerActionKind.decline);
      final again = await actions.accept(heroId);
      expect(again.problem!.status, 409);
      expect((await world.repos('reem').requests.getRequest(requestId: heroId)).voucher!.creditEligible, isTrue);
    });

    test('a stale version is BOOKING_STATE_CONFLICT and refetches', () async {
      final c = await asPartner('hotel_manager');
      final rev = c.read(partnerDataRevisionProvider);
      final r = await c.read(requestActionsProvider.notifier).accept(heroId, version: 1);
      expect(r.problem!.code, ApiProblemCode.bookingStateConflict);
      expect(c.read(partnerDataRevisionProvider), greaterThan(rev));
      expect(c.read(requestActionsProvider).lastProblem, r.problem);
    });

    test('propose another date keeps the request pending with a counter-offer', () async {
      final c = await asPartner('hotel_manager');
      final proposed = (await c.read(requestActionsProvider.notifier).rescheduleTo(heroId, LocalDate.parse('2027-01-21'))).valueOrNull!;
      expect(proposed.status, BookingStatus.pending);
      expect(proposed.proposal, isNotNull);
      expect(proposed.proposal!.options.single.eventDate, LocalDate.parse('2027-01-21'));
      expect(c.read(requestActionsProvider).canUndo, isFalse);
    });

    test('revoke an approval (R10b) or cancel a confirmed request (R13b): the call follows the status', () async {
      final c = await asPartner('hotel_manager');
      final actions = c.read(requestActionsProvider.notifier);
      world.control.jumpToStory('approved');
      final revoked = (await actions.cancelByPartner(heroId)).valueOrNull!;
      expect(revoked.status, BookingStatus.cancelled);
      expect(c.read(requestActionsProvider).last!.kind, PartnerActionKind.revoke);
      expect((await world.repos('reem').requests.getRequest(requestId: heroId)).voucher!.status, VoucherStatus.active);

      world.control.jumpToStory('confirmed');
      final cancelled = (await actions.cancelByPartner(heroId, note: 'Hall closed for works')).valueOrNull!;
      expect(cancelled.status, BookingStatus.cancelled);
      expect(c.read(requestActionsProvider).last!.kind, PartnerActionKind.cancelConfirmed);
    });
  });

  group('redeem', () {
    test('check, redeem once, then the code reads already used', () async {
      final c = await asPartner('hotel_manager');
      final actions = c.read(requestActionsProvider.notifier);
      world.control.jumpToStory('confirmed');
      const code = 'GV-2611-K7QM';

      final check = (await actions.checkVoucher(' ${code.toLowerCase()} ')).valueOrNull!;
      expect(check.ok, isTrue);
      final redeemed = (await actions.redeem(code)).valueOrNull!;
      expect(redeemed.booking.status, BookingStatus.redeemed);
      expect(redeemed.voucher.status, VoucherStatus.used);

      final again = (await actions.checkVoucher(code)).valueOrNull!;
      expect(again.ok, isFalse);
      expect(again.reason, RedeemFailure.alreadyUsed);
      final twice = await actions.redeem(code);
      expect(twice.isSuccess, isFalse);
    });

    test('an unknown code is refused with its reason', () async {
      final c = await asPartner('hotel_manager');
      final check = (await c.read(requestActionsProvider.notifier).checkVoucher('GV-0000-NONE')).valueOrNull!;
      expect(check.ok, isFalse);
      expect(check.reason, RedeemFailure.unknownCode);
    });
  });

  group('tab badges', () {
    test('the manager sees the pending count on Bookings; it drops after an accept', () async {
      final c = await asPartner('hotel_manager', overrides: partnerStateOverrides);
      final counts = await c.read(partnerBadgeCountsProvider.future);
      expect(counts.pending, greaterThan(0));
      final badges = c.read(gzTabBadgesProvider);
      expect(badges['bookings']!.count, counts.pending);

      await c.read(requestActionsProvider.notifier).accept(heroId);
      final after = await c.read(partnerBadgeCountsProvider.future);
      expect(after.pending, counts.pending - 1);
      expect(after.awaitingClient, counts.awaitingClient + 1);
    });

    test('an SLA danger tints the Bookings badge; no one signed in means no badges', () async {
      final danger = world.container(
        overrides: [
          partnerBadgeCountsProvider.overrideWith((ref) async => const PartnerBadgeCounts(pending: 3, unreadMessages: 2, danger: true)),
          gzTabBadgesProvider.overrideWith((ref) => ref.watch(partnerTabBadgesProvider)),
        ],
      );
      await danger.read(partnerBadgeCountsProvider.future);
      final badges = danger.read(gzTabBadgesProvider);
      expect(badges['bookings']!.tone, GzCountTone.danger);
      expect(badges['messages']!.count, 2);

      final guest = world.container(overrides: partnerStateOverrides);
      expect(guest.read(gzTabBadgesProvider), isEmpty);
    });
  });
}
