// Flow-local state and helpers of the staff access flow (HL-ACCS-01..04). What the four screens share and the prototype store does not
// carry: the email being signed in, whether this "device" is already trusted (30 days after an email code, ADR 0028 D6), the failed
// attempts of the sign-in screen, and the demo rules of the prototype. Nothing is persisted; a reload is the story start.
//
// Demo rules (live player only; a static frame is frozen and deterministic):
//   sign in      the four active staff of Aurelia Gulf Hotel (email = first name @aurelia.example, fixtures 0040 ... 0043) with any password;
//                any other email is a wrong sign-in, five of them lock the screen. The first sign-in per session is a NEW device (email code, then the
//                authenticator code for the venue admin); after that the device is trusted and sign-in goes straight to Today.
//   new partner  the service-provider persona (Zahra Floral Studio, zahra@zahra-floral.example) signs in with any password and, once the device is
//                verified, lands on the application form (HL-PROV-01) the first time. While the application is open or rejected every sign-in
//                lands on the account status (HL-ACCS-04); an accepted account goes to Today (ADR 0033 D7, ADR 0038 D3).
//   code         any six digits work, 111111 is a wrong code (five lock the code), 222222 is an expired code.
import { create } from 'zustand'
import { useContext } from 'react'
import { hotelStaff, getVenue, personaFor, users, type HotelStaff } from '../../../../mock'
import { FrameContext } from '../../../../shell/frame'
import { useDevice } from '../../../../shell/device/context'
import { useLang } from '../../../../shell/lang'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'
import { useApplication } from '../../provider/_components/application'

/** Config values the screens read (ADR 0028, ADR 0012 D4): never typed into a message. */
export const OTP_LENGTH = 6
export const OTP_TTL_MINUTES = 5
export const RESEND_SECONDS = 60
export const MAX_ATTEMPTS = 5
export const LOCK_MINUTES = 15
export const TRUST_DAYS = 30
export const TOTP_SECONDS = 30
export const PASSWORD_MIN = 10

/** Hind Al-Enezi, Manager at Aurelia Gulf Hotel: the demo account. Staff are invited and sign in by email (Resend); display only. */
export const DEMO_EMAIL = 'hind@aurelia.example'
/** What the password manager "remembered" for her: masked, never shown unless the person reveals it. */
export const DEMO_PASSWORD = 'Aurelia-2026'
/** Ghazal Support (fixture phone 0001), display only. */
export const SUPPORT_PHONE = '+96550000001'
export const WRONG_CODE = '111111'
export const EXPIRED_CODE = '222222'

export const VENUE_ID = 'V01'

/** Prototype email of a staff member (the mock carries no email): first name of the Latin name at the venue's example domain. */
export const emailOf = (s: HotelStaff): string => `${(s.nameLatin.split(' ')[0] ?? 'staff').toLowerCase()}@aurelia.example`
export const normalizeEmail = (v: string): string => v.trim().toLowerCase()
export const isValidEmail = (v: string): boolean => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.trim())
/** h•••@aurelia.example: first letter and the domain, the rest hidden. */
export const maskEmail = (v: string): string => {
  const [name = '', domain = ''] = v.split('@')
  return `${name.slice(0, 1)}•••@${domain}`
}

/** The active staff member behind an email (the sign-in screen); invited staff have no password yet. */
export function activeStaffByEmail(email: string): HotelStaff | undefined {
  const e = normalizeEmail(email)
  return hotelStaff.find(s => s.status === 'active' && emailOf(s) === e)
}

/** The service-provider persona: invited by Ghazal without an account type yet, so her first sign-in ends on the chooser. */
const providerPersona = () => personaFor('service_provider')
export const providerUser = () => users.find(u => u.id === providerPersona()?.userId)
export const PROVIDER_EMAIL = 'zahra@zahra-floral.example'
export const isProviderEmail = (email: string): boolean => normalizeEmail(email) === PROVIDER_EMAIL

export const staffById = (id: string | null | undefined): HotelStaff | undefined => hotelStaff.find(s => s.id === id)

/** The one invitation in the seed: Sara Al-Qattan (Marketing), invited by the venue admin, valid until Sat 14 Nov 2026 (fixtures.md section 12). */
export const invitedStaff = (): HotelStaff | undefined => hotelStaff.find(s => s.status === 'invited')
export const adminStaff = (): HotelStaff | undefined => hotelStaff.find(s => s.role === 'admin')
export const demoStaff = (): HotelStaff | undefined => hotelStaff.find(s => s.isYou)

export const venueOf = () => getVenue(VENUE_ID)

