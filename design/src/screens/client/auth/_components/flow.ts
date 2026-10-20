// Flow-local state and helpers of the auth flow (CL-AUTH-01..05). Everything the five screens share that the prototype store does
// not carry: the number being verified, how deep the auth screens are stacked (so a finished sign-in can pop back to the screen that
// opened the gate), the result of an OTP that the password screen is waiting for, and the demo rules of the prototype.
// Nothing here is persisted; a reload is the story start.
import { create } from 'zustand'
import { useContext } from 'react'
import { useNavInternals } from '../../../../system/nav/NavProvider'
import { FrameContext } from '../../../../shell/frame'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype, type AuthUser, type GateReason } from '../../../../shell/state'
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
  /** Auth screens pushed on top of the screen that opened the gate. */
  depth: number
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
  setDepth: (depth: number) => void
  setOtpResult: (r: OtpResult) => void
  setAttempts: (n: number) => void
  reset: () => void
}

/** Opens the pre-prompt this long after the sign-in lands, so the person sees where they came back to first. */
export const BIO_PROMPT_DELAY_MS = 900

const initial = { phone: '', purpose: 'login' as OtpPurpose, depth: 0, otpResult: null as OtpResult, attempts: 0 }

export const useAuthFlow = create<AuthFlow>()(set => ({
  ...initial,
  bioOffered: false,
  bioEnabled: false,
  setBioOffered: bioOffered => set({ bioOffered }),
  setBioEnabled: bioEnabled => set({ bioEnabled }),
  setPhone: phone => set({ phone }),
  setPurpose: purpose => set({ purpose }),
  setDepth: depth => set({ depth: Math.max(0, depth) }),
  setOtpResult: otpResult => set({ otpResult }),
  setAttempts: attempts => set({ attempts }),
  reset: () => set({ ...initial }),
}))

// A session ends when the prototype goes back to guest (sign-out, or Restart in the launcher): the flow forgets everything with it.
usePrototype.subscribe((state, prev) => {
  if (state.auth === 'guest' && prev.auth === 'signedIn') useAuthFlow.setState({ ...initial, bioOffered: false, bioEnabled: false })
})

/** What the prototype shows when no params say otherwise: the shared story (a request to Aurelia on Thu 14 Jan 2027). */
export const DEFAULT_REASON: GateReason = 'send-request'

/** True in the player, false in a static frame (canvas, #/frame): timers and demo rules only run live. */
export const useLive = (): boolean => useDevice().mode === 'live'

/**
 * The reason the gate was opened for: a frame state (`ctx-<reason>`, `nudge`), then the sheet's own params. `null` is the plain
 * sign-in (onboarding "I have an account", an empty Bookings tab): no context line, nothing waiting. A static frame with no state
 * shows the shared story (a request to Aurelia) so the canvas has something to draw.
 */
export function useGateReason(): GateReason | null {
  const { params } = useNav<{ reason?: GateReason | null }>()
  const live = useLive()
  const { state } = useOptionalFrame()
  const fromState = state?.startsWith('ctx-') ? (state.slice(4) as GateReason) : state === 'nudge' ? 'save' : undefined
  return fromState ?? params.reason ?? (live ? null : DEFAULT_REASON)
}

/** useFrame() throws outside a frame route (the player); screens must also run there. */
export function useOptionalFrame(): { state: string | undefined } {
  const frame = useContext(FrameContext)
  return { state: frame?.state }
}

/** The signed-in user a verified number resolves to. */
export function userForPhone(national: string, name?: string): AuthUser {
  if (national === KNOWN_NATIONAL) return usePrototype.getState().user ?? { id: 'user-reem', name: 'ريم الدوسري', phone: '+96550000012', monogram: 'ر' }
  const display = name?.trim() || ''
  return { id: 'user-new', name: display, phone: national ? `+965${national}` : '', monogram: Array.from(display)[0]?.toUpperCase() ?? '' }
}

/**
 * Movement of the auth stack. `go` pushes an auth screen and counts it; `back` pops one; `finish` signs in, clears the gate and pops
 * every auth screen so the person lands on the screen that asked for the account (with their draft in the store, never lost).
 * Opened directly (no screen below) it lands on Discover instead.
 */
/** The navigator's own state, when there is one (the player); a static frame has none. */
function useStackReader(): () => Array<{ id: string }> {
  let read: () => Array<{ id: string }> = () => []
  try {
    const { state } = useNavInternals()
    read = () => state.stacks[state.active] ?? []
  } catch {
    // static frame: no navigator
  }
  return read
}

export function useAuthMoves() {
  const nav = useNav()
  const stack = useStackReader()
  const go = (id: string, params?: Record<string, unknown>) => {
    const s = useAuthFlow.getState()
    s.setDepth(s.depth + 1)
    nav.push(id, params)
  }
  const back = () => {
    const s = useAuthFlow.getState()
    s.setDepth(s.depth - 1)
    nav.pop()
  }
  const land = () => {
    const s = useAuthFlow.getState()
    const n = s.depth
    s.reset()
    const entries = stack()
    const base = entries[entries.length - 1 - n]
    // Signing in from onboarding ("I already have an account") leaves onboarding for Discover; anywhere else the person returns to
    // the screen that asked, now signed in.
    if (base?.id.startsWith('CL-ONBD') || n === 0 || !nav.canGoBack) nav.reset('CL-DISC-01')
    else nav.pop(n)
  }
  /** Signs in, lands back on the screen that asked, and (once per session) offers biometric unlock over it. */
  const finish = (user: AuthUser, message: string) => {
    const store = usePrototype.getState()
    store.signIn(user)
    store.clearGate()
    store.clearSignupNudge()
    land()
    nav.toast({ message, tone: 'success' })
    const flow = useAuthFlow.getState()
    if (!flow.bioOffered) {
      flow.setBioOffered(true)
      window.setTimeout(() => {
        nav.dismissToast()
        nav.openSheet('CL-AUTH-05', { params: { presentation: 'sheet', mode: 'pre-prompt' } })
      }, BIO_PROMPT_DELAY_MS)
    }
  }
  return { nav, go, back, land, finish }
}
