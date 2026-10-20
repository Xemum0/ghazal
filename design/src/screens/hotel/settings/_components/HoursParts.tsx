// The pieces of Business hours (text diet, ADR 0034): the day row (a short day name, the opening and closing time as two buttons with an arrow
// between them, the open switch), the read-only row, the custom time sheet (12-hour clock, Western digits, never the native picker), the
// add-closure sheet and the "Shown to couples as" lines. A time is its figure plus a glyph for the part of the day (sun, sunset, moon) instead of
// the AM or PM word; the full reading ("9:00 AM") is the accessible name. Times are Kuwait time and are never converted to the device's time
// zone; every time string comes from the shared formatter.
import { useState } from 'react'
import type { GzFormat } from '@gz/i18n'
import { Button, Calendar, Icon, SegmentedControl, Switch, TextField, type DateRange } from '../../../../system'
import { useFormat } from '../../../../i18n'
import { Figures, SheetFrame, useWords } from './bits'
import { HOURS_12, MINUTES, dayPartOf, joinClock, runsOf, splitClock, type Closure, type DayHours, type HoursRun, type Week, type Weekday } from './model'

const NBSP = ' '

/** `HH:MM` as an instant on a fixed Kuwait day; only its clock reading is ever shown. */
export const clockAt = (f: GzFormat, hhmm: string): Date => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  return f.kuwaitDate(2026, 11, 15, h, m)
}

/** The figure of a clock reading without its AM or PM marker (the marker is a glyph on screen and part of the accessible name). */
export const figureOf = (f: GzFormat, hhmm: string): string => f.time(clockAt(f, hhmm)).split(NBSP)[0] ?? ''

/** A clock reading as figure + part-of-day glyph. */
export function TimeFigure({ hhmm, next = false }: { hhmm: string; next?: boolean }) {
  const f = useFormat()
  const { t } = useWords()
  return (
    <span className="hs-time">
      <span className="hs-time__fig gz-t-fig-body-s">
        <Figures text={figureOf(f, hhmm)} />
      </span>
      <Icon name={dayPartOf(hhmm)} size="xs" tone="secondary" />
      {next ? (
        <span className="hs-time__next gz-t-fig-caption">
          +1
          <span className="gz-sr-only">{t('hotelSettingsHoursNextDay')}</span>
        </span>
      ) : null}
    </span>
  )
}

// ---------------------------------------------------------------- the day row

export type HoursDayProps = {
  weekday: Weekday
  day: DayHours
  /** Same opening and closing time: the one mistake. */
  invalid?: boolean
  /** Without handlers the row only reads (a role that can only view). */
  onOpenChange?: (open: boolean) => void
  onPickFrom?: () => void
  onPickTo?: () => void
  /** "All days" under the row being edited. */
  onCopy?: () => void
  last?: boolean
}

export function HoursDay({ weekday, day, invalid = false, onOpenChange, onPickFrom, onPickTo, onCopy, last = false }: HoursDayProps) {
  const f = useFormat()
  const { t } = useWords()
  const edit = Boolean(onOpenChange)
  const name = f.weekdayName(weekday, 'header')
  const full = f.weekdayName(weekday, 'long')
  const reading = (hhmm: string) => f.plain(f.time(clockAt(f, hhmm)))
  const nextDay = day.open && day.to < day.from
  const from = <TimeFigure hhmm={day.from} />
  const to = <TimeFigure hhmm={day.to} next={nextDay} />
  return (
    <div className={`hs-day${last ? ' is-last' : ''}${day.open ? '' : ' is-off'}`} data-gz="HoursDay" data-open={day.open || undefined}>
      <div className="hs-day__row">
        <span className="hs-day__name gz-t-title">{name}</span>
        <span className="hs-day__times">
          {day.open ? (
            <>
              {edit ? (
                <button type="button" className="gz-reset gz-press hs-day__time" onClick={onPickFrom} aria-label={`${t('hotelSettingsHoursTimeFrom')} ${reading(day.from)}`}>
                  {from}
                </button>
              ) : (
                <span className="hs-day__time is-read">
                  {from}
                  <span className="gz-sr-only">{reading(day.from)}</span>
                </span>
              )}
              <Icon name="arrow-right" size="xs" tone="secondary" />
              {edit ? (
                <button
                  type="button"
                  className={`gz-reset gz-press hs-day__time${invalid ? ' is-invalid' : ''}`}
                  onClick={onPickTo}
                  aria-label={`${t('hotelSettingsHoursTimeTo')} ${reading(day.to)}`}
                  aria-invalid={invalid || undefined}
                >
                  {to}
                </button>
              ) : (
                <span className="hs-day__time is-read">
                  {to}
                  <span className="gz-sr-only">{reading(day.to)}</span>
                </span>
              )}
            </>
          ) : (
            <span className="hs-day__closed">
              <Icon name="lock" size="xs" tone="disabled" />
              <span className="gz-sr-only">{t('hotelSettingsHoursClosedWord')}</span>
            </span>
          )}
        </span>
        {edit ? (
          <span className="hs-day__switch">
            <Switch checked={day.open} onChange={onOpenChange} label={t('hotelSettingsHoursOpenOn', { day: full })} />
          </span>
        ) : null}
      </div>
      {edit && day.open && invalid ? (
        <p className="hs-day__error gz-t-caption" role="alert">
          <Icon name="warning-circle" size="xs" tone="danger" />
          {t('hotelSettingsHoursInvalid')}
        </p>
      ) : null}
      {edit && day.open && onCopy ? (
        <div className="hs-day__copy">
          <Button variant="tertiary" iconStart="copy" onClick={onCopy}>
            {t('hotelSettingsHoursCopy')}
          </Button>
        </div>
      ) : null}
    </div>
  )
}

