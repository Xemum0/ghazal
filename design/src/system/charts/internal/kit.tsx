// Shared parts of the charts (ADR 0014 D5, direction 2.7). Charts are SVG or flex boxes drawn from tokens only; no chart library.
//   - measure: the plot reads its own inline size (ResizeObserver) and draws in real px, so strokes and dots never distort
//   - niceTicks: the three value-axis ticks (0, mid, max) on round numbers
//   - Reveal: draw / grow ONCE when the chart first scrolls into view (reduced motion keeps the finished chart)
//   - ChartTable: the table twin every chart carries for assistive technology (and `showTable` shows it)
//   - direction: time and ordinal axes run in reading direction, the value axis never flips (ADR 0014 D5)
import { useId, useLayoutEffect, useRef, useState, type ReactNode, type RefObject } from 'react'
import { flat } from '@gz/tokens'
import { useRevealOnce } from '../../core/useRevealOnce'
import { cx } from '../../core/cx'
import { useLang } from '../../../shell/lang'
import './chart.css'

/** The inline size of an element in px, re-measured on resize and once the fonts are in. 0 until the first measurement. */
export function useInlineSize<T extends HTMLElement>(): [RefObject<T | null>, number] {
  const ref = useRef<T | null>(null)
  const [width, setWidth] = useState(0)
  useLayoutEffect(() => {
    const node = ref.current
    if (!node) return
    const measure = () => setWidth(node.offsetWidth) // layout px: unaffected by a scaled phone
    measure()
    const ro = new ResizeObserver(measure)
    ro.observe(node)
    void document.fonts?.ready.then(measure)
    return () => ro.disconnect()
  }, [])
  return [ref, width]
}

/** The next round step (1, 1.5, 2, 2.5, 3, 4, 5, 6, 8 x 10^n) at or above `raw`: ticks read 0 / 30 / 60, never 0 / 50 / 100 for a 54 maximum. */
function niceCeil(raw: number): number {
  if (raw <= 0) return 1
  const pow = 10 ** Math.floor(Math.log10(raw))
  const f = raw / pow
  const step = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10].find(m => f <= m) ?? 10
  return step * pow
}

/** Three value-axis ticks `[0, step, 2 x step]`; `max` is the last tick, so the tallest value always fits. */
export function niceTicks(dataMax: number): { ticks: [number, number, number]; max: number } {
  const step = niceCeil(Math.max(dataMax, 1) / 2)
  return { ticks: [0, step, step * 2], max: step * 2 }
}

/** Evenly spaced sample indexes for the explicit axis labels (first and last always included). */
export function labelIndexes(count: number, labels: number): number[] {
  if (count <= 1) return [0]
  const k = Math.max(2, Math.min(labels, count))
  return Array.from({ length: k }, (_, i) => Math.round((i * (count - 1)) / (k - 1)))
}

/**
 * Reveal wrapper: `is-armed` hides the marks until the chart first enters the viewport, then `is-in` plays the draw / grow once.
 * `animate = false` renders the finished chart at once.
 */
export function Reveal({ animate = true, className, children, ...rest }: { animate?: boolean; className?: string; children: ReactNode } & Record<string, unknown>) {
  const [ref, seen] = useRevealOnce<HTMLDivElement>(animate)
  return (
    <div ref={ref} className={cx(className, animate && (seen ? 'is-in' : 'is-armed'))} {...rest}>
      {children}
    </div>
  )
}

/** Time and ordinal axes read in reading direction: earliest first at the inline-start, which is the right edge in Arabic. */
export function useReadingOrder() {
  const { isRtl } = useLang()
  return { isRtl, /** Index of the i-th point counted from the physical left edge. */ physical: <T,>(items: readonly T[]): T[] => (isRtl ? [...items].reverse() : [...items]) }
}

export type TableTwin = {
  caption: string
  /** First header cell (the axis), then one per series. */
  headers: string[]
  rows: string[][]
}

/** The table twin: read by assistive technology always, visible on request (`show`). Cells are LTR isolates (numbers, dates). */
export function ChartTable({ twin, show = false }: { twin: TableTwin; show?: boolean }) {
  const table = (
    <table className={cx('gz-chart-table', show && 'gz-chart-table--shown gz-t-caption')}>
      <caption className="gz-chart-table__caption">{twin.caption}</caption>
      <thead>
        <tr>
          {twin.headers.map((h, i) => (
            <th key={i} scope="col">
              {h}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {twin.rows.map((row, r) => (
          <tr key={r}>
            {row.map((cell, c) =>
              c === 0 ? (
                <th key={c} scope="row">
                  <bdi dir="ltr">{cell}</bdi>
                </th>
              ) : (
                <td key={c}>
                  <bdi dir="ltr" className="gz-num">
                    {cell}
                  </bdi>
                </td>
              ),
            )}
          </tr>
        ))}
      </tbody>
    </table>
  )
  // A table ignores width and overflow, so the visually hidden twin sits in a clipped box (a bare sr-only table would widen the page).
  return show ? table : <div className="gz-sr-only">{table}</div>
}

/** Accessible name + description of a chart: `role="img"` with a title and a long description by reference. */
export function useChartIds() {
  const uid = useId().replace(/:/g, '')
  return { titleId: `${uid}t`, descId: `${uid}d`, patternId: `${uid}p` }
}

/** Hatch and dot fills: SVG `<pattern>` defs (Flutter: a CustomPainter shader). A pattern, not a colour, carries the category. */
export type FillPattern = 'solid' | 'hatch' | 'dots' | 'cross'

const PITCH = flat['size.chart.pattern-pitch']
const HALF = PITCH / 2
const DOT = flat['stroke.icon']
const LINE = flat['stroke.thread']

const TONES = ['ink', 'gold'] as const
export type PatternTone = (typeof TONES)[number]

export function PatternDefs({ id }: { id: string }) {
  return (
    <svg className="gz-chart-defs" width="0" height="0" aria-hidden="true" focusable="false">
      <defs>
        {TONES.map(tone => (
          <g key={tone} className={`gz-pat gz-pat--${tone}`}>
            <pattern id={`${id}-hatch-${tone}`} width={PITCH} height={PITCH} patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <rect width={PITCH} height={PITCH} className="gz-pat__bg" />
              <line x1="0" y1="0" x2="0" y2={PITCH} className="gz-pat__ink" strokeWidth={LINE} />
            </pattern>
            <pattern id={`${id}-dots-${tone}`} width={PITCH} height={PITCH} patternUnits="userSpaceOnUse">
              <rect width={PITCH} height={PITCH} className="gz-pat__bg" />
              <circle cx={HALF} cy={HALF} r={DOT} className="gz-pat__fill" />
            </pattern>
            <pattern id={`${id}-cross-${tone}`} width={PITCH} height={PITCH} patternUnits="userSpaceOnUse">
              <rect width={PITCH} height={PITCH} className="gz-pat__bg" />
              <path d={`M0 0L${PITCH} ${PITCH}M${PITCH} 0L0 ${PITCH}`} className="gz-pat__ink" strokeWidth={flat['stroke.hair']} />
            </pattern>
          </g>
        ))}
      </defs>
    </svg>
  )
}

/** A flex child that paints a pattern over its box (no CSS gradient: the pattern is an SVG shader). */
export function PatternFill({ id, pattern, tone = 'ink' }: { id: string; pattern: FillPattern; tone?: PatternTone }) {
  if (pattern === 'solid') return null
  return (
    <svg className="gz-chart-pattern" aria-hidden="true" focusable="false">
      <rect width="100%" height="100%" fill={`url(#${id}-${pattern}-${tone})`} />
    </svg>
  )
}
