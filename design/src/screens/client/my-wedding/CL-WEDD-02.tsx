// CL-WEDD-02 Checklist (pushed from My Wedding; tab bar visible). Requirements: CA-TOOL-12, CA-TOOL-13, CA-TOOL-14, CA-TOOL-15,
// CA-TOOL-16.
//
// The PRD defaults with due dates counted back from the wedding date, the couple's own tasks, a completion percentage and a way into
// Services for each task. Rules, no AI. Ticking draws the check (160 ms class), the row stays a moment and then moves to Completed with
// an Undo bar; no confetti; finishing everything earns one quiet line. Offline the list is read only with a stamp.
//
// Text diet (ADR 0034): a task is a check, one word and a calendar fact; the deep link is the search glyph; the progress is a percent, its
// fraction and a gold line; a band is a glyph and two words at most. The empty state is a drawing, three words and one verb; finishing the
// list earns one quiet drawing and two words.
import { useEffect, useMemo, useRef, useState } from 'react'
import { useFormat, useT } from '../../../i18n'
import { Banner, EmptyState, ErrorState, FactChip, Icon, Illustration, Screen, Skeleton, TopBar, useNav } from '../../../system'
import type { IconName } from '@gz/tokens'
import { clock } from '../../../mock'
import { ChecklistRow } from './_components/ChecklistRow'
import { DateText } from './_components/DateText'
import { ProgressHead } from './_components/ProgressHead'
import { TaskSheet } from './_components/TaskSheet'
import { groupChecklist, type Band, type TaskRow } from './_components/model'
import { useTools } from './_components/tools'
import { useChecklistModel, useStateParam, useWedding } from './_components/useWedding'
import './CL-WEDD-02.css'

export const states = ['loading', 'empty-no-date', 'all-complete', 'offline-read-only', 'error']

/** The glyph of each countdown band, at the start of its heading. */
const BAND_ICON: Record<Band, IconName> = {
  booking: 'hall',
  more: 'calendar-dots',
  months: 'calendar-dots',
  month: 'calendar',
  week: 'timer',
  noDate: 'calendar-x',
  done: 'check-circle',
}

const BAND_KEY = {
  booking: 'clientMyWeddingChecklistBandBooking',
  month: 'clientMyWeddingChecklistBandMonth',
  week: 'clientMyWeddingChecklistBandWeek',
  noDate: 'clientMyWeddingChecklistBandNoDate',
  done: 'clientMyWeddingChecklistBandDone',
} as const

/** Moves to Completed this long after the tick (about 600 ms, the inventory). */
const SETTLE_MS = 600

