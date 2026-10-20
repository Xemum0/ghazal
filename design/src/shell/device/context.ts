// Leaf module of the device framework: contexts and hooks shared by the Device, the Navigator and the system components.
// It imports nothing from system/ or from the rest of shell/, so every layer can depend on it without a cycle.
import { createContext, useContext, useEffect, useId } from 'react'

export type DeviceMode = 'static' | 'live'
/** `status` draws the status bar (47) and the home indicator (34) and provides those safe areas; `none` draws neither (splash, full-bleed media). */
export type DeviceChrome = 'status' | 'none'
/** Content colour of the system chrome: `dark` = ink glyphs on a light surface, `light` = canvas glyphs over imagery or an ink panel. */
export type ChromeTone = 'dark' | 'light'
export type AppKind = 'client' | 'hotel'

export type DeviceInfo = {
  /** Frame size in dp. Width is fluid 360 to 430; height is 844 unless the frame grows with its content (`autoHeight`). */
  width: number
  height: number
  autoHeight: boolean
  mode: DeviceMode
  chrome: DeviceChrome
  /** Resolved safe areas in dp: 47 / 34 with the status chrome, 0 / 0 without. Also published as --gz-safe-top / --gz-safe-bottom. */
  safeTop: number
  safeBottom: number
}

const DEFAULT_DEVICE: DeviceInfo = {
  width: 390,
  height: 844,
  autoHeight: false,
  mode: 'static',
  chrome: 'status',
  safeTop: 47,
  safeBottom: 34,
}

export const DeviceContext = createContext<DeviceInfo>(DEFAULT_DEVICE)

/** Size, mode and safe areas of the frame a component is drawn in. Components never read window.innerWidth (ADR 0024 D2). */
export const useDevice = (): DeviceInfo => useContext(DeviceContext)

/** Which of the two apps is drawn. Only a few components differ (large title face, density); the system is one. */
export const AppContext = createContext<AppKind>('client')
export const useAppKind = (): AppKind => useContext(AppContext)

// ---------------------------------------------------------------- status-bar tone

export type ToneRegistry = {
  /** Register a screen's wish for the chrome tone; returns the unregister function. Later registrations win. */
  register: (id: string, tone: ChromeTone) => () => void
}

export const ToneContext = createContext<ToneRegistry | null>(null)

/** True for the layer that is currently on top and settled; lower layers and exiting layers do not drive the chrome. */
export const LayerActiveContext = createContext<boolean>(true)

/**
 * A screen that draws imagery or an ink panel under the status bar asks for light chrome: `useStatusTone('light')`.
 * Only the active layer registers, so a pop gives the tone back to the screen that is revealed. TopBar does this for
 * its transparent variant; most screens never call it.
 */
export function useStatusTone(tone: ChromeTone | undefined, enabled = true): void {
  const id = useId()
  const registry = useContext(ToneContext)
  const active = useContext(LayerActiveContext)
  useEffect(() => {
    if (!registry || !tone || !enabled || !active) return
    return registry.register(id, tone)
  }, [registry, id, tone, enabled, active])
}

// ---------------------------------------------------------------- bottom bars

/**
 * What sits under the screen's bottom edge. ActionBar adds the home-indicator inset only when nothing below already does
 * (venue details: the CTA bar replaces the tab bar; hotel save bars sit above the tab bar, so they add none).
 */
export type BottomChrome = { tabBar: boolean }
export const BottomChromeContext = createContext<BottomChrome>({ tabBar: false })
export const useBottomChrome = (): BottomChrome => useContext(BottomChromeContext)
