// Initial values and fixture access for the store. Everything that reads the fixtures goes through design/src/mock and is wrapped
// so a missing or still-moving fixture degrades to an empty value instead of breaking the prototype.
import * as mock from '../../mock'
import type { Booking, Brief, IsoDate, IsoDateTime, Listing, VisitAppointment, Voucher } from '../../mock'
import type { BookingDraft, PaymentState, SearchBrief, WeddingProfileState } from './types'

export function safe<T>(read: () => T, fallback: T): T {
  try {
    const v = read()
    return v === undefined ? fallback : v
  } catch {
    return fallback
  }
}

export const clone = <T>(v: T): T => structuredClone(v)

export const EMPTY_BRIEF: SearchBrief = { date: null, guests: null, audience: null, areaIds: [], budget: null, dateMode: 'undecided' }

export const EMPTY_DRAFT: BookingDraft = {
  targetType: 'venue',
  venueId: null,
  providerId: null,
  hallId: null,
  sessionId: null,
  packageId: null,
  extras: [],
  eventDate: null,
  audience: null,
  guests: null,
  personal: { name: '', phone: '', email: '', bookingFor: 'bride' },
  requests: '',
  voucherId: null,
  step: 'package',
}

export const IDLE_PAYMENT: PaymentState = { outcome: 'idle', method: null, kind: null, refId: null, amount: null }

export const hotelVenueId = (): string => safe(() => mock.meta.hotelVenueId, 'V01')
export const clientUserId = (): string => safe(() => mock.meta.clientUserId, 'user-reem')

/** A fresh deep copy of the partner venue's requests: the mutable queue the partner actions work on. */
export const hotelBookingsCopy = (): Booking[] => safe(() => clone(mock.bookingsFor({ venueId: hotelVenueId() })), [])

/** The signed-in client's requests (the same ids as the partner queue for the hero request), copied. */
export const clientBookingsCopy = (): Booking[] => safe(() => clone(mock.bookingsFor({ clientId: clientUserId() })), [])

/** Every voucher of the seed (the wallet of a client is a filter on it; the partner redeems from the same objects), copied. */
export const vouchersCopy = (): Voucher[] => safe(() => clone([...mock.vouchers, mock.competingVoucher]), [])

export const visitsCopy = (): VisitAppointment[] => safe(() => clone(mock.visits), [])

export const listingsCopy = (): Listing[] => safe(() => clone(mock.listings), [])

/** Reem's wedding profile as the onboarding result (the shared story). */
export function storyWeddingProfile(): WeddingProfileState | null {
  const p = safe(() => mock.weddingProfile, null)
  if (!p) return null
  return {
    role: p.role,
    name: p.brideName,
    partnerName: p.partnerName,
    weddingDate: p.weddingDate,
    dateMode: p.dateMode,
    guests: { ...p.guests },
    venueBudget: { min: { ...p.venueBudget.min }, max: { ...p.venueBudget.max } },
    totalBudget: { ...p.totalBudget },
    areaIds: [...p.areaIds],
    searching: [...p.searching],
  }
}

/** The story Brief: Thu 14 Jan 2027, about 350 guests (ladies), Salmiya or Sharq, venue-and-catering budget KD 20,000 to 35,000. */
export function storyBrief(): SearchBrief {
  const p = storyWeddingProfile()
  if (!p) return { ...EMPTY_BRIEF }
  const brief: Brief = {
    date: p.weddingDate,
    guests: p.guests.women,
    audience: p.searching[0] ?? 'women',
    areaIds: p.areaIds,
    budget: p.venueBudget ? { min: p.venueBudget.min, max: p.venueBudget.max } : null,
  }
  return { ...brief, dateMode: p.dateMode } as SearchBrief
}

export const storyFavourites = (): { venue: string[]; vendor: string[]; package: string[] } => {
  const saved = safe(() => mock.clientState.saved, [])
  const out = { venue: [] as string[], vendor: [] as string[], package: [] as string[] }
  for (const s of saved) out[s.type].push(s.id)
  return out
}

export const storyCompare = (): string[] => safe(() => [...mock.clientState.compareVenueIds], [])

export const storyUser = () => {
  const u = safe(() => mock.users.find(x => x.id === clientUserId()), undefined)
  // The demo persona (Reem) is a woman; the fixtures carry no `sex` yet, so the prototype account holds it.
  return u ? { id: u.id, name: u.name, phone: u.phone, monogram: u.monogram, sex: 'female' as const } : { id: clientUserId(), name: '', phone: '', monogram: '', sex: 'female' as const }
}

/** ISO instant plus hours, written with the Kuwait offset (the fixtures never use Z). */
export function addHours(iso: IsoDateTime, hours: number): IsoDateTime {
  const ms = Date.parse(iso) + hours * 3_600_000
  const kuwait = new Date(ms + 3 * 3_600_000).toISOString().replace('Z', '').replace(/\.\d{3}$/, '')
  return `${kuwait}+03:00`
}

export const nowIso = (): IsoDateTime => safe(() => mock.clock.now(), '2026-11-12T16:00:00+03:00')
export const todayIso = (): IsoDate => safe(() => mock.clock.today(), '2026-11-12')
