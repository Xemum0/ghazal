// ConfirmTimer (CL-BKNG-02, approved states): the 24 hour window to confirm, as a figure and a line (ADR 0034). Flow-local twin of the system
// ConfirmWindow, which still carries four sentences; a request for a diet pass of it is in docs/engineering/requests.md. The time left is
// hours and minutes in the figures voice (never seconds, never a ticking digit); the absolute deadline sits on the Booking Thread above
// (timer glyph and time). The bar shows how much of the window has passed and never turns red. What the hold means is behind the info glyph.
import { Icon, InfoButton, useConfirmLeft } from '../../../../system'
import { Fx } from './Fx'
import { useBk } from './useBk'
import './confirm-timer.css'

export function ConfirmTimer({ deadline, now }: { deadline: string; now?: string }) {
  const { t, f } = useBk()
  const left = useConfirmLeft(deadline, now)
  if (left.ended) return null
  // Hours and minutes from the formatter's own unit letters (`24 h`, `40 m`); the compact duration would turn 24 h into `1 d`. The formatter
  // may add an empty tail (`1 h 0 m`, Arabic `1 \u0633 0 \u062f`): only the FIRST unit word of the string is the unit asked for.
  const unit = (ms: number) => f.duration(ms).match(/[^\d\s\u00a0\u2066-\u2069\u0660-\u0669]+/)?.[0] ?? ''
  const hours = Math.floor(left.leftMin / 60)
  const minutes = left.leftMin % 60
  const value = hours > 0 ? `${f.integer(hours)}\u00a0${unit(3_600_000)}${minutes > 0 ? ` ${f.integer(minutes)}\u00a0${unit(60_000)}` : ''}` : `${f.integer(minutes)}\u00a0${unit(60_000)}`
  return (
    <section className="gzb-timer" data-gz="ConfirmTimer" data-state={left.lastHour ? 'last-hour' : 'open'} aria-label={t('clientBookingsConfirmWindow')}>
      <div className="gzb-timer__row">
        <span className="gzb-timer__glyph" aria-hidden="true">
          <Icon name={left.lastHour ? 'timer' : 'hourglass'} size="md" tone="accent" />
        </span>
        <span className="gzb-timer__left" data-gz-id="left">
          <span className="gz-sr-only">{t('clientBookingsConfirmLeft')}</span>
          <span className="gzb-timer__figure gz-t-kpi">
            <Fx text={value} />
          </span>
        </span>
        <InfoButton title={t('clientBookingsConfirmInfoTitle')} className="gzb-timer__info">
          <p>{t('clientBookingsConfirmInfo')}</p>
        </InfoButton>
      </div>
      <div
        className="gzb-timer__bar"
        role="progressbar"
        aria-label={t('clientBookingsConfirmWindow')}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(left.passed * 100)}
        aria-valuetext={value}
      >
        <span className="gzb-timer__fill" style={{ flexGrow: left.passed }} />
        <span className="gzb-timer__rest" style={{ flexGrow: 1 - left.passed }} />
      </div>
    </section>
  )
}
