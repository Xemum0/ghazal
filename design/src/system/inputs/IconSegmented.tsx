// IconSegmented (ADR 0034): the segmented control as glyphs. Equal, fixed-width options in an ink-100 track; the selected option is
// the ink-700 pill (canvas glyph) with the 2 px gold thread, and shows a one-word label beside its glyph (`labels="all"` shows every
// word, `labels="none"` is glyphs only: the label is then the accessible name). Option widths are equal and never depend on the
// label, so the pill slides between identical cells and nothing resizes. Measured scale-safe from the START edge (useThread).
import { useRef, type CSSProperties, type KeyboardEvent } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon } from '../core/Icon'
import { cx } from '../core/cx'
import { rovingIndex } from './internal/roving'
import { useControllable } from './internal/useControllable'
import { useThread } from './internal/useThread'
import './internal/base.css'
import './icon-segmented.css'

export type IconSegmentedOption<V extends string> = { value: V; icon: IconName; /** One word; the accessible name. */ label: string; disabled?: boolean }

export type IconSegmentedProps<V extends string> = {
  options: ReadonlyArray<IconSegmentedOption<V>>
  value?: V
  defaultValue?: V
  onChange?: (value: V) => void
  /** The group's accessible name (no visible label). */
  label: string
  /** `selected` (default): the chosen option shows its word. `all`: every option does. `none`: glyphs only. */
  labels?: 'selected' | 'all' | 'none'
  disabled?: boolean
  className?: string
}

export function IconSegmented<V extends string>({ options, value: valueProp, defaultValue, onChange, label, labels = 'selected', disabled, className }: IconSegmentedProps<V>) {
  const [value, setValue] = useControllable<V | undefined>(valueProp, defaultValue ?? options.find(o => !o.disabled)?.value, onChange as ((v: V | undefined) => void) | undefined)
  const ref = useRef<HTMLDivElement>(null)
  const active = Math.max(0, options.findIndex(o => o.value === value))
  const box = useThread(ref, active, '[role="radio"]', options.length)
  const flags = options.map(o => Boolean(o.disabled || disabled))

  const onKey = (e: KeyboardEvent<HTMLButtonElement>, i: number) => {
    const next = rovingIndex(e, i, flags)
    if (next === null) return
    e.preventDefault()
    const opt = options[next]
    if (!opt) return
    setValue(opt.value)
    ref.current?.querySelectorAll<HTMLElement>('[role="radio"]')[next]?.focus()
  }

  const style = { '--gz-in-x': `${box.x * box.dir}px`, '--gz-in-w': `${box.w}px` } as CSSProperties

  return (
    <div
      ref={ref}
      className={cx('gz-iseg', className)}
      data-gz="IconSegmented"
      data-ready={box.ready || undefined}
      role="radiogroup"
      aria-label={label}
      aria-disabled={disabled || undefined}
      style={style}
    >
      {box.w > 0 ? <span className="gz-iseg__thumb gz-thread-slide" aria-hidden="true" /> : null}
      {options.map((o, i) => {
        const selected = i === active && o.value === value
        const showLabel = labels === 'all' || (labels === 'selected' && selected)
        return (
          <button
            key={o.value}
            type="button"
            role="radio"
            aria-checked={selected}
            tabIndex={selected || (value === undefined && i === 0) ? 0 : -1}
            disabled={flags[i]}
            className="gz-in-btn gz-iseg__opt gz-t-button gz-press"
            data-selected={selected || undefined}
            onClick={() => setValue(o.value)}
            onKeyDown={e => onKey(e, i)}
          >
            <Icon name={o.icon} size="sm" />
            <span className={cx(showLabel ? 'gz-iseg__label' : 'gz-sr-only')}>{o.label}</span>
          </button>
        )
      })}
    </div>
  )
}
