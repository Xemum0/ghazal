// HL-SETT-01 More (tab root). Requirement IDs: HA-AUTH-02, HA-AUTH-03, HA-AUTH-04, HA-SET-05, HA-VMGT-09, HA-VMGT-10, HA-MSG-05, PA-ACC-02, PA-ACC-04, PA-ACC-05, HA-SET-06, HA-VIS-05.
// Everything that is not the daily loop, two levels deep at most (ADR 0008 D11). Voucher model (ADR 0033): the listing card on top shows the
// listing status, language completeness as two threads (a hotel) or the listing counts (a provider) and the Billing row that replaced the payout
// row (the end date of the plan, or the crown of a major hotel); below it the venue tiles (glyph, count, one word), Visits, Grow, Notifications,
// Business and Account, or for a service provider Listings, Notifications and Account. Content is role-aware and navigation is not: a row a role
// cannot use is hidden, never locked. Language is a per-user setting and flips the app on the spot. Logging out clears the device.
// Text diet (ADR 0034): no row has a sub-line and no sentence is on the screen; counts, dates and glyphs carry what the sub-lines said.
// Live prototype note: the persona is Hind (Manager) but the default view is the all-access owner view so Staff can be opened; `role-manager`
// draws her real view (Staff hidden). The login holds both account types (A-06), so Switch account type is live.
// States: loading, error, offline, role-reception, role-accountant, role-marketing, role-manager, venue-under-review, language-sheet,
// venue-switcher-sheet, logout-dialog, role-provider, fee-exempt-badge, account-type-switch-sheet, hotel-with-plan, plan-expiring
import { useEffect, useMemo, useRef, type ReactNode } from 'react'
import { activeListingOf, getArea, getVenue, hotelSettings, packagesFor, reviewsAwaitingReply } from '../../../mock'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { useLang } from '../../../shell/lang'
import { usePrototype } from '../../../shell/state'
import { Banner, CountBadge, Dialog, ErrorState, FactChip, Figures, PullToRefresh, Screen, Sheet, Skeleton, Switch, TopBar, useNav } from '../../../system'
import { useAccessFlow } from '../access/_components/flow'
import { useProv } from '../provider/_components/store'
import { AccountTypeContent, LanguageContent, ListingCard, MoreGroup, PreviewContent, VenueSwitcherContent, VenueTiles, type CardState, type MoreRow, type MoreTile, type PreviewSubject } from './_components/MoreParts'
import { PROVIDER_ID, PROVIDER_NAME, NON_MAJOR_NAME, VENUE_ID, useAccount, useBi, useBilling, useStaff, useWords } from './_components/bits'
import { ACCESS, roleOfState } from './_components/model'
import { useSettingsLocal } from './_components/store'
import './HL-SETT-01.css'

export const states = [
  'loading',
  'error',
  'offline',
  'role-reception',
  'role-accountant',
  'role-marketing',
  'role-manager',
  'venue-under-review',
  'language-sheet',
  'venue-switcher-sheet',
  'logout-dialog',
  'role-provider',
  'fee-exempt-badge',
  'account-type-switch-sheet',
  'hotel-with-plan',
  'plan-expiring',
]

const APP_VERSION = '1.0.0'