type AccessFlow = {
  /** The email being signed in (or whose password is being reset). */
  email: string
  /** Staff member the current attempt resolves to. */
  staffId: string | null
  /** This device has passed an email code within 30 days. */
  trusted: boolean
  /** The two first-run sheets on Today open once per session. */
  firstRunDone: boolean
  /** The email being signed in belongs to the new service-provider partner (no staff record, no type yet). */
  provider: boolean
  /** The account type chooser was shown once this session; the next sign-in goes to Today. */
  typeAsked: boolean
  failed: number
  lockedAt: string | null
  setEmail: (email: string) => void
  setStaffId: (id: string | null) => void
  setTrusted: (v: boolean) => void
  setFirstRunDone: (v: boolean) => void
  setProvider: (v: boolean) => void
  setTypeAsked: (v: boolean) => void
  setFailed: (n: number) => void
  setLockedAt: (iso: string | null) => void
}

export const useAccessFlow = create<AccessFlow>()(set => ({
  email: '',
  staffId: null,
  trusted: false,
  firstRunDone: false,
  provider: false,
  typeAsked: false,
  failed: 0,
  lockedAt: null,
  setEmail: email => set({ email }),
  setStaffId: staffId => set({ staffId }),
  setTrusted: trusted => set({ trusted }),
  setFirstRunDone: firstRunDone => set({ firstRunDone }),
  setProvider: provider => set({ provider }),
  setTypeAsked: typeAsked => set({ typeAsked }),
  setFailed: failed => set({ failed }),
  setLockedAt: lockedAt => set({ lockedAt }),
}))

// "Restart" in the launcher re-seeds the prototype store (a new hotelBookings copy while the session is a guest); a sign-out does not.
// Only a restart makes this device "new" again, so the first sign-in of every session shows the verification screen.
usePrototype.subscribe((state, prev) => {
  if (state.auth === 'guest' && state.hotelBookings !== prev.hotelBookings) {
    useAccessFlow.setState({ email: '', staffId: null, trusted: false, firstRunDone: false, provider: false, typeAsked: false, failed: 0, lockedAt: null })
  }
})

/** True in the player, false in a static frame (canvas, #/frame): timers and demo rules only run live. */
export const useLive = (): boolean => useDevice().mode === 'live'

/** useFrame() throws outside a frame route; screens must also run in the player. */
export function useScreenState(): string | undefined {
  return useContext(FrameContext)?.state
}

/** What every screen of the flow can do besides pushing: land on Today after a successful sign-in. */
export function useAccessMoves() {
  const nav = useNav()
  const { lang } = useLang()

  /**
   * Signs the staff member in and lands on Today. The first sign-in of the session asks for the two quiet first-run sheets
   * (notifications, then the biometric lock) by passing `firstRun` to Today. The viewer keeps the language they chose in the
   * launcher: the user's own language setting only takes over in the real app.
   */
  const finish = (staff: HotelStaff) => {
    const store = usePrototype.getState()
    const flow = useAccessFlow.getState()
    store.signIn({ id: staff.userId, name: lang === 'ar' ? staff.name : staff.nameLatin, phone: staff.phone, monogram: staff.monogram })
    const first = !flow.firstRunDone
    flow.setFirstRunDone(true)
    flow.setFailed(0)
    flow.setLockedAt(null)
    nav.reset('HL-TODY-01', first ? { firstRun: true } : undefined)
  }
  /**
   * The end of a successful sign-in for either partner type. The service-provider partner has no staff record and has not applied yet: the
   * first time she goes to the application (HL-PROV-01, which carries `account: 'provider'` as its hint); while her application is under
   * review or was rejected she lands on the account status (HL-ACCS-04); afterwards, and for every hotel or hall staff member, on Today.
   */
  const complete = (staff: HotelStaff | undefined) => {
    const flow = useAccessFlow.getState()
    const user = providerUser()
    if (flow.provider && user) {
      const store = usePrototype.getState()
      store.signIn({ id: user.id, name: (lang === 'ar' ? user.name : user.nameLatin) ?? user.name, phone: user.phone ?? '', monogram: user.monogram ?? '' })
      flow.setFailed(0)
      flow.setLockedAt(null)
      const decision = useApplication.getState().status
      if (decision === 'under_review' || decision === 'rejected') {
        nav.reset('HL-ACCS-04', { variant: decision === 'rejected' ? 'application-rejected' : 'application-review', account: 'provider' })
      } else if (!flow.typeAsked && decision === 'none') {
        flow.setTypeAsked(true)
        nav.reset('HL-PROV-01', { account: 'provider' })
      } else {
        nav.reset('HL-TODY-01', { account: 'provider' })
      }
      return
    }
    if (staff) finish(staff)
  }
  /** Back to the sign-in screen from anywhere (sign out, session ended, finished password reset). */
  const toSignIn = (params?: Record<string, unknown>) => nav.reset('HL-ACCS-01', params)
  return { nav, finish, complete, toSignIn }
}
