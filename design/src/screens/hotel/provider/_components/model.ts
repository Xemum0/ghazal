// Flow model of the provider and listings screens (HL-PROV-01..07): who the viewer is, which listings are theirs, what each listing's next
// step is, and the illustrative sample rates the prototype may show in ONE labelled state. Everything real comes from the shared fixtures
// (design/src/mock); money stays integer fils.
import { iconNames, type IconName } from '@gz/tokens'
import { clock, engine, getProvider, meta, partnerFor, personaFor, serviceCategories } from '../../../../mock'
import type { AdPlanCycle, Bilingual, Listing, ListingStatus, ProviderPackage, ServiceCategoryId } from '../../../../mock'

// ---------------------------------------------------------------- the viewer

/** `provider` = a service-provider account (Listings in the slot of Calendar); `hotel` = a hotel or hall that also lists; `major` = a fee-exempt major hotel. */
export type AccountKind = 'provider' | 'hotel' | 'major'

export type Account = {
  kind: AccountKind
  exempt: boolean
  accountId: string
  providerId: string
  name: Bilingual
}

const PROVIDER = personaFor('service_provider')
const HOTEL = personaFor('hotel_non_major')
const MAJOR = personaFor('hotel')

export const PROVIDER_ACCOUNT_ID = PROVIDER?.partnerAccountId ?? 'partner-vendor-flowers-zahra'
export const PROVIDER_ID = partnerFor(PROVIDER_ACCOUNT_ID)?.providerId ?? 'vendor-flowers-zahra'

export function accountOf(kind: AccountKind): Account {
  const id = kind === 'provider' ? PROVIDER_ACCOUNT_ID : kind === 'hotel' ? (HOTEL?.partnerAccountId ?? 'partner-V05') : (MAJOR?.partnerAccountId ?? 'partner-V01')
  const a = partnerFor(id)
  return {
    kind,
    exempt: kind === 'major' || a?.feeExempt === true,
    accountId: id,
    providerId: PROVIDER_ID,
    name: a?.name ?? { en: 'Zahra Floral Studio', ar: 'استوديو زهرة للزهور' },
  }
}

export const isAccountKind = (v: unknown): v is AccountKind => v === 'provider' || v === 'hotel' || v === 'major'

// ---------------------------------------------------------------- lifecycle

export const FEE_FILS = meta.config.voucherFeeFils
export const RETENTION_DAYS = meta.config.listingRejectedRetentionDays
/** The banner shows at -7 days (PA-ADS-05). */
export const EXPIRY_WARN_DAYS = 7
/** After 48 hours in review the status screen adds a way to reach support (PA-REV-02). */
export const LONG_WAIT_HOURS = 48

export const today = (): string => clock.today()

export const daysLeft = (endsOn: string | null): number | null => (endsOn ? engine.diffDays(today(), endsOn) : null)

export const isExpiring = (l: Pick<Listing, 'status' | 'endsOn'>): boolean => {
  const d = daysLeft(l.endsOn)
  return l.status === 'active' && d !== null && d >= 0 && d <= EXPIRY_WARN_DAYS
}

export type NextStep =
  | { id: 'finish' | 'choose-plan' | 'fix' | 'renew' | 'submit'; to: 'HL-PROV-03' | 'HL-PROV-04'; params: Record<string, unknown> }
  | null

const hasPackages = (l: Pick<Listing, 'packageIds'>): boolean => l.packageIds.length > 0

/** What the card's action says and where it goes (HL-PROV-02 interactions). */
export function nextStepOf(l: Listing, exempt: boolean): NextStep {
  const params = { listingId: l.id }
  switch (l.status) {
    case 'draft':
      if (!hasPackages(l)) return { id: 'finish', to: 'HL-PROV-03', params }
      return exempt ? { id: 'submit', to: 'HL-PROV-04', params } : { id: 'choose-plan', to: 'HL-PROV-04', params }
    case 'payment_pending':
      return { id: 'choose-plan', to: 'HL-PROV-04', params }
    case 'rejected':
      return { id: 'fix', to: 'HL-PROV-03', params }
    case 'expired':
      return { id: 'renew', to: 'HL-PROV-04', params: { ...params, renewal: true } }
    case 'active':
      return isExpiring(l) ? { id: 'renew', to: 'HL-PROV-04', params: { ...params, renewal: true } } : null
    default:
      return null
  }
}

