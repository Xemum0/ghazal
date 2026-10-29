// HL-ACCS-04 Account status. Requirements: HA-AUTH-02, HA-AUTH-04 (ADR 0028 D3, ADR 0008 D1).
// A specific, calm screen for every moment the app cannot open normally: venue under review, venue suspended, staff member deactivated,
// session ended by an admin, and a deep link to something the role may not open. Never a dead end: each variant has exactly one next step
// (the gold action) and, on the full-screen variants, a quiet Sign out and, when the account belongs to more than one venue, Switch venue.
// Text diet (ADR 0034): a state composition, not a page of sentences. One drawing per variant (hourglass, warning, key, doorway, shield), a
// title of one or two words, the venue as a quiet line, and the sentence that used to sit under the title behind an info glyph (the recovery
// exception). The support number is no longer on the screen: Contact support shows it (a dialog, as the inventory asks) when the session cannot
// open the Support thread. No red fill.
// Voucher model (ADR 0033): the screen serves hotels, halls and service providers; nothing here mentions payouts or bank details.
// Partner application (PA-ACC-07, ADR 0038): a service provider or a private hall waits here after sending the form of HL-PROV-01. Three
// variants follow the application: in review (the wait; in the live player a prototype-only tray plays the Ghazal staff decision, the same
// pattern as the moderator tray of HL-PROV-06), not approved (the reasons and the staff note, and "Edit and resubmit" back to the prefilled
// form) and approved (continue to Today as any accepted account). Only an accepted account creates listings (HL-PROV-03 holds the editor back).
// States: suspended, deactivated, session-revoked, no-access, offline, application-review, application-rejected, application-approved
// (the default frame is the venue under-review variant).
import type { ReactNode } from 'react'
import { ActionBar, Button, EmptyState, ErrorState, Screen, Tag, TopBar, Wordmark, useBi, type IllustrationName } from '../../../system'
import { useT } from '../../../i18n'
import { hotelSettings, partnerFor, personaFor } from '../../../mock'
import { useLang } from '../../../shell/lang'
import { usePrototype } from '../../../shell/state'
import { UserText } from '../provider/_components/bits'
import { DEMO_REASONS, demoHallForm, demoProviderForm, nameOfForm, useApplication, type ApplicationReason } from '../provider/_components/application'
import { StateNote } from './_components'
import { SwitchVenueSheet, type StatusVariant } from './_components/SwitchVenueSheet'
import { demoStaff, useAccessFlow, useAccessMoves, useLive, useScreenState, venueOf } from './_components/flow'
import { useContactAdmin, useSupport } from './_components/support'
import './_components/access.css'
import './HL-ACCS-04.css'

export const states = ['suspended', 'deactivated', 'session-revoked', 'no-access', 'offline', 'application-review', 'application-rejected', 'application-approved']

type Variant = 'under-review' | 'application-review' | 'application-rejected' | 'application-approved' | 'suspended' | 'deactivated' | 'session-revoked' | 'no-access'

const VARIANTS: readonly string[] = ['under-review', 'application-review', 'application-rejected', 'application-approved', 'suspended', 'deactivated', 'session-revoked', 'no-access']

const ART: Record<Variant, IllustrationName> = {
  'under-review': 'hourglass',
  'application-review': 'hourglass',
  'application-rejected': 'warning',
  'application-approved': 'seal',
  suspended: 'warning',
  deactivated: 'key',
  'session-revoked': 'doorway',
  'no-access': 'shield',
}

const REASON = {
  missing_details: 'hotelProviderReasonMissing',
  cannot_verify: 'hotelProviderAppReasonVerify',
  category_unavailable: 'hotelProviderReasonCategory',
} as const satisfies Record<ApplicationReason, string>

