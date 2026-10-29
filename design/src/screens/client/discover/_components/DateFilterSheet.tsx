// DateFilterSheet: the body of CL-DISC-06 (see that file for the contract). A component so Results and the Filters sheet can open it as a node sheet
// with their own hand-back (`onApply`), and the screen file stays a thin wrapper that reads the same from the navigation params.
// Text diet (ADR 0034): the calendar is the screen. Two chips (Not decided, Any month), the info glyph beside the close glyph, nearest dates as calendar chips, the
// CTA with the live count and "Clear". The density legend (three sample figures, one word each) and the seven-day limit live behind the info
// glyph: the marks on the days (plain, bead, struck) read without them. No sentence on the screen.
import { useLayoutEffect, useMemo, useRef, useState } from 'react'
import * as mock from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { storyBrief } from '../../../../shell/state/defaults'
import {
  BarButton, Banner, Button, Calendar, Chip, ErrorState, Figures, InfoButton, useNav,
  type CalendarDayInfo, type DateRange,
} from '../../../../system'
import { NO_FILTERS, freeOn, nearestFreeDates, results, type Filters } from './data'
import { useDayLabel } from './labels'
import { useScenario } from './scenario'
import { useDiscover } from './state'
import { useSheetFill } from './useSheetFill'
import './date-filter.css'

type Ym = { year: number; month: number }
type View = 'calendar' | 'months'
const MAX_DAYS = 7
const MONTHS_AHEAD = 12
const EMPTY_DATE = '2026-12-31'

const monthOf = (iso: string): Ym => ({ year: Number(iso.slice(0, 4)), month: Number(iso.slice(5, 7)) })

