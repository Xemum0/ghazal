// Icon: one glyph from the generated registry (packages/design-tokens/dist/icons.ts, Phosphor subset, ADR 0023).
// Sizes are the four size tokens (16 / 20 / 24 / 32). Directional glyphs mirror in Arabic through the shared mechanism
// (mirror.ts); everything else never does. Decorative by default (aria-hidden); pass `label` to make it an image.
import type { CSSProperties } from 'react'
import { icons, iconsLight, iconsRegular, type IconName } from '@gz/tokens'
import { cx } from './cx'
import { mirrorClass } from './mirror'
import './icon.css'

export type IconSize = 'xs' | 'sm' | 'md' | 'lg'
export type IconTone = 'inherit' | 'primary' | 'secondary' | 'accent' | 'success' | 'danger' | 'disabled' | 'on-dark'
export type IconWeight = 'default' | 'light' | 'regular'

export type IconProps = {
  name: IconName
  /** xs 16, sm 20, md 24 (default), lg 32. */
  size?: IconSize
  /** Colour role from the icon tokens. `inherit` (default) follows `currentColor`. */
  tone?: IconTone
  /** An accessible name. Without it the icon is decorative and hidden from assistive technology. */
  label?: string
  /** `auto` follows the registry (ADR 0014 D2); `true` / `false` override it for the rare composed glyph. */
  mirror?: boolean | 'auto'
  /** `default` is the product weight (registry setting); `light` and `regular` exist for the gallery comparison. */
  weight?: IconWeight
  className?: string
  style?: CSSProperties
}

const SETS = { default: icons, light: iconsLight, regular: iconsRegular } as const

export function Icon({ name, size = 'md', tone = 'inherit', label, mirror = 'auto', weight = 'default', className, style }: IconProps) {
  const glyph = SETS[weight][name]
  return (
    <svg
      data-gz="Icon"
      data-gz-icon={name}
      className={cx('gz-icon', `gz-icon--${size}`, tone !== 'inherit' && `gz-icon--${tone}`, mirrorClass(name, mirror), className)}
      style={style}
      viewBox={glyph.viewBox}
      fill="currentColor"
      focusable="false"
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      {glyph.paths.map((d, i) => (
        <path key={i} d={d} />
      ))}
    </svg>
  )
}
