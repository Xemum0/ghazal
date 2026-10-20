// Sparkline: the trend of one series in a KPI tile. A 2 px ink line, a flat tint under it, one bead on the latest value. It carries no
// numbers (the tile does) and mirrors in Arabic: earlier is at the inline-start, which is the right edge there (ADR 0014 D5, "sparklines
// mirror"). It draws on once when it first scrolls into view; reduced motion shows the finished line.
// Accessible: `role="img"` with a name and a description that states the first and last values.
import { flat } from '@gz/tokens'
import { useChartIds, useInlineSize, useReadingOrder, Reveal } from './internal/kit'

const BEAD = flat['size.knot.bead']
const PAD = flat['space.2']

export type SparklineProps = {
  values: readonly number[]
  /** Accessible name: what the line is ("Views, last 30 days"). */
  label: string
  /** Spoken summary with the first and last values ("From 120 to 180"). */
  description?: string
  /** Height in px, a multiple of 4. Default 32 (KPI tile). */
  height?: number
  /** Flat tint under the line. Default on. */
  area?: boolean
  /** The bead on the latest value. Default on. */
  endMark?: boolean
  tone?: 'ink' | 'accent'
  animate?: boolean
  className?: string
}

export function Sparkline({ values, label, description, height = flat['size.chart.spark'], area = true, endMark = true, tone = 'ink', animate = true, className }: SparklineProps) {
  const [ref, width] = useInlineSize<HTMLDivElement>()
  const { isRtl } = useReadingOrder()
  const { titleId, descId } = useChartIds()
  const n = values.length
  const lo = Math.min(...values)
  const hi = Math.max(...values)
  const span = hi - lo || 1
  // The bead needs room at both ends; the line leaves PAD at the top and bottom.
  const inner = { x0: BEAD, x1: Math.max(BEAD, width - BEAD), y0: PAD / 2, y1: Math.max(PAD, height - PAD / 2) }
  const px = (i: number) => {
    const t = n <= 1 ? 1 : i / (n - 1)
    const x = inner.x0 + (inner.x1 - inner.x0) * (isRtl ? 1 - t : t)
    return Math.round(x * 10) / 10
  }
  const py = (v: number) => Math.round((inner.y1 - ((v - lo) / span) * (inner.y1 - inner.y0)) * 10) / 10
  const pts = values.map((v, i) => [px(i), py(v)] as const)
  const line = pts.map(([x, y], i) => `${i === 0 ? 'M' : 'L'}${x} ${y}`).join(' ')
  const last = pts[n - 1]
  const first = pts[0]
  const areaPath = last && first ? `${line} L${last[0]} ${height} L${first[0]} ${height} Z` : ''

  return (
    <Reveal animate={animate} className={`gz-spark${className ? ` ${className}` : ''}`} data-gz="Sparkline" data-tone={tone}>
      <div ref={ref} className="gz-spark__box" style={{ blockSize: height }}>
        {width > 0 && n > 1 ? (
          <svg className="gz-spark__svg" width={width} height={height} viewBox={`0 0 ${width} ${height}`} role="img" aria-labelledby={`${titleId} ${descId}`}>
            <title id={titleId}>{label}</title>
            <desc id={descId}>{description ?? ''}</desc>
            {area ? <path d={areaPath} className="gz-spark__area gz-chart-fade" /> : null}
            <path d={line} pathLength={1} className="gz-spark__line gz-draw" />
            {endMark && last ? (
              <rect
                x={last[0] - BEAD / 2}
                y={last[1] - BEAD / 2}
                width={BEAD}
                height={BEAD}
                transform={`rotate(45 ${last[0]} ${last[1]})`}
                className="gz-spark__bead gz-chart-fade"
              />
            ) : null}
          </svg>
        ) : null}
      </div>
    </Reveal>
  )
}
