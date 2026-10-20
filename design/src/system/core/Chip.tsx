// Chip and FilterChip (direction section 3): 44 high, radius 8, 1 px ink-300 border, body-s label. Selected = ink-900 border on
// paper, the label in 500 and an 8 px gold bead (a thing chosen). The 500 weight is reserved by a hidden copy of the label,
// so choosing a chip never changes the width of its label. FilterChip adds a count (a gold count badge) and a menu chevron.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { cx } from './cx'
import { Icon } from './Icon'
import { CountBadge } from './Badge'
import './core.css'
import './chip.css'

export type ChipProps = {
  children: ReactNode
  /** Chosen: ink border, bead, weight 500. Makes the chip a toggle (aria-pressed). */
  selected?: boolean
  iconStart?: IconName
  disabled?: boolean
  onClick?: () => void
  /** Opens a sheet or menu: trailing chevron-down and aria-haspopup. */
  menu?: boolean
  /** Number of filters applied (shown as a gold count badge when above zero). */
  count?: number
  previewState?: 'pressed' | 'focus'
  className?: string
}

export function Chip({ children, selected, iconStart, disabled, onClick, menu, count, previewState, className }: ChipProps) {
  const interactive = Boolean(onClick) || selected !== undefined || menu
  const classes = cx(
    'gz-chip gz-t-body-s gz-select',
    interactive && 'gz-chip--interactive gz-press',
    selected && 'is-selected',
    previewState === 'pressed' && 'is-pressed',
    previewState === 'focus' && 'is-focus',
    className,
  )
  const body = (
    <>
      {selected ? <span className="gz-chip__bead" aria-hidden="true"><span className="gz-bead" /></span> : null}
      {iconStart ? <Icon name={iconStart} size="sm" /> : null}
      <span className="gz-chip__label">
        <span>{children}</span>
        <span className="gz-chip__ghost" aria-hidden="true">{children}</span>
      </span>
      {count && count > 0 ? <CountBadge count={count} /> : null}
      {menu ? <Icon name="chevron-down" size="xs" /> : null}
    </>
  )
  if (!interactive) {
    return (
      <span data-gz="Chip" className={classes}>
        {body}
      </span>
    )
  }
  return (
    <button
      type="button"
      data-gz="Chip"
      className={cx('gz-reset', classes)}
      disabled={disabled}
      aria-pressed={selected === undefined ? undefined : selected}
      aria-haspopup={menu ? 'dialog' : undefined}
      onClick={onClick}
    >
      {body}
    </button>
  )
}

export type FilterChipProps = Omit<ChipProps, 'selected' | 'onClick'> & {
  selected: boolean
  onToggle: (next: boolean) => void
}

/** A chip that filters: toggles on tap, or (with `menu`) opens the filter sheet and reports how many filters are on. */
export function FilterChip({ selected, onToggle, ...rest }: FilterChipProps) {
  return <Chip {...rest} selected={selected} onClick={() => onToggle(!selected)} />
}
