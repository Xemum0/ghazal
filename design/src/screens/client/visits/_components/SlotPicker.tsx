// SlotPicker (CL-VIST-01, CL-VIST-05): the day rail and the 30-minute arrival windows of one venue's visit hours, with no words on it
// (ADR 0034). The rail shows only the next days that have a free window (the venue's visit rules, Kuwait time) as figures; the chosen day
// is the gold calendar cell and the only one that spells its weekday and month (every cell keeps its full date as its accessible name).
// Windows are grouped by the part of the day as a glyph (sun, sunset, moon) with the meridiem once beside it, then chips that carry only
// the start time. A window that is gone stays in place, struck by its `clock-off` glyph, so the person sees why a time moved.
import { useMemo } from 'react'
import type { IconName } from '@gz/tokens'
import { PROTOTYPE_NOW, visitDatesFor, visitSlotsFor } from '../../../../mock'
import { Chip, Figures, Icon } from '../../../../system'
import { useV } from './model'
import './slot-picker.css'

export type SlotPickerProps = {
  venueId: string
  date: string | null
  slot: string | null
  onChange: (date: string, slot: string | null) => void
  /** A window that was taken while the sheet was open: its chip is struck. */
  takenSlot?: string | null
  /** Hide days before this many days from now (the "no slots this week" frame). */
  skipDays?: number
  disabled?: boolean
}

const GROUPS = ['morning', 'afternoon', 'evening'] as const
type Group = (typeof GROUPS)[number]
const GROUP_ICON: Record<Group, IconName> = { morning: 'sun', afternoon: 'sunset', evening: 'moon' }

export function useVisitDates(venueId: string, skipDays = 0): string[] {
  const { f } = useV()
  return useMemo(() => visitDatesFor(venueId).filter(d => f.daysUntil(d) > skipDays), [venueId, skipDays, f])
}

export function SlotPicker({ venueId, date, slot, onChange, takenSlot, skipDays = 0, disabled = false }: SlotPickerProps) {
  const { t, f, clockParts, isRtl } = useV()
  const dates = useVisitDates(venueId, skipDays)
  const active = date && dates.includes(date) ? date : (dates[0] ?? null)
  const slots = useMemo(() => (active ? visitSlotsFor(venueId, active) : []), [venueId, active])
  const groups = useMemo(() => {
    const of = (iso: string): Group => {
      const h = f.civil(iso).hour
      return h < 12 ? 'morning' : h < 17 ? 'afternoon' : 'evening'
    }
    return GROUPS.map(g => ({ id: g, slots: slots.filter(s => of(s.start) === g) })).filter(g => g.slots.length > 0)
  }, [slots, f])
  const groupName = (g: Group) => t(g === 'morning' ? 'clientVisitsSlotMorning' : g === 'afternoon' ? 'clientVisitsSlotAfternoon' : 'clientVisitsSlotEvening')

  const pickDate = (d: string) => {
    const first = visitSlotsFor(venueId, d).find(s => s.available)
    onChange(d, first?.start ?? null)
  }

  const onKey = (e: React.KeyboardEvent<HTMLButtonElement>, i: number) => {
    const step = e.key === 'ArrowRight' ? (isRtl ? -1 : 1) : e.key === 'ArrowLeft' ? (isRtl ? 1 : -1) : 0
    if (!step) return
    const next = dates[i + step]
    if (!next) return
    e.preventDefault()
    pickDate(next)
    e.currentTarget.parentElement?.querySelectorAll<HTMLElement>('[role="radio"]')[i + step]?.focus()
  }

  return (
    <div className="gzvt-slot" data-gz-id="visits.slots">
      <div className="gzvt-days gz-no-scrollbar" role="radiogroup" aria-label={t('clientVisitsSlotDay')}>
        {dates.map((d, i) => {
          const c = f.civil(d)
          const on = d === active
          return (
            <button
              key={d}
              type="button"
              role="radio"
              aria-checked={on}
              tabIndex={on ? 0 : -1}
              disabled={disabled}
              data-selected={on || undefined}
              className="gz-reset gzvt-day gz-press"
              onClick={() => pickDate(d)}
              onKeyDown={e => onKey(e, i)}
              aria-label={f.plain(f.date(d, 'full'))}
            >
              {on ? <span className="gzvt-day__wd gz-t-caption">{f.weekdayName(c.weekday, 'short')}</span> : null}
              <span className="gzvt-day__n gz-t-fig-title">
                <Figures text={f.integer(c.day)} />
              </span>
              {on ? <span className="gzvt-day__mo gz-t-caption">{f.monthName(c.month, 'short')}</span> : null}
            </button>
          )
        })}
      </div>

      <div className="gzvt-groups">
        {groups.map(g => {
          const mer = clockParts(g.slots[0]!.start).mer
          return (
            <div key={g.id} className="gzvt-group" role="group" aria-label={groupName(g.id)}>
              <span className="gzvt-group__mark" aria-hidden="true">
                <Icon name={GROUP_ICON[g.id]} size="md" />
                <span className="gzvt-group__mer gz-t-caption">{mer}</span>
              </span>
              <div className="gzvt-chips">
                {g.slots.map(s => {
                  const taken = s.start === takenSlot || (!s.available && s.start > PROTOTYPE_NOW)
                  const { hm, mer: unit } = clockParts(s.start)
                  const label = (
                    <>
                      <Figures text={hm} />
                      <span className="gz-sr-only"> {unit}</span>
                    </>
                  )
                  return taken ? (
                    <Chip key={s.start} disabled iconStart="clock-off" className="gzvt-chip--taken">
                      {label}
                      <span className="gz-sr-only"> {t('clientVisitsSlotTaken')}</span>
                    </Chip>
                  ) : (
                    <Chip key={s.start} selected={s.start === slot} disabled={disabled || !s.available} onClick={() => active && onChange(active, s.start)}>
                      {label}
                    </Chip>
                  )
                })}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