export function DateFilterSheet({ onApply, state }: { onApply?: (patch: Partial<Filters>) => void; state?: string }) {
  const t = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const dayLabel = useDayLabel()
  const s = useScenario(state)
  const fill = useSheetFill()
  const { safeTop } = useDevice()
  // A static frame of an id missing from SHEET_SCREENS (request filed) draws this as a screen: no Sheet container, so no gutter and no top inset.
  const root = useRef<HTMLDivElement>(null)
  const [bare, setBare] = useState(false)
  useLayoutEffect(() => setBare(!root.current?.closest('.gz-sheet')), [])
  const live = s.live
  const brief = s.brief
  const today = mock.clock.today()

  const loading = state === 'loading-density'
  const errored = state === 'error'
  const offline = state === 'offline' || !s.online

  // The range the filter already holds (live) or the one a frame states.
  const held: DateRange = useMemo(() => {
    if (!live) {
      if (state === 'range-selected') return { start: '2027-01-14', end: '2027-01-16' }
      if (state === 'no-venues-on-date') return { start: EMPTY_DATE, end: EMPTY_DATE }
      return { start: storyBrief().date ?? null, end: storyBrief().date ?? null }
    }
    const filters = useDiscover.getState().filters
    if (filters.dates) return { start: filters.dates.from, end: filters.dates.to }
    return brief.date && brief.dateMode === 'exact' ? { start: brief.date, end: brief.date } : { start: null, end: null }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
  const [range, setRange] = useState<DateRange>(held)
  const [view, setView] = useState<View>(!live && state === 'flexible-month' ? 'months' : 'calendar')
  const [month, setMonth] = useState<Ym>(monthOf(held.start ?? today))
  const [flex, setFlex] = useState<string | null>(!live && state === 'flexible-month' ? '2027-03-01' : null)

  // ---- the density of the visible month: how many of the Brief's venues are free on each day, as a shape on the day
  const days = useMemo<Record<string, CalendarDayInfo>>(() => {
    if (loading || offline || errored) return {}
    const first = f.kuwaitDate(month.year, month.month, 1)
    const out: Record<string, CalendarDayInfo> = {}
    for (let i = 0; i < 31; i += 1) {
      const d = mock.engine.addDays(f.isoDay(first), i)
      if (monthOf(d).month !== month.month) break
      if (d < today) continue
      const { free, of } = freeOn(brief, d)
      out[d] = { status: free === 0 ? 'booked' : free >= Math.max(2, Math.ceil(of / 2)) ? 'available' : 'held' }
    }
    return out
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [month.year, month.month, loading, offline, errored, brief.governorateIds, brief.guests, brief.audience])

  // ---- what the footer says: the count for the day or the range, by the same function Results runs
  const from = range.start
  const to = range.end ?? range.start
  const single = from !== null && from === to
  const filterOf = (): Filters => (from && to && !single ? { ...NO_FILTERS, dates: { from, to } } : { ...NO_FILTERS, available: true })
  const count = useMemo(() => {
    if (!from) return null
    return single ? results({ ...brief, date: from }, { ...NO_FILTERS, available: true }).length : results(brief, filterOf()).length
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [from, to, brief.governorateIds, brief.guests, brief.audience])
  const near = useMemo(() => (single && count === 0 && from ? nearestFreeDates(brief, 3, from) : []), [single, count, from, brief])

  const cta = loading || offline || errored || from === null ? t('clientDiscoverDatesApply') : count === 0 ? t('clientDiscoverDatesNone') : t('clientDiscoverCtaCount', { count: count ?? 0 })

  // ---- actions
  const pick = (next: DateRange) => {
    // A range is at most seven days: dragging further keeps the first seven.
    const end = next.start && next.end && mock.engine.addDays(next.start, MAX_DAYS - 1) < next.end ? mock.engine.addDays(next.start, MAX_DAYS - 1) : next.end
    setFlex(null)
    setRange({ start: next.start, end })
  }
  /** Hands the filter side of the choice to whoever opened the sheet: the Filters draft, or the Results filters themselves. */
  const hand = (patch: Partial<Filters>) => {
    if (onApply) return onApply(patch)
    const st = useDiscover.getState()
    st.replaceFilters({ ...st.filters, ...patch })
  }
  const apply = () => {
    if (!live) return nav.closeSheet()
    if (flex) {
      s.setBrief({ date: flex, dateMode: 'flexible_month' })
      hand({ dates: null, available: false })
    } else if (from && to) {
      // One day is the Brief date and the availability filter; a range is its own filter (the Brief date is its first day).
      s.setBrief({ date: from, dateMode: 'exact' })
      hand(single ? { dates: null, available: true } : { dates: { from, to }, available: false })
    }
    nav.closeSheet()
  }
  const clear = () => {
    setRange({ start: null, end: null })
    setFlex(null)
    if (!live) return
    s.setBrief({ date: null, dateMode: 'undecided' })
    hand({ dates: null, available: false })
  }
  const undecided = () => {
    setRange({ start: null, end: null })
    setFlex(null)
    setView('calendar')
  }
  const pickNear = (d: string) => setRange({ start: d, end: d })

  const start = monthOf(today)
  const months: Ym[] = Array.from({ length: MONTHS_AHEAD }, (_, i) => {
    const n = start.month - 1 + i
    return { year: start.year + Math.floor(n / 12), month: (n % 12) + 1 }
  })
  const monthText = (m: Ym) => f.date(f.kuwaitDate(m.year, m.month, 1), 'monthYear')
  const sameMonth = (iso: string | null, m: Ym) => iso !== null && monthOf(iso).year === m.year && monthOf(iso).month === m.month

  // The legend and the limit, behind the info glyph: the same three marks the days carry (plain figure, bead, struck figure), one word each.
  const legend = (
    <>
      <ul className="gzd-dl__legend" aria-label={t('clientDiscoverDatesLegend')} data-gz-id="dates.legend">
        {(['many', 'few', 'none'] as const).map(k => (
          <li key={k} className="gzd-dl__legend-item">
            <span className="gzd-dl__sample" data-k={k} aria-hidden="true">
              <span className="gz-t-cal-day">{f.plain(f.integer(k === 'many' ? 13 : k === 'few' ? 14 : 12))}</span>
            </span>
            <span>{t(k === 'many' ? 'clientDiscoverDatesMany' : k === 'few' ? 'clientDiscoverDatesFew' : 'clientDiscoverDatesNoneLegend')}</span>
          </li>
        ))}
      </ul>
      <p className="gzd-dl__hint">{t('clientDiscoverDatesHint', { days: MAX_DAYS })}</p>
    </>
  )

  return (
    <div ref={root} className={`gzd-dl${bare ? ' gzd-dl--bare' : ''}`} data-gz-id="dates.sheet" style={bare ? { paddingBlockStart: safeTop } : { blockSize: fill }} aria-busy={loading || undefined}>
      <header className="gz-sheet__header" data-gz-id="sheet.header">
        <h2 className="gz-sheet__title gz-t-d1">{t('clientDiscoverDatesTitle')}</h2>
        {view === 'calendar' && !loading && !offline && !errored ? (
          <InfoButton title={c('commonCalendarAvailability')}>
            {legend}
          </InfoButton>
        ) : null}
        <BarButton icon="close" label={c('commonActionClose')} onPress={() => nav.closeSheet()} dataId="sheet.close" />
      </header>

      <div className="gzd-dl__scroll gz-no-scrollbar">
        {offline ? (
          <div className="gzd-dl__banner">
            <Banner tone="offline" shape="card">{c('commonStateOffline')}</Banner>
          </div>
        ) : null}

        {errored ? (
          <ErrorState kind="load" fill={false} onRetry={() => undefined} />
        ) : (
          <div className="gzd-dl__panel">
            <div className="gzd-dl__alts" role="group" aria-label={t('clientDiscoverDatesTitle')}>
              <Chip selected={view === 'calendar' && range.start === null && flex === null && !loading} onClick={undecided}>
                {c('commonLabelNotDecided')}
              </Chip>
              <Chip menu iconStart="calendar-dots" selected={view === 'months' || flex !== null} onClick={() => setView(v => (v === 'months' ? 'calendar' : 'months'))}>
                {flex ? <Figures text={f.date(flex, 'monthYear')} /> : t('clientDiscoverDatesFlexible')}
              </Chip>
            </div>

            {view === 'calendar' ? (
              <>
                <Calendar
                  mode="range"
                  value={range}
                  onChange={pick}
                  month={month}
                  onMonthChange={setMonth}
                  days={days}
                  isSelectable={(iso, status) => status !== 'closed' && iso >= today}
                  maxDate={mock.meta.availabilityWindow.to}
                  summary={false}
                  legend={false}
                  label={t('clientDiscoverDatesTitle')}
                />
                {near.length > 0 ? (
                  <section className="gzd-dl__near" data-gz-id="dates.near">
                    <div className="gzd-dl__nearchips gz-no-scrollbar" role="group" aria-label={t('clientDiscoverResultsNoneDates')}>
                      {near.map(d => (
                        <Chip key={d} iconStart="calendar" onClick={() => pickNear(d)}>
                          <Figures text={dayLabel(d)} />
                        </Chip>
                      ))}
                    </div>
                  </section>
                ) : null}
              </>
            ) : (
              <section className="gzd-dl__months" aria-label={t('clientDiscoverDatesFlexible')}>
                <div className="gzd-dl__monthgrid" role="group">
                  {months.map(m => (
                    <Chip
                      key={`${m.year}-${m.month}`}
                      selected={sameMonth(flex, m)}
                      onClick={() => {
                        setFlex(f.isoDay(f.kuwaitDate(m.year, m.month, 1)))
                        setRange({ start: null, end: null })
                      }}
                    >
                      <Figures text={monthText(m)} />
                    </Chip>
                  ))}
                </div>
              </section>
            )}
          </div>
        )}
      </div>

      <div className="gzd-dl__foot" data-gz-id="dates.foot">
        <Button variant="primary" fullWidth onClick={apply} loading={loading} disabled={errored || (!flex && count === 0)}>
          <Figures text={flex ? t('clientDiscoverDatesApply') : cta} />
        </Button>
        <div className="gzd-dl__clear">
          <Button variant="tertiary" onClick={clear}>
            {t('clientDiscoverDatesClear')}
          </Button>
        </div>
      </div>
    </div>
  )
}
