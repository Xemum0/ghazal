// ConfirmLeft: the 24 hour window to confirm an approved request, as one figure and one line (ADR 0034). The time left is hours and minutes in
// the figures voice (`23 h 40 m`, never seconds, never a ticking digit); the bar shows how much of the window has passed and never turns red.
// The sentence that says what the hold means is behind the info glyph. The system ConfirmWindow still carries four sentences; the bookings flow
// has the same twin (a request to adopt the anatomy is in docs/engineering/requests.md).
import { Icon, InfoButton, useConfirmLeft } from '../../../../system'
import { Fx } from './Fx'
import { useVc } from './useVc'
import './confirm-left.css'

export function ConfirmLeft({ deadline, now }: { deadline: string; now?: string }) {
  const { t, f } = useVc()
  const left = useConfirmLeft(deadline, now)
  if (left.ended) return null
  // Hours and minutes from the formatter's own unit letters (`24 h`, `40 m`): only the FIRST unit word of a duration string is the unit asked for.
  const unit = (ms: number) => f.duration(ms).match(/[^\d\s ⁦-⁩٠-٩]+/)?.[0] ?? ''
  const hours = Math.floor(left.leftMin / 60)
  const minutes = left.leftMin % 60
  const nb = ' '
  const value = hours > 0 ? `${f.integer(hours)}${nb}${unit(3_600_000)}${minutes > 0 ? ` ${f.integer(minutes)}${nb}${unit(60_000)}` : ''}` : `${f.integer(minutes)}${nb}${unit(60_000)}`
  return (
    <section className="gzv-left" data-gz="ConfirmLeft" data-state={left.lastHour ? 'last-hour' : 'open'} aria-label={t('clientVouchersInfoWindow')}>
      <div className="gzv-left__row">
        <span className="gzv-left__glyph" aria-hidden="true">
          <Icon name={left.lastHour ? 'timer' : 'hourglass'} size="md" tone="accent" />
        </span>
        <span className="gzv-left__time" data-gz-id="left">
          <span className="gz-sr-only">{t('clientVouchersWindowLeft')}</span>
          <span className="gzv-left__figure gz-t-kpi">
            <Fx text={value} />
          </span>
        </span>
        <span className="gzv-left__info">
          <InfoButton title={t('clientVouchersInfoWindow')}>
            <p>{t('clientVouchersWindowBody')}</p>
          </InfoButton>
        </span>
      </div>
      <div
        className="gzv-left__bar"
        role="progressbar"
        aria-label={t('clientVouchersInfoWindow')}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(left.passed * 100)}
        aria-valuetext={value}
      >
        <span className="gzv-left__fill" style={{ flexGrow: left.passed }} />
        <span className="gzv-left__rest" style={{ flexGrow: 1 - left.passed }} />
      </div>
    </section>
  )
}
