// CL-PROF-01 Profile (tab root). Requirements: CA-PROF-01, CA-PROF-02, CA-PROF-03, CA-PROF-04, CA-PROF-05, CA-PROF-07, CA-PROF-10, CA-PROF-11, CA-PROF-12, CA-VCH-06.
//
// The hub of the Profile tab, text-diet edition (ADR 0034): the monogram and the verified number, one wedding card (rings, the date and the
// days to go as facts), then three quiet lists of one-word rows with a glyph, no group titles and no captions. Counts are figures at the end
// of the row (vouchers ready, visits ahead, saved halls), the request is a status glyph, Receipts shows the KD 2 paid to Ghazal (ADR 0033).
// Every row goes somewhere: Wedding (CL-PROF-02), Bookings, Vouchers, Visits, Receipts, Saved, Personal info (CL-PROF-03), Notifications
// (CL-PROF-04), the language sheet (Profile tab, Language row, choose: three taps, ADR 0007 D7), Settings (CL-PROF-05), the pinned Support
// thread and the in-app reader for Terms and Privacy. Sign out asks first and returns to Home as a guest. A guest sees one doorway card with
// Sign in, Language, Terms and Privacy (saved hearts and the Brief stay on the device).
// In the live prototype the status glyph follows the story (pending, approved with the hours to confirm, confirmed as the hotel app and the
// client move it); a static frame shows it pending unless `?state=` names another.
import { LANGUAGE_NATIVE_NAME } from '@gz/i18n'
import { useFormat, useT, Phone } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { usePrototype } from '../../../shell/state'
import { Avatar, Banner, Button, Dialog, ErrorState, FactChip, FactRow, Figures, Icon, IconListRow, Illustration, Screen, Skeleton, StatusIcon, TopBar, useNav } from '../../../system'
import { clientState, weddingProfile } from '../../../mock'
import { LanguageSheet, FrameSheet, useLegalReader, useSignOut } from './_components/sheets'
import { Mixed } from './_components/parts'
import { APP_VERSION, paidVoucherFils, useGuest, useIdentity, useLive, useProfileFlow, useReadyVouchers, useSceneState, useStoryBooking, useUpcomingVisits } from './_components/useProfile'
import './CL-PROF-01.css'

export const states = ['guest', 'loading', 'offline', 'sign-out-confirm', 'language-sheet', 'confirmed', 'deletion-scheduled']

