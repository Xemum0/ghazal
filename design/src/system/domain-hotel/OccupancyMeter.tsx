// OccupancyMeter: how full the halls are over a period, as a hairline panel: the share in the figures voice, one sentence that says
// what it counts (`21 of 36 hall-nights booked`), and the stacked bar of booked / on hold / blocked / open told apart by pattern, with
// each part's count and share in the legend and a table twin underneath. A hall-night is one hall on one date (ADR 0002 D9: lanes per
// hall). Held nights are never counted as booked: a hold is not a booking (ADR 0001).
import { useFormat } from '../../i18n'
import { cx } from '../core/cx'
import { BreakdownChart, type Segment } from '../charts'
import { Fig, Figures } from './internal/bits'
import { defineWords, definePlurals, p } from './internal/copy'
import './analytics-cards.css'

const useW = defineWords({
  booked: p('Booked', 'محجوز'),
  held: p('On hold', 'محجوز مؤقتًا'),
  blocked: p('Blocked', 'مغلق'),
  open: p('Open', 'متاح'),
  of: p('{booked} of {total} hall-nights booked', '{booked} من {total} ليلة قاعة محجوزة'),
})

const usePl = definePlurals({
  nights: { en: { one: 'hall-night', other: 'hall-nights' }, ar: { '=1': 'ليلة قاعة', '=2': 'ليلتا قاعة', few: 'ليالي قاعات', many: 'ليلة قاعة', other: 'ليلة قاعة' } },
})

export type OccupancyMeterProps = {
  /** `Occupancy, next 28 days`. */
  title: string
  /** Hall-nights in the period, by state. */
  booked: number
  held: number
  blocked: number
  open: number
  className?: string
}

export function OccupancyMeter({ title, booked, held, blocked, open, className }: OccupancyMeterProps) {
  const f = useFormat()
  const w = useW()
  const pl = usePl()
  const total = booked + held + blocked + open
  // Blocked nights are not for sale: they leave the denominator, so a hotel is not "emptier" for closing a hall.
  const sellable = total - blocked
  const share = sellable > 0 ? Math.round((booked / sellable) * 100) : 0
  const segments: Segment[] = [
    { id: 'booked', label: w('booked'), value: booked, tone: 'strong' },
    { id: 'held', label: w('held'), value: held, tone: 'gold', pattern: 'hatch' },
    { id: 'blocked', label: w('blocked'), value: blocked, tone: 'quiet', pattern: 'cross' },
    { id: 'open', label: w('open'), value: open, tone: 'open' },
  ]
  return (
    <section data-gz="OccupancyMeter" className={cx('gz-occ', className)}>
      <h3 className="gz-t-title gz-rev__title">{title}</h3>
      <div className="gz-occ__hero">
        <span className="gz-t-kpi gz-occ__share">
          <Fig>{f.percent(share)}</Fig>
        </span>
        <span className="gz-t-caption gz-occ__of">
          <Figures text={w('of', { booked: f.integer(booked), total: f.integer(sellable) })} />
        </span>
      </div>
      <BreakdownChart
        title={title}
        description={`${pl('nights', sellable)}`}
        segments={segments}
        formatValue={n => f.integer(n)}
        formatShare={n => f.percent(n)}
      />
    </section>
  )
}