export default function Checklist() {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const state = useStateParam()
  const w = useWedding()
  const model = useChecklistModel(w)
  const [fresh, setFresh] = useState<ReadonlySet<string>>(new Set())
  const timers = useRef<number[]>([])
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])

  const offline = state === 'offline-read-only'
  const allComplete = state === 'all-complete'
  const noDate = w.phase === 'no-date' || w.eventDate === null

  // The "all complete" frame: every row done, as the couple would see it at the end.
  const rows: TaskRow[] = useMemo(
    () => (allComplete ? model.rows.map(r => ({ ...r, done: true, doneAt: r.doneAt ?? clock.now() })) : model.rows),
    [allComplete, model.rows],
  )
  const done = rows.filter(r => r.done).length
  const total = rows.length

  const addTask = () => {
    nav.openSheet(<TaskSheet weddingDate={w.eventDate} today={w.today} />)
  }
  const editTask = (row: TaskRow) => {
    nav.openSheet(<TaskSheet editing={row} weddingDate={w.eventDate} today={w.today} />)
  }
  const toggle = (row: TaskRow, next: boolean) => {
    useTools.getState().toggleTask(row.id, next, clock.now())
    if (!next) return
    setFresh(s => new Set(s).add(row.id))
    timers.current.push(
      window.setTimeout(() => {
        setFresh(s => {
          const n = new Set(s)
          n.delete(row.id)
          return n
        })
      }, SETTLE_MS),
    )
    nav.toast({
      message: t('clientMyWeddingChecklistToastDone'),
      undo: true,
      action: { label: c('commonActionUndo'), onPress: () => useTools.getState().toggleTask(row.id, false, clock.now()) },
    })
  }

  const top = (
    <TopBar
      title={t('clientMyWeddingChecklistTitle')}
      actions={noDate || offline || state === 'loading' || state === 'error' ? [] : [{ icon: 'plus', label: t('clientMyWeddingChecklistAdd'), onPress: addTask }]}
    />
  )

  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="gzmw-cl" aria-busy="true">
          <div className="gzmw-cl__pad gzmw-cl__skel">
            <Skeleton blockSize={20} />
            <Skeleton blockSize={4} />
          </div>
          {Array.from({ length: 6 }, (_, i) => (
            <div key={i} className="gzmw-cl__pad gzmw-cl__skelrow">
              <Skeleton variant="circle" inlineSize={24} />
              <div className="gzmw-cl__skeltext">
                <Skeleton inlineSize={160} blockSize={24} />
                <Skeleton inlineSize={96} blockSize={20} />
              </div>
            </div>
          ))}
        </div>
      </Screen>
    )
  }
  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => nav.replace('CL-WEDD-02')} />
      </Screen>
    )
  }
  if (noDate) {
    return (
      <Screen top={top}>
        <EmptyState
          illustration="calendar"
          title={t('clientMyWeddingChecklistEmptyTitle')}
          action={{ label: t('clientMyWeddingChecklistEmptyAction'), variant: 'primary', onPress: () => nav.openSheet('CL-DISC-02') }}
        />
      </Screen>
    )
  }

  // A ticked row stays in its band until it has settled, then it joins Completed.
  const grouped = groupChecklist(
    rows.map(r => (fresh.has(r.id) ? { ...r, done: false } : r)),
    w.eventDate ?? clock.today(),
  )
  const byId = new Map(rows.map(r => [r.id, r]))
  const venueStatus = w.status === 'pending' || w.status === 'approved' ? w.status : null

  const bandTitle = (band: Band): string => {
    if (band === 'more') return t('clientMyWeddingChecklistBandMore', { count: f.integer(6) })
    if (band === 'months') return t('clientMyWeddingChecklistBandMonths', { from: f.integer(1), to: f.integer(6) })
    return t(BAND_KEY[band])
  }

  return (
    <Screen top={top}>
      {offline ? (
        <Banner tone="offline">
          {c('commonStateOffline')} <FactChip icon="clock" value={<DateText text={f.time(clock.now())} />} label={t('clientMyWeddingUpdated')} size="sm" />
        </Banner>
      ) : null}

      <div className="gzmw-cl" data-gz-id="checklist">
        <div className="gzmw-cl__pad gzmw-cl__head">
          <ProgressHead done={done} total={total} />
          {done === total && total > 0 ? (
            <div className="gzmw-cl__alldone" role="status" data-gz-id="all-done">
              <Illustration name="seal" size="lg" />
              <p className="gz-t-d2">{t('clientMyWeddingChecklistAllDone')}</p>
            </div>
          ) : null}
        </div>

        {grouped.map(g => (
          <section key={g.band} className="gzmw-cl__group" aria-label={bandTitle(g.band)} data-band={g.band}>
            <h2 className="gzmw-cl__band gz-t-body-s">
              <Icon name={BAND_ICON[g.band]} size="xs" tone="secondary" />
              {bandTitle(g.band)}
            </h2>
            <div className="gzmw-cl__rows">
              {g.rows.map((gr, i) => {
                const row = byId.get(gr.id) ?? gr
                return (
                  <ChecklistRow
                    key={row.id}
                    row={row}
                    today={w.today}
                    readOnly={offline}
                    fresh={fresh.has(row.id)}
                    venueStatus={row.auto ? venueStatus : null}
                    last={i === g.rows.length - 1}
                    onToggle={next => toggle(row, next)}
                    onBrowse={() => nav.push('CL-SERV-02', { categoryId: row.serviceCategoryId })}
                    onOpenBooking={w.booking ? () => nav.push('CL-BKNG-02', { bookingId: w.booking?.id }) : undefined}
                    onEdit={() => editTask(row)}
                  />
                )
              })}
            </div>
          </section>
        ))}
      </div>
    </Screen>
  )
}
