// StickyBar (CL-VENU-01, direction rule 8): the CTA bar that replaces the tab bar on venue details. The page's one gold fill lives here.
// The three paths of the voucher model sit in one bar (ADR 0033): the primary is the verb of the voucher path (Get voucher with the KD 2 as a
// figure beside it, or Send request when a ready voucher exists), and under it the two quiet ones, Book visit and Contact, which need no
// voucher. With no date the verb is Choose date, with an unavailable date Free dates; with no voucher price (or a saving under the KD 2 fee)
// the page says nothing about vouchers and the primary becomes Contact. ADR 0034: every label within two words, the fee is a ticket glyph
// and a figure (the money is never icon-only), the offline reason is the banner above. Offline the button is disabled.
import { useT } from '../../../../i18n'
import { ActionBar, Button, Icon, Price } from '../../../../system'
import { VOUCHER_FEE_FILS } from './model'
import type { VenueActions } from './useActions'
import type { VenuePage } from './usePage'

export function StickyBar({ page, actions }: { page: VenuePage; actions: VenueActions }) {
  const t = useT('client-venue')
  const tc = useT('common')
  const { venue, hall, brief, status, prices, row, owned, visitOpen, flags } = page
  if (!venue || !hall) return null

  const carry = { brief, hallId: hall.id, sessionId: page.sessionId, packageId: row?.pkg.id ?? null }
  const priced = prices !== null && (status === 'available' || status === 'held')
  const voucherPath = priced && prices.eligible
  const contactIsPrimary = priced && !prices.eligible
  // A date but no guest count yet: there is no quote to price (nor to attach a ready voucher to), so the bar asks for the guests first.
  const guestsMissing = (status === 'available' || status === 'held') && prices === null && brief.guests === null
  const getsVoucher = !flags.offline && status !== 'none' && status !== 'unavailable' && !guestsMissing && !contactIsPrimary && !(owned && voucherPath)

  const action = flags.offline
    ? { label: t('clientVenueCtaOffline'), iconEnd: 'offline' as const, disabled: true }
    : status === 'none'
      ? { label: t('clientVenueCtaChooseDate'), iconEnd: 'calendar' as const, onPress: () => actions.openCalendar(hall.id) }
      : status === 'unavailable'
        ? { label: t('clientVenueCtaSeeDates'), iconEnd: 'calendar' as const, onPress: () => actions.openCalendar(hall.id) }
        : guestsMissing
          ? { label: t('clientVenueCalGuestsCta'), iconEnd: 'users-three' as const, onPress: actions.editBrief }
          : contactIsPrimary
            ? { label: t('clientVenueCtaContact'), iconEnd: 'chat' as const, onPress: actions.contactVenue }
            : owned && voucherPath
              ? { label: t('clientVenueCtaSendRequest'), iconEnd: 'send' as const, onPress: () => actions.sendRequest(carry, owned) }
              : { label: t('clientVenueCtaGetVoucher'), iconEnd: 'ticket' as const, onPress: () => actions.getVoucher(carry) }

  // The two paths that need no voucher: a glyph and one word each. Not offered offline (the banner says why).
  const note = flags.offline ? undefined : (
    <span className="gzv-barlinks">
      {visitOpen ? (
        <Button variant="tertiary" iconStart="calendar-check" onClick={actions.bookVisit} data-gz-id="venue.visit">
          {t('clientVenueCtaVisit')}
        </Button>
      ) : (
        <span className="gzv-barnote gzv-barnote--quiet" data-gz-id="venue.visit-none">
          <Icon name="calendar-x" size="sm" tone="secondary" />
          <span className="gz-t-button">{t('clientVenueCtaVisit')}</span>
          <span className="gz-sr-only">{t('clientVenueVisitNone')}</span>
        </span>
      )}
      {!contactIsPrimary ? (
        <Button variant="tertiary" iconStart="chat" onClick={actions.contactVenue} data-gz-id="venue.contact">
          {t('clientVenueCtaContact')}
        </Button>
      ) : null}
    </span>
  )

  return (
    <ActionBar
      action={action}
      note={note}
      summaryLabel={
        getsVoucher ? (
          <>
            <Icon name="ticket" size="sm" tone="secondary" />
            <span className="gz-sr-only">{tc('commonVoucherPrice')}</span>
          </>
        ) : undefined
      }
      summaryValue={getsVoucher ? <Price fils={VOUCHER_FEE_FILS} size="display" /> : undefined}
    />
  )
}
