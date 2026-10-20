// HotelMonthGrid: the hotel's month view (ADR 0008 D9, direction 3 "Calendar cell"). Sunday-first, seven flex columns, cells 52 high and at
// least 44 wide, the Thu-Sat peak band at the inline-end edge, today with the ink outline, past days quiet. Each day carries one mark per
// hall, in hall order, so a mark always sits in its hall's slot: a solid disc = booked, a ring = on hold, a dash = blocked; a gold bead
// at the corner = a pending request (informational, it never claims the date). Nothing is colour alone and the day's accessible name
// lists what each hall carries.
// Two modes. `view`: a tap selects a day (the agenda below opens). `select`: block-dates range selection with two input paths that
// mirror with the week (ADR 0014 D4): tap a start and an end ("Select dates" mode), or press and hold a day, then drag across the
// dates; a thread joins the endpoints and booked-out days refuse the selection.
import { useEffect, useMemo, useRef, useState, type KeyboardEvent, type PointerEvent } from 'react'
import type { CalendarClaim, Hall, IsoDate } from '@gz/contracts'
import { engine } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { IconButton } from '../../core'
import { cx } from '../../core/cx'
import { Fig } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import { dayFacts, inSpan, isFull, tapSpan, type DateSpan, type DayFacts } from './model'
import '../calendar.css'

const useW = defineWords({
  booked: p('Booked', 'محجوز'),
  held: p('On hold', 'محجوز مؤقتًا'),
  blocked: p('Blocked', 'مغلق'),
  free: p('open', 'متاح'),
  requested: p('Request', 'طلب'),
  requestedLegend: p('Pending request', 'طلب بانتظار الرد'),
  sep: p(', ', '، '),
})

export type YearMonth = { year: number; month: number }
const HOLD_MS = 280
const SLOP = 8

export type HotelMonthGridProps = {
  halls: readonly Hall[]
  claims: readonly CalendarClaim[]
  month?: YearMonth
  defaultMonth?: YearMonth
  onMonthChange?: (m: YearMonth) => void
  /** Default: the prototype's today. */
  today?: IsoDate
  mode?: 'view' | 'select'
  /** View mode: the tapped day. */
  selected?: IsoDate | null
  onSelectDate?: (iso: IsoDate) => void
  /** Select mode: the range being built. */
  range?: DateSpan
  onRangeChange?: (r: DateSpan) => void
  legend?: boolean
  /** Accessible name of the grid. */
  label: string
  className?: string
}

