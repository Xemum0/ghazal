// MultiDateCalendar: a month grid where a venue picks up to N free dates (HL-DCSN-03). The system Calendar picks one date or one range, so
// this flow-local twin keeps its anatomy (Sunday-first from the formatter, seven flex columns, 52 high cells at least 44 wide, the Thu to
// Sat band at the inline-end edge, selected = gold fill with the canvas and gold-600 rings) and adds what the proposal needs: several
// picks, a price caption on every free day, busy days struck through, the original date marked, and a "taken while open" state.
// Requested as a shared `Calendar mode="multiple"` in docs/engineering/requests.md.
import { useMemo, useRef, useState, type KeyboardEvent } from 'react'
import type { CalendarDay } from '@gz/i18n'
import { engine, type IsoDate } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { BarButton, Figures } from '../../../../system'
import './multi-date-calendar.css'

export type FreeDay = { fils: number }
export type YearMonth = { year: number; month: number }

export type MultiDateCalendarProps = {
  month: YearMonth
  onMonthChange: (m: YearMonth) => void
  /** Free dates of the hall and session with their re-quoted total (integer fils). A date that is not here is busy or closed. */
  free: Readonly<Record<string, FreeDay>>
  /** Dates picked so far (order is the order the couple will see). */
  picked: readonly IsoDate[]
  max: number
  onToggle: (iso: IsoDate) => void
  /** The date being replaced: marked, never selectable. */
  original?: IsoDate
  /** Dates that were taken while the sheet was open: struck and refused. */
  taken?: readonly IsoDate[]
  /** First and last month the venue may browse (the 90-day horizon). */
  minMonth: YearMonth
  maxMonth: YearMonth
  today: IsoDate
  label: string
}

const cmp = (a: YearMonth, b: YearMonth) => a.year * 12 + a.month - (b.year * 12 + b.month)
const addMonth = (m: YearMonth, n: number): YearMonth => {
  const idx = m.year * 12 + (m.month - 1) + n
  return { year: Math.floor(idx / 12), month: (idx % 12) + 1 }
}

/** Where a day sits in the Thu-Sat band of its row: `first`, `last`, `only`, or none. */
const bandOf = (row: readonly CalendarDay[], i: number): 'first' | 'last' | undefined => {
  if (!row[i]?.isPeak) return undefined
  return row[i - 1]?.isPeak ? (row[i + 1]?.isPeak ? undefined : 'last') : 'first'
}

export function MultiDateCalendar({ month, onMonthChange, free, picked, max, onToggle, original, taken = [], minMonth, maxMonth, today, label }: MultiDateCalendarProps) {
  const f = useFormat()
  const t = useT('common')
  const th = useT('hotel-decisions')
  const grid = useRef<HTMLDivElement>(null)
  const weeks = useMemo(() => f.monthGrid(month.year, month.month), [f, month.year, month.month])
  const headers = f.weekdayHeaders()
  const names = f.weekdayLabels()
  const canPrev = cmp(month, minMonth) > 0
  const canNext = cmp(month, maxMonth) < 0
  const full = picked.length >= max
  const [focusIso, setFocusIso] = useState<string | null>(null)
  const firstFree = weeks.flat().find(d => d.inMonth && free[d.iso])?.iso
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

  const money = (fils: number) => {
    const p = f.moneyParts(fils, { mode: 'browse' })
    return `${p.integer}${p.fraction}`
  }

  return (
    <div className="gzd-cal" data-gz="MultiDateCalendar" role="group" aria-label={label}>
      <div className="gzd-cal__head">
        <BarButton icon="chevron-left" label={t('commonCalendarPreviousMonth')} disabled={!canPrev} onPress={() => onMonthChange(addMonth(month, -1))} />
        <div className="gzd-cal__titles">
          <h3 className="gz-t-ui-title gzd-cal__title" aria-live="polite">
            <Figures text={f.date(f.kuwaitDate(month.year, month.month, 1), 'monthYear')} />
          </h3>
        </div>
        <BarButton icon="chevron-right" label={t('commonCalendarNextMonth')} disabled={!canNext} onPress={() => onMonthChange(addMonth(month, 1))} />
      </div>

      <div ref={grid} className="gzd-cal__grid" role="grid" aria-label={label} onKeyDown={onKey}>
        <div className="gzd-cal__row" role="row">
          {headers.map((h, i) => (
            <div key={i} role="columnheader" aria-label={names[i]} className="gzd-cal__hcell gz-t-caption" data-peak={bandOf(weeks[0] ?? [], i) ?? (weeks[0]?.[i]?.isPeak ? 'mid' : undefined)} data-top="">
              {h}
            </div>
          ))}
        </div>
        {weeks.map((row, r) => (
          <div key={r} className="gzd-cal__row" role="row">
            {row.map((d, i) => {
              const band = bandOf(row, i) ?? (d.isPeak ? 'mid' : undefined)
              const bottom = r === weeks.length - 1 ? '' : undefined
              if (!d.inMonth) return <div key={d.iso} role="gridcell" aria-hidden="true" className="gzd-cal__cell" data-peak={band} data-bottom={bottom} />
              const iso = d.iso
              const isOriginal = iso === original
              const isTaken = taken.includes(iso)
              const day = free[iso]
              const isPicked = picked.includes(iso)
              const selectable = Boolean(day) && !isOriginal && !isTaken && (isPicked || !full)
              const status = isTaken ? 'taken' : isOriginal ? 'original' : day ? 'free' : iso < today ? 'past' : 'busy'
              const parts = [
                f.plain(f.date(iso, 'full')),
                isOriginal ? th('hotelDecisionsProposeOriginal') : isTaken ? th('hotelDecisionsProposeTakenBadge') : day ? t('commonAvailabilityFree') : iso < today ? t('commonAvailabilityPast') : t('commonAvailabilityBooked'),
                day && !isOriginal ? f.plain(f.money(day.fils, { mode: 'browse' })) : '',
                isPicked ? t('commonCalendarSelected') : '',
              ].filter(Boolean)
              return (
                <div key={iso} role="gridcell" className="gzd-cal__cell" data-peak={band} data-bottom={bottom}>
                  <button
                    type="button"
                    className="gz-reset gz-press gzd-cal__day"
                    data-iso={iso}
                    data-status={status}
                    data-selected={isPicked || undefined}
                    data-today={iso === today || undefined}
                    aria-pressed={day && !isOriginal ? isPicked : undefined}
                    aria-disabled={!selectable || undefined}
                    aria-label={parts.join(' · ')}
                    tabIndex={iso === tabIso ? 0 : -1}
                    onClick={() => selectable && onToggle(iso)}
                  >
                    <span className="gz-t-cal-day gzd-cal__fig">{f.integer(d.day)}</span>
                    {isPicked && day && !isOriginal && !isTaken ? <span className="gz-t-cal-price gzd-cal__price">{money(day.fils)}</span> : null}
                    {isOriginal ? <span className="gzd-cal__orig" aria-hidden="true" /> : null}
                  </button>
                </div>
              )
            })}
          </div>
        ))}
      </div>
    </div>
  )
}
