// The Compare tray mounted on a tab screen (ADR 0009 D3): floating 16 above the tab bar, rising once, collapsing to the 44 pill after three
// idle seconds and when the list scrolls down, returning on scroll-up or a tap on the pill. It is a zero-height slot under the screen
// body, so it never changes the layout above it. In a static frame nothing times out: the frame shows the state it is told to.
import { useEffect, useRef, useState } from 'react'
import { getVenue, type Venue } from '../../../../mock'
import { useDevice } from '../../../../shell/device'
import { CompareTray } from '../../../../system'
import './tray-layer.css'

const IDLE_MS = 3000
const SCROLL_STEP = 8

export type TrayLayerProps = {
  ids: readonly string[]
  /** Static frames: draw the pill. */
  collapsed?: boolean
  onOpen: () => void
  onRemove: (id: string) => void
  onClear: () => void
}

export function TrayLayer({ ids, collapsed: forced = false, onOpen, onRemove, onClear }: TrayLayerProps) {
  const live = useDevice().mode === 'live'
  const slot = useRef<HTMLDivElement>(null)
  const [idle, setIdle] = useState(false)
  const venues = ids.map(id => getVenue(id)).filter((v): v is Venue => Boolean(v))
  const key = ids.join('|')

  // Any change of the set wakes the tray, then three idle seconds put it to sleep.
  useEffect(() => {
    if (!live) return
    setIdle(false)
    const id = window.setTimeout(() => setIdle(true), IDLE_MS)
    return () => window.clearTimeout(id)
  }, [live, key])

  // Scroll down: collapse; scroll up: return. The scroller is the screen body that holds this slot.
  useEffect(() => {
    if (!live) return
    const body = slot.current?.closest<HTMLElement>('.gz-screen')?.querySelector<HTMLElement>('.gz-screen__body')
    if (!body) return
    let last = body.scrollTop
    const onScroll = () => {
      const next = body.scrollTop
      if (next > last + SCROLL_STEP) setIdle(true)
      else if (next < last - SCROLL_STEP) setIdle(false)
      last = next
    }
    body.addEventListener('scroll', onScroll, { passive: true })
    return () => body.removeEventListener('scroll', onScroll)
  }, [live])

  if (venues.length === 0) return null
  return (
    <div ref={slot} className="svd-trayslot" data-gz-id="trayslot">
      <CompareTray
        floating
        venues={venues}
        collapsed={forced || idle}
        onOpen={onOpen}
        onRemove={onRemove}
        onClear={onClear}
        onExpand={() => setIdle(false)}
      />
    </div>
  )
}