export default function ProfileHub() {
  const t = useT('client-profile')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const { lang } = useLang()
  const state = useSceneState()
  const live = useLive()
  const guest = useGuest()
  const who = useIdentity()
  const { status, booking } = useStoryBooking()
  const ready = useReadyVouchers().length
  const visits = useUpcomingVisits()
  const profile = usePrototype(s => s.weddingProfile)
  const savedLive = usePrototype(s => s.favourites.venue.length)
  const scheduledLive = useProfileFlow(s => s.deletionAfter)
  const legal = useLegalReader()
  const signOut = useSignOut()

  const weddingDate = live ? (profile?.weddingDate ?? null) : weddingProfile.weddingDate
  const savedCount = live ? savedLive : clientState.saved.filter(s => s.type === 'venue').length
  const scheduled = live ? scheduledLive : state === 'deletion-scheduled' ? (booking?.eventDate ?? weddingProfile.weddingDate) : null
  const paid = status !== null || ready > 0
  const daysToGo = weddingDate ? f.daysUntil(weddingDate) : 0

  const top = <TopBar variant="large-title" title={t('clientProfileHubTitle')} back={false} />

  // ------------------------------------------------------------ loading and error
  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="gzpr-hub" aria-busy="true" aria-label={c('commonStateLoading')}>
          <div className="gzpr-pad gzpr-id">
            <Skeleton variant="circle" inlineSize={56} />
            <div className="gzpr-skel">
              <Skeleton inlineSize={160} blockSize={28} />
              <Skeleton inlineSize={120} blockSize={20} />
            </div>
          </div>
          <div className="gzpr-pad">
            <Skeleton blockSize={112} />
          </div>
          {[5, 4, 3].map((rows, g) => (
            <div key={g} className="gzpr-pad gzpr-skel gzpr-skel--rows">
              {Array.from({ length: rows }, (_, i) => (
                <Skeleton key={i} blockSize={64} />
              ))}
            </div>
          ))}
        </div>
      </Screen>
    )
  }
  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => nav.replace('CL-PROF-01')} />
      </Screen>
    )
  }

  const openLanguage = () => nav.openSheet(<LanguageSheet />)
  const openSignIn = () => nav.openSheet('CL-AUTH-01', { params: { reason: null } })
  const native = LANGUAGE_NATIVE_NAME[lang]

  // A figure at the end of a row; its word is the accessible name.
  const count = (n: number, label: string) =>
    n > 0 ? (
      <span className="gzpr-count gz-t-fig-body">
        <span className="gz-sr-only">{label}</span>
        <Figures text={f.integer(n)} />
      </span>
    ) : undefined

  // ------------------------------------------------------------ rows
  const languageRow = <IconListRow icon="translate" title={c('commonLabelLanguage')} trailing={<span className="gzpr-native" lang={lang}>{native}</span>} chevron onClick={openLanguage} />
  const termsRow = <IconListRow icon="document" title={t('clientProfileSharedTerms')} chevron onClick={() => legal('terms')} />
  const privacyRow = <IconListRow icon="shield-check" title={t('clientProfileSharedPrivacy')} chevron onClick={() => legal('privacy')} last />

  const body = guest ? (
    <>
      <div className="gzpr-pad">
        <section className="gzpr-guest" data-gz="GuestCard">
          <Illustration name="doorway" size="lg" />
          <Button variant="primary" onClick={openSignIn}>
            {t('clientProfileSharedSignIn')}
          </Button>
        </section>
      </div>
      <div className="gzpr-list">
        {languageRow}
        {termsRow}
        {privacyRow}
      </div>
    </>
  ) : (
    <>
      <div className="gzpr-pad">
        <section className="gzpr-id" aria-label={t('clientProfileHubAccount')} data-gz="IdentityHeader">
          <Avatar name={who.name} initial={who.monogram} size="md" />
          <div className="gzpr-id__text">
            <h2 className="gzpr-id__name gz-t-d1" dir="auto">
              {who.name}
            </h2>
            <p className="gzpr-id__phone">
              <Phone value={who.phone} className="gz-t-fig-caption gzpr-id__digits" />
              <Icon name="check-circle" size="xs" tone="success" />
              <span className="gz-sr-only">{t('clientProfileHubVerified')}</span>
            </p>
          </div>
        </section>
      </div>

      {scheduled ? (
        <div className="gzpr-pad">
          <div className="gzpr-card gzpr-card--quiet" data-gz="ScheduledNote">
            <IconListRow
              flush
              last
              icon="calendar-x"
              title={t('clientProfileDelScheduledTitle')}
              trailing={<FactChip icon="calendar" value={<Mixed>{f.date(scheduled, 'dayMonth')}</Mixed>} label={t('clientProfileDelScheduledTitle')} />}
              chevron
              onClick={() => nav.push('CL-PROF-06')}
            />
          </div>
        </div>
      ) : null}

      <div className="gzpr-pad">
        <div className="gzpr-card" data-gz="WeddingCard" data-gz-id="group.wedding">
          <IconListRow
            flush
            last
            illustration="rings"
            title={t('clientProfileHubRowWedding')}
            facts={
              weddingDate ? (
                <FactRow>
                  <FactChip icon="calendar" value={<Mixed>{f.date(weddingDate, 'dayMonth')}</Mixed>} label={t('clientProfileWedDate')} />
                  {daysToGo > 0 ? <FactChip icon="countdown" value={<Mixed>{c('commonCountDays', { count: daysToGo })}</Mixed>} label={t('clientProfileWedCountdown')} tone="accent" /> : null}
                </FactRow>
              ) : (
                <span className="gzpr-quiet">{c('commonLabelNotDecided')}</span>
              )
            }
            chevron
            onClick={() => nav.push('CL-PROF-02')}
          />
        </div>
      </div>

      <div className="gzpr-list" data-gz-id="group.activity">
        <IconListRow
          icon="calendar-check"
          title={t('clientProfileHubRowBookings')}
          trailing={status ? <StatusIcon status={status} /> : undefined}
          chevron
          onClick={() => nav.push('CL-BKNG-01')}
        />
        <IconListRow icon="ticket" title={t('clientProfileHubRowVouchers')} trailing={count(ready, t('clientProfileHubCountReady'))} chevron onClick={() => nav.push('CL-VCHR-02')} />
        <IconListRow icon="calendar-dots" title={t('clientProfileHubRowVisits')} trailing={count(visits, t('clientProfileHubCountUpcoming'))} chevron onClick={() => nav.push('CL-VIST-04')} />
        <IconListRow
          icon="receipt"
          title={t('clientProfileHubRowReceipts')}
          trailing={
            paid ? (
              <span className="gzpr-count gz-t-fig-body">
                <span className="gz-sr-only">{t('clientProfileHubCountPaid')}</span>
                <Mixed>
                  <Figures text={f.money(paidVoucherFils(), { mode: 'browse' })} />
                </Mixed>
              </span>
            ) : undefined
          }
          chevron
          onClick={() => nav.push('CL-BKNG-05')}
        />
        <IconListRow icon="heart" title={t('clientProfileHubRowSaved')} trailing={count(savedCount, t('clientProfileHubCountHalls'))} chevron onClick={() => nav.switchTab('saved')} last />
      </div>

      <div className="gzpr-list" data-gz-id="group.account">
        <IconListRow icon="user" title={t('clientProfileHubRowPersonal')} chevron onClick={() => nav.push('CL-PROF-03')} />
        <IconListRow icon="bell" title={t('clientProfileHubRowNotifications')} chevron onClick={() => nav.push('CL-PROF-04')} />
        {languageRow}
        <IconListRow icon="settings" title={c('commonLabelSettings')} chevron onClick={() => nav.push('CL-PROF-05')} last />
      </div>

      <div className="gzpr-list" data-gz-id="group.help">
        <IconListRow icon="chat-text" title={t('clientProfileSharedSupport')} chevron onClick={() => nav.push('CL-MSGS-02', { conversationId: 'conv-support-reem' })} />
        {termsRow}
        {privacyRow}
      </div>

      <div className="gzpr-pad">
        <Button variant="secondary" fullWidth iconStart="sign-out" onClick={signOut}>
          {t('clientProfileSharedSignOut')}
        </Button>
      </div>
    </>
  )

  const screen = (
    <Screen top={top}>
      {state === 'offline' ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className="gzpr-hub" data-gz-id="profile.hub" data-mode={guest ? 'guest' : 'signed-in'}>
        {body}
        <p className="gzpr-version gz-t-fig-caption">
          <Figures text={t('clientProfileSharedVersion', { version: APP_VERSION })} />
        </p>
      </div>
      {state === 'sign-out-confirm' ? (
        <Dialog
          title={t('clientProfileSharedSignOutTitle')}
          icon="sign-out"
          confirmLabel={t('clientProfileSharedSignOut')}
          cancelLabel={t('clientProfileSharedSignOutStay')}
          tone="destructive"
        />
      ) : null}
    </Screen>
  )

  return state === 'language-sheet' ? (
    <>
      {screen}
      <FrameSheet>
        <LanguageSheet />
      </FrameSheet>
    </>
  ) : (
    screen
  )
}
