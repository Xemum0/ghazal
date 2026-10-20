// CL-AUTH-02 WhatsApp code. Requirements: CA-AUTH-05, CA-AUTH-06 (ADR 0012 D4, ADR 0028 item 2).
// A pushed screen, and (params.presentation = 'sheet') the same controller inside a sheet: the booking Details step opens it as
// "Verify number" without leaving the step. Text diet (ADR 0034): a chat drawing, a two-word title, the number as a figure with one
// word to change it, six boxes in LTR order in both languages, a timer figure (Resend at zero), Open WhatsApp, and the interrupted intent
// as a quiet strip. No sentence anywhere: wrong, expired, locked and delivery-failed are a glyph and two or three words, the recovery text
// is behind an info glyph. Five attempts then a lock; no SMS fallback: delivery-failed offers resend, Apple, Google and Support.
// Success draws the seal and continues: a new account goes to name and terms, an existing one straight back to the interrupted intent,
// a password flow back to the password screen.
import { ActionBar, Banner, BarButton, Button, Screen, TopBar, useNav } from '../../../system'
import { useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { AuthHead } from './_components/AuthHead'
import { NumberRow } from './_components/NumberRow'
import { OtpBody, useOtp, verifyingPhone, type OtpView } from './_components/OtpPanel'
import { ResumeStrip, hasResume } from './_components/ResumeStrip'
import { KNOWN_NATIONAL, useAuthFlow, useAuthMoves, userForPhone, useGateReason } from './_components/flow'
import './_components/auth.css'
import './CL-AUTH-02.css'

export const states = ['loading', 'wrong-code', 'expired-code', 'resend-cooldown', 'locked', 'delivery-failed', 'offline', 'success']

const asView = (state: string | undefined): OtpView => (states.includes(state ?? '') ? (state as OtpView) : 'default')

export default function ClAuth02() {
  const t = useT('client-auth')
  const tc = useT('common')
  const { state } = useFrame()
  const { params } = useNav<{ presentation?: 'sheet' }>()
  const sheet = params.presentation === 'sheet'
  const reason = useGateReason()
  const { nav, go, back, finish } = useAuthMoves()
  const phone = useAuthFlow(s => s.phone)
  const purpose = useAuthFlow(s => s.purpose)
  const draftPhone = usePrototype(s => s.bookingDraft.personal.phone)
  const shownPhone = verifyingPhone(sheet ? draftPhone.replace(/\D/g, '').slice(-8) : phone)

  const verified = () => {
    const flow = useAuthFlow.getState()
    if (sheet) {
      nav.closeSheet()
      nav.toast({ message: t('clientAuthOtpSuccessTitle'), tone: 'success' })
    } else if (purpose === 'password-create' || purpose === 'password-reset') {
      flow.setOtpResult(purpose === 'password-create' ? 'create-verified' : 'reset-verified')
      back()
    } else if (flow.phone === '' || flow.phone === KNOWN_NATIONAL) {
      finish(userForPhone(KNOWN_NATIONAL), t('clientAuthSharedSignedIn'))
    } else {
      nav.replace('CL-AUTH-03', { reason })
    }
  }

  const otp = useOtp({ seed: asView(state), onVerified: verified })

  const changeNumber = () => {
    if (sheet) return nav.closeSheet()
    back()
    if (purpose === 'login') nav.openSheet('CL-AUTH-01', { params: { reason } })
  }
  const provider = (p: 'apple' | 'google') => (sheet ? nav.closeSheet() : nav.replace('CL-AUTH-03', { reason, provider: p }))
  const openWhatsapp = () => nav.toast({ message: t('clientAuthOtpOpening'), icon: 'whatsapp' })

  const body = (
    <OtpBody otp={otp} sheet={sheet} onChangeNumber={changeNumber} onOpenWhatsapp={openWhatsapp} onApple={() => provider('apple')} onGoogle={() => provider('google')} />
  )
  const settled = otp.view === 'success'
  // Locked and delivery-failed bring their own drawing (shield, chat): the head then keeps only its title.
  const stateful = otp.view === 'locked' || otp.view === 'delivery-failed'

  if (sheet) {
    const a = otp.action
    return (
      <div className="gza-sheet" data-gz="OtpSheet">
        <div className="gza-sheet__head">
          <h2 className="gza-sheet__title gz-t-d1">{t('clientAuthOtpSheetTitle')}</h2>
          <span className="gza-sheet__close">
            <BarButton icon="close" label={tc('commonActionClose')} onPress={() => nav.closeSheet()} />
          </span>
        </div>
        {settled ? null : <NumberRow phone={shownPhone} onChange={changeNumber} />}
        {body}
        <Button variant="primary" fullWidth loading={a.loading} disabled={a.disabled} onClick={a.onPress}>
          {a.label}
        </Button>
      </div>
    )
  }

  return (
    <Screen top={<TopBar back="auto" onBack={back} />} bottom={<ActionBar action={otp.action} />}>
      {otp.view === 'offline' ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      <div className="gza-body gza02-body">
        <div className="gza02-main">
          {settled ? null : (
            <>
              <AuthHead title={t('clientAuthOtpTitle')} art={stateful ? undefined : 'chat'} />
              <NumberRow phone={shownPhone} onChange={changeNumber} />
            </>
          )}
          {body}
        </div>
        {hasResume(reason) && purpose === 'login' && !settled && !stateful ? <ResumeStrip reason={reason} compact /> : null}
      </div>
    </Screen>
  )
}
