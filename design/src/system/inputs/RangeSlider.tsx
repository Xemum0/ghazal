import { useRef, useState, type CSSProperties, type KeyboardEvent, type PointerEvent, type ReactNode } from 'react'
import { useFormat } from '../../i18n'
import { layoutScale } from '../core/layoutScale'
import { useControllable } from './internal/useControllable'
import { useInputWords } from './internal/copy'
import './internal/base.css'
import './range.css'

export type RangeValue = readonly [number, number]

export type RangeSliderProps = {
  min: number
  max: number
  step?: number
  value?: RangeValue
  defaultValue?: RangeValue
  onChange?: (value: [number, number]) => void
  /** Fires when a drag or a key press settles (use it to run the search). */
  onChangeEnd?: (value: [number, number]) => void
  /** Group name (`Venue and catering budget`). */
  label: string
  /** Names of the two handles for assistive tech. Default: Minimum / Maximum. */
  thumbLabels?: readonly [string, string]
  /** Captions above the two value labels. Default: the same words; pass `null` to hide them. */
  captions?: readonly [ReactNode, ReactNode] | null
  /** Visible value label (numeric voice). Default: the formatted integer. Money callers pass the shared formatter's parts. */
  formatValue?: (n: number, edge: 'min' | 'max') => ReactNode
  /** Plain-text value for screen readers (`KD 20,000`). Default: the formatted integer. */
  valueText?: (n: number, edge: 'min' | 'max') => string
  /** Labels under the two ends of the rail (`Under 5,000`, `35,000+`). */
  edgeLabels?: readonly [ReactNode, ReactNode]
  /** Least distance between the handles, in value units. Default 0 (they may meet, never cross). */
  minGap?: number
  disabled?: boolean
  className?: string
}

const snap = (n: number, min: number, max: number, step: number) => {
  const k = Math.round((n - min) / step)
  const decimals = (String(step).split('.')[1] ?? '').length
  return Math.min(max, Math.max(min, Number((min + k * step).toFixed(decimals))))
}

/**
 * Range slider (budget band, guest range). Two 24 px handles with 44 x 44 hit areas on a 4 px rail: ink-200 track, gold-500
 * fill between the handles (a gold LINE, direction 2.3 e). The rail is a flex row of three proportional segments, so it
 * mirrors by direction alone: the minimum sits at the inline-start (right in Arabic, ADR 0014 D2). Pointer drag, tap-to-move
 * the nearest handle, and full keyboard model (arrows follow what you see, PageUp / PageDown x10, Home / End). Value labels
 * above the rail use the numeric voice and are LTR islands; they never swap sides.
 */
