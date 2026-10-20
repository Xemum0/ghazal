// PrototypePlayer: the live prototype. A Device in live mode (thin bezel by default) around a NavRoot, with the prototype store bridged
// to the URL language. `story` seeds the store: `start` (guest, nothing chosen) or a persona loaded from the shared fixtures.
import { useLayoutEffect } from 'react'
import { NavRoot, type NavRootProps } from '../../system/nav/NavRoot'
import { usePrototype, useLanguageBridge } from '../state'
import type { AppKind } from './context'
import { Device } from './Device'

export type Story = 'start' | 'client' | 'hotel'

export type PrototypePlayerProps = {
  app: AppKind
  /** First screen (inventory id). A tab root enters the tab host; anything else is a flow outside it. */
  initial?: string
  initialTab?: string
  story?: Story
  /** Seed the prototype store on mount (default). The Launcher passes false when switching apps so the client's choices survive. */
  seed?: boolean
  width?: number
  height?: number
  bezel?: 'none' | 'thin'
  /** `none` on a real phone: the device already has its own status bar and home indicator. */
  chrome?: 'status' | 'none'
  screens?: NavRootProps['screens']
}

/** What the story starts on, by app (the first screen of the first flow in the inventory). */
export const STORY_START: Record<AppKind, string> = { client: 'CL-ONBD-01', hotel: 'HL-ACCS-01' }

export function PrototypePlayer({ app, initial, initialTab, story = 'start', seed = true, width, height, bezel = 'thin', chrome, screens }: PrototypePlayerProps) {
  useLanguageBridge()
  // Seed the store before the first paint; a remount (key change) re-seeds it, which is how "Restart" works.
  useLayoutEffect(() => {
    if (!seed) return
    const s = usePrototype.getState()
    if (story === 'start') s.resetToStoryStart()
    else s.loadStory(story)
  }, [story, seed])

  return (
    <Device mode="live" app={app} width={width} height={height} bezel={bezel} chrome={chrome} label={`${app} prototype`}>
      <NavRoot app={app} initial={initial ?? STORY_START[app]} initialTab={initialTab} screens={screens} />
    </Device>
  )
}
