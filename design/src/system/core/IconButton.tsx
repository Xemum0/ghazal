// IconButton: a 44 x 44 target around one glyph (WCAG 2.2, direction section 2.5). The visible disk may be smaller than the target.
// Variants: plain (ink glyph), outline (hairline disk), over-image (canvas disk with the fab ring, for photography) and
// on-scrim (bare canvas glyph over a top scrim, status-bar style). `active` makes it a toggle (heart, compare) and plays
// the favourite pop once when it turns on. A label is mandatory: an icon alone is not a name.
import { useEffect, useRef, useState, type ButtonHTMLAttributes } from 'react'
import type { IconName } from '@gz/tokens'
import { cx } from './cx'
import { Icon, type IconSize } from './Icon'
import './core.css'
import './icon-button.css'

export type IconButtonVariant = 'plain' | 'outline' | 'over-image' | 'on-scrim'
/** `sm` = 32 disk in the 44 target (venue card controls); `lg` = 44 disk (hero and gallery chrome). */
export type IconButtonDisk = 'sm' | 'lg'

export type IconButtonProps = Omit<ButtonHTMLAttributes<HTMLButtonElement>, 'className' | 'children' | 'aria-label'> & {
  icon: IconName
  /** Glyph shown while `active` (heart-fill for heart). Defaults to `icon`. */
  iconActive?: IconName
  /** The accessible name (required). Pass the state-aware string: "Save to favourites" / "Remove from favourites". */
  label: string
  variant?: IconButtonVariant
  disk?: IconButtonDisk
  iconSize?: IconSize
  /** Toggle state (aria-pressed). Leave undefined for a plain action button. */
  active?: boolean
  previewState?: 'pressed' | 'focus'
  className?: string
}

export function IconButton({
  icon,
  iconActive,
  label,
  variant = 'plain',
  disk,
  iconSize = 'md',
  active,
  previewState,
  className,
  type = 'button',
  ...rest
}: IconButtonProps) {
  const isToggle = active !== undefined
  const [popping, setPopping] = useState(false)
  const was = useRef(active)
  useEffect(() => {
    if (isToggle && active && !was.current) setPopping(true)
    was.current = active
  }, [active, isToggle])

  const diskSize = disk ?? (variant === 'over-image' ? 'sm' : 'lg')
  return (
    <button
      {...rest}
      type={type}
      data-gz="IconButton"
      data-variant={variant}
      aria-label={label}
      aria-pressed={isToggle ? active : undefined}
      className={cx(
        'gz-reset gz-iconbtn gz-press',
        `gz-iconbtn--${variant}`,
        `gz-iconbtn--disk-${diskSize}`,
        isToggle && active && 'is-active',
        isToggle && active && !iconActive && 'is-ink',
        previewState === 'pressed' && 'is-pressed',
        previewState === 'focus' && 'is-focus',
        className,
      )}
    >
      <span className="gz-iconbtn__disk" onAnimationEnd={() => setPopping(false)}>
        <Icon
          name={isToggle && active ? (iconActive ?? icon) : icon}
          size={iconSize}
          className={popping ? 'gz-favorite-pop' : undefined}
        />
      </span>
    </button>
  )
}
