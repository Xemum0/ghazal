// Switch (direction section 3, "Toggle"): 52 x 32 track inside a 44 high target. Off = paper with an ink-500 ring; on = ink-700
// with the canvas knob and an ink-900 check. Never gold. On = knob toward inline-end, so it mirrors with the language (ADR 0014).
import type { ButtonHTMLAttributes } from 'react'
import { cx } from './cx'
import { Icon } from './Icon'
import { useControllable } from './useControllable'
import './core.css'
import './switch.css'

export type SwitchProps = Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'className' | 'children' | 'onChange' | 'aria-label' | 'defaultChecked'> & {
  checked?: boolean
  defaultChecked?: boolean
  onChange?: (checked: boolean) => void
  /** The accessible name (the row's visible title, or what the switch does). */
  label: string
  previewState?: 'pressed' | 'focus'
  className?: string
}

export function Switch({ checked, defaultChecked = false, onChange, label, disabled, previewState, className, type = 'button', ...rest }: SwitchProps) {
  const [on, setOn] = useControllable(checked, defaultChecked, onChange)
  return (
    <button
      {...rest}
      type={type}
      role="switch"
      data-gz="Switch"
      aria-checked={on}
      aria-label={label}
      disabled={disabled}
      onClick={() => setOn(!on)}
      className={cx('gz-reset gz-switch', on && 'is-on', previewState === 'pressed' && 'is-pressed', previewState === 'focus' && 'is-focus', className)}
    >
      <span className="gz-switch__track">
        <span className="gz-switch__knob">{on ? <Icon name="check" size="xs" /> : null}</span>
      </span>
    </button>
  )
}
