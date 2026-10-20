// Labels and applied chips of the Discover filters. One place turns a Filters value into the words people read (the removable chips of
// Results, the summary lines of the Filters sheet), so the two can never disagree. Words come from client-discover; numbers, money and dates
// come from the shared formatter. Nothing here is typed by hand into a message.
// ADR 0034 (text diet): a chip is a glyph and one short value (`[car] 30 min`, `[users] 200 – 500`, `[star] 4.5+`), never a sentence;
// the glyph is part of the chip model (`icon`) so Results and the Filters sheet draw the same chip.
import type { IconName } from '@gz/tokens'
import * as mock from '../../../../mock'
import type { Audience, HallSetting, LuxuryLevel, VenueType } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { brandOf, NO_FILTERS, shelfIds, type CategoryId, type FacilityKey, type Filters, type SearchBrief, type ShelfId } from './data'

export const ARRANGEMENTS: readonly Audience[] = ['women', 'men', 'mixed']
export const SETTINGS: readonly HallSetting[] = ['indoor', 'outdoor', 'mixed']
export const FACILITIES: readonly FacilityKey[] = ['parking', 'valet', 'bridal', 'buffet', 'decor', 'photography']
export const LEVELS: readonly LuxuryLevel[] = ['prestige', 'signature', 'classic', 'government']
export const RATINGS: readonly number[] = [3.5, 4, 4.5]
export const DISTANCES: readonly number[] = [15, 30, 45]
export const SORTS = ['recommended', 'voucher_price', 'rating', 'newest', 'price', 'price-desc', 'distance'] as const
export const VENUE_TYPES: readonly VenueType[] = ['private-hall', 'governmental', 'hotel']
export type SortKey = (typeof SORTS)[number]

export const ARRANGEMENT_ICON: Record<Audience, IconName> = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' }
export const SETTING_ICON: Record<HallSetting, IconName> = { indoor: 'hall', outdoor: 'garden', mixed: 'venue' }
export const FACILITY_ICON: Record<FacilityKey, IconName> = { parking: 'parking', valet: 'valet', bridal: 'makeup', buffet: 'buffet', decor: 'decor', photography: 'camera' }
export const TYPE_ICON: Record<VenueType, IconName> = { 'private-hall': 'hall', governmental: 'bank', hotel: 'hotel' }
export const LEVEL_ICON: Record<LuxuryLevel, IconName> = { prestige: 'crown', signature: 'sparkle', classic: 'star', government: 'bank' }

const ARRANGEMENT_KEY = { women: 'clientDiscoverArrangementWomen', men: 'clientDiscoverArrangementMen', mixed: 'clientDiscoverArrangementMixed' } as const
const SETTING_KEY = { indoor: 'clientDiscoverSettingIndoor', outdoor: 'clientDiscoverSettingOutdoor', mixed: 'clientDiscoverSettingMixed' } as const
const FACILITY_KEY = {
  parking: 'clientDiscoverFacilityParking',
  valet: 'clientDiscoverFacilityValet',
  bridal: 'clientDiscoverFacilityBridal',
  buffet: 'clientDiscoverFacilityBuffet',
  decor: 'clientDiscoverFacilityDecor',
  photography: 'clientDiscoverFacilityPhotography',
} as const
const LEVEL_KEY = {
  prestige: 'clientDiscoverLevelPrestige',
  signature: 'clientDiscoverLevelSignature',
  classic: 'clientDiscoverLevelClassic',
  government: 'clientDiscoverLevelGovernment',
} as const
const CATEGORY_KEY: Record<CategoryId, 'clientDiscoverCategoryLuxuryHotels' | 'clientDiscoverCategoryWeddingHalls' | 'clientDiscoverCategoryGovernment' | 'clientDiscoverCategoryBeach' | 'clientDiscoverCategoryOutdoor' | 'clientDiscoverCategoryVip'> = {
  'luxury-hotels': 'clientDiscoverCategoryLuxuryHotels',
  'wedding-halls': 'clientDiscoverCategoryWeddingHalls',
  government: 'clientDiscoverCategoryGovernment',
  beach: 'clientDiscoverCategoryBeach',
  outdoor: 'clientDiscoverCategoryOutdoor',
  vip: 'clientDiscoverCategoryVip',
}
const TYPE_KEY = { 'private-hall': 'commonVenueTypePrivateHall', governmental: 'commonVenueTypeGovernmental', hotel: 'commonVenueTypeHotel' } as const
const SORT_KEY = {
  recommended: 'clientDiscoverSortRecommended',
  voucher_price: 'clientDiscoverSortVoucher',
  rating: 'clientDiscoverSortRating',
  newest: 'clientDiscoverSortNewest',
  price: 'clientDiscoverSortPrice',
  'price-desc': 'clientDiscoverSortPriceDesc',
  distance: 'clientDiscoverSortDistance',
} as const

