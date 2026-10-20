// The small overlays of Today: the foreground new-request banner (ADR 0008 D2: 6 seconds, non-modal), the two first-run sheets
// (notifications, then the biometric lock) and the venue switcher sheet. Built from the system's Sheet, Button, Illustration and Icon.
// Text diet (docs/design/02-text-diet.md): the banner is a name and its facts; a first-run sheet is a drawing, two glyph points and one
// action, and the paragraph that explains the permission sits behind an info glyph (consent exception, section 6).
import { useEffect, useState } from 'react'
import { hotelNotifications, hotelSettings, getVenue, getVisit } from '../../../../mock'
import { useDevice } from '../../../../shell/device/context'
import type { IconName } from '@gz/tokens'
import { Button, FactChip, FactRow, Icon, Illustration, InfoButton, Sheet } from '../../../../system'
import { TextFact, TimeLeft } from './Facts'
import { UserText, useBi, useDayMonth, useWords } from './bits'
import { usePendingRequests, VENUE_ID } from './data'
import { useFormat } from '../../../../i18n'
import './overlays.css'

// ---------------------------------------------------------------- the foreground banner

export type NewRequestBannerProps = {
  onOpen?: () => void
  /** Static frames keep it on screen; the live prototype dismisses it after 6 seconds. */
  autoDismiss?: boolean
  /** `visit` is the arrival of a site-visit request (HL-VIST-01): the same banner, its own glyph and no reply clock. */
  kind?: 'request' | 'visit'
}

/** The hero story's request arriving: Reem Al-Dosari, ladies' reception, Thu 14 Jan, 350 guests, voucher attached. Distinct from every other row. */
export function NewRequestBanner({ onOpen, autoDismiss = false, kind = 'request' }: NewRequestBannerProps) {
  const f = useFormat()
  const dayMonth = useDayMonth()
  const bi = useBi()
  const { t } = useWords()
  const pending = usePendingRequests()
  const { mode } = useDevice()
  const [gone, setGone] = useState(false)
  const visit = kind === 'visit'
  const n = visit ? hotelNotifications.find(x => x.kind === 'visit_request') : hotelNotifications.find(x => x.kind === 'new_request' && x.bookingId === 'bk-GZ-2611-0147')
  const reading = visit ? undefined : pending.find(r => r.booking.id === n?.bookingId)?.sla
  const slot = visit && n?.visitId ? getVisit(n.visitId)?.slotStart : undefined
  const params = (n?.params ?? {}) as { client?: string; eventDate?: string; guests?: number; visitors?: number }

  useEffect(() => {
    if (!autoDismiss || mode !== 'live') return
    const id = window.setTimeout(() => setGone(true), 6000)
    return () => window.clearTimeout(id)
  }, [autoDismiss, mode])

  if (!n || gone) return null
  return (
    <div className="ht-banner gz-fade-in" role="alert" data-gz="NewRequestBanner">
      <button type="button" className="gz-reset ht-banner__main gz-press" onClick={onOpen}>
        <span className="ht-banner__disk" aria-hidden="true">
          <Icon name={visit ? 'calendar-plus' : 'bell'} size="sm" />
        </span>
        <span className="ht-banner__text">
          <span className="gz-sr-only">{bi(n.title)}. {bi(n.body)}. </span>
          <span className="ht-banner__title">{params.client ? <UserText role="title">{params.client}</UserText> : <span className="gz-t-title">{bi(n.title)}</span>}</span>
          <FactRow className="ht-banner__facts">
            {slot ? <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={f.dateTime(slot, 'short')} /> : params.eventDate ? <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={dayMonth(params.eventDate)} /> : null}
            {params.guests ? <FactChip icon="users-three" label={t('hotelTodayFactGuests')} value={f.integer(params.guests)} /> : null}
            {params.visitors ? <FactChip icon="users-three" label={t('hotelTodayFactVisitors')} value={f.integer(params.visitors)} /> : null}
            {reading ? <TimeLeft minutes={reading.minutesLeft} tone="gold" say={s => t('hotelTodayWindowEnds', { time: s })} /> : null}
          </FactRow>
        </span>
        <Icon name="chevron-right" size="sm" tone="secondary" />
      </button>
    </div>
  )
}

// ---------------------------------------------------------------- first run (two sheets in sequence)

export type FirstRunStep = 'notifications' | 'biometric'

export type FirstRunContentProps = {
  step: FirstRunStep
  onPrimary?: () => void
  onSkip?: () => void
}

