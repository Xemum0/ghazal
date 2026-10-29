// CL-PROF-06 Delete account. Requirements: CA-PROF-09 (ADR 0007 D12, ADR 0028 item 7; Apple and Google require deletion inside the app).
//
// One screen, four moves, text-diet edition (ADR 0034). (1) The consequences as glyph rows with a one-word outcome (personal data anonymised,
// receipts kept as the law requires, plans removed, a pending request withdrawn, a ready voucher offered for refund first, ADR 0033); the full
// sentences, Sign in with Apple included, are behind the info glyph. (2) A fresh WhatsApp code. (3) The last confirmation: who, "Can't be
// undone", a destructive button with icon and text (never colour alone). (4) A plain "deleted" and the language screen again.
// Deletion is PAUSED, never a dead end, while a request is approved (confirm or cancel it first) or a confirmed booking is still ahead: an
// hourglass, the request named as a fact row, and the ways forward (open it or schedule the deletion after the event, cancel it, Support);
// a request made for after the event shows as "scheduled" here and as a row on the Profile hub. A pending request is simply withdrawn with
// the account. No gold on the destructive path: the one gold action is the verb that unblocks.
// States: default, blocked-active-booking, blocked-approved, scheduled-after-event, otp-reauth, confirm, deleting, success, error, offline.
import { useEffect, useRef, useState } from 'react'
import { useFormat, useT, Phone } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { usePrototype } from '../../../shell/state'
import { EMPTY_BRIEF } from '../../../shell/state/defaults'
import { ActionBar, Avatar, Banner, Button, EmptyState, ErrorState, FactChip, FactRow, Icon, IconListRow, Illustration, InfoButton, Screen, StatusPill, SuccessState, TopBar, useNav } from '../../../system'
import { getVenue, meta } from '../../../mock'
import { useOtp } from '../auth/_components/OtpPanel'
import { Mixed } from './_components/parts'
import { CodeBody } from './_components/reauth'
import { storyProfile, useIdentity, useLive, useProfileFlow, useReadyVouchers, useSceneState, useStoryBooking } from './_components/useProfile'
import './_components/parts.css'
import './CL-PROF-06.css'

export const states = ['blocked-active-booking', 'blocked-approved', 'scheduled-after-event', 'otp-reauth', 'confirm', 'deleting', 'success', 'error', 'offline']

type Step = 'consequences' | 'blocked' | 'scheduled' | 'otp' | 'confirm' | 'deleting' | 'success'

const WORK_MS = 1200

function seedStep(state: string | undefined, live: boolean, blocked: boolean, scheduled: boolean): Step {
  if (!live) {
    switch (state) {
      case 'blocked-active-booking':
      case 'blocked-approved':
        return 'blocked'
      case 'scheduled-after-event':
        return 'scheduled'
      case 'otp-reauth':
        return 'otp'
      case 'confirm':
      case 'error':
        return 'confirm'
      case 'deleting':
        return 'deleting'
      case 'success':
        return 'success'
      default:
        return 'consequences'
    }
  }
  return scheduled ? 'scheduled' : blocked ? 'blocked' : 'consequences'
}

