// Attempts left as five quiet pips (filled = still available), after a wrong code. The number is the accessible name; nothing is
// said on screen. Config comes from flow.ts (MAX_ATTEMPTS), never typed here.
import { useT } from '../../../../i18n'
import { MAX_ATTEMPTS } from './flow'
import './otp.css'

export function AttemptPips({ left }: { left: number }) {
  const t = useT('client-auth')
  return (
    <span className="gza-pips" role="img" aria-label={t('clientAuthOtpAttemptsLeft', { count: left })} data-gz="AttemptPips">
      {Array.from({ length: MAX_ATTEMPTS }, (_, i) => (
        <span key={i} className={i < left ? 'gza-pip is-on' : 'gza-pip'} />
      ))}
    </span>
  )
}
