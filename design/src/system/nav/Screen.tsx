// Screen: the scaffold a screen draws itself in (Flutter: Scaffold). A TopBar above, a scrolling body, an ActionBar below.
// The bars are flex items, not sticky positioning, so they translate to Scaffold.appBar / bottomNavigationBar directly; the body is
// the one scroll container (hidden scrollbar) and reports its offset to the bars (hairline, large-title collapse, transparent -> solid).
// A transparent TopBar (over a hero) overlays the body instead of sitting above it.
import { useContext, useEffect, useRef, useState, type ReactNode } from 'react'
import { LayerActiveContext } from '../../shell/device/context'
import { cx } from '../core/cx'
import { ScreenScrollContext, ScrollTopSignalContext } from './screen-context'
import './screen.css'

export type ScreenProps = {
  /** A <TopBar />. */
  top?: ReactNode
  /** Draw `top` over the body (transparent bar over a photograph) instead of above it. */
  topOverlay?: boolean
  /** An <ActionBar /> (or any pinned footer). */
  bottom?: ReactNode
  children?: ReactNode
  /** Extra class for the scrolling body (screens add their own layout, never their own scroller). */
  bodyClassName?: string
  /** The body does not scroll (a map, a chat composer owns the scroll below it). */
  fixed?: boolean
}

export function Screen({ top, topOverlay, bottom, children, bodyClassName, fixed }: ScreenProps) {
  const [scrollTop, setScrollTop] = useState(0)
  const bodyRef = useRef<HTMLDivElement>(null)
  const signal = useContext(ScrollTopSignalContext)
  const active = useContext(LayerActiveContext)
  const seen = useRef(signal)

  useEffect(() => {
    if (signal === seen.current) return
    seen.current = signal
    if (!active) return
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    bodyRef.current?.scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' })
  }, [signal, active])

  return (
    <ScreenScrollContext.Provider value={{ scrollTop }}>
      <div className="gz-screen" data-gz="Screen">
        {top && !topOverlay ? top : null}
        <div className="gz-screen__main">
          {top && topOverlay ? top : null}
          <div
            ref={bodyRef}
            className={cx('gz-screen__body gz-no-scrollbar', fixed && 'gz-screen__body--fixed', bodyClassName)}
            onScroll={e => setScrollTop(Math.round(e.currentTarget.scrollTop))}
          >
            {children}
          </div>
        </div>
        {bottom}
      </div>
    </ScreenScrollContext.Provider>
  )
}