export default function MoreRoot() {
  const { state } = useFrame()
  const nav = useNav()
  const { t, c } = useWords()
  const f = useFormat()
  const bi = useBi()
  const { lang, setLang } = useLang()
  const role = roleOfState(state)
  const access = ACCESS[role]
  const account = useAccount()
  const isProvider = account.type === 'provider'
  const billing = useBilling(account, state)
  const venue = getVenue(VENUE_ID)
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const underReview = state === 'venue-under-review'

  const biometric = useSettingsLocal(s => s.biometric)
  const staff = useStaff()
  const requests = usePrototype(s => s.hotelBookings.filter(b => b.venueId === VENUE_ID && b.status === 'pending').length)
  const visitRequests = usePrototype(s => s.visits.filter(v => v.venueId === VENUE_ID && v.status === 'requested').length)
  const listings = usePrototype(s => s.listings)
  const mine = useMemo(() => listings.filter(l => l.providerId === PROVIDER_ID), [listings])
  const listingCounts = useMemo(
    () => ({ live: mine.filter(l => l.status === 'active').length, review: mine.filter(l => l.status === 'pending_review' || l.status === 'approved').length }),
    [mine],
  )

  // ---- overlays (the live navigator draws them; a static frame draws the same content in its own container)
  const openLanguage = () => {
    const key = nav.openSheet(<LanguageContent onChoose={choose} />, { title: t('hotelSettingsLanguageTitle') })
    function choose(next: 'ar' | 'en') {
      nav.closeSheet(key)
      if (next === lang) return
      toastAfterFlip.current = true
      setLang(next)
    }
  }
  // The toast is worded after the switch, in the language just chosen.
  const toastAfterFlip = useRef(false)
  useEffect(() => {
    if (!toastAfterFlip.current) return
    toastAfterFlip.current = false
    nav.toast({ message: t('hotelSettingsLanguageSaved'), tone: 'success', icon: 'check-circle' })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lang])

  const venueName = () => (venue ? venue.name[lang] : '')
  const sisterName = () => hotelSettings.sister?.name[lang] ?? ''
  const chooseVenue = (key: string | null, id: string) => {
    if (key) nav.closeSheet(key)
    const sister = id !== VENUE_ID
    useSettingsLocal.getState().setActiveVenue(id)
    nav.toast({ message: sister ? sisterName() : venueName(), tone: 'success', icon: 'swap' })
  }
  const openSwitcher = () => {
    const key = nav.openSheet(<VenueSwitcherContent pendingHere={requests} onChoose={id => chooseVenue(key, id)} />, { title: t('hotelSettingsSwitchTitle') })
  }

  const area = venue?.areaId ? getArea(venue.areaId) : undefined
  const liveProviderListing = activeListingOf(PROVIDER_ID)
  const subject: PreviewSubject | null = isProvider
    ? { name: bi(PROVIDER_NAME), cover: liveProviderListing?.cover ?? null }
    : venue
      ? { name: bi(account.major ? venue.name : NON_MAJOR_NAME), cover: venue.cover ?? null, area: area ? bi(area.name) : undefined, rating: venue.rating }
      : null
  const openPreview = () => {
    const key = nav.openSheet(<PreviewContent subject={subject} onClose={() => nav.closeSheet(key)} />, { title: t('hotelSettingsPreviewTitle') })
  }

  // Switching the type changes whose Today, listings and billing the app draws; the sign-in holds both (A-06).
  const switchType = (key: string | null, type: 'venue' | 'provider') => {
    if (key) nav.closeSheet(key)
    if (type === account.type) return
    useAccessFlow.getState().setProvider(type === 'provider')
    useProv.getState().setViewer('provider')
    nav.toast({ message: t(type === 'provider' ? 'hotelSettingsAcctSwitchedProvider' : 'hotelSettingsAcctSwitchedVenue'), tone: 'success', icon: 'check-circle' })
  }
  const openAccountType = () => {
    const key = nav.openSheet(
      <AccountTypeContent
        current={account.type}
        onChoose={type => switchType(key, type)}
        onSetup={() => {
          nav.closeSheet(key)
          nav.push('HL-PROV-01', { account: account.type === 'provider' ? 'provider' : 'venue' })
        }}
      />,
      { title: t('hotelSettingsAcctTitle') },
    )
  }

  const logoutDialog = {
    title: t('hotelSettingsLogoutTitle'),
    icon: 'sign-out' as const,
    confirmLabel: t('hotelSettingsMoreLogout'),
    cancelLabel: c('commonActionCancel'),
    tone: 'destructive' as const,
  }
  const logout = async () => {
    const result = await nav.openDialog(logoutDialog)
    if (result !== 'confirm') return
    usePrototype.getState().signOut()
    useSettingsLocal.getState().reset()
    nav.reset('HL-ACCS-01')
  }

  const toggleBiometric = async (on: boolean) => {
    if (!on) {
      useSettingsLocal.getState().setBiometric(false)
      nav.toast({ message: t('hotelSettingsBiometricOff'), icon: 'fingerprint' })
      return
    }
    const result = await nav.openDialog({
      title: t('hotelSettingsBiometricOnTitle'),
      icon: 'face-id',
      confirmLabel: t('hotelSettingsBiometricOnConfirm'),
      cancelLabel: c('commonActionCancel'),
    })
    if (result !== 'confirm') return
    useSettingsLocal.getState().setBiometric(true)
    nav.toast({ message: t('hotelSettingsBiometricOn'), tone: 'success', icon: 'check-circle' })
  }

  const legal = () => nav.toast({ message: t('hotelSettingsMoreLegalToast'), icon: 'external-link' })

  // ---- rows by role and account type (hidden, never locked)
  const photos = venue?.gallery.length ?? 0
  const packageCount = packagesFor(VENUE_ID).length
  const hallCount = venue?.halls.length ?? 0
  const waiting = reviewsAwaitingReply(VENUE_ID).length
  // A count at inline-end: a quiet figure (the number was the sub-line of the row).
  const count = (n: number): ReactNode => <span className="hs-count gz-t-fig-body-s">{f.integer(n)}</span>
  // A count that needs an answer: the gold badge (visits waiting, reviews waiting).
  const waitingBadge = (n: number): ReactNode => (n > 0 ? <CountBadge count={n} max={9} /> : undefined)

  const tilesVenue: MoreTile[] = []
  const rowsVisits: MoreRow[] = []
  const rowsGrow: MoreRow[] = []
  const rowsListings: MoreRow[] = []
  if (!isProvider) {
    if (access.media) tilesVenue.push({ id: 'media', icon: 'image', title: t('hotelSettingsMoreMedia'), count: photos, onPress: () => nav.push('HL-VENU-01') })
    if (access.venue) {
      tilesVenue.push(
        { id: 'packages', icon: 'offer', title: t('hotelSettingsMorePackages'), count: packageCount, onPress: () => nav.push('HL-VENU-02') },
        { id: 'halls', icon: 'hall', title: t('hotelSettingsMoreHalls'), count: hallCount, onPress: () => nav.push('HL-VENU-04') },
        { id: 'policies', icon: 'document', title: t('hotelSettingsMorePolicies'), onPress: () => nav.push('HL-VENU-05') },
        { id: 'rules', icon: 'checklist', title: t('hotelSettingsMoreRules'), onPress: () => nav.push('HL-VENU-06') },
      )
    }
    if (access.availability) tilesVenue.push({ id: 'availability', icon: 'calendar-check', title: t('hotelSettingsMoreAvailability'), onPress: () => nav.switchTab('calendar') })

    if (access.visits) {
      rowsVisits.push({ id: 'visit-requests', icon: 'door', title: t('hotelSettingsMoreVisitRequests'), trailing: waitingBadge(visitRequests), onPress: () => nav.push('HL-VIST-01') })
      if (access.venue) rowsVisits.push({ id: 'visit-availability', icon: 'calendar-dots', title: t('hotelSettingsMoreVisitAvailability'), onPress: () => nav.push('HL-VIST-05') })
    }

    if (access.voucherPrices) rowsGrow.push({ id: 'voucher-prices', icon: 'ticket', title: t('hotelSettingsMoreVoucherPrices'), onPress: () => nav.push('HL-GROW-01') })
    if (access.analytics) rowsGrow.push({ id: 'analytics', icon: 'chart-line', title: t('hotelSettingsMoreAnalytics'), onPress: () => nav.push('HL-GROW-04') })
    if (access.reviews) rowsGrow.push({ id: 'reviews', icon: 'star', title: t('hotelSettingsMoreReviews'), trailing: waitingBadge(waiting), onPress: () => nav.push('HL-GROW-06') })
  } else if (access.listings) {
    rowsListings.push(
      { id: 'listings', icon: 'megaphone', title: t('hotelSettingsMoreListings'), trailing: count(mine.length), onPress: () => nav.push('HL-PROV-02', { account: 'provider' }) },
      { id: 'performance', icon: 'chart-line', title: t('hotelSettingsMorePerformance'), onPress: () => nav.push('HL-PROV-07', { account: 'provider', listingId: liveProviderListing?.id ?? mine[0]?.id }) },
    )
  }

  const language: MoreRow = {
    id: 'language',
    icon: 'translate',
    title: t('hotelSettingsMoreLanguage'),
    trailing: <span lang={lang}>{lang === 'ar' ? 'العربية' : 'English'}</span>,
    onPress: openLanguage,
  }

  const rowsBusiness: MoreRow[] = []
  if (!isProvider && access.staff) rowsBusiness.push({ id: 'staff', icon: 'team', title: t('hotelSettingsMoreStaff'), trailing: count(staff.length), onPress: () => nav.push('HL-SETT-03') })
  if (!isProvider && access.hours !== 'none') rowsBusiness.push({ id: 'hours', icon: 'clock', title: t('hotelSettingsMoreHours'), onPress: () => nav.push('HL-SETT-05') })
  const hasBusiness = rowsBusiness.length > 0
  if (hasBusiness) rowsBusiness.push(language)

  const rowsNotifications: MoreRow[] = [{ id: 'notifications', icon: 'bell', title: t('hotelSettingsMoreNotifications'), onPress: () => nav.push('HL-SETT-02') }]

  const rowsAccount: MoreRow[] = []
  if (!hasBusiness) rowsAccount.push(language)
  if (access.accountType) {
    rowsAccount.push({
      id: 'account-type',
      icon: 'user',
      title: t('hotelSettingsMoreAccountType'),
      trailing: <FactChip icon={isProvider ? 'megaphone' : 'hotel'} label={t(isProvider ? 'hotelSettingsAcctProvider' : 'hotelSettingsAcctVenue')} />,
      onPress: openAccountType,
    })
  }
  rowsAccount.push(
    {
      id: 'biometric',
      icon: 'fingerprint',
      title: t('hotelSettingsMoreBiometric'),
      chevron: false,
      trailing: <Switch checked={biometric} onChange={toggleBiometric} label={t('hotelSettingsMoreBiometric')} />,
    },
    {
      id: 'support',
      icon: 'chat-text',
      title: t('hotelSettingsMoreSupport'),
      onPress: isProvider ? () => nav.toast({ message: t('hotelSettingsMoreSupportToast'), icon: 'chat-text' }) : () => nav.push('HL-TODY-05', { conversationId: 'conv-support-aurelia' }),
    },
  )
  if (!isProvider) rowsAccount.push({ id: 'switch', icon: 'swap', title: t('hotelSettingsMoreSwitch'), onPress: openSwitcher })
  rowsAccount.push({ id: 'logout', icon: 'sign-out', title: t('hotelSettingsMoreLogout'), tone: 'danger', chevron: false, onPress: logout })

  // ---- the card
  const cardState: CardState = isProvider ? (listingCounts.live > 0 ? 'live' : listingCounts.review > 0 ? 'review' : 'draft') : underReview ? 'review' : 'live'
  const cardName = isProvider ? bi(PROVIDER_NAME) : venue && account.major ? bi(venue.name) : bi(NON_MAJOR_NAME)
  const showBilling = access.billing !== 'none'

  // ---- body
  const refresh = () => new Promise<void>(resolve => window.setTimeout(resolve, 900))
  let body
  if (loading) {
    body = (
      <div className="hs-more__skeleton" aria-busy="true" aria-label={c('commonStateLoading')}>
        <Skeleton variant="block" blockSize={252} />
        <Skeleton variant="line" inlineSize={160} blockSize={24} />
        {[0, 1, 2, 3].map(i => (
          <Skeleton key={i} variant="line" blockSize={48} />
        ))}
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-SETT-01')} />
  } else {
    body = (
      <>
        <div className="hs-more__card">
          <ListingCard
            name={cardName}
            state={cardState}
            completeness={isProvider ? undefined : hotelSettings.listingCompleteness}
            listings={isProvider ? listingCounts : undefined}
            billing={showBilling ? billing : undefined}
            onBilling={access.billing !== 'none' ? () => nav.push('HL-SETT-04') : undefined}
            onPreview={openPreview}
          />
        </div>
        <VenueTiles title={t('hotelSettingsMoreGroupVenue')} tiles={tilesVenue} />
        <MoreGroup title={t('hotelSettingsMoreGroupVisits')} rows={rowsVisits} />
        <MoreGroup rows={rowsListings} />
        <MoreGroup title={t('hotelSettingsMoreGroupGrow')} rows={rowsGrow} />
        <MoreGroup rows={rowsNotifications} />
        {hasBusiness ? <MoreGroup title={t('hotelSettingsMoreGroupBusiness')} rows={rowsBusiness} /> : null}
        <MoreGroup title={t('hotelSettingsMoreGroupAccount')} rows={rowsAccount} />
        <footer className="hs-more__foot">
          <p className="gz-t-caption">
            <Figures text={t('hotelSettingsMoreVersion', { version: APP_VERSION })} />
          </p>
          <div className="hs-more__legal">
            <button type="button" className="gz-reset hs-more__link gz-t-caption gz-press" onClick={legal}>
              {t('hotelSettingsMoreTerms')}
            </button>
            <button type="button" className="gz-reset hs-more__link gz-t-caption gz-press" onClick={legal}>
              {t('hotelSettingsMorePrivacy')}
            </button>
          </div>
        </footer>
      </>
    )
  }

  const top = <TopBar variant="large-title" title={t('hotelSettingsMoreTitle')} back={false} />

  return (
    <div className="hs-root">
      <Screen top={top} bodyClassName="hs-more">
        {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
        <PullToRefresh onRefresh={refresh}>
          <div className="hs-more__body">{body}</div>
        </PullToRefresh>
      </Screen>
      {state === 'language-sheet' ? (
        <Sheet title={t('hotelSettingsLanguageTitle')}>
          <LanguageContent onChoose={() => undefined} />
        </Sheet>
      ) : null}
      {state === 'venue-switcher-sheet' ? (
        <Sheet title={t('hotelSettingsSwitchTitle')}>
          <VenueSwitcherContent pendingHere={requests} onChoose={() => undefined} />
        </Sheet>
      ) : null}
      {state === 'account-type-switch-sheet' ? (
        <Sheet title={t('hotelSettingsAcctTitle')}>
          <AccountTypeContent current={account.type} onChoose={() => undefined} onSetup={() => undefined} />
        </Sheet>
      ) : null}
      {state === 'logout-dialog' ? <Dialog {...logoutDialog} /> : null}
    </div>
  )
}
