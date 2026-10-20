import type { Audience, Bilingual, Id, IsoDate, IsoDateTime, Lang, Money } from './common.ts'

// ---------------------------------------------------------------- people

export type UserRole = 'client' | 'hotel_staff' | 'provider_staff' | 'planner' | 'support'

export interface User {
  id: Id
  role: UserRole
  /** Name as typed (user text is stored as typed; display uses dir=auto). */
  name: string
  /** Name in the other script when the seed carries one (staff and planners). */
  nameLatin?: string
  /** Single-letter monogram, first letter of the name in its own script, ignoring ال (ADR 0015 D4). */
  monogram: string
  /** Display-only fixture phone, +965 5000 00NN. */
  phone: string
  email: string | null
  locale: Lang
  digitStyle: 'western' | 'easternArabic'
  createdAt: IsoDateTime
}

export type WeddingRole = 'bride' | 'groom' | 'family' | 'planner'

export interface BudgetBand {
  id: Id
  min: Money
  /** null = open ended ("35,000+"). */
  max: Money | null
}

export interface WeddingProfile {
  id: Id
  userId: Id
  role: WeddingRole
  brideName: string
  partnerName: string | null
  weddingDate: IsoDate
  dateMode: 'exact' | 'flexible_month' | 'undecided'
  guests: { women: number; men: number }
  /** Venue and catering budget band chosen in onboarding (ADR 0007 D3, amended). */
  venueBudget: { min: Money; max: Money }
  /** Total wedding budget, asked in the Budget Manager. */
  totalBudget: Money
  areaIds: Id[]
  /** Sections the couple is searching for, in priority order. */
  searching: Audience[]
}

// ---------------------------------------------------------------- planning tools

export type ChecklistGroup =
  | 'invitation'
  | 'dress'
  | 'venue'
  | 'photographer'
  | 'cake'
  | 'music'
  | 'flowers'
  | 'transportation'
  | 'custom'

export interface ChecklistItem {
  id: Id
  group: ChecklistGroup
  title: Bilingual
  dueOn: IsoDate | null
  done: boolean
  doneAt: IsoDateTime | null
  /** Completed by the system (Venue completes at `confirmed`, not at approval: the client must confirm within 24 h). */
  auto: boolean
  custom: boolean
  /** Service category that "Choose a photographer" opens. */
  serviceCategoryId: Id | null
  bookingId: Id | null
}

export type BudgetCategoryId =
  | 'venue_catering'
  | 'photo_video'
  | 'flowers_decor'
  | 'attire'
  | 'makeup_henna'
  | 'cars'
  | 'invitations'
  | 'music'
  | 'honeymoon'

export interface BudgetExpense {
  id: Id
  categoryId: BudgetCategoryId
  label: string
  amount: Money
  status: 'paid' | 'committed' | 'planned'
  date: IsoDate | null
  bookingId: Id | null
  vendorId: Id | null
}

export interface BudgetCategory {
  id: BudgetCategoryId
  name: Bilingual
  allocated: Money
  paid: Money
  committed: Money
  /** Venue and catering is auto-linked to the booking. */
  autoLinked: boolean
  icon: string
}

export interface Budget {
  total: Money
  categories: BudgetCategory[]
  expenses: BudgetExpense[]
}

// ---------------------------------------------------------------- notifications

export type NotificationKind =
  // request machine (client side)
  | 'request_sent'
  | 'request_approved'
  | 'confirm_reminder'
  | 'request_confirmed'
  | 'request_declined'
  | 'request_expired'
  | 'booking_cancelled'
  // vouchers
  | 'voucher_ready'
  | 'voucher_released'
  | 'voucher_redeemed'
  | 'voucher_refunded'
  | 'voucher_expiring'
  // visits and group chat
  | 'visit_requested'
  | 'visit_confirmed'
  | 'visit_reminder'
  | 'visit_message'
  // partner side
  | 'new_request'
  | 'client_confirmed'
  | 'client_lapsed'
  | 'voucher_redeemed_by_you'
  | 'visit_request'
  | 'listing_submitted'
  | 'listing_approved'
  | 'listing_rejected'
  | 'listing_expiring'
  | 'review_received'
  | 'calendar_confirm'
  | 'invite'
  // planning
  | 'countdown'
  | 'new_venue'
  | 'planner_assigned'
  | 'message'
  | 'review_prompt'
  | 'checklist_due'

export interface Notification {
  id: Id
  audience: 'client' | 'hotel'
  userId: Id
  kind: NotificationKind
  title: Bilingual
  /** Ready-made copy for the prototype; production copy renders from the ARB with `params` through the formatter. */
  body: Bilingual
  /** Raw values behind the copy (fils, dates, names) so the formatter can render them in either language. */
  params: Record<string, string | number | Money>
  at: IsoDateTime
  read: boolean
  /** Visual tone of the leading icon: never the only signal (ADR 0003 D7). */
  tone: 'neutral' | 'gold' | 'success' | 'danger'
  /** Tag shown on the row, for example 'Needs reply'. */
  tag: Bilingual | null
  bookingId: Id | null
  venueId: Id | null
  conversationId: Id | null
  /** Marketing is opt-in (ADR 0015 D8); transactional always arrives. */
  channel: 'transactional' | 'marketing'
  /** Voucher the event is about (code is shown through the formatter as an LTR isolate). */
  voucherId?: Id | null
  /** Visit the event is about. */
  visitId?: Id | null
  /** Listing the event is about (partner notifications). */
  listingId?: Id | null
}

export interface NotificationPreferences {
  userId: Id
  marketing: boolean
  quietHours: { start: string; end: string }
  maxMarketingPerWeek: number
}

// ---------------------------------------------------------------- reviews

export interface OwnerReply {
  text: Bilingual
  repliedAt: IsoDateTime
  by: string
}

export interface Review {
  id: Id
  venueId: Id
  /** First name plus initial (نورة ع. / Noura A.), or anonymous. */
  author: Bilingual
  monogram: string
  anonymous: boolean
  /** 0.5 steps. */
  rating: number
  categories: { venue: number; food: number; service: number; value: number }
  text: Bilingual
  /** Language the author typed in. */
  origin: Lang
  audience: Exclude<Audience, 'mixed'>
  hallId: Id | null
  eventDate: IsoDate
  postedAt: IsoDateTime
  ownerReply: OwnerReply | null
  /** Hotel side: the reply the manager has staged in the composer but not yet sent; never shown to couples. */
  replyDraft: Bilingual | null
  /** Hotel side: a review waits for a reply once it is 7+ days old without one. */
  verifiedBooking: boolean
  /** Photos in reviews are empty-room only and stay in moderation until approved (ADR 0015 D7). */
  photos: string[]
}

// ---------------------------------------------------------------- saved and compare

export interface SavedItem {
  type: 'venue' | 'vendor' | 'package'
  id: Id
  savedAt: IsoDateTime
  /** Last price seen, to drive 'Price dropped' (a real price from the last 28 days). */
  lastSeenPrice: Money | null
}

export interface ClientState {
  userId: Id
  saved: SavedItem[]
  compareVenueIds: Id[]
  /** Recently viewed, newest first (feeds 'Recommended for you', rules-based). */
  recentlyViewedVenueIds: Id[]
}
