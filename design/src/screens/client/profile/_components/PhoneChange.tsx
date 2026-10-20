// Changing the verified number (CL-PROF-03, CA-AUTH-05): a new number is verified with a WhatsApp code before it replaces the old one. Two
// steps in one sheet: the new number, then the code (the auth flow's code controller, so five attempts, the 60 s resend and the lock are
// the same everywhere). Success writes the account's number and closes with a quiet toast; dismissing leaves the old number untouched.
// Text diet (ADR 0034): a field and one action, then the number and the six boxes; the back arrow in the header returns to the field.
import { useState } from 'react'
import { useFormat, useT } from '../../../../i18n'
import { usePrototype } from '../../../../shell/state'
import { Button, PhoneField, useNav } from '../../../../system'
import { useOtp } from '../../auth/_components/OtpPanel'
import { CodeBody } from './reauth'
import { SheetBox } from './parts'
import './phone-change.css'

export type PhoneStep = 'enter' | 'otp'

export function PhoneChangeSheet({ initialStep = 'enter', initialPhone = '' }: { initialStep?: PhoneStep; initialPhone?: string }) {
  const t = useT('client-profile')
  const tc = useT('common')
  const f = useFormat()
  const nav = useNav()
  const [step, setStep] = useState<PhoneStep>(initialStep)
  const [phone, setPhone] = useState(initialPhone)
  const [invalid, setInvalid] = useState(false)

  const verified = () => {
    usePrototype.setState(s => (s.user ? { user: { ...s.user, phone: `+965${phone}` } } : s))
    nav.closeSheet()
    nav.toast({ message: t('clientProfilePhoneDone'), tone: 'success' })
  }
  const otp = useOtp({ onVerified: verified })

  const send = () => {
    if (!f.isValidPhone(phone)) return setInvalid(true)
    setInvalid(false)
    setStep('otp')
  }

  if (step === 'otp') {
    const a = otp.action
    return (
      <SheetBox
        title={t('clientProfilePhoneTitle')}
        onBack={() => setStep('enter')}
        backLabel={tc('commonActionBack')}
        footer={
          <Button variant="primary" fullWidth loading={a.loading} disabled={a.disabled} onClick={a.onPress}>
            {a.label}
          </Button>
        }
      >
        <div className="gzpr-phone">
          <CodeBody otp={otp} phone={`+965${phone}`} sheet />
        </div>
      </SheetBox>
    )
  }

  return (
    <SheetBox
      title={t('clientProfilePhoneTitle')}
      onClose={() => nav.closeSheet()}
      footer={
        <Button variant="primary" fullWidth iconStart="whatsapp" onClick={send}>
          {t('clientProfilePhoneSend')}
        </Button>
      }
    >
      <div className="gzpr-phone">
        <PhoneField
          label={t('clientProfilePhoneNew')}
          value={phone}
          onChange={v => {
            setPhone(v)
            if (invalid) setInvalid(false)
          }}
          error={invalid ? t('clientProfilePhoneErrorDigits', { count: 8 }) : undefined}
          validateOnBlur={false}
          autoFocus={false}
        />
      </div>
    </SheetBox>
  )
}
