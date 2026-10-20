// Button (direction section 3): primary gold fill 52, secondary hairline 48, tertiary gold-700 text with underline 44,
// destructive danger on its tint 48. One primary per screen. Press = tone step + scale .985 (tertiary: the underline shortens).
// Loading keeps the label, takes the pressed tone and draws the thread once along the bottom edge (480 ms, nothing loops).
import { useId, type ButtonHTMLAttributes, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { cx } from './cx'
import { Icon } from './Icon'
import './core.css'
import './button.css'

export type ButtonVariant = 'primary' | 'secondary' | 'tertiary' | 'destructive'
/** 44 / 48 / 52 / 56: the control-height scale (size.control.sm / md / cta / lg). */
export type ButtonSize = 'sm' | 'md' | 'cta' | 'lg'

/** The height each variant has unless a size is named: primary 52, secondary 48, tertiary 44, destructive 48. */
export const defaultButtonSize: Record<ButtonVariant, ButtonSize> = { primary: 'cta', secondary: 'md', tertiary: 'sm', destructive: 'md' }

export type ButtonProps = Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'className' | 'children'> & {
  variant?: ButtonVariant
  size?: ButtonSize
  iconStart?: IconName
  iconEnd?: IconName
  /** Action accepted and in flight: pressed tone, no further taps, the thread draws once. */
  loading?: boolean
  /** Fill the width of the parent (the CTA bar, a sheet footer). Pairs share the width with `flex: 1` in their row instead. */
  fullWidth?: boolean
  /** A disabled button states why, as a caption under it (direction section 3). */
  reason?: string
  /** Tertiary on an ink surface: the label and its rule are canvas instead of gold-700. */
  onDark?: boolean
  /** Gallery only: show :active or :focus-visible without a pointer or keyboard. */
  previewState?: 'pressed' | 'focus'
  className?: string
  children: ReactNode
}

export function Button({
  variant = 'primary',
  size,
  iconStart,
  iconEnd,
  loading = false,
  fullWidth = false,
  reason,
  onDark = false,
  previewState,
  className,
  children,
  disabled,
  onClick,
  type = 'button',
  ...rest
}: ButtonProps) {
  const reasonId = useId()
  const height = size ?? defaultButtonSize[variant]
  const showReason = Boolean(disabled && reason)
  const button = (
    <button
      {...rest}
      type={type}
      data-gz="Button"
      data-variant={variant}
      data-size={height}
      disabled={disabled}
      aria-busy={loading || undefined}
      aria-disabled={loading || undefined}
      aria-describedby={showReason ? reasonId : rest['aria-describedby']}
      onClick={loading ? undefined : onClick}
      className={cx(
        'gz-reset gz-t-button gz-btn',
        `gz-btn--${variant}`,
        `gz-btn--${height}`,
        variant !== 'tertiary' && 'gz-press',
        onDark && 'gz-btn--on-dark',
        fullWidth && !showReason && 'gz-btn--block',
        loading && 'is-loading',
        previewState === 'pressed' && 'is-pressed',
        previewState === 'focus' && 'is-focus',
        className,
      )}
    >
      {iconStart ? <Icon name={iconStart} size="sm" /> : null}
      <span className="gz-btn__label">
        {children}
        {variant === 'tertiary' ? <span className="gz-btn__underline gz-underline-press" aria-hidden="true" /> : null}
      </span>
      {iconEnd ? <Icon name={iconEnd} size="sm" /> : null}
      {loading ? (
        <span className="gz-btn__thread" aria-hidden="true">
          <span className="gz-btn__thread-fill gz-thread-draw" />
        </span>
      ) : null}
    </button>
  )
  if (!showReason) return button
  return (
    <div className={cx('gz-btn-wrap', fullWidth && 'gz-btn-wrap--block')} data-gz="ButtonWithReason">
      {button}
      <p id={reasonId} className="gz-t-caption gz-btn__reason">
        {reason}
      </p>
    </div>
  )
}
