// Prototype state: the shapes of every slice. Money is integer fils ({ fils, currency }, ADR 0010); ids are fixture ids; nothing here
// is a display string. The store is the prototype's memory only: nothing is persisted, a reload is the story start.
import type {
  Audience,
  Booking,
  Brief,
  GatewayMethod,
  GroupThread,
  IsoDate,
  IsoDateTime,
  Listing,
  ListingRejectionCode,
  AdPlanCycle,
  Message,
  Money,
  Notification,
  RedeemCheck,
  Voucher,
  VisitAppointment,
  VisitStatus,
} from '../../mock'

export type Lang = 'en' | 'ar'

// ---------------------------------------------------------------- language
export type LanguageSlice = {
  language: Lang
  /** Writes ?lang= (the URL is the source of truth, so a screenshot URL is the whole state); the bridge mirrors it back here. */
  setLanguage: (lang: Lang) => void
}

// ---------------------------------------------------------------- auth (ADR 0038: no guest mode)
/** `guest` is only the signed-out state: the Client app shows nothing but the first-run screens (language, introduction, sign-in) until `signIn`. The Partner app has its own signed-out screens (HL-ACCS-*). */
export type AuthLevel = 'guest' | 'signedIn'
/** Required at sign-up, editable in Profile (ADR 0038 D4, OQ-R2-02): not shown to venues and not used to filter. */
export type Sex = 'female' | 'male'
export type AuthUser = { id: string; name: string; phone: string; monogram: string; sex?: Sex }

export type AuthSlice = {
  auth: AuthLevel
  user: AuthUser | null
  signIn: (user?: AuthUser) => void
  signOut: () => void
  /** Name and sex are editable in Profile (CL-PROF-03); the monogram follows the name. */
  patchUser: (patch: Partial<Pick<AuthUser, 'name' | 'sex' | 'monogram'>>) => void
}

// ---------------------------------------------------------------- wedding profile (onboarding result)
export type WeddingRole = 'bride' | 'groom' | 'family' | 'planner'
export type WeddingProfileState = {
  role: WeddingRole
  name: string
  partnerName: string | null
  weddingDate: IsoDate | null
  dateMode: 'exact' | 'flexible_month' | 'undecided'
  guests: { women: number; men: number }
  venueBudget: { min: Money; max: Money } | null
  totalBudget: Money | null
  /** Retired by ADR 0038 (no exact-area choice anywhere in the Client app): kept so an older profile still reads; new answers go to `governorateIds`. */
  areaIds: string[]
  /** ADR 0038 (CA-FLT-08): the governorates the couple prefers. Undefined = derive from `areaIds`. */
  governorateIds?: string[]
  searching: Audience[]
}

export type WeddingSlice = {
  weddingProfile: WeddingProfileState | null
  setWeddingProfile: (profile: WeddingProfileState | null) => void
  patchWeddingProfile: (patch: Partial<WeddingProfileState>) => void
}

// ---------------------------------------------------------------- favourites and compare (ADR 0009)
export type FavouriteKind = 'venue' | 'vendor' | 'package'
export type FavouritesSlice = {
  favourites: Record<FavouriteKind, string[]>
  /** Returns the new state of the heart. */
  toggleFavourite: (kind: FavouriteKind, id: string) => boolean
}

export const COMPARE_MAX = 3
export type CompareResult = 'added' | 'exists' | 'full'
export type CompareSlice = {
  /** Venue ids, first added first (the first sits at inline-start). At most COMPARE_MAX. */
  compareList: string[]
  addToCompare: (venueId: string) => CompareResult
  removeFromCompare: (venueId: string) => void
  /** Replace one column with another venue (the full-tray "Replace" path). */
  replaceInCompare: (oldId: string, newId: string) => void
  clearCompare: () => void
}

// ---------------------------------------------------------------- the Brief (ADR 0007 D3)
export type SearchBrief = Brief & {
  dateMode: 'exact' | 'flexible_month' | 'undecided'
  /** ADR 0038: the only region the client chooses. Undefined = derive from `areaIds` of an older Brief (briefGovernorates); [] = every governorate. */
  governorateIds?: string[]
}
export type BriefSlice = {
  searchBrief: SearchBrief
  setBrief: (patch: Partial<SearchBrief>) => void
  clearBrief: () => void
}

