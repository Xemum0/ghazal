// CL-PLAN-02 Request consultation. Covers CA-PLAN-05, CA-PLAN-04, CA-AUTH-10.
// Form (45-word budget; the two-week calendar alone is 14 figures): the package as one tappable row (Change is its chevron), the wedding as
// two facts, up to three time windows picked on a two-week calendar (sun, sunset and moon marks under each day show what is chosen), how
// to be reached as three glyphs, optional notes. Send is a hard gate (ADR 0007 D8): a guest meets the sign-in sheet, and the request
// resumes with everything typed. An open request is never duplicated: the screen shows where it stands instead.
import { useEffect, useRef, useState } from 'react'
import type { IconName } from '@gz/tokens'
import type { PlannerTier } from '@gz/contracts'
import { getVenue, plannerPackages, plannerRequest } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import {
  ActionBar, Banner, EmptyState, Fig, FactChip, Icon, IconSegmented, Price, Screen, SuccessState, TextArea, TopBar, useBi, useNav,
} from '../../../system'
import { SheetHead, TierMarks, TierThumb } from './_components/parts'
import { DayGrid } from './_components/DayGrid'
import { Fx } from './_components/Fx'
import {
  MAX_WINDOWS, WINDOW_PARTS, dayMonth, isoToDate, packageOf, parseWindow, upcomingDays, usePlannerFlow, windowKey,
  type Reach, type WindowPart,
} from './_components/plannerFlow'
import { useViewer } from './_components/useViewer'
import './CL-PLAN-02.css'

export const states = ['validation-error', 'sending', 'success', 'error', 'offline', 'guest-gate', 'open-request-exists']

type Phase = 'idle' | 'sending' | 'success' | 'error'
/** `edit`: the status screen sends the viewer back to change the open request (the form opens with what was sent). */
type Params = { tier?: PlannerTier; edit?: boolean }

const PART_KEY = {
  morning: 'clientPlannerRequestWindowMorning',
  afternoon: 'clientPlannerRequestWindowAfternoon',
  evening: 'clientPlannerRequestWindowEvening',
} as const

/** The session glyphs of the diet (02-text-diet section 2): sun for the morning, sunset for the afternoon, moon for the evening. */
const PART_ICON: Record<WindowPart, IconName> = { morning: 'sun', afternoon: 'sunset', evening: 'moon' }

