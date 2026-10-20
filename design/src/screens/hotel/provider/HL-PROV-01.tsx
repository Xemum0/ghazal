// HL-PROV-01 Choose your account type: first-run onboarding of a new partner. Hotel or wedding hall, or Service provider; then the profile
// (business name in Arabic and English, categories for a provider, venue type and area for a venue, contact phone) and a submit that puts the
// account under review. The first listing is reviewed again before it goes live. Fee exemption is never chosen here: Ghazal sets it.
// Requirements: PA-ACC-01, PA-ACC-02, PA-ACC-03, PA-REV-01
// States: venue-profile, provider-profile, categories, submitted-under-review, validation, loading, error, offline (the default frame is the chooser)
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import { areasByGovernorate, governorates, personaFor } from '../../../mock'
import type { ServiceCategoryId } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { ActionBar, Avatar, Button, ChipGroup, ErrorState, Icon, Illustration, PhoneField, Screen, SelectRow, Skeleton, ThreadBead, TopBar, useNav } from '../../../system'
import { BilingualField, FieldError } from './_components/fields'
import { Note, OfflineStrip, StaticSheet, useBi, useLive, useP } from './_components/bits'
import { CategorySheet } from './_components/CategorySheet'
import { categoryIcon, categoryOptions } from './_components/model'
import { useProv } from './_components/store'
import './HL-PROV-01.css'

export const states = ['venue-profile', 'provider-profile', 'categories', 'submitted-under-review', 'validation', 'loading', 'error', 'offline']

type Kind = 'venue' | 'service_provider'
type Step = 'choose' | 'profile' | 'submitted'
type Profile = { nameAr: string; nameEn: string; cats: ServiceCategoryId[]; venueType: 'private-hall' | 'hotel' | null; gov: string | null; area: string | null; phone: string }

const PERSONA = personaFor('service_provider')
const PHONE = (PERSONA?.phone ?? '+96550000047').replace('+965', '')
const DEMO_PROVIDER: Profile = { nameAr: 'استوديو زهرة للزهور', nameEn: 'Zahra Floral Studio', cats: ['flowers'], venueType: null, gov: null, area: null, phone: PHONE }
const DEMO_VENUE: Profile = { nameAr: 'فندق لومي مارينا', nameEn: 'Lumi Marina Hotel', cats: [], venueType: 'hotel', gov: governorates[0]?.id ?? null, area: areasByGovernorate()[0]?.areas[0]?.id ?? null, phone: PHONE }
const BLANK: Profile = { nameAr: '', nameEn: '', cats: [], venueType: null, gov: null, area: null, phone: '' }

const CHOICES: { kind: Kind; icon: IconName; title: 'hotelProviderTypeHotelTitle' | 'hotelProviderTypeProviderTitle'; facts: IconName[] }[] = [
  { kind: 'venue', icon: 'hotel', title: 'hotelProviderTypeHotelTitle', facts: ['calendar', 'chat', 'ticket'] },
  { kind: 'service_provider', icon: 'megaphone', title: 'hotelProviderTypeProviderTitle', facts: ['catering', 'flower', 'camera'] },
]

