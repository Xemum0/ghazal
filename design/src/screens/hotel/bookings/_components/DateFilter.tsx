// DateFilter: the date filter sheet of the Bookings tab (HL-BOOK-02): a Sunday-first range calendar (no native picker) that filters the
// whole tab by event date or by request date. The choice between the two is two glyphs (a calendar tick, a paper plane) with their words; the
// range reads as one fact under the calendar; no instruction. The applied range shows as a removable chip under the segments (RangeChip).
// Every day is selectable here: the venue looks back as well as forward, so the calendar's own "past days are closed" rule is switched off.
import { useMemo, useState } from 'react'
import { engine, PROTOTYPE_TODAY } from '../../../../mock'
import { useT } from '../../../../i18n'
import { Button, Calendar, FactChip, Icon, IconSegmented, type DateRange as CalRange } from '../../../../system'
import { Fx, useDays } from './bits'
import { SheetFrame } from './SheetFrame'
import type { DateField, DateRange } from './model'
import './date-filter.css'

/** Every day of the look-back and look-ahead window is a plain available day for the filter. */
function useOpenDays() {
  return useMemo(() => {
    const out: Record<string, { status: 'available' }> = {}
    const start = engine.addDays(PROTOTYPE_TODAY, -400)
    for (let i = 0; i <= 800; i++) out[engine.addDays(start, i)] = { status: 'available' }
    return out
  }, [])
}

/** `19 Nov` for a single day, `19 Nov - 19 Dec` for a range. */
function useRangeText() {
  const days = useDays()
  const t = useT('hotel-bookings')
  return (start: string, end: string | null) => (end && end !== start ? t('hotelBookingsRangeLine', { from: days.dm(start), to: days.dm(end) }) : days.dm(start))
}

export type DateFilterProps = {
  field: DateField
  range: DateRange
  onApply: (range: DateRange, field: DateField) => void
  onClose: () => void
}

export function DateFilterContent({ field: initialField, range: initial, onApply, onClose }: DateFilterProps) {
  const t = useT('hotel-bookings')
  const c = useT('common')
  const days = useOpenDays()
  const rangeText = useRangeText()
  const [field, setField] = useState<DateField>(initialField)
  const [range, setRange] = useState<CalRange>({ start: initial.start, end: initial.end })
  const ready = Boolean(range.start)

  return (
    <SheetFrame
      title={t('hotelBookingsFilterTitle')}
      onClose={onClose}
      footer={
        <>
          <Button variant="primary" fullWidth disabled={!ready} onClick={() => onApply({ start: range.start, end: range.end ?? range.start }, field)}>
            {c('commonActionApply')}
          </Button>
          <Button variant="tertiary" onClick={() => onApply({ start: null, end: null }, field)}>
            {c('commonActionClear')}
          </Button>
        </>
      }
    >
      <IconSegmented<DateField>
        label={t('hotelBookingsFilterBy')}
        labels="all"
        value={field}
        onChange={setField}
        options={[
          { value: 'event', icon: 'calendar-check', label: t('hotelBookingsFilterEvent') },
          { value: 'request', icon: 'send', label: t('hotelBookingsFilterRequest') },
        ]}
      />
      <Calendar mode="range" value={range} onChange={setRange} days={days} legend={false} isSelectable={() => true} label={t('hotelBookingsFilterTitle')} />
      <div className="hbk-range" role="status">
        {range.start ? (
          <FactChip icon="calendar" label={t('hotelBookingsFilterTitle')} value={<Fx text={rangeText(range.start, range.end)} />} />
        ) : null}
      </div>
    </SheetFrame>
  )
}

export type RangeChipProps = {
  range: DateRange
  field: DateField
  onRemove: () => void
  onEdit: () => void
}

/** The applied range as a chip with a remove control (44 targets: the label opens the filter, the cross removes it). */
export function RangeChip({ range, field, onRemove, onEdit }: RangeChipProps) {
  const t = useT('hotel-bookings')
  const c = useT('common')
  const rangeText = useRangeText()
  if (!range.start) return null
  const text = rangeText(range.start, range.end)
  return (
    <div className="hbk-rchip" role="group" aria-label={t('hotelBookingsRangeApplied')}>
      <button type="button" className="gz-reset hbk-rchip__label gz-t-body-s gz-press" onClick={onEdit}>
        <Icon name={field === 'event' ? 'calendar-check' : 'send'} size="sm" tone="secondary" />
        <span className="gz-sr-only">{field === 'event' ? t('hotelBookingsFilterEvent') : t('hotelBookingsFilterRequest')}</span>
        <Fx text={text} />
      </button>
      <button type="button" className="gz-reset hbk-rchip__remove gz-press" aria-label={`${c('commonActionRemove')}: ${text}`} onClick={onRemove}>
        <Icon name="close" size="sm" />
      </button>
    </div>
  )
}
