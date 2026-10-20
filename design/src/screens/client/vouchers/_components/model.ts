// The vouchers flow's model: what a screen knows about the voucher in front of it, from the prototype store (live) or from the fixtures (a
// static frame). Pure reads: no screen invents data. Money is integer fils; nothing here is a display string.
//
//   useSceneState   the `?state=` of a static frame, or `state` in the navigator params in the player
//   useLive         true only in the live prototype (timers and store writes); a static frame never moves
//   useSignedIn     a static frame is a signed-in client unless the state says guest; the player follows the auth gate
//   useWallet       the signed-in client's vouchers (live vouchers first, then used, expired, not valid, credit issued)
//   phaseOf         one word for where a voucher is: ready, pending, approved, confirmed, redeemed, consumed, released, expired, forfeited, credit-issued, unpaid
//   useQuote        the quote a voucher would be bound to (params, else the booking draft, else the story hall)
//   useTargetFacts  names for a voucher or quote: venue or provider, hall, package, thumbnail
import { useContext, useMemo } from 'react'
import { useDevice } from '../../../../shell/device/context'
import { FrameContext } from '../../../../shell/frame'
import { usePrototype } from '../../../../shell/state'
import { useBi, useNav } from '../../../../system'
import { clock, creditVouchersFor, engine, getBooking, getCreditVoucher, getHall, getPackage, getProvider, getVenue, getVoucher, meta, packagesFor, quoteFor, quoteForProvider, voucherOptions } from '../../../../mock'
import type { Audience, Bilingual, Booking, ImageRef, IsoDate, Venue, Voucher, WalletVoucher } from '../../../../mock'

export const STORY_VOUCHER_CODE = 'GV-2611-K7QM'
export const STORY_RELEASED_CODE = 'GV-2611-R4TF'
export const STORY_CREDIT_ISSUED_CODE = 'GV-2610-H9XB'
export const STORY_FORFEITED_CODE = 'GV-2609-F6TM'
export const STORY_CREDIT_CODE = 'GV-2611-C4RD'
export const STORY_EXPIRED_CODE = 'GV-2608-D5QN'
/** The days inside which a ready voucher says "Expires" in the gold ink (inventory CL-VCHR-02). */
export const EXPIRING_DAYS = 7

// ---------------------------------------------------------------- scene

export function useSceneState(): string | undefined {
  const frame = useContext(FrameContext)
  const nav = useNav()
  const fromNav = nav.params.state
  return frame?.state ?? (typeof fromNav === 'string' ? fromNav : undefined)
}

export const useLive = (): boolean => useDevice().mode === 'live'

export function useSignedIn(): boolean {
  const live = useLive()
  const auth = usePrototype(s => s.auth)
  const state = useSceneState()
  if (state === 'guest' || state === 'guest-gated') return false
  return live ? auth === 'signedIn' : true
}

// ---------------------------------------------------------------- the story voucher and its siblings (fixtures)

export function storyVoucher(): Voucher {
  const v = getVoucher(STORY_VOUCHER_CODE)
  if (!v) throw new Error('Story voucher missing')
  return v
}

/** The story voucher as it is the moment after payment: ready to use, not yet in a request. Derived from the fixture, nothing added. */
export function readyVariantOf(v: Voucher): Voucher {
  return { ...v, status: 'active', bookingId: null, releasedAt: null, releaseReason: null, reuseUntil: null, creditEligible: false }
}

export const settled = (v: Voucher): Voucher => (v.status === 'active' && engine.isVoucherExpired(v.validUntil, v.reuseUntil, clock.now()) ? { ...v, status: 'expired' } : v)

// ---------------------------------------------------------------- the wallet

const RANK: Record<Voucher['status'], number> = { bound: 0, active: 1, unpaid: 2, used: 3, expired: 4, forfeited: 5, credit_issued: 6 }
/** A ready credit voucher leads the wallet; an ended one sorts with the ended bound vouchers. */
const rankOf = (v: WalletVoucher): number => (v.kind === 'credit' ? (v.status === 'active' ? -1 : 3.5) : RANK[v.status])

export type Segment = 'ready' | 'request' | 'history'

export const segmentOf = (v: WalletVoucher): Segment => (v.status === 'active' ? 'ready' : v.status === 'bound' || v.status === 'unpaid' ? 'request' : 'history')

