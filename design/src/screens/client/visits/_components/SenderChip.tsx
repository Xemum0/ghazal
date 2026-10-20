// SenderChip (CL-VIST-03): who wrote the first bubble of a run, as the role chip alone, in one word (Hotel, Support). The chat has exactly three
// roles and each has its own surface (ink tint for the hotel, rose tint for support: the same tones as the member discs in the pinned card),
// so a first name next to a two-word role would only repeat what the discs and the member sheet already say (ADR 0034). The name and the
// full role are the accessible name. Flow-local twin of `RoleBadge` with a `short` form (filed in docs/engineering/requests.md); delete this
// file when the system badge has it. A word, never a glyph that could pass for a face (ADR 0015).
import type { ThreadRole } from '@gz/contracts'
import { useV } from './model'
import './sender-chip.css'

export function SenderChip({ role, name }: { role: Exclude<ThreadRole, 'client'>; name: string }) {
  const { t, tc } = useV()
  const short = role === 'hotel_representative' ? t('clientVisitsRoleHotel') : t('clientVisitsRoleSupport')
  const full = role === 'hotel_representative' ? tc('commonRoleHotelRep') : tc('commonRoleSupport')
  return (
    <span className="gzvt-sc" data-gz="SenderChip" data-role={role}>
      <span className="gz-sr-only">{`${name}, ${full}`}</span>
      <span className="gzvt-sc__chip gz-t-pill" aria-hidden="true">
        {short}
      </span>
    </span>
  )
}
