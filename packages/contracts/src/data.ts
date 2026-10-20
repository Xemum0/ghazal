// Typed loaders for packages/contracts/fixtures/*.json. The JSON is generated from seed/*.mjs (see scripts/build.mjs) and is
// the single seed for both apps and, later, the Flutter fixture tests. Everything here is read-only data (voucher model, ADR 0033).
import type {
  AdPlan,
  Area,
  AmenityDef,
  Analytics,
  Booking,
  BudgetBand,
  Budget,
  CalendarClaim,
  ChecklistItem,
  Conversation,
  DayOverride,
  Extra,
  FaqItem,
  FilterTaxonomy,
  Governorate,
  GroupThread,
  HotelSettings,
  HotelStaff,
  HotelVariants,
  Listing,
  Message,
  Meta,
  Notification,
  NotificationPreferences,
  Package,
  PartnerAccount,
  PartnerPersona,
  Planner,
  PlannerPackage,
  PlannerRequest,
  PriceRule,
  ReferencePoint,
  RequestItem,
  Review,
  ReviewDecision,
  ServiceCategory,
  ServiceGroup,
  ServiceProvider,
  User,
  VendorQuoteRequest,
  Venue,
  VenueMembership,
  VisitAppointment,
  Voucher,
  VoucherWindow,
  WeddingProfile,
  ClientState,
  Money,
} from './types.ts'

import metaJson from '../fixtures/meta.json'
import areasJson from '../fixtures/areas.json'
import amenitiesJson from '../fixtures/amenities.json'
import taxonomyJson from '../fixtures/taxonomy.json'
import venuesJson from '../fixtures/venues.json'
import packagesJson from '../fixtures/packages.json'
import windowsJson from '../fixtures/voucher-windows.json'
import reviewsJson from '../fixtures/reviews.json'
import overridesJson from '../fixtures/day-overrides.json'
import servicesJson from '../fixtures/services.json'
import partnersJson from '../fixtures/partners.json'
import visitsJson from '../fixtures/visits.json'
import plannersJson from '../fixtures/planners.json'
import peopleJson from '../fixtures/people.json'
import clientJson from '../fixtures/client.json'
import bookingsJson from '../fixtures/bookings.json'
import vouchersJson from '../fixtures/vouchers.json'
import chatJson from '../fixtures/chat.json'
import hotelJson from '../fixtures/hotel.json'
import faqJson from '../fixtures/faq.json'
import stressVenuesJson from '../fixtures/stress/venues.json'
import stressBookingsJson from '../fixtures/stress/bookings.json'
import stressEmptyJson from '../fixtures/stress/empty.json'
import stressTextJson from '../fixtures/stress/text.json'

// JSON modules widen string-literal unions to `string`; the fixtures are validated by `pnpm -F @gz/contracts validate`.
const as = <T>(v: unknown): T => v as T

export const meta = as<Meta>(metaJson)

/** Fixed prototype clock: Thu 12 Nov 2026, 4:00 PM, Asia/Kuwait (ADR 0031, docs/engineering/conventions.md section 8). */
export const PROTOTYPE_NOW: string = meta.now
export const PROTOTYPE_TODAY: string = meta.today

// ---------------------------------------------------------------- geography and filters
export const governorates = as<Governorate[]>(areasJson.governorates)
export const areas = as<Area[]>(areasJson.areas)
export const referencePoints = as<ReferencePoint[]>(areasJson.referencePoints)
export const amenityDefs = as<AmenityDef[]>(amenitiesJson)
/** Venue types, capacity range and bands, pricing structures and sorts of the filter sheet. */
export const filterTaxonomy = as<FilterTaxonomy>(taxonomyJson)

// ---------------------------------------------------------------- venues, packages (two prices), voucher windows
export const venues = as<Venue[]>(venuesJson)
export const packages = as<Package[]>(packagesJson.packages)
export const priceRules = as<PriceRule[]>(packagesJson.priceRules)
export const extras = as<Extra[]>(packagesJson.extras)
/** Time-boxed voucher prices (HL-GROW-01..03); they replace offers, flash sales and coupon codes. */
export const voucherWindows = as<VoucherWindow[]>(windowsJson)
export const reviews = as<Review[]>(reviewsJson)
export const dayOverrides = as<DayOverride[]>(overridesJson)

// ---------------------------------------------------------------- additional services and the Partner app
export const serviceGroups = as<ServiceGroup[]>(servicesJson.groups)
export const serviceCategories = as<ServiceCategory[]>(servicesJson.categories)
export const serviceProviders = as<ServiceProvider[]>(servicesJson.providers)
/** @deprecated Pre-voucher name of `serviceProviders`; kept so screens keep compiling while they migrate. */
export const vendors = serviceProviders
export const partnerAccounts = as<PartnerAccount[]>(partnersJson.accounts)
/** Weekly, monthly and annual advertising plans. Rates are NOT decided: `ratesFils` is null ("Rates announced soon"). */
export const adPlans = as<AdPlan[]>(partnersJson.adPlans)
export const listings = as<Listing[]>(partnersJson.listings)
export const reviewDecisions = as<ReviewDecision[]>(partnersJson.reviewDecisions)
export const partnerPersonas = as<PartnerPersona[]>(partnersJson.personas)

