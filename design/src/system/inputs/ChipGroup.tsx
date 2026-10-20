import { useRef, type KeyboardEvent, type ReactNode } from 'react'
import { useControllable } from './internal/useControllable'
import { rovingIndex } from './internal/roving'
import '../core/core.css'
import '../core/chip.css'
import './chips.css'

export type ChipOption<V extends string | number> = {
  value: V
  label: ReactNode
  disabled?: boolean
}

type Common<V extends string | number> = {
  options: ReadonlyArray<ChipOption<V>>
  /** Accessible name of the group. */
  label: string
  /** `wrap`: chips flow onto several lines. `rail`: one horizontally scrolling line (gutter-bleed is the screen's job). */
  layout?: 'wrap' | 'rail'
  disabled?: boolean
  className?: string
}

export type ChipGroupProps<V extends string | number> = Common<V> &
  (
    | {
        selection?: 'single'
        value?: V | null
        defaultValue?: V | null
        onChange?: (value: V | null) => void
        /** Tapping the selected chip clears it. Default false: a choice stays a choice. */
        deselectable?: boolean
      }
    | {
        selection: 'multiple'
        value?: V[]
        defaultValue?: V[]
        onChange?: (value: V[]) => void
        deselectable?: never
      }
  )

/**
 * Chips, 44 high, radius 8, 1 px ink-300 border, body-s. Rendered with the shared Chip anatomy and CSS (system/core): selected = ink-900 border, an 8 px gold bead and weight 500
 * (the label reserves its 500 width so neighbours never jump). Single selection is a radio group with roving tabindex;
 * multiple selection is a group of toggle buttons (aria-pressed). Gold is the bead only, never a fill.
 */
export function ChipGroup<V extends string | number>(props: ChipGroupProps<V>) {
  const { options, label, layout = 'wrap', disabled } = props
  const multiple = props.selection === 'multiple'
  const [raw, setRaw] = useControllable<unknown>(
    props.value as unknown,
    (props.defaultValue as unknown) ?? (multiple ? [] : null),
    props.onChange as ((v: unknown) => void) | undefined,
  )
  const ref = useRef<HTMLDivElement>(null)
  const selectedSet = new Set<V>(multiple ? ((raw as V[]) ?? []) : raw === null || raw === undefined ? [] : [raw as V])
  const flags = options.map(o => Boolean(o.disabled || disabled))
  const firstSelected = options.findIndex(o => selectedSet.has(o.value) && !flags[options.indexOf(o)])
  const tabStop = firstSelected >= 0 ? firstSelected : flags.findIndex(f => !f)

  const toggle = (v: V) => {
    if (multiple) {
      const cur = (raw as V[]) ?? []
      setRaw(cur.includes(v) ? cur.filter(x => x !== v) : [...cur, v])
    } else if (selectedSet.has(v)) {
      if (props.deselectable) setRaw(null)
    } else setRaw(v)
  }

  const onKey = (e: KeyboardEvent<HTMLButtonElement>, i: number) => {
    const next = rovingIndex(e, i, flags)
    if (next === null) return
    e.preventDefault()
    const el = ref.current?.querySelectorAll<HTMLElement>('.gz-chip')[next]
    el?.focus()
    if (!multiple && options[next]) setRaw(options[next]!.value)
  }

  return (
    <div
      ref={ref}
      className={['gz-chips', props.className ?? ''].filter(Boolean).join(' ')}
      data-gz="ChipGroup"
      data-layout={layout}
      role={multiple ? 'group' : 'radiogroup'}
      aria-label={label}
    >
      {options.map((o, i) => {
        const selected = selectedSet.has(o.value)
        return (
          <button
            key={String(o.value)}
            type="button"
            role={multiple ? undefined : 'radio'}
            aria-checked={multiple ? undefined : selected}
            aria-pressed={multiple ? selected : undefined}
            tabIndex={multiple || i === tabStop ? 0 : -1}
            disabled={flags[i]}
            data-gz="Chip"
            className={`gz-reset gz-chip gz-t-body-s gz-select gz-chip--interactive gz-press${selected ? ' is-selected' : ''}`}
            onClick={() => toggle(o.value)}
            onKeyDown={e => onKey(e, i)}
          >
            {selected ? (
              <span className="gz-chip__bead" aria-hidden="true">
                <span className="gz-bead" />
              </span>
            ) : null}
            <span className="gz-chip__label">
              <span>{o.label}</span>
              <span className="gz-chip__ghost" aria-hidden="true">
                {o.label}
              </span>
            </span>
          </button>
        )
      })}
    </div>
  )
}
