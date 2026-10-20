// HL-CALN-03 Day view: one date in operational detail. For every hall, the setup, event and teardown on a business-day bar, the booking card with its
// money state and Call / Chat, and what can be done with the date (Block, Create offer, Open this date). This is where "tap a date opens its day
// agenda and the related booking" lands.
// Requirements: HA-CAL-03, HA-CAL-06, HA-CAL-07, HA-CAL-09, HA-DASH-01
// States: loading, empty, error, offline, held, blocked, open-day, requested-info
import { useState } from 'react'
import { useFormat } from '../../../i18n'
import { ErrorState, PullToRefresh, Screen, useNav } from '../../../system'
import { CalTop, HallChips, PeriodHead, ViewSwitch } from './_components/Chrome'
import { HallDay } from './_components/HallDay'
import { DaySkeleton } from './_components/Skeletons'
import { HALLS, TODAY, addDays, canBlock, claimOf, hallsFor, useClaims } from './_components/data'
import { roleFrom, useWords } from './_components/calBits'
import { useCal } from './_components/store'
import './HL-CALN-03.css'

export const states = ['loading', 'empty', 'error', 'offline', 'held', 'blocked', 'open-day', 'requested-info']

/** The date each state frame draws (fixtures: docs/product/screens/hotel/05-calendar.json contentNotes). */
const FRAME_DATE: Record<string, string> = {
  held: '2026-12-10',
  blocked: '2026-11-23',
  'open-day': '2026-11-20',
  'requested-info': '2027-01-14',
  empty: '2026-11-17',
}
const MAJLIS = 'V01-majlis'

export default function CalendarDay({ state }: { state?: string }) {
  const f = useFormat()
  const nav = useNav()
  const { t } = useWords()
  const role = roleFrom(nav.params.role)
  const may = canBlock(role)
  const store = useCal()

  const framed = state !== undefined
  const asked = typeof nav.params.date === 'string' ? nav.params.date : null
  const [frameDate, setFrameDate] = useState<string>(FRAME_DATE[state ?? ''] ?? store.selected)
  const [frameHall, setFrameHall] = useState('all')
  const [liveDate, setLiveDate] = useState<string>(asked ?? store.selected)
  const date = framed ? frameDate : liveDate
  const hall = framed ? frameHall : store.hall
  const setHall = framed ? setFrameHall : store.setHall
  const go = (iso: string) => {
    if (framed) setFrameDate(iso)
    else setLiveDate(iso)
    store.select(iso)
  }

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const claims = useClaims()
  const halls = hallsFor(hall)

  const openBlock = (opts: { hallId?: string | null; mode?: 'block' | 'open' }) =>
    nav.openSheet('HL-CALN-04', { params: { mode: opts.mode ?? 'block', start: date, end: date, hallIds: opts.hallId ? [opts.hallId] : undefined, role } })

  const top = <CalTop offline={offline} actions={may && !offline && !loading && !error ? { block: () => openBlock({}) } : undefined} />

  let body
  if (loading) body = <DaySkeleton />
  else if (error) body = <ErrorState kind="load" onRetry={() => nav.replace('HL-CALN-03', { date })} />
  else {
    body = (
      <>
        <PeriodHead
          title={f.date(date, 'short')}
          prevLabel={t('hotelCalendarPrevDay')}
          nextLabel={t('hotelCalendarNextDay')}
          onPrev={() => go(addDays(date, -1))}
          onNext={() => go(addDays(date, 1))}
          onToday={() => go(TODAY)}
        />
        <div className="cal-d__halls">
          {halls.map(h => (
            <HallDay
              key={h.id}
              date={date}
              hall={h}
              allHalls={HALLS}
              claims={claims}
              claim={claimOf(claims, date, h.id)}
              role={role}
              offline={offline}
              onBlock={hallId => openBlock({ hallId })}
              onOpenDates={() => openBlock({ mode: 'open' })}
            />
          ))}
        </div>
      </>
    )
  }

  return (
    <Screen top={top} bodyClassName="cal-d">
      <ViewSwitch view="day" />
      <HallChips value={hall} onChange={setHall} />
      <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
    </Screen>
  )
}
