import { useId, type MouseEvent, type ReactNode } from 'react'
import { Switch } from '../core/Switch'
import { useControllable } from './internal/useControllable'
import './internal/base.css'
import './togglerow.css'

export type ToggleProps = {
  checked?: boolean
  defaultChecked?: boolean
  onChange?: (checked: boolean) => void
  disabled?: boolean
  /** The accessible name (what the switch does). */
  label: string
  id?: string
  className?: string
}

/** The shared Switch (system/core: 52 x 32 track in a 44 high target, ink-700 on, canvas knob with an ink-900 check, never gold). */
export function Toggle(props: ToggleProps) {
  return <Switch id={props.id} checked={props.checked} defaultChecked={props.defaultChecked} onChange={props.onChange} disabled={props.disabled} label={props.label} className={props.className} />
}

export type ToggleRowProps = Omit<ToggleProps, 'label'> & {
  title: string
  description?: ReactNode
  /** Why the row is disabled; replaces the description. */
  disabledReason?: ReactNode
  /** 1 px ink-200 rule under the row (list rows). Default true. */
  divider?: boolean
}

/**
 * List row (64 min): title and description at the start, the switch at the end. The whole row is the target; the switch is the
 * one focusable control and carries the title as its accessible name (labelledby) and the description (describedby).
 */
export function ToggleRow(props: ToggleRowProps) {
  const uid = useId().replace(/:/g, '')
  const [on, setOn] = useControllable<boolean>(props.checked, props.defaultChecked ?? false, props.onChange)
  const sub = props.disabled && props.disabledReason ? props.disabledReason : props.description

  // A tap anywhere on the row toggles; the switch's own tap is already handled by the switch, so ignore it here.
  const onRow = (e: MouseEvent<HTMLDivElement>) => {
    if (props.disabled) return
    if ((e.target as HTMLElement).closest('[role="switch"]')) return
    setOn(!on)
  }

  return (
    <div
      className={['gz-toggle-row', props.className ?? ''].filter(Boolean).join(' ')}
      data-gz="ToggleRow"
      data-divider={props.divider === false ? undefined : ''}
      data-disabled={props.disabled || undefined}
      onClick={onRow}
    >
      <div className="gz-toggle-row__text">
        <span id={`${uid}-t`} className="gz-toggle-row__title gz-t-body">
          {props.title}
        </span>
        {sub ? (
          <span id={`${uid}-d`} className="gz-toggle-row__sub gz-t-caption">
            {sub}
          </span>
        ) : null}
      </div>
      <Switch
        id={props.id}
        checked={on}
        onChange={setOn}
        disabled={props.disabled}
        label={props.title}
        aria-labelledby={`${uid}-t`}
        aria-describedby={sub ? `${uid}-d` : undefined}
      />
    </div>
  )
}
