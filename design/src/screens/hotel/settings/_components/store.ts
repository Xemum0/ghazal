// Flow-local prototype memory of Settings: what has to stay in step between More, Staff, Business hours and Notification preferences but is
// not part of the shared prototype store. The fixtures are never touched; a reload is the story start. Voucher model (ADR 0033): there is no
// bank information here any more; the only step-up left is for staff changes.
import { create } from 'zustand'
import { hotelSettings, hotelStaff, PROTOTYPE_NOW, type HotelStaff } from '../../../../mock'
import { ASSIGNABLE, weekFrom, type Closure, type SettingsRole, type Week, type Weekday } from './model'

export const VENUE_ID: string = hotelSettings.venueId

export type PrefKey = 'confirmations' | 'cancelled' | 'redemptions' | 'visits' | 'messages' | 'reviews' | 'listing' | 'plan'

export type StaffOverride = { role?: SettingsRole; status?: HotelStaff['status']; canAccept?: boolean; removed?: boolean; inviteExpiresAt?: string }

/** What a step-up check unlocks once the code is confirmed (the Verify screen pops back to the screen that asked). */
export type PendingAction =
  | { kind: 'invite'; name: string; email: string; role: Exclude<SettingsRole, 'admin'>; canAccept: boolean }
  | { kind: 'role'; id: string; role: Exclude<SettingsRole, 'admin'> }
  | { kind: 'remove'; id: string }

export type Pending = { screen: 'staff'; action: PendingAction; startedAt: number; verified: boolean }

/** The step-up token lasts five minutes (ADR 0028 D6). `performance.now()` is the session clock; it is not the prototype's story clock. */
export const STEP_UP_MS = 5 * 60 * 1000
const HOUR_MS = 60 * 60 * 1000
const DAY_MS = 24 * HOUR_MS

const initialWeek = (): Week => weekFrom(hotelSettings.hours)
const initialClosures = (): Closure[] =>
  hotelSettings.hours.closures.map((c, i) => ({ id: `fixture-${i}`, label: c.label, from: c.from, to: c.to, approximate: c.approximate }))

const initialPrefs = (): Record<PrefKey, boolean> => ({
  confirmations: true,
  cancelled: true,
  redemptions: hotelSettings.notificationPrefs.vouchers,
  visits: hotelSettings.notificationPrefs.visits,
  messages: hotelSettings.notificationPrefs.messages,
  reviews: hotelSettings.notificationPrefs.reviews,
  listing: true,
  plan: true,
})

type SettingsLocal = {
  biometric: boolean
  setBiometric: (on: boolean) => void
  activeVenue: string
  setActiveVenue: (id: string) => void

  prefs: Record<PrefKey, boolean>
  setPref: (key: PrefKey, on: boolean) => void

  week: Week
  savedWeek: Week
  closures: Closure[]
  savedClosures: Closure[]
  /** The weekday the person last touched: "Copy to all days" shows under it. */
  lastEdited: Weekday | null
  setDay: (day: Weekday, patch: Partial<Week[Weekday]>) => void
  copyToAll: (day: Weekday) => void
  addClosure: (c: Closure) => void
  removeClosure: (id: string) => void
  saveHours: () => void
  discardHours: () => void

  staffOverrides: Record<string, StaffOverride>
  invited: HotelStaff[]
  patchStaff: (id: string, patch: StaffOverride) => void
  invite: (name: string, email: string, role: Exclude<SettingsRole, 'admin'>) => HotelStaff
  resendInvite: (id: string) => void

  stepUpUntil: number
  pending: Pending | null
  beginStepUp: (screen: Pending['screen'], action: PendingAction) => void
  markVerified: () => void
  clearPending: () => void
  reset: () => void
}

let seq = 0

