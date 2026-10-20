// HallChoice: which hall, shown only when more than one fits (ADR 0002). A single-choice list rather than a segmented control, because a
// hall name is a serif name and "Danah Ballroom" must never be cut: each row carries the name, what the hall holds as a glyph and a figure,
// and the same ink border and check as a chosen package (choice is ink, never gold alone).
import type { Hall } from '../../../../mock'
import { FactChip, Icon, useBi } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import './hall.css'

export type HallChoiceProps = {
  label: string
  halls: { hall: Hall; max: number }[]
  value: string
  onChange: (hallId: string) => void
}

export function HallChoice({ label, halls, value, onChange }: HallChoiceProps) {
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  return (
    <div className="bk-halls" role="radiogroup" aria-label={label} data-gz="HallChoice">
      {halls.map(({ hall, max }) => {
        const on = hall.id === value
        return (
          <button key={hall.id} type="button" role="radio" aria-checked={on} className={on ? 'gz-reset gz-press bk-hall is-selected' : 'gz-reset gz-press bk-hall'} onClick={() => onChange(hall.id)}>
            <span className="bk-hall__mark" aria-hidden="true">{on ? <Icon name="check" size="xs" /> : null}</span>
            <span className="bk-hall__name gz-t-d1">{bi(hall.name)}</span>
            <FactChip icon="users-three" label={tc('commonUnitUpToGuests', { count: max })} value={f.integer(max)} />
          </button>
        )
      })}
    </div>
  )
}
