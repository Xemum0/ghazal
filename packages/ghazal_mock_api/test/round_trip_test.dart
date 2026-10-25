// The typed round trip: the REAL ghazal_api repositories (dio, interceptors, generated models) against MockBackend.httpClientAdapter.
// If the mock sent a shape the models cannot parse, or the client sent one the mock rejects, these tests fail.
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_api/ghazal_api.dart' show AuthTokens;
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import 'harness.dart';

void main() {
  late World w;
  setUp(() async => w = await World.create());

  test('guest reads the public catalog', () async {
    final a = w.actor('guest');
    final config = await a.dio.get<Object?>('/config');
    expect(config.statusCode, 200);
    final areas = await a.repos.venues.listAreas();
    expect(areas.governorates, isNotEmpty);
    final taxonomy = await a.repos.venues.getFilterTaxonomy();
    expect(taxonomy.sorts, isNotEmpty);
    final page = await a.repos.venues.searchVenues(limit: 5);
    expect(page.items.length, 5);
    expect(page.nextCursor, isNotNull);
    final next = await a.repos.venues.searchVenues(limit: 5, cursor: page.nextCursor);
    expect(next.items.first.venue.id, isNot(page.items.first.venue.id));
    final count = await a.repos.venues.countVenues();
    expect(count.count, 16);
    final regions = await a.repos.venues.searchRegions(q: 'salmiya');
    expect(regions, isNotEmpty);
  });

  test('venue detail, availability, day and the hero quote: KD 18,200 standard, KD 15,400 voucher', () async {
    final a = w.actor('guest');
    final detail = await a.repos.venues.getVenue(venueId: 'V01', date: LocalDate.parse('2027-01-14'), guests: 350, audience: Audience.women);
    expect(detail.venue.id, 'V01');
    expect(detail.packages, isNotEmpty);
    final avail = await a.repos.venues.getVenueAvailability(
      venueId: 'V01',
      from: LocalDate.parse('2027-01-01'),
      to: LocalDate.parse('2027-01-31'),
      hallId: 'V01-danah',
      guests: 350,
      audience: Audience.women,
    );
    expect(avail.days.length, 31);
    final day = await a.repos.venues.getVenueDayAvailability(venueId: 'V01', date: LocalDate.parse('2027-01-14'), guests: 350, audience: Audience.women);
    expect(day.hallId, isNotNull);
    final quote = await a.repos.venues.quoteVenue(
      venueId: 'V01',
      body: VenueQuoteInput(
        eventDate: LocalDate.parse('2027-01-14'),
        sections: [QuoteSectionInput(hallId: 'V01-danah', audience: Audience.women, guests: 350, packageId: 'V01-ladies-weekend')],
      ),
    );
    expect(quote.voucherOffered, isTrue);
    expect(quote.totals.standardTotal.fils, 18200000);
    expect(quote.totals.voucherTotal.fils, 15400000);
    expect(quote.quoteId, isNotNull);
  });

  test('a gated call without a session is AUTH_REQUIRED; the error is a typed ApiProblem', () async {
    final a = w.actor('guest');
    await expectLater(
      a.repos.vouchers.listVouchers(),
      throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 401).having((e) => e.code, 'code', ApiProblemCode.authRequired)),
    );
  });

  test('sign in by WhatsApp code, then me', () async {
    final a = w.actor('guest');
    final ch = await a.repos.auth.requestOtp(
      body: const OtpRequestInput(phone: '+96550000012', purpose: OtpPurpose.login),
    );
    expect(ch.codeLength, 6);
    await expectLater(
      a.repos.auth.verifyOtp(
        body: OtpVerifyInput(challengeId: ch.challengeId, code: '000000'),
      ),
      throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 423)),
    );
    final session = await a.repos.auth.verifyOtp(
      body: OtpVerifyInput(challengeId: ch.challengeId, code: '123456'),
    );
    expect(session.user.user.name, isNotEmpty);
    expect(session.isNewUser, isFalse);
    await a.tokens.write(AuthTokens(accessToken: session.accessToken, refreshToken: session.refreshToken));
    final me = await a.repos.profile.getMe();
    expect(me.user.phone, '+96550000012');
    expect(me.phoneVerified, isTrue);
  });

  test('Reem: wallet, requests and the hero request detail', () async {
    final a = w.actor('reem');
    final wallet = await a.repos.vouchers.listVouchers();
    expect(wallet.items, isNotEmpty);
    final requests = await a.repos.requests.listRequests();
    final hero = requests.items.firstWhere((r) => r.booking.ref == 'GZ-2611-0147');
    expect(hero.booking.status, BookingStatus.pending);
    final detail = await a.repos.requests.getRequest(requestId: hero.booking.id);
    expect(detail.booking.totals.voucherTotal.fils, 15400000);
    expect(detail.confirmWindow.state, ConfirmWindowState.none);
    final overview = await a.repos.wedding.getWeddingOverview();
    expect(overview.daysToWedding, 63);
    final budget = await a.repos.wedding.getBudget();
    expect(budget.paid.fils, 2000);
    final home = await a.repos.home.getHome();
    expect(home.statusCard.kind, HomeStatusKind.pending);
  });

  test('partner: Today, Needs you, request inbox with the hero request on top', () async {
    final a = w.actor('hotel_manager', venueId: 'V01');
    final me = await a.repos.partnerAccount.getPartnerMe();
    expect(me.memberships.map((m) => m.venueId), ['V01', 'V-sister-marina'], reason: 'Hind also works at the sister venue, so Switch venue shows');
    final today = await a.repos.partnerRequests.getPartnerToday();
    expect(today.tiles.requests, greaterThan(0));
    expect(today.needsYou, isNotEmpty);
    final pending = await a.repos.partnerRequests.listPartnerRequests(segment: RequestSegment.pending);
    expect(pending.items.any((r) => r.booking.ref == 'GZ-2611-0147'), isTrue);
    final detail = await a.repos.partnerRequests.getPartnerRequest(requestId: 'bk-GZ-2611-0147');
    expect(detail.client.name, isNotEmpty);
    final calendar = await a.repos.partnerCalendar.getPartnerCalendar(from: LocalDate.parse('2027-01-01'), to: LocalDate.parse('2027-01-31'));
    expect(calendar.days.length, 31);
    final listings = await a.repos.partnerListings.listListings();
    expect(listings.listings, isEmpty);
  });

  test('provider: listings, billing says rates announced soon, no payment can be created', () async {
    final a = w.actor('provider', providerId: 'vendor-flowers-zahra');
    final listings = await a.repos.partnerListings.listListings();
    expect(listings.listings.any((l) => l.id == 'lst-flowers-zahra' && l.status == ListingStatus.active), isTrue);
    expect(listings.listings.map((l) => l.status).toSet().length, greaterThan(1), reason: 'the provider persona sees listings in several review states');
    final billing = await a.repos.partnerListings.getPartnerBilling();
    expect(billing.payable, isFalse);
    expect(billing.plans.every((p) => p.announcedSoon), isTrue);
    final provider = await a.repos.partnerListings.getPartnerProvider();
    expect(provider.packages, isNotEmpty);
  });

  test('notifications, chat and the support conversation of Reem', () async {
    final a = w.actor('reem');
    final n = await a.repos.notifications.listNotifications();
    expect(n.items, isNotEmpty);
    final unread = await a.repos.notifications.getUnreadNotificationCount();
    expect(unread.count, greaterThan(0));
    await a.repos.notifications.markAllNotificationsRead();
    expect((await a.repos.notifications.getUnreadNotificationCount()).count, 0);
    final convs = await a.repos.chat.listConversations();
    expect(convs.items.any((c) => c.kind == ConversationKind.visitGroup), isTrue);
    final msgs = await a.repos.chat.listMessages(conversationId: 'conv-aurelia-reem');
    expect(msgs.items, isNotEmpty);
    expect(msgs.items.every((m) => !m.draft), isTrue, reason: 'hotel drafts never reach the client');
    final support = await a.repos.support.getSupportConversation();
    expect(support.kind, ConversationKind.support);
    expect((await a.repos.support.listFaq()), isNotEmpty);
  });

  test('services, planners and favourites', () async {
    final a = w.actor('reem');
    final cats = await a.repos.services.listServiceCategories();
    expect(cats.primary, isNotEmpty);
    final providers = await a.repos.services.listServiceProviders(categoryId: cats.primary.first.id);
    expect(providers.items, isNotEmpty);
    final packages = await a.repos.planners.listPlannerPackages();
    expect(packages.length, 3);
    final saved = await a.repos.wedding.listWishlist();
    expect(saved.items, isNotEmpty);
  });
}
