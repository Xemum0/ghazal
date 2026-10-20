// HotelWeekView: the week as a vertical list of seven day rows with one lane per hall (ADR 0008 D9, ADR 0002 D9). A lane is 44 high (it
// is a target): booked = a solid ink bar with the guest; held = gold hatched stripe + gold-100 body with the hold deadline; blocked =
// cross-hatched stripe, struck text and the reason; open = a hairline outline, with a gold bead when a request points at the date
// (informational, never a claim). Sunday-first, Thu to Sat on the rose-50 peak wash, today with the ink outline on its date. The
// week arrows follow reading direction (previous at the inline-start).
import { useState } from 'react'
import type { CalendarClaim, Hall, IsoDate } from '@gz/contracts'
import { engine } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { IconButton } from '../../core'
import { ThreadBead } from '../../brand'
import { cx } from '../../core/cx'
import { PatternDefs, PatternFill, useChartIds } from '../../charts/internal/kit'
import { Fig, Figures, UserText, useBi } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import { markOf } from './model'
import '../calendar.css'

const useW = defineWords({
  open: p('Open', 'متاح'),
  holdUntil: p('Held until {time}', 'محجوز حتى {time}'),
  request: p('Request', 'طلب'),
  today: p('Today', 'اليوم'),
  week: p('Week of {from} to {to}', 'أسبوع {from} إلى {to}'),
  offline_booking: p('Booked offline', 'حجز خارج غزل'),
  maintenance: p('Maintenance', 'صيانة'),
  private_event: p('Private event', 'مناسبة خاصة'),
  other: p('Other', 'أخرى'),
  booked: p('Booked', 'محجوز'),
  blocked: p('Blocked', 'مغلق'),
})

export type HotelWeekViewProps = {
  halls: readonly Hall[]
  claims: readonly CalendarClaim[]
  /** Any date inside the week to show (the week starts on Sunday). Controlled with `onWeekChange`, otherwise the initial week. */
  date?: IsoDate
  onWeekChange?: (sunday: IsoDate) => void
  today?: IsoDate
  onOpenBooking?: (bookingId: string) => void
  onSelectDate?: (iso: IsoDate) => void
  label: string
  className?: string
}

const sundayOf = (iso: IsoDate): IsoDate => engine.addDays(iso, -engine.weekdayOf(iso))

export function HotelWeekView({ halls, claims, date, onWeekChange, today, onOpenBooking, onSelectDate, label, className }: HotelWeekViewProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const bi = useBi()
  const { patternId } = useChartIds()
  const now = today ?? f.isoDay(f.now())
  const [inner, setInner] = useState<IsoDate>(() => sundayOf(date ?? now))
  const sunday = date && onWeekChange ? sundayOf(date) : inner
  const go = (d: number) => {
    const next = engine.addDays(sunday, d * 7)
    if (!(date && onWeekChange)) setInner(next)
    onWeekChange?.(next)
  }
  const days = Array.from({ length: 7 }, (_, i) => engine.addDays(sunday, i))
  const [m0, m1] = [Number((days[0] as string).slice(5, 7)), Number((days[6] as string).slice(5, 7))]
  const [d0, d1] = [f.integer(Number((days[0] as string).slice(8))), f.integer(Number((days[6] as string).slice(8)))]
  // `6 – 12 December`, or `28 Nov – 4 Dec` across a month edge: it must fit on one line next to the two arrows.
  const span = m0 === m1 ? `${d0} – ${d1} ${f.monthName(m0)}` : `${d0} ${f.monthName(m0, 'short')} – ${d1} ${f.monthName(m1, 'short')}`
  return (
    <div data-gz="HotelWeekView" className={cx('gz-wk', className)}>
      <PatternDefs id={patternId} />
      <div className="gz-hc__head">
        <IconButton icon="chevron-left" label={t('commonCalendarPreviousMonth')} onClick={() => go(-1)} />
        <h3 className="gz-hc__title gz-t-ui-title" aria-live="polite">
          <Figures text={span} />
        </h3>
        <IconButton icon="chevron-right" label={t('commonCalendarNextMonth')} onClick={() => go(1)} />
      </div>
      <ol className="gz-wk__list" aria-label={label}>
        {days.map(iso => {
          const wd = engine.weekdayOf(iso)
          const isToday = iso === now
          return (
            <li key={iso} className={cx('gz-wk__day', wd >= 4 && 'gz-wk__day--peak', iso < now && 'gz-wk__day--past')}>
              <button type="button" className={cx('gz-reset gz-wk__date', isToday && 'is-today')} onClick={() => onSelectDate?.(iso)} aria-label={`${f.date(iso, 'short')}${isToday ? `، ${w('today')}` : ''}`}>
                <span className="gz-t-caption gz-wk__wd">{f.weekdayName(wd, 'header')}</span>
                <span className="gz-t-price-strong gz-wk__num">
                  <Fig>{f.integer(Number(iso.slice(8)))}</Fig>
                </span>
              </button>
              <div className="gz-wk__lanes">
                {halls.map(h => {
                  const c = claims.find(x => x.date === iso && x.hallId === h.id && markOf(x))
                  const reqs = claims.filter(x => x.date === iso && x.hallId === h.id && x.kind === 'requested').length
                  const mark = c ? markOf(c) : null
                  const hall = bi(h.name)
                  const inner = (
                    <>
                      {mark === 'held' ? <span className="gz-wk__stripe"><PatternFill id={patternId} pattern="hatch" tone="gold" /></span> : null}
                      {mark === 'blocked' ? <span className="gz-wk__stripe"><PatternFill id={patternId} pattern="cross" tone="ink" /></span> : null}
                      <span className="gz-wk__text">
                        <span className="gz-wk__hall gz-t-caption">{hall}</span>
                        <span className="gz-wk__info gz-t-caption">
                          {mark === 'booked' && c ? (
                            <>
                              {c.clientName ? <UserText role="caption">{c.clientName}</UserText> : null}
                              {c.clientName ? ' · ' : ''}
                              <Figures text={f.guests(c.guests ?? 0)} />
                            </>
                          ) : mark === 'held' && c ? (
                            <Figures text={c.holdUntil ? w('holdUntil', { time: f.dateTime(c.holdUntil) }) : ''} />
                          ) : mark === 'blocked' && c ? (
                            <span className="gz-wk__struck">{c.blockReason ? w(c.blockReason) : w('blocked')}</span>
                          ) : (
                            <>
                              {reqs > 0 ? <ThreadBead tone="gold" /> : null}
                              {reqs > 0 ? w('request') : w('open')}
                            </>
                          )}
                        </span>
                      </span>
                    </>
                  )
                  const cls = cx('gz-wk__lane', `gz-wk__lane--${mark ?? 'open'}`)
                  return mark === 'booked' && c?.bookingId && onOpenBooking ? (
                    <button key={h.id} type="button" className={cx('gz-reset', cls, 'gz-press')} onClick={() => onOpenBooking(c.bookingId as string)}>
                      {inner}
                    </button>
                  ) : (
                    <div key={h.id} className={cls}>
                      {inner}
                    </div>
                  )
                })}
              </div>
            </li>
          )
        })}
      </ol>
    </div>
  )
}
