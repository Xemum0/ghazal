// Services flow model (CL-SERV-01..04, voucher model ADR 0033): the five primary categories and the secondary groups, filtering and
// sorting of a provider list (approved, active listings only), the voucher quote of a package, the budget category a service lands in,
// and the small in-memory store the four screens share (list filters, enquiries sent in this session).
// Everything shown comes from the fixtures (design/src/mock); nothing here is a display string.
import { create } from 'zustand'
import type { IconName } from '@gz/tokens'
import {
  activeListingOf, conversations, governorates, meta, primaryCategories, quoteForProvider, secondaryCategories, serviceCategories, serviceGroups,
  vendorQuoteRequest, vendors, vendorsFor,
  type ProviderPackage, type Quote, type ServiceCategory, type ServiceCategoryId, type ServiceGroup, type Vendor, type Voucher,
} from '../../../../mock'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'

// ---------------------------------------------------------------- categories
export const CATEGORIES: readonly ServiceCategory[] = [...serviceCategories].sort((a, b) => a.order - b.order)
/** The five Additional services categories, in the owner's order (CA-SVC-13). */
export const PRIMARY: readonly ServiceCategory[] = primaryCategories()
/** "More services" (CA-SVC-16): the secondary categories, after the five. */
export const SECONDARY: readonly ServiceCategory[] = secondaryCategories()

export const categoryOf = (id: string | undefined): ServiceCategory | undefined => CATEGORIES.find(c => c.id === id)

/** The registry glyph of a category (the fixtures' own `icon` names are not all in the registry). */
export const ICON_OF: Record<ServiceCategoryId, IconName> = {
  catering: 'drinks',
  buffet: 'buffet',
  flowers: 'flower',
  decor: 'decor',
  event_planning: 'calendar-check',
  photography: 'camera',
  videography: 'video',
  cake: 'cake',
  dj: 'dj',
  mc: 'mic',
  live_music: 'music',
  henna: 'sparkle',
  bridal_makeup: 'makeup',
  wedding_dress: 'dress',
  suit_rental: 'suit',
  luxury_cars: 'car',
  invitations: 'mail',
  travel: 'travel',
  honeymoon: 'beach',
}

/** The drawing of a "More services" group (the illustration catalogue has one for each). */
export const GROUP_ART: Record<string, 'cake' | 'camera' | 'oud' | 'palette' | 'dress' | 'car' | 'suitcase'> = {
  flowers_cake: 'cake',
  photo_video: 'camera',
  music: 'oud',
  henna_makeup: 'palette',
  attire: 'dress',
  cars_invitations: 'car',
  travel: 'suitcase',
}

/** The unit a price of a category is quoted in. Per-guest prices carry the glyph; the rest carry one quiet word (message key suffix). */
export type UnitKind = 'guest' | 'event' | 'cake' | 'session' | 'dress' | 'suit' | 'card' | 'booking' | 'package'
const UNIT_OF: Partial<Record<ServiceCategoryId, UnitKind>> = {
  catering: 'guest',
  buffet: 'guest',
  cake: 'cake',
  henna: 'session',
  bridal_makeup: 'session',
  wedding_dress: 'dress',
  suit_rental: 'suit',
  invitations: 'card',
  travel: 'booking',
  honeymoon: 'package',
}
export const unitOf = (categoryId: ServiceCategoryId): UnitKind => UNIT_OF[categoryId] ?? 'event'

/** The categories a list shows as sibling chips: the five primaries together, or the secondaries of the same group. */
export const siblingsOf = (id: ServiceCategoryId): ServiceCategory[] => {
  const c = categoryOf(id)
  if (!c) return []
  return c.primary ? [...PRIMARY] : SECONDARY.filter(x => x.groupId === c.groupId)
}

/** One row of "More services": a group of secondary categories, or a lone category (cake) that is named by itself. */
export type SecondaryRow = { id: string; group: ServiceGroup | undefined; leaves: ServiceCategory[] }
export const SECONDARY_ROWS: readonly SecondaryRow[] = (() => {
  const groups = [...serviceGroups].sort((a, b) => a.order - b.order)
  return groups.flatMap(g => {
    const leaves = SECONDARY.filter(c => c.groupId === g.id)
    return leaves.length > 0 ? [{ id: g.id, group: g, leaves }] : []
  })
})()

