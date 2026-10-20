// WeekStrip: the 7-day strip of Hotel Today (direction 3 "7-day strip", rule 5): seven flex columns, at least 88 high, each with the short
// weekday, the date in the figures voice and up to three 4 px marks, one per hall or session: confirmed = solid ink-700, pending (a
// request or a hold) = gold-500, open = a hairline outline. Today has an ink-900 1 px outline; the selected day is the one gold fill
// (ring 2 px canvas + 1 px gold-600). The legend and every day's accessible name carry the counts, so colour is never the only signal.
// Longer ranges wrap into rows of seven (the 14-day availability strip of ADR 0008 D4).
import type { ReactNode } from 'react'
import type { IsoDate } from '@gz/contracts'
import { engine } from '../../mock'
import { useFormat } from '../../i18n'
import { cx } from '../core/cx'
import { Fig } from './internal/bits'
import { defineWords, definePlurals, p } from './internal/copy'
import './week-strip.css'

export type StripMark = 'confirmed' | 'pending' | 'open'
export type StripDay = {
  iso: IsoDate
  /** One mark per hall or session, at most three. */
  marks: readonly StripMark[]
}

const useW = defineWords({
  confirmed: p('Confirmed', 'مؤكد'),
  pending: p('Pending or on hold', 'بانتظار الرد أو محجوز مؤقتًا'),
  open: p('Open', 'متاح'),
  today: p('Today', 'اليوم'),
  selected: p('selected', 'محدد'),
  sep: p(', ', '، '),
})

const usePl = definePlurals({
  confirmed: { en: { other: '{n} confirmed' }, ar: { '=1': 'حجز مؤكد', '=2': 'حجزان مؤكدان', few: '{n} حجوزات مؤكدة', many: '{n} حجزًا مؤكدًا', other: '{n} حجز مؤكد' } },
  pending: { en: { other: '{n} pending' }, ar: { '=1': 'طلب بانتظار الرد', '=2': 'طلبان بانتظار الرد', few: '{n} طلبات بانتظار الرد', many: '{n} طلبًا بانتظار الرد', other: '{n} طلب بانتظار الرد' } },
  open: { en: { other: '{n} open' }, ar: { '=1': 'فترة متاحة', '=2': 'فترتان متاحتان', few: '{n} فترات متاحة', many: '{n} فترة متاحة', other: '{n} فترة متاحة' } },
})

export type WeekStripProps = {
  days: readonly StripDay[]
  /** Default: the prototype's today. */
  today?: IsoDate
  selected?: IsoDate | null
  onSelect?: (iso: IsoDate) => void
  /** Show the legend with the counts under the strip (default on). */
  legend?: boolean
  /** Accessible name of the strip ("Next 7 days"). */
  label: string
  /** Under the legend: `6 open weekend dates in the next 60 days` and its link (ADR 0008 D4). */
  footer?: ReactNode
  className?: string
}

export function WeekStrip({ days, today, selected, onSelect, legend = true, label, footer, className }: WeekStripProps) {
  const f = useFormat()
  const w = useW()
  const pl = usePl()
  const now = today ?? f.isoDay(f.now())
  const rows: StripDay[][] = []
  for (let i = 0; i < days.length; i += 7) rows.push(days.slice(i, i + 7))
  const count = (m: StripMark) => days.reduce((a, d) => a + d.marks.filter(x => x === m).length, 0)

  const dayName = (d: StripDay) => {
    const c = d.marks.filter(m => m === 'confirmed').length
    const pd = d.marks.filter(m => m === 'pending').length
    const o = d.marks.filter(m => m === 'open').length
    const parts = [c ? pl('confirmed', c) : '', pd ? pl('pending', pd) : '', o ? pl('open', o) : ''].filter(Boolean)
    return [f.date(d.iso, 'short'), d.iso === now ? w('today') : '', parts.join(w('sep'))].filter(Boolean).join(w('sep'))
  }

  return (
    <div data-gz="WeekStrip" className={cx('gz-ws', className)} role="group" aria-label={label}>
      <div className="gz-ws__rows">
        {rows.map((row, r) => (
          <div key={r} className="gz-ws__row">
            {row.map(d => {
              const wd = engine.weekdayOf(d.iso)
              const isToday = d.iso === now
              const isSel = selected === d.iso
              return (
                <button
                  key={d.iso}
                  type="button"
                  className={cx('gz-reset gz-ws__day gz-select', isToday && 'is-today', isSel && 'is-selected')}
                  aria-label={dayName(d)}
                  aria-pressed={onSelect ? isSel : undefined}
                  onClick={() => onSelect?.(d.iso)}
                >
                  <span className="gz-ws__wd gz-t-caption">{f.weekdayName(wd, 'header')}</span>
                  <span className="gz-ws__fig gz-t-price-strong">
                    <Fig>{f.integer(Number(d.iso.slice(8)))}</Fig>
                  </span>
                  <span className="gz-ws__marks" aria-hidden="true">
                    {d.marks.slice(0, 3).map((m, i) => (
                      <i key={i} className={cx('gz-ws__mark', `gz-ws__mark--${m}`)} />
                    ))}
                  </span>
                </button>
              )
            })}
          </div>
        ))}
      </div>
      {legend ? (
        <ul className="gz-ws__legend gz-t-caption">
          {(['confirmed', 'pending', 'open'] as const).map(m => (
            <li key={m} className="gz-ws__key">
              <i className={cx('gz-ws__mark', `gz-ws__mark--${m}`)} aria-hidden="true" />
              <span>{w(m)}</span>
              <Fig>{f.integer(count(m))}</Fig>
            </li>
          ))}
        </ul>
      ) : null}
      {footer}
    </div>
  )
}
