// The invitation, read-only (HL-ACCS-03). Text diet: the venue name (serif, it is a venue name) beside a small envelope drawing, the role as
// a tag with its summary behind an info glyph, then three facts as glyph + value with no label: who invited, the number that was invited, and
// how long the invitation is valid. The number cannot be edited. The labels are accessible names.
import { plainText } from '@gz/i18n'
import { FactChip, Icon, Illustration, InfoButton, Tag, useBi } from '../../../../system'
import { Phone, useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Fx } from './Fx'
import { adminStaff, invitedStaff, venueOf } from './flow'
import './invite-card.css'

export function InviteCard() {
  const t = useT('hotel-access')
  const f = useFormat()
  const bi = useBi()
  const { lang } = useLang()
  const invited = invitedStaff()
  const admin = adminStaff()
  const venue = venueOf()
  if (!invited) return null
  const inviter = admin ? (lang === 'ar' ? admin.name : admin.nameLatin) : (invited.invitedBy ?? '')
  const role = bi(invited.roleLabel)
  return (
    <section className="hxa-card" data-gz="InviteCard" aria-label={t('hotelAccessSetupCardLabel')}>
      <div className="hxa-card__head">
        <span className="hxa-card__art" aria-hidden="true">
          <Illustration name="envelope" size="sm" />
        </span>
        <div className="hxa-card__who">
          <h2 className="hxa-card__venue gz-t-d1">{venue ? bi(venue.name) : ''}</h2>
          <div className="hxa-card__role">
            <Tag icon="user">{role}</Tag>
            <InfoButton title={role} label={t('hotelAccessSetupRoleInfo')} className="hxa-card__info">
              {bi(invited.roleSummary)}
            </InfoButton>
          </div>
        </div>
      </div>
      <ul className="hxa-card__facts">
        <li className="hxa-card__fact">
          <FactChip icon="user-plus" label={t('hotelAccessInviteFrom', { name: inviter })} value={<bdi dir="auto">{inviter}</bdi>} />
        </li>
        <li className="hxa-card__fact">
          <FactChip icon="whatsapp" label={t('hotelAccessSetupInvitedNumber')} value={<Phone value={invited.phone} />} />
        </li>
        {invited.inviteExpiresAt ? (
          <li className="hxa-card__fact">
            <FactChip
              icon="calendar"
              label={t('hotelAccessSetupValidUntil', { date: plainText(f.date(invited.inviteExpiresAt, 'dayMonth')) })}
              value={<Fx text={f.date(invited.inviteExpiresAt, 'dayMonth')} />}
            />
          </li>
        ) : null}
      </ul>
    </section>
  )
}
