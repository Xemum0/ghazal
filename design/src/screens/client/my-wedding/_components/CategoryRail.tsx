// CategoryRail (CL-WEDD-04): the category of an expense, chosen by glyph. Two lines of four 44-high options (no scrolling in a sheet); the chosen
// one has the ink border and the gold bead, and its one-word name sits under the rail (every option's name is its accessible name). A radio group
// with roving tabindex, arrows follow what you see. Gold is the bead only, never a fill (direction 2.3).
import { useRef, type KeyboardEvent } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon } from '../../../../system'
import './sheet.css'

export type CategoryOption = { value: string; icon: IconName; /** One word; the accessible name. */ label: string }

export type CategoryRailProps = {
  options: readonly CategoryOption[]
  value: string
  onChange: (value: string) => void
  /** The group's accessible name. */
  label: string
  disabled?: boolean
}

export function CategoryRail({ options, value, onChange, label, disabled }: CategoryRailProps) {
  const ref = useRef<HTMLDivElement>(null)
  const active = Math.max(0, options.findIndex(o => o.value === value))
  const rows = [options.slice(0, 4), options.slice(4)].filter(r => r.length > 0)
  const chosen = options[active]

  const onKey = (e: KeyboardEvent<HTMLButtonElement>, i: number) => {
    const dir = ref.current && window.getComputedStyle(ref.current).direction === 'rtl' ? -1 : 1
    let to = -1
    if (e.key === 'ArrowRight') to = i + dir
    else if (e.key === 'ArrowLeft') to = i - dir
    else if (e.key === 'ArrowDown') to = i + 4
    else if (e.key === 'ArrowUp') to = i - 4
    if (to < 0 || to >= options.length) return
    e.preventDefault()
    const next = options[to]
    if (!next) return
    onChange(next.value)
    ref.current?.querySelectorAll<HTMLElement>('[role="radio"]')[to]?.focus()
  }

  return (
    <div className="gzmw-rail" data-gz="CategoryRail">
      <div ref={ref} role="radiogroup" aria-label={label} aria-disabled={disabled || undefined} className="gzmw-rail__rows">
        {rows.map((row, r) => (
          <div className="gzmw-rail__row" key={r}>
            {row.map((o, c) => {
              const i = r * 4 + c
              const selected = i === active
              return (
                <button
                  key={o.value}
                  type="button"
                  role="radio"
                  aria-checked={selected}
                  aria-label={o.label}
                  tabIndex={selected ? 0 : -1}
                  disabled={disabled}
                  className={`gz-reset gzmw-rail__opt gz-press${selected ? ' is-selected' : ''}`}
                  onClick={() => onChange(o.value)}
                  onKeyDown={e => onKey(e, i)}
                >
                  <Icon name={o.icon} size="md" tone="primary" />
                  {selected ? <span className="gzmw-rail__bead" aria-hidden="true" /> : null}
                </button>
              )
            })}
          </div>
        ))}
      </div>
      <p className="gzmw-rail__name gz-t-caption" aria-live="polite">
        {chosen?.label}
      </p>
    </div>
  )
}
