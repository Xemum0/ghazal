// How a payment screen knows what to draw and whether time moves.
//   useSceneState  the state to show: `?state=` in a static frame (canvas, shots), `state` in the navigator params in the player
//   useLive        true only in the live prototype: timers tick and transient screens move on by themselves; a static frame never does
//   useTick        seconds elapsed since mount, live only (the countdown), 0 in a static frame so shots are deterministic
//   useAfter       run once after a delay, live only
import { useContext, useEffect, useRef, useState } from 'react'
import { useDevice } from '../../../../shell/device/context'
import { FrameContext } from '../../../../shell/frame'
import { useNav } from '../../../../system'

export function useSceneState(): string | undefined {
  const frame = useContext(FrameContext)
  const nav = useNav()
  const fromNav = nav.params.state
  return frame?.state ?? (typeof fromNav === 'string' ? fromNav : undefined)
}

export const useLive = (): boolean => useDevice().mode === 'live'

export function useTick(enabled = true): number {
  const live = useLive()
  const [s, setS] = useState(0)
  useEffect(() => {
    if (!live || !enabled) return
    const id = window.setInterval(() => setS(v => v + 1), 1000)
    return () => window.clearInterval(id)
  }, [live, enabled])
  return s
}

export function useAfter(ms: number, run: () => void, enabled = true): void {
  const live = useLive()
  const fn = useRef(run)
  fn.current = run
  useEffect(() => {
    if (!live || !enabled) return
    const id = window.setTimeout(() => fn.current(), ms)
    return () => window.clearTimeout(id)
  }, [live, enabled, ms])
}

/** The reading of the platform the player draws: iOS unless the URL asks for Android (`?platform=android`). */
export function usePlatform(): 'ios' | 'android' {
  const nav = useNav()
  const fromNav = nav.params.platform
  const frame = useContext(FrameContext)
  if (frame?.state === 'android') return 'android'
  return fromNav === 'android' ? 'android' : 'ios'
}

/** Entrances (khayt, thread) draw when first seen in the player; a static frame shows the finished line. */
export const useDraw = (): 'inview' | false => (useLive() ? 'inview' : false)
