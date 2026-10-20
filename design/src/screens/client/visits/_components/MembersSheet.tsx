// MembersSheet (CL-VIST-03): who is in this chat. Names as monograms (never a photograph) with the role chip beside each name, then one
// quiet line (a lock and "Private") whose info glyph holds the rules (only the three of you can read it, no phone number is shared,
// support cannot be blocked), then the two ways out: the venue page and report or block (CL-MSGS-03).
import type { ThreadMember } from '@gz/contracts'
import { Avatar, Button, Icon, InfoButton, RoleBadge } from '../../../../system'
import { useV } from './model'
import './members-sheet.css'

export type MembersSheetProps = {
  members: readonly ThreadMember[]
  meId?: string
  onReport: () => void
  onOpenVenue: () => void
}

export function MembersSheet({ members, meId, onReport, onOpenVenue }: MembersSheetProps) {
  const { t, lang } = useV()
  const order = { client: 0, hotel_representative: 1, support: 2 } as const
  const sorted = [...members].sort((a, b) => order[a.role] - order[b.role])
  return (
    <div className="gzvt-ms" data-gz="MembersSheet">
      <ul className="gzvt-ms__list">
        {sorted.map(m => {
          const name = lang === 'ar' ? m.name : m.nameLatin
          return (
            <li key={m.userId} className="gzvt-ms__row">
              <Avatar name={name} initial={lang === 'ar' ? m.monogram : undefined} size="md" />
              <bdi dir="auto" className="gzvt-ms__name gz-t-title">
                {name}
              </bdi>
              <RoleBadge role={m.role} you={m.userId === meId} />
            </li>
          )
        })}
      </ul>
      <div className="gzvt-ms__rule gz-t-body-s">
        <Icon name="lock" size="sm" tone="secondary" />
        <span>{t('clientVisitsMembersPrivateTitle')}</span>
        <InfoButton title={t('clientVisitsMembersPrivateTitle')}>
          <p>{t('clientVisitsMembersPrivate')}</p>
        </InfoButton>
      </div>
      <div className="gzvt-ms__actions">
        <Button variant="secondary" iconStart="hotel" fullWidth onClick={onOpenVenue}>
          {t('clientVisitsMembersVenue')}
        </Button>
        <Button variant="tertiary" iconStart="flag" onClick={onReport}>
          {t('clientVisitsMembersReport')}
        </Button>
      </div>
    </div>
  )
}
