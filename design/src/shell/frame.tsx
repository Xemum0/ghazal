import { createContext, useContext } from 'react'

/** What a screen can know about the frame it is rendered in. Screens never read window.innerWidth (ADR 0024 D2). */
export type FrameState = {
  screenId: string
  /** ?state= (loading | empty | error | offline | ...). Undefined means the default data state. */
  state: string | undefined
  /** Frame width in dp (CSS px). 390 by default; 360 and 430 for the fluid checks. */
  width: number
}

export const FrameContext = createContext<FrameState | null>(null)

export function useFrame(): FrameState {
  const ctx = useContext(FrameContext)
  if (!ctx) throw new Error('useFrame() is only available inside a #/frame/<screenId> route')
  return ctx
}
