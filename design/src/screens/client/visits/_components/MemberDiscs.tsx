// MemberDiscs (visits): the three members of a visit chat as three monogram discs in a fixed order (You, Hotel representative, Ghazal
// support), told apart by their ring and tint (the same three surfaces as the role chips), never by a face (ADR 0015). It replaces the
// row of role chips: the names and roles are the accessible name here and the words in the member sheet and on every bubble run.
// With `onOpen` the discs are one 44 target that opens the member sheet.
import type { ThreadMember } from '@gz/contracts'
import { Avatar } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import { useV } from './model'
import './member-discs.css'

const ORDER = { client: 0, hotel_representative: 1, support: 2 } as const

export function MemberDiscs({ members, meId, onOpen }: { members: readonly ThreadMember[]; meId?: string; onOpen?: () => void }) {
  const { t } = useV()
  const { lang } = useLang()
  const sorted = [...members].sort((a, b) => ORDER[a.role] - ORDER[b.role])
  const discs = sorted.map(m => (
    <span key={m.userId} className="gzvt-md__d" data-role={m.role} data-you={m.userId === meId || undefined}>
      <Avatar name={lang === 'ar' ? m.name : m.nameLatin} initial={lang === 'ar' ? m.monogram : undefined} size="xs" />
    </span>
  ))
  if (onOpen) {
    return (
      <button type="button" className="gz-reset gzvt-md gzvt-md--button gz-press" data-gz="MemberDiscs" aria-label={t('clientVisitsMembersOpen')} aria-haspopup="dialog" onClick={onOpen}>
        <span className="gzvt-md__in" aria-hidden="true">
          {discs}
        </span>
      </button>
    )
  }
  return (
    <span className="gzvt-md" role="group" aria-label={t('clientVisitsMembersOpen')} data-gz="MemberDiscs">
      {discs}
    </span>
  )
}
