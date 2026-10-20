import { useEffect, useId, useMemo, useRef, useState, type KeyboardEvent, type ReactNode } from 'react'
import type { CalendarDay } from '@gz/i18n'
import { useFormat, useT } from '../../i18n'
import { Glyph } from './internal/Glyph'
import { useControllable } from './internal/useControllable'
import { useInputWords } from './internal/copy'
import { Figures } from './internal/Figures'
import { addDaysIso, addMonths, cmpMonth, eachDay, monthOfIso, type Ym } from './internal/calendarModel'
import { SegmentedControl } from './SegmentedControl'
import './internal/base.css'
import './calendar.css'

/**
 * Availability states (ADR 0002 D8, ADR 0004). `peak` is an available day inside a peak band: it is accepted as a status for
 * convenience and normalised to `available` + the band tint. Held (approved for another couple, requests still allowed) is
 * selectable; booked, blocked and closed (past, inside the lead time, outside the season) are not.
 */
export type DayStatus = 'available' | 'held' | 'booked' | 'blocked' | 'closed' | 'peak'

export type CalendarDayInfo = {
  status?: DayStatus
  /** The day's price in integer fils (Prices view; ADR 0010, ADR 0004). */
  price?: number
  /** Force or cancel the peak tint for this day; default follows the country's Thu-Sat band. */
  peak?: boolean
}

export type DateRange = { start: string | null; end: string | null }
export type CalendarView = 'availability' | 'prices'

type Shared = {
  /** `YYYY-MM-DD` keyed facts about days; days without an entry are available (or closed when in the past). */
  days?: Readonly<Record<string, CalendarDayInfo>>
  /** Visible month (controlled) or the initial month. */
  month?: Ym
  defaultMonth?: Ym
  onMonthChange?: (month: Ym) => void
  /** First / last selectable key; days outside are closed and the paging chevrons stop at their months. */
  minDate?: string
  maxDate?: string
  /** `YYYY-MM-DD` of today (marker and past dates). Default: the prototype clock. */
  today?: string
  /** Availability | Prices. Controlled or uncontrolled; the toggle shows when `showViewToggle` (default: when any day has a price). */
  view?: CalendarView
  defaultView?: CalendarView
  onViewChange?: (view: CalendarView) => void
  showViewToggle?: boolean
  /** Caption that carries the unit of the prices (`KD · per guest`): a price never appears without its unit (ADR 0010 D9). */
  priceBasis?: ReactNode
  /** Legend under the grid. `true` (default) lists the states that occur; `false` hides it. */
  legend?: boolean
  /** The selected date line under the grid (the Hijri secondary line shows in Arabic only, ADR 0011 D1). */
  summary?: boolean
  /** Decide selectability yourself (the hotel blocks over `booked` days it owns). */
  isSelectable?: (iso: string, status: DayStatus) => boolean
  /** Accessible name of the whole calendar. */
  label?: string
  className?: string
}

export type CalendarProps = Shared &
  (
    | { mode?: 'single'; value?: string | null; defaultValue?: string | null; onChange?: (value: string | null) => void }
    | { mode: 'range'; value?: DateRange; defaultValue?: DateRange; onChange?: (value: DateRange) => void }
  )

type Cell = { day: CalendarDay; status: DayStatus; peak: boolean; price: number | undefined; selectable: boolean }

const EMPTY_RANGE: DateRange = { start: null, end: null }

/**
 * Month calendar (direction 3 "Calendar cell"). Sunday-first through the formatter's explicit week config, seven flex columns,
 * cells 52 high and at least 44 wide (46 at 360). The Thu to Sat band is one contiguous rose-50 block at the inline-end edge
 * in both languages. Day states are never colour alone: held = gold-700 corner bead, booked = struck figure, blocked = struck
 * figure in a hairline box, closed = ink-400, selected = gold fill + ring, today = ink hairline. Single date or range (a 2 px
 * gold thread connects the endpoints). Availability | Prices toggle, per-day price in the figures voice. Roving-tabindex grid
 * with arrow keys that follow what you see, PageUp / PageDown for months.
 */