/** `Thu 14 Jan` / `14 يناير`: the short day of a shelf title or a chip (the year is the Brief's, stated in the sentence). Arabic drops the weekday: the title must hold one line beside "See all". */
export function useDayLabel() {
  const f = useFormat()
  const { lang } = useLang()
  return (iso: string): string => {
    const c = f.civil(iso)
    const dm = `${f.integer(c.day)} ${f.monthName(c.month, 'short')}`
    return lang === 'ar' ? dm : `${f.weekdayName(c.weekday, 'short')} ${dm}`
  }
}

export function useLabels() {
  const t = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const { lang } = useLang()
  const areaName = (id: string) => mock.getArea(id)?.name[lang] ?? ''
  return {
    arrangement: (a: Audience) => t(ARRANGEMENT_KEY[a]),
    setting: (s: HallSetting) => t(SETTING_KEY[s]),
    facility: (k: FacilityKey) => t(FACILITY_KEY[k]),
    level: (l: LuxuryLevel) => t(LEVEL_KEY[l]),
    category: (id: CategoryId) => t(CATEGORY_KEY[id]),
    sort: (s: SortKey) => t(SORT_KEY[s]),
    venueType: (v: VenueType) => c(TYPE_KEY[v]),
    governorate: (id: string) => mock.getGovernorate(id)?.name[lang] ?? '',
    governorates: (ids: readonly string[]) => f.list(ids.map(id => mock.getGovernorate(id)?.name[lang] ?? '').filter(Boolean), 'and'),
    structure: (v: 'per_person' | 'package') => c(v === 'per_person' ? 'commonPricingPerPerson' : 'commonPricingPackages'),
    capacity: (lo: number, hi: number) => f.numberRange(lo, hi),
    area: areaName,
    areas: (ids: readonly string[]) => f.list(ids.map(areaName).filter(Boolean), 'and'),
    brand: (b: string) => {
      const v = mock.venues.find(x => brandOf(x)?.en === b)
      const br = v ? brandOf(v) : null
      return br ? br[lang] : b
    },
    within: (minutes: number) => t('clientDiscoverMinutes', { minutes: f.integer(minutes) }),
    priceRange: (lo: number, hi: number) => f.moneyRange(lo * 1000, hi * 1000, { mode: 'browse' }),
    voucherRange: (lo: number, hi: number) => f.moneyRange(lo * 1000, hi * 1000, { mode: 'browse' }),
    rating: (r: number) => f.number(r, { minFraction: 1, maxFraction: 1 }),
  }
}

export type Chip = {
  id: string
  /** The glyph that says what kind of filter this is (the label is a value). */
  icon?: IconName
  label: string
  /** The filters with this chip removed. */
  remove: (f: Filters) => Filters
}

const SHELF_TITLE: Record<ShelfId, 'clientDiscoverFreeTitle' | 'clientDiscoverFeaturedTitle' | 'clientDiscoverVoucherTitle' | 'clientDiscoverWeekTitle' | 'clientDiscoverRecommendedTitle' | 'clientDiscoverTrendingTitle' | 'clientDiscoverNearbyTitle'> = {
  free: 'clientDiscoverFreeTitle',
  featured: 'clientDiscoverFeaturedTitle',
  voucher: 'clientDiscoverVoucherTitle',
  week: 'clientDiscoverWeekTitle',
  recommended: 'clientDiscoverRecommendedTitle',
  trending: 'clientDiscoverTrendingTitle',
  nearby: 'clientDiscoverNearbyTitle',
}

