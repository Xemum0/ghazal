// Prototype mock content (ADR 0031 D6). The single bilingual seed is packages/contracts/fixtures: both apps read it from here, and the
// Flutter tests will reuse the same JSON. Screens import mock data from this barrel, never from the package path or the JSON files.
//
// Time is fixed: the prototype clock is Thu 12 Nov 2026, 4:00 PM, Asia/Kuwait. Read it through `clock` (or pass PROTOTYPE_NOW to a
// selector); never call the system clock. Money is integer fils ({ fils, currency }) and is formatted only by the shared formatter.
// What is in the seed, the hero ids and the shared story: docs/product/fixtures.md.
import { PROTOTYPE_NOW, PROTOTYPE_TODAY } from '@gz/contracts'

export * from '@gz/contracts'

/** The injected clock. Screens and mocks read `clock.now()`; there is no Date.now() in the prototype. */
export const clock = {
  now: (): string => PROTOTYPE_NOW,
  today: (): string => PROTOTYPE_TODAY,
} as const

export { PROTOTYPE_NOW, PROTOTYPE_TODAY }

// ---------------------------------------------------------------- selector index (all re-exported above; voucher model, ADR 0033)
// Venues       getVenue(id), requireVenue(id), getHall(hallId), listVenues(filter, brief), searchRegions(query), venueAvailabilityOn(venueId, date, brief),
//              cardPrice(venueId, brief) (standard amount + voucher + savings), guestRange(venueId), sectionTags(venueId), structuresOf(venueId),
//              nearby(venueId), compareSet(ids, brief, origin)
// Availability availabilityFor(venueId, hallId, month, brief) (fromPrice + voucherPrice), availabilityYear(venueId, hallId, brief)
// Packages     packagesFor(venueId), getPackage(id), extrasFor(venueId), rulesFor(scopeId), windowsFor(venueId), activeWindows()
// Pricing      quoteFor({ venueId, eventDate, sections, extras, venueDiscount }), quoteForProvider({ providerId, packageId, qty })  -> standard, voucher, savings, eligible
// Reviews      reviewsFor(venueId), reviewsAwaitingReply(venueId)
// Requests     bookingsFor({ venueId, providerId, clientId, status }), getBooking(idOrRef), heroBookingAs(variant), heroVoucherAs(variant),
//              confirmCountdown(booking), bookingTarget(booking)
// Vouchers     vouchersFor(clientId), getVoucher(idOrCode), voucherFor(booking), voucherOptions(voucher), redeemableFor(targetId), checkRedemption(code, targetId)
// Visits       visitsFor(filter), getVisit(id), visitSlotsFor(venueId, date), visitDatesFor(venueId), groupThreadFor(visitId, side)
// Services     primaryCategories(), secondaryCategories(), providersFor(categoryId), getProvider(id), listingsFor(providerId), activeListingOf(providerId)
// Partner      requestsFor(venueId), needsYou(venueId), slaOf(item), calendarFor(venueId, month), softDatesFor(venueId), openWeekendDates(venueId),
//              partnerFor(accountId), personaFor(kind), paysFees(accountId), planRates()
// Chat         conversationsFor('client' | 'hotel'), messagesFor(conversationId, 'client' | 'hotel'), notificationsFor('client' | 'hotel')
// Planning     checklistFor(bookingStatus), budgetFor(bookingStatus), daysToWedding()
// Reference    areasByGovernorate(), getArea(id), getGovernorate(id), filterTaxonomy, governorates, serviceProviders, adPlans, listings, partnerAccounts
// Engine       engine.* (pricing, availability, voucher rules, transitions R01-R13, visit slots, SLA, dates, money): the same code that built the fixtures
// Stress       stress.* (long names, no photos, no reviews, extreme prices, empty lists, bidi sheet, lapsed and withdrawn requests)
