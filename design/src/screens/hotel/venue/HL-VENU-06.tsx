// HL-VENU-06 Booking rules: per hall, how requests work under the voucher model: request to book only (read-only), the reply window, the fixed
// 24 hour confirm window (read-only), the minimum notice, the doors to voucher prices, visit availability and the calendar, and a live
// "What couples see" timeline. No instant booking, deposit, pay window, balance, guest lock, cash or payout verification (ADR 0033).
// Requirements: HA-VMGT-10, HA-DASH-04, HA-AUTH-02, HA-VIS-05
// States: loading, validation, success, error, offline, unsaved-guard.
// Params: `hallId` selects the hall. Values come from the fixtures and the platform configuration.
// Roles: Admin and Manager only (ADR 0008 D12).
import { useState } from 'react'
import { useFrame } from '../../../shell/frame'
import { ChipGroup, Dialog, ErrorState, Icon, ListRow, Screen, SegmentedControl, Stepper, TopBar, useNav } from '../../../system'
import { CouplesTimeline, ModeCard } from './_components/RulesParts'
import { FormSkeleton, Padded, SaveBar, StateStrip, useDraft, useIsStatic } from './_components/editor'
import { FactLine, Figures, Page, ReadOnlyRow, Section, useBi, useUnsavedGuard, useV } from './_components/bits'
import { FieldError } from './_components/fields'
import { useVenueStore, type RulesModel } from './_components/store'
import { REPLY_WINDOWS, halls, platform, venue } from './_components/venue'
import './HL-VENU-06.css'

export const states = ['loading', 'validation', 'success', 'error', 'offline', 'unsaved-guard']

type Rules = Record<string, RulesModel>

export default function BookingRules() {
  const { state } = useFrame()
  const nav = useNav()
  const isStatic = useIsStatic()
  const { t, c } = useV()
  const bi = useBi()
  const hallList = halls()
  const stored = useVenueStore(s => s.rules)
  const requested = typeof nav.params.hallId === 'string' ? nav.params.hallId : hallList[0]?.id
  const [hallId, setHallId] = useState(requested ?? '')
  const { draft, update, dirty, commit } = useDraft<Rules>(() => {
    const base = JSON.parse(JSON.stringify(stored)) as Rules
    const id = hallList[0]?.id
    // The validation frame: a 48 hour reply window with one day of notice, so a couple could be asked for a date before the venue has to answer.
    if (state === 'validation' && id && base[id]) base[id] = { ...base[id], responseHours: 48, minNoticeDays: 1 }
    return base
  })

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const saved = state === 'success'
  const dirtyShown = dirty || state === 'unsaved-guard'
  const guard = useUnsavedGuard(dirtyShown)

  const rules = draft[hallId] ?? draft[hallList[0]?.id ?? '']
  const base = stored[hallId]
  const edit = (patch: Partial<RulesModel>) => update(d => ({ ...d, [hallId]: { ...(d[hallId] as RulesModel), ...patch } }))

  const noticeTooShort = rules !== undefined && rules.minNoticeDays * 24 < rules.responseHours
  const problem = noticeTooShort ? t('hotelVenueNoticeShort') : undefined

  const save = () => {
    if (problem || offline || isStatic) return
    for (const id of Object.keys(draft)) if (JSON.stringify(draft[id]) !== JSON.stringify(stored[id])) useVenueStore.getState().saveRules(draft[id] as RulesModel)
    commit()
    nav.toast({ message: t('hotelVenueToastRulesSaved'), icon: 'check-circle' })
    nav.pop()
  }

  const top = (
    <>
      <TopBar title={t('hotelVenueRulesTitle')} subtitle={bi(venue().name)} onBack={guard} />
      <StateStrip offline={offline} saved={saved} />
    </>
  )

  let body
  if (loading || !rules) {
    body = <FormSkeleton rows={5} />
  } else if (error) {
    body = (
      <Padded>
        <ErrorState kind="load" title={t('hotelVenueErrorTitle')} body={t('hotelVenueErrorBody')} onRetry={() => nav.replace('HL-VENU-06')} />
      </Padded>
    )
  } else {
    const hours = (n: number) => c('commonCountHours', { count: n })
    const days = (n: number) => c('commonCountDays', { count: n })
    const shorter = base !== undefined && rules.responseHours < base.responseHours
    body = (
      <Page>
        {hallList.length > 1 ? (
          <SegmentedControl<string>
            label={t('hotelVenueRulesHall')}
            face="hall"
            value={hallId}
            onChange={setHallId}
            options={hallList.map(h => ({ value: h.id, label: bi(h.name) }))}
          />
        ) : null}

        <Section title={t('hotelVenueSecMode')}>
          <ModeCard />
        </Section>

        <Section title={t('hotelVenueSecResponse')}>
          <ChipGroup<number>
            label={t('hotelVenueRespondLabel')}
            value={rules.responseHours}
            onChange={v => v && edit({ responseHours: v as RulesModel['responseHours'] })}
            options={REPLY_WINDOWS.map(h => ({ value: h, label: <Figures text={hours(h)} /> }))}
          />
          {shorter ? <FactLine icon="warning-circle">{t('hotelVenueRespondWarn')}</FactLine> : null}
        </Section>

        <Section title={t('hotelVenueSecConfirm')}>
          <div className="hv-ro-list">
            <ReadOnlyRow label={t('hotelVenueConfirmLabel')} value={<Figures text={t('hotelVenueConfirmFixed', { hours: hours(platform.confirmWindowHours) })} />} />
          </div>
          <Stepper
            label={t('hotelVenueNoticeDays')}
            value={rules.minNoticeDays}
            min={1}
            max={120}
            step={1}
            onChange={minNoticeDays => edit({ minNoticeDays })}
            valueText={days}
          />
          {noticeTooShort ? <FieldError>{t('hotelVenueNoticeShort')}</FieldError> : null}
        </Section>

        <Section title={t('hotelVenueSecPreview')}>
          <CouplesTimeline rules={rules} />
        </Section>

        <div className="hv-links">
            <ListRow flush leading={<Icon name="ticket" size="md" />} title={t('hotelVenueLinkVoucher')} chevron onClick={() => nav.push('HL-GROW-01')} />
            <ListRow flush leading={<Icon name="clock" size="md" />} title={t('hotelVenueLinkVisits')} chevron onClick={() => nav.push('HL-VIST-05')} />
            <ListRow flush last leading={<Icon name="calendar" size="md" />} title={t('hotelVenueLinkCalendar')} chevron onClick={() => nav.switchTab('calendar')} />
        </div>
      </Page>
    )
  }

  const bar = loading || error ? undefined : <SaveBar dirty={dirtyShown} problem={problem} offline={offline} saved={saved} onSave={save} />

  return (
    <div className="hv-root">
      <Screen top={top} bottom={bar}>
        {body}
      </Screen>
      {state === 'unsaved-guard' ? (
        <Dialog title={t('hotelVenueGuardTitle')} body={t('hotelVenueGuardBody')} icon="warning-circle" tone="destructive" confirmLabel={t('hotelVenueGuardDiscard')} cancelLabel={t('hotelVenueGuardKeep')} />
      ) : null}
    </div>
  )
}
