// ConfirmClock: the 24 hour confirm window of CL-BOOK-08 as ONE layout for every moment of the window (flow-local; the shared ConfirmWindow draws
// the elapsed share, this draws what is left). Spoken in glyphs and figures (ADR 0034): a timer glyph and the absolute deadline, a 4 px bar whose
// gold fill is the share of the 24 hours still remaining, and the time left as an hourglass and a figure (`23 h`); in the final hour the same
// line becomes a calm mm:ss. No eyebrow, no sentence. Never red, never animated.
import { Figures, FactChip, Icon, CONFIRM_WINDOW_HOURS, useConfirmLeft } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import './confirm.css'

const two = (n: number) => String(n).padStart(2, '0')

export type ConfirmClockProps = {
  deadline: string
  /** Live seconds left (the player ticks); used for the mm:ss line in the final hour. */
  seconds: number
  /** Show mm:ss instead of the hours left. */
  final: boolean
}

export function ConfirmClock({ deadline, seconds, final }: ConfirmClockProps) {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const left = useConfirmLeft(deadline)
  const remaining = final ? Math.min(1, seconds / (CONFIRM_WINDOW_HOURS * 3600)) : 1 - left.passed
  const clock = `${two(Math.floor(seconds / 60))}:${two(seconds % 60)}`
  return (
    <section className="bk-clock" data-gz="ConfirmClock" data-state={final ? 'final' : 'open'} aria-label={t('clientBookingConfirmWindowLabel')}>
      <p className="bk-clock__deadline gz-t-title">
        <Icon name="timer" size="md" tone="accent" />
        <span className="gz-sr-only">{t('clientBookingConfirmByLabel')}</span>
        <Figures text={f.dateTime(deadline, 'short')} />
      </p>
      <div
        className="bk-clock__bar"
        role="progressbar"
        aria-label={t('clientBookingConfirmWindowLabel')}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(remaining * 100)}
        aria-valuetext={left.text}
      >
        <span className="bk-clock__fill" style={{ flexGrow: remaining }} />
        <span className="bk-clock__rest" style={{ flexGrow: 1 - remaining }} />
      </div>
      {final ? (
        <p className="bk-clock__left gz-t-title" data-gz-id="booking.countdown" role="timer" aria-label={t('clientBookingConfirmLeft', { time: clock })}>
          <Icon name="hourglass" size="sm" tone="secondary" />
          <bdi dir="ltr" className="gz-t-fig-body">{clock}</bdi>
        </p>
      ) : (
        <p className="bk-clock__left" data-gz-id="left">
          <FactChip icon="hourglass" label={left.text} value={tc('commonCountHours', { count: Math.max(1, Math.ceil(seconds / 3600)) })} />
        </p>
      )}
    </section>
  )
}
