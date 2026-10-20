// The two provider buttons, side by side and equal (secondary 48): the registry's own Apple and Google marks and one word each.
// Apple is shown because the prototype is an iPhone; on Android the row is Google alone (inventory: "Continue with Apple (iOS only)").
import { Button } from '../../../../system'
import { useT } from '../../../../i18n'
import './auth.css'

export function ProviderButtons({ onApple, onGoogle, disabled }: { onApple?: () => void; onGoogle?: () => void; disabled?: boolean }) {
  const t = useT('client-auth')
  return (
    <div className="gza-paths" data-gz-id="auth.providers">
      <Button variant="secondary" iconStart="apple" disabled={disabled} onClick={onApple} className="gza-path">
        {t('clientAuthSharedApple')}
      </Button>
      <Button variant="secondary" iconStart="google" disabled={disabled} onClick={onGoogle} className="gza-path">
        {t('clientAuthSharedGoogle')}
      </Button>
    </div>
  )
}