export default function HlAccs04() {
  const t = useT('hotel-access')
  const tp = useT('hotel-provider')
  const tc = useT('common')
  const bi = useBi()
  const { lang } = useLang()
  const state = useScreenState()
  const live = useLive()
  const { nav, finish, toSignIn } = useAccessMoves()
  const params = nav.params as { variant?: Variant; account?: 'provider' | 'hotel' }
  const flowProvider = useAccessFlow(s => s.provider)
  const app = useApplication()
  const offline = state === 'offline'
  // An application variant follows the prototype's application store in the player (the tray below plays the Ghazal staff); a frame names its own.
  const asked: Variant = state !== undefined && VARIANTS.includes(state) ? (state as Variant) : (params.variant ?? 'under-review')
  const variant: Variant = asked.startsWith('application') && state === undefined ? (app.status === 'rejected' ? 'application-rejected' : app.status === 'approved' ? 'application-approved' : 'application-review') : asked
  const isApplication = variant === 'application-review' || variant === 'application-rejected' || variant === 'application-approved'
  // The service-provider partner (Zahra Floral Studio) sees her own business, never the hotel's name.
  const provider = params.account === 'provider' || flowProvider
  const persona = provider ? personaFor('service_provider') : undefined
  const venue = venueOf()
  const applied = app.form ?? (params.account === 'hotel' ? demoHallForm(lang) : demoProviderForm(lang))
  const venueName = isApplication ? bi(nameOfForm(applied)) : provider ? bi(partnerFor(persona?.partnerAccountId ?? '')?.name ?? { en: '', ar: '' }) : venue ? bi(venue.name) : ''
  const staff = demoStaff()
  const support = useSupport()
  const contactAdmin = useContactAdmin()
  // The account belongs to more than one venue when the seed names a sister venue (HA-AUTH-03).
  const multiVenue = !provider && !isApplication && Boolean(hotelSettings.sister)
  const fullScreen = variant !== 'no-access'
  const venueVariant = variant === 'under-review' || variant === 'suspended' || variant === 'deactivated' || variant === 'application-review' || variant === 'application-approved'
  const reasons: ApplicationReason[] = state === undefined && app.reasons.length > 0 ? app.reasons : DEMO_REASONS
  const note = state === undefined && app.note ? app.note : tp('hotelProviderAppDemoNote')

  const title: Record<Exclude<Variant, 'no-access'>, string> = {
    'under-review': t('hotelAccessStatusUnderReviewTitle'),
    'application-review': t('hotelAccessStatusApplicationTitle'),
    'application-rejected': t('hotelAccessStatusRejectedTitle'),
    'application-approved': t('hotelAccessStatusApprovedTitle'),
    suspended: t('hotelAccessStatusSuspendedTitle'),
    deactivated: t('hotelAccessStatusDeactivatedTitle'),
    'session-revoked': t('hotelAccessStatusRevokedTitle'),
  }
  // The sentence behind the info glyph (the recovery exception).
  const detail: Partial<Record<Variant, ReactNode>> = {
    'under-review': t('hotelAccessStatusUnderReviewBody'),
    'application-review': t('hotelAccessStatusApplicationBody'),
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
        variant={isApplication ? 'under-review' : (variant as StatusVariant)}
        onPick={() => {
          nav.closeSheet(key)
          if (staff) finish(staff)
        }}
      />,
      { title: t('hotelAccessStatusSwitchVenue') },
    )
  }

  const account = params.account ?? (applied.kind === 'private_hall' ? 'hotel' : 'provider')
  const primary = (() => {
    switch (variant) {
      case 'under-review':
      case 'application-review':
      case 'suspended':
        return { label: t('hotelAccessSupportAction'), onPress: support }
      case 'application-rejected':
        return { label: t('hotelAccessStatusEditResubmit'), iconEnd: 'chevron-right' as const, onPress: () => nav.push('HL-PROV-01', { resubmit: true, account }) }
      case 'application-approved':
        return { label: tc('commonActionContinue'), iconEnd: 'chevron-right' as const, onPress: () => nav.reset('HL-TODY-01', { account }) }
      case 'deactivated':
        return { label: t('hotelAccessAdminAction'), onPress: contactAdmin }
      case 'session-revoked':
        return { label: t('hotelAccessSigninSubmit'), onPress: signOut }
      case 'no-access':
        return { label: tc('commonLabelToday'), iconEnd: 'arrow-right' as const, onPress: () => nav.reset('HL-TODY-01') }
    }
  })()

  const quiet = fullScreen && variant !== 'application-approved' ? (
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

  // The reasons staff gave and their note, in the staff member's own words (user text keeps its script).
  const rejected = variant === 'application-rejected' ? (
    <section className="hxa04__reasons" aria-label={t('hotelAccessStatusReasonsLabel')}>
      <ul className="hxa04__chips">
        {reasons.map(r => (
          <li key={r}>
            <Tag icon="warning-circle">{tp(REASON[r])}</Tag>
          </li>
        ))}
      </ul>
      <UserText role="body">{note}</UserText>
    </section>
  ) : null

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
              facts={rejected ?? undefined}
              detail={detail[variant]}
              detailTitle={title[variant]}
              size="hero"
            />
          )}
        </div>

        {live && variant === 'application-review' ? (
          <section className="hxa04__proto" data-gz-id="proto" aria-label={t('hotelAccessStatusProtoTitle')}>
            <p className="gz-t-label hxa04__protolabel">{t('hotelAccessStatusProtoTitle')}</p>
            <div className="hxa04__protobtns">
              <Button variant="secondary" onClick={() => useApplication.getState().approve()}>
                {t('hotelAccessStatusProtoApprove')}
              </Button>
              <Button variant="secondary" onClick={() => useApplication.getState().reject(DEMO_REASONS, tp('hotelProviderAppDemoNote'))}>
                {t('hotelAccessStatusProtoReject')}
              </Button>
            </div>
          </section>
        ) : null}
      </div>
    </Screen>
  )
}