export default function RequestConsultation() {
  const t = useT('client-planner')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const { lang } = useLang()
  const frame = useFrame()
  const nav = useNav<Params>()
  const { guest, live } = useViewer(frame.state)
  const auth = usePrototype(s => s.auth)
  const draft = usePlannerFlow(s => s.draft)
  const sent = usePlannerFlow(s => s.request)
  const { toggleWindow, setReach, setNote } = usePlannerFlow.getState()
  const state = frame.state

  // A frame state forces what the live phases would produce.
  const [phase, setPhase] = useState<Phase>('idle')
  const [attempted, setAttempted] = useState(false)
  const pending = useRef(false)
  const timers = useRef<number[]>([])
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])

  const windows = state === 'validation-error' ? [] : draft.windows
  const shown: Phase = state === 'sending' ? 'sending' : state === 'success' ? 'success' : state === 'error' ? 'error' : phase
  const showWindowError = (attempted || state === 'validation-error') && windows.length === 0
  const offline = state === 'offline'
  const openRequest = state === 'open-request-exists' || (live && state === undefined && sent !== null && shown !== 'success' && !nav.params.edit)

  const days = upcomingDays(f)
  const firstChosen = windows[0] ? parseWindow(windows[0]).date : undefined
  const [day, setDay] = useState<string>(firstChosen ?? days[0] ?? '')
  const activeDay = days.includes(day) ? day : (days[0] ?? '')
  // The tier the screen was opened with (a package chosen on CL-PLAN-01 or a request being edited) seeds the draft once; after that the
  // picker sheet owns it.
  const [seeded, setSeeded] = useState(false)
  useEffect(() => {
    const tier = nav.params.tier
    if (tier && tier !== usePlannerFlow.getState().draft.tier) usePlannerFlow.getState().setTier(tier)
    setSeeded(true)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
  const pkg = packageOf(seeded ? draft.tier : (nav.params.tier ?? draft.tier))
  const venueId = plannerRequest.venueId ?? 'V01'
  const venue = getVenue(venueId)

  const dayLabel = (iso: string) => f.date(isoToDate(f, iso), 'short')
  const full = windows.length >= MAX_WINDOWS
  const activeParts = windows.filter(k => parseWindow(k).date === activeDay).map(k => parseWindow(k).part)
  const marksOf = (iso: string): IconName[] =>
    WINDOW_PARTS.filter(part => windows.includes(windowKey(iso, part))).map(part => PART_ICON[part])

  // The status screen: back to the one already under this form when the request was being edited, else this screen gives way to it.
  const toStatus = () => (nav.params.edit && nav.canGoBack ? nav.pop() : nav.replace('CL-PLAN-03', { justSent: true }))

  // ---------------------------------------------------------------- sending
  const doSend = () => {
    setPhase('sending')
    timers.current.push(
      window.setTimeout(() => {
        usePlannerFlow.getState().send()
        setPhase('success')
        timers.current.push(
          window.setTimeout(() => {
            toStatus()
            nav.toast({ message: t('clientPlannerRequestSentToast'), tone: 'success' })
          }, 1800),
        )
      }, 900),
    )
  }
  const send = () => {
    setAttempted(true)
    if (draft.windows.length === 0) return
    if (auth === 'guest') {
      // Hard gate (ADR 0007 D8): remember the intent, open the sign-in sheet; sign-in resumes this exact request.
      pending.current = true
      usePrototype.getState().openGate('planner', { screenId: 'CL-PLAN-02', params: { tier: draft.tier } })
      nav.openSheet('CL-AUTH-01', { params: { reason: 'planner' } })
      return
    }
    doSend()
  }
  useEffect(() => {
    if (auth === 'signedIn' && pending.current) {
      pending.current = false
      doSend()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [auth])

  const openPicker = () => {
    nav.openSheet(<PackagePicker />, { dismissible: true })
  }

  const top = <TopBar title={t('clientPlannerRequestTitle')} back={shown === 'success' ? false : 'auto'} />

  // ---------------------------------------------------------------- success and open request: one drawing, one title, one action
  if (shown === 'success') {
    return (
      <Screen top={top}>
        <SuccessState
          illustration="success-request"
          title={t('clientPlannerRequestSuccessTitle')}
          action={{ label: t('clientPlannerViewRequest'), onPress: toStatus }}
        />
      </Screen>
    )
  }

  if (openRequest) {
    return (
      <Screen top={top}>
        <EmptyState
          illustration="empty-bookings"
          title={t('clientPlannerRequestOpenTitle')}
          action={{ label: t('clientPlannerViewRequest'), onPress: () => nav.replace('CL-PLAN-03'), variant: 'primary' }}
        />
      </Screen>
    )
  }

  // ---------------------------------------------------------------- the form
  const sending = shown === 'sending'
  const bar = (
    <ActionBar
      action={{
        label: guest ? t('clientPlannerGuestSignIn') : t('clientPlannerRequestSend'),
        onPress: send,
        loading: sending,
        disabled: offline,
      }}
    />
  )

  const reachOptions: { value: Reach; icon: IconName; label: string }[] = [
    { value: 'chat', icon: 'chat', label: t('clientPlannerRequestReachChat') },
    { value: 'whatsapp', icon: 'whatsapp', label: t('clientPlannerRequestReachWhatsapp') },
    { value: 'phone', icon: 'phone', label: t('clientPlannerRequestReachPhone') },
  ]

  return (
    <Screen top={top} bottom={bar}>
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      {shown === 'error' ? (
        <div className="gzp-gutter gzp2-banner gzp-bannerstack">
          <Banner tone="danger" action={{ label: tc('commonActionRetry'), onPress: send }}>
            {tc('commonStateTitleGeneric')}
          </Banner>
        </div>
      ) : null}

      <div className="gzp2-form" aria-busy={sending || undefined}>
        {/* package and wedding: one row, tap to change */}
        <button
          type="button"
          className="gz-reset gzp-panel gzp2-package gz-press"
          aria-label={`${t('clientPlannerRequestChange')}: ${bi(pkg.name)}`}
          aria-haspopup="dialog"
          onClick={openPicker}
          disabled={sending}
          data-gz-id="plan.package"
        >
          <TierThumb tier={pkg.tier} />
          <span className="gzp2-package__text">
            <span className="gzp-pkg__name">
              <span className="gz-t-d1" lang={lang}>
                {bi(pkg.name)}
              </span>
              <TierMarks tier={pkg.tier} />
            </span>
            <span className="gzp2-package__facts">
              <FactChip icon="hall" size="sm" label={t('clientPlannerWeddingLabel')} value={bi(venue?.name)} />
              <FactChip icon="calendar" size="sm" label={t('clientPlannerWeddingLabel')} value={<Fx text={dayMonth(f, plannerRequest.eventDate)} />} />
            </span>
          </span>
          <Icon name="chevron-down" size="sm" tone="secondary" />
        </button>

        {/* time windows */}
        <section className="gzp2-times" aria-labelledby="gzp2-times-title">
          <div className="gzp-gutter gzp2-times__head">
            <h3 id="gzp2-times-title" className="gzp2-times__title gz-t-title">
              {t('clientPlannerRequestTimesTitle')}
            </h3>
            <span className={`gzp2-count gz-t-fig-body-s${full ? ' is-full' : ''}`}>
              <Fig>{`${f.integer(windows.length)}/${f.integer(MAX_WINDOWS)}`}</Fig>
            </span>
          </div>

          <div className="gzp-gutter">
            <DayGrid
              days={days}
              value={activeDay}
              onPick={setDay}
              name={t('clientPlannerRequestDayLabel')}
              label={iso => {
                const count = windows.filter(k => parseWindow(k).date === iso).length
                return count ? t('clientPlannerRequestDayWithChoices', { day: dayLabel(iso), count }) : dayLabel(iso)
              }}
              marks={marksOf}
              disabled={sending}
              aside={
                <>
                  <Icon name="clock" size="xs" />
                  <span>{tc('commonLabelKuwaitTime')}</span>
                </>
              }
            />
          </div>

          <div className="gzp-gutter">
            <div className="gzp2-parts" role="group" aria-label={t('clientPlannerRequestWindowLabel', { day: dayLabel(activeDay) })}>
              {WINDOW_PARTS.map(part => {
                const on = activeParts.includes(part)
                return (
                  <button
                    key={part}
                    type="button"
                    aria-pressed={on}
                    disabled={sending || (full && !on)}
                    className={`gz-reset gzp2-part gz-press${on ? ' is-on' : ''}`}
                    onClick={() => toggleWindow(windowKey(activeDay, part))}
                    data-gz-id={`part.${part}`}
                  >
                    <Icon name={PART_ICON[part]} size="md" tone={on ? 'accent' : 'secondary'} />
                    <span className={on ? 'gzp2-part__word gz-t-caption' : 'gz-sr-only'}>{t(PART_KEY[part])}</span>
                  </button>
                )
              })}
            </div>
            {showWindowError ? (
              <p className="gzp2-error gz-t-body-s" role="alert">
                <Icon name="warning-circle" size="xs" tone="danger" />
                <span>{t('clientPlannerRequestWindowsError')}</span>
              </p>
            ) : null}
          </div>
        </section>

        {/* reach */}
        <section className="gzp-gutter">
          <IconSegmented<Reach>
            label={t('clientPlannerRequestReachLabel')}
            options={reachOptions}
            value={draft.reach}
            onChange={setReach}
            disabled={sending}
          />
        </section>

        {/* notes */}
        <section className="gzp-gutter">
          <TextArea
            label={t('clientPlannerRequestNotesLabel')}
            optional
            value={draft.note}
            onValueChange={setNote}
            rows={3}
            disabled={sending}
          />
        </section>
      </div>
    </Screen>
  )
}

// ---------------------------------------------------------------- pieces

/** The package sheet: three radio rows (thumb, name and marks, from-price), one tap chooses and closes. */
function PackagePicker() {
  const t = useT('client-planner')
  const bi = useBi()
  const { lang } = useLang()
  const nav = useNav()
  const tier = usePlannerFlow(s => s.draft.tier)
  return (
    <div className="gzp2-picker">
      <SheetHead title={t('clientPlannerTierPickerLabel')} onClose={() => nav.closeSheet()} />
      <div className="gzp2-picker__list" role="radiogroup" aria-label={t('clientPlannerTierPickerLabel')}>
        {plannerPackages.map(p => (
          <button
            key={p.id}
            type="button"
            role="radio"
            aria-checked={p.tier === tier}
            className={`gz-reset gzp2-opt gz-press${p.tier === tier ? ' is-selected' : ''}`}
            onClick={() => {
              usePlannerFlow.getState().setTier(p.tier)
              nav.closeSheet()
            }}
          >
            <TierThumb tier={p.tier} />
            <span className="gzp2-opt__text">
              <span className="gzp-pkg__name">
                <span className="gz-t-d1" lang={lang}>
                  {bi(p.name)}
                </span>
                <TierMarks tier={p.tier} />
              </span>
              <Price fils={p.from.fils} size="strong" prefix={t('clientPlannerFromPrefix')} />
            </span>
            {p.tier === tier ? <span className="gz-bead" aria-hidden="true" /> : null}
          </button>
        ))}
      </div>
    </div>
  )
}
