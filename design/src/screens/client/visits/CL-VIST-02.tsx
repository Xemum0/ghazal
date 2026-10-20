// CL-VIST-02 Visit requested. Requirements: CA-VIS-02, CA-VIS-03, CA-NOTI-02.
// Text diet (ADR 0034): the visit drawing beside a two-word title and the three chat members as discs, one summary card (venue, then the
// day, the arrival window and the visitors as icon + value), and the four steps of a visit on one gold thread with a word only under the
// step in progress. The three sentences (waiting for the hotel, what happens next) are gone: the thread says where things stand, and it
// is also the status (the "Requested" chip would repeat the title). No celebratory language (the one warm moment of a flow stays at booking confirmation). "Open chat" is the one gold
// action; two seconds after the request the chat opens by itself unless the person taps Stay (never under reduced motion, never while the
// notification pre-prompt is up). After the first request the OS notification pre-prompt rises as a sheet, once per session, never at launch.
// States: default, auto-redirecting, offline.
import { useEffect, useRef, useState } from 'react'
import { getVenue } from '../../../mock'
import { ActionBar, Banner, Button, Icon, IconProgress, Illustration, Screen, TopBar, useNav, type IconProgressStep } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { MemberDiscs } from './_components/MemberDiscs'
import { VenueLine } from './_components/VenueLine'
import { VisitFacts } from './_components/VisitFacts'
import { REDIRECT_MS, useV, useVisitView, type VisitParams } from './_components/model'
import { PromptSheet } from '../messages/_components/PromptSheet'
import { useMsgStore } from '../messages/_components/store'
import './CL-VIST-02.css'

export const states = ['auto-redirecting', 'offline']

export default function VisitRequested() {
  const { state } = useFrame()
  const nav = useNav<VisitParams>()
  const { t, tc, live } = useV()
  const view = useVisitView(nav.params.visitId, nav.params.visitId ? undefined : 'requested')
  const promptShown = useMsgStore(s => s.promptShown)
  const permission = useMsgStore(s => s.permission)
  const [stay, setStay] = useState(false)
  const timer = useRef<number | null>(null)

  const visit = view?.visit
  const venue = visit ? getVenue(visit.venueId) : undefined
  const me = view?.members.find(m => m.role === 'client')
  const offline = state === 'offline'
  // The prompt comes first the very first time; otherwise the chat opens by itself after two seconds.
  const willPrompt = !promptShown && permission === 'unknown'
  const reduce = typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches
  const redirecting = state === 'auto-redirecting' || (live && !stay && !willPrompt && !reduce && !offline)

  const openChat = () => {
    if (!visit) return
    nav.replace('CL-VIST-03', { visitId: visit.id })
  }
  const back = () => (nav.canGoBack ? nav.pop() : nav.replace('CL-VENU-01', { venueId: visit?.venueId }))

  useEffect(() => {
    if (!live || !redirecting || !visit) return
    timer.current = window.setTimeout(openChat, REDIRECT_MS)
    return () => {
      if (timer.current !== null) window.clearTimeout(timer.current)
    }
  }, [live, redirecting, visit?.id]) // eslint-disable-line react-hooks/exhaustive-deps

  // The notification pre-prompt: once, a beat after the screen has settled, over this screen.
  useEffect(() => {
    if (!live || !willPrompt || offline) return
    const id = window.setTimeout(() => {
      useMsgStore.getState().markPromptShown()
      setStay(true)
      nav.openSheet(<PromptSheet />)
    }, 1200)
    return () => window.clearTimeout(id)
  }, [live, willPrompt, offline]) // eslint-disable-line react-hooks/exhaustive-deps

  if (!view || !visit || !venue) return null

  // The four steps of a visit; the request is on record, the hotel's answer is what is awaited (a knot ties only on a recorded event).
  const steps: IconProgressStep[] = [
    { key: 'request', icon: 'send', label: t('clientVisitsStepRequest'), state: 'tied' },
    { key: 'confirm', icon: 'calendar-check', label: t('clientVisitsStepConfirm'), state: 'now' },
    { key: 'way', icon: 'navigate', label: t('clientVisitsStepWay'), state: 'open' },
    { key: 'arrival', icon: 'pin', label: t('clientVisitsStepArrival'), state: 'open' },
  ]

  const top = <TopBar back={false} />
  const bottom = (
    <ActionBar
      action={{ label: t('clientVisitsOpenChat'), onPress: openChat, iconEnd: 'chat', disabled: offline }}
      secondary={{ label: t('clientVisitsBackToVenue'), onPress: back }}
    />
  )

  return (
    <Screen top={top} bottom={bottom} bodyClassName="gzvt-rq">
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      <div className="gzvt-rq__page">
        <header className="gzvt-rq__hero">
          <span className="gzvt-rq__art" aria-hidden="true">
            <Illustration name="success-visit" size="lg" />
          </span>
          <div className="gzvt-rq__heading">
            <h1 className="gzvt-rq__title gz-t-d3">{t('clientVisitsRequestedTitle')}</h1>
            <MemberDiscs members={view.members} meId={me?.userId} />
          </div>
        </header>

        <section className="gzvt-rq__card" aria-label={t('clientVisitsSummary')} data-gz-id="visits.summary">
          <VenueLine venue={venue} />
          <div className="gzvt-rq__facts">
            <VisitFacts slotStart={visit.slotStart} slotEnd={visit.slotEnd} visitors={visit.visitors} compact />
          </div>
          {visit.note ? (
            <p className="gzvt-rq__note gz-t-body-s gz-clamp-2" dir="auto">
              <Icon name="chat-text" size="xs" tone="secondary" />
              <span>{visit.note}</span>
            </p>
          ) : null}
        </section>

        <section className="gzvt-rq__thread" aria-label={t('clientVisitsStepsLabel')}>
          <IconProgress steps={steps} label={t('clientVisitsStepsLabel')} draw="mount" />
        </section>

        {redirecting ? (
          <div className="gzvt-rq__redirect" role="status">
            <span className="gzvt-rq__line" aria-hidden="true" data-live={live || undefined} style={live ? { animationDuration: `${REDIRECT_MS}ms` } : undefined} />
            <div className="gzvt-rq__redirect-row">
              <span className="gz-t-body-s">{t('clientVisitsRedirecting')}</span>
              <Button variant="tertiary" onClick={() => setStay(true)}>
                {t('clientVisitsStay')}
              </Button>
            </div>
          </div>
        ) : null}
      </div>
    </Screen>
  )
}