export function Calendar(props: CalendarProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useInputWords()
  const uid = useId().replace(/:/g, '')
  const range = props.mode === 'range'
  const today = props.today ?? f.isoDay(f.now())
  const days = props.days ?? {}

  const [raw, setRaw] = useControllable<unknown>(props.value as unknown, (props.defaultValue as unknown) ?? (range ? EMPTY_RANGE : null), props.onChange as ((v: unknown) => void) | undefined)
  const single = range ? null : ((raw as string | null) ?? null)
  const rng: DateRange = range ? ((raw as DateRange) ?? EMPTY_RANGE) : EMPTY_RANGE

  const initialMonth = props.defaultMonth ?? monthOfIso((range ? rng.start : single) ?? today)
  const [month, setMonth] = useControllable<Ym>(props.month, initialMonth, props.onMonthChange)
  const hasPrices = Object.values(days).some(d => d.price !== undefined)
  const [view, setView] = useControllable<CalendarView>(props.view, props.defaultView ?? 'availability', props.onViewChange)
  const showToggle = props.showViewToggle ?? hasPrices
  const prices = view === 'prices'

  const minMonth = props.minDate ? monthOfIso(props.minDate) : undefined
  const maxMonth = props.maxDate ? monthOfIso(props.maxDate) : undefined
  const canPrev = !minMonth || cmpMonth(month, minMonth) > 0
  const canNext = !maxMonth || cmpMonth(month, maxMonth) < 0

  const statusOf = (iso: string): DayStatus => {
    const given = days[iso]?.status
    if (given && given !== 'peak') return given
    if (iso < today || (props.minDate && iso < props.minDate) || (props.maxDate && iso > props.maxDate)) return 'closed'
    return 'available'
  }
  const selectableOf = (iso: string, status: DayStatus) =>
    props.isSelectable ? props.isSelectable(iso, status) : status === 'available' || status === 'held'

  const weeks = useMemo(() => f.monthGrid(month.year, month.month), [f, month.year, month.month])
  const cells: Cell[][] = weeks.map(week =>
    week.map(day => {
      const info = days[day.iso]
      const status = statusOf(day.iso)
      return { day, status, peak: info?.peak ?? (info?.status === 'peak' ? true : day.isPeak), price: info?.price, selectable: selectableOf(day.iso, status) }
    }),
  )

  // One precision per list (ADR 0010 D8): if any visible price has fils, every price shows three decimals.
  const visiblePrices = cells.flat().filter(c => c.day.inMonth && c.price !== undefined).map(c => c.price as number)
  const priceMode = visiblePrices.some(p => p % 1000 !== 0) ? 'exact' : 'browse'

  // ---- selection ------------------------------------------------------------------------------------------------
  const [lastTap, setLastTap] = useState<string | null>(null)
  const pick = (iso: string) => {
    setLastTap(iso)
    if (!range) {
      setRaw(single === iso ? null : iso)
      return
    }
    const { start, end } = rng
    if (!start || (start && end)) return setRaw({ start: iso, end: null })
    if (iso < start) return setRaw({ start: iso, end: null })
    // A range may not swallow a day the client cannot choose: restart from the tapped day instead.
    const between = eachDay(start, iso).some(d => !selectableOf(d, statusOf(d)))
    if (between) return setRaw({ start: iso, end: null })
    setRaw({ start, end: iso })
  }

  const selStart = range ? rng.start : single
  const selEnd = range ? (rng.end ?? rng.start) : single
  const rangeRole = (iso: string): 'start' | 'end' | 'mid' | 'only' | undefined => {
    if (!selStart || !selEnd) return undefined
    if (iso < selStart || iso > selEnd) return undefined
    if (selStart === selEnd) return 'only'
    return iso === selStart ? 'start' : iso === selEnd ? 'end' : 'mid'
  }

  // ---- roving focus ---------------------------------------------------------------------------------------------
  const [focusIso, setFocusIso] = useState<string | null>(null)
  const grid = useRef<HTMLDivElement>(null)
  const pendingFocus = useRef(false)
  const inMonth = (iso: string) => {
    const m = monthOfIso(iso)
    return m.year === month.year && m.month === month.month
  }
  const firstOfMonth = `${month.year}-${String(month.month).padStart(2, '0')}-01`
  const tabIso = focusIso && inMonth(focusIso) ? focusIso : selStart && inMonth(selStart) ? selStart : inMonth(today) ? today : firstOfMonth

  useEffect(() => {
    if (!pendingFocus.current) return
    pendingFocus.current = false
    grid.current?.querySelector<HTMLElement>(`[data-iso="${focusIso}"]`)?.focus()
  }, [focusIso, month.year, month.month])

  const moveFocus = (iso: string) => {
    pendingFocus.current = true
    setFocusIso(iso)
    const m = monthOfIso(iso)
    if (m.year !== month.year || m.month !== month.month) setMonth(m)
  }

  const onKey = (e: KeyboardEvent<HTMLDivElement>) => {
    const cur = (e.target as HTMLElement).closest<HTMLElement>('[data-iso]')?.dataset.iso
    if (!cur) return
    const rtl = getComputedStyle(e.currentTarget).direction === 'rtl'
    let to: string | null = null
    switch (e.key) {
      case 'ArrowRight': to = addDaysIso(cur, rtl ? -1 : 1); break
      case 'ArrowLeft': to = addDaysIso(cur, rtl ? 1 : -1); break
      case 'ArrowDown': to = addDaysIso(cur, 7); break
      case 'ArrowUp': to = addDaysIso(cur, -7); break
      case 'Home': to = addDaysIso(cur, -weekdayIndex(cur)); break
      case 'End': to = addDaysIso(cur, 6 - weekdayIndex(cur)); break
      case 'PageDown': to = shiftMonth(cur, e.shiftKey ? 12 : 1); break
      case 'PageUp': to = shiftMonth(cur, e.shiftKey ? -12 : -1); break
      default: return
    }
    e.preventDefault()
    if (props.minDate && to < props.minDate) return
    if (props.maxDate && to > props.maxDate) return
    moveFocus(to)
  }
  const weekdayIndex = (iso: string) => {
    for (const row of weeks) {
      const i = row.findIndex(d => d.iso === iso)
      if (i >= 0) return i
    }
    return 0
  }
  const shiftMonth = (iso: string, n: number) => {
    const base = monthOfIso(iso)
    const target = addMonths(base, n)
    const dayNum = Number(iso.slice(8, 10))
    const last = new Date(Date.UTC(target.year, target.month, 0)).getUTCDate()
    return `${target.year}-${String(target.month).padStart(2, '0')}-${String(Math.min(dayNum, last)).padStart(2, '0')}`
  }

  // ---- labels ---------------------------------------------------------------------------------------------------
  const statusWord = (s: DayStatus, iso: string): string | undefined => {
    switch (s) {
      case 'held': return t('commonAvailabilityHeld')
      case 'booked': return t('commonAvailabilityBooked')
      case 'blocked': return t('commonAvailabilityBlocked')
      case 'closed': return iso < today ? t('commonAvailabilityPast') : t('commonAvailabilityUnavailable')
      default: return t('commonAvailabilityAvailable')
    }
  }
  const labelOf = (c: Cell) => {
    const parts = [f.plain(f.date(c.day.iso, 'full')), statusWord(c.status, c.day.iso)]
    if (c.price !== undefined && (c.status === 'available' || c.status === 'held')) parts.push(f.plain(f.money(c.price, { mode: priceMode })))
    if (c.day.iso === today) parts.push(t('commonCalendarToday'))
    const role = rangeRole(c.day.iso)
    if (role === 'start') parts.push(w('startDate'))
    else if (role === 'end') parts.push(w('endDate'))
    else if (role === 'only' || (role && !range)) parts.push(t('commonCalendarSelected'))
    return parts.filter(Boolean).join(' · ')
  }

  const titleDate = f.kuwaitDate(month.year, month.month, 1)
  const headers = f.weekdayHeaders()
  const fullNames = f.weekdayLabels()
  const rowsLast = cells.length - 1

  // Legend lists the states that occur in the visible month (plus the structural ones).
  const present = new Set<DayStatus | 'peak'>()
  for (const c of cells.flat()) {
    if (!c.day.inMonth) continue
    if (c.status === 'held' || c.status === 'booked' || c.status === 'blocked') present.add(c.status)
    if (c.peak && c.status !== 'closed') present.add('peak')
  }
  const legendItems = (['held', 'booked', 'blocked', 'peak'] as const).filter(s => present.has(s))

  // ---- summary --------------------------------------------------------------------------------------------------
  let summary: ReactNode = null
  if (props.summary) {
    if (!range && single) {
      const d = f.dateWithHijri(single)
      summary = (
        <>
          <span className="gz-cal__sum-main">
            <Figures text={d.primary} />
          </span>
          {d.secondary ? (
            <span className="gz-cal__sum-sub gz-t-caption">
              <Figures text={d.secondary} />
            </span>
          ) : null}
        </>
      )
    } else if (range && rng.start) {
      summary = (
        <span className="gz-cal__sum-main">
          <Figures
            text={
              rng.end && rng.end !== rng.start
                ? w('rangeFromTo', { from: f.plain(f.date(rng.start, 'short')), to: f.plain(f.date(rng.end, 'short')) })
                : f.date(rng.start, 'full')
            }
          />
        </span>
      )
    }
  }

  return (
    <div className={['gz-cal', props.className ?? ''].filter(Boolean).join(' ')} data-gz="Calendar" role="group" aria-label={props.label}>
      {showToggle ? (
        <SegmentedControl
          label={`${t('commonCalendarAvailability')} / ${t('commonCalendarPrices')}`}
          options={[
            { value: 'availability', label: t('commonCalendarAvailability') },
            { value: 'prices', label: t('commonCalendarPrices') },
          ]}
          value={view}
          onChange={setView}
        />
      ) : null}

      <div className="gz-cal__head">
        <button type="button" className="gz-in-btn gz-in-action gz-cal__nav gz-press" aria-label={t('commonCalendarPreviousMonth')} disabled={!canPrev} onClick={() => setMonth(addMonths(month, -1))}>
          <Glyph name="chevron-left" size="md" />
        </button>
        <h3 id={`${uid}-title`} className="gz-cal__title gz-t-ui-title" aria-live="polite">
          <Figures text={f.date(titleDate, 'monthYear')} />
        </h3>
        <button type="button" className="gz-in-btn gz-in-action gz-cal__nav gz-press" aria-label={t('commonCalendarNextMonth')} disabled={!canNext} onClick={() => setMonth(addMonths(month, 1))}>
          <Glyph name="chevron-right" size="md" />
        </button>
      </div>

      <div ref={grid} className="gz-cal__grid" role="grid" aria-labelledby={`${uid}-title`} aria-multiselectable={range || undefined} aria-describedby={`${uid}-hint`} onKeyDown={onKey}>
        <div className="gz-cal__row gz-cal__row--head" role="row">
          {headers.map((h, i) => {
            const peakCol = weeks[0]?.[i]?.isPeak ?? false
            return (
              <div key={i} role="columnheader" aria-label={fullNames[i]} className="gz-cal__hcell gz-t-caption" data-peak={peakCol ? peakPos(weeks[0] ?? [], i) : undefined} data-top="">
                {h}
              </div>
            )
          })}
        </div>
        <div key={`${month.year}-${month.month}`} className="gz-cal__body gz-fade-in">
          {cells.map((row, r) => (
            <div key={r} className="gz-cal__row" role="row">
              {row.map((c, i) => {
                const iso = c.day.iso
                const role = c.day.inMonth ? rangeRole(iso) : undefined
                const peak = c.peak && c.status !== 'closed' ? peakPos(row.map(x => ({ isPeak: x.peak && x.status !== 'closed' })) as CalendarDay[], i) : undefined
                const edge = r === rowsLast ? '' : undefined
                if (!c.day.inMonth) {
                  return <div key={iso} role="gridcell" aria-hidden="true" className="gz-cal__cell" data-peak={peak} data-bottom={edge} />
                }
                const interactive = c.selectable
                const showPrice = prices && c.price !== undefined && (c.status === 'available' || c.status === 'held')
                const mp = c.price !== undefined ? f.moneyParts(c.price, { mode: priceMode }) : null
                return (
                  <div key={iso} role="gridcell" aria-selected={role ? true : undefined} className="gz-cal__cell" data-peak={peak} data-bottom={edge} data-range={role}>
                    {role && role !== 'only' ? <span className="gz-cal__thread" data-cap={role === 'start' ? 'start' : role === 'end' ? 'end' : undefined} aria-hidden="true" /> : null}
                    <button
                      type="button"
                      data-iso={iso}
                      className="gz-in-btn gz-cal__day gz-press"
                      data-status={c.status}
                      data-selected={role === 'start' || role === 'end' || role === 'only' ? '' : undefined}
                      data-inrange={role === 'mid' ? '' : undefined}
                      data-today={iso === today ? '' : undefined}
                      data-tap={lastTap === iso ? '' : undefined}
                      tabIndex={iso === tabIso ? 0 : -1}
                      aria-disabled={interactive ? undefined : true}
                      aria-label={labelOf(c)}
                      onClick={() => interactive && pick(iso)}
                      onFocus={() => setFocusIso(iso)}
                    >
                      <span className="gz-cal__fig gz-t-cal-day">{f.plain(f.integer(c.day.day))}</span>
                      {showPrice && mp ? <span className="gz-cal__price gz-t-cal-price">{mp.fractionIsZero && priceMode === 'browse' ? mp.integer : mp.amount}</span> : null}
                      {c.status === 'held' ? <span className="gz-cal__held" aria-hidden="true" /> : null}
                    </button>
                  </div>
                )
              })}
            </div>
          ))}
        </div>
      </div>

      {prices && props.priceBasis ? <p className="gz-cal__basis gz-t-caption">{props.priceBasis}</p> : null}

      {props.legend !== false && legendItems.length > 0 ? (
        <ul className="gz-cal__legend gz-t-caption" aria-label={t('commonAvailabilityAvailable')}>
          {legendItems.map(s => (
            <li key={s} className="gz-cal__legend-item">
              <span className="gz-cal__sw" data-sw={s} aria-hidden="true">
                {s === 'held' ? (
                  <>
                    <span className="gz-cal__sw-fig gz-cal__sw-fig--plain gz-t-cal-day">{f.plain(f.integer(14))}</span>
                    <span className="gz-cal__held" />
                  </>
                ) : s === 'peak' ? null : <span className="gz-cal__sw-fig gz-t-cal-day">{f.plain(f.integer(s === 'booked' ? 12 : 13))}</span>}
              </span>
              <span>{s === 'held' ? t('commonAvailabilityHeld') : s === 'booked' ? t('commonAvailabilityBooked') : s === 'blocked' ? t('commonAvailabilityBlocked') : t('commonCalendarPeak')}</span>
            </li>
          ))}
        </ul>
      ) : null}

      {summary ? (
        <p className="gz-cal__summary gz-t-body-s" aria-live="polite">
          {summary}
        </p>
      ) : null}
      <span id={`${uid}-hint`} className="gz-sr-only">
        {w('calendarHint')}
      </span>
    </div>
  )
}

/** first | mid | last | only: where a peak column sits in its contiguous band (drives the band's rounded outer corners). */
function peakPos(row: ReadonlyArray<Pick<CalendarDay, 'isPeak'>>, i: number): 'first' | 'mid' | 'last' | 'only' {
  const before = i > 0 && row[i - 1]?.isPeak
  const after = i < row.length - 1 && row[i + 1]?.isPeak
  if (before && after) return 'mid'
  if (before) return 'last'
  if (after) return 'first'
  return 'only'
}