// ---------------------------------------------------------------- booking draft (ADR 0033: a request for the voucher price)
export type BookingStep = 'package' | 'details' | 'review' | 'sent'
export type BookingDraft = {
  targetType: 'venue' | 'provider'
  venueId: string | null
  /** Set when the request goes to a service provider (no hall, no session). */
  providerId: string | null
  hallId: string | null
  sessionId: string | null
  packageId: string | null
  extras: string[]
  eventDate: IsoDate | null
  audience: Audience | null
  /** Guests (venue) or quantity (provider). */
  guests: number | null
  personal: { name: string; phone: string; email: string; bookingFor: 'bride' | 'groom' | 'family' | 'planner' }
  requests: string
  /** The voucher bound to this quote once the client has paid for it. */
  voucherId: string | null
  step: BookingStep
}
export type BookingSlice = {
  bookingDraft: BookingDraft
  startDraft: (venueId: string, patch?: Partial<BookingDraft>) => void
  patchDraft: (patch: Partial<BookingDraft>) => void
  toggleExtra: (extraId: string) => void
  setStep: (step: BookingStep) => void
  resetDraft: () => void
}

// ---------------------------------------------------------------- payment outcome (ADR 0027 gateway boundary; ADR 0033: the KD 2 voucher and listing plans only)
export type PaymentOutcome = 'idle' | 'processing' | 'success' | 'failed' | 'cancelled' | 'verifying'
export type PaymentMethodKey = GatewayMethod
export type PaymentState = {
  outcome: PaymentOutcome
  method: PaymentMethodKey | null
  kind: 'voucher' | 'listing' | null
  /** The voucher id (kind voucher) or listing id (kind listing) being paid for. */
  refId: string | null
  amount: Money | null
}
export type PaymentSlice = {
  payment: PaymentState
  beginPayment: (args: { kind: 'voucher' | 'listing'; refId: string; amount: Money; method: PaymentMethodKey }) => void
  setPaymentOutcome: (outcome: PaymentOutcome) => void
  resetPayment: () => void
}

// ---------------------------------------------------------------- vouchers (the client's wallet, ADR 0033 D2)
export type VoucherPurchase = {
  targetType: 'venue' | 'provider'
  targetId: string
  hallId?: string | null
  packageId: string
  eventDate: IsoDate
  guests?: number | null
  /** Integer fils of the bound quote: standard and voucher price. */
  standardFils: number
  voucherFils: number
}
export type VoucherSlice = {
  /** A mutable copy of every voucher (the wallet is `selectMyVouchers`; the partner redeems from the same objects); the fixtures are never touched. */
  vouchers: Voucher[]
  /** A mutable copy of the client's requests. A request the partner acts on changes here too (same ids as `hotelBookings`). */
  clientBookings: Booking[]
  /** Creates an `unpaid` voucher bound to one target and quote (A-01) and returns its id. The checkout lapses after 30 minutes unpaid. */
  startVoucherCheckout: (purchase: VoucherPurchase) => string
  /** Settles the checkout: success makes the voucher `active` (60 days), failure leaves it `unpaid` and nothing charged. */
  settleVoucherPayment: (outcome: 'success' | 'failed') => void
  /** R01: sends the request at the voucher price, binds the voucher, returns the new request id (null when the draft or voucher is unusable). */
  sendRequest: (voucherId: string, draft?: Partial<BookingDraft>) => string | null
  /** R07 and R10a: the client withdraws or cancels; the voucher is released (R13a after confirm consumes it). */
  cancelRequest: (bookingId: string, reason?: Booking['reasonCode']) => void
  /** R08: the client confirms inside the 24 h window. */
  confirmBooking: (bookingId: string) => boolean
  /** R09: the 24 h window passed without a confirmation (the prototype's "let it lapse" control). The voucher is forfeited (ADR 0035 D4). */
  lapseApproval: (bookingId: string) => void
  /** Ask support for a credit voucher after a venue-fault release (never money back). */
  askSupportCredit: (voucherId: string) => void
}

