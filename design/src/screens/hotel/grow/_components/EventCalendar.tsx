// EventCalendar: the month grid where the venue picks the event dates an offer covers (HL-GROW-03). The system Calendar picks one date or one
// range; an offer wants several loose dates (Thu 3 Dec and Sat 5 Dec), so this flow-local twin keeps its anatomy (Sunday-first from the
// formatter, seven flex columns, 52 high cells at least 44 wide, the Thu to Sat band at the inline-end edge, selected = gold fill with the two
// rings) and adds what the offer needs: any number of picks, booked days struck through and not selectable, the venue's open weekend dates
// marked with a gold-700 bead, no native picker. Requested as `Calendar mode="multiple"` (docs/engineering/requests.md).
import { useMemo, useRef, useState, type KeyboardEvent } from 'react'
import type { CalendarDay } from '@gz/i18n'
import { engine, softDatesFor, venueAvailabilityOn, type IsoDate } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { BarButton, Figures } from '../../../../system'
import { useWords } from './bits'
import { VENUE_ID } from './model'
import './event-calendar.css'

export type YearMonth = { year: number; month: number }

const cmp = (a: YearMonth, b: YearMonth) => a.year * 12 + a.month - (b.year * 12 + b.month)
const addMonth = (m: YearMonth, n: number): YearMonth => {
  const idx = m.year * 12 + (m.month - 1) + n
  return { year: Math.floor(idx / 12), month: (idx % 12) + 1 }
}
const bandOf = (row: readonly CalendarDay[], i: number): 'first' | 'last' | undefined => {
  if (!row[i]?.isPeak) return undefined
  return row[i - 1]?.isPeak ? (row[i + 1]?.isPeak ? undefined : 'last') : 'first'
}

export type EventCalendarProps = {
  month: YearMonth
  onMonthChange: (m: YearMonth) => void
  picked: readonly IsoDate[]
  onToggle: (iso: IsoDate) => void
  minMonth: YearMonth
  maxMonth: YearMonth
  today: IsoDate
  label: string
  disabled?: boolean
}

export function EventCalendar({ month, onMonthChange, picked, onToggle, minMonth, maxMonth, today, label, disabled }: EventCalendarProps) {
  const f = useFormat()
  const c = useT('common')
  const { t } = useWords()
  const grid = useRef<HTMLDivElement>(null)
  const weeks = useMemo(() => f.monthGrid(month.year, month.month), [f, month.year, month.month])
  const headers = f.weekdayHeaders()
  const names = f.weekdayLabels()
  const soft = useMemo(() => new Set(softDatesFor(VENUE_ID)), [])
  const [focusIso, setFocusIso] = useState<string | null>(null)

  const state = (iso: IsoDate): 'free' | 'busy' | 'past' => (iso < today ? 'past' : venueAvailabilityOn(VENUE_ID, iso).state === 'available' ? 'free' : 'busy')
  const firstFree = weeks.flat().find(d => d.inMonth && state(d.iso) === 'free')?.iso
  const tabIso = focusIso ?? picked.find(p => p.startsWith(`${month.year}-${String(month.month).padStart(2, '0')}`)) ?? firstFree

  const onKey = (e: KeyboardEvent<HTMLDivElement>) => {
    const cur = (e.target as HTMLElement).closest<HTMLElement>('[data-iso]')?.dataset.iso
    if (!cur) return
    const rtl = getComputedStyle(e.currentTarget).direction === 'rtl'
    const delta = { ArrowRight: rtl ? -1 : 1, ArrowLeft: rtl ? 1 : -1, ArrowDown: 7, ArrowUp: -7 }[e.key as 'ArrowRight']
    if (!delta) return
    e.preventDefault()
    const to = engine.addDays(cur, delta)
    setFocusIso(to)
    requestAnimationFrame(() => grid.current?.querySelector<HTMLElement>(`[data-iso="${to}"]`)?.focus())
  }

  return (
    <div className="ge-cal" data-gz="EventCalendar" data-disabled={disabled || undefined} role="group" aria-label={label}>
      <div className="ge-cal__head">
        <BarButton icon="chevron-left" label={c('commonCalendarPreviousMonth')} disabled={cmp(month, minMonth) <= 0} onPress={() => onMonthChange(addMonth(month, -1))} />
        <h3 className="gz-t-ui-title ge-cal__title" aria-live="polite">
          <Figures text={f.date(f.kuwaitDate(month.year, month.month, 1), 'monthYear')} />
        </h3>
        <BarButton icon="chevron-right" label={c('commonCalendarNextMonth')} disabled={cmp(month, maxMonth) >= 0} onPress={() => onMonthChange(addMonth(month, 1))} />
      </div>

      <div ref={grid} className="ge-cal__grid" role="grid" aria-label={label} onKeyDown={onKey}>
        <div className="ge-cal__row" role="row">
          {headers.map((h, i) => (
            <div key={i} role="columnheader" aria-label={names[i]} className="ge-cal__hcell gz-t-caption" data-peak={bandOf(weeks[0] ?? [], i) ?? (weeks[0]?.[i]?.isPeak ? 'mid' : undefined)} data-top="">
              {h}
            </div>
          ))}
        </div>
        {weeks.map((row, r) => (
          <div key={r} className="ge-cal__row" role="row">
            {row.map((d, i) => {
              const band = bandOf(row, i) ?? (d.isPeak ? 'mid' : undefined)
              const bottom = r === weeks.length - 1 ? '' : undefined
              if (!d.inMonth) return <div key={d.iso} role="gridcell" aria-hidden="true" className="ge-cal__cell" data-peak={band} data-bottom={bottom} />
              const iso = d.iso
              const st = state(iso)
              const isPicked = picked.includes(iso)
              const selectable = !disabled && (st === 'free' || isPicked)
              const open = soft.has(iso)
              const parts = [
                f.plain(f.date(iso, 'full')),
                st === 'free' ? c('commonAvailabilityFree') : st === 'past' ? c('commonAvailabilityPast') : c('commonAvailabilityBooked'),
                open ? t('hotelGrowOpenWeekend') : '',
                isPicked ? c('commonCalendarSelected') : '',
              ].filter(Boolean)
              return (
                <div key={iso} role="gridcell" className="ge-cal__cell" data-peak={band} data-bottom={bottom}>
                  <button
                    type="button"
                    className="gz-reset gz-press ge-cal__day"
                    data-iso={iso}
                    data-status={st}
                    data-selected={isPicked || undefined}
                    data-today={iso === today || undefined}
                    aria-pressed={st === 'free' || isPicked ? isPicked : undefined}
                    aria-disabled={!selectable || undefined}
                    aria-label={parts.join(' · ')}
                    tabIndex={iso === tabIso ? 0 : -1}
                    onClick={() => selectable && onToggle(iso)}
                  >
                    <span className="gz-t-cal-day ge-cal__fig">{f.integer(d.day)}</span>
                    {open && !isPicked ? <span className="ge-cal__bead" aria-hidden="true" /> : null}
                  </button>
                </div>
              )
            })}
          </div>
        ))}
      </div>

      <ul className="ge-cal__legend gz-t-caption" aria-hidden="true">
        <li className="ge-cal__legend-item">
          <span className="ge-cal__sw ge-cal__sw--busy" />
          {c('commonAvailabilityBooked')}
        </li>
        <li className="ge-cal__legend-item">
          <span className="ge-cal__sw ge-cal__sw--open" />
          {t('hotelGrowOpenWeekend')}
        </li>
      </ul>
    </div>
  )
}
