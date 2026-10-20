// HotelDayView: the day as a prep - event - teardown timeline per hall (ADR 0008 D9: "Day as a prep-event-teardown timeline per hall").
// A hall with a booking shows Setup (before the session, from the session's buffer), the event with the guest, guests and a status pill,
// and Teardown (after it, on the next day when the event crosses midnight). A hall on hold shows one On hold row with its deadline; a
// blocked hall one Blocked row with its reason; a free hall says so and offers Block. It is the DayTimeline, once per hall, with the
// same Now knot when the day is today.
import type { CalendarClaim, Hall, IsoDate } from '@gz/contracts'
import { useFormat } from '../../../i18n'
import { Button } from '../../core'
import { cx } from '../../core/cx'
import { DayTimeline, type TimelineEvent } from '../DayTimeline'
import { Figures, timeRangeText, useBi } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import { markOf } from './model'
import '../calendar.css'

const useW = defineWords({
  setup: p('Setup', 'التجهيز'),
  teardown: p('Teardown', 'الفك والتنظيف'),
  held: p('On hold', 'محجوز مؤقتًا'),
  blocked: p('Blocked', 'مغلق'),
  open: p('Open: nothing booked or held on this date', 'متاح: لا حجز ولا تثبيت في هذا التاريخ'),
  block: p('Block this date', 'إغلاق هذا التاريخ'),
  holdUntil: p('Held until {time}', 'محجوز حتى {time}'),
  offline_booking: p('Booked offline', 'حجز خارج غزل'),
  maintenance: p('Maintenance', 'صيانة'),
  private_event: p('Private event', 'مناسبة خاصة'),
  other: p('Other', 'أخرى'),
})

const shift = (hhmm: string, minutes: number): { time: string; days: number } => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  const total = h * 60 + m + minutes
  const days = Math.floor(total / 1440)
  const t = ((total % 1440) + 1440) % 1440
  return { time: `${String(Math.floor(t / 60)).padStart(2, '0')}:${String(t % 60).padStart(2, '0')}`, days }
}

export type HotelDayViewProps = {
  date: IsoDate
  halls: readonly Hall[]
  claims: readonly CalendarClaim[]
  /** Venue-local `HH:MM`: only for today. */
  now?: string
  onOpenBooking?: (bookingId: string) => void
  onBlock?: (hallId: string) => void
  className?: string
}

export function HotelDayView({ date, halls, claims, now, onOpenBooking, onBlock, className }: HotelDayViewProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  return (
    <div data-gz="HotelDayView" className={cx('gz-dv', className)}>
      {halls.map(h => {
        const c = claims.find(x => x.date === date && x.hallId === h.id && markOf(x))
        const mark = c ? markOf(c) : null
        const session = h.sessions[0]
        const events: TimelineEvent[] = []
        if (c && mark === 'booked') {
          const start = c.start ?? session?.start ?? '21:00'
          const end = c.end ?? session?.end ?? '02:00'
          const before = shift(start, -(session?.bufferBeforeMin ?? 120))
          const after = shift(end, session?.bufferAfterMin ?? 60)
          const crosses = end < start
          const range = timeRangeText(f, date, start, end)
          events.push({ id: `${c.id}-setup`, time: before.time, nextDay: before.days > 0, title: w('setup'), kind: 'prep' })
          events.push({ id: c.id, time: start, title: c.clientName ?? '', userTitle: true, kind: 'event', status: 'confirmed', meta: <Figures text={`${f.guests(c.guests ?? 0)} · ${range}`} /> })
          events.push({ id: `${c.id}-down`, time: after.time, nextDay: crosses || after.days > 0, title: w('teardown'), kind: 'prep' })
        } else if (c && mark === 'held') {
          events.push({ id: c.id, time: c.start ?? session?.start ?? '21:00', title: w('held'), kind: 'event', status: 'held', meta: <Figures text={c.holdUntil ? w('holdUntil', { time: f.dateTime(c.holdUntil) }) : ''} /> })
        } else if (c && mark === 'blocked') {
          events.push({ id: c.id, time: session?.start ?? '09:00', title: w('blocked'), kind: 'event', status: 'blocked', meta: c.blockReason ? w(c.blockReason) : undefined })
        }
        return (
          <section key={h.id} className="gz-dv__hall" aria-label={bi(h.name)}>
            <header className="gz-dv__head">
              <h3 className="gz-t-title gz-dv__name">{bi(h.name)}</h3>
              {session ? (
                <span className="gz-t-caption gz-dv__session">
                  <Figures text={`${bi(session.name)} · ${timeRangeText(f, date, session.start, session.end)}`} />
                </span>
              ) : null}
            </header>
            {events.length ? (
              <DayTimeline date={date} events={events} now={now} onPress={id => (c?.bookingId && id === c.id ? onOpenBooking?.(c.bookingId) : undefined)} />
            ) : (
              <div className="gz-dv__open">
                <p className="gz-t-body-s gz-dv__openline">{w('open')}</p>
                <Button variant="secondary" iconStart="lock" onClick={() => onBlock?.(h.id)}>
                  {w('block')}
                </Button>
              </div>
            )}
          </section>
        )
      })}
    </div>
  )
}