export const useSettingsLocal = create<SettingsLocal>()((set, get) => ({
  biometric: false,
  setBiometric: on => set({ biometric: on }),
  activeVenue: VENUE_ID,
  setActiveVenue: id => set({ activeVenue: id }),

  prefs: initialPrefs(),
  setPref: (key, on) => set(s => ({ prefs: { ...s.prefs, [key]: on } })),

  week: initialWeek(),
  savedWeek: initialWeek(),
  closures: initialClosures(),
  savedClosures: initialClosures(),
  lastEdited: null,
  setDay: (day, patch) => set(s => ({ week: { ...s.week, [day]: { ...s.week[day], ...patch } }, lastEdited: day })),
  copyToAll: day =>
    set(s => {
      const from = s.week[day]
      const next = {} as Week
      for (const d of [0, 1, 2, 3, 4, 5, 6] as Weekday[]) next[d] = { ...from }
      return { week: next, lastEdited: day }
    }),
  addClosure: c => set(s => ({ closures: [...s.closures, c] })),
  removeClosure: id => set(s => ({ closures: s.closures.filter(c => c.id !== id) })),
  saveHours: () => set(s => ({ savedWeek: structuredClone(s.week), savedClosures: [...s.closures], lastEdited: null })),
  discardHours: () => set(s => ({ week: structuredClone(s.savedWeek), closures: [...s.savedClosures], lastEdited: null })),

  staffOverrides: {},
  invited: [],
  patchStaff: (id, patch) => set(s => ({ staffOverrides: { ...s.staffOverrides, [id]: { ...s.staffOverrides[id], ...patch } } })),
  invite: (name, _email, role) => {
    seq += 1
    const label = roleLabelOf(role)
    const person: HotelStaff = {
      id: `staff-local-${seq}`,
      userId: `user-local-${seq}`,
      venueId: VENUE_ID,
      name,
      nameLatin: name,
      monogram: Array.from(name.trim())[0] ?? '',
      role,
      roleLabel: label.label,
      roleSummary: label.summary,
      phone: '',
      status: 'invited',
      uiLang: /[؀-ۿ]/.test(name) ? 'ar' : 'en',
      lastSeenAt: null,
      invitedAt: PROTOTYPE_NOW,
      inviteExpiresAt: new Date(Date.parse(PROTOTYPE_NOW) + 3 * DAY_MS).toISOString(),
      invitedBy: 'Hind Al-Enezi',
      isYou: false,
    }
    set(s => ({ invited: [...s.invited, person] }))
    return person
  },
  resendInvite: id => {
    const expires = new Date(Date.parse(PROTOTYPE_NOW) + 3 * DAY_MS).toISOString()
    set(s => ({
      invited: s.invited.map(p => (p.id === id ? { ...p, inviteExpiresAt: expires } : p)),
      staffOverrides: { ...s.staffOverrides, [id]: { ...s.staffOverrides[id], status: 'invited', inviteExpiresAt: expires } },
    }))
  },

  stepUpUntil: 0,
  pending: null,
  beginStepUp: (screen, action) => set({ pending: { screen, action, startedAt: performance.now(), verified: false } }),
  markVerified: () => set(s => (s.pending ? { pending: { ...s.pending, verified: true }, stepUpUntil: performance.now() + STEP_UP_MS } : s)),
  clearPending: () => set({ pending: null }),
  reset: () => {
    seq = 0
    set({
      biometric: false,
      activeVenue: VENUE_ID,
      prefs: initialPrefs(),
      week: initialWeek(),
      savedWeek: initialWeek(),
      closures: initialClosures(),
      savedClosures: initialClosures(),
      lastEdited: null,
      staffOverrides: {},
      invited: [],
      stepUpUntil: 0,
      pending: null,
    })
  },
}))

/** A fixture person of each assignable role gives the bilingual label and one-line summary (never retyped in a screen). */
export function roleLabelOf(role: SettingsRole): { label: HotelStaff['roleLabel']; summary: HotelStaff['roleSummary'] } {
  const model = hotelStaff.find(s => s.role === role) ?? hotelStaff[0]!
  return { label: model.roleLabel, summary: model.roleSummary }
}

export const assignableRoles = ASSIGNABLE
export const HOURS_24 = 24
export { HOUR_MS }
