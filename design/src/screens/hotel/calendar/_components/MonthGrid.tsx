// MonthGrid: the system's HotelMonthGrid on the flow's gutter, with the one thing the system grid does not draw yet: soft-date mode, where the
// unsold weekend dates of the next 60 days are outlined (a 1 px gold-650 ring, the sole carrier is the ring plus the key behind the (i),
// never colour alone). The outline is applied to the grid's own day buttons by their `data-iso`; requested in docs/engineering/requests.md
// as a `softDates` prop of HotelMonthGrid. The legend line the grid used to carry now lives behind the (i) of the period header (MonthKey).
import { useEffect, useRef } from 'react'
import type { CalendarClaim, Hall, IsoDate } from '../../../../mock'
import { HotelMonthGrid } from '../../../../system'
import type { DateSpan } from '../../../../system'
import { SOFT_DATES } from './data'
import { useMonthTitle, useWords } from './calBits'
import type { YearMonth } from './store'
import './month-grid.css'

export type MonthGridProps = {
  halls: readonly Hall[]
  claims: readonly CalendarClaim[]
  ym: YearMonth
  onYm: (ym: YearMonth) => void
  mode: 'view' | 'select'
  selected: IsoDate | null
  onSelect: (iso: IsoDate) => void
  range: DateSpan
  onRange: (r: DateSpan) => void
  soft?: boolean
}

export function MonthGrid({ halls, claims, ym, onYm, mode, selected, onSelect, range, onRange, soft }: MonthGridProps) {
  const { t } = useWords()
  const title = useMonthTitle()
  const ref = useRef<HTMLDivElement>(null)

  // Outline the soft dates after every render (the grid re-renders on month change, selection and range change). The grid's own month header is
  // display:none here (the flow draws its own); it is marked hidden for assistive technology and the word census too (a request is filed for a
  // `header` prop of HotelMonthGrid).
  useEffect(() => {
    ref.current?.querySelector('.gz-hc__head')?.setAttribute('aria-hidden', 'true')
    ref.current?.querySelectorAll<HTMLElement>('[data-iso]').forEach(el => {
      if (soft && SOFT_DATES.includes(el.dataset.iso ?? '')) el.setAttribute('data-soft', '')
      else el.removeAttribute('data-soft')
    })
  })

  return (
    <div ref={ref} className="cal-grid" data-soft-mode={soft || undefined}>
      <HotelMonthGrid
        halls={halls}
        claims={claims}
        month={ym}
        onMonthChange={onYm}
        mode={mode}
        selected={selected}
        onSelectDate={onSelect}
        range={range}
        onRangeChange={onRange}
        legend={false}
        label={t('hotelCalendarGridLabel', { month: title(ym.year, ym.month) })}
      />
    </div>
  )
}
