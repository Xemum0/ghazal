// Pager: a horizontal pager whose geometry is a formula, not a measurement (ADR 0024 D2): item width = frame width - 2 x gutter - peek,
// peek = space.6; or the full frame width (`full`, heroes and the gallery viewer). Flutter: PageView(viewportFraction). No scroll-snap:
// the track is a transform, dragged with pointer events and settled over 320 ms ease-emph; at the ends it resists. The first page sits
// at inline-start (the right in Arabic) and the track runs in reading direction, so a drag toward the next page flips with `dir`.
import { Children, useCallback, useRef, useState, type KeyboardEvent, type PointerEvent, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { layoutScale } from '../core/layoutScale'
import { useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { useDevice } from '../../shell/device/context'
import { cx } from '../core/cx'
import './pager.css'

const GUTTER = flat['space.gutter']
const PEEK = flat['space.6']
const GAP = flat['space.3']
const RESIST = 0.3
const FLICK = 500
const COMMIT_SHARE = 0.2

/** Width of one page for a frame of `frameWidth` dp: the shared formula (CSS and Flutter's viewportFraction read the same numbers). */
export const pagerItemWidth = (frameWidth: number, mode: 'full' | 'peek'): number => (mode === 'full' ? frameWidth : frameWidth - 2 * GUTTER - PEEK)

export type PagerProps = {
  children: ReactNode
  mode?: 'full' | 'peek'
  index?: number
  defaultIndex?: number
  onIndexChange?: (index: number) => void
  /** Accessible name of the carousel region. */
  label: string
  /** Override the frame width (specimens outside a Device). */
  width?: number
  className?: string
}

export function Pager({ children, mode = 'full', index, defaultIndex = 0, onIndexChange, label, width, className }: PagerProps) {
  const t = useT('common')
  const { isRtl } = useLang()
  const device = useDevice()
  const frame = width ?? device.width
  const pages = Children.toArray(children)
  const count = pages.length
  const [inner, setInner] = useState(defaultIndex)
  const current = Math.min(Math.max(index ?? inner, 0), Math.max(0, count - 1))
  const [dragging, setDragging] = useState(false)
  const [dx, setDx] = useState(0)
  const drag = useRef<{ x0: number; last: number; t: number; v: number; id: number } | null>(null)

  const itemWidth = pagerItemWidth(frame, mode)
  const gap = mode === 'peek' ? GAP : 0
  const pad = mode === 'peek' ? GUTTER : 0
  const step = itemWidth + gap
  // Total track = pad + pages + gaps + pad; the last page rests with its far edge on the gutter.
  const total = pad + count * itemWidth + Math.max(0, count - 1) * gap + pad
  const maxOffset = Math.max(0, total - frame)
  const offsetOf = (i: number) => Math.min(i * step, maxOffset)
  // Reading direction: the track starts at inline-start, so the next page lies further toward inline-end.
  const sign = isRtl ? 1 : -1

  const go = useCallback(
    (next: number) => {
      const clamped = Math.min(Math.max(next, 0), count - 1)
      if (index === undefined) setInner(clamped)
      if (clamped !== current) onIndexChange?.(clamped)
    },
    [count, current, index, onIndexChange],
  )

  const onDown = (e: PointerEvent<HTMLDivElement>) => {
    if (e.button !== 0 || count < 2) return
    drag.current = { x0: e.clientX, last: e.clientX, t: e.timeStamp, v: 0, id: e.pointerId }
  }
  const onMove = (e: PointerEvent<HTMLDivElement>) => {
    const d = drag.current
    if (!d || d.id !== e.pointerId) return
    // Pointer deltas are screen px, the track moves in layout px: undo the phone's scale (Launcher, Studio zoom).
    const k = layoutScale(e.currentTarget)
    const raw = (e.clientX - d.x0) / k
    if (!dragging) {
      if (Math.abs(raw) < flat['space.1']) return
      e.currentTarget.setPointerCapture(e.pointerId)
      setDragging(true)
    }
    const dt = Math.max(1, e.timeStamp - d.t)
    d.v = (((e.clientX - d.last) / k) / dt) * 1000
    d.last = e.clientX
    d.t = e.timeStamp
    // Resist at the ends: toward "before the first" or "after the last".
    const towardNext = (isRtl ? raw > 0 : raw < 0) ? 1 : -1
    const atEnd = (towardNext === 1 && current === count - 1) || (towardNext === -1 && current === 0)
    setDx(atEnd ? raw * RESIST : raw)
  }
  const onUp = (e: PointerEvent<HTMLDivElement>) => {
    const d = drag.current
    if (!d || d.id !== e.pointerId) return
    drag.current = null
    if (!dragging) return
    setDragging(false)
    const raw = (e.clientX - d.x0) / layoutScale(e.currentTarget)
    const toward = isRtl ? raw > 0 : raw < 0
    const velTowardNext = isRtl ? d.v : -d.v
    const commit = Math.abs(raw) > step * COMMIT_SHARE || Math.abs(d.v) > FLICK
    setDx(0)
    if (commit) go(current + (toward || velTowardNext > FLICK ? 1 : -1))
  }
  const onKey = (e: KeyboardEvent<HTMLDivElement>) => {
    const next = (e.key === 'ArrowRight') !== isRtl
    if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
      e.preventDefault()
      go(current + (next ? 1 : -1))
    }
  }

  const shift = sign * offsetOf(current) + dx

  return (
    <div
      className={cx('gz-pager', className)}
      data-gz="Pager"
      data-mode={mode}
      role="group"
      aria-roledescription="carousel"
      aria-label={label}
      tabIndex={0}
      onKeyDown={onKey}
      onPointerDown={onDown}
      onPointerMove={onMove}
      onPointerUp={onUp}
      onPointerCancel={onUp}
    >
      <div
        className={cx('gz-pager__track', dragging && 'is-dragging')}
        style={{ paddingInlineStart: pad, paddingInlineEnd: pad, columnGap: gap, transform: `translateX(${shift}px)` }}
      >
        {pages.map((page, i) => (
          <div
            key={i}
            className="gz-pager__page"
            role="group"
            aria-roledescription="slide"
            aria-label={t('commonCounter', { current: i + 1, total: count })}
            aria-hidden={i === current ? undefined : true}
            style={{ inlineSize: itemWidth }}
          >
            {page}
          </div>
        ))}
      </div>
    </div>
  )
}

export type PagerProgressProps = {
  count: number
  index: number
  /** on-photo: rule-on-photo track (hero, viewer); on-canvas: hairline track. */
  tone?: 'on-photo' | 'on-canvas'
}

/** Hairline progress with a gold fill and a bead (direction section 5): flex ratios, no widths, no calc. Follows `dir`. */
export function PagerProgress({ count, index, tone = 'on-photo' }: PagerProgressProps) {
  const done = Math.min(Math.max(index + 1, 0), count)
  return (
    <div className={cx('gz-progress', `gz-progress--${tone}`)} data-gz="PagerProgress" aria-hidden="true">
      <span className="gz-progress__fill" style={{ flexGrow: done }} />
      <span className="gz-progress__bead" />
      <span className="gz-progress__rest" style={{ flexGrow: Math.max(count - done, 0) }} />
    </div>
  )
}
