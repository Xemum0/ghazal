// HL-ACCS-04 Account status. Requirements: HA-AUTH-02, HA-AUTH-04 (ADR 0028 D3, ADR 0008 D1).
// A specific, calm screen for every moment the app cannot open normally: venue under review, venue suspended, staff member deactivated,
// session ended by an admin, and a deep link to something the role may not open. Never a dead end: each variant has exactly one next step
// (the gold action) and, on the full-screen variants, a quiet Sign out and, when the account belongs to more than one venue, Switch venue.
// Text diet (ADR 0034): a state composition, not a page of sentences. One drawing per variant (hourglass, warning, key, doorway, shield), a
// title of one or two words, the venue as a quiet line, and the sentence that used to sit under the title behind an info glyph (the recovery
// exception). The support number is no longer on the screen: Contact support shows it (a dialog, as the inventory asks) when the session cannot
// open the Support thread. No red fill.
// Voucher model (ADR 0033): the screen serves hotels, halls and service providers. Under review reads "Your account is under review" and, for a
// service provider, adds that the first listing is reviewed before it goes live (the listing's own wait lives in HL-PROV-06); nothing here
// mentions payouts or bank details.
// States: suspended, deactivated, session-revoked, no-access, offline, under-review-provider (the default frame is the under-review variant).
import type { ReactNode } from 'react'
import { ActionBar, Button, EmptyState, ErrorState, Screen, TopBar, Wordmark, useBi, type IllustrationName } from '../../../system'
import { useT } from '../../../i18n'
import { hotelSettings, partnerFor, personaFor } from '../../../mock'
import { useLang } from '../../../shell/lang'
import { usePrototype } from '../../../shell/state'
import { StateNote } from './_components'
import { SwitchVenueSheet } from './_components/SwitchVenueSheet'
import { demoStaff, useAccessFlow, useAccessMoves, useScreenState, venueOf } from './_components/flow'
import { useContactAdmin, useSupport } from './_components/support'
import './_components/access.css'
import './HL-ACCS-04.css'

export const states = ['suspended', 'deactivated', 'session-revoked', 'no-access', 'offline', 'under-review-provider']

type Variant = 'under-review' | 'suspended' | 'deactivated' | 'session-revoked' | 'no-access'

const VARIANTS: readonly string[] = ['under-review', 'suspended', 'deactivated', 'session-revoked', 'no-access']

const ART: Record<Variant, IllustrationName> = {
  'under-review': 'hourglass',
  suspended: 'warning',
  deactivated: 'key',
  'session-revoked': 'doorway',
  'no-access': 'shield',
}

export default function HlAccs04() {
  const t = useT('hotel-access')
  const tc = useT('common')
  const bi = useBi()
  const { lang } = useLang()
  const state = useScreenState()
  const { nav, finish, toSignIn } = useAccessMoves()
  const params = nav.params as { variant?: Variant; account?: 'provider' | 'hotel' }
  const flowProvider = useAccessFlow(s => s.provider)
  const offline = state === 'offline'
  const variant: Variant = state === 'under-review-provider' ? 'under-review' : VARIANTS.includes(state ?? '') ? (state as Variant) : (params.variant ?? 'under-review')
  // The service-provider partner (Zahra Floral Studio) sees her own business, never the hotel's name.
  const provider = state === 'under-review-provider' || params.account === 'provider' || flowProvider
  const persona = provider ? personaFor('service_provider') : undefined
  const venue = venueOf()
  const venueName = provider ? bi(partnerFor(persona?.partnerAccountId ?? '')?.name ?? { en: '', ar: '' }) : venue ? bi(venue.name) : ''
  const staff = demoStaff()
  const support = useSupport()
  const contactAdmin = useContactAdmin()
  // The account belongs to more than one venue when the seed names a sister venue (HA-AUTH-03).
  const multiVenue = !provider && Boolean(hotelSettings.sister)
  const fullScreen = variant !== 'no-access'
  const venueVariant = variant === 'under-review' || variant === 'suspended' || variant === 'deactivated'

  const title: Record<Exclude<Variant, 'no-access'>, string> = {
    'under-review': t('hotelAccessStatusUnderReviewTitle'),
    suspended: t('hotelAccessStatusSuspendedTitle'),
    deactivated: t('hotelAccessStatusDeactivatedTitle'),
    'session-revoked': t('hotelAccessStatusRevokedTitle'),
  }
  // The sentence behind the info glyph. A provider's first listing is reviewed before it goes live: that sentence rides with the under-review one.
  const detail: Record<Exclude<Variant, 'no-access'>, ReactNode> = {
    'under-review': (
      <>
        <p>{t('hotelAccessStatusUnderReviewBody')}</p>
        {provider ? <p>{t('hotelAccessStatusUnderReviewProviderNote')}</p> : null}
      </>
    ),
    suspended: t('hotelAccessStatusSuspendedBody'),
    deactivated: t('hotelAccessStatusDeactivatedBody'),
    'session-revoked': t('hotelAccessStatusRevokedBody'),
  }

  const signOut = () => {
    usePrototype.getState().signOut()
    toSignIn()
  }
  const switchVenue = () => {
    const key = nav.openSheet(
      <SwitchVenueSheet
        variant={variant}
        onPick={() => {
          nav.closeSheet(key)
          if (staff) finish(staff)
        }}
      />,
      { title: t('hotelAccessStatusSwitchVenue') },
    )
  }

  const primary = (() => {
    switch (variant) {
      case 'under-review':
      case 'suspended':
        return { label: t('hotelAccessSupportAction'), onPress: support }
      case 'deactivated':
        return { label: t('hotelAccessAdminAction'), onPress: contactAdmin }
      case 'session-revoked':
        return { label: t('hotelAccessSigninSubmit'), onPress: signOut }
      case 'no-access':
        return { label: tc('commonLabelToday'), iconEnd: 'arrow-right' as const, onPress: () => nav.reset('HL-TODY-01') }
    }
  })()

  const quiet = fullScreen ? (
    <span className="hxa04__quiet">
      {variant !== 'session-revoked' && multiVenue ? (
        <Button variant="tertiary" onClick={switchVenue}>
          {t('hotelAccessStatusSwitchVenue')}
        </Button>
      ) : null}
      {variant !== 'session-revoked' ? (
        <Button variant="tertiary" onClick={signOut}>
          {t('hotelAccessStatusSignOut')}
        </Button>
      ) : null}
    </span>
  ) : undefined

  return (
    <Screen top={fullScreen ? undefined : <TopBar back />} bottom={<ActionBar action={primary} note={quiet} />}>
      <div className="hxa04" data-gz="AccountStatus" data-variant={variant} data-fullscreen={fullScreen || undefined}>
        {fullScreen ? (
          <header className="hxa04__brand">
            <Wordmark size="md" script={lang === 'ar' ? 'arabic' : 'latin'} />
          </header>
        ) : null}

        {offline ? <StateNote tone="offline">{tc('commonStateOffline')}</StateNote> : null}

        <div className="hxa04__main" data-gz-id="status.state">
          {variant === 'no-access' ? (
            <ErrorState kind="no-access" body={t('hotelAccessStatusNoAccessBody')} />
          ) : (
            <EmptyState
              illustration={ART[variant]}
              title={title[variant]}
              body={venueVariant && venueName ? venueName : undefined}
              detail={detail[variant]}
              detailTitle={title[variant]}
              size="hero"
            />
          )}
        </div>
      </div>
    </Screen>
  )
}
