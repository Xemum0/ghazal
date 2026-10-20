import type { Bilingual, Id, ImageRef, IsoDate, IsoDateTime, Money } from './common.ts'
import type { PriceStructure } from './pricing.ts'
import type { ThreadMember } from './visit.ts'

// ---------------------------------------------------------------- additional services (voucher model: service providers)

export type ServiceGroupId =
  | 'hospitality'
  | 'flowers_cake'
  | 'planning'
  | 'photo_video'
  | 'music'
  | 'henna_makeup'
  | 'attire'
  | 'cars_invitations'
  | 'travel'

export interface ServiceGroup {
  id: ServiceGroupId
  name: Bilingual
  order: number
}

/**
 * Five primary categories of the "Additional services" section (owner list, in this order): catering, buffet, flowers, decor,
 * event_planning. Everything else is secondary and shows after them under "More services". Categories render from data.
 */
export type ServiceCategoryId =
  | 'catering'
  | 'buffet'
  | 'flowers'
  | 'decor'
  | 'event_planning'
  | 'photography'
  | 'videography'
  | 'cake'
  | 'dj'
  | 'mc'
  | 'live_music'
  | 'henna'
  | 'bridal_makeup'
  | 'wedding_dress'
  | 'suit_rental'
  | 'luxury_cars'
  | 'invitations'
  | 'travel'
  | 'honeymoon'

export interface ServiceCategory {
  id: ServiceCategoryId
  groupId: ServiceGroupId
  /** One of the five primary Additional services categories. */
  primary: boolean
  name: Bilingual
  description: Bilingual
  icon: string
  image: ImageRef
  /** Price anchor of the category (research 8.6); the unit is always stated. */
  anchor: { min: Money; max: Money; unit: Bilingual }
  order: number
}

/** A provider package with two prices on the same basis, like a venue package (voucher-model section 6). */
export interface ProviderPackage {
  id: Id
  name: Bilingual
  /** Standard price: what the client pays the provider without a voucher. */
  price: Money
  /** Voucher price on the same unit; null = no voucher price (not voucher-eligible). */
  voucherPrice: Money | null
  /** Unit of the price: per guest, per event, per card. */
  unit: Bilingual
  priceStructure: PriceStructure
  /** Minimum guests or units for a per-person package. */
  minQuantity: number | null
  includes: Bilingual[]
}

export interface ServiceProvider {
  id: Id
  categoryId: ServiceCategoryId
  /** Extra categories a provider also serves (a photography studio that also films). */
  alsoCategoryIds: ServiceCategoryId[]
  name: Bilingual
  monogram: string
  areaId: Id
  /** Governorate of the area, denormalised for the region filter. */
  governorateId: Id
  /** Partner account that runs the provider (`partner-<provider id>`). */
  partnerAccountId: Id
  about: Bilingual
  /** null rating = new provider, shown as 'New' / 'جديد'. */
  rating: { average: number; count: number } | null
  /** Lowest standard price among the packages. */
  from: Money
  /** Lowest voucher price among the packages; null when no package has a voucher price. */
  fromVoucher: Money | null
  fromUnit: Bilingual
  packages: ProviderPackage[]
  portfolio: ImageRef[]
  tags: Bilingual[]
  /** Plain fact: female photographers / artists available for ladies' halls. */
  femaleTeamForLadies: boolean
  usuallyRepliesHours: number
  verified: boolean
  /** Contact phone shown on the profile (display-only fixture number). */
  phone: string
}

/** @deprecated Pre-voucher names, kept so screens keep compiling while they migrate: use ServiceProvider and ProviderPackage. */
export type Vendor = ServiceProvider
/** @deprecated Use ProviderPackage. */
export type VendorPackage = ProviderPackage

// ---------------------------------------------------------------- wedding planners

export type PlannerTier = 'silver' | 'gold' | 'royal'

export interface PlannerPackage {
  id: Id
  tier: PlannerTier
  name: Bilingual
  tagline: Bilingual
  /** One, two or three thread marks signal the tier; never metallic colour coding. */
  marks: 1 | 2 | 3
  from: Money
  inclusions: Bilingual[]
  suits: Bilingual
  image: ImageRef
}

export interface Planner {
  id: Id
  userId: Id
  name: Bilingual
  role: Bilingual
  monogram: string
  tiers: PlannerTier[]
  languages: ('ar' | 'en')[]
  about: Bilingual
  yearsExperience: number
}

