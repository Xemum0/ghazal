// BookingActionList: what the partner may do with a request (ADR 0033 D3, ADR 0008 D12): Propose another date (a counter-offer on a pending
// request), Revoke approval (an approved request, before the client confirms) and Cancel booking (a confirmed request), each a 64 row with
// the consequence in a caption, so nobody taps into a surprise. Revoke and Cancel are the danger tone and say what happens to the client's
// voucher: it goes back to them to use again (a support-granted credit is the only money-side remedy, ADR 0035); nothing else moves because the event is paid between client and venue. Only
// Admin and Manager see Revoke and Cancel (the screen passes `actions` for the role); an action the role cannot use is not drawn, never locked.
import type { IconName } from '@gz/tokens'
import { Icon, ListRow } from '../../core'
import { cx } from '../../core/cx'
import { Figures } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './booking-detail.css'

const useW = defineWords({
  reschedule: p('Propose another date', 'اقتراح موعد آخر'),
  rescheduleWhy: p('Offer up to three dates at the same voucher price. The client has 48 hours to answer.', 'اقتراح حتى ثلاثة مواعيد بسعر الكوبون نفسه. أمام العميل 48 ساعة للرد.'),
  revoke: p('Revoke approval', 'سحب الموافقة'),
  revokeWhy: p('The date is released and the voucher goes back to the client.', 'يُخلى التاريخ ويعود الكوبون إلى العميل.'),
  cancel: p('Cancel booking', 'إلغاء الحجز'),
  cancelWhy: p('The voucher goes back to the client. The cancellation counts on your record.', 'يعود الكوبون إلى العميل. ويُسجَّل الإلغاء في سجلكم.'),
})

export type BookingAction = 'reschedule' | 'revoke' | 'cancel'

const ICON: Record<BookingAction, IconName> = { reschedule: 'calendar-dots', revoke: 'undo', cancel: 'close' }

export type BookingActionListProps = {
  /** The actions this role may take, in order. */
  actions: readonly BookingAction[]
  onAction?: (a: BookingAction) => void
  className?: string
}

export function BookingActionList({ actions, onAction, className }: BookingActionListProps) {
  const w = useW()
  return (
    <div data-gz="BookingActionList" className={cx('gz-bal', className)}>
      {actions.map((a, i) => (
        <ListRow
          key={a}
          flush
          chevron
          last={i === actions.length - 1}
          tone={a === 'cancel' || a === 'revoke' ? 'danger' : 'default'}
          onClick={() => onAction?.(a)}
          leading={
            <span className={cx('gz-inv__disk', (a === 'cancel' || a === 'revoke') && 'gz-inv__disk--danger')} aria-hidden="true">
              <Icon name={ICON[a]} size="sm" />
            </span>
          }
          title={w(a)}
          subtitle={<Figures text={a === 'reschedule' ? w('rescheduleWhy') : a === 'revoke' ? w('revokeWhy') : w('cancelWhy')} />}
        />
      ))}
    </div>
  )
}
