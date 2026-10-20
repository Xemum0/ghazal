// Attempts left as five quiet pips (filled = still available), after a wrong code. The number is the accessible name; nothing is said on
// screen. The count comes from flow.ts (MAX_ATTEMPTS), never typed here.
import { useT } from '../../../../i18n'
import { MAX_ATTEMPTS } from './flow'
import './code-panel.css'

export function AttemptPips({ left }: { left: number }) {
  const t = useT('hotel-access')
  return (
    <span className="hxa-pips" role="img" aria-label={t('hotelAccessVerifyAttemptsLeft', { count: left })} data-gz="AttemptPips">
      {Array.from({ length: MAX_ATTEMPTS }, (_, i) => (
        <span key={i} className={i < left ? 'hxa-pip is-on' : 'hxa-pip'} />
      ))}
    </span>
  )
}
