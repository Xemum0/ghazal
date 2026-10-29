// Flow-local state and helpers of the auth flow (CL-AUTH-01..05). Everything the five screens share that the prototype store does
// not carry: the number being verified, the result of an OTP that the password screen is waiting for, and the demo rules of the
// prototype. There is no guest mode (ADR 0038 D4): the sign-in is the first thing after the introduction, a finished sign-in resets
// the stack (a returning account lands on Home, a new one continues to the optional onboarding steps) and nothing is "resumed".
// Nothing here is persisted; a reload is the story start.
import { create } from 'zustand'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype, type AuthUser, type Sex } from '../../../../shell/state'
import { useNav } from '../../../../system'

/** Config values the screens read (ADR 0028 item 2, ADR 0012 D4): never typed into a message. */
export const OTP_LENGTH = 6
export const OTP_TTL_MINUTES = 5
export const RESEND_SECONDS = 60
export const MAX_ATTEMPTS = 5
export const PASSWORD_MIN = 8
export const LOCK_MINUTES = 15

/** The one account the prototype recognises as returning: Reem Al-Dosari (+965 5000 0012). Any other number is a new account. */
export const KNOWN_NATIONAL = '50000012'
/** Ghazal Support (fixture phone 0001), display only. */
export const SUPPORT_PHONE = '+96550000001'

export type OtpPurpose = 'login' | 'password-create' | 'password-reset' | 'booking'
export type OtpResult = 'create-verified' | 'reset-verified' | null

type AuthFlow = {
  /** National digits of the number the person typed. */
  phone: string
  purpose: OtpPurpose
  /** The password screen is waiting for this. */
  otpResult: OtpResult
  /** Failed code attempts in this verification. */
  attempts: number
  /** The biometric pre-prompt is offered once per session (CA-AUTH-08); Not now closes it for good. */
  bioOffered: boolean
  /** Biometric unlock is on for this phone (the Settings toggle, CL-PROF-05, reads the same truth in the prototype). */
  bioEnabled: boolean
  setBioOffered: (v: boolean) => void
  setBioEnabled: (v: boolean) => void
  setPhone: (phone: string) => void
  setPurpose: (purpose: OtpPurpose) => void
  setOtpResult: (r: OtpResult) => void
  setAttempts: (n: number) => void
  reset: () => void
}

/** Opens the pre-prompt this long after the sign-in lands, so the person sees where they came back to first. */
export const BIO_PROMPT_DELAY_MS = 900

const initial = { phone: '', purpose: 'login' as OtpPurpose, otpResult: null as OtpResult, attempts: 0 }

export const useAuthFlow = create<AuthFlow>()(set => ({
  ...initial,
  bioOffered: false,
  bioEnabled: false,
  setBioOffered: bioOffered => set({ bioOffered }),
  setBioEnabled: bioEnabled => set({ bioEnabled }),
  setPhone: phone => set({ phone }),
  setPurpose: purpose => set({ purpose }),
  setOtpResult: otpResult => set({ otpResult }),
  setAttempts: attempts => set({ attempts }),
  reset: () => set({ ...initial }),
}))

// A session ends when the prototype goes back to guest (sign-out, or Restart in the launcher): the flow forgets everything with it.
usePrototype.subscribe((state, prev) => {
  if (state.auth === 'guest' && prev.auth === 'signedIn') useAuthFlow.setState({ ...initial, bioOffered: false, bioEnabled: false })
})

/** True in the player, false in a static frame (canvas, #/frame): timers and demo rules only run live. */
export const useLive = (): boolean => useDevice().mode === 'live'

/** The signed-in user a verified number resolves to. */
export function userForPhone(national: string, name?: string, sex?: Sex): AuthUser {
  if (national === KNOWN_NATIONAL) return usePrototype.getState().user ?? { id: 'user-reem', name: 'ريم الدوسري', phone: '+96550000012', monogram: 'ر', sex: 'female' }
  const display = name?.trim() || ''
  return { id: 'user-new', name: display, phone: national ? `+965${national}` : '', monogram: Array.from(display)[0]?.toUpperCase() ?? '', ...(sex ? { sex } : {}) }
}

type Nav = ReturnType<typeof useNav>

/** Offers biometric unlock once per session (CA-AUTH-08), a moment after the person has landed somewhere calm. */
export function offerBiometrics(nav: Nav): void {
  const flow = useAuthFlow.getState()
  if (flow.bioOffered) return
  flow.setBioOffered(true)
  window.setTimeout(() => {
    nav.dismissToast()
    nav.openSheet('CL-AUTH-05', { params: { presentation: 'sheet', mode: 'pre-prompt' } })
  }, BIO_PROMPT_DELAY_MS)
}

/**
 * Movement of the auth screens. `go` pushes one, `back` pops one, `finish` signs in and resets the stack: a returning account lands on
 * Home and is offered biometric unlock; a new account (`fresh`) continues to the optional onboarding steps (CL-ONBD-03 to 05), and the
 * offer waits for the end of them.
 */
export function useAuthMoves() {
  const nav = useNav()
  const go = (id: string, params?: Record<string, unknown>) => nav.push(id, params)
  const back = () => nav.pop()
  const finish = (user: AuthUser, message: string | null, opts: { fresh?: boolean } = {}) => {
    usePrototype.getState().signIn(user)
    useAuthFlow.getState().reset()
    nav.reset(opts.fresh ? 'CL-ONBD-03' : 'CL-DISC-01')
    if (message) nav.toast({ message, tone: 'success' })
    if (!opts.fresh) offerBiometrics(nav)
  }
  return { nav, go, back, finish }
}
