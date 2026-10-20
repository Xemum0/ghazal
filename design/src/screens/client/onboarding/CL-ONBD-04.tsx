// CL-ONBD-04 Wedding date. Covers CA-ONB-03, CA-ONB-08, CA-ONB-09.
// Text diet (ADR 0034): the full-screen form of the shared single-date calendar (the system Calendar: Sunday-first, Thu to Sat peak band,
// closed past days) under a two-word title, nothing else said in words. A picked day shows as a fact strip: the date, the Hijri line in
// the Arabic UI only, and the time left as a glyph and a figure (`63 d`). The occasions around the visible month (approximate until
// announced) are quiet facts under the grid. Two honest alternatives, each one word: Undecided and Flexible (a 12-month sheet); when one is
// chosen it replaces the grid with a drawing, its name and the way back (the Illustration on this step's state).
// States: default, selected (Thu 14 Jan 2027, the demo date), not-decided, flexible-month (the month sheet open).
import { useState } from 'react'
import { ActionBar, Button, Calendar, Chip, EmptyState, FactChip, Figures, Icon, PickerSheet, Screen, useDuration, useNav } from '../../../system'
import { useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { meta, weddingProfile as storyProfile } from '../../../mock'
import { StepBar } from './_components/StepBar'
import { StepHead } from './_components/StepHead'
import { commitDate } from './_components/profile'
import { useScreenState } from './_components/useScreenState'
import './_components/form.css'
import './CL-ONBD-04.css'

export const states = ['selected', 'not-decided', 'flexible-month']

type Ym = { year: number; month: number }
type Mode = 'exact' | 'undecided' | 'flexible_month'

const monthOf = (iso: string): Ym => ({ year: Number(iso.slice(0, 4)), month: Number(iso.slice(5, 7)) })
const MONTHS_AHEAD = 12
const DAY_MS = 86_400_000

export default function ClOnbd04() {
  const t = useT('client-onboarding')
  const c = useT('common')
  const f = useFormat()
  const duration = useDuration()
  const nav = useNav()
  const state = useScreenState()
  const saved = usePrototype(s => s.weddingProfile)

  const today = f.isoDay(f.now())
  const demo = storyProfile.weddingDate

  const initialDate = state === 'selected' || state === 'flexible-month' ? demo : saved?.dateMode === 'exact' ? saved.weddingDate : null
  const initialMode: Mode = state === 'not-decided' ? 'undecided' : state === 'flexible-month' ? 'flexible_month' : (saved?.dateMode ?? 'exact')
  const [mode, setMode] = useState<Mode>(initialMode)
  const [date, setDate] = useState<string | null>(initialMode === 'exact' ? initialDate : null)
  const [flex, setFlex] = useState<Ym | null>(initialMode === 'flexible_month' ? monthOf(demo) : saved?.dateMode === 'flexible_month' && saved.weddingDate ? monthOf(saved.weddingDate) : null)
  const [month, setMonth] = useState<Ym>(date ? monthOf(date) : flex ?? monthOf(today))
  const [sheet, setSheet] = useState(state === 'flexible-month')
  const [draftMonth, setDraftMonth] = useState<Ym | null>(flex)

  // The 12 months from this one: the flexible-month choices.
  const start = monthOf(today)
  const months: Ym[] = Array.from({ length: MONTHS_AHEAD }, (_, i) => {
    const n = start.month - 1 + i
    return { year: start.year + Math.floor(n / 12), month: (n % 12) + 1 }
  })
  const monthText = (m: Ym) => f.date(f.kuwaitDate(m.year, m.month, 1), 'monthYear')
  const sameMonth = (a: Ym | null, b: Ym) => a !== null && a.year === b.year && a.month === b.month

  const pickDay = (iso: string | null) => {
    setDate(iso)
    setMode('exact')
    setFlex(null)
  }
  const decideLater = () => {
    setMode(m => (m === 'undecided' ? 'exact' : 'undecided'))
    setDate(null)
    setFlex(null)
  }
  const confirmMonth = () => {
    if (draftMonth) {
      setFlex(draftMonth)
      setMode('flexible_month')
      setDate(null)
    }
    setSheet(false)
  }

  const next = () => nav.push('CL-ONBD-05')
  const confirm = () => {
    if (mode === 'exact') commitDate({ date, mode: date ? 'exact' : 'undecided' })
    else if (mode === 'flexible_month' && flex) commitDate({ date: f.isoDay(f.kuwaitDate(flex.year, flex.month, 1)), mode: 'flexible_month' })
    else commitDate({ date: null, mode: 'undecided' })
    next()
  }

  const dayInfo = date ? f.dateWithHijri(date) : null
  const days = date ? f.daysUntil(date) : 0
  // The time left is a figure and the formatter's own day unit (d, ي): the unit is read from the formatter, never typed, and sits after the
  // figure in reading order in both languages (the compact duration string would run as one LTR island and put the Arabic unit first).
  const dayUnit = duration(DAY_MS).replace(/[\d\u0660-\u0669\u2066\u2069\s\u00a0]/g, '')
  const occasions = meta.occasions.filter(o => {
    const a = monthOf(o.from)
    const b = monthOf(o.to)
    const v = month.year * 12 + month.month
    return a.year * 12 + a.month <= v && v <= b.year * 12 + b.month
  })

  return (
    <Screen top={<StepBar step={2} total={4} onSkip={next} />} bottom={<ActionBar action={{ label: c('commonActionContinue'), onPress: confirm }} />}>
      <div className="obd-form">
        <StepHead title={t('clientOnboardingDateTitle')} />

        {mode === 'exact' ? (
          <>
            <Calendar mode="single" value={date} onChange={pickDay} month={month} onMonthChange={setMonth} maxDate={meta.availabilityWindow.to} summary={false} label={t('clientOnboardingDateTitle')} />
            {/* The strip keeps its height whether or not a day is chosen, so picking never moves the controls under it. */}
            <section className="obd-date__strip" aria-live="polite">
              {dayInfo && date ? (
                <>
                  <span className="obd-date__icon" aria-hidden="true">
                    <Icon name="calendar-check" size="md" />
                  </span>
                  <div className="obd-date__text">
                    <p className="obd-date__date gz-t-title">
                      <Figures text={f.date(date, 'short')} />
                    </p>
                    {dayInfo.secondary ? (
                      <p className="obd-date__hijri gz-t-caption">
                        <Figures text={dayInfo.secondary} />
                      </p>
                    ) : null}
                  </div>
                  <FactChip icon="countdown" label={c('commonCountdownDays', { count: days })} value={days > 0 ? f.integer(days) : c('commonCountdownDays', { count: 0 })} unit={days > 0 ? dayUnit : undefined} />
                </>
              ) : (
                <>
                  <span className="obd-date__icon obd-date__icon--muted" aria-hidden="true">
                    <Icon name="calendar-plus" size="md" />
                  </span>
                  <p className="obd-date__none gz-t-body-s">{t('clientOnboardingDatePickDate')}</p>
                </>
              )}
            </section>
            {occasions.length > 0 ? (
              <div className="obd-date__occasions" role="group" aria-label={t('clientOnboardingDateOccasions')}>
                {occasions.map(o => (
                  <FactChip
                    key={o.id}
                    icon="sparkle"
                    size="sm"
                    tone="muted"
                    label={o.name[f.lang]}
                    value={
                      o.from === o.to
                        ? t('clientOnboardingDateOccasionOne', { name: o.name[f.lang], date: f.date(o.from, 'short') })
                        : t('clientOnboardingDateOccasionRange', { name: o.name[f.lang], from: f.date(o.from, 'dayMonth'), to: f.date(o.to, 'dayMonth') })
                    }
                  />
                ))}
              </div>
            ) : null}
          </>
        ) : (
          <EmptyState
            fill={false}
            align="center"
            illustration={mode === 'undecided' ? 'hourglass' : 'calendar'}
            title={mode === 'flexible_month' && flex ? <Figures text={monthText(flex)} /> : t('clientOnboardingDateNotDecided')}
            action={{ label: t('clientOnboardingDatePickDate'), variant: 'tertiary', onPress: () => setMode('exact') }}
          />
        )}

        <div className="obd-date__alts" role="group">
          <Chip iconStart="calendar-dots" selected={mode === 'undecided'} onClick={decideLater}>
            {t('clientOnboardingDateNotDecided')}
          </Chip>
          <Chip
            iconStart="calendar"
            menu
            selected={mode === 'flexible_month'}
            onClick={() => {
              setDraftMonth(flex ?? months[0] ?? null)
              setSheet(true)
            }}
          >
            {mode === 'flexible_month' && flex ? <Figures text={monthText(flex)} /> : t('clientOnboardingDateFlexible')}
          </Chip>
        </div>
      </div>

      <PickerSheet
        open={sheet}
        onClose={() => setSheet(false)}
        title={t('clientOnboardingDateFlexibleTitle')}
        footer={
          <Button fullWidth onClick={confirmMonth}>
            {c('commonActionDone')}
          </Button>
        }
      >
        <div className="obd-months" role="group" aria-label={t('clientOnboardingDateMonthsLabel')} tabIndex={-1} data-autofocus>
          {[0, 2, 4, 6, 8, 10].map(i => (
            <div className="obd-months__row" key={i}>
              {months.slice(i, i + 2).map(m => (
                <Chip key={`${m.year}-${m.month}`} className="obd-months__chip" selected={sameMonth(draftMonth, m)} onClick={() => setDraftMonth(m)}>
                  <Figures text={monthText(m)} />
                </Chip>
              ))}
            </div>
          ))}
        </div>
      </PickerSheet>
    </Screen>
  )
}
