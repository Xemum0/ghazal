// RoleBadge: the text chip that names who a person is in a visit group chat (CL-VIST-03, HL-VIST-03): Client, Hotel representative,
// Ghazal support. Text only, no glyph that could pass for a face (ADR 0015); the role is also in the accessible name. Three quiet tones
// so the roles are told apart by wording AND by surface: client = hairline, hotel representative = ink tint, support = rose tint.
// `you` swaps the client chip to "You" on the client's own phone.
import type { ThreadRole } from '@gz/contracts'
import { useT } from '../../i18n'
import { cx } from '../core/cx'
import './role-badge.css'

export type RoleBadgeProps = {
  role: ThreadRole
  /** The viewer is this person: the chip reads "You". */
  you?: boolean
  className?: string
}

export function RoleBadge({ role, you = false, className }: RoleBadgeProps) {
  const t = useT('common')
  const label = you ? t('commonRoleYou') : role === 'client' ? t('commonRoleClient') : role === 'hotel_representative' ? t('commonRoleHotelRep') : t('commonRoleSupport')
  return (
    <span data-gz="RoleBadge" data-role={role} className={cx('gz-role gz-t-pill', `gz-role--${role}`, className)}>
      {label}
    </span>
  )
}
