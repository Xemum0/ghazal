// DayTimeline: the vertical day of the Hotel Today screen (direction 3 "Day timeline", rule 5): a time column (56), a rail (16) and the
// content. One thread down the rail: done knots are 12 px gold, the ringed Now knot is 16 px (3 px canvas gap, 3 px gold-650 ring),
// the knots still to come are hollow 12 px ink-500 rings; the line is gold up to Now and ink-200 beyond. The time is the figures voice
// (Cairo 600 14/20) with am/pm as a caption. Setup and teardown rows are quiet; events carry their title, hall and guests and may carry
// a status pill. Times are venue-local `HH:MM`; a row after midnight says which day it falls on. Nothing animates but the thread draw
// once; "Now" is a row, not a pulse.
import type { CSSProperties, ReactNode } from 'react'
import type { IsoDate } from '@gz/contracts'
import { engine } from '../../mock'
import { useFormat } from '../../i18n'
import { useLang } from '../../shell/lang'
import { StatusPill, type StatusKey } from '../core'
import { cx } from '../core/cx'
import { useRevealOnce } from '../core/useRevealOnce'
import { clockInstant, Figures, splitTime, UserText } from './internal/bits'
import { defineWords, p } from './internal/copy'
import './day-timeline.css'

const useW = defineWords({
  now: p('Now', 'الآن'),
  empty: p('Nothing scheduled today', 'لا شيء مجدول اليوم'),
})

export type TimelineEvent = {
  id: string
  /** Venue-local `HH:MM`. */
  time: string
  /** The row falls on the next calendar day (a teardown after midnight). */
  nextDay?: boolean
  title: string
  /** Hall, guests, session: already formatted, may carry numbers (they are set in the figures voice by the caller or Figures). */
  meta?: ReactNode
  /** `event` = a booking (title in 600), `prep` = setup or teardown (quiet). */
  kind?: 'event' | 'prep'
  /** A user-typed title (a guest's name) takes its own script. Default false. */
  userTitle?: boolean
  status?: StatusKey
}

export type DayTimelineProps = {
  date: IsoDate
  events: readonly TimelineEvent[]
  /** Venue-local `HH:MM` of the clock; omit for a day that is not today (every knot is open, nothing is done). */
  now?: string
  onPress?: (id: string) => void
  /** Draw the thread on once (default) or show it finished. */
  animate?: boolean
  className?: string
}

type Row = { kind: 'now' | 'event'; id: string; minutes: number; time: string; nextDay?: boolean; event?: TimelineEvent }

const minutesOf = (hhmm: string, nextDay?: boolean): number => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  return h * 60 + m + (nextDay ? 1440 : 0)
}

export function DayTimeline({ date, events, now, onPress, animate = true, className }: DayTimelineProps) {
  const f = useFormat()
  const w = useW()
  const { isRtl } = useLang()
  const [ref, seen] = useRevealOnce<HTMLOListElement>(animate)

  const rows: Row[] = events.map(e => ({ kind: 'event', id: e.id, minutes: minutesOf(e.time, e.nextDay), time: e.time, nextDay: e.nextDay, event: e }))
  if (now) rows.push({ kind: 'now', id: 'now', minutes: minutesOf(now), time: now })
  rows.sort((a, b) => a.minutes - b.minutes || (a.kind === 'now' ? -1 : 1))
  const nowAt = now ? minutesOf(now) : null
  const stateOf = (r: Row): 'done' | 'now' | 'open' => (r.kind === 'now' ? 'now' : nowAt !== null && r.minutes < nowAt ? 'done' : 'open')
  const reached = (r: Row | undefined) => (r ? stateOf(r) !== 'open' : false)

  if (rows.length === 0) return <p className="gz-t-body-s gz-tl__empty">{w('empty')}</p>

  return (
    <ol ref={ref} data-gz="DayTimeline" className={cx('gz-tl', isRtl && 'gz-tl--rtl', className)}>
      {rows.map((r, i) => {
        const st = stateOf(r)
        const first = i === 0
        const last = i === rows.length - 1
        const next = rows[i + 1]
        const clock = splitTime(f.time(clockInstant(f, r.nextDay ? engine.addDays(date, 1) : date, r.time)))
        const delay = { '--gz-delay': `${Math.min(i, 4) * 120}ms` } as CSSProperties
        const e = r.event
        const body = e ? (
          <>
            <span className="gz-tl__title-row">
              {e.userTitle ? (
                <UserText role="title" className={cx('gz-tl__title', e.kind === 'prep' && 'gz-tl__title--prep')}>
                  {e.title}
                </UserText>
              ) : (
                <span className={cx('gz-tl__title gz-t-title', e.kind === 'prep' && 'gz-tl__title--prep')}>{e.title}</span>
              )}
              {e.status ? <StatusPill status={e.status} audience="hotel" /> : null}
            </span>
            {e.meta || r.nextDay ? (
              <span className="gz-tl__meta gz-t-caption">
                {r.nextDay ? <Figures text={f.date(engine.addDays(date, 1), 'short')} /> : null}
                {r.nextDay && e.meta ? ' · ' : null}
                {e.meta}
              </span>
            ) : null}
          </>
        ) : (
          <span className="gz-tl__title gz-tl__title--now gz-t-title">{w('now')}</span>
        )
        const content = onPress && e ? (
          <button type="button" className="gz-reset gz-tl__content gz-tl__content--button" onClick={() => onPress(e.id)}>
            {body}
          </button>
        ) : (
          <div className="gz-tl__content">{body}</div>
        )
        return (
          <li key={r.id} className={cx('gz-tl__row', `gz-tl__row--${st}`, r.kind === 'now' && 'gz-tl__row--marker')} aria-current={r.kind === 'now' ? 'time' : undefined}>
            <span className="gz-tl__time">
              <span className="gz-t-timeline-time">
                <bdi dir="ltr">{clock.figure}</bdi>
              </span>
              {clock.suffix ? <span className="gz-t-label gz-tl__ampm">{clock.suffix}</span> : null}
            </span>
            <span className="gz-tl__rail" aria-hidden="true">
              <span className={cx('gz-tl__slot', first && 'gz-tl__slot--first', last && 'gz-tl__slot--last', reached(r) && 'is-reached')}>
                <span className={cx('gz-tl__knot', `gz-tl__knot--${st}`)} />
              </span>
              {!last ? <span className={cx('gz-tl__down', reached(next) && 'is-reached', reached(next) && animate && (seen ? 'gz-thread-draw-y' : 'is-armed'))} style={delay} /> : null}
            </span>
            {content}
          </li>
        )
      })}
    </ol>
  )
}
