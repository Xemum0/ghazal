// StatusIcon (ADR 0034): a status as a glyph in a tone disk, with the word as its accessible name. Use it inside a row that already
// names what it is about (a calendar day, a list row, a card corner); with `showLabel` it IS the StatusPill (icon + one word).
// Colour reinforces and never carries the status alone: the glyph and the (hidden or shown) word always do.
import { useT } from '../../i18n'
import { cx } from './cx'
import { Icon, type IconTone } from './Icon'
import { StatusPill, statusMeta, type StatusAudience, type StatusKey } from './StatusPill'
import './status-icon.css'

export type StatusIconProps = {
  status: StatusKey
  audience?: StatusAudience
  /** `sm` = 24 disk, glyph 16; `md` = 32 disk, glyph 20. */
  size?: 'sm' | 'md'
  /** Shows the one word beside the glyph (renders the StatusPill). */
  showLabel?: boolean
  /** Replaces the shared word (composed string). */
  label?: string
  className?: string
}

const TONE: Record<string, IconTone> = {
  pending: 'accent',
  'pending-outline': 'accent',
  success: 'success',
  danger: 'danger',
  'danger-outline': 'danger',
  neutral: 'secondary',
  'neutral-outline': 'secondary',
  rose: 'primary',
}

export function StatusIcon({ status, audience = 'client', size = 'sm', showLabel = false, label, className }: StatusIconProps) {
  const t = useT('common')
  if (showLabel) return <StatusPill status={status} audience={audience} label={label} className={className} />
  const meta = statusMeta[status]
  const key = audience === 'hotel' && meta.hotel ? meta.hotel : meta.client
  return (
    <span
      data-gz="StatusIcon"
      data-status={status}
      data-tone={meta.tone}
      role="img"
      aria-label={label ?? t(key)}
      className={cx('gz-sicon', `gz-sicon--${size}`, `gz-sicon--${meta.tone}`, className)}
    >
      <Icon name={meta.icon} size={size === 'md' ? 'sm' : 'xs'} tone={TONE[meta.tone] ?? 'inherit'} />
    </span>
  )
}
