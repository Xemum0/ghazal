// BusinessHoursRow: one weekday of the venue's office hours (HL-SETT-05, HA-SET-04): the day, an open switch and, when open, the two times
// as 44-high buttons that open the custom time sheet (12-hour clock, Western digits, never the native picker). A closing time before the
// opening time runs past midnight and says so ("next day"), it is not an error; the same time on both ends is. "Copy to all days" sits
// under the row the person is editing. Times are Kuwait time, no device conversion.
import type { IsoDate } from '@gz/contracts'
import { useFormat } from '../../../i18n'
import { Button, Icon, Switch } from '../../core'
import { cx } from '../../core/cx'
import { Figures, clockInstant } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './settings.css'

const useW = defineWords({
  closed: p('Closed', 'مغلق'),
  open: p('Open on {day}', 'مفتوح يوم {day}'),
  from: p('Opens', 'يفتح'),
  to: p('Closes', 'يغلق'),
  nextDay: p('next day', 'اليوم التالي'),
  copy: p('Copy to all days', 'نسخ إلى كل الأيام'),
  invalid: p('The closing time is before the opening time.', 'وقت الإغلاق يسبق وقت الفتح.'),
  pick: p('{what} at {time}', '{what} الساعة {time}'),
})

export type BusinessHoursRowProps = {
  /** 0 = Sunday ... 6 = Saturday. */
  weekday: 0 | 1 | 2 | 3 | 4 | 5 | 6
  open: boolean
  /** Venue-local `HH:MM`. */
  from: string
  to: string
  onOpenChange?: (open: boolean) => void
  onPickFrom?: () => void
  onPickTo?: () => void
  /** Show "Copy to all days" under the row. */
  onCopy?: () => void
  /** Same opening and closing time. */
  invalid?: boolean
  /** Any date, only to anchor the clock formatting. */
  anchor?: IsoDate
  last?: boolean
  className?: string
}

export function BusinessHoursRow({ weekday, open, from, to, onOpenChange, onPickFrom, onPickTo, onCopy, invalid = false, anchor = '2026-11-15', last = false, className }: BusinessHoursRowProps) {
  const f = useFormat()
  const w = useW()
  const day = f.weekdayName(weekday, 'long')
  const time = (hhmm: string) => f.time(clockInstant(f, anchor, hhmm))
  const nextDay = open && to < from
  return (
    <div data-gz="BusinessHoursRow" data-open={open || undefined} className={cx('gz-bh', last && 'is-last', className)}>
      <div className="gz-bh__head">
        <span className="gz-bh__day gz-t-title">{day}</span>
        {!open ? <span className="gz-t-caption gz-bh__closed">{w('closed')}</span> : null}
        <Switch checked={open} onChange={onOpenChange} label={w('open', { day })} />
      </div>
      {open ? (
        <div className="gz-bh__times">
          <button type="button" className="gz-reset gz-bh__time gz-press" onClick={onPickFrom} aria-label={w('pick', { what: w('from'), time: f.plain(time(from)) })}>
            <span className="gz-t-caption gz-bh__what">{w('from')}</span>
            <span className="gz-bh__value gz-t-body-s">
              <Icon name="clock" size="xs" tone="secondary" />
              <Figures text={time(from)} />
            </span>
          </button>
          <button type="button" className={cx('gz-reset gz-bh__time gz-press', invalid && 'is-invalid')} onClick={onPickTo} aria-label={w('pick', { what: w('to'), time: f.plain(time(to)) })}>
            <span className="gz-t-caption gz-bh__what">{w('to')}</span>
            <span className="gz-bh__value gz-t-body-s">
              <Icon name="clock" size="xs" tone={invalid ? 'danger' : 'secondary'} />
              <Figures text={time(to)} />
              {nextDay ? <span className="gz-t-caption gz-bh__next">{w('nextDay')}</span> : null}
            </span>
          </button>
        </div>
      ) : null}
      {open && invalid ? (
        <p className="gz-t-caption gz-bh__error" role="alert">
          <Icon name="warning-circle" size="xs" tone="danger" />
          {w('invalid')}
        </p>
      ) : null}
      {open && onCopy ? (
        <Button variant="tertiary" iconStart="copy" onClick={onCopy}>
          {w('copy')}
        </Button>
      ) : null}
    </div>
  )
}