export interface TimeWindow {
  date: IsoDate
  part: 'morning' | 'afternoon' | 'evening'
}

export interface PlannerRequest {
  id: Id
  clientId: Id
  tier: PlannerTier
  venueId: Id | null
  eventDate: IsoDate
  windows: TimeWindow[]
  note: string
  requestedAt: IsoDateTime
  status: 'requested' | 'assigned' | 'meeting_scheduled'
  plannerId: Id | null
  assignedAt: IsoDateTime | null
  meeting: { at: IsoDateTime; durationMin: number; channel: 'video_call' } | null
  slots: { date: IsoDate; times: string[] }[]
}

export interface VendorQuoteRequest {
  id: Id
  clientId: Id
  vendorId: Id
  vendorPackageId: Id
  eventDate: IsoDate
  venueId: Id | null
  guests: number | null
  note: string
  requestedAt: IsoDateTime
  status: 'sent' | 'replied'
}

// ---------------------------------------------------------------- chat

export type ConversationKind = 'venue' | 'planner' | 'vendor' | 'support' | 'enquiry' | 'visit_group'
export type MessageKind =
  | 'text'
  | 'voice'
  | 'document'
  | 'image'
  | 'meeting_card'
  | 'quote_request_card'
  | 'booking_card'
  | 'visit_card'
  | 'system'

/** In a visit group chat `venue` is the hotel representative and `support` the Ghazal support representative. */
export type MessageFrom = 'client' | 'venue' | 'planner' | 'vendor' | 'support' | 'system'

export interface Message {
  id: Id
  conversationId: Id
  from: MessageFrom
  /** Staff member or party shown as sender ('Handled by Hind Al-Enezi'). */
  senderName: string | null
  at: IsoDateTime
  kind: MessageKind
  /**
   * Message text in both languages for the prototype's convenience. `origin` is the language it was typed in;
   * a real chat shows the original text only (dialect belongs in typed chat, never in labels: ADR 0013).
   */
  text: Bilingual | null
  origin: 'ar' | 'en'
  voice?: { seconds: number }
  document?: { name: string; sizeKb: number; mime: 'application/pdf' }
  image?: { file: string; alt: Bilingual }
  card?: {
    kind: 'meeting' | 'quote_request' | 'booking' | 'visit' | 'voucher_offer'
    title: Bilingual
    lines: Bilingual[]
    at?: IsoDateTime
    refId?: Id
  }
  status: 'sent' | 'delivered' | 'read'
  /** A hotel-side draft that has not been sent: never visible to the client until the hotel sends it. */
  draft: boolean
}

export interface Conversation {
  id: Id
  kind: ConversationKind
  title: Bilingual
  /** Context line under the title ('Request · Thu 14 Jan'). */
  subtitle: Bilingual
  monogram: string
  /** Client user, or the prospective client for an enquiry. */
  clientId: Id | null
  clientName: string
  venueId: Id | null
  bookingId: Id | null
  plannerId: Id | null
  vendorId: Id | null
  pinned: boolean
  /** Unread counts per side. */
  unread: { client: number; hotel: number }
  /** Staff member who handled it (shared per-venue inbox). */
  handledBy: string | null
  lastMessageAt: IsoDateTime
  /** Venue-side flag: the couple wrote last and is waiting. */
  awaitingReplySince: IsoDateTime | null
  /** Typical reply time shown in the header, derived from data. */
  usuallyRepliesHours: number | null
  /** Visit group chat only: the visit this chat belongs to. */
  visitId?: Id | null
  /** Visit group chat only: exactly three members (client, hotel representative, Ghazal support representative). */
  members?: ThreadMember[]
  /** Visit group chat only: read-only from this instant (24 h after the slot, or at once on cancel or decline). */
  readOnlyFrom?: IsoDateTime | null
  /** Visit group chat only: archived 30 days after it went read-only. */
  archiveOn?: IsoDate | null
}

/** The dedicated three-way chat of one site visit (voucher-model section 11.2). */
export interface GroupThread extends Conversation {
  kind: 'visit_group'
  visitId: Id
  members: ThreadMember[]
}

export interface ConversationBundle {
  conversation: Conversation
  messages: Message[]
}
