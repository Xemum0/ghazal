// Flow-local state and helpers of the staff access flow (HL-ACCS-01..04). What the four screens share and the prototype store does not
// carry: the number being signed in, whether this "device" is already trusted (30 days after a WhatsApp code, ADR 0028 D6), the failed
// attempts of the sign-in screen, and the demo rules of the prototype. Nothing is persisted; a reload is the story start.
//
// Demo rules (live player only; a static frame is frozen and deterministic):
//   sign in      the four active staff of Aurelia Gulf Hotel (fixtures +965 5000 0040 ... 0043) with any password; any other number is a
//                wrong sign-in, five of them lock the screen. The first sign-in per session is a NEW device (WhatsApp code, then the
//                authenticator code for the venue admin); after that the device is trusted and sign-in goes straight to Today.
//   new partner  the service-provider persona (Zahra Floral Studio, +965 5000 0047) signs in with any password and, once the device is
//                verified, lands on the account type chooser (HL-PROV-01) the first time; later sign-ins go to Today (ADR 0033 D7).
//   code         any six digits work, 111111 is a wrong code (five lock the code), 222222 is an expired code.
import { create } from 'zustand'
import { useContext } from 'react'
import { hotelStaff, getVenue, personaFor, users, type HotelStaff } from '../../../../mock'
import { FrameContext } from '../../../../shell/frame'
import { useDevice } from '../../../../shell/device/context'
import { useLang } from '../../../../shell/lang'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'

/** Config values the screens read (ADR 0028, ADR 0012 D4): never typed into a message. */
export const OTP_LENGTH = 6
export const OTP_TTL_MINUTES = 5
export const RESEND_SECONDS = 60
export const MAX_ATTEMPTS = 5
export const LOCK_MINUTES = 15
export const TRUST_DAYS = 30
export const TOTP_SECONDS = 30
export const PASSWORD_MIN = 10

/** Hind Al-Enezi, Manager at Aurelia Gulf Hotel (+965 5000 0040): the demo account, display only. */
export const DEMO_NATIONAL = '50000040'
/** What the password manager "remembered" for her: masked, never shown unless the person reveals it. */
export const DEMO_PASSWORD = 'Aurelia-2026'
/** Ghazal Support (fixture phone 0001), display only. */
export const SUPPORT_PHONE = '+96550000001'
export const WRONG_CODE = '111111'
export const EXPIRED_CODE = '222222'

export const VENUE_ID = 'V01'

const nationalOf = (phone: string): string => phone.replace(/\D/g, '').slice(-8)

/** The active staff member behind a mobile number (the sign-in screen); invited staff have no password yet. */
export function activeStaffByNational(national: string): HotelStaff | undefined {
  return hotelStaff.find(s => s.status === 'active' && nationalOf(s.phone) === national)
}

/** The service-provider persona: invited by Ghazal without an account type yet, so her first sign-in ends on the chooser. */
const providerPersona = () => personaFor('service_provider')
export const providerUser = () => users.find(u => u.id === providerPersona()?.userId)
export const PROVIDER_NATIONAL = nationalOf(providerPersona()?.phone ?? '')
export const isProviderNumber = (national: string): boolean => PROVIDER_NATIONAL !== '' && national === PROVIDER_NATIONAL

export const staffById = (id: string | null | undefined): HotelStaff | undefined => hotelStaff.find(s => s.id === id)
export const staffByNational = (national: string): HotelStaff | undefined => hotelStaff.find(s => nationalOf(s.phone) === national)

/** The one invitation in the seed: Sara Al-Qattan (Marketing), invited by the venue admin, valid until Sat 14 Nov 2026 (fixtures.md section 12). */
export const invitedStaff = (): HotelStaff | undefined => hotelStaff.find(s => s.status === 'invited')
export const adminStaff = (): HotelStaff | undefined => hotelStaff.find(s => s.role === 'admin')
export const demoStaff = (): HotelStaff | undefined => hotelStaff.find(s => s.isYou)

export const venueOf = () => getVenue(VENUE_ID)

type AccessFlow = {
  /** National digits of the number being signed in (or whose password is being reset). */
  phone: string
  /** Staff member the current attempt resolves to. */
  staffId: string | null
  /** This device has passed a WhatsApp code within 30 days. */
  trusted: boolean
  /** The two first-run sheets on Today open once per session. */
  firstRunDone: boolean
  /** The number being signed in belongs to the new service-provider partner (no staff record, no type yet). */
  provider: boolean
  /** The account type chooser was shown once this session; the next sign-in goes to Today. */
  typeAsked: boolean
  failed: number
  lockedAt: string | null
  setPhone: (phone: string) => void
  setStaffId: (id: string | null) => void
  setTrusted: (v: boolean) => void
  setFirstRunDone: (v: boolean) => void
  setProvider: (v: boolean) => void
  setTypeAsked: (v: boolean) => void
  setFailed: (n: number) => void
  setLockedAt: (iso: string | null) => void
}

export const useAccessFlow = create<AccessFlow>()(set => ({
  phone: '',
  staffId: null,
  trusted: false,
  firstRunDone: false,
  provider: false,
  typeAsked: false,
  failed: 0,
  lockedAt: null,
  setPhone: phone => set({ phone }),
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
    useAccessFlow.setState({ phone: '', staffId: null, trusted: false, firstRunDone: false, provider: false, typeAsked: false, failed: 0, lockedAt: null })
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
   * The end of a successful sign-in for either partner type. The service-provider partner has no staff record and no account type yet:
   * the first time she goes to the chooser (HL-PROV-01, which carries `account: 'provider'` as its hint); afterwards, and for every
   * hotel or hall staff member, to Today.
   */
  const complete = (staff: HotelStaff | undefined) => {
    const flow = useAccessFlow.getState()
    const user = providerUser()
    if (flow.provider && user) {
      const store = usePrototype.getState()
      store.signIn({ id: user.id, name: (lang === 'ar' ? user.name : user.nameLatin) ?? user.name, phone: user.phone ?? '', monogram: user.monogram ?? '' })
      flow.setFailed(0)
      flow.setLockedAt(null)
      if (!flow.typeAsked) {
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