/** The removable chips for the applied filters, in the order people decided them. The Brief itself is the echo above, not a chip. */
export function useAppliedChips(filters: Filters, brief: SearchBrief): Chip[] {
  const t = useT('client-discover')
  const L = useLabels()
  const dayLabel = useDayLabel()
  const out: Chip[] = []
  const date = brief.date ? dayLabel(brief.date) : ''
  if (filters.shelf) {
    const key = SHELF_TITLE[filters.shelf]
    out.push({ id: 'shelf', label: key === 'clientDiscoverFreeTitle' ? t(key, { date }) : t(key), remove: x => ({ ...x, shelf: null }) })
  }
  if (filters.category) out.push({ id: 'category', label: L.category(filters.category), remove: x => ({ ...x, category: null }) })
  if (filters.governorateIds.length) out.push({ id: 'governorates', icon: 'pin', label: L.governorates(filters.governorateIds), remove: x => ({ ...x, governorateIds: [] }) })
  if (filters.areaIds !== null) {
    out.push({
      id: 'areas',
      icon: 'pin',
      label: filters.areaIds.length ? L.areas(filters.areaIds) : t('clientDiscoverChipAreasAll'),
      remove: x => ({ ...x, areaIds: null }),
    })
  }
  for (const v of filters.types) out.push({ id: `type-${v}`, icon: TYPE_ICON[v], label: L.venueType(v), remove: x => ({ ...x, types: x.types.filter(y => y !== v) }) })
  if (filters.available && brief.date && !filters.dates) out.push({ id: 'available', icon: 'calendar-check', label: dayLabel(brief.date), remove: x => ({ ...x, available: false }) })
  if (filters.dates) {
    const { from, to } = filters.dates
    out.push({ id: 'dates', icon: 'calendar-check', label: from === to ? dayLabel(from) : `${dayLabel(from)} – ${dayLabel(to)}`, remove: x => ({ ...x, dates: null }) })
  }
  if (filters.arrangement) out.push({ id: 'arrangement', icon: ARRANGEMENT_ICON[filters.arrangement], label: L.arrangement(filters.arrangement), remove: x => ({ ...x, arrangement: null }) })
  if (filters.withinMinutes !== null) out.push({ id: 'within', icon: 'car', label: L.within(filters.withinMinutes), remove: x => ({ ...x, withinMinutes: null }) })
  if (filters.capacity) out.push({ id: 'capacity', icon: 'users-three', label: L.capacity(filters.capacity[0], filters.capacity[1]), remove: x => ({ ...x, capacity: null }) })
  if (filters.structure) out.push({ id: 'structure', icon: filters.structure === 'package' ? 'package' : 'per-guest', label: L.structure(filters.structure), remove: x => ({ ...x, structure: null }) })
  if (filters.voucherOnly) out.push({ id: 'voucher', icon: 'ticket', label: t('clientDiscoverChipVoucher'), remove: x => ({ ...x, voucherOnly: false }) })
  if (filters.voucherPrice) out.push({ id: 'voucher-price', icon: 'ticket', label: L.voucherRange(filters.voucherPrice[0], filters.voucherPrice[1]), remove: x => ({ ...x, voucherPrice: null }) })
  if (filters.price) out.push({ id: 'price', icon: 'per-guest', label: L.priceRange(filters.price[0], filters.price[1]), remove: x => ({ ...x, price: null }) })
  for (const s of filters.settings) out.push({ id: `setting-${s}`, icon: SETTING_ICON[s], label: L.setting(s), remove: x => ({ ...x, settings: x.settings.filter(v => v !== s) }) })
  for (const k of filters.facilities) out.push({ id: `facility-${k}`, icon: FACILITY_ICON[k], label: L.facility(k), remove: x => ({ ...x, facilities: x.facilities.filter(v => v !== k) }) })
  if (filters.minRating !== null) out.push({ id: 'rating', icon: 'star', label: t('clientDiscoverChipRating', { rating: L.rating(filters.minRating) }), remove: x => ({ ...x, minRating: null }) })
  for (const l of filters.levels) out.push({ id: `level-${l}`, icon: LEVEL_ICON[l], label: L.level(l), remove: x => ({ ...x, levels: x.levels.filter(v => v !== l) }) })
  for (const b of filters.brands) out.push({ id: `brand-${b}`, label: L.brand(b), remove: x => ({ ...x, brands: x.brands.filter(v => v !== b) }) })
  return out
}

/** `Clear all` keeps the date availability default (it is the Brief speaking), so the list never silently shows booked halls. */
export const clearedFilters = (brief: SearchBrief): Filters => ({ ...NO_FILTERS, available: Boolean(brief.date) })

export { shelfIds }