/** The end of what a voucher can still do: the reuse window while released, else the validity end (an absolute date). */
export function endsOn(v: WalletVoucher): IsoDate | null {
  if (v.kind === 'bound' && v.status === 'active' && v.reuseUntil) return v.reuseUntil
  return v.validUntil ? engine.kuwaitDateOf(v.validUntil) : null
}

export function daysToEnd(v: WalletVoucher): number | null {
  const end = endsOn(v)
  return end ? engine.diffDays(clock.today(), end) : null
}

export function useWallet(): WalletVoucher[] {
  const all = usePrototype(s => s.vouchers)
  const user = usePrototype(s => s.user)
  const me = user?.id ?? meta.clientUserId
  return useMemo(() => {
    const bound: WalletVoucher[] = all.filter(v => v.clientId === me && v.status !== 'unpaid').map(settled)
    return [...bound, ...creditVouchersFor(me, clock.now())].sort((a, b) => rankOf(a) - rankOf(b) || ((b.kind === 'bound' ? b.purchasedAt : b.grantedAt) ?? '').localeCompare((a.kind === 'bound' ? a.purchasedAt : a.grantedAt) ?? ''))
  }, [all, me])
}

/** The bound vouchers of the wallet (a credit voucher is not tied to a request's venue, so quote matching ignores it). */
export function useBoundWallet(): Voucher[] {
  const wallet = useWallet()
  return useMemo(() => wallet.filter((v): v is Voucher => v.kind === 'bound'), [wallet])
}

/** A wallet for the static frames: the story client's vouchers straight from the fixtures (bound, credit, not valid, credit issued). */
export function fixtureWallet(): WalletVoucher[] {
  const bound = [STORY_VOUCHER_CODE, STORY_RELEASED_CODE, STORY_FORFEITED_CODE, STORY_CREDIT_ISSUED_CODE]
    .map(code => getVoucher(code))
    .filter((v): v is Voucher => Boolean(v))
    .map(settled)
  const credit = getCreditVoucher(STORY_CREDIT_CODE)
  return [...bound, ...(credit ? [credit] : [])].sort((a, b) => rankOf(a) - rankOf(b))
}

// ---------------------------------------------------------------- a voucher's request

export function useBookingOf(v: Voucher | null): Booking | null {
  const mine = usePrototype(s => s.clientBookings)
  const theirs = usePrototype(s => s.hotelBookings)
  if (!v?.bookingId) return null
  return mine.find(b => b.id === v.bookingId) ?? theirs.find(b => b.id === v.bookingId) ?? getBooking(v.bookingId) ?? null
}

/** Finds the request of any voucher (the store's copies first, then the fixtures): for lists, where a hook per row is not possible. */
export function useBookingLookup(): (v: Voucher) => Booking | null {
  const mine = usePrototype(s => s.clientBookings)
  const theirs = usePrototype(s => s.hotelBookings)
  return v => (v.bookingId ? (mine.find(b => b.id === v.bookingId) ?? theirs.find(b => b.id === v.bookingId) ?? getBooking(v.bookingId) ?? null) : null)
}

export type Phase = 'ready' | 'pending' | 'approved' | 'confirmed' | 'redeemed' | 'consumed' | 'released' | 'expired' | 'forfeited' | 'credit-issued' | 'unpaid'

export function phaseOf(v: Voucher, booking: Booking | null): Phase {
  const s = settled(v).status
  switch (s) {
    case 'unpaid':
      return 'unpaid'
    case 'active':
      return v.releaseReason || v.reuseUntil ? 'released' : 'ready'
    case 'bound':
      return booking?.status === 'approved' ? 'approved' : booking?.status === 'confirmed' ? 'confirmed' : 'pending'
    case 'used':
      return v.usedReason === 'cancelled_after_confirm' ? 'consumed' : 'redeemed'
    case 'expired':
      return 'expired'
    case 'forfeited':
      return 'forfeited'
    case 'credit_issued':
      return 'credit-issued'
  }
}

/** What a released voucher can still do now: reuse at the same venue, ask support for a credit voucher (ADR 0035 D5). */
export const optionsOf = (v: Voucher): { reusable: boolean; creditEligible: boolean; reusableUntil: IsoDate | null } => voucherOptions(v, clock.now())

// ---------------------------------------------------------------- the quote a voucher is bound to

