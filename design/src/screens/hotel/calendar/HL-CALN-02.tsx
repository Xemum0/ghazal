// HL-CALN-02 Week view: seven day rows for planning the week. For each day, what each hall is doing, so the manager sees gaps and clashes faster
// than in the month grid. Sunday first; Thu-Sat on the rose peak wash; Block and Create offer sit inline on open lanes.
// Requirements: HA-CAL-02, HA-CAL-06, HA-CAL-07, HA-CAL-09
// States: loading, empty, error, offline, hall-filter
// Tapping a date opens the Day view; a booked lane opens the booking; "Select dates" is the accessible way to build a range.
import { useEffect, useRef, useState } from 'react'
import { useFormat } from '../../../i18n'
import { ErrorState, IconListRow, PullToRefresh, Screen, useNav } from '../../../system'
import type { DateSpan } from '../../../system'
import { CalTop, HallChips, PeriodHead, ViewSwitch } from './_components/Chrome'
import { RangeBar } from './_components/RangeBar'
import { WeekSkeleton } from './_components/Skeletons'
import { WeekRows } from './_components/WeekRows'
import { TODAY, addDays, canBlock, datesOfSpan, hallsFor, sundayOf, useClaims } from './_components/data'
import { Figures, roleFrom, useSpanText, useWords } from './_components/calBits'
import { useCal } from './_components/store'
import './HL-CALN-02.css'

export const states = ['loading', 'empty', 'error', 'offline', 'hall-filter']

const NONE: DateSpan = { start: null, end: null }
const MAJLIS = 'V01-majlis'

export default function CalendarWeek({ state }: { state?: string }) {
  const f = useFormat()
  const nav = useNav()
  const { t } = useWords()
  const spanText = useSpanText()
  const role = roleFrom(nav.params.role)
  const may = canBlock(role)

  const framed = state !== undefined
  const store = useCal()
  const [frameHall, setFrameHall] = useState(state === 'hall-filter' ? MAJLIS : 'all')
  const hall = framed ? frameHall : store.hall
  const setHall = framed ? setFrameHall : store.setHall

  const [selecting, setSelecting] = useState(false)
  const [range, setRange] = useState<DateSpan>(NONE)

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const empty = state === 'empty'
  const all = useClaims()
  const claims = empty ? [] : all
  const halls = hallsFor(hall)
  // After a block or an open the week updates in place; leave range select behind.
  const seen = useRef(all)
  useEffect(() => {
    if (seen.current === all) return
    seen.current = all
    setSelecting(false)
    setRange(NONE)
  }, [all])
  const sunday = sundayOf(store.selected)
  const days = Array.from({ length: 7 }, (_, i) => addDays(sunday, i))
  const dates = datesOfSpan(range.start, range.end)

  const m0 = Number(sunday.slice(5, 7))
  const m1 = Number((days[6] as string).slice(5, 7))
  const d0 = f.integer(Number(sunday.slice(8)))
  const d1 = f.integer(Number((days[6] as string).slice(8)))
  const title = m0 === m1 ? `${d0} – ${d1} ${f.monthName(m0)}` : `${d0} ${f.monthName(m0, 'short')} – ${d1} ${f.monthName(m1, 'short')}`

  const tap = (iso: string) => {
    const r = range
    if (!r.start || r.end) setRange({ start: iso, end: null })
    else setRange(iso < r.start ? { start: iso, end: r.start } : { start: r.start, end: iso })
  }
  const toggleSelect = () => {
    setSelecting(s => !s)
    setRange(NONE)
  }
  const openBlock = (opts: { start?: string | null; end?: string | null; hallId?: string | null; mode?: 'block' | 'open' }) =>
    nav.openSheet('HL-CALN-04', { params: { mode: opts.mode ?? 'block', start: opts.start ?? null, end: opts.end ?? null, hallIds: opts.hallId ? [opts.hallId] : undefined, role } })
  const openDay = (iso: string) => {
    store.select(iso)
    nav.push('HL-CALN-03', { date: iso })
  }

  const top = (
    <CalTop
      offline={offline}
      actions={may && !offline && !loading && !error ? { select: { pressed: selecting, onPress: toggleSelect }, block: () => openBlock({ start: selecting ? range.start : null, end: selecting ? range.end : null }) } : undefined}
    />
  )
  const bottom = selecting ? (
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

  let body
  if (loading) body = <WeekSkeleton />
  else if (error) body = <ErrorState kind="load" onRetry={() => nav.replace('HL-CALN-02')} />
  else {
    body = (
      <>
        <PeriodHead
          title={<Figures text={title} />}
          prevLabel={t('hotelCalendarPrevWeek')}
          nextLabel={t('hotelCalendarNextWeek')}
          onPrev={() => store.select(addDays(store.selected, -7))}
          onNext={() => store.select(addDays(store.selected, 7))}
          onToday={() => store.select(TODAY)}
        />
        {empty ? <IconListRow illustration="partner-calendar" title={t('hotelCalendarEmptyTitle')} /> : null}
        <WeekRows
          sunday={sunday}
          halls={halls}
          claims={claims}
          role={role}
          offline={offline}
          selecting={selecting}
          range={range}
          onTapDate={tap}
          onOpenDay={openDay}
          onBlock={(iso, hallId) => openBlock({ start: iso, end: iso, hallId })}
          onOpenDates={iso => openBlock({ start: iso, end: iso, mode: 'open' })}
          onOffer={iso => nav.push('HL-GROW-02', { date: iso })}
          onBooking={bookingId => nav.push('HL-BOOK-03', { bookingId })}
        />
      </>
    )
  }

  return (
    <Screen top={top} bottom={bottom} bodyClassName="cal-w">
      <ViewSwitch view="week" />
      <HallChips value={hall} onChange={setHall} />
      <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>
        {body}
      </PullToRefresh>
    </Screen>
  )
}
