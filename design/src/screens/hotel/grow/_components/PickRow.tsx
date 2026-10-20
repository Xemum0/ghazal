// PickRow: choose which packages or halls a window covers without printing them all. One field-sized row: a glyph, the choice in a few words
// (`All`, one name, or the first name and a count) and a chevron; a tap opens the system sheet with a checkbox per option and `All` first.
// Empty selection means all (the model's rule): picking a specific one drops `All`, picking `All` clears the specific ones. The names are the
// venue's own and stay in their script.
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat } from '../../../../i18n'
import { Button, Checkbox, Icon, PickerSheet } from '../../../../system'
import { Fig, useWords } from './bits'
import './pick-row.css'

export type PickOption = { value: string; label: string }

export type PickRowProps = {
  icon: IconName
  /** One word: the sheet title and the accessible name of the row. */
  label: string
  /** The `All` option's text. */
  allLabel: string
  options: readonly PickOption[]
  /** The chosen ids; empty means all. */
  value: readonly string[]
  onChange: (next: string[]) => void
  disabled?: boolean
}

export function PickRow({ icon, label, allLabel, options, value, onChange, disabled }: PickRowProps) {
  const f = useFormat()
  const { c } = useWords()
  const [open, setOpen] = useState(false)
  const chosen = options.filter(o => value.includes(o.value))
  const first = chosen[0]
  const toggle = (id: string, on: boolean) => {
    const next = on ? [...value, id] : value.filter(v => v !== id)
    onChange(next.length === options.length ? [] : next)
  }
  return (
    <>
      <button type="button" className="gz-reset gz-press gk-pick" disabled={disabled} aria-haspopup="dialog" aria-expanded={open} aria-label={label} onClick={() => setOpen(true)}>
        <Icon name={icon} size="sm" tone="secondary" />
        <span className="gk-pick__text gz-t-body">
          {first ? <bdi dir="auto">{first.label}</bdi> : allLabel}
          {chosen.length > 1 ? (
            <span className="gk-pick__more gz-t-caption">
              +<Fig>{f.integer(chosen.length - 1)}</Fig>
            </span>
          ) : null}
        </span>
        <Icon name="chevron-down" size="sm" tone="secondary" />
      </button>
      <PickerSheet
        open={open}
        onClose={() => setOpen(false)}
        title={label}
        footer={
          <Button variant="primary" fullWidth onClick={() => setOpen(false)}>
            {c('commonActionDone')}
          </Button>
        }
      >
        <div className="gk-pick__list" role="group" aria-label={label}>
          <Checkbox checked={value.length === 0} onChange={on => on && onChange([])}>
            {allLabel}
          </Checkbox>
          {options.map(o => (
            <Checkbox key={o.value} checked={value.includes(o.value)} onChange={on => toggle(o.value, on)}>
              <bdi dir="auto">{o.label}</bdi>
            </Checkbox>
          ))}
        </div>
      </PickerSheet>
    </>
  )
}