export type Quote = {
  targetType: 'venue' | 'provider'
  targetId: string
  hallId: string | null
  packageId: string
  audience: Audience | null
  eventDate: IsoDate
  guests: number | null
  standardFils: number
  voucherFils: number
  savingsFils: number
  /** The saving beats the voucher fee (voucher-model 4.1): otherwise no voucher is offered. */
  offered: boolean
}

const FEE = (): number => meta.config.voucherFeeFils

/** The bound quote of a stored voucher (what it was bought for). */
export function quoteOfVoucher(v: Voucher): Quote {
  const savings = Math.max(0, v.quoteFils.standard - v.quoteFils.voucher)
  return {
    targetType: v.targetType,
    targetId: v.venueOrProviderId,
    hallId: v.hallId,
    packageId: v.packageId,
    audience: null,
    eventDate: v.eventDate,
    guests: v.guests,
    standardFils: v.quoteFils.standard,
    voucherFils: v.quoteFils.voucher,
    savingsFils: savings,
    offered: savings > FEE(),
  }
}

export type QuoteInput = {
  venueId?: string | null
  providerId?: string | null
  hallId?: string | null
  packageId?: string | null
  date?: string | null
  guests?: number | null
  audience?: Audience | null
}

/** Quotes one choice from the fixtures' pricing engine, or null when the inputs do not name a priced choice. */
export function quoteOfChoice(input: QuoteInput): Quote | null {
  try {
    if (input.providerId) {
      const provider = getProvider(input.providerId)
      const pkg = provider?.packages.find(p => p.id === input.packageId) ?? provider?.packages[0]
      if (!provider || !pkg) return null
      const qty = input.guests ?? 1
      const q = quoteForProvider({ providerId: provider.id, packageId: pkg.id, qty })
      const savings = q.totals.savings.fils
      return {
        targetType: 'provider',
        targetId: provider.id,
        hallId: null,
        packageId: pkg.id,
        audience: null,
        eventDate: input.date ?? clock.today(),
        guests: qty,
        standardFils: q.totals.standardTotal.fils,
        voucherFils: q.totals.voucherTotal.fils,
        savingsFils: savings,
        offered: savings > FEE(),
      }
    }
    if (!input.venueId) return null
    const venue = getVenue(input.venueId)
    if (!venue) return null
    const pkg = (input.packageId ? getPackage(input.packageId) : undefined) ?? packagesFor(venue.id).find(p => p.voucherFils !== null) ?? packagesFor(venue.id)[0]
    if (!pkg) return null
    const hallId = input.hallId && pkg.hallIds.includes(input.hallId) ? input.hallId : (pkg.hallIds[0] ?? venue.halls[0]?.id ?? null)
    if (!hallId) return null
    const audience = input.audience ?? pkg.audiences[0] ?? 'women'
    const guests = input.guests ?? pkg.minGuests
    const eventDate = input.date ?? storyVoucher().eventDate
    const q = quoteFor({ venueId: venue.id, eventDate, sections: [{ hallId, audience, guests, packageId: pkg.id }] })
    const savings = q.totals.savings.fils
    return {
      targetType: 'venue',
      targetId: venue.id,
      hallId,
      packageId: pkg.id,
      audience,
      eventDate,
      guests,
      standardFils: q.totals.standardTotal.fils,
      voucherFils: q.totals.voucherTotal.fils,
      savingsFils: savings,
      offered: savings > FEE(),
    }
  } catch {
    return null
  }
}

/** The quote the explainer binds: navigator params first, else the booking draft, else the story hall (Reem's request). */
export function useQuote(): Quote {
  const nav = useNav()
  const draft = usePrototype(s => s.bookingDraft)
  const brief = usePrototype(s => s.searchBrief)
  const live = useLive()
  const p = nav.params as { venueId?: string; providerId?: string; hallId?: string; packageId?: string; date?: string; eventDate?: string; guests?: number; audience?: Audience }
  return useMemo(() => {
    const fromParams = p.venueId || p.providerId ? quoteOfChoice({ venueId: p.venueId, providerId: p.providerId, hallId: p.hallId, packageId: p.packageId, date: p.date ?? p.eventDate ?? null, guests: p.guests ?? null, audience: p.audience ?? null }) : null
    if (fromParams) return fromParams
    if (live && (draft.venueId || draft.providerId)) {
      const fromDraft = quoteOfChoice({ venueId: draft.venueId, providerId: draft.providerId, hallId: draft.hallId, packageId: draft.packageId, date: draft.eventDate ?? brief.date ?? null, guests: draft.guests, audience: draft.audience })
      if (fromDraft) return fromDraft
    }
    return quoteOfVoucher(storyVoucher())
  }, [p.venueId, p.providerId, p.hallId, p.packageId, p.date, p.eventDate, p.guests, p.audience, live, draft, brief.date])
}

