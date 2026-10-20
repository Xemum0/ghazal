// Histogram (flow-local, Filters price and Brief budget): where the roster's prices fall, drawn above a range slider. Flex columns, no grid,
// no calc; bars inside the chosen range are darker. A plain flex row, so the minimum sits at inline-start and it mirrors in Arabic exactly like
// the slider under it (direction 6). Decorative for assistive technology: the slider carries the value.
import { flat } from '@gz/tokens'
import './histogram.css'

const MAX_BAR = flat['space.10']
const BAR_STEP = flat['space.1']

export type HistogramProps = {
  /** One value per hall, in the slider's unit. */
  values: readonly number[]
  min: number
  max: number
  /** The chosen range; bins that overlap it are drawn darker. */
  range: readonly [number, number]
  bins?: number
}

export function Histogram({ values, min, max, range, bins = 12 }: HistogramProps) {
  const width = (max - min) / bins
  const counts = Array.from({ length: bins }, (_, i) => values.filter(v => Math.min(Math.max(Math.floor((v - min) / width), 0), bins - 1) === i).length)
  const tallest = Math.max(1, ...counts)
  return (
    <div className="gzd-hist" aria-hidden="true" data-gz-id="histogram">
      {counts.map((n, i) => {
        const lo = min + i * width
        const inside = lo + width > range[0] && lo < range[1]
        const height = n === 0 ? BAR_STEP / 2 : Math.max(BAR_STEP, Math.round(((n / tallest) * MAX_BAR) / BAR_STEP) * BAR_STEP)
        return (
          <span key={i} className="gzd-hist__col">
            <span className={`gzd-hist__bar${inside && n > 0 ? ' is-inside' : ''}`} style={{ blockSize: height }} />
          </span>
        )
      })}
    </div>
  )
}
