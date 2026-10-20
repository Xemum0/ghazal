// HL-SETT-02 Notification preferences. Requirement IDs: HA-NOTI-08, HA-NOTI-01, HA-NOTI-02, HA-NOTI-03, HA-NOTI-04, HA-NOTI-05, HA-AUTH-02.
// Which alerts reach this phone, limited by role: a type a role cannot receive is hidden, never locked. New booking requests lead the screen
// with their own drawing (a bell), a lock glyph (always on for the roles that act on them) and a play control for the alert sound; business
// hours are one row below it. Every other alert is a glyph, one word and a switch. If the OS permission is off, one callout says so with
// Open Settings and the consequence behind its (i); nothing else is blocked. Changes save at once with "Saved"; offline pauses the switches.
// Text diet (ADR 0034): no sentence is on the screen. What each alert covers, that WhatsApp is the system's and that there is no marketing
// push sit in the sheet of the top bar's (i). Alerts are drawn in four quiet groups with space between them instead of four headings.
// Voucher model (ADR 0033): requests, client confirmations, vouchers redeemed, visits and chat, listing review decisions and plan expiry;
// balances, refunds and instant booking are gone.
// States: loading, error, offline, push-denied, role-limited.
import { useEffect, useRef, useState } from 'react'
import { useFrame } from '../../../shell/frame'
import { Banner, Button, ErrorState, FactChip, IconButton, IconListRow, InfoButton, Screen, Skeleton, TopBar, useNav } from '../../../system'
import { useAccount, useWords } from './_components/bits'
import { Callout } from './_components/Callout'
import { AboutSheet, PrefRow } from './_components/NotifParts'
import { ACCESS, NOTIF_GLYPH, NOTIF_ROLES, PROVIDER_HIDDEN, roleOfState, type NotifType } from './_components/model'
import { useSettingsLocal, type PrefKey } from './_components/store'
import './HL-SETT-02.css'

export const states = ['loading', 'error', 'offline', 'push-denied', 'role-limited']

const SOUND_MS = 1800

type Kind = Exclude<NotifType, 'newRequest'>
const TITLE = {
  confirmations: 'hotelSettingsNotifConfirmations',
  cancelled: 'hotelSettingsNotifCancelled',
  redemptions: 'hotelSettingsNotifRedemptions',
  visits: 'hotelSettingsNotifVisits',
  messages: 'hotelSettingsNotifMessages',
  reviews: 'hotelSettingsNotifReviews',
  listing: 'hotelSettingsNotifListing',
  plan: 'hotelSettingsNotifPlan',
} as const satisfies Record<Kind, string>

const GROUPS: readonly { id: string; types: readonly NotifType[] }[] = [
  { id: 'requests', types: ['newRequest', 'confirmations', 'cancelled'] },
  { id: 'vouchers', types: ['redemptions', 'visits'] },
  { id: 'talk', types: ['messages', 'reviews'] },
  { id: 'listing', types: ['listing', 'plan'] },
]

