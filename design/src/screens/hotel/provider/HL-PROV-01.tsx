// HL-PROV-01 Apply to join: the application form of a service provider or a private hall (PA-ACC-07, PA-ACC-08, ADR 0038). Two steps and a result:
// the account type (Service provider or Private hall; a hotel or a hall chain is onboarded by Ghazal as before), the form (business name in
// Arabic and English, up to three registered categories plus an open "Other" note for a provider, governorate, contact person, phone, email,
// a short description, an optional commercial licence reference), and "Application received": the account stays under review, Ghazal staff
// accept or reject it (HL-ACCS-04 shows the wait and the decision), and only an accepted account creates listings. A rejected application comes
// back here through "Edit and resubmit", prefilled, with the reason on top. Fee exemption is never chosen here: Ghazal sets it.
// Signed out (round 2b: HL-ACCS-01 "Apply to join" opens it with `signedOut`): the form also makes the account. A first section "Your account"
// (email, password with its strength thread, repeat password) comes before "Your business"; the email is also the contact email, so the business
// section does not ask for it twice. Account errors: email already registered, password too weak, passwords differ. Submit holds the form as
// pending and opens the email code (HL-ACCS-02, mode `application`); the right code creates the application and lands on HL-ACCS-04 (in review).
// A signed-in partner (a rejected applicant resubmitting, an account adding a type) never sees the account section. Back from the first step
// returns to HL-ACCS-01.
// Requirements: PA-ACC-01, PA-ACC-02, PA-ACC-03, PA-ACC-07, PA-ACC-08, PA-REV-01
// States: empty, hall, filled, categories, validation, submitting, submitted, resubmit, error, offline, signed-out, account-errors (the default frame is the account type)
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import { governorates } from '../../../mock'
import type { ServiceCategoryId } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { useLang } from '../../../shell/lang'
import { useT } from '../../../i18n'
import { ActionBar, Avatar, Button, ChipGroup, Icon, IconListRow, Illustration, PhoneField, Screen, TextArea, TextField, ThreadBead, TopBar, useNav } from '../../../system'
import { PasswordField } from '../access/_components/PasswordField'
import { PasswordRules, checkPassword } from '../access/_components/PasswordRules'
import { isEmailTaken, useAccessFlow } from '../access/_components/flow'
import { BilingualField, FieldError } from './_components/fields'
import { Note, OfflineStrip, StaticSheet, useAfter, useBi, useLive, useP } from './_components/bits'
import { CategorySheet } from './_components/CategorySheet'
import { ABOUT_MAX, BLANK_FORM, MAX_CATEGORIES, demoHallForm, demoProviderForm, isComplete, missingOf, nameOfForm, useApplication, type ApplicantKind, type ApplicationForm } from './_components/application'
import { categoryIcon, categoryOptions } from './_components/model'
import { useProv } from './_components/store'
import './HL-PROV-01.css'

export const states = ['empty', 'hall', 'filled', 'categories', 'validation', 'submitting', 'submitted', 'resubmit', 'error', 'offline', 'signed-out', 'account-errors']

/** Frames that draw the signed-out form (the account section on top). */
const SIGNED_OUT_FRAMES: readonly string[] = ['signed-out', 'account-errors']
/** The weak, mistyped password of the account-errors frame. */
const DEMO_WEAK = '123456'
const DEMO_OTHER = '123457'

type Step = 'choose' | 'form' | 'submitted'

const CHOICES: { kind: ApplicantKind; icon: IconName; title: 'hotelProviderTypeProviderTitle' | 'hotelProviderTypeHallTitle'; facts: IconName[] }[] = [
  { kind: 'service_provider', icon: 'megaphone', title: 'hotelProviderTypeProviderTitle', facts: ['catering', 'flower', 'camera'] },
  { kind: 'private_hall', icon: 'hall', title: 'hotelProviderTypeHallTitle', facts: ['calendar', 'chat', 'ticket'] },
]

