// What a Screen scaffold tells the bars around it. TopBar reads the scroll offset (hairline, large-title collapse, the
// transparent bar turning solid); nothing else in the system needs it.
import { createContext, useContext } from 'react'

export type ScreenScroll = { scrollTop: number }

export const ScreenScrollContext = createContext<ScreenScroll>({ scrollTop: 0 })
export const useScreenScroll = (): ScreenScroll => useContext(ScreenScrollContext)

// ---------------------------------------------------------------- bottom bars and tab re-tap

/** An ActionBar reports its height so floating toasts sit above it (the host owns the registry). */
export type BarInsetRegistry = { report: (key: string, height: number) => void; clear: (key: string) => void }
export const BarInsetContext = createContext<BarInsetRegistry | null>(null)

/** Bumped when the active tab is re-selected; the root Screen of that tab scrolls to top (ADR 0007 D5). */
export const ScrollTopSignalContext = createContext<number>(0)
