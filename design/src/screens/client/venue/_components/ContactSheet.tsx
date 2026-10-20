// ContactSheet (CL-VENU-01 "Contact", the browse-only path of ADR 0033): a guest reaches the venue through its own published channels (phone and
// WhatsApp) and pays the venue directly at the standard price; no Ghazal object is created. A registered client opens the in-app chat instead
// (CL-MSGS-02), so this sheet is the guest's path; it also offers the account for chat. ADR 0034: two rows (a glyph, one word, the number) and
// one button; the explanation is gone (the sheet's title and the glyphs say it).
import * as mock from '../../../../mock'
import { Phone, useT } from '../../../../i18n'
import { usePrototype } from '../../../../shell/state'
import { Button, IconListRow, useBi, useNav } from '../../../../system'
import './sections.css'

export function ContactSheet({ venueId }: { venueId: string }) {
  const t = useT('client-venue')
  const tc = useT('common')
  const bi = useBi()
  const nav = useNav()
  const venue = mock.getVenue(venueId)
  if (!venue) return null
  const say = (message: string, icon: 'phone' | 'chat') => {
    nav.closeSheet()
    nav.toast({ message, icon })
  }
  const signIn = () => {
    nav.closeSheet()
    usePrototype.getState().openGate('chat', { screenId: 'CL-MSGS-02', params: { venueId } })
    nav.openSheet('CL-AUTH-01', { params: { reason: 'chat' } })
  }
  return (
    <div className="gzv-contact" data-gz-id="venue.contact">
      <ul className="gzv-maps">
        <li>
          <IconListRow flush icon="phone" title={tc('commonActionCall')} trailing={<Phone value={venue.phone} />} chevron={false} onClick={() => say(t('clientVenueContactCalling', { venue: bi(venue.name) }), 'phone')} />
        </li>
        <li>
          <IconListRow flush last icon="whatsapp" title={tc('commonActionWhatsapp')} trailing={<Phone value={venue.phone} />} chevron={false} onClick={() => say(t('clientVenueContactWhatsapp'), 'chat')} />
        </li>
      </ul>
      <Button variant="secondary" iconStart="chat" fullWidth onClick={signIn}>
        {t('clientVenueContactChat')}
      </Button>
    </div>
  )
}