/** A ready voucher that already fits this quote exactly (same target, hall, package, date and guests). */
export function matchingReady(wallet: Voucher[], q: Quote): Voucher | undefined {
  return wallet.find(v => v.status === 'active' && v.venueOrProviderId === q.targetId && v.hallId === q.hallId && v.packageId === q.packageId && v.eventDate === q.eventDate && v.guests === q.guests)
}

/** Why a voucher does not fit a changed quote, or null when it still does (CL-VCHR-04). */
export function misfit(v: Voucher, q: Quote): 'target' | 'saving' | null {
  if (v.venueOrProviderId !== q.targetId) return 'target'
  if (!(q.savingsFils > FEE())) return 'saving'
  return null
}

// ---------------------------------------------------------------- names

export type Facts = {
  name: string
  kind: 'venue' | 'provider'
  hall: string | null
  pkg: string | null
  cover: ImageRef | null
  venue: Venue | null
  monogram: string
}

export function useFactsOf(target: { targetType: 'venue' | 'provider'; targetId: string; hallId: string | null; packageId: string }): Facts {
  const bi = useBi()
  if (target.targetType === 'provider') {
    const provider = getProvider(target.targetId)
    const pkg = provider?.packages.find(p => p.id === target.packageId)
    return { name: provider ? bi(provider.name) : '', kind: 'provider', hall: null, pkg: pkg ? bi(pkg.name) : null, cover: null, venue: null, monogram: provider?.monogram ?? '' }
  }
  const venue = getVenue(target.targetId) ?? null
  const hall = target.hallId ? getHall(target.hallId)?.hall : undefined
  const pkg = getPackage(target.packageId)
  return { name: venue ? bi(venue.name) : '', kind: 'venue', hall: hall ? bi(hall.name) : null, pkg: pkg ? bi(pkg.name) : null, cover: venue?.cover ?? null, venue, monogram: '' }
}

export const targetOfVoucher = (v: Voucher) => ({ targetType: v.targetType, targetId: v.venueOrProviderId, hallId: v.hallId, packageId: v.packageId })
export const targetOfQuote = (q: Quote) => ({ targetType: q.targetType, targetId: q.targetId, hallId: q.hallId, packageId: q.packageId })

export function useFactsOfVoucher(v: Voucher): Facts {
  return useFactsOf(targetOfVoucher(v))
}

/** The venue's reply window in hours (its own SLA, else the platform default), and the fixed confirm window. */
export function replyHoursOf(targetType: 'venue' | 'provider', targetId: string): number {
  if (targetType === 'provider') return getProvider(targetId)?.usuallyRepliesHours ?? meta.config.defaultReplyHours
  return getVenue(targetId)?.policies.responseSlaHours ?? meta.config.defaultReplyHours
}

export const CONFIRM_HOURS = (): number => meta.config.confirmWindowHours

export type { Bilingual }

// ---------------------------------------------------------------- hand-offs

/** The params CL-BOOK-01 takes to start a request that is already bound to this voucher (the quote is prefilled and locked). */
export function requestParams(v: Voucher): Record<string, unknown> {
  return {
    ...(v.targetType === 'venue' ? { venueId: v.venueOrProviderId } : { providerId: v.venueOrProviderId }),
    voucherId: v.id,
    date: v.eventDate,
    hallId: v.hallId ?? undefined,
    guests: v.guests ?? undefined,
    fresh: true,
  }
}

/** Remembers the voucher on the booking draft (the Review screen reads it) and opens the request flow. */
export function openRequest(nav: { push: (id: string, params?: Record<string, unknown>) => void }, v: Voucher): void {
  usePrototype.getState().patchDraft({ voucherId: v.id })
  nav.push('CL-BOOK-01', requestParams(v))
}