/** The body and the two actions of a first-run sheet. The live navigator draws the sheet around it (title through the sheet options). */
export function FirstRunContent({ step, onPrimary, onSkip }: FirstRunContentProps) {
  const { t, c } = useWords()
  const notifications = step === 'notifications'
  const points: { icon: IconName; name: string; word?: string }[] = notifications
    ? [
        { icon: 'bolt', name: t('hotelTodayFirstRunNotifPointTime'), word: t('hotelTodayFirstRunNotifPointTime') },
        { icon: 'sound', name: t('hotelTodayFirstRunNotifPointSound'), word: t('hotelTodayFirstRunNotifPointSound') },
      ]
    : [
        { icon: 'face-id', name: t('hotelTodayFirstRunFaceId') },
        { icon: 'fingerprint', name: t('hotelTodayFirstRunFingerprint') },
      ]
  return (
    <>
      <div className="ht-sheet__body">
        <Illustration name={notifications ? 'bell' : 'shield'} size="lg" />
        <ul className="ht-sheet__points">
          {points.map(p => (
            <li key={p.icon} className="ht-sheet__point">
              <span className="ht-sheet__glyph" aria-hidden="true">
                <Icon name={p.icon} size="sm" />
              </span>
              {p.word ? <span className="gz-t-body-s">{p.word}</span> : <span className="gz-sr-only">{p.name}</span>}
            </li>
          ))}
        </ul>
        <div className="ht-sheet__meta">
          <span className="ht-sheet__dots" role="img" aria-label={c('commonCounter', { current: notifications ? 1 : 2, total: 2 })}>
            <i className="ht-sheet__dot" data-on={notifications || undefined} />
            <i className="ht-sheet__dot" data-on={!notifications || undefined} />
          </span>
          <InfoButton title={firstRunTitle(step, t)}>{notifications ? t('hotelTodayFirstRunNotifBody') : t('hotelTodayFirstRunLockBody')}</InfoButton>
        </div>
      </div>
      <div className="ht-sheet__footer">
        <Button variant="primary" fullWidth onClick={onPrimary}>
          {notifications ? t('hotelTodayFirstRunNotifAllow') : t('hotelTodayFirstRunLockOn')}
        </Button>
        <Button variant="tertiary" onClick={onSkip}>
          {notifications ? t('hotelTodayFirstRunNotNow') : c('commonActionSkip')}
        </Button>
      </div>
    </>
  )
}

export const firstRunTitle = (step: FirstRunStep, t: ReturnType<typeof useWords>['t']) => (step === 'notifications' ? t('hotelTodayFirstRunNotifTitle') : t('hotelTodayFirstRunLockTitle'))

/** A static frame's own sheet container around the same content (the canvas draws the first-run state without a navigator). */
export function FirstRunSheet({ step, onPrimary, onSkip, onClose, placement = 'overlay', dismissible = true }: FirstRunContentProps & { onClose?: () => void; placement?: 'overlay' | 'inline'; dismissible?: boolean }) {
  const { t } = useWords()
  return (
    <Sheet placement={placement} dismissible={dismissible} title={firstRunTitle(step, t)} onRequestClose={onClose}>
      <FirstRunContent step={step} onPrimary={onPrimary} onSkip={onSkip} />
    </Sheet>
  )
}

// ---------------------------------------------------------------- the venue switcher

export type VenueSwitcherProps = { onSelect?: (venueId: string) => void }

/** Rows of the venue switcher; the live navigator draws the sheet (title through its options), a static frame wraps it in `<Sheet>`. */
export function VenueSwitcherContent({ onSelect }: VenueSwitcherProps) {
  const bi = useBi()
  const f = useFormat()
  const { t } = useWords()
  const pending = usePendingRequests()
  const here = getVenue(VENUE_ID)
  const sister = hotelSettings.sister
  const rows = [
    { id: VENUE_ID, name: here ? bi(here.name) : '', role: t('hotelTodayRoleManager'), pending: pending.length, current: true },
    ...(sister ? [{ id: sister.id, name: t('hotelTodaySwitchSister'), role: t('hotelTodayRoleReception'), pending: sister.pending, current: false }] : []),
  ]
  return (
    <ul className="ht-switch">
      {rows.map(r => (
        <li key={r.id}>
          <button type="button" className="gz-reset ht-switch__row gz-press" aria-current={r.current || undefined} onClick={() => onSelect?.(r.id)}>
            <span className="ht-switch__text">
              <UserText role="d1">{r.name}</UserText>
              <span className="ht-switch__meta gz-t-caption">
                <span>{r.role}</span>
                {r.pending > 0 ? (
                  <FactChip icon="calendar-dots" label={t('hotelTodaySwitchPending', { count: r.pending })} value={f.integer(r.pending)} tone="accent" size="sm" />
                ) : null}
              </span>
            </span>
            {r.current ? <Icon name="check" size="sm" tone="primary" label={t('hotelTodaySwitchCurrent')} /> : null}
          </button>
        </li>
      ))}
    </ul>
  )
}

export function VenueSwitcherSheet({ onSelect, onClose, placement = 'overlay' }: VenueSwitcherProps & { onClose?: () => void; placement?: 'overlay' | 'inline' }) {
  const { t } = useWords()
  return (
    <Sheet placement={placement} title={t('hotelTodaySwitchTitle')} onRequestClose={onClose}>
      <VenueSwitcherContent onSelect={onSelect} />
    </Sheet>
  )
}

