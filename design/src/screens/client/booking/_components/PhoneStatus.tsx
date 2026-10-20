// PhoneStatus: the line under the phone field. Verified is a success glyph and one word; an unverified number offers one action, "Verify" with the
// WhatsApp glyph, a 48 secondary button that opens the code sheet. A request cannot be sent without a verified number.
import { Button, Icon } from '../../../../system'
import { useT } from '../../../../i18n'

export type PhoneStatusProps = {
  verified: boolean
  onVerify: () => void
  disabled?: boolean
}

export function PhoneStatus({ verified, onVerify, disabled }: PhoneStatusProps) {
  const t = useT('client-booking')
  if (verified) {
    return (
      <p className="bk-verified gz-t-body-s" role="status" data-gz-id="booking.phone.verified">
        <Icon name="check-circle" size="sm" tone="success" />
        <span>{t('clientBookingPhoneVerified')}</span>
      </p>
    )
  }
  return (
    <div className="bk-verify" data-gz-id="booking.phone.verify">
      <Button variant="secondary" iconStart="whatsapp" onClick={onVerify} disabled={disabled}>
        {t('clientBookingPhoneVerify')}
      </Button>
    </div>
  )
}