export const plannerPackages = as<PlannerPackage[]>(plannersJson.packages)
export const planners = as<Planner[]>(plannersJson.planners)

// ---------------------------------------------------------------- people
export const users = as<User[]>(peopleJson.users)
export const hotelStaff = as<HotelStaff[]>(peopleJson.hotelStaff)

// ---------------------------------------------------------------- the client persona
export const weddingProfile = as<WeddingProfile>(clientJson.weddingProfile)
export const budgetBands = as<BudgetBand[]>(clientJson.budgetBands)
export const checklist = as<ChecklistItem[]>(clientJson.checklist)
export const budget = as<Budget>(clientJson.budget)
export const budgetVariants = as<{
  pending: { paid: Money; committed: Money }
  confirmed: { paid: Money; committed: Money }
  sampleExpense: Budget['expenses'][number]
  flowersAt82: { categoryId: string; paid: Money }
}>(clientJson.budgetVariants)
export const notificationPrefs = as<NotificationPreferences>(clientJson.notificationPrefs)
export const clientState = as<ClientState>(clientJson.state)
export const plannerRequest = as<PlannerRequest>(clientJson.plannerRequest)
export const vendorQuoteRequest = as<VendorQuoteRequest>(clientJson.vendorQuoteRequest)
export const clientNotifications = as<Notification[]>(clientJson.notifications)
export const heroVariantNotifications = as<
  Record<'approved' | 'confirmReminder' | 'confirmed' | 'lapsed' | 'declined' | 'redeemed' | 'thirtyDays', Notification>
>(clientJson.heroVariantNotifications)

// ---------------------------------------------------------------- requests and vouchers
export const bookings = as<Booking[]>(bookingsJson.bookings)
export const vouchers = as<Voucher[]>(vouchersJson.vouchers)
export const competingVoucher = as<Voucher>(vouchersJson.competingVoucher)
/** The hero request walked through every state: the same booking and voucher (same ids, same quote) in each variant. */
export type HeroVariant = 'pending' | 'approved' | 'confirmed' | 'redeemed' | 'completed' | 'declined' | 'expired' | 'lapsed' | 'cancelled' | 'counter_offer'
export const heroVariants = as<Record<Exclude<HeroVariant, 'pending'>, { booking: Booking; voucher: Voucher }>>(bookingsJson.heroVariants)
export const competingRequest = as<Booking>(bookingsJson.competingRequest)

// ---------------------------------------------------------------- visits and chat
export const visits = as<VisitAppointment[]>(visitsJson)
export const conversations = as<Conversation[]>(chatJson.conversations)
export const messages = as<Message[]>(chatJson.messages)
/** The dedicated three-way group chats of the visits (client, hotel representative, Ghazal support representative). */
export const groupThreads = conversations.filter((c): c is GroupThread => c.kind === 'visit_group')

// ---------------------------------------------------------------- the hotel side (Aurelia Gulf Hotel)
export const triage = as<RequestItem[]>(hotelJson.triage)
export const calendarClaims = as<CalendarClaim[]>(hotelJson.calendarClaims)
export const softDates = as<string[]>(hotelJson.softDates)
export const softDateOptOut = as<string[]>(hotelJson.softDateOptOut)
export const analytics = as<Analytics>(hotelJson.analytics)
export const hotelSettings = as<HotelSettings>(hotelJson.settings)
export const hotelMemberships = as<VenueMembership[]>(hotelJson.memberships)
export const hotelNotifications = as<Notification[]>(hotelJson.notifications)
export const hotelVariants = as<
  HotelVariants & { proposalCandidates: { eventDate: string; hallId: string; sessionId: string; quotedTotal: Money; delta: Money }[] }
>(hotelJson.variants)

export const platformFaq = as<FaqItem[]>(faqJson)

/**
 * Stress fixtures (docs/engineering/testing.md section 6): a long mixed-script name, a venue with no photos, a venue with no
 * reviews, extreme prices, awkward requests, empty lists and the shaping-and-bidi sheet. Ids start with S; never in the main lists.
 */
export const stress = {
  venues: as<Venue[]>(stressVenuesJson.venues),
  packages: as<Package[]>(stressVenuesJson.packages),
  priceRules: as<PriceRule[]>(stressVenuesJson.priceRules),
  extras: as<Extra[]>(stressVenuesJson.extras),
  /** Venue ids of the three compare items with three price units: per guest, flat per night, ministry rental fee. */
  compareUnits: as<string[]>(stressVenuesJson.compareUnits),
  bookings: as<Booking[]>(stressBookingsJson.bookings),
  vouchers: as<Voucher[]>(stressBookingsJson.vouchers),
  empty: as<Record<string, never[]>>(stressEmptyJson),
  text: stressTextJson as Record<string, unknown>,
}
