// The WhatsApp code body of the Profile flow: deletion asks for a fresh code (CL-PROF-06, ADR 0028 item 7) and a new phone number is
// verified the same way (CL-PROF-03). The auth flow's code controller does the work (five attempts, 60 s resend, expired and locked states,
// the demo codes), so the rules are the same everywhere; this body is leaner than the sign-in one: no "change number" (the code goes to the
// number on the account), no provider shortcuts. Text diet (ADR 0034): the number is a value beside the WhatsApp mark, a wrong code is two
// words, a timer is a figure, locked and not-delivered are a drawing and three words with the recovery text behind the info glyph.
import { Button, EmptyState, FactChip, Icon, OtpInput, SuccessState } from '../../../../system'
import { Phone, useT } from '../../../../i18n'
import { AttemptPips } from '../../auth/_components/AttemptPips'
import type { OtpModel } from '../../auth/_components/OtpPanel'
import { useSupport } from '../../auth/_components/support'
import './reauth.css'

export function CodeBody({ otp, phone, sheet = false }: { otp: OtpModel; phone: string; sheet?: boolean }) {
  const a = useT('client-auth')
  const support = useSupport()
  const { view, code, seconds, attemptsLeft } = otp
  const size = sheet ? 'lg' : 'hero'

  if (view === 'success') return <SuccessState illustration="seal" title={a('clientAuthOtpSuccessTitle')} size={size} fill={!sheet} />

  if (view === 'locked') {
    return (
      <EmptyState
        illustration="shield"
        title={a('clientAuthOtpLocked')}
        detail={a('clientAuthOtpLockedDetail')}
        action={{ label: a('clientAuthSharedSupport'), onPress: support, variant: 'tertiary' }}
        fill={false}
        size="lg"
        align="start"
      />
    )
  }

  if (view === 'delivery-failed') {
    return (
      <EmptyState
        illustration="chat"
        artTone="danger"
        title={a('clientAuthOtpDeliveryFailed')}
        detail={a('clientAuthOtpDeliveryFailedDetail')}
        action={{ label: a('clientAuthOtpSendAgain'), onPress: otp.resend, variant: 'secondary' }}
        secondary={{ label: a('clientAuthSharedSupport'), onPress: support }}
        fill={false}
        size="lg"
        align="start"
      />
    )
  }

  const error = view === 'wrong-code' ? a('clientAuthOtpWrong') : view === 'expired-code' ? a('clientAuthOtpExpired') : undefined
  const frozen = view === 'offline'
  const showResend = view !== 'expired-code'

  return (
    <div className="gzpr-code" data-gz="CodeBody" data-view={view}>
      <div className="gzpr-code__num">
        <span className="gz-irow__disk" aria-hidden="true">
          <Icon name="whatsapp" size="md" />
        </span>
        <p className="gzpr-code__value">
          <Phone value={phone} className="gz-t-fig-title" />
        </p>
      </div>
      <OtpInput label={a('clientAuthOtpLabel')} value={code} onChange={otp.change} onComplete={c => otp.verify(c)} loading={view === 'loading'} error={error} disabled={frozen} autoFocus={otp.live} />
      {showResend ? (
        <div className="gzpr-code__row">
          {seconds > 0 ? (
            <FactChip icon="timer" value={a('clientAuthOtpTimer', { count: seconds })} label={a('clientAuthOtpResendIn', { count: seconds })} />
          ) : (
            <Button variant="tertiary" className="gzpr-flush" onClick={otp.resend} disabled={frozen}>
              {a('clientAuthOtpResend')}
            </Button>
          )}
          {view === 'wrong-code' ? <AttemptPips left={attemptsLeft} /> : null}
        </div>
      ) : (
        <Button variant="secondary" fullWidth onClick={otp.resend}>
          {a('clientAuthOtpResend')}
        </Button>
      )}
    </div>
  )
}
