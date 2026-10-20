// Flow-local state and view hooks of the Profile flow (CL-PROF-01..06). What the prototype store does not carry: the email, the
// notification preferences, the usage-data switch and a scheduled deletion. In a live prototype everything is read from the store
// and from this slice; in a static frame (canvas, shots) a screen reads explicit data from its `?state=`, never what was played.
// Nothing is persisted: a reload (or a sign-out) is the story start.
import { useContext } from 'react'
import { create } from 'zustand'
import type { Booking, Voucher } from '../../../../mock'
import { clock, engine, heroBookingAs, heroVoucherAs, meta, notificationPrefs, users, visitsFor, vouchersFor, weddingProfile } from '../../../../mock'
import { useLang } from '../../../../shell/lang'
import { FrameContext } from '../../../../shell/frame'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'

// ---------------------------------------------------------------- config the screens read (never typed into a message)
export const APP_VERSION = '1.0.0'
/** The prototype is an iPhone: Face ID. The wording follows the platform (Touch ID, fingerprint) through this one value. */
export const BIOMETRIC_METHOD = 'face'
/** Marketing is never sent in the last week before the wedding (ADR 0007 D11). */
export const MARKETING_BLACKOUT_DAYS = 7
/** The two quiet-hour windows (ADR 0007 D11, ADR 0015 D8): marketing 22:00-09:00, booking and payment alerts silent 23:00-08:00. */
export const QUIET_MARKETING = { from: [22, 0], to: [9, 0] } as const
export const QUIET_ALERTS = { from: [23, 0], to: [8, 0] } as const

// ---------------------------------------------------------------- frame and mode

export const useLive = (): boolean => useDevice().mode === 'live'

/** The frame's `?state=`, else the `state` the player was started with; undefined in the live app by default. */
export function useSceneState(): string | undefined {
  const frame = useContext(FrameContext)
  const nav = useNav()
  const fromNav = nav.params.state
  return frame?.state ?? (typeof fromNav === 'string' ? fromNav : undefined)
}

// ---------------------------------------------------------------- the flow slice

export type Channel = 'push' | 'whatsapp' | 'email'
export type NotifKind = 'confirmWindow' | 'voucherExpiry' | 'visitReminders' | 'milestones' | 'offers' | 'priceDrops' | 'newVenues'

export type ProfileFlow = {
  /** Optional email. Empty until the person adds one. */
  email: string
  notif: {
    confirmWindow: boolean
    voucherExpiry: boolean
    visitReminders: boolean
    milestones: boolean
    marketing: boolean
    offers: boolean
    priceDrops: boolean
    newVenues: boolean
    reminderChannels: Channel[]
    marketingChannels: Channel[]
  }
  /** The phone's notification permission (the OS, not ours). */
  osNotifications: 'allowed' | 'denied'
  shareUsage: boolean
  /** A deletion requested for after the event (ADR 0007 D12); null while none. */
  deletionAfter: string | null
  setEmail: (email: string) => void
  setNotif: (patch: Partial<ProfileFlow['notif']>) => void
  setShareUsage: (on: boolean) => void
  scheduleDeletion: (after: string | null) => void
  reset: () => void
}

/** The flow's start values: what a static frame shows (a frame never reads what was played). */
export const flowDefaults = () => initial()

const initial = () => ({
  email: '',
  notif: {
    confirmWindow: true,
    voucherExpiry: true,
    visitReminders: true,
    milestones: true,
    // Reem opted in during onboarding (fixture); a new account starts with marketing off (ADR 0007 D11).
    marketing: notificationPrefs.marketing,
    offers: true,
    priceDrops: true,
    newVenues: true,
    reminderChannels: ['push', 'whatsapp'] as Channel[],
    marketingChannels: ['push'] as Channel[],
  },
  osNotifications: 'allowed' as const,
  shareUsage: true,
  deletionAfter: null as string | null,
})

export const useProfileFlow = create<ProfileFlow>()(set => ({
  ...initial(),
  setEmail: email => set({ email }),
  setNotif: patch => set(s => ({ notif: { ...s.notif, ...patch } })),
  setShareUsage: shareUsage => set({ shareUsage }),
  scheduleDeletion: deletionAfter => set({ deletionAfter }),
  reset: () => set({ ...initial() }),
}))

// A session ends when the prototype goes back to guest (sign-out, Restart in the launcher): the flow forgets everything with it.
usePrototype.subscribe((state, prev) => {
  if (state.auth === 'guest' && prev.auth === 'signedIn') useProfileFlow.getState().reset()
})

