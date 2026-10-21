// ConfirmWindow (CL-BKNG approved state, the approval notification, the partner "Awaiting client" card): the 24 hour window the client has
// to confirm an approved request (owner rule, fixed). Calm by design: the deadline is an absolute sentence, the time left is hours and
// minutes (never seconds, never a ticking digit), the thread bar only shows how much of the window has passed and never turns red.
// Under an hour it says minutes; at the end it says the window closed and what happens to the voucher, in a neutral tone.
//
// states   open (hours and minutes left) . last hour (minutes left) . lapsed (window ended) . confirmed (done, with the time it was confirmed)
import { useFormat, useT } from '../../i18n'
import { Button } from '../core'
import { cx } from '../core/cx'
import { Figures } from '../domain-client/bits'
import { defineWords, p } from '../domain-client/copy'
import './confirm-window.css'

/** The window the owner fixed: 24 hours from the approval (configuration, not partner-editable). */
export const CONFIRM_WINDOW_HOURS = 24

const useW = defineWords({
  eyebrow: p('Confirm your booking', 'أكدوا حجزكم'),
  by: p('Confirm by {when}', 'التأكيد حتى {when}'),
  held: p('The date is held for you until then. You pay nothing more to Ghazal.', 'التاريخ محجوز لكم حتى ذلك الوقت. لا مبلغ إضافي لغزل.'),
  lessThanMinute: p('Less than a minute left', 'أقل من دقيقة متبقية'),
  lapsedTitle: p('The confirm window ended', 'انتهت مهلة التأكيد'),
  lapsedBody: p('The date was released and the voucher is no longer valid.', 'تم إخلاء التاريخ ولم يعد الكوبون صالحًا.'),
  doneTitle: p('You confirmed this booking', 'تم تأكيد الحجز'),
  doneAt: p('Confirmed on {when}', 'تم التأكيد في {when}'),
  thread: p('Share of the confirm window that has passed', 'المدة المنقضية من مهلة التأكيد'),
})

export type ConfirmWindowProps = {
  /** When the window closes (`booking.confirmBy`). */
  deadline: string
  /** When the client confirmed (`booking.confirmedAt`): switches to the done state. */
  confirmedAt?: string | null
  /** The primary action; omitted when the screen has its own bar. */
  onConfirm?: () => void
  /** Over an ink panel (the approval hero). */
  onDark?: boolean
  /** Instant to measure from; defaults to the prototype clock. */
  now?: string
  className?: string
}

export function useConfirmLeft(deadline: string, now?: string) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const nowMs = now ? new Date(now).getTime() : f.now().getTime()
  const endMs = new Date(deadline).getTime()
  const leftMin = Math.max(0, Math.ceil((endMs - nowMs) / 60000))
  const totalMin = CONFIRM_WINDOW_HOURS * 60
  const passed = Math.min(1, Math.max(0, 1 - leftMin / totalMin))
  const hours = Math.floor(leftMin / 60)
  const minutes = leftMin % 60
  const parts: string[] = []
  if (hours > 0) parts.push(t('commonCountHours', { count: hours }))
  if (minutes > 0 || hours === 0) parts.push(t('commonCountMinutes', { count: minutes }))
  const text = leftMin <= 0 ? '' : leftMin < 1 ? w('lessThanMinute') : t('commonStatusTimeLeft', { time: f.list(parts) })
  return { leftMin, passed, text, ended: leftMin <= 0, lastHour: leftMin > 0 && leftMin <= 60 }
}

export function ConfirmWindow({ deadline, confirmedAt, onConfirm, onDark = false, now, className }: ConfirmWindowProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const left = useConfirmLeft(deadline, now)
  const state = confirmedAt ? 'confirmed' : left.ended ? 'lapsed' : left.lastHour ? 'last-hour' : 'open'

  return (
    <section data-gz="ConfirmWindow" data-state={state} className={cx('gz-cwin', onDark && 'gz-on-dark', className)} aria-label={w('eyebrow')}>
      {state === 'confirmed' ? (
        <>
          <h3 className="gz-cwin__title gz-t-title">{w('doneTitle')}</h3>
          <p className="gz-cwin__line gz-t-body-s">
            <Figures text={w('doneAt', { when: f.dateTime(confirmedAt as string, 'short') })} />
          </p>
        </>
      ) : state === 'lapsed' ? (
        <>
          <h3 className="gz-cwin__title gz-t-title">{w('lapsedTitle')}</h3>
          <p className="gz-cwin__line gz-t-body-s">{w('lapsedBody')}</p>
        </>
      ) : (
        <>
          <p className="gz-cwin__eyebrow gz-t-label">{w('eyebrow')}</p>
          <h3 className="gz-cwin__deadline gz-t-title">
            <Figures text={w('by', { when: f.dateTime(deadline, 'full') })} />
          </h3>
          <div
            className="gz-cwin__bar"
            role="progressbar"
            aria-label={w('thread')}
            aria-valuemin={0}
            aria-valuemax={100}
            aria-valuenow={Math.round(left.passed * 100)}
            aria-valuetext={left.text}
          >
            <span className="gz-cwin__fill" style={{ flexGrow: left.passed }} />
            <span className="gz-cwin__rest" style={{ flexGrow: 1 - left.passed }} />
          </div>
          <p className="gz-cwin__left gz-t-body-s" data-gz-id="left">
            <Figures text={left.text} />
          </p>
          <p className="gz-cwin__held gz-t-caption">{w('held')}</p>
          {onConfirm ? (
            <Button variant="primary" fullWidth onClick={onConfirm}>
              {t('commonConfirmBooking')}
            </Button>
          ) : null}
        </>
      )}
    </section>
  )
}