export function RangeSlider(props: RangeSliderProps) {
  const f = useFormat()
  const w = useInputWords()
  const { min, max, step = 1, label, disabled, edgeLabels, minGap = 0 } = props
  const [value, setValue] = useControllable<RangeValue>(props.value, props.defaultValue ?? [min, max], props.onChange as ((v: RangeValue) => void) | undefined)
  const [lo, hi] = [Math.min(value[0], value[1]), Math.max(value[0], value[1])]
  const rail = useRef<HTMLDivElement>(null)
  const drag = useRef<0 | 1 | null>(null)
  const [dragging, setDragging] = useState<0 | 1 | null>(null)
  const span = Math.max(1, max - min)
  const thumbNames = props.thumbLabels ?? [w('minimum'), w('maximum')]
  const captions = props.captions === undefined ? ([w('minimum'), w('maximum')] as const) : props.captions
  const show = props.formatValue ?? ((n: number) => <bdi dir="ltr">{f.integer(n)}</bdi>)
  const say = props.valueText ?? ((n: number) => f.integer(n))

  const commit = (i: 0 | 1, raw: number, settle = false) => {
    const s = snap(raw, min, max, step)
    const next: [number, number] = i === 0 ? [Math.min(s, hi - minGap), hi] : [lo, Math.max(s, lo + minGap)]
    next[0] = Math.max(min, next[0])
    next[1] = Math.min(max, next[1])
    if (next[0] !== lo || next[1] !== hi) setValue(next)
    if (settle) props.onChangeEnd?.(next)
  }

  // Pointer to value. Positions are measured from the START edge, so Arabic needs no second formula.
  const valueAt = (clientX: number, i: 0 | 1) => {
    const el = rail.current
    if (!el) return lo
    const r = el.getBoundingClientRect()
    const rtl = getComputedStyle(el).direction === 'rtl'
    const thumb = el.querySelector<HTMLElement>('.gz-range__thumb')
    const tw = (thumb?.offsetWidth ?? 0) * layoutScale(el) // the rect is screen px; the thumb width is layout px
    const usable = Math.max(1, r.width - 2 * tw)
    const fromStart = rtl ? r.right - clientX : clientX - r.left
    const frac = (fromStart - tw * (i + 0.5)) / usable
    return min + Math.min(1, Math.max(0, frac)) * span
  }

  const nearest = (clientX: number): 0 | 1 => {
    const el = rail.current
    if (!el) return 0
    const thumbs = el.querySelectorAll<HTMLElement>('.gz-range__thumb')
    const d = (t: HTMLElement | undefined) => {
      if (!t) return Infinity
      const b = t.getBoundingClientRect()
      return Math.abs(clientX - (b.left + b.width / 2))
    }
    const d0 = d(thumbs[0])
    const d1 = d(thumbs[1])
    if (d0 === d1) return clientX < (thumbs[0]?.getBoundingClientRect().left ?? 0) ? 0 : 1
    return d0 < d1 ? 0 : 1
  }

  const down = (e: PointerEvent<HTMLDivElement>) => {
    if (disabled || e.button !== 0) return
    const hit = (e.target as HTMLElement).closest<HTMLElement>('.gz-range__thumb')
    const i = hit ? (Number(hit.dataset.i) as 0 | 1) : nearest(e.clientX)
    drag.current = i
    setDragging(i)
    e.currentTarget.setPointerCapture(e.pointerId)
    commit(i, valueAt(e.clientX, i))
    rail.current?.querySelectorAll<HTMLElement>('.gz-range__thumb')[i]?.focus()
  }
  const move = (e: PointerEvent<HTMLDivElement>) => {
    if (drag.current === null) return
    commit(drag.current, valueAt(e.clientX, drag.current))
  }
  const up = (e: PointerEvent<HTMLDivElement>) => {
    if (drag.current === null) return
    const i = drag.current
    drag.current = null
    setDragging(null)
    commit(i, valueAt(e.clientX, i), true)
  }

  const key = (e: KeyboardEvent<HTMLDivElement>, i: 0 | 1) => {
    if (disabled) return
    const rtl = getComputedStyle(e.currentTarget).direction === 'rtl'
    const cur = i === 0 ? lo : hi
    let to: number | null = null
    if (e.key === 'ArrowRight') to = cur + (rtl ? -step : step)
    else if (e.key === 'ArrowLeft') to = cur + (rtl ? step : -step)
    else if (e.key === 'ArrowUp') to = cur + step
    else if (e.key === 'ArrowDown') to = cur - step
    else if (e.key === 'PageUp') to = cur + step * 10
    else if (e.key === 'PageDown') to = cur - step * 10
    else if (e.key === 'Home') to = min
    else if (e.key === 'End') to = max
    if (to === null) return
    e.preventDefault()
    commit(i, to, true)
  }

  // Segment weights: whole numbers out of 1000 so flex-grow carries the proportion (no %, no calc).
  const g = (v: number) => ((v - min) / span) * 1000
  const style = { '--gz-in-a': g(lo), '--gz-in-b': g(hi) - g(lo), '--gz-in-c': 1000 - g(hi) } as CSSProperties

  const thumb = (i: 0 | 1) => {
    const v = i === 0 ? lo : hi
    const edge = i === 0 ? 'min' : 'max'
    return (
      <div
        className="gz-range__thumb"
        role="slider"
        tabIndex={disabled ? -1 : 0}
        data-i={i}
        data-active={dragging === i || undefined}
        aria-label={thumbNames[i]}
        aria-orientation="horizontal"
        aria-valuemin={i === 0 ? min : lo + minGap}
        aria-valuemax={i === 0 ? hi - minGap : max}
        aria-valuenow={v}
        aria-valuetext={say(v, edge)}
        aria-disabled={disabled || undefined}
        onKeyDown={e => key(e, i)}
      />
    )
  }

  return (
    <div className={['gz-range', props.className ?? ''].filter(Boolean).join(' ')} data-gz="RangeSlider" data-disabled={disabled || undefined} role="group" aria-label={label}>
      <div className="gz-range__values">
        {([lo, hi] as const).map((v, i) => (
          <div key={i} className="gz-range__value" data-edge={i === 0 ? 'start' : 'end'}>
            {captions ? <span className="gz-range__caption gz-t-caption">{captions[i]}</span> : null}
            <span className="gz-range__figure gz-t-fig-title">{show(v, i === 0 ? 'min' : 'max')}</span>
          </div>
        ))}
      </div>
      <div ref={rail} className="gz-range__rail" style={style} onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerCancel={up}>
        <span className="gz-range__line" aria-hidden="true" />
        <span className="gz-range__seg gz-range__seg--a" aria-hidden="true" />
        {thumb(0)}
        <span className="gz-range__seg gz-range__seg--fill" aria-hidden="true" />
        {thumb(1)}
        <span className="gz-range__seg gz-range__seg--c" aria-hidden="true" />
      </div>
      {edgeLabels ? (
        <div className="gz-range__edges gz-t-caption" aria-hidden="true">
          <span>{edgeLabels[0]}</span>
          <span>{edgeLabels[1]}</span>
        </div>
      ) : null}
    </div>
  )
}
