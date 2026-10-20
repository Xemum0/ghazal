// Illustration: one drawing of the system set (ADR 0034). Decorative by default (hidden from assistive technology); pass `label`
// only when the drawing is the sole carrier of meaning. Sizes are the four illustration tokens (64 / 96 / 144 / 200). A drawing
// with reading-direction meaning mirrors in Arabic through the shared `gz-mirror` class (ADR 0014); `mirror` overrides the registry.
import type { CSSProperties } from 'react'
import { cx } from '../core/cx'
import { illustrationEntry, type IllustrationName } from './registry'
import './illustration.css'

export type IllustrationSize = 'sm' | 'md' | 'lg' | 'hero'
export type IllustrationTone = 'default' | 'quiet' | 'danger' | 'success' | 'on-dark'

export type IllustrationProps = {
  name: IllustrationName
  /** sm 64, md 96, lg 144 (default), hero 200. */
  size?: IllustrationSize
  /** Rebinds the colour roles; the drawing never changes. */
  tone?: IllustrationTone
  /** An accessible name. Without it the drawing is decorative. */
  label?: string
  /** `auto` follows the registry; `true` / `false` override. */
  mirror?: boolean | 'auto'
  className?: string
  style?: CSSProperties
}

export function Illustration({ name, size = 'lg', tone = 'default', label, mirror = 'auto', className, style }: IllustrationProps) {
  const { Draw, mirror: registered } = illustrationEntry(name)
  const flip = mirror === 'auto' ? registered : mirror
  return (
    <svg
      data-gz="Illustration"
      data-gz-illustration={name}
      className={cx('gz-illus', `gz-illus--${size}`, tone !== 'default' && `gz-illus--${tone}`, flip && 'gz-mirror', className)}
      style={style}
      viewBox="0 0 120 120"
      focusable="false"
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <Draw />
    </svg>
  )
}
