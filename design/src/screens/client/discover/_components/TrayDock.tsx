// TrayDock: the Compare tray where Discover mounts it (Home and Results, ADR 0009 D3). The anti-nag rules live here:
//   - it appears only when the set holds something, and only an add made in this session opens it; a set that was already there when the
//     screen opened (saved earlier, merged on sign-in) starts as the 44 pill, because it is not news;
//   - with one hall it says "Add one more to compare" and nothing is actionable; with two or three it is "Compare (n)";
//   - it collapses to the pill after three idle seconds and when the list scrolls down, and returns when the list scrolls up;
//   - `inFlow` (Home): the dock takes its own height under the scroll body instead of floating over it, so the tray never covers the status card;
//   - "Clear" empties the set and the tray does not come back until the next add; it never pushes a notification.
import { useEffect, useRef, useState, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { CompareTray, useNav } from '../../../../system'
import * as mock from '../../../../mock'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import { useScreenScroll } from '../../../../system/nav/screen-context'
import type { Scenario } from './scenario'
import './tray-dock.css'

/** Interaction timing, not animation: three idle seconds (ADR 0009 D3). */
const IDLE_MS = 3000
const SCROLL_STEP = flat['space.4']

export function TrayDock({ scenario, forceCollapsed, inFlow, children }: { scenario: Scenario; forceCollapsed?: boolean; inFlow?: boolean; children?: ReactNode }) {
  const nav = useNav()
  const live = useDevice().mode === 'live'
  const { scrollTop } = useScreenScroll()
  const ids = scenario.compare
  const [open, setOpen] = useState(() => (live ? false : !forceCollapsed))
  const last = useRef({ top: scrollTop, count: ids.length })
  const idle = useRef<number | null>(null)

  const arm = () => {
    if (idle.current !== null) window.clearTimeout(idle.current)
    idle.current = window.setTimeout(() => setOpen(false), IDLE_MS)
  }
  useEffect(() => () => {
    if (idle.current !== null) window.clearTimeout(idle.current)
  }, [])

  // An add in this session opens the tray and starts the idle clock; a removal leaves it as it is.
  useEffect(() => {
    if (!live) return
    if (ids.length > last.current.count) {
      setOpen(true)
      arm()
    }
    last.current.count = ids.length
  }, [ids.length, live])

  // Scrolling the list down collapses the tray, scrolling up brings it back (only when there is a set).
  useEffect(() => {
    if (!live) return
    const delta = scrollTop - last.current.top
    if (Math.abs(delta) < SCROLL_STEP) return
    last.current.top = scrollTop
    if (ids.length === 0) return
    if (delta > 0) setOpen(false)
    else {
      setOpen(true)
      arm()
    }
  }, [scrollTop, live, ids.length])

  if (ids.length === 0 && !children) return null
  const venues = ids.map(id => mock.getVenue(id)).filter((v): v is NonNullable<ReturnType<typeof mock.getVenue>> => Boolean(v))
  const collapsed = live ? !open : Boolean(forceCollapsed)
  const store = () => usePrototype.getState()

  return (
    <div className={`gzd-dock${inFlow ? ' gzd-dock--flow' : ''}`} data-gz-id="dock">
      <div className="gzd-dock__stack">
        {children}
        {venues.length > 0 ? (
          <CompareTray
            venues={venues}
            collapsed={collapsed}
            className="gzd-dock__tray"
            onOpen={() => nav.push('CL-SAVD-04', { from: 'discover' })}
            onRemove={id => live && store().removeFromCompare(id)}
            onClear={() => live && store().clearCompare()}
            onExpand={() => {
              setOpen(true)
              arm()
            }}
          />
        ) : null}
      </div>
    </div>
  )
}
