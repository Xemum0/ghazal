// CL-PROF-04 Notification preferences. Requirements: CA-PROF-06, CA-NOTI-02, CA-NOTI-03, CA-NOTI-04, CA-NOTI-05, CA-NOTI-07, CA-NOTI-08.
//
// What reaches the person, in three groups, text-diet edition (ADR 0034): glyph rows with a one-word name and a switch, no caption under any of
// them. Always on: requests, vouchers, visits (no switch, a check: they are about the KD 2 voucher and appointments). Reminders (on by default):
// confirm the request (the hours to confirm as a timer fact), voucher expiry, visit, countdown; there is no "balance due" because the app takes
// no balance (ADR 0033). Offers and news: one master switch, opt-in and off until turned on; then offers, price drops (halls saved or compared on
// the date) and new halls (preferred governorates). The frequency (at most two a week, none in the final seven days) is behind the info glyph on the
// master row. Channels are chosen per group as three glyph chips after the send mark (email only once an email exists). The quiet hours open a
// sheet; the phone's own permission is shown and links out. Every change saves at once with a quiet toast.
// States: default, os-denied, saving, error, offline-disabled.
import { useState } from 'react'
import { useT } from '../../../i18n'
import { Banner, Button, ChipGroup, FactChip, Icon, IconListRow, InfoButton, Screen, TopBar, useNav } from '../../../system'
import { meta, notificationPrefs } from '../../../mock'
import { Head, Mixed, SwitchRow } from './_components/parts'
import { QuietSheet, useQuietRange } from './_components/quiet'
import { MARKETING_BLACKOUT_DAYS, QUIET_MARKETING, flowDefaults, useLive, useProfileFlow, useSceneState, type Channel, type ProfileFlow } from './_components/useProfile'
import './CL-PROF-04.css'

export const states = ['os-denied', 'saving', 'error', 'offline-disabled']

type Notif = ProfileFlow['notif']

