// The provider flow's own state: which account type the viewer chose, the editor drafts saved per listing, plans chosen and paid, and edits of
// a LIVE listing that are waiting for review (A-09: the approved version stays live). Listing lifecycle itself (status, history, plan cycle)
// lives in the shared prototype store (selectors and submitListing / chooseListingPlan / moderateListing); this file only adds what that
// store does not hold yet (create, save an edit, record a payment). The requests for those actions are in docs/engineering/requests.md.
import { create } from 'zustand'
import { clock, engine } from '../../../../mock'
import type { AdPlanCycle, Bilingual, GatewayMethod, ImageRef, Listing, PriceStructure, ServiceCategoryId } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { PROVIDER_ACCOUNT_ID, PROVIDER_ID, packagesOf, type AccountKind } from './model'

// ---------------------------------------------------------------- editor draft

export type PackageDraft = {
  id: string
  nameAr: string
  nameEn: string
  structure: PriceStructure
  /** Integer fils; null while the field is empty. */
  standardFils: number | null
  voucherFils: number | null
  /** Inclusions as typed (each in the script it was typed in). */
  includes: string[]
}

export type ListingDraft = {
  categoryId: ServiceCategoryId | null
  titleAr: string
  titleEn: string
  descAr: string
  descEn: string
  photos: ImageRef[]
  packages: PackageDraft[]
  chat: boolean
  showPhone: boolean
}

export const EMPTY_DRAFT: ListingDraft = { categoryId: null, titleAr: '', titleEn: '', descAr: '', descEn: '', photos: [], packages: [], chat: true, showPhone: true }

const scriptOf = (text: string): 'ar' | 'en' => (/[؀-ۿݐ-ݿ]/.test(text) ? 'ar' : 'en')
export { scriptOf }

/** The editor's starting point for a saved listing: its text, its photos, and its packages as the provider fixture holds them. */
export function seedDraft(l: Listing): ListingDraft {
  return {
    categoryId: l.categoryId,
    titleAr: l.title.ar,
    titleEn: l.title.en,
    descAr: l.description.ar,
    descEn: l.description.en,
    photos: l.cover ? [l.cover] : [],
    packages: packagesOf(l).map(p => ({
      id: p.id,
      nameAr: p.name.ar,
      nameEn: p.name.en,
      structure: p.priceStructure,
      standardFils: p.price.fils,
      voucherFils: p.voucherPrice?.fils ?? null,
      includes: p.includes.map(i => i.en),
    })),
    chat: true,
    showPhone: true,
  }
}

export type Problems = { category?: boolean; titleAr?: boolean; titleEn?: boolean; descAr?: boolean; descEn?: boolean; packages?: boolean }

/** What stops a listing being sent for review (PA-LST-02): both languages, a category, at least one complete package. */
export function problemsOf(d: ListingDraft): Problems {
  const pkgOk = (p: PackageDraft) => p.nameAr.trim() !== '' && p.nameEn.trim() !== '' && p.standardFils !== null && p.standardFils > 0 && p.voucherFils !== null && p.voucherFils <= p.standardFils
  return {
    category: d.categoryId === null,
    titleAr: d.titleAr.trim() === '',
    titleEn: d.titleEn.trim() === '',
    descAr: d.descAr.trim() === '',
    descEn: d.descEn.trim() === '',
    packages: d.packages.length === 0 || !d.packages.every(pkgOk),
  }
}
export const hasProblems = (p: Problems): boolean => Object.values(p).some(Boolean)

// ---------------------------------------------------------------- the flow store

export type PaidPlan = { cycle: AdPlanCycle; fils: number; at: string; method: GatewayMethod; receiptNo: string }

type ProvState = {
  viewer: AccountKind
  setViewer: (k: AccountKind) => void
  /** Editor drafts saved per listing id (what "Save draft" wrote). */
  edits: Record<string, ListingDraft>
  /** Listing id -> when an edit of the live listing was sent; the approved version stays live meanwhile. */
  revisions: Record<string, string>
  /** Listing id -> the plan that was paid for (prototype sample amounts only). */
  paid: Record<string, PaidPlan>
  reset: () => void
}

const initial = () => ({ viewer: 'provider' as AccountKind, edits: {}, revisions: {}, paid: {} })

export const useProv = create<ProvState>(set => ({
  ...initial(),
  setViewer: viewer => set({ viewer }),
  reset: () => set(initial()),
}))

// ---------------------------------------------------------------- actions on the shared listings

const bi = (en: string, ar: string): Bilingual => ({ en, ar })