/** Where a tap on the card goes (HL-PROV-02 interactions). */
export function openTarget(l: Listing): { to: 'HL-PROV-03' | 'HL-PROV-06' | 'HL-PROV-07'; params: Record<string, unknown> } {
  const params = { listingId: l.id }
  switch (l.status) {
    case 'draft':
    case 'payment_pending':
      return { to: 'HL-PROV-03', params }
    case 'active':
    case 'expired':
    case 'paused':
      return { to: 'HL-PROV-07', params }
    default:
      return { to: 'HL-PROV-06', params }
  }
}

const RANK: Record<ListingStatus, number> = { rejected: 0, draft: 1, payment_pending: 1, expired: 2, active: 3, pending_review: 4, approved: 4, paused: 5 }

export type Group = 'attention' | 'running' | 'ended'

/** Needs-you first, then what is running or waiting, then what ended. */
export function groupOf(l: Listing): Group {
  if (l.status === 'rejected' || l.status === 'draft' || l.status === 'payment_pending' || isExpiring(l)) return 'attention'
  if (l.status === 'expired' || l.status === 'paused') return 'ended'
  return 'running'
}

export const sortListings = (list: readonly Listing[]): Listing[] =>
  [...list].sort((a, b) => (isExpiring(b) ? 1 : 0) - (isExpiring(a) ? 1 : 0) || RANK[a.status] - RANK[b.status] || (b.submittedAt ?? '').localeCompare(a.submittedAt ?? ''))

// ---------------------------------------------------------------- categories

export type CategoryOption = { id: ServiceCategoryId; name: Bilingual; icon: string; primary: boolean }

/** The five primary categories first, then the rest (CL-SERV-01 order). */
export const categoryOptions = (): CategoryOption[] =>
  [...serviceCategories]
    .sort((a, b) => Number(b.primary) - Number(a.primary) || a.order - b.order)
    .map(c => ({ id: c.id, name: c.name, icon: c.icon, primary: c.primary }))

export const categoryName = (id: ServiceCategoryId): Bilingual | undefined => serviceCategories.find(c => c.id === id)?.name

// ---------------------------------------------------------------- packages of a listing

export const packagesOf = (l: Pick<Listing, 'providerId' | 'packageIds'>): ProviderPackage[] => {
  const p = getProvider(l.providerId)
  return p ? p.packages.filter(k => l.packageIds.includes(k.id)) : []
}

// ---------------------------------------------------------------- sample rates (prototype only)

/**
 * NOT-FOR-RELEASE SAMPLE. The real rates are an owner decision (OQ-V-07) and are null in the fixtures; every surface says "Rates announced
 * soon". The prototype's `rates-set-sample` state needs some amounts to show the payable layout, so they live here, in one labelled place,
 * and every screen that shows them also shows a "Sample" mark. A fixtures request (`sampleRates`) is filed in docs/engineering/requests.md.
 */
export const SAMPLE_RATES_FILS: Record<AdPlanCycle, number> = { weekly: 5000, monthly: 15000, annual: 120000 }
export const SAMPLE_PERIOD_DAYS: Record<AdPlanCycle, number> = { weekly: 7, monthly: 30, annual: 365 }

export const CYCLES: readonly AdPlanCycle[] = ['weekly', 'monthly', 'annual']

// ---------------------------------------------------------------- which listing a screen is about

/** The listing named by the route, else the first one that still needs a plan (the demo story), else the live one. */
export function pickListing(list: readonly Listing[], id: unknown, prefer: readonly ListingStatus[]): Listing | undefined {
  if (typeof id === 'string') {
    const hit = list.find(l => l.id === id)
    if (hit) return hit
  }
  for (const s of prefer) {
    const hit = list.find(l => l.status === s)
    if (hit) return hit
  }
  return list[0]
}

/** A category's icon when the registry has it; five secondary categories name glyphs the registry lacks (requests.md), so they fall back. */
export const categoryIcon = (name: string): IconName => ((iconNames as readonly string[]).includes(name) ? (name as IconName) : 'sparkle')
