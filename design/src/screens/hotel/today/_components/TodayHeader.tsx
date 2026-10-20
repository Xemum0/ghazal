// The Ink band of the Today screen (direction 3 "Ink panels", rule 9), in two parts so it costs little of a small screen:
//   TodayBar    pinned under the status bar: the venue switcher (serif name) and the bell with its unread count, 56 high
//   TodayIntro  the first block of the scroll body, still on Ink: the day as a quiet caption and the status as a figure (a glyph, a
//               number, the time left), closed by a 1 px gold-500 rule (the khayt)
// Serif only for the venue name (rule 1). The greeting is gone (text diet: no greeting banner); the status is a number, not a sentence.
// The status bar over the band turns light.
import type { ReactNode } from 'react'
import { getVenue } from '../../../../mock'
import { useT } from '../../../../i18n'
import { useStatusTone } from '../../../../shell/device/context'
import { CountBadge, Figures, Icon, IconButton } from '../../../../system'
import { useBi, useDateLine, usePartnerIdentity, VENUE_ID, type AccountKind, type TodayRole } from './bits'
import './today-header.css'

export type TodayBarProps = {
  /** The partner behind the account: the hotel (default) or the service provider, which has one name and no switcher. */
  account?: AccountKind
  unread: number
  /** Offline: the persistent stamp (a glyph and the time of the last update) sits on the band under the venue row (ADR 0008 D10). */
  stamp?: string
  /** The venue chip opens the switcher only when the account has more than one venue. */
  multiVenue?: boolean
  onVenue?: () => void
  onBell?: () => void
}

export function TodayBar({ account = 'venue', unread, stamp, multiVenue = true, onVenue, onBell }: TodayBarProps) {
  const t = useT('hotel-today')
  const bi = useBi()
  const venue = getVenue(VENUE_ID)
  useStatusTone('light')
  const identity = usePartnerIdentity(account)
  const name = identity ? bi(identity.partnerName) : venue ? bi(venue.name) : ''
  const chip = (
    <>
      <span className="ht-head__venue gz-t-d1">{name}</span>
      {multiVenue ? <Icon name="chevron-down" size="sm" tone="on-dark" /> : null}
    </>
  )
  return (
    <header className="ht-bar gz-on-dark" data-gz="TodayBar">
      <div className="ht-bar__row">
        {multiVenue ? (
          <button type="button" className="gz-reset ht-head__chip gz-press" onClick={onVenue} aria-haspopup="dialog" aria-label={t('hotelTodaySwitchVenue', { venue: name })}>
            {chip}
          </button>
        ) : (
          <div className="ht-head__chip">{chip}</div>
        )}
        <span className="ht-head__bell">
          <IconButton icon="bell" variant="on-scrim" label={unread > 0 ? t('hotelTodayBellUnread', { count: unread }) : t('hotelTodayBell')} onClick={onBell} />
          {unread > 0 ? (
            <span className="ht-head__count" aria-hidden="true">
              <CountBadge count={unread} max={9} />
            </span>
          ) : null}
        </span>
      </div>
      {stamp ? (
        <p className="ht-head__stamp gz-t-caption" role="status">
          <Icon name="offline" size="xs" tone="on-dark" />
          <span aria-hidden="true">
            <Figures text={stamp} />
          </span>
          <span className="gz-sr-only">{t('hotelTodayOfflineStamp', { time: stamp })}</span>
        </p>
      ) : null}
    </header>
  )
}

export type TodayIntroProps = {
  role?: TodayRole
  account?: AccountKind
  /** The status as a figure (a node, so a loading frame can draw a skeleton in its place). */
  status?: ReactNode
}

export function TodayIntro({ role = 'manager', account = 'venue', status }: TodayIntroProps) {
  const t = useT('hotel-today')
  const dateLine = useDateLine()
  // The role is named only where it is not the default Manager, so the three role variants say whose Today this is.
  const roleWord = account === 'venue' && role !== 'manager' ? t(role === 'reception' ? 'hotelTodayRoleReception' : role === 'accountant' ? 'hotelTodayRoleAccountant' : 'hotelTodayRoleMarketing') : null
  return (
    <div className="ht-intro gz-on-dark" data-gz="TodayIntro">
      <p className="ht-head__date gz-t-caption">
        <Figures text={dateLine} />
        {roleWord ? (
          <>
            <span className="ht-head__dot" aria-hidden="true" />
            <span>{roleWord}</span>
          </>
        ) : null}
      </p>
      {status ? <div className="ht-head__status">{status}</div> : null}
    </div>
  )
}
