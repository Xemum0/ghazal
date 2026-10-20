// The two keys of the calendar, each behind an (i) (ADR 0034 section 6): what the marks of the month grid mean, and what the three segments of a
// day's bar are. They are lists of a shape and one word, not paragraphs, and they leave the screen quiet: the marks themselves carry the state
// by shape (never colour alone), and every day button names what each hall carries for assistive technology.
import type { ReactNode } from 'react'
import { InfoButton } from '../../../../system'
import { Hatch } from './Hatch'
import { Fx, useWords } from './calBits'
import './legend.css'

/** The marks of the month grid. The ring joins the list only while the soft dates are outlined. */
export function MonthKey({ soft }: { soft?: boolean }) {
  const { t, c } = useWords()
  return (
    <InfoButton title={t('hotelCalendarKeyTitle')}>
      <ul className="cal-key">
        <li className="cal-key__row">
          <span className="gz-hc__swatch">
            <i className="gz-hc__mark gz-hc__mark--booked" />
          </span>
          {c('commonAvailabilityBooked')}
        </li>
        <li className="cal-key__row">
          <span className="gz-hc__swatch">
            <i className="gz-hc__mark gz-hc__mark--held" />
          </span>
          {c('commonAvailabilityHeld')}
        </li>
        <li className="cal-key__row">
          <span className="gz-hc__swatch">
            <i className="gz-hc__mark gz-hc__mark--blocked" />
          </span>
          {c('commonAvailabilityBlocked')}
        </li>
        <li className="cal-key__row">
          <span className="gz-hc__swatch">
            <i className="gz-hc__req" />
          </span>
          {t('hotelCalendarRequestedLabel')}
        </li>
        {soft ? (
          <li className="cal-key__row">
            <span className="cal-key__ring" />
            {t('hotelCalendarLegendSoft')}
          </li>
        ) : null}
      </ul>
      <p className="cal-key__note">{t('hotelCalendarRequestNote')}</p>
    </InfoButton>
  )
}

export type ScheduleRow = { key: string; kind: 'setup' | 'event' | 'teardown'; label: string; time: string; extra?: string }

/** The phases of one hall's day: the shape of the segment, its word, its time. */
export function ScheduleKey({ title, rows, children }: { title: string; rows: readonly ScheduleRow[]; children?: ReactNode }) {
  const { t } = useWords()
  return (
    <InfoButton title={title} label={t('hotelCalendarTimes')}>
      <ul className="cal-key">
        {rows.map(row => (
          <li key={row.key} className="cal-key__row cal-key__row--time">
            <span className="cal-key__bar" data-kind={row.kind} aria-hidden="true">
              {row.kind === 'event' ? null : <Hatch tone="ink" />}
            </span>
            <span className="cal-key__word">{row.label}</span>
            <span className="cal-key__time">
              <Fx text={row.time} />
              {row.extra ? <span className="cal-key__next"><Fx text={row.extra} /></span> : null}
            </span>
          </li>
        ))}
      </ul>
      {children}
    </InfoButton>
  )
}
