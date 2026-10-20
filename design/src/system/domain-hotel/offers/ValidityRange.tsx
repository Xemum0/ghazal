// ValidityRange: step 2 of the voucher-price window editor (HL-GROW-03): when the voucher price applies and when it runs. The event dates are
// a range picked in the shared DateField (custom calendar sheet, never the native picker); a time-boxed window also takes a duration chip
// (6 / 12 / 24 / 48 hours) that resolves to an absolute end time, shown as a line under it; the status says whether the window is Scheduled
// (starts in the future), Active or Ended with a pill (icon + label). Times are absolute and in Kuwait time; nothing counts down for couples.
import type { IsoDate, IsoDateTime } from '@gz/contracts'
import { useFormat } from '../../../i18n'
import { StatusPill } from '../../core'
import { ChipGroup, DateField, type DateRange } from '../../inputs'
import { cx } from '../../core/cx'
import { Figures } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './offers.css'

const useW = defineWords({
  eventDates: p('Event dates', 'تواريخ المناسبة'),
  helper: p('The lower voucher price applies to events on these dates.', 'يسري سعر الكوبون الأقل على المناسبات في هذه التواريخ.'),
  window: p('This price runs for', 'مدة هذا السعر'),
  hours: p('{n} hours', '{n} ساعة'),
  ends: p('Ends {time}', 'ينتهي {time}'),
  scheduled: p('Scheduled', 'مجدول'),
  active: p('Active', 'نشط'),
  ended: p('Ended', 'منتهٍ'),
  starts: p('Starts {time}', 'يبدأ {time}'),
})

export type ValidityStatus = 'scheduled' | 'active' | 'ended'

export type ValidityRangeProps = {
  /** The event dates the offer covers. */
  value: DateRange
  onChange?: (r: DateRange) => void
  /** Flash sale only: the window in hours (6, 12, 24, 48) and the absolute end it resolves to. */
  windowHours?: 6 | 12 | 24 | 48
  onWindowChange?: (h: 6 | 12 | 24 | 48) => void
  endsAt?: IsoDateTime
  startsAt?: IsoDateTime
  status?: ValidityStatus
  today?: IsoDate
  error?: string
  className?: string
}

const WINDOWS = [6, 12, 24, 48] as const

export function ValidityRange({ value, onChange, windowHours, onWindowChange, endsAt, startsAt, status, today, error, className }: ValidityRangeProps) {
  const f = useFormat()
  const w = useW()
  return (
    <div data-gz="ValidityRange" className={cx('gz-vr', className)}>
      <DateField mode="range" label={w('eventDates')} helper={w('helper')} value={value} onChange={onChange} today={today} error={error} />
      {windowHours !== undefined ? (
        <div className="gz-vr__window">
          <p className="gz-t-label gz-vr__label">{w('window')}</p>
          <ChipGroup
            label={w('window')}
            layout="wrap"
            value={windowHours}
            onChange={v => v && onWindowChange?.(v as 6 | 12 | 24 | 48)}
            options={WINDOWS.map(h => ({ value: h, label: <Figures text={w('hours', { n: f.integer(h) })} /> }))}
          />
        </div>
      ) : null}
      {status || endsAt ? (
        <div className="gz-vr__status">
          {status ? <StatusPill status={status === 'active' ? 'confirmed' : status === 'scheduled' ? 'requested' : 'expired'} label={w(status)} /> : null}
          <span className="gz-t-caption gz-vr__line">
            <Figures text={status === 'scheduled' && startsAt ? w('starts', { time: f.dateTime(startsAt) }) : endsAt ? w('ends', { time: f.dateTime(endsAt) }) : ''} />
          </span>
        </div>
      ) : null}
    </div>
  )
}