export default function ApplyToJoin() {
  const { state } = useFrame()
  const { lang } = useLang()
  const nav = useNav()
  const bi = useBi()
  const { t } = useP()
  const ta = useT('hotel-access')
  const live = useLive()
  const setViewer = useProv(s => s.setViewer)
  const app = useApplication()
  // Signed out: the sign-in screen opened the form for a new applicant. A frame names it with `?state=signed-out`.
  const signedOut = state === undefined ? nav.params.signedOut === true : SIGNED_OUT_FRAMES.includes(state)

  // A rejected application comes back here prefilled (HL-ACCS-04 "Edit and resubmit").
  const resubmit = state === 'resubmit' || (state === undefined && nav.params.resubmit === true && app.form !== null)
  const frameForm: ApplicationForm | null =
    state === 'hall' ? demoHallForm(lang) : state === 'validation' || state === 'empty' || state === 'signed-out' ? BLANK_FORM : state === 'account-errors' || state === 'resubmit' || state === 'filled' || state === 'categories' || state === 'submitting' || state === 'submitted' || state === 'error' || state === 'offline' ? demoProviderForm(lang) : null
  const initialForm: ApplicationForm | null = frameForm ?? (resubmit ? app.form : null)

  const [step, setStep] = useState<Step>(state === 'submitted' ? 'submitted' : initialForm ? 'form' : 'choose')
  const [kind, setKind] = useState<ApplicantKind | null>(initialForm?.kind ?? null)
  const [p, setP] = useState<ApplicationForm>(initialForm ?? BLANK_FORM)
  const [tried, setTried] = useState(state === 'validation' || state === 'account-errors')
  // The account (signed out only): the email is the form's own `email`; the two passwords are never stored with the application.
  const [password, setPassword] = useState(state === 'account-errors' ? DEMO_WEAK : '')
  const [repeat, setRepeat] = useState(state === 'account-errors' ? DEMO_OTHER : '')
  const [busy, setBusy] = useState(state === 'submitting')
  const [failed, setFailed] = useState(state === 'error')
  const patch = (x: Partial<ApplicationForm>) => setP(s => ({ ...s, ...x }))
  const offline = state === 'offline'

  const isHall = p.kind === 'private_hall'
  const missing = missingOf(p)
  const check = checkPassword(password, '')
  const account = {
    emailTaken: signedOut && !missing.email && isEmailTaken(p.email),
    weak: signedOut && !(check.length && check.mix),
    differ: signedOut && repeat !== password,
  }
  const accountBad = account.emailTaken || account.weak || account.differ
  const incomplete = Object.values(missing).some(Boolean) || accountBad
  const required = t('hotelProviderRequired')

  const send = () => {
    setTried(true)
    setFailed(false)
    if (!isComplete(p) || accountBad) return
    setBusy(true)
  }
  // The round trip is simulated in the live player only: a static frame holds still.
  useAfter(
    700,
    () => {
      setViewer(isHall ? 'hotel' : 'provider')
      setBusy(false)
      if (signedOut) {
        // The account exists, its email is not verified yet: the code screen follows, and only the right code makes the application (HL-ACCS-02).
        const flow = useAccessFlow.getState()
        useApplication.getState().setPending(p)
        flow.setEmail(p.email.trim())
        flow.setStaffId(null)
        flow.setProvider(true)
        flow.setFailed(0)
        nav.push('HL-ACCS-02', { mode: 'application' })
        return
      }
      useApplication.getState().submit(p)
      setStep('submitted')
    },
    busy,
  )

  const chooseCategories = () => {
    const key = nav.openSheet(
      <CategorySheet title={t('hotelProviderProfileCategories')} max={MAX_CATEGORIES} value={p.cats} onClose={() => nav.closeSheet(key)} onApply={v => { patch({ cats: v }); nav.closeSheet(key) }} />,
      {},
    )
  }

  const barTitle = step === 'submitted' ? t('hotelProviderSubmittedBar') : resubmit ? t('hotelProviderFormBarEdit') : t(isHall ? 'hotelProviderTypeHallTitle' : 'hotelProviderTypeProviderTitle')
  const top = (
    <>
      <TopBar
        title={step === 'choose' ? undefined : barTitle}
        back={step === 'submitted' ? false : 'auto'}
        onBack={step === 'form' && !resubmit ? () => setStep('choose') : undefined}
      />
      {offline ? <OfflineStrip /> : null}
    </>
  )

  let bottom
  let body
  if (step === 'choose') {
    bottom = (
      <ActionBar
        action={{
          label: t('hotelProviderContinue'),
          iconEnd: 'chevron-right',
          disabled: kind === null,
          reason: kind === null ? t('hotelProviderChooseReason') : undefined,
          onPress: () => {
            if (kind) patch({ kind })
            setStep('form')
          },
        }}
      />
    )
    body = (
      <div className="hp01">
        <header className="hp01__head">
          <h1 className="gz-t-ui-xl hp01__title">{t('hotelProviderChooseTitle')}</h1>
        </header>
        <div className="hp01__cards" role="radiogroup" aria-label={t('hotelProviderChooseTitle')}>
          {CHOICES.map(c => (
            <button key={c.kind} type="button" role="radio" aria-checked={kind === c.kind} className="gz-reset gz-press hp01__card" data-selected={kind === c.kind || undefined} onClick={() => setKind(c.kind)}>
              <span className="hp01__cardhead">
                <span className="hp01__disk">
                  <Icon name={c.icon} size="md" />
                </span>
                <span className="gz-t-title hp01__cardtitle">{t(c.title)}</span>
                <span className="hp01__radio" aria-hidden="true">
                  <ThreadBead tone={kind === c.kind ? 'gold' : 'hollow'} />
                </span>
              </span>
              <span className="hp01__facts" aria-hidden="true">
                {c.facts.map(k => (
                  <Icon key={k} name={k} size="md" tone="secondary" />
                ))}
              </span>
            </button>
          ))}
        </div>
        <Note tone="quiet" icon="hotel">
          {t('hotelProviderChooseChains')}
        </Note>
      </div>
    )
  } else if (step === 'submitted') {
    bottom = (
      <ActionBar
        action={{
          label: t('hotelProviderSubmittedStatus'),
          iconEnd: 'chevron-right',
          onPress: () => nav.reset('HL-ACCS-04', { variant: 'application-review', account: isHall ? 'hotel' : 'provider' }),
        }}
      />
    )
    body = (
      <div className="hp01">
        <header className="hp01__head">
          <Illustration name="partner-review" size="lg" />
          <h1 className="gz-t-ui-xl hp01__title">{t('hotelProviderSubmittedTitle')}</h1>
          <p className="gz-t-body hp01__line">{t('hotelProviderSubmittedLine')}</p>
        </header>
        <div className="hp01__who">
          <Avatar name={bi(nameOfForm(p))} initial={Array.from(bi(nameOfForm(p)).trim())[0]} voice="sans" size="md" />
          <span className="hp01__whotext">
            <span className="gz-t-title hp01__whoname" dir="auto">{bi(nameOfForm(p))}</span>
          </span>
          <Icon name={isHall ? 'hall' : 'megaphone'} size="md" tone="secondary" />
        </div>
        <section className="hp01__next" aria-label={t('hotelProviderSubmittedNext')}>
          <h2 className="gz-t-label hp01__label">{t('hotelProviderSubmittedNext')}</h2>
          <IconListRow flush icon="clipboard" title={t('hotelProviderNextReview')} />
          <IconListRow flush icon="mail" title={t('hotelProviderNextEmail')} />
          <IconListRow flush last icon="megaphone" title={t('hotelProviderNextListings')} />
        </section>
      </div>
    )
  } else {
    bottom = (
      <ActionBar
        action={{ label: t('hotelProviderSubmit'), iconEnd: 'check', loading: busy, disabled: offline, reason: offline ? t('hotelProviderNeedsConnection') : undefined, onPress: send }}
      />
    )
    const cats = categoryOptions()
    body = (
      <div className="hp01" aria-busy={busy || undefined}>
        {failed ? (
          <Note tone="danger" action={{ label: t('hotelProviderRetryShort'), onPress: send }}>
            {t('hotelProviderSubmitError')}
          </Note>
        ) : null}
        {resubmit ? <Note tone="danger">{t('hotelProviderFormResubmitNote', { note: app.note || t('hotelProviderAppDemoNote') })}</Note> : null}
        {tried && incomplete ? <Note tone="danger">{t('hotelProviderFormFix')}</Note> : null}
        {signedOut ? (
          <section className="hp01__section" data-gz-id="account" aria-labelledby="hp01-account">
            <h2 id="hp01-account" className="gz-t-title hp01__h">
              {t('hotelProviderFormAccountTitle')}
            </h2>
            <TextField
              label={t('hotelProviderFormEmail')}
              dir="ltr"
              inputMode="email"
              autoComplete="username"
              autoCapitalize="none"
              autoCorrect="off"
              startAdornment={<Icon name="mail" size="sm" tone="secondary" />}
              value={p.email}
              onValueChange={email => patch({ email })}
              error={tried && missing.email ? t('hotelProviderFormEmailError') : tried && account.emailTaken ? t('hotelProviderAccountEmailUsed') : undefined}
            />
            <PasswordField
              label={ta('hotelAccessSetupPasswordLabel')}
              showLabel
              autoComplete="new-password"
              value={password}
              onValueChange={setPassword}
              error={tried && account.weak ? t('hotelProviderAccountPasswordWeak') : undefined}
            />
            <PasswordRules check={password.length > 0 ? check : { length: false, mix: false, score: 0 }} />
            <PasswordField
              label={t('hotelProviderAccountRepeat')}
              showLabel
              autoComplete="new-password"
              value={repeat}
              onValueChange={setRepeat}
              error={account.differ && (repeat.length > 0 || tried) ? ta('hotelAccessSetupMismatch') : undefined}
            />
          </section>
        ) : null}
        {signedOut ? (
          <h2 className="gz-t-title hp01__h hp01__h--business">{t('hotelProviderFormBusinessTitle')}</h2>
        ) : null}
        <BilingualField
          label={t('hotelProviderProfileName')}
          ar={p.nameAr}
          en={p.nameEn}
          onAr={nameAr => patch({ nameAr })}
          onEn={nameEn => patch({ nameEn })}
          errorAr={tried && missing.nameAr ? required : undefined}
          errorEn={tried && missing.nameEn ? required : undefined}
          maxLength={60}
        />
        {!isHall ? (
          <div className="hp01__group">
            <span className="gz-t-label hp01__label">{t('hotelProviderProfileCategories')}</span>
            {p.cats.length > 0 ? (
              <div className="hp01__cats">
                {p.cats.map(id => (
                  <span key={id} className="gz-t-body-s hp01__cat">
                    <Icon name={categoryIcon(cats.find(c => c.id === id)?.icon ?? 'flower')} size="xs" />
                    {bi(cats.find(c => c.id === id)?.name ?? { en: '', ar: '' })}
                  </span>
                ))}
              </div>
            ) : null}
            <span className="hp01__start">
              <Button variant="secondary" iconStart={p.cats.length ? 'edit' : 'plus'} onClick={chooseCategories}>
                {t(p.cats.length ? 'hotelProviderCatsEdit' : 'hotelProviderCatsChoose')}
              </Button>
            </span>
            <TextField label={t('hotelProviderFormOther')} helper={t('hotelProviderFormOtherHelper')} maxLength={60} value={p.otherNote} onValueChange={otherNote => patch({ otherNote })} />
            {tried && missing.cats ? <FieldError>{required}</FieldError> : null}
          </div>
        ) : null}
        <div className="hp01__group">
          <span className="gz-t-label hp01__label">{t('hotelProviderProfileGovernorate')}</span>
          <ChipGroup<string>
            label={t('hotelProviderProfileGovernorate')}
            layout="wrap"
            value={p.gov}
            onChange={gov => patch({ gov })}
            options={governorates.map(g => ({ value: g.id, label: bi(g.name) }))}
          />
          {tried && missing.gov ? <FieldError>{required}</FieldError> : null}
        </div>
        <TextField label={t('hotelProviderFormContact')} maxLength={60} value={p.contact} onValueChange={contact => patch({ contact })} error={tried && missing.contact ? required : undefined} />
        <PhoneField label={t('hotelProviderProfilePhone')} value={p.phone} onChange={n => patch({ phone: n })} error={tried && missing.phone ? t('hotelProviderPhoneError') : undefined} />
        {signedOut ? null : (
          <TextField
            label={t('hotelProviderFormEmail')}
            dir="ltr"
            inputMode="email"
            autoComplete="email"
            value={p.email}
            onValueChange={email => patch({ email })}
            error={tried && missing.email ? t('hotelProviderFormEmailError') : undefined}
          />
        )}
        <TextArea label={t('hotelProviderFormAbout')} rows={3} maxLength={ABOUT_MAX} value={p.about} onValueChange={about => patch({ about })} error={tried && missing.about ? required : undefined} />
        <TextField label={t('hotelProviderFormLicence')} optional dir="ltr" maxLength={40} value={p.licence} onValueChange={licence => patch({ licence })} />
      </div>
    )
  }

  return (
    <>
      <Screen top={top} bottom={bottom}>
        {body}
      </Screen>
      {state === 'categories' ? (
        <StaticSheet label={t('hotelProviderProfileCategories')}>
          <CategorySheet title={t('hotelProviderProfileCategories')} max={MAX_CATEGORIES} value={p.cats as ServiceCategoryId[]} onApply={() => undefined} />
        </StaticSheet>
      ) : null}
    </>
  )
}
