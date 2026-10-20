// PriceHistogram (flow-local): where the roster's hall prices fall for the couple's guest count, drawn above the budget slider.
// Ten bins across the slider's range, bars in flex columns (no grid, no calc). Bars inside the chosen range are darker; the row
// is a plain flex row, so the minimum sits at inline-start and it mirrors in Arabic exactly like the slider under it (direction 6).
// Decorative for assistive technology: the slider and the band chips carry the value.
import { listVenues } from '../../../../mock'
import { cx } from './cx'
import './price-histogram.css'

const BINS = 10
const MAX_BAR = 48
const BAR_STEP = 4

export type PriceHistogramProps = {
  /** The slider's range, in dinars. */
  min: number
  max: number
  /** The chosen range, in dinars; bins that overlap it are drawn darker. */
  range: readonly [number, number]
  /** Guests the prices are for (the Brief's), or null for each hall's minimum. */
  guests: number | null
}

export function PriceHistogram({ min, max, range, guests }: PriceHistogramProps) {
  const prices = listVenues({}, { guests, audience: 'women' })
    .map(r => (r.price ? r.price.amount.fils / 1000 : null))
    .filter((p): p is number => p !== null)
  const width = (max - min) / BINS
  const counts = Array.from({ length: BINS }, (_, i) => prices.filter(p => Math.min(Math.floor((p - min) / width), BINS - 1) === i).length)
  const tallest = Math.max(1, ...counts)
  return (
    <div className="obd-hist" aria-hidden="true" data-gz-id="onboarding.histogram">
      {counts.map((n, i) => {
        const lo = min + i * width
        const inside = lo + width > range[0] && lo < range[1]
        const height = n === 0 ? BAR_STEP / 2 : Math.max(BAR_STEP, Math.round(((n / tallest) * MAX_BAR) / BAR_STEP) * BAR_STEP)
        return (
          <span key={i} className="obd-hist__col">
            <span className={cx('obd-hist__bar', inside && n > 0 && 'is-inside')} style={{ blockSize: height }} />
          </span>
        )
      })}
    </div>
  )
}
