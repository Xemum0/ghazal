// Every seeded document through the generated models: pages of every list a persona can open are walked to the end and each row's detail is
// fetched, so a seed or a handler that the client models cannot parse fails here instead of in a screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import 'harness.dart';

Future<List<T>> all<T>(Future<Page<T>> Function(String? cursor) fetch) async {
  final out = <T>[];
  String? cursor;
  for (var i = 0; i < 40; i++) {
    final page = await fetch(cursor);
    out.addAll(page.items);
    cursor = page.nextCursor;
    if (cursor == null) return out;
  }
  fail('a list never ended');
}

void main() {
  late World w;
  setUp(() async => w = await World.create());

  test('client side: every list and detail of Reem parses', () async {
    final a = w.actor('reem');
    final r = a.repos;
    final wallet = await all((c) => r.vouchers.listVouchers(cursor: c, limit: 3));
    expect(wallet.length, greaterThanOrEqualTo(5));
    for (final item in wallet) {
      final d = await r.vouchers.getVoucher(voucherId: item.voucher.id);
      expect(d.voucher.id, item.voucher.id);
    }
    final requests = await all((c) => r.requests.listRequests(cursor: c, limit: 4));
    expect(requests.length, greaterThanOrEqualTo(3));
    for (final row in requests) {
      final d = await r.requests.getRequest(requestId: row.booking.id);
      expect(d.booking.id, row.booking.id);
      await r.requests.getConfirmWindow(requestId: row.booking.id);
    }
    for (final row in await all((c) => r.visits.listVisits(cursor: c))) {
      final t = await r.visits.getVisitThread(visitId: row.visit.id);
      expect(t.thread.members, isNotNull);
    }
    for (final conv in await all((c) => r.chat.listConversations(cursor: c, limit: 5))) {
      final msgs = await all((c) => r.chat.listMessages(conversationId: conv.id, cursor: c, limit: 10));
      expect(msgs, isNotEmpty, reason: conv.id);
    }
    expect((await all((c) => r.notifications.listNotifications(cursor: c, limit: 5))).length, greaterThan(10));
    await all((c) => r.vouchers.listReceipts(cursor: c));
    await all((c) => r.support.listRefundRequests(cursor: c));
    await all((c) => r.services.listQuoteRequests(cursor: c));
    await r.wedding.getBudget();
    await r.wedding.getChecklist();
    await r.wedding.getWeddingOverview();
    await r.planners.getCurrentPlannerRequest();
    final providers = await all((c) => r.services.listServiceProviders(cursor: c, limit: 20));
    expect(providers.length, greaterThan(20));
    final venues = await all((c) => r.venues.searchVenues(cursor: c, limit: 6, date: LocalDate.parse('2027-01-14'), guests: 300, audience: Audience.women));
    expect(venues.length, greaterThan(8));
    for (final v in venues.take(5)) {
      await r.venues.getVenue(venueId: v.venue.id, date: LocalDate.parse('2027-01-14'), guests: 300);
      await all((c) => r.reviews.listVenueReviews(venueId: v.venue.id, cursor: c, limit: 20));
    }
  });

  test('partner side: every list and detail of the hotel manager parses', () async {
    final a = w.actor('hotel_manager', venueId: 'V01');
    final r = a.repos;
    for (final seg in RequestSegment.values.where((s) => s != RequestSegment.unknown)) {
      final rows = await all((c) => r.partnerRequests.listPartnerRequests(segment: seg, cursor: c, limit: 5));
      for (final row in rows.take(6)) {
        await r.partnerRequests.getPartnerRequest(requestId: row.booking.id);
      }
    }
    await r.partnerRequests.getPartnerToday();
    await r.partnerRequests.listNeedsYou();
    await all((c) => r.partnerBookings.listRedeemableVouchers(cursor: c));
    await all((c) => r.partnerBookings.listRedeemedVouchers(cursor: c));
    for (final row in await all((c) => r.partnerVisits.listPartnerVisits(cursor: c))) {
      await r.partnerVisits.getPartnerVisitThread(visitId: row.id);
    }
    await r.partnerCalendar.getPartnerCalendar(from: LocalDate.parse('2026-11-01'), to: LocalDate.parse('2027-02-28'));
    await r.partnerCalendar.getPartnerCalendarDay(date: LocalDate.parse('2026-12-10'));
    await r.partnerCalendar.listCalendarHolds();
    await r.partnerCalendar.getSoftDates();
    await all((c) => r.partnerReviews.listPartnerReviews(cursor: c, limit: 20));
    final analytics = await r.partnerGrowth.getPartnerAnalytics();
    expect(analytics.series, isNotEmpty);
    await r.partnerGrowth.listVoucherWindows();
    final staff = await r.partnerAccount.listStaff();
    expect(staff.staff.length, 5);
    await r.partnerAccount.getPartnerNotificationPreferences();
    await r.partnerVenue.getPartnerVenue();
    await r.partnerVenue.listPartnerHalls();
    await r.partnerVenue.listPartnerPackages();
    await r.partnerVenue.getVenuePolicies();
    await r.partnerVenue.getBookingRules();
    await r.partnerVenue.getBusinessHours();
    final media = await r.partnerVenue.listVenueMedia();
    expect(media.items, isNotEmpty);
    await r.partnerVisits.getVisitAvailability();
    for (final conv in await all((c) => r.chat.listConversations(cursor: c, limit: 5))) {
      await all((c) => r.chat.listMessages(conversationId: conv.id, cursor: c, limit: 10));
    }
    await r.notifications.listNotifications();
  });

  test('provider side: listings in every state, billing, packages, performance', () async {
    final a = w.actor('provider', providerId: 'vendor-flowers-zahra');
    final r = a.repos;
    final listings = (await r.partnerListings.listListings()).listings;
    for (final l in listings) {
      await r.partnerListings.getListing(listingId: l.id);
    }
    await r.partnerGrowth.getListingPerformance(listingId: 'lst-flowers-zahra');
    await r.partnerListings.getPartnerBilling();
    await r.partnerListings.listProviderPackages();
    await r.partnerRequests.getPartnerToday();
    final rows = await all((c) => r.partnerRequests.listPartnerRequests(segment: RequestSegment.pending, cursor: c));
    expect(rows, isNotEmpty);
  });

  test('the seeds hold provider listings in the review states the story needs', () async {
    final states = w.mock.app.seed.rows('Listing').map((l) => l['status'] as String).toSet();
    expect(states, containsAll(['draft', 'pending_review', 'approved', 'rejected', 'active', 'expired']));
  });
}
