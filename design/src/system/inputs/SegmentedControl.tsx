import { useRef, type CSSProperties, type KeyboardEvent, type ReactNode } from 'react'
import { useControllable } from './internal/useControllable'
import { rovingIndex } from './internal/roving'
import { useThread } from './internal/useThread'
import './internal/base.css'
import './segmented.css'

export type SegmentedOption<V extends string> = { value: V; label: ReactNode; disabled?: boolean }

export type SegmentedControlProps<V extends string> = {
  options: ReadonlyArray<SegmentedOption<V>>
  value?: V
  defaultValue?: V
  onChange?: (value: V) => void
  /** The group's accessible name (required: there is no visible label). */
  label: string
  /** `hall`: option labels in the display face (hall names only, direction 3). Default `ui`. */
  face?: 'ui' | 'hall'
  disabled?: boolean
  className?: string
}

/**
 * Segmented control: ink-100 track (radius 12, 4 pad), 44 high options, the selected option is an ink-700 pill (radius 8,
 * canvas label) with a 2 px gold thread that slides to the active option over 320 ms. The slide is measured from the START
 * edge and signed by the direction, so Arabic mirrors without a second code path. Radio-group semantics, roving tabindex,
 * arrows follow what you see. Used for hall, session and Availability | Prices.
 */
export function SegmentedControl<V extends string>(props: SegmentedControlProps<V>) {
  const { options, label, face = 'ui', disabled } = props
  const [value, setValue] = useControllable<V | undefined>(props.value, props.defaultValue ?? options.find(o => !o.disabled)?.value, props.onChange as ((v: V | undefined) => void) | undefined)
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
      className={['gz-seg', props.className ?? ''].filter(Boolean).join(' ')}
      data-gz="SegmentedControl"
      data-ready={box.ready || undefined}
      data-face={face}
      role="radiogroup"
      aria-label={label}
      aria-disabled={disabled || undefined}
      style={style}
    >
      {box.w > 0 ? <span className="gz-seg__thumb gz-thread-slide" aria-hidden="true" /> : null}
      {options.map((o, i) => {
        const selected = i === active && o.value === value
        return (
          <button
            key={o.value}
            type="button"
            role="radio"
            aria-checked={selected}
            tabIndex={selected || (value === undefined && i === 0) ? 0 : -1}
            disabled={flags[i]}
            className={`gz-in-btn gz-seg__opt gz-press ${face === 'hall' ? 'gz-t-d1' : 'gz-t-button'}`}
            data-selected={selected || undefined}
            onClick={() => setValue(o.value)}
            onKeyDown={e => onKey(e, i)}
          >
            <span className="gz-seg__label">{o.label}</span>
          </button>
        )
      })}
    </div>
  )
}
