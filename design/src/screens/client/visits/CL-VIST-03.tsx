// CL-VIST-03 Visit chat. Requirements: CA-VIS-03, CA-VIS-05, CA-VIS-06, CA-CHAT-06, CA-CHAT-07, CA-CHAT-08, CA-CHAT-11.
// The dedicated three-way group chat of one visit: the client, a hotel representative and a Ghazal support representative (the owner's rule:
// the appointment arrival is confirmed in this chat). Text diet (ADR 0034): the bar carries the venue name only; the pinned card under it
// carries the status pill, the three members as monogram discs (one 44 target that opens the member sheet), a "more" glyph for change or
// cancel, the day, window and visitors as icon + value, and the action of the moment (confirm a proposed time, "En route", "Arrived").
// Every bubble run of the other two carries its sender's first name and role chip and aligns by its own first strong character; system
// lines mark the request, the confirmation, the arrival and the close. The composer is the shared one (text, attach, voice); it may queue
// offline, the arrival taps may not. After the slot (24 h) or at once on cancel or decline the chat is read-only: the composer is
// replaced by a lock, one word and a link to the venue thread. What remains on this screen is chat content (authored by the three
// members, exempt from the budget) and the shared bubble, date and tab-bar chrome.
// States: requested, confirmed, reschedule-proposed, day-of, arrived, completed-read-only, declined, cancelled, missed, sending, failed,
// offline-queued, loading, error.
import { Fragment, useEffect, useMemo, useRef, useState } from 'react'
import type { IconName } from '@gz/tokens'
import type { Message, ThreadMember } from '@gz/contracts'
import { PROTOTYPE_NOW, getVenue } from '../../../mock'
import {
  Banner, Button, ChatBubble, ChatDateDivider, EmptyState, ErrorState, FullscreenGallery, Icon, Screen, Skeleton, TopBar, imageSrc, useBi, useNav,
} from '../../../system'
import { useFrame } from '../../../shell/frame'
import { AttachSheet, type AttachPick } from '../messages/_components/AttachSheet'
import { MsgComposer as Composer } from '../messages/_components/MsgComposer'
import { nextPhoto } from '../messages/_components/media'
import { useMsgStore } from '../messages/_components/store'
import { DeliveryLine } from './_components/DeliveryLine'
import { MemberDiscs } from './_components/MemberDiscs'
import { MembersSheet } from './_components/MembersSheet'
import { PinnedVisit } from './_components/PinnedVisit'
import { SenderChip } from './_components/SenderChip'
import { CHAT_STATES, HERO_VISIT, useV, useVisitLocal, useVisitView, type Delivery, type VisitParams } from './_components/model'
import { useVisitActions } from './_components/useVisitActions'
import './CL-VIST-03.css'

export const states = [
  'requested', 'confirmed', 'reschedule-proposed', 'day-of', 'arrived', 'completed-read-only', 'declined', 'cancelled', 'missed', 'sending', 'failed', 'offline-queued', 'loading', 'error',
]

const DOC_NAME = 'visit-notes.pdf'

/** The glyph of a system line: what happened, read from its tag (an id suffix) or the seeded English line. */
function systemIcon(m: Message): IconName {
  const key = `${m.id} ${m.text?.en ?? ''}`.toLowerCase()
  if (/cancel|declin|could not offer/.test(key)) return 'close'
  if (/closed|read-only/.test(key)) return 'lock'
  if (/arriv/.test(key)) return 'pin'
  if (/complete|visit is done/.test(key)) return 'check-double'
  if (/propos|asked/.test(key)) return 'calendar-dots'
  if (/missed/.test(key)) return 'user-minus'
  if (/confirm/.test(key)) return 'calendar-check'
  return 'users-three'
}

type Row = { m: Message; tag?: string }

