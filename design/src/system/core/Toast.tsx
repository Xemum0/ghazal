// Toast and UndoBar (direction section 3): ink-900 bar, canvas text, radius 8, elev-2, the action in gold-400 with a 44 hit area.
// The UndoBar adds the 2 px gold line that depletes over 8 s (linear; a determinate timer, so it runs under reduced motion
// too) and reports the end with onExpire. Both sit 16 above the bar they float over: wrap them in ToastRegion.
import type { ReactNode } from 'react'
import { flat, type IconName } from '@gz/tokens'
import { useT } from '../../i18n'
import { cx } from './cx'
import { Icon } from './Icon'
import './core.css'
import './toast.css'

export type ToastProps = {
  message: ReactNode
  icon?: IconName
  /** Action label (gold-400, 44 hit). Omit for a message-only toast. */
  actionLabel?: string
  onAction?: () => void
  previewState?: 'pressed' | 'focus'
  className?: string
}

export function Toast({ message, icon, actionLabel, onAction, previewState, className }: ToastProps) {
  return (
    <div data-gz="Toast" role="status" aria-live="polite" className={cx('gz-on-dark gz-toast', icon && 'gz-toast--icon', className)}>
      {icon ? <Icon name={icon} size="sm" /> : null}
      <p className="gz-toast__message gz-t-body-s">{message}</p>
      {actionLabel ? (
        <button
          type="button"
          onClick={onAction}
          className={cx('gz-reset gz-t-button gz-toast__action gz-press', previewState === 'pressed' && 'is-pressed', previewState === 'focus' && 'is-focus')}
        >
          {actionLabel}
        </button>
      ) : null}
    </div>
  )
}

export type UndoBarProps = {
  message: ReactNode
  /** Called when the undo action is tapped within the 8 seconds. */
  onUndo?: () => void
  /** Called when the line has fully depleted: the change is final. */
  onExpire?: () => void
  /** Replay key: change it to restart the line (the gallery's replay). */
  runKey?: string | number
  previewState?: 'pressed' | 'focus'
  className?: string
}

export function UndoBar({ message, onUndo, onExpire, runKey, previewState, className }: UndoBarProps) {
  const t = useT('common')
  return (
    <div data-gz="UndoBar" role="status" aria-live="polite" className={cx('gz-on-dark gz-toast gz-toast--undo', className)}>
      <p className="gz-toast__message gz-t-body-s">{message}</p>
      <button
        type="button"
        onClick={onUndo}
        className={cx('gz-reset gz-t-button gz-toast__action gz-press', previewState === 'pressed' && 'is-pressed', previewState === 'focus' && 'is-focus')}
      >
        {t('commonActionUndo')}
      </button>
      <span className="gz-toast__timer" aria-hidden="true">
        <span key={runKey} className="gz-toast__timer-fill gz-undo-line" onAnimationEnd={onExpire} />
      </span>
    </div>
  )
}

export type ToastRegionProps = {
  children: ReactNode
  /** Height in px of the bar the toast floats over (tab bar 56 + safe 34, CTA bar 12 + 52 + 12 + 34); 16 is added above it. */
  barHeight?: number
}

/** Pins its children to the bottom of the nearest positioned ancestor, 16 above the bar, inside the gutters. */
export function ToastRegion({ children, barHeight = 0 }: ToastRegionProps) {
  return (
    <div className="gz-toast-region" style={{ insetBlockEnd: barHeight + flat['space.4'] }}>
      {children}
    </div>
  )
}
