// HL-CALN-01 Month calendar (tab root): the month at a glance with the chosen day's agenda beneath it. Entry point for blocking, reopening,
// range select and soft-date mode (the unsold weekend dates worth an offer). Sunday-first, Thu-Sat on the rose-tint peak band, one mark per
// hall (solid = booked, ring = on hold, dash = blocked, gold bead = a request that claims nothing); the key to the marks is behind the (i).
// Text diet (ADR 0034): three glyphs for the views, one word per hall chip, the date as the agenda heading (it opens the day), facts as glyph
// and value, no sentence on the screen. Words per state: see the hand-back of the diet pass.
// Requirements: HA-CAL-01, HA-CAL-04, HA-CAL-05, HA-CAL-06, HA-CAL-07, HA-CAL-09, HA-DASH-07
// States: loading, empty, error, offline, range-select, soft-date-mode, hall-filter, calendar-nudge
// Block in three taps: Calendar, the date, Block (the lock in the bar opens the sheet on the chosen date). Range select: "Select dates" (press and hold then drag, or tap a start and an end).
import { useEffect, useRef, useState } from 'react'
import { useFormat } from '../../../i18n'
import { ActionBar, ChipGroup, EmptyState, ErrorState, Icon, IconButton, IconListRow, PullToRefresh, Screen, useNav } from '../../../system'
import type { DateSpan } from '../../../system'
import { Agenda } from './_components/Agenda'
import { CalTop, HallChips, PeriodHead, ViewSwitch } from './_components/Chrome'
import { MonthKey } from './_components/Legend'
import { MonthGrid } from './_components/MonthGrid'
import { Nudge } from './_components/Nudge'
import { RangeBar } from './_components/RangeBar'
import { RangeHint } from './_components/RangeHint'
import { MonthSkeleton } from './_components/Skeletons'
import { DEMO_RANGE, SOFT_DATES, SOFT_WINDOW_DAYS, TODAY, canBlock, datesOfSpan, hallsFor, useClaims } from './_components/data'
import { Fig, Fx, roleFrom, useLive, useMonthTitle, useSpanText, useWords } from './_components/calBits'
import { useCal, type YearMonth } from './_components/store'
import './HL-CALN-01.css'

export const states = ['loading', 'empty', 'error', 'offline', 'range-select', 'soft-date-mode', 'hall-filter', 'calendar-nudge']

const NONE: DateSpan = { start: null, end: null }
const DEC: YearMonth = { year: 2026, month: 12 }
const MAJLIS = 'V01-majlis'
const TODAY_YM: YearMonth = { year: Number(TODAY.slice(0, 4)), month: Number(TODAY.slice(5, 7)) }

