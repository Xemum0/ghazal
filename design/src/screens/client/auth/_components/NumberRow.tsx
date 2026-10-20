// The number a code was sent to, as a value and not a sentence: the WhatsApp mark on a quiet disk, the figure in an LTR island, and
// one word at the end edge to change it. Used by the code screen (CL-AUTH-02) and the reset-code step (CL-AUTH-04).
import { Button, Icon } from '../../../../system'
import { Phone, useT } from '../../../../i18n'
import './auth.css'

export function NumberRow({ phone, onChange }: { phone: string; onChange: () => void }) {
  const t = useT('client-auth')
  return (
    <div className="gza-number" data-gz="NumberRow">
      <span className="gza-number__mark" aria-hidden="true">
        <Icon name="whatsapp" size="sm" />
      </span>
      <p className="gza-number__value gz-t-fig-title">
        <Phone value={phone} />
      </p>
      <Button variant="tertiary" aria-label={t('clientAuthOtpChangeNumber')} onClick={onChange}>
        {t('clientAuthOtpChange')}
      </Button>
    </div>
  )
}
