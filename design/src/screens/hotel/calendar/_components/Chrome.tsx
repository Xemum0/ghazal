// The chrome the three calendar views share (HL-CALN-01 Month, -02 Week, -03 Day): the top bar with its two icon actions, the Month / Week /
// Day switch (three glyphs, the chosen one names itself), the hall chips (only when the venue has more than one hall, one word each) and the
// period header (the title, then arrows that mirror with the week, Today only when the view is somewhere else, and an optional (i)).
// Switching the view moves along the inventory edges: Month pushes Week or Day, Week and Day replace each other, and Month from either pops
// back to the tab root, so Back always lands somewhere sensible.
import type { ReactNode } from 'react'
import { useFormat } from '../../../../i18n'
import { Banner, Button, ChipGroup, IconButton, IconSegmented, TopBar, useNav, type TopBarAction } from '../../../../system'
import { HALLS } from './data'
import { useCal } from './store'
import { useWords, useShortHall } from './calBits'
import './chrome.css'

export type CalView = 'month' | 'week' | 'day'

export type CalTopProps = {
  offline?: boolean
  /** Hide the two actions (read-only roles, or offline: the banner names the state instead). */
  actions?: { select?: { pressed: boolean; onPress: () => void }; block?: () => void }
}

export function CalTop({ offline, actions }: CalTopProps) {
  const { t } = useWords()
  const f = useFormat()
  const list: TopBarAction[] = []
  if (actions?.select) list.push({ icon: 'calendar-plus', label: t('hotelCalendarActionSelect'), pressed: actions.select.pressed, onPress: actions.select.onPress })
  if (actions?.block) list.push({ icon: 'lock', label: t('hotelCalendarActionBlock'), onPress: actions.block })
  return (
    <>
      <TopBar title={t('hotelCalendarTitle')} actions={list} />
      {offline ? <Banner tone="offline">{t('hotelCalendarOfflineStamp', { time: f.time(f.now()) })}</Banner> : null}
    </>
  )
}

export function ViewSwitch({ view }: { view: CalView }) {
  const { t } = useWords()
  const nav = useNav()
  const selected = useCal(s => s.selected)
  const go = (to: CalView) => {
    if (to === view) return
    const target = to === 'week' ? 'HL-CALN-02' : 'HL-CALN-03'
    const params = to === 'day' ? { date: selected } : undefined
    if (to === 'month') nav.switchTab('calendar')
    else if (view === 'month') nav.push(target, params)
    else nav.replace(target, params)
  }
  return (
    <div className="cal-switch">
      <IconSegmented<CalView>
        label={t('hotelCalendarViewLabel')}
        value={view}
        labels="all"
        onChange={go}
        options={[
          { value: 'month', icon: 'calendar-dots', label: t('hotelCalendarViewMonth') },
          { value: 'week', icon: 'list', label: t('hotelCalendarViewWeek') },
          { value: 'day', icon: 'clock', label: t('hotelCalendarViewDay') },
        ]}
      />
    </div>
  )
}

/** The hall filter: a rail of chips, shown only because this venue has more than one hall. One word each: All, then the halls by short name. */
export function HallChips({ value, onChange }: { value: string; onChange: (hall: string) => void }) {
  const { t } = useWords()
  const short = useShortHall(HALLS)
  if (HALLS.length < 2) return null
  return (
    <div className="cal-halls">
      <ChipGroup<string>
        label={t('hotelCalendarHallsLabel')}
        layout="rail"
        value={value}
        onChange={v => onChange(v ?? 'all')}
        options={[{ value: 'all', label: t('hotelCalendarHallsAll') }, ...HALLS.map(h => ({ value: h.id, label: short(h.id) }))]}
      />
    </div>
  )
}

export type PeriodHeadProps = {
  title: ReactNode
  prevLabel: string
  nextLabel: string
  onPrev: () => void
  onNext: () => void
  onToday: () => void
  /** The view is not on today: Today (one word) appears. At today it would only repeat what the title says. */
  away?: boolean
  /** An (i) before the arrows (the legend of the month). */
  info?: ReactNode
}

/** The title at the start; Today, the (i) and the two arrows (the registry mirrors them in Arabic) at the end. */
export function PeriodHead({ title, prevLabel, nextLabel, onPrev, onNext, onToday, away, info }: PeriodHeadProps) {
  const { c } = useWords()
  return (
    <div className="cal-head">
      <h2 className="cal-head__title gz-t-ui-title" aria-live="polite">
        {title}
      </h2>
      {away ? (
        <Button variant="tertiary" onClick={onToday}>
          {c('commonCalendarToday')}
        </Button>
      ) : null}
      {info}
      <IconButton icon="chevron-left" label={prevLabel} onClick={onPrev} />
      <IconButton icon="chevron-right" label={nextLabel} onClick={onNext} />
    </div>
  )
}
