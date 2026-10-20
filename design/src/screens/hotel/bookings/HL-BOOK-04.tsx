// HL-BOOK-04 Contact client (sheet). Requirement IDs: HA-BOOK-06, HA-BOOK-07, HA-AUTH-02.
// "Reach this client" in one tap: call the contact person, message in the app, or open WhatsApp (OQ-B-12: outside the PRD text). A number
// shows only once the client shared it (OQ-B-19); until then one short line says so and Chat stays. In the prototype Call and WhatsApp show a
// toast instead of leaving the app, and the number is a display-only fixture (never a tel: link).
// Text diet (ADR 0034): the client's name is the title; three rows are a glyph, one word and the number; the privacy sentence (this number is
// shown for this booking only, the voucher code appears through redemption) is behind the info glyph beside the close; no sub-line, no Done.
// States: number-not-shared, role-limited, offline
import { getBooking, type Booking } from '../../../mock'
import { Phone, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { Banner, Icon, IconListRow, InfoButton, useNav } from '../../../system'
import { STORY_BOOKING_ID, UserText, canContact, type BookingRole } from './_components/bits'
import { useBookingActions } from './_components/actions'
import { useBookingById, useBookingParams } from './_components/model'
import { SheetFrame } from './_components/SheetFrame'
import { StateStack } from './_components/States'
import './HL-BOOK-04.css'

export const states = ['number-not-shared', 'role-limited', 'offline']

export default function ContactClient() {
  const { state } = useFrame()
  const nav = useNav()
  const t = useT('hotel-bookings')
  const c = useT('common')
  const act = useBookingActions()
  const params = useBookingParams()
  const found = useBookingById(params.bookingId ?? STORY_BOOKING_ID) ?? (getBooking(STORY_BOOKING_ID) as Booking)
  const role: BookingRole = state === 'role-limited' ? 'accountant' : (params.role ?? 'manager')
  const shared = state === 'number-not-shared' ? false : found.contact.shared
  const offline = state === 'offline'
  const allowed = canContact(role)
  const close = () => nav.closeSheet()
  const ref = { id: found.id, eventDate: found.eventDate }

  // The prototype never leaves the app: Call and WhatsApp say what they would do (the real targets are tel: and wa.me, digits only).
  const call = () => nav.toast({ message: t('hotelBookingsCallToast', { name: `⁨${found.contact.name}⁩` }), icon: 'phone' })
  const whatsapp = () => nav.toast({ message: t('hotelBookingsWhatsappToast', { name: `⁨${found.contact.name}⁩` }), icon: 'whatsapp' })
  const chat = () => {
    close()
    act.chat(ref)
  }

  return (
    <SheetFrame
      title={<UserText role="ui-title">{found.clientName}</UserText>}
      info={allowed ? { title: c('commonLabelDetails'), body: <p>{t('hotelBookingsContactPrivacy')}</p> } : undefined}
      onClose={close}
    >
      {!allowed ? (
        <StateStack illustration="shield" title={c('commonStateTitleNoAccess')} info={{ title: c('commonLabelDetails'), body: <p>{t('hotelBookingsRoleNoContact')}</p> }} />
      ) : (
        <>
          {offline ? (
            <Banner tone="offline" shape="card">
              <span className="hbk-contact__offline">
                {t('hotelBookingsOfflineShort')}
                <InfoButton title={c('commonLabelDetails')}>
                  <p>{t('hotelBookingsContactOffline')}</p>
                </InfoButton>
              </span>
            </Banner>
          ) : null}
          <div className="hbk-contact__rows">
            {shared ? (
              <IconListRow flush icon="phone" title={c('commonActionCall')} trailing={<Phone value={found.contact.phone} />} onClick={call} />
            ) : (
              <p className="hbk-contact__note gz-t-body-s" role="status">
                <Icon name="info" size="sm" tone="accent" />
                {t('hotelBookingsNotShared')}
              </p>
            )}
            <IconListRow flush icon="chat" title={t('hotelBookingsChatRow')} onClick={chat} last={!shared} />
            {shared ? <IconListRow flush last icon="whatsapp" title={c('commonActionWhatsapp')} trailing={<Phone value={found.contact.phone} />} onClick={whatsapp} /> : null}
          </div>
        </>
      )}
    </SheetFrame>
  )
}
