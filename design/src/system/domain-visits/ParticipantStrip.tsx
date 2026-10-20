// ParticipantStrip (CL-VIST-03, HL-VIST-03 header): the three members of a visit group chat, side by side, each a monogram, a name and a
// role badge. Exactly three roles, in a fixed order: Client, Hotel representative, Ghazal support. Names are shown as typed in the
// viewer's script (Arabic name in Arabic, Latin in English). The whole strip is one target that opens the member sheet.
import type { ThreadMember } from '@gz/contracts'
import { useLang } from '../../shell/lang'
import { Avatar } from '../core'
import { cx } from '../core/cx'
import { useBi } from '../domain-client/bits'
import { defineWords, p } from '../domain-client/copy'
import { RoleBadge } from './RoleBadge'
import './participant-strip.css'

const useW = defineWords({
  label: p('Chat members', 'أعضاء المحادثة'),
  open: p('Show chat members', 'عرض أعضاء المحادثة'),
  works: p('{org}', '{org}'),
})

export type ParticipantStripProps = {
  members: readonly ThreadMember[]
  /** The signed-in person's user id: that member's badge reads "You". */
  meId?: string
  /** Opens the member sheet. Without it the strip is informational. */
  onOpen?: () => void
  /** Show the organisation line under the hotel representative (the member sheet does; the header does not). */
  showOrganisation?: boolean
  className?: string
}

export function ParticipantStrip({ members, meId, onOpen, showOrganisation = false, className }: ParticipantStripProps) {
  const { lang } = useLang()
  const w = useW()
  const bi = useBi()
  const order = { client: 0, hotel_representative: 1, support: 2 } as const
  const sorted = [...members].sort((a, b) => order[a.role] - order[b.role])
  const body = sorted.map(m => (
    <span key={m.userId} className="gz-pstrip__m" data-role={m.role}>
      <Avatar name={lang === 'ar' ? m.name : m.nameLatin} initial={lang === 'ar' ? m.monogram : undefined} size="sm" voice="sans" />
      <span className="gz-pstrip__name gz-t-caption gz-clamp-2" dir="auto">
        {lang === 'ar' ? m.name : m.nameLatin}
      </span>
      <RoleBadge role={m.role} you={m.userId === meId} />
      {showOrganisation && m.organisation ? <span className="gz-pstrip__org gz-t-caption">{bi(m.organisation)}</span> : null}
    </span>
  ))
  if (onOpen) {
    return (
      <button type="button" data-gz="ParticipantStrip" className={cx('gz-reset gz-pstrip gz-press', className)} onClick={onOpen} aria-label={w('open')}>
        {body}
      </button>
    )
  }
  return (
    <div data-gz="ParticipantStrip" role="group" aria-label={w('label')} className={cx('gz-pstrip', className)}>
      {body}
    </div>
  )
}