export default function NotificationPrefs() {
  const { state } = useFrame()
  const nav = useNav()
  const { t, c } = useWords()
  const role = roleOfState(state)
  const account = useAccount()
  const prefs = useSettingsLocal(s => s.prefs)
  const offline = state === 'offline'
  const pushOff = state === 'push-denied'
  const [playing, setPlaying] = useState(false)
  const [about, setAbout] = useState(false)
  const timer = useRef<number | undefined>(undefined)
  const savedToast = useRef<string | null>(null)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const play = () => {
    setPlaying(true)
    window.clearTimeout(timer.current)
    timer.current = window.setTimeout(() => setPlaying(false), SOUND_MS)
  }
  const change = (key: PrefKey, on: boolean) => {
    if (offline) {
      nav.toast({ message: c('commonStateOffline'), icon: 'offline' })
      return
    }
    useSettingsLocal.getState().setPref(key, on)
    if (savedToast.current) nav.dismissToast(savedToast.current)
    savedToast.current = nav.toast({ message: c('commonStateSaved'), icon: 'check-circle' })
  }

  const canHours = ACCESS[role].hours !== 'none' && account.type === 'venue'
  // A service provider has no visits and no venue reviews; a major hotel has no plan to expire.
  const visible = (type: NotifType) => NOTIF_ROLES[type].includes(role) && !(account.type === 'provider' && PROVIDER_HIDDEN.includes(type)) && !(type === 'plan' && account.major)

  const row = (type: NotifType, last: boolean) => {
    if (type === 'newRequest') {
      return (
        <div key={type} className="hs-notif__lead">
          <IconListRow
            illustration="bell"
            title={t('hotelSettingsNotifNewRequest')}
            trailing={
              <span className="hs-notif__ctrl">
                <FactChip icon="lock" label={t('hotelSettingsNotifAlwaysOn')} />
                <IconButton
                  icon={playing ? 'sound' : 'play'}
                  iconSize="sm"
                  variant="outline"
                  disk="sm"
                  label={playing ? t('hotelSettingsNotifPlaying') : t('hotelSettingsNotifPlaySound')}
                  aria-live="polite"
                  onClick={play}
                />
              </span>
            }
            last={!canHours}
          />
          {canHours ? <IconListRow icon="clock" title={t('hotelSettingsMoreHours')} chevron onClick={() => nav.push('HL-SETT-05')} last /> : null}
        </div>
      )
    }
    return <PrefRow key={type} icon={NOTIF_GLYPH[type]} title={t(TITLE[type as Kind])} checked={prefs[type as PrefKey]} onChange={on => change(type as PrefKey, on)} disabled={offline} last={last} />
  }

  let body
  if (state === 'loading') {
    body = (
      <div className="hs-page__skeleton" aria-busy="true" aria-label={c('commonStateLoading')}>
        <Skeleton variant="block" blockSize={128} />
        {[0, 1, 2, 3, 4].map(i => (
          <Skeleton key={i} variant="line" blockSize={48} />
        ))}
      </div>
    )
  } else if (state === 'error') {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-SETT-02')} />
  } else {
    body = (
      <>
        {pushOff ? (
          <div className="hs-page__pad">
            <Callout
              icon="bell"
              title={t('hotelSettingsNotifPushOffTitle')}
              role="alert"
              info={<InfoButton title={t('hotelSettingsNotifPushOffTitle')}>{t('hotelSettingsNotifPushOffBody')}</InfoButton>}
              action={
                <Button variant="secondary" iconStart="settings" onClick={() => nav.toast({ message: t('hotelSettingsNotifPushOffToast'), icon: 'external-link' })}>
                  {t('hotelSettingsNotifPushOffAction')}
                </Button>
              }
            />
          </div>
        ) : null}
        {GROUPS.map(group => {
          const types = group.types.filter(visible)
          if (types.length === 0) return null
          return (
            <section key={group.id} className="hs-notif__group" data-group={group.id}>
              {types.map((type, i) => row(type, i === types.length - 1))}
            </section>
          )
        })}
      </>
    )
  }

  const aboutLines = [
    ...(visible('newRequest') ? [{ icon: 'bell' as const, text: t('hotelSettingsNotifAboutLock') }, { icon: 'moon' as const, text: t('hotelSettingsNotifAboutQuiet') }] : []),
    { icon: 'mail' as const, text: t('hotelSettingsNotifAboutChannel') },
  ]

  return (
    <Screen top={<TopBar title={t('hotelSettingsMoreNotifications')} actions={[{ icon: 'info', label: c('commonA11yInfo'), onPress: () => setAbout(true) }]} />}>
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className="hs-page hs-page--groups">{body}</div>
      <AboutSheet open={about} onClose={() => setAbout(false)} title={t('hotelSettingsNotifAboutTitle')} lines={aboutLines} />
    </Screen>
  )
}
