// Radio and RadioGroup: a 24 ring in a 44 row; chosen = ink-700 ring with a 12 dot. The chosen radio is the group's tab stop,
// arrow keys move the choice and follow reading direction (ADR 0014: next is toward inline-end).
import { createContext, useContext, useRef, type KeyboardEvent, type ReactNode } from 'react'
import { useLang } from '../../shell/lang'
import { cx } from './cx'
import { useControllable } from './useControllable'
import './core.css'
import './radio.css'

type Ctx = { value: string | undefined; select: (v: string) => void }
const RadioCtx = createContext<Ctx | null>(null)

export type RadioGroupProps = {
  /** Accessible name of the group (the question the choice answers). */
  label: string
  value?: string
  defaultValue?: string
  onChange?: (value: string) => void
  children: ReactNode
  className?: string
}

export function RadioGroup({ label, value, defaultValue, onChange, children, className }: RadioGroupProps) {
  const { isRtl } = useLang()
  const ref = useRef<HTMLDivElement>(null)
  const [current, setCurrent] = useControllable<string | undefined>(value, defaultValue, onChange as ((v: string | undefined) => void) | undefined)

  const onKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    const next = e.key === 'ArrowDown' || e.key === (isRtl ? 'ArrowLeft' : 'ArrowRight')
    const prev = e.key === 'ArrowUp' || e.key === (isRtl ? 'ArrowRight' : 'ArrowLeft')
    if (!next && !prev) return
    const radios = Array.from(ref.current?.querySelectorAll<HTMLButtonElement>('[role="radio"]:not(:disabled)') ?? [])
    if (!radios.length) return
    e.preventDefault()
    const at = radios.findIndex(r => r === document.activeElement)
    const target = radios[(at + (next ? 1 : -1) + radios.length) % radios.length]
    target?.focus()
    target?.click()
  }

  return (
    <RadioCtx.Provider value={{ value: current, select: v => setCurrent(v) }}>
      <div ref={ref} role="radiogroup" aria-label={label} data-gz="RadioGroup" className={cx('gz-radiogroup', className)} onKeyDown={onKeyDown}>
        {children}
      </div>
    </RadioCtx.Provider>
  )
}

export type RadioProps = {
  value: string
  children: ReactNode
  disabled?: boolean
  /** Standalone use without a group (gallery state specimens). */
  checked?: boolean
  previewState?: 'pressed' | 'focus'
  className?: string
}

export function Radio({ value, children, disabled, checked, previewState, className }: RadioProps) {
  const ctx = useContext(RadioCtx)
  const on = checked ?? ctx?.value === value
  // Roving tab stop: the chosen radio; until something is chosen every radio can take focus.
  const tabStop = on || ctx?.value === undefined
  return (
    <button
      type="button"
      role="radio"
      data-gz="Radio"
      aria-checked={on}
      tabIndex={tabStop ? 0 : -1}
      disabled={disabled}
      onClick={() => ctx?.select(value)}
      className={cx('gz-reset gz-radio', on && 'is-on', previewState === 'pressed' && 'is-pressed', previewState === 'focus' && 'is-focus', className)}
    >
      <span className="gz-radio__ring">
        <span className="gz-radio__dot" />
      </span>
      <span className="gz-radio__label gz-t-body-s">{children}</span>
    </button>
  )
}