/** Approved, active providers of a category (only these ever reach a client list: CA-SVC-17). */
export const providerCount = (categoryId: string): number => vendorsFor(categoryId).length
/** A paid placement (the listing's plan), labelled "Sponsored" to clients. */
export const isSponsored = (v: Vendor): boolean => activeListingOf(v.id)?.sponsored === true

export const DEFAULT_CATEGORY: ServiceCategoryId = 'photography'
/** The voucher fee (KD 2), a Super Admin configuration value: read from the platform config, never typed. */
export const VOUCHER_FEE_FILS = meta.config.voucherFeeFils
export const DEFAULT_VENDOR_ID = vendorQuoteRequest.vendorId
/** The vendor thread the fixtures already hold for this vendor (Lamha's, from the story), if any. */
export const conversationOf = (vendorId: string): string | undefined => conversations.find(c => c.vendorId === vendorId)?.id
export const vendorOf = (id: string | undefined): Vendor | undefined => vendors.find(v => v.id === id)

/** Budget category (CL-WEDD-04 ids) a service category is planned under. */
const BUDGET_OF: Record<ServiceCategoryId, string> = {
  catering: 'venue_catering',
  buffet: 'venue_catering',
  event_planning: 'flowers_decor', // no planning line in the budget fixtures yet (requests.md)
  decor: 'flowers_decor',
  photography: 'photo_video',
  videography: 'photo_video',
  flowers: 'flowers_decor',
  cake: 'flowers_decor',
  dj: 'music',
  mc: 'music',
  live_music: 'music',
  henna: 'makeup_henna',
  bridal_makeup: 'makeup_henna',
  wedding_dress: 'attire',
  suit_rental: 'attire',
  luxury_cars: 'cars',
  invitations: 'invitations',
  travel: 'honeymoon',
  honeymoon: 'honeymoon',
}
export const budgetCategoryOf = (id: ServiceCategoryId): string => BUDGET_OF[id]

// ---------------------------------------------------------------- filters and sort
export type Sort = 'recommended' | 'price' | 'rating'
/** Region is the governorate only (ADR 0038, CA-FLT-08); an empty list = every governorate. */
export type Filters = { governorateIds: string[]; maxFils: number | null; minRating: number | null; sort: Sort }
export const NO_FILTERS: Filters = { governorateIds: [], maxFils: null, minRating: null, sort: 'recommended' }

export const MIN_RATINGS = [4.5, 4] as const

export const appliedCount = (f: Filters): number => (f.governorateIds.length > 0 ? 1 : 0) + (f.maxFils !== null ? 1 : 0) + (f.minRating !== null ? 1 : 0)

export function filterVendors(list: readonly Vendor[], f: Filters): Vendor[] {
  return list.filter(v => {
    if (f.governorateIds.length > 0 && !f.governorateIds.includes(v.governorateId)) return false
    if (f.maxFils !== null && v.from.fils > f.maxFils) return false
    if (f.minRating !== null && (v.rating === null || v.rating.average < f.minRating)) return false
    return true
  })
}

export function sortVendors(list: readonly Vendor[], sort: Sort): Vendor[] {
  const out = [...list]
  // Recommended: paid placements first (labelled), then the list order.
  if (sort === 'recommended') out.sort((a, b) => Number(isSponsored(b)) - Number(isSponsored(a)))
  if (sort === 'price') out.sort((a, b) => a.from.fils - b.from.fils)
  if (sort === 'rating') out.sort((a, b) => (b.rating?.average ?? -1) - (a.rating?.average ?? -1) || (b.rating?.count ?? 0) - (a.rating?.count ?? 0))
  return out
}

export const listFor = (categoryId: ServiceCategoryId, f: Filters): Vendor[] => sortVendors(filterVendors(vendorsFor(categoryId), f), f.sort)

/** The governorates the category's vendors work in (fixture order), the options of the shared GovernorateFilter. */
export function governorateOptions(categoryId: ServiceCategoryId): string[] {
  const seen = new Set(vendorsFor(categoryId).map(v => v.governorateId))
  return governorates.filter(g => seen.has(g.id)).map(g => g.id)
}

/** "Up to" price steps from the real starting prices of the category: every distinct price but the highest, at most three. */
export function priceSteps(categoryId: ServiceCategoryId): number[] {
  const distinct = [...new Set(vendorsFor(categoryId).map(v => v.from.fils))].sort((a, b) => a - b)
  return distinct.slice(0, -1).slice(0, 3)
}

