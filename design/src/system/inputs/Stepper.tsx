import { useEffect, useId, useRef, type KeyboardEvent, type PointerEvent, type ReactNode } from 'react'
import { useFormat } from '../../i18n'
import { useControllable } from './internal/useControllable'
import { Glyph } from './internal/Glyph'
import { useInputWords } from './internal/copy'
import './internal/base.css'
import './stepper.css'

// Press-and-hold repeat: a short pause so a tap is one step, then a steady repeat. Interaction timing, not animation.
const HOLD_DELAY_MS = 400
const HOLD_REPEAT_MS = 90

export type StepperProps = {
  value?: number
  defaultValue?: number
  onChange?: (value: number) => void
  min?: number
  max?: number
  /** The step (a package's `guest_step`, ADR 0002 D7). Default 1. */
  step?: number
  /** Row title at the start (`Guests in this hall`). Without it the stepper is just the controls. */
  label?: ReactNode
  /** Caption under the title or value (`guests`, a rule such as `Minimum 200`). */
  caption?: ReactNode
  /** Custom value text (default: the integer, formatted, Cairo figures). */
  renderValue?: (value: number) => ReactNode
  /** Plain-text spoken value (`350 guests`). */
  valueText?: (value: number) => string
  disabled?: boolean
  id?: string
  className?: string
}

/**
 * Counter / stepper (guests, rooms). A row: title and caption at the start, then `[ - ] 350 [ + ]` at the end, buttons 44 x 44
 * (radius 8, ink-500 hairline), the value in the figures voice (Cairo 600, tabular, an LTR island). Buttons disable at the
 * limits. Press and hold repeats; ArrowUp / ArrowDown, PageUp / PageDown (x10), Home / End work from a focused button. The
 * minus button sits at the inline-start in LTR and at the start (right) in Arabic, like the rest of the row.
 */
export function Stepper(props: StepperProps) {
  const f = useFormat()
  const w = useInputWords()
  const { min = 0, max = Number.MAX_SAFE_INTEGER, step = 1, label, caption, disabled } = props
  const clamp = (n: number) => Math.min(max, Math.max(min, n))
  const [value, setValue, latest] = useControllable<number>(props.value, clamp(props.defaultValue ?? min), props.onChange)
  const uid = useId().replace(/:/g, '')
  const timer = useRef<number | null>(null)

  const bump = (dir: 1 | -1, times = 1) => {
    const next = clamp(latest.current + dir * step * times)
    if (next !== latest.current) setValue(next)
  }

  const stop = () => {
    if (timer.current !== null) {
      window.clearTimeout(timer.current)
      window.clearInterval(timer.current)
      timer.current = null
    }
  }
  useEffect(() => stop, [])

  const hold = (dir: 1 | -1) => (e: PointerEvent<HTMLButtonElement>) => {
    if (disabled || e.button !== 0) return
    stop()
    bump(dir)
    timer.current = window.setTimeout(() => {
      timer.current = window.setInterval(() => bump(dir), HOLD_REPEAT_MS)
    }, HOLD_DELAY_MS)
  }

  const onKey = (e: KeyboardEvent) => {
    const map: Record<string, () => void> = {
      ArrowUp: () => bump(1),
      ArrowDown: () => bump(-1),
      PageUp: () => bump(1, 10),
      PageDown: () => bump(-1, 10),
      Home: () => setValue(min),
      End: () => max !== Number.MAX_SAFE_INTEGER && setValue(max),
    }
    const run = map[e.key]
    if (run) {
      e.preventDefault()
      run()
    }
  }

  const atMin = value <= min
  const atMax = value >= max
  const spoken = props.valueText?.(value) ?? f.integer(value)

  return (
    <div className={['gz-stepper', props.className ?? ''].filter(Boolean).join(' ')} data-gz="Stepper" data-disabled={disabled || undefined} onKeyDown={onKey} role="group" aria-labelledby={label ? `${uid}-l` : undefined}>
      {label || caption ? (
        <div className="gz-stepper__text">
          {label ? (
            <span id={`${uid}-l`} className="gz-stepper__label gz-t-body">
              {label}
            </span>
          ) : null}
          {caption ? <span className="gz-stepper__caption gz-t-caption">{caption}</span> : null}
        </div>
      ) : null}
      <div className="gz-stepper__ctrl">
        <button
          type="button"
          className="gz-in-btn gz-stepper__btn gz-press"
          aria-label={w('decrease')}
          aria-controls={`${uid}-v`}
          disabled={disabled || atMin}
          onPointerDown={hold(-1)}
          onPointerUp={stop}
          onPointerLeave={stop}
          onPointerCancel={stop}
          onClick={e => e.detail === 0 && bump(-1)} // keyboard activation; pointer presses are handled on pointerdown
        >
          <Glyph name="minus" size="sm" />
        </button>
        <output id={`${uid}-v`} className="gz-stepper__value gz-t-fig-title" aria-live="polite" aria-label={spoken}>
          {props.renderValue ? props.renderValue(value) : <bdi dir="ltr">{f.integer(value)}</bdi>}
        </output>
        <button
          type="button"
          className="gz-in-btn gz-stepper__btn gz-press"
          aria-label={w('increase')}
          aria-controls={`${uid}-v`}
          disabled={disabled || atMax}
          onPointerDown={hold(1)}
          onPointerUp={stop}
          onPointerLeave={stop}
          onPointerCancel={stop}
          onClick={e => e.detail === 0 && bump(1)}
        >
          <Glyph name="plus" size="sm" />
        </button>
      </div>
    </div>
  )
}