// ---------------------------------------------------------------- who is looking

export type Identity = {
  /** Display name in the current language (Arabic UI shows the Arabic name, English the Latin spelling). */
  name: string
  monogram: string
  /** E.164, display only. */
  phone: string
}

const reem = users.find(u => u.id === meta.clientUserId)

/** The first letter of a name in its own script, ignoring a leading Arabic `ال` (ADR 0015 D4). */
export function monogramFor(name: string): string {
  const first = name.trim().split(/\s+/).filter(Boolean)[0] ?? ''
  const base = first.length > 2 && first.startsWith('ال') ? first.slice(2) : first
  const ch = Array.from(base)[0]
  return ch ? ch.toUpperCase() : ''
}

/** Guest or signed in. A static frame is Reem unless the state says guest. */
export function useGuest(): boolean {
  const live = useLive()
  const auth = usePrototype(s => s.auth)
  const state = useSceneState()
  if (state === 'guest') return true
  return live ? auth === 'guest' : false
}

export function useIdentity(): Identity {
  const { lang } = useLang()
  const user = usePrototype(s => s.user)
  const live = useLive()
  const account = !live || !user ? { id: reem?.id ?? '', name: reem?.name ?? '', phone: reem?.phone ?? '', monogram: reem?.monogram ?? '' } : user
  const person = users.find(u => u.id === account.id)
  const name = lang === 'en' && person?.nameLatin ? person.nameLatin : account.name
  return { name, monogram: lang === 'en' && person?.nameLatin ? monogramFor(person.nameLatin) : account.monogram || monogramFor(name), phone: account.phone }
}

// ---------------------------------------------------------------- the story request, the wallet and the visits

/** Where the couple's one request stands (ADR 0033): `confirmed` also covers a redeemed voucher with the event still ahead. */
export type StoryStatus = 'pending' | 'approved' | 'confirmed' | null

const FRAME_STATUS: Record<string, Exclude<StoryStatus, null>> = {
  'blocked-active-booking': 'confirmed',
  confirmed: 'confirmed',
  'scheduled-after-event': 'confirmed',
  'blocked-approved': 'approved',
  approved: 'approved',
}

/** The couple's one request as it stands: the hotel app moves it, the 24 hour confirmation settles it. A static frame is explicit. */
export function useStoryBooking(): { status: StoryStatus; booking: Booking | null } {
  const live = useLive()
  const state = useSceneState()
  const hotelBookings = usePrototype(s => s.hotelBookings)
  const signedIn = usePrototype(s => s.auth === 'signedIn')

  let status: StoryStatus
  if (live) {
    const b = hotelBookings.find(x => x.id === meta.story.bookingId)
    status = !signedIn || !b ? null : b.status === 'pending' || b.status === 'approved' ? b.status : b.status === 'confirmed' || b.status === 'redeemed' ? 'confirmed' : null
  } else {
    status = FRAME_STATUS[state ?? ''] ?? 'pending'
  }
  return { status, booking: status ? heroBookingAs(status) : null }
}

/** Vouchers of the signed-in client that are ready to use (paid, not in a request), live from the store; a static frame reads the fixtures. */
export function useReadyVouchers(): Voucher[] {
  const live = useLive()
  const state = useSceneState()
  const userId = usePrototype(s => s.user?.id)
  const stored = usePrototype(s => s.vouchers)
  if (state === 'no-vouchers') return []
  const all = live ? stored.filter(v => v.clientId === userId) : vouchersFor(meta.clientUserId)
  return all.filter(v => v.status === 'active' && !engine.isVoucherExpired(v.validUntil, v.reuseUntil, clock.now()))
}

/** The one voucher paid to Ghazal that the hub shows as "KD 2.000 paid" (the story voucher, once its payment went through). */
export const paidVoucherFils = (): number => heroVoucherAs('pending').priceFils

/** Visits still ahead (requested, confirmed, or a new time proposed) of the signed-in client. */
export function useUpcomingVisits(): number {
  const live = useLive()
  const userId = usePrototype(s => s.user?.id)
  const stored = usePrototype(s => s.visits)
  const all = live ? stored.filter(v => v.clientId === userId) : visitsFor({ clientId: meta.clientUserId })
  return all.filter(v => v.status === 'requested' || v.status === 'confirmed' || v.status === 'reschedule_proposed').length
}

/** Whole days from the prototype clock; kept here so a screen never reaches for the clock itself. */
export const today = (): string => clock.today()

export { weddingProfile as storyProfile }
