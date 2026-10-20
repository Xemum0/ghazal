// DecisionBar: the pinned bar of Booking detail (ADR 0008 D8, D12; ADR 0033; ADR 0034). It carries only the action of the status; Call and
// Chat sit on the client panel above, so the bar never repeats them.
//   Pending               the ONE gold Accept at thumb height, Decline, and a calendar glyph for another date (Accept disabled with a glyph and
//                         one word on a held date or offline). Accepting starts the client's fixed 24 h confirm window.
//   Approved              Revoke approval (Admin and Manager, reason required, a reliability strike).
//   Confirmed             Redeem voucher (the ONE gold action, opens HL-BOOK-06 with the code).
//   Completed             Reply, when a review waits. Every other status has no bar.
// A Reception user never sees Revoke; an Accountant sees no bar at all. A bar is canvas with a 1 px ink-200 top rule, never ink (direction 2.5).
import type { ReactNode } from 'react'
import { useT } from '../../../../i18n'
import { useBottomChrome } from '../../../../shell/device/context'
import { Button, Icon, useNav } from '../../../../system'
import { canChange, canContact, canDecide, canRedeem } from './bits'
import { refOf, useBookingActions } from './actions'
import type { DetailModel } from './detail'
import './decision-bar.css'

export function DecisionBar({ m, others }: { m: DetailModel; others: number }): ReactNode {
  const { booking: b, role, lock, held } = m
  const t = useT('hotel-bookings')
  const c = useT('common')
  const nav = useNav()
  const act = useBookingActions()
  const { tabBar } = useBottomChrome()
  const ref = refOf(b, others)
  const offline = lock === 'offline'
  let content: ReactNode = null

  const why = (icon: 'lock' | 'offline', text: string) => (
    <p className="hbk-bar__why" role="status">
      <Icon name={icon} size="xs" tone="secondary" />
      <span className="gz-t-caption">{text}</span>
    </p>
  )

  if (b.status === 'pending' && !b.proposal) {
    if (!canDecide(role)) return null
    const blocked = offline || held
    content = (
      <>
        {offline ? why('offline', t('hotelBookingsOfflineShort')) : held ? why('lock', t('hotelBookingsHeldLine')) : null}
        <div className="hbk-bar__row">
          <Button variant="primary" size="cta" iconStart="check" disabled={blocked} onClick={() => act.accept(ref)} className="hbk-bar__main">
            {c('commonActionAccept')}
          </Button>
          <Button variant="secondary" size="cta" disabled={offline} onClick={() => act.decline(ref)} className="hbk-bar__decline">
            {c('commonActionDecline')}
          </Button>
          <Button variant="secondary" size="cta" iconStart="calendar-dots" disabled={offline} onClick={() => act.propose(ref)} className="hbk-bar__date">
            <span className="gz-sr-only">{t('hotelBookingsProposeDate')}</span>
          </Button>
        </div>
      </>
    )
  } else if (b.status === 'approved') {
    if (!canContact(role) || !canChange(role)) return null
    content = (
      <Button variant="destructive" size="md" fullWidth iconStart="close" disabled={offline} onClick={() => act.cancel(ref)}>
        {t('hotelBookingsRevokeApproval')}
      </Button>
    )
  } else if (b.status === 'confirmed') {
    if (!canRedeem(role)) return null
    content = (
      <>
        {offline ? why('offline', t('hotelBookingsOfflineShort')) : null}
        <Button variant="primary" size="cta" fullWidth iconStart="qr-code" disabled={offline} onClick={() => act.redeem(b)}>
          {c('commonRedeemVoucher')}
        </Button>
      </>
    )
  } else if (b.status === 'completed' && m.review) {
    const reviewId = m.review.id
    content = (
      <Button variant="secondary" size="md" fullWidth iconStart="star" onClick={() => nav.push('HL-GROW-06', { reviewId })}>
        {t('hotelBookingsReplyToReview')}
      </Button>
    )
  }

  if (!content) return null
  return (
    <div className="hbk-bar" data-gz="DecisionBar">
      {content}
      {tabBar ? null : <span className="hbk-bar__inset" aria-hidden="true" />}
    </div>
  )
}