export function HotelMonthGrid({ halls, claims, month, defaultMonth, onMonthChange, today, mode = 'view', selected, onSelectDate, range, onRangeChange, legend = true, label, className }: HotelMonthGridProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const now = today ?? f.isoDay(f.now())
  const [inner, setInner] = useState<YearMonth>(() => defaultMonth ?? { year: Number(now.slice(0, 4)), month: Number(now.slice(5, 7)) })
  const ym = month ?? inner
  const setMonth = (m: YearMonth) => {
    if (!month) setInner(m)
    onMonthChange?.(m)
  }
  const step = (d: number) => {
    const idx = ym.year * 12 + (ym.month - 1) + d
    setMonth({ year: Math.floor(idx / 12), month: (idx % 12) + 1 })
  }
  const weeks = useMemo(() => f.monthGrid(ym.year, ym.month), [f, ym.year, ym.month])
  const headers = f.weekdayHeaders()
  const select = mode === 'select'
  const span: DateSpan = range ?? { start: null, end: null }
  const gridRef = useRef<HTMLDivElement>(null)
  const drag = useRef<{ startIso: IsoDate; x: number; y: number; timer: number; active: boolean } | null>(null)
  const suppress = useRef(false)
  const pendingFocus = useRef<IsoDate | null>(null)
  const { isRtl } = useLang()

  const facts = (iso: IsoDate): DayFacts => dayFacts(iso, halls, claims, now)
  const selectable = (d: DayFacts) => select && !d.past && !isFull(d)

  // While a drag is live the page must not scroll under the finger: a non-passive touchmove cancels it.
  useEffect(() => {
    const el = gridRef.current
    if (!el) return
    const stop = (e: TouchEvent) => {
      if (drag.current?.active) e.preventDefault()
    }
    el.addEventListener('touchmove', stop, { passive: false })
    return () => el.removeEventListener('touchmove', stop)
  }, [])

  const isoAt = (x: number, y: number): IsoDate | null => {
    const el = document.elementFromPoint(x, y)?.closest<HTMLElement>('[data-iso]')
    return el && el.getAttribute('aria-disabled') !== 'true' ? (el.dataset.iso ?? null) : null
  }

  const down = (e: PointerEvent, iso: IsoDate) => {
    if (!select) return
    const st = { startIso: iso, x: e.clientX, y: e.clientY, timer: 0, active: false }
    st.timer = window.setTimeout(() => {
      st.active = true
      suppress.current = true
      onRangeChange?.({ start: iso, end: iso })
    }, HOLD_MS)
    drag.current = st
  }
  const move = (e: PointerEvent) => {
    const st = drag.current
    if (!st) return
    if (!st.active) {
      if (Math.hypot(e.clientX - st.x, e.clientY - st.y) > SLOP) {
        window.clearTimeout(st.timer)
        drag.current = null
      }
      return
    }
    const iso = isoAt(e.clientX, e.clientY)
    if (iso) onRangeChange?.({ start: st.startIso, end: iso })
  }
  const up = () => {
    const st = drag.current
    if (st) window.clearTimeout(st.timer)
    drag.current = null
  }
  const press = (iso: IsoDate) => {
    if (suppress.current) {
      suppress.current = false
      return
    }
    if (select) onRangeChange?.(tapSpan(span, iso))
    else onSelectDate?.(iso)
  }

  // Roving tabindex: one day is in the tab order (the chosen day, else today, else the 1st); arrows move by what you see
  // (so Left is the next day in Arabic), Up and Down by a week, Home and End to the ends of the week, PageUp and PageDown by four weeks.
  const monthKey = `${ym.year}-${String(ym.month).padStart(2, '0')}`
  const tabStop: IsoDate = (select ? span.start : selected) && (select ? span.start : selected)!.startsWith(monthKey) ? ((select ? span.start : selected) as IsoDate) : now.startsWith(monthKey) ? now : `${monthKey}-01`
  const focusIso = (iso: IsoDate) => {
    if (iso.startsWith(monthKey)) gridRef.current?.querySelector<HTMLElement>(`[data-iso="${iso}"]`)?.focus()
    else {
      pendingFocus.current = iso
      setMonth({ year: Number(iso.slice(0, 4)), month: Number(iso.slice(5, 7)) })
    }
  }
  useEffect(() => {
    if (pendingFocus.current) {
      const iso = pendingFocus.current
      pendingFocus.current = null
      gridRef.current?.querySelector<HTMLElement>(`[data-iso="${iso}"]`)?.focus()
    }
  })
  const keys = (e: KeyboardEvent, iso: IsoDate) => {
    const side = isRtl ? -1 : 1
    const wd = engine.weekdayOf(iso)
    const to: Record<string, IsoDate> = {
      ArrowRight: engine.addDays(iso, side),
      ArrowLeft: engine.addDays(iso, -side),
      ArrowDown: engine.addDays(iso, 7),
      ArrowUp: engine.addDays(iso, -7),
      Home: engine.addDays(iso, -wd),
      End: engine.addDays(iso, 6 - wd),
      PageDown: engine.addDays(iso, 28),
      PageUp: engine.addDays(iso, -28),
    }
    const next = to[e.key]
    if (!next) return
    e.preventDefault()
    focusIso(next)
  }

  const name = (d: DayFacts) => {
    const per = halls
      .map((h, i) => {
        const l = d.lanes[i]
        return `${h.name[f.lang]} ${l === 'booked' ? w('booked') : l === 'held' ? w('held') : l === 'blocked' ? w('blocked') : w('free')}`
      })
      .join(w('sep'))
    return `${f.date(d.iso, 'short')}${w('sep')}${per}${d.requested ? `${w('sep')}${w('requested')}` : ''}`
  }

  const title = f.date(`${ym.year}-${String(ym.month).padStart(2, '0')}-01`, 'monthYear')
  return (
    <div data-gz="HotelMonthGrid" data-mode={mode} className={cx('gz-hc', className)}>
      <div className="gz-hc__head">
        <IconButton icon="chevron-left" label={t('commonCalendarPreviousMonth')} onClick={() => step(-1)} />
        <h3 className="gz-hc__title gz-t-ui-title" aria-live="polite">
          {title}
        </h3>
        <IconButton icon="chevron-right" label={t('commonCalendarNextMonth')} onClick={() => step(1)} />
      </div>
      <div ref={gridRef} className="gz-hc__grid" role="grid" aria-label={label} aria-multiselectable={select || undefined} onPointerMove={move} onPointerUp={up} onPointerCancel={up} onPointerLeave={up}>
        <div className="gz-hc__row" role="row">
          {headers.map((h, i) => (
            <span key={i} role="columnheader" className="gz-hc__hcell gz-t-caption" data-top data-peak={i === 4 ? 'first' : i === 6 ? 'last' : i === 5 ? 'mid' : undefined}>
              {h}
            </span>
          ))}
        </div>
        {weeks.map((week, wi) => (
          <div key={wi} className="gz-hc__row" role="row">
            {week.map((day, di) => {
              const peak = di === 4 ? 'first' : di === 6 ? 'last' : di === 5 ? 'mid' : undefined
              const bottom = wi === weeks.length - 1 || undefined
              if (!day.inMonth) return <span key={di} role="gridcell" className="gz-hc__cell" data-peak={peak} data-bottom={bottom} aria-hidden="true" />
              const d = facts(day.iso)
              const ok = !select || selectable(d)
              const isEnd = select && (day.iso === span.start || day.iso === (span.end ?? span.start))
              const isSel = select ? Boolean(span.start) && isEnd : selected === day.iso
              const inRange = select && inSpan(day.iso, span) && Boolean(span.end) && span.start !== span.end
              return (
                <span key={day.iso} role="gridcell" className="gz-hc__cell" data-peak={peak} data-bottom={bottom} aria-selected={select ? isSel || inRange : undefined}>
                  {inRange ? <span className="gz-hc__thread" aria-hidden="true" /> : null}
                  <button
                    type="button"
                    className="gz-reset gz-hc__day gz-t-cal-day"
                    data-iso={day.iso}
                    data-today={day.iso === now || undefined}
                    data-past={d.past || undefined}
                    data-selected={isSel || undefined}
                    data-inrange={inRange || undefined}
                    aria-label={name(d)}
                    tabIndex={day.iso === tabStop ? 0 : -1}
                    aria-pressed={!select ? isSel : undefined}
                    onKeyDown={e => keys(e, day.iso)}
                    aria-disabled={ok ? undefined : true}
                    onPointerDown={e => down(e, day.iso)}
                    onClick={() => (ok ? press(day.iso) : undefined)}
                  >
                    <span className="gz-hc__fig">
                      <Fig>{f.integer(day.day)}</Fig>
                    </span>
                    <span className="gz-hc__lanes" aria-hidden="true">
                      {d.lanes.map((l, i) => (
                        <i key={i} className={cx('gz-hc__mark', `gz-hc__mark--${l ?? 'none'}`)} />
                      ))}
                    </span>
                    {d.requested > 0 ? <i className="gz-hc__req" aria-hidden="true" /> : null}
                  </button>
                </span>
              )
            })}
          </div>
        ))}
      </div>
      {legend ? (
        <ul className="gz-hc__legend gz-t-caption">
          <li className="gz-hc__key">
            <span className="gz-hc__swatch">
              <i className="gz-hc__mark gz-hc__mark--booked" />
            </span>
            {w('booked')}
          </li>
          <li className="gz-hc__key">
            <span className="gz-hc__swatch">
              <i className="gz-hc__mark gz-hc__mark--held" />
            </span>
            {w('held')}
          </li>
          <li className="gz-hc__key">
            <span className="gz-hc__swatch">
              <i className="gz-hc__mark gz-hc__mark--blocked" />
            </span>
            {w('blocked')}
          </li>
          <li className="gz-hc__key">
            <span className="gz-hc__swatch">
              <i className="gz-hc__req" />
            </span>
            {w('requestedLegend')}
          </li>
          <li className="gz-hc__key">
            <span className="gz-hc__swatch gz-hc__swatch--peak" />
            {t('commonCalendarPeak')}
          </li>
        </ul>
      ) : null}
    </div>
  )
}