export default function NotificationPreferences() {
  const t = useT('client-profile')
  const c = useT('common')
  const nav = useNav()
  const live = useLive()
  const state = useSceneState()
  const storedNotif = useProfileFlow(s => s.notif)
  const storedOs = useProfileFlow(s => s.osNotifications)
  const email = useProfileFlow(s => s.email)
  const range = useQuietRange()
  const [failed, setFailed] = useState(false)

  const notif: Notif = live ? storedNotif : flowDefaults().notif
  const os = state === 'os-denied' ? 'denied' : live ? storedOs : 'allowed'
  const offline = state === 'offline-disabled'
  const saving = state === 'saving'
  const hasEmail = live ? email.trim() !== '' : false
  const locked = offline
  const hours = meta.config.confirmWindowHours

  const set = (patch: Partial<Notif>) => {
    if (!live) return
    useProfileFlow.getState().setNotif(patch)
    setFailed(false)
    nav.toast({ message: c('commonStateSaved'), icon: 'check' })
  }
  const openSettings = () => nav.toast({ message: t('clientProfileSharedOpeningSettings'), icon: 'external-link' })

  // The three channels as glyphs after the send mark; the word is the accessible name.
  const channelLabel = (icon: 'bell' | 'whatsapp' | 'mail', name: string) => (
    <span className="gzpr-notif__chan">
      <Icon name={icon} size="sm" />
      <span className="gz-sr-only">{name}</span>
    </span>
  )
  const channels = (value: Channel[], onChange: (v: Channel[]) => void, emailHint = false) => (
    <div className="gzpr-pad gzpr-notif__channels">
      <span className="gzpr-notif__send" aria-hidden="true">
        <Icon name="send" size="md" tone="secondary" />
      </span>
      <ChipGroup<Channel>
        label={t('clientProfileNotifChannels')}
        selection="multiple"
        value={value}
        onChange={onChange}
        disabled={locked}
        options={[
          { value: 'push', label: channelLabel('bell', t('clientProfileNotifChannelPush')) },
          { value: 'whatsapp', label: channelLabel('whatsapp', t('clientProfileNotifChannelWhatsapp')) },
          { value: 'email', label: channelLabel('mail', t('clientProfileNotifChannelEmail')), disabled: !hasEmail },
        ]}
      />
      {!hasEmail && emailHint ? (
        <Button variant="tertiary" onClick={() => nav.push('CL-PROF-03')}>
          {t('clientProfileNotifChannelEmailAdd')}
        </Button>
      ) : null}
    </div>
  )

  const always = [
    { icon: 'calendar-check', title: t('clientProfileNotifRequests') },
    { icon: 'ticket', title: t('clientProfileNotifVouchers') },
    { icon: 'calendar-dots', title: t('clientProfileNotifVisits') },
  ] as const

  return (
    <Screen top={<TopBar title={t('clientProfileNotifTitle')} />}>
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className="gzpr-notif" data-gz-id="notification.preferences">
        {os === 'denied' || state === 'error' || failed ? (
          <div className="gzpr-notif__top">
            {os === 'denied' ? (
              <Banner tone="info" icon="bell" action={{ label: c('commonLabelSettings'), onPress: openSettings }}>
                {t('clientProfileNotifDenied')}
              </Banner>
            ) : null}
            {state === 'error' || failed ? (
              <Banner tone="danger" action={{ label: c('commonActionRetry'), onPress: () => setFailed(false) }}>
                {t('clientProfileSharedSaveFailed')}
              </Banner>
            ) : null}
          </div>
        ) : null}

        <section className="gzpr-section" aria-label={t('clientProfileNotifGroupAlways')}>
          <div className="gzpr-pad">
            <Head title={t('clientProfileNotifGroupAlways')} />
          </div>
          <div className="gzpr-list">
            {always.map((r, i) => (
              <IconListRow
                key={r.icon}
                icon={r.icon}
                title={r.title}
                trailing={
                  <>
                    <Icon name="check-circle" size="sm" tone="secondary" />
                    <span className="gz-sr-only">{t('clientProfileSharedOn')}</span>
                  </>
                }
                last={i === always.length - 1}
              />
            ))}
          </div>
        </section>

        <section className="gzpr-section" aria-label={t('clientProfileNotifGroupReminders')}>
          <div className="gzpr-pad">
            <Head title={t('clientProfileNotifGroupReminders')} />
          </div>
          <div className="gzpr-list">
            <SwitchRow
              icon="timer"
              title={t('clientProfileNotifConfirm')}
              label={t('clientProfileNotifConfirm')}
              fact={<FactChip icon="timer" value={<Mixed>{c('commonCountHours', { count: hours })}</Mixed>} label={t('clientProfileNotifConfirmFact')} tone="muted" size="sm" />}
              checked={notif.confirmWindow}
              onChange={confirmWindow => set({ confirmWindow })}
              disabled={locked}
              busy={saving}
            />
            <SwitchRow
              icon="hourglass"
              title={t('clientProfileNotifVoucherExpiry')}
              label={t('clientProfileNotifVoucherExpiry')}
              checked={notif.voucherExpiry}
              onChange={voucherExpiry => set({ voucherExpiry })}
              disabled={locked}
            />
            <SwitchRow
              icon="calendar-dots"
              title={t('clientProfileNotifVisitReminders')}
              label={t('clientProfileNotifVisitReminders')}
              checked={notif.visitReminders}
              onChange={visitReminders => set({ visitReminders })}
              disabled={locked}
            />
            <SwitchRow
              icon="countdown"
              title={t('clientProfileNotifMilestones')}
              label={t('clientProfileNotifMilestones')}
              checked={notif.milestones}
              onChange={milestones => set({ milestones })}
              disabled={locked}
              last
            />
          </div>
          {channels(notif.reminderChannels, reminderChannels => set({ reminderChannels }), true)}
        </section>

        <section className="gzpr-section" aria-label={t('clientProfileNotifGroupMarketing')}>
          <div className="gzpr-list">
            <SwitchRow
              icon="megaphone"
              title={t('clientProfileNotifGroupMarketing')}
              label={t('clientProfileNotifGroupMarketing')}
              checked={notif.marketing}
              onChange={marketing => set({ marketing })}
              disabled={locked}
              last={!notif.marketing}
              info={
                <InfoButton title={t('clientProfileNotifFrequencyTitle')}>
                  {t('clientProfileNotifFrequency', { count: notificationPrefs.maxMarketingPerWeek, days: MARKETING_BLACKOUT_DAYS })}
                </InfoButton>
              }
            />
            {notif.marketing ? (
              <>
                <SwitchRow nested icon="offer" title={t('clientProfileNotifOffers')} label={t('clientProfileNotifOffers')} checked={notif.offers} onChange={offers => set({ offers })} disabled={locked} />
                <SwitchRow nested icon="trend-down" title={t('clientProfileNotifPriceDrops')} label={t('clientProfileNotifPriceDrops')} checked={notif.priceDrops} onChange={priceDrops => set({ priceDrops })} disabled={locked} />
                <SwitchRow nested icon="venue" title={t('clientProfileNotifNewVenues')} label={t('clientProfileNotifNewVenues')} checked={notif.newVenues} onChange={newVenues => set({ newVenues })} disabled={locked} last />
              </>
            ) : null}
          </div>
          {notif.marketing ? channels(notif.marketingChannels, marketingChannels => set({ marketingChannels })) : null}
        </section>

        <div className="gzpr-list">
          <IconListRow
            icon="moon"
            title={t('clientProfileNotifQuiet')}
            facts={<FactChip icon="clock" value={<Mixed>{range(QUIET_MARKETING)}</Mixed>} label={t('clientProfileNotifQuiet')} tone="muted" size="sm" />}
            chevron
            onClick={() => nav.openSheet(<QuietSheet />)}
            last={os === 'denied'}
          />
          {os === 'denied' ? null : (
            <IconListRow
              icon="phone"
              title={t('clientProfileNotifPhone')}
              trailing={t('clientProfileSharedOn')}
              chevron
              onClick={openSettings}
              last
            />
          )}
        </div>
      </div>
    </Screen>
  )
}