// ---------------------------------------------------------------- time sheet

export function TimeContent({ title, initial, onSet, onClose }: { title: string; initial: string; onSet: (hhmm: string) => void; onClose?: () => void }) {
  const { t } = useWords()
  const f = useFormat()
  const start = splitClock(initial)
  const [hour, setHour] = useState(start.hour)
  const [minute, setMinute] = useState(start.minute)
  const [pm, setPm] = useState(start.pm)
  const value = joinClock(hour, minute, pm)
  const minutes = MINUTES.includes(minute) ? MINUTES : [...MINUTES, minute].sort((a, b) => a - b)
  return (
    <SheetFrame
      title={title}
      onClose={onClose}
      footer={
        <Button fullWidth onClick={() => onSet(value)}>
          {t('hotelSettingsHoursSetTime')}
        </Button>
      }
    >
      <p className="hs-time__now gz-t-ui-xl">
        <Figures text={f.time(clockAt(f, value))} />
      </p>
      <div className="hs-picks" role="radiogroup" aria-label={t('hotelSettingsHoursHour')}>
        {HOURS_12.map(h => (
          <button key={h} type="button" role="radio" aria-checked={h === hour} className={`gz-reset gz-press hs-pick${h === hour ? ' is-on' : ''}`} onClick={() => setHour(h)}>
            <Figures text={f.integer(h)} />
          </button>
        ))}
      </div>
      <div className="hs-picks" role="radiogroup" aria-label={t('hotelSettingsHoursMinute')}>
        {minutes.map(m => (
          <button key={m} type="button" role="radio" aria-checked={m === minute} className={`gz-reset gz-press hs-pick hs-pick--wide${m === minute ? ' is-on' : ''}`} onClick={() => setMinute(m)}>
            <Figures text={`:${String(m).padStart(2, '0')}`} />
          </button>
        ))}
      </div>
      <SegmentedControl
        label={title}
        value={pm ? 'pm' : 'am'}
        onChange={v => setPm(v === 'pm')}
        options={[
          { value: 'am', label: t('hotelSettingsHoursAm') },
          { value: 'pm', label: t('hotelSettingsHoursPm') },
        ]}
      />
    </SheetFrame>
  )
}

// ---------------------------------------------------------------- closure sheet

export function ClosureContent({ onAdd, onClose }: { onAdd: (c: Omit<Closure, 'id'>) => void; onClose?: () => void }) {
  const { t } = useWords()
  const [range, setRange] = useState<DateRange>({ start: null, end: null })
  const [label, setLabel] = useState('')
  const ready = range.start !== null
  return (
    <SheetFrame
      title={t('hotelSettingsHoursAddTitle')}
      onClose={onClose}
      footer={
        <Button
          fullWidth
          disabled={!ready}
          onClick={() => range.start && onAdd({ label: { en: label.trim(), ar: label.trim() }, from: range.start, to: range.end ?? range.start, approximate: false })}
        >
          {t('hotelSettingsHoursAddConfirm')}
        </Button>
      }
    >
      <Calendar mode="range" value={range} onChange={setRange} legend={false} summary={false} label={t('hotelSettingsHoursAddTitle')} />
      <TextField label={t('hotelSettingsHoursAddLabel')} optional value={label} onValueChange={setLabel} autoComplete="off" />
    </SheetFrame>
  )
}

// ---------------------------------------------------------------- "Shown to couples as"

/** Sun–Thu, Fri, Sat, a single day, or every day: the days of one run in words. */
export function useRunDays() {
  const { t } = useWords()
  const f = useFormat()
  return (run: HoursRun): string => {
    const name = (d: number) => f.weekdayName(d, 'long')
    if (run.count === 7) return t('hotelSettingsHoursEveryDay')
    if (run.count === 1) return name(run.first)
    if (run.count === 2) return t('hotelSettingsHoursDaysPair', { first: name(run.first), last: name(run.last) })
    return t('hotelSettingsHoursDaysRange', { first: name(run.first), last: name(run.last) })
  }
}

export function usePreviewLines() {
  const { t } = useWords()
  const f = useFormat()
  const days = useRunDays()
  return (week: Week): string[] => {
    const runs = runsOf(week)
    if (runs.every(r => !r.open)) return [t('hotelSettingsHoursAllClosed')]
    return runs.map(r =>
      r.open
        ? t('hotelSettingsHoursLine', { days: days(r), from: f.time(clockAt(f, r.from)), to: f.time(clockAt(f, r.to)) })
        : t('hotelSettingsHoursLineClosed', { days: days(r) }),
    )
  }
}
