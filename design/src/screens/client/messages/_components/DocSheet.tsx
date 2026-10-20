// DocSheet: the PDF preview of a document in a conversation (CA-CHAT-06): the file name, one page that states what the document says
// (built from the request or the provider's own record, through the formatter) and Download, the one gold action. The page reads as
// glyph and value (date, hall, guests, package: no labels, the words are accessible names) and three priced rows with one word each
// (standard, voucher, saved). The legal document itself is the PDF; this is the reading view. Chat documents are private between the two
// sides and can be reported.
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import type { Booking, Conversation, Message } from '@gz/contracts'
import { getBooking, getHall, getVenue, vendorQuoteRequest } from '../../../../mock'
import { Button, FactChip, Figures, Icon, useBi, useNav } from '../../../../system'
import { providerOf } from './model'
import { MsgSheetHead as SheetHead } from './MsgSheetHead'
import { useMsg } from './useMsg'
import './doc-sheet.css'

type Fact = { icon: IconName; label: string; value: string }
type Price = { icon: IconName; label: string; value: string; tone?: 'strong' | 'success' | 'muted' }

/** The reading rows of the document: the hotel's quotation reads the booking; a provider's quotation reads the quote request. */
function useRows(conversation: Conversation): { heading: string; from: string; facts: Fact[]; prices: Price[] } {
  const { t, f } = useMsg()
  const bi = useBi()
  const venue = conversation.venueId ? getVenue(conversation.venueId) : undefined
  const booking: Booking | undefined = conversation.bookingId ? getBooking(conversation.bookingId) : undefined
  const vendor = providerOf(conversation)
  const heading = t('clientMessagesDocQuotation')

  if (vendor) {
    const venueOfEvent = getVenue(vendorQuoteRequest.venueId ?? '')
    const pkg = vendor.packages[0]
    const facts: Fact[] = [
      { icon: 'calendar', label: t('clientMessagesDocEvent'), value: f.date(vendorQuoteRequest.eventDate, 'compact') },
      ...(venueOfEvent ? [{ icon: 'hall' as const, label: t('clientMessagesDocHall'), value: bi(venueOfEvent.name) }] : []),
      ...(vendorQuoteRequest.guests ? [{ icon: 'users-three' as const, label: t('clientMessagesDocGuests'), value: f.integer(vendorQuoteRequest.guests) }] : []),
      ...(pkg ? [{ icon: 'package' as const, label: t('clientMessagesDocPackage'), value: bi(pkg.name) }] : []),
    ]
    const prices: Price[] = [
      ...(pkg ? [{ icon: 'coins' as const, label: t('clientMessagesDocStandard'), value: `${f.money(pkg.price.fils)} ${bi(pkg.unit)}`.trim(), tone: 'muted' as const }] : []),
      ...(pkg?.voucherPrice ? [{ icon: 'ticket' as const, label: t('clientMessagesDocVoucher'), value: `${f.money(pkg.voucherPrice.fils)} ${bi(pkg.unit)}`.trim(), tone: 'strong' as const }] : []),
    ]
    return { heading, from: bi(vendor.name), facts, prices }
  }

  if (booking && venue) {
    const section = booking.sections[0]
    const hall = section ? getHall(section.hallId) : undefined
    const facts: Fact[] = [
      { icon: 'calendar', label: t('clientMessagesDocEvent'), value: f.date(booking.eventDate, 'compact') },
      ...(hall ? [{ icon: 'hall' as const, label: t('clientMessagesDocHall'), value: bi(hall.hall.name) }] : []),
      { icon: 'users-three', label: t('clientMessagesDocGuests'), value: f.integer(booking.sections.reduce((n, s) => n + s.guests, 0)) },
    ]
    const prices: Price[] = [
      { icon: 'coins', label: t('clientMessagesDocStandard'), value: f.money(booking.totals.standardTotal.fils, { mode: 'exact' }), tone: 'muted' },
      { icon: 'ticket', label: t('clientMessagesDocVoucher'), value: f.money(booking.totals.voucherTotal.fils, { mode: 'exact' }), tone: 'strong' },
      { icon: 'offer', label: t('clientMessagesDocSaving'), value: f.money(booking.totals.savings.fils, { mode: 'exact' }), tone: 'success' },
    ]
    return { heading, from: bi(venue.name), facts, prices }
  }
  return { heading, from: bi(conversation.title), facts: [], prices: [] }
}

export function DocSheet({ message, conversation, saved: fixedSaved }: { message: Message; conversation: Conversation; saved?: boolean }) {
  const nav = useNav()
  const { t, f } = useMsg()
  const { heading, from, facts, prices } = useRows(conversation)
  const [saved, setSaved] = useState(false)
  const done = fixedSaved ?? saved
  const doc = message.document
  if (!doc) return null
  return (
    <div className="gzm-doc" data-gz="DocSheet">
      <SheetHead
        plain
        title={
          <bdi dir="ltr" className="gzm-doc__name">
            {doc.name}
          </bdi>
        }
      />
      <div className="gzm-doc__page" role="group" aria-label={t('clientMessagesDocPreview')}>
        <div className="gzm-doc__top">
          <h3 className="gzm-doc__heading gz-t-d1">{heading}</h3>
          <span className="gzm-doc__from gz-t-body-s">
            <bdi dir="auto">{from}</bdi>
          </span>
          <FactChip icon="document" value={t('clientMessagesUnitKb', { n: f.integer(doc.sizeKb) })} label={t('clientMessagesDocFileSize')} tone="muted" size="sm" />
        </div>
        <div className="gzm-doc__rule" aria-hidden="true" />
        <ul className="gzm-doc__facts">
          {facts.map(r => (
            <li key={r.icon + r.value} className="gzm-doc__fact">
              <FactChip icon={r.icon} label={r.label} value={<bdi dir="auto">{r.value}</bdi>} />
            </li>
          ))}
        </ul>
        {prices.length > 0 ? (
          <>
            <div className="gzm-doc__rule" aria-hidden="true" />
            <dl className="gzm-doc__prices">
              {prices.map(r => (
                <div key={r.icon} className="gzm-doc__price" data-tone={r.tone}>
                  <dt className="gzm-doc__price-label gz-t-body-s">
                    <Icon name={r.icon} size="sm" tone={r.tone === 'success' ? 'success' : 'secondary'} />
                    <span>{r.label}</span>
                  </dt>
                  <dd className="gzm-doc__price-value gz-t-fig-body">
                    <Figures text={r.value} />
                  </dd>
                </div>
              ))}
            </dl>
          </>
        ) : null}
      </div>
      <Button
        variant="primary"
        fullWidth
        iconStart={done ? 'check' : 'download'}
        onClick={() => {
          setSaved(true)
          nav.toast({ message: t('clientMessagesDocSaved'), tone: 'success' })
        }}
      >
        {done ? t('clientMessagesDocSaved') : t('clientMessagesDocDownload')}
      </Button>
    </div>
  )
}