export default function DeleteAccount() {
  const t = useT('client-profile')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const { lang } = useLang()
  const live = useLive()
  const state = useSceneState()
  const who = useIdentity()
  const { status, booking } = useStoryBooking()
  const ready = useReadyVouchers()
  const deletionAfter = useProfileFlow(s => s.deletionAfter)

  const blocked = status === 'confirmed' || status === 'approved'
  const approved = status === 'approved'
  const venueName = booking?.venueId ? (getVenue(booking.venueId)?.name[lang] ?? '') : ''
  const refundable = ready.filter(v => v.creditEligible)
  const eventDate = booking?.eventDate ?? ''
  // Pages are built eagerly each render, so a missing booking (nothing active, or just erased) must never reach the date formatter.
  const day = (d: string, style: 'full' | 'short') => (d ? f.date(d, style) : '')
  const [step, setStep] = useState<Step>(() => seedStep(state, live, blocked, deletionAfter !== null))
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const offline = state === 'offline'
  const phone = who.phone

  const otp = useOtp({ onVerified: () => setStep('confirm') })

  // ------------------------------------------------------------ moves
  const keep = () => nav.pop()
  const back = () => (step === 'deleting' || step === 'success' ? undefined : step === 'otp' || step === 'confirm' ? setStep('consequences') : nav.pop())

  const erase = () => {
    // Everything of the person goes; the partner side of a pending request is withdrawn by the client.
    const story = meta.story.bookingId
    usePrototype.getState().signOut()
    usePrototype.setState(s => ({
      weddingProfile: null,
      favourites: { venue: [], vendor: [], package: [] },
      compareList: [],
      searchBrief: { ...EMPTY_BRIEF },
      hotelBookings: s.hotelBookings.map(b => (b.id === story && b.status === 'pending' ? { ...b, status: 'cancelled' as const, cancelledBy: 'client' as const, respondBy: null } : b)),
    }))
    useProfileFlow.getState().reset()
  }
  const confirmDelete = () => {
    if (offline) return
    setStep('deleting')
    if (live) {
      timer.current = window.setTimeout(() => {
        erase()
        setStep('success')
      }, WORK_MS)
    }
  }
  const finish = () => nav.reset('CL-ONBD-01')
  const scheduleAfter = () => {
    useProfileFlow.getState().scheduleDeletion(eventDate || null)
    setStep('scheduled')
  }
  const unschedule = () => {
    useProfileFlow.getState().scheduleDeletion(null)
    nav.toast({ message: t('clientProfileDelScheduledCancelled') })
    nav.pop()
  }
  const openBooking = (extra?: Record<string, unknown>) => booking && nav.push('CL-BKNG-02', { bookingId: booking.id, ...extra })
  const toSupport = () => nav.push('CL-MSGS-02', { conversationId: 'conv-support-reem' })

  // ------------------------------------------------------------ the pages

  // One consequence: a glyph, a noun, the outcome in one word.
  const outcome = (icon: 'user' | 'receipt' | 'heart' | 'calendar-check' | 'ticket', title: string, word: string, key: string, last = false, own = false) => (
    <IconListRow key={key} icon={icon} title={own ? <bdi dir="auto">{title}</bdi> : title} trailing={<span className="gzpr-del__out">{word}</span>} last={last} />
  )

  const consequences = (
    <>
      <div className="gzpr-pad gzpr-del__head">
        <Illustration name="shield" size="md" />
        <p className="gzpr-del__warn gz-t-body-s">
          <Icon name="warning-circle" size="sm" tone="danger" />
          {t('clientProfileDelUndone')}
        </p>
        <InfoButton title={t('clientProfileDelDetailTitle')}>
          <p className="gzpr-del__para">{t('clientProfileDelSheetData')}</p>
          <p className="gzpr-del__para">{t('clientProfileDelSheetReceipts')}</p>
          <p className="gzpr-del__para">{t('clientProfileDelSheetSaved')}</p>
          <p className="gzpr-del__para">{t('clientProfileDelSheetApple')}</p>
          {status === 'pending' ? <p className="gzpr-del__para">{t('clientProfileDelSheetRequest', { venue: venueName })}</p> : null}
          {refundable.length > 0 ? (
            <p className="gzpr-del__para">{t('clientProfileDelVoucherDetailRefund', { count: refundable.length })}</p>
          ) : ready.length > 0 ? (
            <p className="gzpr-del__para">{t('clientProfileDelVoucherDetailEnds', { count: ready.length })}</p>
          ) : null}
        </InfoButton>
      </div>
      <div className="gzpr-list" data-gz-id="delete.consequences">
        {outcome('user', t('clientProfileDelItemData'), t('clientProfileDelOutAnonymised'), 'data')}
        {outcome('receipt', t('clientProfileHubRowReceipts'), t('clientProfileDelOutKept'), 'receipts')}
        {outcome('heart', t('clientProfileDelItemPlans'), t('clientProfileDelOutRemoved'), 'plans', status !== 'pending' && ready.length === 0)}
        {status === 'pending' ? outcome('calendar-check', venueName, t('clientProfileDelOutWithdrawn'), 'request', ready.length === 0, true) : null}
        {ready.length > 0 ? (
          <IconListRow
            icon="ticket"
            title={t('clientProfileDelVoucher', { count: ready.length })}
            trailing={
              refundable.length > 0 ? (
                <Button variant="tertiary" onClick={() => nav.push('CL-VCHR-03', { voucherId: refundable[0]?.id })}>
                  {t('clientProfileDelVoucherRefund')}
                </Button>
              ) : (
                <span className="gzpr-del__out">{t('clientProfileDelOutRemoved')}</span>
              )
            }
            last
          />
        ) : null}
      </div>
      <div className="gzpr-pad gzpr-del__actions">
        <Button variant="destructive" fullWidth iconStart="trash" onClick={() => setStep('otp')} disabled={offline}>
          {t('clientProfileDelTitle')}
        </Button>
        <Button variant="tertiary" className="gzpr-flush" onClick={keep}>
          {t('clientProfileSharedKeep')}
        </Button>
      </div>
    </>
  )

  const blockedPage = (
    <>
      <EmptyState
        illustration="hourglass"
        title={t('clientProfileDelBlockedTitle')}
        detail={approved ? t('clientProfileDelBlockedApprovedDetail', { venue: venueName }) : t('clientProfileDelBlockedDetail', { venue: venueName, date: day(eventDate, 'full') })}
        detailTitle={t('clientProfileDelBlockedTitle')}
        fill={false}
        size="lg"
      />
      {booking ? (
        <div className="gzpr-list">
          <IconListRow
            icon="calendar-check"
            title={<bdi dir="auto">{venueName}</bdi>}
            facts={
              <FactRow>
                <FactChip icon="calendar" value={<Mixed>{day(eventDate, 'full')}</Mixed>} label={t('clientProfileWedDate')} />
                <StatusPill status={approved ? 'approved' : 'confirmed'} />
              </FactRow>
            }
            chevron
            onClick={() => openBooking()}
            last
          />
        </div>
      ) : null}
      <div className="gzpr-pad gzpr-del__actions">
        {approved ? (
          <Button variant="primary" fullWidth onClick={() => openBooking()}>
            {t('clientProfileDelBlockedOpen')}
          </Button>
        ) : (
          <Button variant="primary" fullWidth onClick={scheduleAfter}>
            {t('clientProfileDelBlockedSchedule')}
          </Button>
        )}
        <Button variant="secondary" fullWidth onClick={() => openBooking({ intent: 'cancel' })}>
          {approved ? t('clientProfileDelBlockedCancelRequest') : t('clientProfileDelBlockedCancel')}
        </Button>
        <Button variant="tertiary" className="gzpr-flush" iconStart="chat" onClick={toSupport}>
          {t('clientProfileSharedSupport')}
        </Button>
      </div>
    </>
  )

  const scheduledPage = (
    <SuccessState
      illustration="calendar"
      title={t('clientProfileDelScheduledTitle')}
      body={f.date(deletionAfter || eventDate || storyProfile.weddingDate, 'full')}
      action={{ label: c('commonActionDone'), onPress: () => nav.pop() }}
      secondary={{ label: t('clientProfileDelScheduledCancel'), onPress: unschedule }}
    />
  )

  const confirmPage = (
    <div className="gzpr-pad gzpr-del__confirm">
      <Illustration name="warning" size="lg" />
      <div className="gzpr-del__who">
        <Avatar name={who.name} initial={who.monogram} size="md" />
        <h2 className="gzpr-del__name gz-t-d1" dir="auto">
          {who.name}
        </h2>
        <p className="gzpr-del__phone">
          <Phone value={phone} className="gz-t-fig-caption gzpr-del__digits" />
        </p>
      </div>
      <div className="gzpr-del__actions">
        <p className="gzpr-del__warn gz-t-body-s">
          <Icon name="warning-circle" size="sm" tone="danger" />
          {t('clientProfileDelUndone')}
        </p>
        <Button variant="destructive" fullWidth iconStart="trash" disabled={offline} onClick={confirmDelete}>
          {t('clientProfileDelTitle')}
        </Button>
        <Button variant="tertiary" onClick={keep}>
          {t('clientProfileSharedKeep')}
        </Button>
      </div>
    </div>
  )

  // ErrorState's `body` is the recovery text; the system puts it behind the info glyph.
  const errorPage = <ErrorState title={t('clientProfileDelErrorTitle')} body={t('clientProfileDelErrorDetail')} onRetry={confirmDelete} secondary={{ label: t('clientProfileSharedKeep'), onPress: keep }} />

  const deletingPage = <EmptyState illustration="hourglass" title={t('clientProfileDelDeleting')} />

  const successPage = (
    <SuccessState illustration="seal" title={t('clientProfileDelSuccessTitle')} detail={t('clientProfileDelSuccessDetail')} detailTitle={t('clientProfileDelSuccessTitle')} action={{ label: c('commonActionDone'), onPress: finish }} />
  )

  const stateful = otp.view === 'locked' || otp.view === 'delivery-failed' || otp.view === 'success'
  const otpPage = (
    <div className="gzpr-pad gzpr-del__otp">
      {stateful ? null : <Illustration name="chat" size="md" />}
      <CodeBody otp={otp} phone={phone} />
    </div>
  )

  const page =
    step === 'blocked'
      ? blockedPage
      : step === 'scheduled'
        ? scheduledPage
        : step === 'confirm'
          ? state === 'error'
            ? errorPage
            : confirmPage
          : step === 'deleting'
            ? deletingPage
            : step === 'success'
              ? successPage
              : step === 'otp'
                ? otpPage
                : consequences

  const done = step === 'success'
  // Erasing is terminal: no back arrow while it runs or after it finished; 'Done' is the only way out.
  const locked = done || step === 'deleting'
  const a = otp.action
  return (
    <Screen
      top={<TopBar title={done ? undefined : t('clientProfileDelTitle')} back={locked ? false : 'auto'} onBack={back} />}
      bottom={step === 'otp' ? <ActionBar action={{ label: a.label, loading: a.loading, disabled: a.disabled, reason: a.reason, onPress: a.onPress }} /> : undefined}
    >
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className="gzpr-del" data-gz-id="delete.account" data-step={step}>
        {page}
      </div>
    </Screen>
  )
}