export default function CalendarMonth({ state }: { state?: string }) {
  const f = useFormat()
  const nav = useNav()
  const { t, c } = useWords()
  const live = useLive()
  const monthTitle = useMonthTitle()
  const spanText = useSpanText()
  const role = roleFrom(nav.params.role)
  const may = canBlock(role)

  // A static frame draws its own state; the player reads the shared memory so the three views stay in step.
  const framed = state !== undefined
  const store = useCal()
  const [frameYm, setFrameYm] = useState<YearMonth>(state === 'range-select' ? DEC : store.ym)
  const [frameHall, setFrameHall] = useState(state === 'hall-filter' ? MAJLIS : 'all')
  const ym = framed ? frameYm : store.ym
  const hall = framed ? frameHall : store.hall
  const setYm = framed ? setFrameYm : store.setYm
  const setHall = framed ? setFrameHall : store.setHall

  const [selecting, setSelecting] = useState(state === 'range-select')
  const [range, setRange] = useState<DateSpan>(state === 'range-select' ? { start: DEMO_RANGE.start, end: DEMO_RANGE.end } : NONE)
  const [soft, setSoft] = useState(state === 'soft-date-mode')

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const empty = state === 'empty'
  const all = useClaims()
  const claims = empty ? [] : all
  const halls = hallsFor(hall)
  const dates = datesOfSpan(range.start, range.end)

  // After a block or an open the calendar updates in place; leave range select behind.
  const seen = useRef(all)
  useEffect(() => {
    if (seen.current === all) return
    seen.current = all
    setSelecting(false)
    setRange(NONE)
  }, [all])

  const openBlock = (opts: { start?: string | null; end?: string | null; hallId?: string | null; mode?: 'block' | 'open' }) =>
    nav.openSheet('HL-CALN-04', { params: { mode: opts.mode ?? 'block', start: opts.start ?? null, end: opts.end ?? null, hallIds: opts.hallId ? [opts.hallId] : undefined, role } })

  const toggleSelect = () => {
    setSelecting(s => !s)
    setRange(NONE)
    setSoft(false)
  }

  const top = (
    <CalTop
      offline={offline}
      actions={
        may && !offline && !loading && !error
          ? { select: { pressed: selecting, onPress: toggleSelect }, block: () => openBlock(selecting ? { start: range.start, end: range.end } : { start: store.selected, end: store.selected }) }
          : undefined
      }
    />
  )

  const bottom = soft ? (
    <ActionBar action={{ label: t('hotelCalendarCreateOffer'), onPress: () => nav.push('HL-GROW-02', { dates: SOFT_DATES }), disabled: offline }} />
  ) : selecting ? (
    <RangeBar
      summary={spanText(range.start, range.end)}
      count={dates.length}
      role={role}
      offline={offline}
      onClear={() => setRange(NONE)}
      onBlock={() => openBlock({ start: range.start, end: range.end })}
      onOpen={() => openBlock({ start: range.start, end: range.end, mode: 'open' })}
      onOffer={() => nav.push('HL-GROW-02', { dates })}
    />
  ) : undefined

  const gotoToday = () => {
    store.select(TODAY)
    setYm(TODAY_YM)
  }
  const step = (d: number) => {
    const idx = ym.year * 12 + (ym.month - 1) + d
    setYm({ year: Math.floor(idx / 12), month: (idx % 12) + 1 })
  }
  const away = ym.year !== TODAY_YM.year || ym.month !== TODAY_YM.month || store.selected !== TODAY

  let body
  if (loading) body = <MonthSkeleton />
  else if (error) body = <ErrorState kind="load" onRetry={() => nav.replace('HL-CALN-01')} />
  else {
    body = (
      <>
        {role === 'accountant' ? (
          <p className="cal-m__readonly gz-t-caption">
            <Icon name="eye" size="sm" tone="secondary" />
            {t('hotelCalendarReadOnly')}
          </p>
        ) : null}
        {(live ? true : state === 'calendar-nudge') && !selecting && !soft ? (
          <div className="cal-m__nudge">
            <Nudge offline={offline} preview={state === 'calendar-nudge'} />
          </div>
        ) : null}
        {selecting && dates.length === 0 ? (
          <div className="cal-m__hint">
            <RangeHint />
          </div>
        ) : null}
        <PeriodHead
          title={monthTitle(ym.year, ym.month)}
          prevLabel={c('commonCalendarPreviousMonth')}
          nextLabel={c('commonCalendarNextMonth')}
          onPrev={() => step(-1)}
          onNext={() => step(1)}
          onToday={gotoToday}
          away={away}
          info={<MonthKey soft={soft} />}
        />
        <MonthGrid
          halls={halls}
          claims={claims}
          ym={ym}
          onYm={setYm}
          mode={selecting ? 'select' : 'view'}
          selected={store.selected}
          onSelect={store.select}
          range={range}
          onRange={setRange}
          soft={soft}
        />
        {empty && !selecting && !soft ? (
          <div className="cal-m__empty">
            <EmptyState
              fill={false}
              illustration="partner-calendar"
              title={t('hotelCalendarEmptyTitle')}
              action={may ? { label: t('hotelCalendarActionBlock'), iconStart: 'lock', onPress: () => openBlock({}) } : undefined}
            />
          </div>
        ) : (
          <div className="cal-m__below">
            {selecting ? null : soft ? (
              <section className="cal-m__soft" aria-label={t('hotelCalendarSoftTitle')}>
                <div className="cal-m__softhead">
                  <span className="cal-m__softdisk" aria-hidden="true">
                    <Icon name="calendar-plus" size="md" tone="primary" />
                  </span>
                  <h3 className="cal-m__softtitle gz-t-ui-title">{t('hotelCalendarSoftTitle')}</h3>
                  <span className="cal-m__softn gz-t-fig-body-s">
                    <Fig>{f.integer(SOFT_DATES.length)}</Fig>
                  </span>
                  <IconButton icon="close" label={c('commonActionClose')} onClick={() => setSoft(false)} />
                </div>
                <ChipGroup<string>
                  label={t('hotelCalendarSoftTitle')}
                  layout="wrap"
                  value={SOFT_DATES.includes(store.selected) ? store.selected : null}
                  onChange={v => v && store.select(v)}
                  options={SOFT_DATES.map(d => ({ value: d, label: <Fx text={`${f.integer(Number(d.slice(8)))} ${f.monthName(Number(d.slice(5, 7)), 'short')}`} /> }))}
                />
              </section>
            ) : (
              <>
                <Agenda
                  date={store.selected}
                  halls={halls}
                  claims={claims}
                  role={role}
                  offline={offline}
                  onBlock={hallId => openBlock({ start: store.selected, end: store.selected, hallId })}
                  onOpenDates={() => openBlock({ start: store.selected, end: store.selected, mode: 'open' })}
                />
                {SOFT_DATES.length > 0 && !offline ? (
                  <IconListRow
                    flush
                    last
                    icon="calendar-plus"
                    title={t('hotelCalendarSoftTitle')}
                    trailing={
                      <span className="gz-t-fig-body-s">
                        <Fig>{f.integer(SOFT_DATES.length)}</Fig>
                        <span className="gz-sr-only">{t('hotelCalendarSoftRow', { count: SOFT_DATES.length, days: f.integer(SOFT_WINDOW_DAYS) })}</span>
                      </span>
                    }
                    onClick={() => setSoft(true)}
                  />
                ) : null}
              </>
            )}
          </div>
        )}
      </>
    )
  }

  return (
    <Screen top={top} bottom={bottom} bodyClassName="cal-m">
      <ViewSwitch view="month" />
      <HallChips value={hall} onChange={setHall} />
      <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
    </Screen>
  )
}
