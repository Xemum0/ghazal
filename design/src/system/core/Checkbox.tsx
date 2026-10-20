// Checkbox: a 24 box (radius 4) in a row that is at least 44 high and whole-row tappable. Checked = ink-700 fill with a canvas
// check (the same ink as the Switch: choice is ink, never gold). Indeterminate shows a minus. Error = danger border + icon + text.
import { useId, type ButtonHTMLAttributes, type ReactNode } from 'react'
import { cx } from './cx'
import { Icon } from './Icon'
import { useControllable } from './useControllable'
import './core.css'
import './checkbox.css'

export type CheckboxProps = Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'className' | 'children' | 'onChange' | 'defaultChecked'> & {
  /** The visible label. */
  children: ReactNode
  checked?: boolean
  defaultChecked?: boolean
  indeterminate?: boolean
  onChange?: (checked: boolean) => void
  /** Validation message: shown under the row with an icon, and the box turns danger. */
  error?: string
  previewState?: 'pressed' | 'focus'
  className?: string
}

export function Checkbox({ children, checked, defaultChecked = false, indeterminate = false, onChange, error, disabled, previewState, className, type = 'button', ...rest }: CheckboxProps) {
  const [on, setOn] = useControllable(checked, defaultChecked, onChange)
  const errorId = useId()
  const row = (
    <button
      {...rest}
      type={type}
      role="checkbox"
      data-gz="Checkbox"
      aria-checked={indeterminate ? 'mixed' : on}
      aria-invalid={error ? true : undefined}
      aria-describedby={error ? errorId : rest['aria-describedby']}
      disabled={disabled}
      onClick={() => setOn(indeterminate ? true : !on)}
      className={cx('gz-reset gz-check', (on || indeterminate) && 'is-on', error && 'is-error', previewState === 'pressed' && 'is-pressed', previewState === 'focus' && 'is-focus', className)}
    >
      <span className="gz-check__box">{indeterminate ? <Icon name="minus" size="xs" /> : on ? <Icon name="check" size="xs" /> : null}</span>
      <span className="gz-check__label gz-t-body-s">{children}</span>
    </button>
  )
  if (!error) return row
  return (
    <div className="gz-check-wrap" data-gz="CheckboxField">
      {row}
      <p id={errorId} className="gz-check__error gz-t-caption" role="alert">
        <Icon name="warning-circle" size="xs" tone="danger" />
        <span>{error}</span>
      </p>
    </div>
  )
}