// ---------------------------------------------------------------- the voucher quote of a package
/** Units a package is quoted for: guests for a per-person package (at least its minimum), else the whole package. */
export function quantityFor(pkg: ProviderPackage, guests: number | null): number {
  if (pkg.priceStructure !== 'per_person') return pkg.minQuantity ?? 1
  return Math.max(guests ?? pkg.minQuantity ?? 1, pkg.minQuantity ?? 1)
}

/** The standard and voucher quote of a package, or null when the engine has none. */
export function quoteOf(vendor: Vendor, pkg: ProviderPackage, guests: number | null): Quote | null {
  try {
    return quoteForProvider({ providerId: vendor.id, packageId: pkg.id, qty: quantityFor(pkg, guests) })
  } catch {
    return null
  }
}

/**
 * A voucher is offered only when the saving beats the fee (CA-VCH-10); otherwise the screen says nothing about vouchers. The test runs on
 * the unit saving times the quantity, exactly as the engine does.
 */
export const voucherOffered = (vendor: Vendor, pkg: ProviderPackage, guests: number | null): boolean =>
  pkg.voucherPrice !== null && (quoteOf(vendor, pkg, guests)?.voucherEligible ?? false)

/** The cheapest voucher offer of a provider for the list card (unit price, same basis as `from`), if any package is voucher-eligible. */
export const fromVoucherOf = (v: Vendor): number | null => (v.fromVoucher !== null && v.fromVoucher.fils < v.from.fils ? v.fromVoucher.fils : null)

/** A ready voucher (paid, not in a request) the client holds for this provider; it can be attached to an enquiry. */
export function readyVoucherOf(vouchers: readonly Voucher[], vendorId: string, clientId: string | undefined): Voucher | undefined {
  return vouchers.find(v => v.targetType === 'provider' && v.venueOrProviderId === vendorId && v.status === 'active' && (!clientId || v.clientId === clientId))
}

// ---------------------------------------------------------------- the flow store
export type SentQuote = {
  vendorId: string
  packageId: string
  eventDate: string | null
  venueId: string | null
  guests: number | null
  note: string
  sentAt: string
  /** The voucher attached to the enquiry (it became a request at the voucher price), else null. */
  voucherId: string | null
  /** The request created in the store when a voucher was attached. */
  bookingId: string | null
}

type ServicesFlow = {
  filters: Record<string, Filters>
  quotes: Record<string, SentQuote>
  setFilters: (categoryId: string, patch: Partial<Filters>) => void
  clearFilters: (categoryId: string) => void
  addQuote: (q: SentQuote) => void
}

export const useServicesFlow = create<ServicesFlow>()(set => ({
  filters: {},
  quotes: {},
  setFilters: (categoryId, patch) => set(s => ({ filters: { ...s.filters, [categoryId]: { ...NO_FILTERS, ...s.filters[categoryId], ...patch } } })),
  clearFilters: categoryId => set(s => ({ filters: { ...s.filters, [categoryId]: { ...NO_FILTERS, sort: s.filters[categoryId]?.sort ?? 'recommended' } } })),
  addQuote: q => set(s => ({ quotes: { ...s.quotes, [q.vendorId]: q } })),
}))

export const useFilters = (categoryId: string): Filters => useServicesFlow(s => s.filters[categoryId]) ?? NO_FILTERS

// ---------------------------------------------------------------- live or static
/** True in the player: taps navigate. A static frame (canvas, shots) draws the same screen with inert actions. */
export const useLive = (): boolean => useDevice().mode === 'live'

/** The prefill of a quote request: the Brief and the draft of this session, or the story's own request in a static frame. */
export function quotePrefill(live: boolean): { eventDate: string | null; venueId: string | null; guests: number | null } {
  if (!live) return { eventDate: vendorQuoteRequest.eventDate, venueId: vendorQuoteRequest.venueId, guests: vendorQuoteRequest.guests }
  const s = usePrototype.getState()
  return { eventDate: s.searchBrief.date ?? s.weddingProfile?.weddingDate ?? null, venueId: s.bookingDraft.venueId, guests: s.searchBrief.guests ?? null }
}

// A session ends when the prototype signs out (or Restart in the launcher): requests and filters go with it.
usePrototype.subscribe((state, prev) => {
  if (state.auth !== 'signedIn' && prev.auth === 'signedIn') useServicesFlow.setState({ filters: {}, quotes: {} })
})
