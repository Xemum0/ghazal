// TimelineBar: one hall's business day as a bar (HL-CALN-03): 06:00 to 06:00, the time axis in reading direction (right to left in Arabic, the
// flex row does it). Setup and teardown are hatched (the hall is busy but nothing is on), the event is the solid ink segment, a hold is gold
// hatch, a block is cross-hatch over the session, and a free hall shows the session window as a hairline outline (what could be sold).
// Segments are flex children whose grow factor is their minutes (Flutter: a Row of Expanded with flex = minutes). The axis is four ticks
// and two glyphs (ADR 0034): a sun at noon, a moon at midnight with the next day's date (the teardown often crosses it); the clock times of
// the three phases are one tap away, behind the (i) of the hall.
import type { IsoDate } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { Icon } from '../../../../system'
import { Hatch } from './Hatch'
import { addDays, weekdayOf } from './data'
import { Fx } from './calBits'
import './timeline-bar.css'

const DAY = 1440
const FROM = 360

/** Minutes after 06:00 of the business day; a time before 06:00 belongs to the next calendar day, still inside the business day. */
export const minuteOf = (hhmm: string): number => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  const abs = h * 60 + m
  return abs >= FROM ? abs - FROM : abs + DAY - FROM
}

export type Segment = { kind: 'setup' | 'teardown' | 'event' | 'held' | 'blocked' | 'window'; start: string; end: string }

export type TimelineBarProps = { date: IsoDate; segments: readonly Segment[]; label: string }

export function TimelineBar({ date, segments, label }: TimelineBarProps) {
  const f = useFormat()
  const ordered = [...segments].map(s => ({ ...s, a: minuteOf(s.start), b: Math.max(minuteOf(s.end), minuteOf(s.start) + 1) })).sort((x, y) => x.a - y.a)
  const parts: { key: string; grow: number; kind?: Segment['kind'] }[] = []
  let at = 0
  ordered.forEach((s, i) => {
    const a = Math.max(s.a, at)
    if (a > at) parts.push({ key: `g${i}`, grow: a - at })
    if (s.b > a) parts.push({ key: `s${i}`, grow: s.b - a, kind: s.kind })
    at = Math.max(at, s.b)
  })
  if (at < DAY) parts.push({ key: 'end', grow: DAY - at })

  const ticks = ['06:00', '12:00', '18:00', '00:00'] as const
  const next = addDays(date, 1)
  const nextDay = `${f.weekdayName(weekdayOf(next), 'header')} ${f.integer(Number(next.slice(8)))}`
  return (
    <div className="cal-tl" data-gz="TimelineBar" role="img" aria-label={label}>
      <div className="cal-tl__bar">
        {parts.map(p => (
          <span key={p.key} className="cal-tl__seg" data-kind={p.kind} style={{ flexGrow: p.grow }}>
            {p.kind === 'setup' || p.kind === 'teardown' ? <Hatch tone="ink" /> : null}
            {p.kind === 'held' ? <Hatch tone="gold" /> : null}
            {p.kind === 'blocked' ? <Hatch tone="ink" kind="cross" /> : null}
          </span>
        ))}
      </div>
      <div className="cal-tl__axis gz-t-caption" aria-hidden="true">
        {ticks.map(tick => (
          <span key={tick} className="cal-tl__tick">
            {tick === '12:00' ? <Icon name="sun" size="xs" tone="secondary" /> : null}
            {tick === '00:00' ? (
              <>
                <Icon name="moon" size="xs" tone="secondary" />
                <Fx text={nextDay} />
              </>
            ) : null}
          </span>
        ))}
      </div>
    </div>
  )
}
