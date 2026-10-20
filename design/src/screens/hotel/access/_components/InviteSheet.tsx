// "Invitation" (HL-ACCS-01 sheet): there is no self sign-up, the invitation arrives as a WhatsApp link from the venue admin and opens Set password.
// Text diet: the sheet title carries the rule ("Invitation only"), three knots on the gold thread show the way (link, password, code), and a
// picture of the message, drawn like the invitation card of HL-ACCS-03 (envelope, venue, role, who sent it), whose link is the way into
// HL-ACCS-03 in the prototype (in the real app the tap happens in WhatsApp). No sentence. The live navigator draws the sheet around this content.
import { Button, FactChip, IconProgress, Illustration, Tag, useBi, type IconProgressStep } from '../../../../system'
import { useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { adminStaff, invitedStaff, venueOf } from './flow'
import './access.css'
import './invite-sheet.css'

export function InviteSheet({ onClose, onOpenInvitation }: { onClose?: () => void; onOpenInvitation?: () => void }) {
  const t = useT('hotel-access')
  const tc = useT('common')
  const bi = useBi()
  const { lang } = useLang()
  const admin = adminStaff()
  const invited = invitedStaff()
  const venue = venueOf()
  const inviter = admin ? (lang === 'ar' ? admin.name : admin.nameLatin) : ''
  const steps: IconProgressStep[] = [
    { key: 'link', icon: 'whatsapp', label: t('hotelAccessInviteStepLink'), state: 'now' },
    { key: 'password', icon: 'lock', label: t('hotelAccessSigninPasswordLabel'), state: 'open' },
    { key: 'code', icon: 'shield-check', label: t('hotelAccessInviteStepCode'), state: 'open' },
  ]
  return (
    <>
      <div className="hxa-inv">
        <IconProgress steps={steps} labels="all" label={t('hotelAccessInviteSteps')} draw="mount" className="hxa-inv__steps" />

        <div className="hxa-inv__msg" data-gz="InviteMessage">
          <div className="hxa-inv__head">
            <span className="hxa-inv__art" aria-hidden="true">
              <Illustration name="envelope" size="sm" />
            </span>
            <div className="hxa-inv__who">
              <p className="hxa-inv__venue gz-t-d1">{venue ? bi(venue.name) : ''}</p>
              {invited ? <Tag icon="user">{bi(invited.roleLabel)}</Tag> : null}
            </div>
          </div>
          <div className="hxa-inv__foot">
            {inviter ? <FactChip icon="user-plus" label={t('hotelAccessInviteFrom', { name: inviter })} value={<bdi dir="auto">{inviter}</bdi>} /> : <span />}
            <Button variant="tertiary" iconStart="whatsapp" className="hxa-flush-end" onClick={onOpenInvitation}>
              {t('hotelAccessInviteLink')}
            </Button>
          </div>
        </div>
      </div>
      <div className="hxa-inv__footer">
        <Button variant="primary" fullWidth onClick={onClose}>
          {tc('commonActionDone')}
        </Button>
      </div>
    </>
  )
}