/** The English line of a system message, matched to the short line of this flow (the seeded and the store's lines are full sentences). */
const SYSTEM_LINES: { test: RegExp; key: 'clientVisitsSysOpened' | 'clientVisitsSysDeclined' | 'clientVisitsSysCancelled' | 'clientVisitsSysArrived' | 'clientVisitsSysCompleted' | 'clientVisitsSysClosed' | 'clientVisitsSysMissed' }[] = [
  { test: /group chat opened/i, key: 'clientVisitsSysOpened' },
  { test: /could not offer/i, key: 'clientVisitsSysDeclined' },
  { test: /cancelled/i, key: 'clientVisitsSysCancelled' },
  { test: /arrival confirmed/i, key: 'clientVisitsSysArrived' },
  { test: /visit is complete/i, key: 'clientVisitsSysCompleted' },
  { test: /missed/i, key: 'clientVisitsSysMissed' },
  { test: /read-only/i, key: 'clientVisitsSysClosed' },
]

export default function VisitChat() {
  const { state } = useFrame()
  const nav = useNav<VisitParams>()
  const bi = useBi()
  const { t, tc, f, lang, live, auth, firstName } = useV()
  const visitId = nav.params.visitId ?? HERO_VISIT
  const viewState = state && CHAT_STATES.includes(state) ? state : state === 'offline-queued' ? 'day-of' : undefined
  const view = useVisitView(visitId, viewState)
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline-queued'
  const guest = live && auth === 'guest'
  const actions = useVisitActions(view, offline)
  const delivery = useVisitLocal(s => s.delivery)
  const onTheWay = useVisitLocal(s => Boolean(s.onTheWay[visitId]))
  const [draft, setDraft] = useState('')
  const [viewer, setViewer] = useState<number | null>(null)
  const [playing, setPlaying] = useState<{ id: string; progress: number } | null>(null)
  const endRef = useRef<HTMLDivElement>(null)

  const venue = view ? getVenue(view.visit.venueId) : undefined
  const venueName = venue ? bi(venue.name) : ''
  const me = view?.members.find(m => m.role === 'client')
  const memberOf = (m: Message): ThreadMember | undefined =>
    view?.members.find(x => x.role === (m.from === 'venue' ? 'hotel_representative' : m.from === 'support' ? 'support' : 'client'))

  // Opening the chat reads it: the unread badge of its inbox row clears.
  useEffect(() => {
    if (live && view && !loading && !error) useMsgStore.getState().open(view.conversationId)
  }, [live, view?.conversationId, loading, error]) // eslint-disable-line react-hooks/exhaustive-deps

  // ---------------------------------------------------------------- rows
  /** A system line says what happened in a few words; the confirmed-visit card repeats the pinned card, so it becomes one line too. */
  const shortLine = (m: Message): Message => {
    const say = (text: string): Message => ({ ...m, kind: 'system', text: { en: text, ar: text } })
    if (m.kind === 'visit_card') return say(t('clientVisitsSysConfirmed'))
    if (m.kind !== 'system') return m
    const en = m.text?.en ?? ''
    const hit = SYSTEM_LINES.find(l => l.test.test(en))
    if (hit) return say(t(hit.key))
    if (/hotel confirmed your visit/i.test(en)) return say(t('clientVisitsSysConfirmed'))
    return m
  }

  const sample = useMemo<Message | null>(() => {
    if (!view || !(state === 'sending' || state === 'failed' || state === 'offline-queued')) return null
    return {
      id: 'sample', conversationId: view.conversationId, from: 'client', senderName: null, at: new Date(Date.parse(PROTOTYPE_NOW) + 60_000).toISOString(), kind: 'text',
      text: { en: t('clientVisitsDemoPending'), ar: t('clientVisitsDemoPending') }, origin: lang, status: 'sent', draft: false,
    }
  }, [view, state, t, lang])
  const sampleDelivery: Delivery | undefined = state === 'sending' ? 'sending' : state === 'failed' ? 'failed' : state === 'offline-queued' ? 'queued' : undefined
  const rows = useMemo<Row[]>(() => (view ? [...view.messages, ...(sample ? [sample] : [])].map(m => ({ m })) : []), [view, sample])
  const photos = useMemo(() => rows.filter(r => r.m.kind === 'image' && r.m.image).map(r => ({ id: r.m.id, src: imageSrc(r.m.image?.file ?? ''), alt: bi(r.m.image?.alt) })), [rows, bi])

  useEffect(() => {
    const body = endRef.current?.closest<HTMLElement>('.gz-screen__body')
    if (body) body.scrollTop = body.scrollHeight
  }, [rows.length, state, loading])

  // A voice note plays by its own length (live only; a static frame never ticks).
  useEffect(() => {
    if (!playing || !live) return
    const seconds = rows.find(r => r.m.id === playing.id)?.m.voice?.seconds ?? 1
    const handle = window.setInterval(() => setPlaying(p => (p && p.progress + 0.1 / seconds < 1 ? { ...p, progress: p.progress + 0.1 / seconds } : null)), 100)
    return () => window.clearInterval(handle)
  }, [playing?.id, live, rows]) // eslint-disable-line react-hooks/exhaustive-deps

  // ---------------------------------------------------------------- actions
  const openChange = () => nav.openSheet('CL-VIST-05', { params: { visitId } })
  const openAnother = () => nav.openSheet('CL-VIST-01', { params: { venueId: view?.visit.venueId } })
  const openVenue = () => nav.push('CL-VENU-01', { venueId: view?.visit.venueId })
  const openVenueThread = () => nav.push('CL-MSGS-02', { venueId: view?.visit.venueId })
  const confirmProposed = () => {
    if (!view) return
    actions.acceptProposed(view.visit)
    nav.toast({ message: t('clientVisitsConfirmedToast'), tone: 'success' })
  }
  const openMembers = () => {
    if (!view) return
    const key = nav.openSheet(
      <MembersSheet
        members={view.members}
        meId={me?.userId}
        onReport={() => {
          nav.closeSheet(key)
          nav.openSheet('CL-MSGS-03', { params: { conversationId: view.conversationId } })
        }}
        onOpenVenue={() => {
          nav.closeSheet(key)
          openVenue()
        }}
      />,
      { title: t('clientVisitsMembersTitle') },
    )
  }
  const openAttach = () => {
    const key = nav.openSheet(
      <AttachSheet
        onPick={(pick: AttachPick) => {
          nav.closeSheet(key)
          if (pick.kind === 'document') return actions.send({ kind: 'document', document: { name: DOC_NAME, sizeKb: 84, mime: 'application/pdf' } })
          const photo = pick.kind === 'recent' ? pick.photo : nextPhoto()
          actions.send({ kind: 'image', image: { file: photo.file, alt: photo.alt } })
        }}
      />,
      { title: t('clientVisitsAttachTitle') },
    )
  }
  const send = (text: string) => {
    actions.send({ kind: 'text', text })
    setDraft('')
  }

  // ---------------------------------------------------------------- guest and states without a thread
  if (guest) {
    return (
      <Screen top={<TopBar title={t('clientVisitsListTitle')} />}>
        <EmptyState illustration="empty-visits" title={t('clientVisitsGuestTitle')} action={{ label: t('clientVisitsGuestAction'), variant: 'primary', onPress: () => nav.openSheet('CL-AUTH-01', { params: { reason: 'visit' } }) }} />
      </Screen>
    )
  }
  if (!view || !venue) return null

  const title = (
    <bdi dir="auto" className="gzvt-ch__title">
      {venueName}
    </bdi>
  )
  const top = (
    <>
      <TopBar title={title} />
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      {loading ? (
        <div className="gzvt-ch__head" aria-busy="true" aria-label={tc('commonStateLoading')}>
          <Skeleton blockSize={112} />
        </div>
      ) : !error ? (
        <div className="gzvt-ch__head">
          <PinnedVisit
            view={view}
            members={<MemberDiscs members={view.members} meId={me?.userId} onOpen={openMembers} />}
            offline={offline}
            onTheWay={onTheWay}
            onChange={openChange}
            onAnother={openAnother}
            onConfirmProposed={confirmProposed}
            onOnTheWay={actions.onTheWay}
            onArrived={actions.arrived}
          />
        </div>
      ) : null}
    </>
  )

  const bottom =
    loading || error ? null : view.closed ? (
      <div className="gzvt-ch__closed" data-gz="ClosedBar">
        <div className="gzvt-ch__closed-in">
          <p className="gzvt-ch__closed-text gz-t-body-s">
            <Icon name="lock" size="sm" tone="secondary" />
            <span>{t('clientVisitsClosed')}</span>
          </p>
          <Button variant="secondary" iconStart="chat" onClick={openVenueThread}>
            {t('clientVisitsMessageVenue')}
          </Button>
        </div>
      </div>
    ) : (
      <Composer value={draft} onChange={setDraft} onSend={send} onAttach={openAttach} onVoice={seconds => actions.send({ kind: 'voice', voice: { seconds } })} onTooShort={() => nav.toast(t('clientVisitsRecordTooShort'))} />
    )

  // ---------------------------------------------------------------- body
  let body
  if (loading) {
    body = (
      <div className="gzvt-ch__skel" aria-busy="true">
        <Skeleton variant="block" inlineSize={248} blockSize={72} />
        <div className="gzvt-ch__skel-end">
          <Skeleton variant="block" inlineSize={216} blockSize={72} />
        </div>
        <Skeleton variant="block" inlineSize={160} blockSize={48} />
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('CL-VIST-03', nav.params)} />
  } else {
    let day = ''
    let lastKey = ''
    body = (
      <div className="gzvt-ch__list">
        {rows.map(({ m }, i) => {
          const d = f.isoDay(m.at)
          const newDay = d !== day
          day = d
          const line = shortLine(m)
          const system = line.kind === 'system'
          const key = system ? 'system' : m.from
          const runStart = newDay || key !== lastKey || lastKey === 'system'
          lastKey = key
          const next = rows[i + 1]?.m
          const nextKey = !next ? '' : next.kind === 'system' ? 'system' : next.from
          const runEnd = nextKey !== key || (next ? f.isoDay(next.at) !== d : true)
          const own = !system && m.from === 'client'
          const isVoice = m.kind === 'voice'
          const pending = own ? (delivery[m.id] ?? (m.id === 'sample' ? sampleDelivery : undefined)) : undefined
          const member = !system && !own && m.from !== 'system' ? memberOf(m) : undefined
          const offer = m.kind === 'booking_card' && m.card?.kind === 'voucher_offer'
          return (
            <Fragment key={m.id}>
              {newDay ? <ChatDateDivider date={m.at} /> : null}
              {system ? (
                <div className="gzvt-msg" data-kind="system">
                  <ChatBubble message={line} side="client" group={systemIcon(m)} />
                </div>
              ) : (
                <div className={`gzvt-msg${runStart && !newDay ? ' is-run-start' : ''}`} data-own={own || undefined} data-kind={m.kind}>
                  {member && runStart && member.role !== 'client' ? <SenderChip role={member.role} name={firstName(lang === 'ar' ? member.name : member.nameLatin)} /> : null}
                  <ChatBubble
                    message={m}
                    side="client"
                    showMeta={runEnd && !pending}
                    playing={isVoice && playing?.id === m.id}
                    progress={isVoice && playing?.id === m.id ? playing.progress : 0}
                    onPlay={isVoice ? () => setPlaying(p => (p?.id === m.id ? null : { id: m.id, progress: 0 })) : undefined}
                    onOpen={m.kind === 'image' ? () => setViewer(Math.max(0, photos.findIndex(p => p.id === m.id))) : undefined}
                  />
                  {offer ? (
                    <div className="gzvt-msg__actions">
                      <Button variant="tertiary" iconStart="ticket" onClick={openVenue}>
                        {t('clientVisitsGetVoucher')}
                      </Button>
                    </div>
                  ) : null}
                  {pending ? <DeliveryLine state={pending} onRetry={() => actions.retry(m.id)} onDiscard={() => actions.discard(m.id)} /> : null}
                </div>
              )}
            </Fragment>
          )
        })}
        <div ref={endRef} aria-hidden="true" />
      </div>
    )
  }

  return (
    <div className="gzvt-ch__root">
      <Screen top={top} bottom={bottom} bodyClassName="gzvt-ch">
        {body}
      </Screen>
      <FullscreenGallery
        open={viewer !== null}
        images={photos.map(p => ({ src: p.src, alt: p.alt }))}
        index={viewer ?? 0}
        onIndexChange={setViewer}
        onClose={() => setViewer(null)}
        label={t('clientVisitsPhotoViewer')}
      />
    </div>
  )
}
