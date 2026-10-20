// VisitDayRow (HL-VIST-05): one weekday of the visit availability: the day, an open switch and, when open, the two times as 56-high buttons
// that open the time sheet (12-hour clock, Western digits, never the native picker). Like the business-hours row, with one more rule: the
// window must sit inside the venue's business hours, and says which two mistakes it has (end not after start, outside business hours).
import { useFormat } from '../../../../i18n'
import { Icon, Switch } from '../../../../system'
import { Figures, useWords } from './bits'
import { clockOf, type DayMistake } from './availability'
import type { DayWindow } from './store'
import './visit-day-row.css'

export type VisitDayRowProps = {
  weekday: 0 | 1 | 2 | 3 | 4 | 5 | 6
  day: DayWindow
  mistake: DayMistake
  disabled?: boolean
  onToggle: (open: boolean) => void
  onPickFrom: () => void
  onPickTo: () => void
  last?: boolean
}

export function VisitDayRow({ weekday, day, mistake, disabled = false, onToggle, onPickFrom, onPickTo, last = false }: VisitDayRowProps) {
  const f = useFormat()
  const { t } = useWords()
  const name = f.weekdayName(weekday, 'long')
  const time = (hhmm: string) => f.time(clockOf(f, hhmm))
  return (
    <div className={`hv-day${last ? ' is-last' : ''}`} data-gz="VisitDayRow" data-open={day.open || undefined}>
      <div className="hv-day__head">
        <span className="gz-t-title hv-day__name">{name}</span>
        {!day.open ? <span className="gz-t-caption hv-day__closed">{t('hotelVisitsDayNoVisits')}</span> : null}
        <Switch checked={day.open} onChange={onToggle} disabled={disabled} label={t('hotelVisitsDayOpenLabel', { day: name })} />
      </div>
      {day.open ? (
        <div className="hv-day__times">
          <button type="button" className="gz-reset gz-press hv-day__time" disabled={disabled} onClick={onPickFrom} aria-label={t('hotelVisitsDayPick', { what: t('hotelVisitsDayFrom'), time: f.plain(time(day.from)) })}>
            <span className="gz-t-caption hv-day__what">{t('hotelVisitsDayFrom')}</span>
            <span className="hv-day__value gz-t-body-s">
              <Icon name="clock" size="xs" tone="secondary" />
              <Figures text={time(day.from)} />
            </span>
          </button>
          <button type="button" className={`gz-reset gz-press hv-day__time${mistake ? ' is-invalid' : ''}`} disabled={disabled} onClick={onPickTo} aria-label={t('hotelVisitsDayPick', { what: t('hotelVisitsDayTo'), time: f.plain(time(day.to)) })}>
            <span className="gz-t-caption hv-day__what">{t('hotelVisitsDayTo')}</span>
            <span className="hv-day__value gz-t-body-s">
              <Icon name="clock" size="xs" tone={mistake ? 'danger' : 'secondary'} />
              <Figures text={time(day.to)} />
            </span>
          </button>
        </div>
      ) : null}
      {day.open && mistake ? (
        <p className="gz-t-caption hv-day__error" role="alert">
          <Icon name="warning-circle" size="xs" tone="danger" />
          {mistake === 'order' ? t('hotelVisitsDayErrorOrder') : t('hotelVisitsDayErrorBounds')}
        </p>
      ) : null}
    </div>
  )
}