/** Creates a draft listing for the viewer's provider and returns its id. */
export function createListing(draft: ListingDraft): string {
  const listings = usePrototype.getState().listings
  const seq = listings.filter(l => l.id.startsWith('lst-proto-')).length + 1
  const id = `lst-proto-${seq}`
  const now = clock.now()
  const l: Listing = {
    id,
    providerId: PROVIDER_ID,
    partnerAccountId: PROVIDER_ACCOUNT_ID,
    feeRefund: null,
    categoryId: draft.categoryId ?? 'flowers',
    title: bi(draft.titleEn, draft.titleAr),
    description: bi(draft.descEn, draft.descAr),
    cover: draft.photos[0] ?? null,
    packageIds: [],
    status: 'draft',
    planCycle: null,
    billing: { status: 'rates_pending', amountFils: null, paidAt: null },
    submittedAt: null,
    decidedAt: null,
    startsOn: null,
    endsOn: null,
    rejection: null,
    planKeptUntil: null,
    sponsored: false,
    history: [{ id: `rev-${id}-1`, listingId: id, at: now, from: null, to: 'draft', actor: 'provider' }],
  }
  usePrototype.setState({ listings: [...listings, l] })
  useProv.setState(s => ({ edits: { ...s.edits, [id]: draft } }))
  return id
}

/** Saves the editor: the draft is kept, and the card's visible fields follow it. */
export function saveListing(id: string, draft: ListingDraft): void {
  useProv.setState(s => ({ edits: { ...s.edits, [id]: draft } }))
  usePrototype.setState(s => ({
    listings: s.listings.map(l =>
      l.id !== id
        ? l
        : {
            ...l,
            categoryId: draft.categoryId ?? l.categoryId,
            title: bi(draft.titleEn || l.title.en, draft.titleAr || l.title.ar),
            description: bi(draft.descEn || l.description.en, draft.descAr || l.description.ar),
            cover: draft.photos[0] ?? l.cover,
            // A saved package count shows on the card's next step (a draft without packages says "Finish your listing").
            packageIds: draft.packages.length ? draft.packages.map(p => p.id) : l.packageIds,
          },
    ),
  }))
}

/** A live listing was edited and sent: the approved version stays live until the moderator approves the new one (A-09). */
export function sendLiveRevision(id: string): void {
  useProv.setState(s => ({ revisions: { ...s.revisions, [id]: clock.now() } }))
}

/** Sends a listing to review from any state that can be sent: a draft or rejected one through the store, an ended one as a renewal. */
function toReview(id: string, cycle: AdPlanCycle): void {
  const st = usePrototype.getState()
  const l = st.listings.find(x => x.id === id)
  if (!l) return
  st.chooseListingPlan(id, cycle)
  if (l.status === 'draft' || l.status === 'rejected') {
    usePrototype.getState().submitListing(id)
    return
  }
  if (l.status === 'expired') {
    const now = clock.now()
    usePrototype.setState(s => ({
      listings: s.listings.map(x =>
        x.id === id
          ? {
              ...x,
              status: 'pending_review' as const,
              submittedAt: now,
              history: [...x.history, { id: `rev-${id}-${x.history.length + 1}`, listingId: id, at: now, from: 'expired' as const, to: 'pending_review' as const, actor: 'provider' as const }],
            }
          : x,
      ),
    }))
  }
}

/** Extends the plan of a live listing by one period from its current end (a renewal does not re-review the content). */
function extendLive(id: string, days: number): void {
  usePrototype.setState(s => ({ listings: s.listings.map(l => (l.id === id && l.endsOn ? { ...l, endsOn: engine.addDays(l.endsOn, days) } : l)) }))
}

/** Records a paid plan (sample amounts in the prototype). A draft or ended listing then goes to review: payment never publishes it. */
export function payAndSubmit(id: string, plan: PaidPlan, periodDays: number): 'review' | 'renewed' {
  const live = usePrototype.getState().listings.find(l => l.id === id)?.status === 'active'
  if (!live) toReview(id, plan.cycle)
  usePrototype.setState(s => ({
    listings: s.listings.map(l => (l.id === id ? { ...l, planCycle: plan.cycle, billing: { status: 'paid' as const, amountFils: plan.fils, paidAt: plan.at } } : l)),
  }))
  useProv.setState(s => ({ paid: { ...s.paid, [id]: plan } }))
  if (live) extendLive(id, periodDays)
  return live ? 'renewed' : 'review'
}

/** Fee-exempt partners, and partners whose rates are not announced yet, go to review with nothing to pay. `cycle` is null for a major hotel (no plan). */
export function chooseAndSubmit(id: string, cycle: AdPlanCycle | null, exempt: boolean): void {
  if (cycle) toReview(id, cycle)
  else {
    const l = usePrototype.getState().listings.find(x => x.id === id)
    if (l && (l.status === 'draft' || l.status === 'rejected')) usePrototype.getState().submitListing(id)
  }
  if (exempt) usePrototype.setState(s => ({ listings: s.listings.map(l => (l.id === id ? { ...l, billing: { ...l.billing, status: 'exempt' as const } } : l)) }))
}
