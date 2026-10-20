// PullIndicator and PullToRefresh. Pending is the OS activity indicator only (direction 2.7: no looping thread loader), so the
// indicator is a plain 24 ring: while pulling its arc grows with the pull (determinate); once released past the threshold it turns
// with the platform's rhythm until the host says it is done. Under reduced motion it holds still as a full ring. The content
// follows the finger with resistance and the settle spring (ADR 0017) brings it home.
import { useCallback, useRef, useState, type PointerEvent, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { layoutScale } from '../core/layoutScale'
import { useT } from '../../i18n'
import { cx } from '../core/cx'
import { springTo, type SpringHandle } from './spring'
import './pull.css'

/** Pull distance at which a release refreshes: 64 (space.16). The indicator sits in that band. */
const THRESHOLD = flat['space.16']
const RESIST = 0.5

const RADIUS = 9
const CIRCUMFERENCE = 2 * Math.PI * RADIUS

export type PullIndicatorProps = {
  /** 0 to 1: how far the pull is toward the threshold. */
  progress: number
  refreshing?: boolean
}

export function PullIndicator({ progress, refreshing = false }: PullIndicatorProps) {
  const t = useT('common')
  const shown = refreshing ? 0.75 : Math.min(Math.max(progress, 0), 1) * 0.75
  return (
    <span className={cx('gz-pull', refreshing && 'is-refreshing')} data-gz="PullIndicator" role="status" aria-label={refreshing ? t('commonStateLoading') : undefined}>
      <svg className="gz-pull__ring" viewBox="0 0 24 24" width="24" height="24" fill="none" aria-hidden="true">
        <circle className="gz-pull__track" cx="12" cy="12" r={RADIUS} />
        <circle
          className="gz-pull__arc"
          cx="12"
          cy="12"
          r={RADIUS}
          strokeDasharray={`${CIRCUMFERENCE * shown} ${CIRCUMFERENCE}`}
          transform="rotate(-90 12 12)"
        />
      </svg>
    </span>
  )
}

export type PullToRefreshProps = {
  /** Called on a release past the threshold; the host resolves it (a Promise) when the data is fresh. */
  onRefresh: () => Promise<unknown> | void
  children: ReactNode
}

/** Wraps scrollable content. Only a pull that starts with the scroller at the top engages; a vertical scroll is never hijacked. */
export function PullToRefresh({ onRefresh, children }: PullToRefreshProps) {
  const [pull, setPull] = useState(0)
  const [refreshing, setRefreshing] = useState(false)
  const root = useRef<HTMLDivElement>(null)
  const state = useRef<{ y0: number; id: number; engaged: boolean } | null>(null)
  const spring = useRef<SpringHandle | null>(null)

  const settle = useCallback((from: number, to: number, velocity = 0) => {
    spring.current?.cancel()
    spring.current = springTo(from, to, velocity, v => setPull(v), () => setPull(to))
  }, [])

  const scroller = () => {
    // The nearest scroll container above: the Screen body.
    let el: HTMLElement | null = root.current
    while (el && el.scrollHeight <= el.clientHeight && el.parentElement) el = el.parentElement
    return el
  }

  const down = (e: PointerEvent<HTMLDivElement>) => {
    if (refreshing || e.button !== 0) return
    const atTop = (scroller()?.scrollTop ?? 0) <= 0
    if (atTop) state.current = { y0: e.clientY, id: e.pointerId, engaged: false }
  }
  const move = (e: PointerEvent<HTMLDivElement>) => {
    const s = state.current
    if (!s || s.id !== e.pointerId) return
    const dy = (e.clientY - s.y0) / layoutScale(e.currentTarget) // screen px to layout px
    if (!s.engaged) {
      if (dy < flat['space.2']) return
      s.engaged = true
      spring.current?.cancel()
      e.currentTarget.setPointerCapture(e.pointerId)
    }
    setPull(Math.max(0, dy * RESIST))
  }
  const up = (e: PointerEvent<HTMLDivElement>) => {
    const s = state.current
    if (!s || s.id !== e.pointerId) return
    state.current = null
    if (!s.engaged) return
    if (pull >= THRESHOLD) {
      setRefreshing(true)
      settle(pull, THRESHOLD)
      Promise.resolve(onRefresh()).finally(() => {
        setRefreshing(false)
        settle(THRESHOLD, 0)
      })
    } else {
      settle(pull, 0)
    }
  }

  return (
    <div ref={root} className="gz-ptr" data-gz="PullToRefresh" onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerCancel={up}>
      <div className="gz-ptr__indicator" style={{ blockSize: pull }}>
        <PullIndicator progress={pull / THRESHOLD} refreshing={refreshing} />
      </div>
      {children}
    </div>
  )
}
