// Badge and CountBadge (direction section 3, 2.3).
// Badge: a short objective label (Best rated, Lowest price, New, Sponsored). outline = hairline pill with the gold bead
// (compare columns), photo = canvas chip for a venue card image (one per card), quiet = ink-50.
// CountBadge: the gold count (20 minimum, full radius, ink-900 Cairo 12). Danger is for SLA danger only (ADR 0008 D2).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat } from '../../i18n'
import { cx } from './cx'
import { Icon } from './Icon'
import './badge.css'

export type BadgeVariant = 'outline' | 'photo' | 'quiet'

export type BadgeProps = {
  children: ReactNode
  variant?: BadgeVariant
  /** The 8 px gold bead before the label. Default on for `outline`. */
  bead?: boolean
  icon?: IconName
  className?: string
}

export function Badge({ children, variant = 'outline', bead, icon, className }: BadgeProps) {
  const showBead = bead ?? variant === 'outline'
  return (
    <span data-gz="Badge" data-variant={variant} className={cx('gz-badge gz-t-pill', `gz-badge--${variant}`, className)}>
      {showBead ? (
        <span className="gz-badge__bead" aria-hidden="true">
          <span className="gz-bead" />
        </span>
      ) : null}
      {icon ? <Icon name={icon} size="xs" /> : null}
      <span className="gz-badge__label">{children}</span>
    </span>
  )
}

export type CountBadgeProps = {
  count: number
  /** Above this the badge reads `99+`. */
  max?: number
  tone?: 'gold' | 'danger'
  /** A 2 px canvas ring so the badge separates from a tab icon or an avatar it overlaps. */
  ring?: boolean
  /** Accessible name when the number alone is not enough ("3 new requests"). */
  label?: string
  className?: string
}

export function CountBadge({ count, max = 99, tone = 'gold', ring = false, label, className }: CountBadgeProps) {
  const f = useFormat()
  const text = count > max ? `${f.integer(max)}+` : f.integer(count)
  return (
    <span
      data-gz="CountBadge"
      data-tone={tone}
      className={cx('gz-count gz-t-badge', `gz-count--${tone}`, ring && 'gz-count--ring', className)}
      role={label ? 'img' : undefined}
      aria-label={label}
    >
      <bdi dir="ltr">{text}</bdi>
    </span>
  )
}
