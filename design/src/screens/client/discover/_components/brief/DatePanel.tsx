// DatePanel (CL-DISC-02): the date picker inside the Brief sheet. Three views of one question: the system calendar (Sunday-first, Thursday to
// Saturday peak band, past days closed) with a ruled strip once a day is picked (the date, the Hijri line in the Arabic UI only, the day
// count as a fact); "Not decided"; and "Any month" (twelve month chips). The two alternatives are chips above the calendar; choosing one
// replaces the date, picking a day replaces them. A skipped answer is not a choice: until someone taps "Not decided" the calendar stays in
// front. Text diet (ADR 0034): no hints and no explanations; the chosen chip and the calendar say what is set.
import { useState } from 'react'
import { Calendar, Chip, Figures, Icon } from '../../../../../system'
import { TextFact } from '../TextFact'
import { useFormat, useT } from '../../../../../i18n'
import { meta } from '../../../../../mock'
import type { PanelProps } from './types'

type Ym = { year: number; month: number }
export type DateView = 'calendar' | 'undecided' | 'months'
const monthOf = (iso: string): Ym => ({ year: Number(iso.slice(0, 4)), month: Number(iso.slice(5, 7)) })
const MONTHS_AHEAD = 12

export function DatePanel({ draft, set, initialView }: PanelProps & { initialView?: DateView }) {
  const t = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const b = draft.brief
  const today = f.isoDay(f.now())
  const [month, setMonth] = useState<Ym>(b.date ? monthOf(b.date) : monthOf(today))
  const [view, setView] = useState<DateView>(initialView ?? (b.dateMode === 'flexible_month' ? 'months' : 'calendar'))

  const start = monthOf(today)
  const months: Ym[] = Array.from({ length: MONTHS_AHEAD }, (_, i) => {
    const n = start.month - 1 + i
    return { year: start.year + Math.floor(n / 12), month: (n % 12) + 1 }
  })
  const monthText = (m: Ym) => f.date(f.kuwaitDate(m.year, m.month, 1), 'monthYear')
  const chosenMonth = b.dateMode === 'flexible_month' && b.date ? monthOf(b.date) : null
  const sameMonth = (a: Ym | null, m: Ym) => a !== null && a.year === m.year && a.month === m.month

  const pickDay = (iso: string | null) => set(x => ({ ...x, later: false, brief: { ...x.brief, ...(iso ? { date: iso, dateMode: 'exact' as const } : { date: null, dateMode: 'undecided' as const }) } }))
  const undecided = () => {
    if (view === 'undecided') {
      set(x => ({ ...x, later: false }))
      return setView('calendar')
    }
    setView('undecided')
    set(x => ({ ...x, later: true, brief: { ...x.brief, date: null, dateMode: 'undecided' } }))
  }
  const flexible = () => setView(v => (v === 'months' ? 'calendar' : 'months'))
  const pickMonth = (m: Ym) => set(x => ({ ...x, later: false, brief: { ...x.brief, date: f.isoDay(f.kuwaitDate(m.year, m.month, 1)), dateMode: 'flexible_month' as const } }))

  const info = b.dateMode === 'exact' && b.date ? f.dateWithHijri(b.date) : null

  return (
    <div className="gzd-br__panel" data-gz-id="brief.date">
      <div className="gzd-br__alts" role="group">
        <Chip selected={view === 'undecided'} onClick={undecided}>
          {c('commonLabelNotDecided')}
        </Chip>
        <Chip menu iconStart="calendar-dots" selected={view === 'months' || chosenMonth !== null} onClick={flexible}>
          {chosenMonth ? <Figures text={monthText(chosenMonth)} /> : t('clientDiscoverBriefDateFlexible')}
        </Chip>
      </div>
      {view === 'calendar' || view === 'undecided' ? (
        <>
          <Calendar mode="single" value={view === 'undecided' ? null : b.dateMode === 'exact' ? b.date : null} onChange={pickDay} month={month} onMonthChange={setMonth} maxDate={meta.availabilityWindow.to} summary={false} legend={false} label={t('clientDiscoverBriefDateTitle')} />
          {view !== 'undecided' && info && b.date ? (
            <section className="gzd-br__strip" aria-live="polite">
              <Icon name="calendar-check" size="md" tone="accent" />
              <div className="gzd-br__stripText">
                <p className="gz-t-title gzd-br__stripDate">
                  <Figures text={info.primary} />
                </p>
                {info.secondary ? (
                  <p className="gz-t-caption gzd-br__hint">
                    <Figures text={info.secondary} />
                  </p>
                ) : null}
              </div>
              <TextFact icon="countdown" label={t('clientDiscoverA11yDaysLeft')} value={c('commonCountDays', { count: f.daysUntil(b.date) })} />
            </section>
          ) : null}
        </>
      ) : null}

      {view === 'months' ? (
        <section className="gzd-br__months" aria-label={t('clientDiscoverBriefDateFlexible')}>
          <div className="gzd-br__monthgrid" role="group">
            {months.map(m => (
              <Chip key={`${m.year}-${m.month}`} selected={sameMonth(chosenMonth, m)} onClick={() => pickMonth(m)} className="gzd-br__monthchip">
                <Figures text={monthText(m)} />
              </Chip>
            ))}
          </div>
        </section>
      ) : null}

    </div>
  )
}
