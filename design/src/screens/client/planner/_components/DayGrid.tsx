// The next two weeks as a Sunday-first calendar strip: the month once above it, seven weekday initials (drawn, not read), then the days as
// 44+ wide cells with up to three gold-700 beads under the figure (windows chosen, or "has free times"). One day is selected (gold fill,
// the direction's selected-day anatomy). Shared by the consultation form (CL-PLAN-02) and the meeting sheet (CL-PLAN-04), so both read as
// one calendar. Every day is a radio with its full date as the accessible name; a day with nothing to offer is disabled, never greyed away.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat } from '../../../../i18n'
import { Icon } from '../../../../system'
import { isoToDate, monthNames } from './plannerFlow'
import './day-grid.css'

export type DayGridProps = {
  /** `YYYY-MM-DD`, consecutive, the first is the earliest bookable day. */
  days: readonly string[]
  value: string
  onPick: (iso: string) => void
  /** The group's accessible name. */
  name: string
  /** The accessible name of a day: the full date, plus what it holds. */
  label: (iso: string) => string
  /** What sits under the figure, up to three marks: the gold-700 bead (a day with free times) or a glyph (a window chosen on it). */
  marks?: (iso: string) => ReadonlyArray<IconName | 'bead'>
  /** A day that cannot be chosen (no free times). Default: all can. */
  enabled?: (iso: string) => boolean
  disabled?: boolean
  /** What sits at inline-end of the month line (the time zone). */
  aside?: ReactNode
}

export function DayGrid({ days, value, onPick, name, label, marks, enabled, disabled, aside }: DayGridProps) {
  const f = useFormat()
  const weekdays = f.weekdayHeaders()
  const first = days[0] ? f.civil(isoToDate(f, days[0])).weekday : 0
  const cells: (string | null)[] = [...Array.from({ length: first }, () => null), ...days]
  while (cells.length % 7 !== 0) cells.push(null)
  const rows = Array.from({ length: cells.length / 7 }, (_, i) => cells.slice(i * 7, i * 7 + 7))
  const months = monthNames(f, days)

  return (
    <div className="gzp-dg" data-gz-id="plan.days">
      <div className="gzp-dg__head">
        <span className="gzp-dg__months gz-t-title">
          {months.map((m, i) => (
            <span key={m} className="gzp-dg__month">
              {i > 0 ? <Icon name="arrow-right" size="xs" tone="secondary" /> : null}
              <span>{m}</span>
            </span>
          ))}
        </span>
        {aside ? <span className="gzp-dg__aside gz-t-caption">{aside}</span> : null}
      </div>
      <div className="gzp-dg__week" aria-hidden="true">
        {weekdays.map((w, i) => (
          <span key={i} className="gzp-dg__wk gz-t-caption">
            {w}
          </span>
        ))}
      </div>
      <div className="gzp-dg__days" role="radiogroup" aria-label={name}>
        {rows.map((row, r) => (
          <div key={r} className="gzp-dg__row">
            {row.map((iso, c) => {
              if (!iso) return <span key={c} className="gzp-dg__day is-blank" aria-hidden="true" />
              const on = enabled ? enabled(iso) : true
              const active = iso === value
              const under = marks ? marks(iso).slice(0, 3) : []
              return (
                <button
                  key={c}
                  type="button"
                  role="radio"
                  aria-checked={active}
                  aria-label={label(iso)}
                  disabled={!on || disabled}
                  data-selected={active || undefined}
                  className="gz-reset gzp-dg__day gz-press"
                  onClick={() => onPick(iso)}
                >
                  <span className="gz-t-cal-day">{f.integer(f.civil(isoToDate(f, iso)).day)}</span>
                  <span className="gzp-dg__marks" aria-hidden="true">
                    {under.map((m, i) =>
                      m === 'bead' ? <span key={i} className="gzp-dg__bead" /> : <Icon key={i} name={m} size="xs" className="gzp-dg__glyph" />,
                    )}
                  </span>
                </button>
              )
            })}
          </div>
        ))}
      </div>
    </div>
  )
}