export default function AccountType() {
  const { state } = useFrame()
  const nav = useNav()
  const bi = useBi()
  const { t } = useP()
  const live = useLive()
  const setViewer = useProv(s => s.setViewer)

  const frameKind: Kind | null = state === 'venue-profile' ? 'venue' : state === 'provider-profile' || state === 'categories' || state === 'validation' || state === 'submitted-under-review' || state === 'loading' || state === 'error' || state === 'offline' ? 'service_provider' : null
  const frameStep: Step = state === 'submitted-under-review' ? 'submitted' : frameKind ? 'profile' : 'choose'
  const [kind, setKind] = useState<Kind | null>(frameKind)
  const [step, setStep] = useState<Step>(frameStep)
  const [p, setP] = useState<Profile>(state === 'validation' ? BLANK : state === 'venue-profile' ? DEMO_VENUE : state ? DEMO_PROVIDER : BLANK)
  const [tried, setTried] = useState(state === 'validation')
  const [failed, setFailed] = useState(state === 'error')
  const patch = (x: Partial<Profile>) => setP(s => ({ ...s, ...x }))
  const offline = state === 'offline'
  const loading = state === 'loading'

  const isVenue = kind === 'venue'
  const missing = {
    nameAr: p.nameAr.trim() === '',
    nameEn: p.nameEn.trim() === '',
    cats: !isVenue && p.cats.length === 0,
    type: isVenue && p.venueType === null,
    area: isVenue && (!p.gov || !p.area),
    phone: p.phone.length !== 8,
  }
  const incomplete = Object.values(missing).some(Boolean)
  const required = t('hotelProviderRequired')

  const submit = () => {
    setTried(true)
    if (incomplete) return
    if (live) setViewer(isVenue ? 'hotel' : 'provider')
    setStep('submitted')
  }

  const chooseCategories = () => {
    const key = nav.openSheet(
      <CategorySheet title={t('hotelProviderProfileCategories')} max={3} value={p.cats} onClose={() => nav.closeSheet(key)} onApply={v => { patch({ cats: v }); nav.closeSheet(key) }} />,
      {},
    )
  }

  const top = (
    <>
      <TopBar
        title={step === 'choose' ? undefined : t(step === 'submitted' ? 'hotelProviderSubmittedBar' : isVenue ? 'hotelProviderTypeHotelTitle' : 'hotelProviderTypeProviderTitle')}
        back={step === 'submitted' ? false : 'auto'}
        onBack={step === 'profile' ? () => setStep('choose') : undefined}
      />
      {offline ? <OfflineStrip /> : null}
    </>
  )

  let bottom
  let body
  if (step === 'choose') {
    bottom = <ActionBar action={{ label: t('hotelProviderContinue'), iconEnd: 'chevron-right', disabled: kind === null, reason: kind === null ? t('hotelProviderChooseReason') : undefined, onPress: () => setStep('profile') }} />
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
      </div>
    )
  } else if (step === 'submitted') {
    bottom = (
      <ActionBar
        action={
          isVenue
            ? { label: t('hotelProviderSubmittedToday'), iconEnd: 'chevron-right', onPress: () => nav.reset('HL-TODY-01') }
            : { label: t('hotelProviderSubmittedFirst'), iconEnd: 'chevron-right', onPress: () => nav.push('HL-PROV-03', { account: 'provider' }) }
        }
        note={
          <span className="hp01__quiet">
            <Button variant="tertiary" onClick={() => nav.push('HL-ACCS-04', { variant: 'under-review' })}>
              {t('hotelProviderSubmittedStatus')}
            </Button>
            {!isVenue ? (
              <Button variant="tertiary" onClick={() => nav.reset('HL-TODY-01')}>
                {t('hotelProviderSubmittedToday')}
              </Button>
            ) : null}
          </span>
        }
      />
    )
    body = (
      <div className="hp01">
        <header className="hp01__head">
          <Illustration name="partner-review" size="hero" />
          <h1 className="gz-t-ui-xl hp01__title">{t('hotelProviderSubmittedTitle')}</h1>
        </header>
        <div className="hp01__who">
          <Avatar name={p.nameEn || p.nameAr} initial={Array.from((p.nameEn || p.nameAr).trim())[0]} voice="sans" size="md" />
          <span className="hp01__whotext">
            <span className="gz-t-title hp01__whoname" dir="auto">{bi({ en: p.nameEn, ar: p.nameAr })}</span>
            <Icon name={isVenue ? 'hotel' : 'megaphone'} size="sm" tone="secondary" />
          </span>
        </div>
      </div>
    )
  } else if (loading) {
    body = (
      <div className="hp01" aria-busy="true">
        <Skeleton variant="line" blockSize={28} inlineSize={180} />
        <Skeleton variant="block" blockSize={56} />
        <Skeleton variant="block" blockSize={56} />
        <Skeleton variant="block" blockSize={56} />
      </div>
    )
  } else {
    bottom = (
      <ActionBar
        action={{ label: t('hotelProviderSubmit'), iconEnd: 'check', loading: false, disabled: offline, reason: offline ? t('hotelProviderNeedsConnection') : undefined, onPress: submit }}
      />
    )
    const cats = categoryOptions()
    body = (
      <div className="hp01">
        {failed ? <Note tone="danger" action={{ label: t('hotelProviderRetryShort'), onPress: () => setFailed(false) }}>{t('hotelProviderSubmitErrorTitle')}</Note> : null}
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
        {isVenue ? (
          <>
            <div className="hp01__group">
              <ChipGroup<'private-hall' | 'hotel'>
                label={t('hotelProviderProfileVenueType')}
                value={p.venueType}
                onChange={v => patch({ venueType: v })}
                options={[
                  { value: 'private-hall', label: t('hotelProviderVenueTypeHall') },
                  { value: 'hotel', label: t('hotelProviderVenueTypeHotel') },
                ]}
              />
              {tried && missing.type ? <FieldError>{required}</FieldError> : null}
            </div>
            <SelectRow<string>
              label={t('hotelProviderProfileGovernorate')}
              sheetTitle={t('hotelProviderProfileGovernorate')}
              placeholder={t('hotelProviderProfileChoose')}
              options={governorates.map(g => ({ value: g.id, label: bi(g.name) }))}
              value={p.gov}
              onChange={v => patch({ gov: v, area: null })}
              error={tried && !p.gov ? required : undefined}
            />
            <SelectRow<string>
              label={t('hotelProviderProfileArea')}
              sheetTitle={t('hotelProviderProfileArea')}
              placeholder={t('hotelProviderProfileChoose')}
              searchable
              options={(areasByGovernorate().find(g => g.governorate.id === p.gov)?.areas ?? []).map(a => ({ value: a.id, label: bi(a.name) }))}
              value={p.area}
              onChange={v => patch({ area: v })}
              disabled={!p.gov}
              error={tried && p.gov && !p.area ? required : undefined}
            />
          </>
        ) : (
          <div className="hp01__group">
            <span className="gz-t-label hp01__label">{t('hotelProviderProfileCategories')}</span>
            <div className="hp01__cats">
              {p.cats.map(id => (
                <span key={id} className="gz-t-body-s hp01__cat">
                  <Icon name={categoryIcon(cats.find(c => c.id === id)?.icon ?? 'flower')} size="xs" />
                  {bi(cats.find(c => c.id === id)?.name ?? { en: '', ar: '' })}
                </span>
              ))}
            </div>
            <Button variant="secondary" iconStart={p.cats.length ? 'edit' : 'plus'} onClick={chooseCategories}>
              {t(p.cats.length ? 'hotelProviderCatsEdit' : 'hotelProviderCatsChoose')}
            </Button>
            {tried && missing.cats ? <FieldError>{required}</FieldError> : null}
          </div>
        )}
        <PhoneField label={t('hotelProviderProfilePhone')} value={p.phone} onChange={n => patch({ phone: n })} error={tried && missing.phone ? t('hotelProviderPhoneError') : undefined} />
        {!isVenue ? (
          <div className="hp01__logo">
            <Avatar name={p.nameEn || p.nameAr || '·'} initial={Array.from((p.nameEn || p.nameAr || '·').trim())[0]} voice="sans" size="md" />
            <span className="hp01__logotext">
              <span className="gz-t-title">{t('hotelProviderLogoTitle')}</span>
            </span>
            <Button variant="tertiary" onClick={() => nav.toast({ message: t('hotelProviderLogoToast'), icon: 'info' })}>
              {t('hotelProviderLogoUpload')}
            </Button>
          </div>
        ) : null}
      </div>
    )
  }

  if (state === 'error') {
    body = <ErrorState kind="generic" title={t('hotelProviderSubmitErrorTitle')} body={t('hotelProviderSubmitError')} onRetry={() => nav.replace('HL-PROV-01', nav.params)} />
    bottom = undefined
  }

  return (
    <>
      <Screen top={top} bottom={bottom}>
        {body}
      </Screen>
      {state === 'categories' ? (
        <StaticSheet label={t('hotelProviderProfileCategories')}>
          <CategorySheet title={t('hotelProviderProfileCategories')} max={3} value={p.cats} onApply={() => undefined} />
        </StaticSheet>
      ) : null}
    </>
  )
}