// ---------------------------------------------------------------- partner request actions (ADR 0008 D5, D6; ADR 0033 D3)
export type HotelAction = { kind: 'approve' | 'decline' | 'counter'; bookingId: string; before: Booking; beforeVoucher: Voucher | null }
export type HotelSlice = {
  /** A mutable copy of the partner venue's requests; the fixtures are never touched. */
  hotelBookings: Booking[]
  /** The last action, undoable while its toast shows (8 s). */
  lastHotelAction: HotelAction | null
  /** R03: approves at the voucher price (or lower). Starts the fixed 24 h confirm window. */
  acceptRequest: (bookingId: string, opts?: { lowerVoucherTotal?: Money }) => void
  /** R04: declines with a reason; the voucher is released and refundable. */
  declineRequest: (bookingId: string, reason?: Booking['rejectReason']) => void
  /** "Propose another date": the request stays `pending` with a counter-offer attached (1 to 3 dates, 48 h, voucher price held). */
  rescheduleRequest: (bookingId: string, newDate: IsoDate) => void
  /** Restores the request (and its voucher) exactly as before the last action (R03u, 8 s). */
  undoLastHotelAction: () => void
  /** The undo window has passed: the action stands. */
  commitHotelAction: () => void
  /** R11: the partner redeems a voucher by code (typed or scanned). Returns the check; on success the request is `redeemed` and the voucher `used`. */
  redeemVoucher: (code: string, staffName?: string) => RedeemCheck
  /** R10b and R13b: the partner revokes or cancels; the voucher is released and refundable (a reliability strike in the real system). */
  cancelByPartner: (bookingId: string, reason?: Booking['reasonCode']) => void
}

// ---------------------------------------------------------------- site visits and their three-way group chat (ADR 0033 D9)
export type VisitChat = { conversation: GroupThread; messages: Message[] }
export type VisitSlice = {
  /** A mutable copy of every visit (client and partner see the same objects). */
  visits: VisitAppointment[]
  /** Group chats created in this session, by visit id. Seeded visits read their chats through `groupThreadFor`. */
  visitChats: Record<string, VisitChat>
  /** Books a visit (free, independent of the voucher), creates its group chat of exactly three roles and returns the visit id. */
  bookVisit: (args: { venueId: string; slotStart: IsoDateTime; visitors: number; note?: string | null }) => string | null
  setVisitStatus: (visitId: string, status: VisitStatus, actor?: 'client' | 'hotel_representative' | 'support') => void
  /** Appends a typed message to a session-created visit chat. */
  sendVisitMessage: (visitId: string, from: 'client' | 'venue' | 'support', text: string) => void
}

// ---------------------------------------------------------------- service-provider listings (ADR 0033 D8)
export type ListingSlice = {
  /** A mutable copy of every listing; clients see only `active` ones. */
  listings: Listing[]
  /** Chooses (or changes) the advertising plan cycle of a draft listing. Rates are not decided, so nothing is charged. */
  chooseListingPlan: (listingId: string, cycle: AdPlanCycle) => void
  /** Sends a listing to review. It is NEVER published on payment: only a moderator decision publishes it. */
  submitListing: (listingId: string) => void
  /** The moderator decision stub (the Super Admin is context only): approve makes the listing live, reject records the reasons. */
  moderateListing: (listingId: string, decision: { approve: true } | { approve: false; codes: ListingRejectionCode[]; note?: string }) => void
}

// ---------------------------------------------------------------- notifications
export type NotificationsSlice = {
  readNotificationIds: string[]
  markNotificationRead: (id: string) => void
  markAllNotificationsRead: (audience: Notification['audience']) => void
}

// ---------------------------------------------------------------- helpers
export type HelperSlice = {
  /** Back to the story start: guest, empty favourites and compare, no brief, untouched hotel queue. */
  resetToStoryStart: () => void
  /** Load the shared story as one persona. `client`: Reem signed in with her wedding profile, brief and saved venues. */
  loadStory: (persona: 'client' | 'hotel') => void
}

export type PrototypeState = LanguageSlice &
  AuthSlice &
  WeddingSlice &
  FavouritesSlice &
  CompareSlice &
  BriefSlice &
  BookingSlice &
  PaymentSlice &
  VoucherSlice &
  HotelSlice &
  VisitSlice &
  ListingSlice &
  NotificationsSlice &
  HelperSlice
