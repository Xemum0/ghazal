// HL-VIST-03 Visit chat. Requirement IDs: HA-VIS-03, HA-VIS-06, HA-MSG-02, HA-MSG-03, HA-AUTH-02.
// The dedicated group chat of one visit as the hotel representative reads it: exactly three roles (the client, the hotel representative,
// a Ghazal support representative), member-only (ADR 0033 D9). The header shows the three role chips (a tap opens the member sheet); the
// visit card is pinned under it with the action for the state; every message carries its sender role; the composer is the Today thread's
// (text, attach, voice) with three quick replies. The chat closes read-only 24 hours after the slot, or at once on decline or cancel.
// Admin and Manager read every visit chat; other staff only the ones they are assigned to. Support cannot be removed or blocked.
// States: default, confirmed, day-of, arrived, closed-read-only, declined, sending, failed, offline-queued, loading, error, role-read-only
import { Fragment, useEffect, useMemo, useRef, useState } from 'react'
import type { Message, ThreadRole } from '../../../mock'
import { getVenue, messagesFor } from '../../../mock'
import { useFormat } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { Banner, Button, ChatBubble, ChatDateDivider, ErrorState, Icon, ParticipantStrip, Screen, Skeleton, TopBar, useNav } from '../../../system'
import { Composer, type QuickReply } from '../today/_components/Composer'
import { ChatPinned } from './_components/ChatPinned'
import { Notice, useWords } from './_components/bits'
import { stamp, useChatRows, type ChatRow } from './_components/chat'
import { useVisitActions } from './_components/actions'
import {
  HERO_REQUESTED,
  VENUE_ID,
  canSee,
  deriveVisit,
  isChatClosed,
  isLead,
  roleOfParam,
  scriptOf,
  staffById,
  useRepresentativeId,
  useVisitById,
  useVisitConversation,
  variantOfState,
} from './_components/model'
import { useVisitsLocal } from './_components/store'
import './HL-VIST-03.css'

export const states = ['default', 'confirmed', 'day-of', 'arrived', 'closed-read-only', 'declined', 'sending', 'failed', 'offline-queued', 'loading', 'error', 'role-read-only']

const ROLE_OF: Partial<Record<Message['from'], ThreadRole>> = { client: 'client', venue: 'hotel_representative', support: 'support' }

export default function VisitChat() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { lang } = useLang()
  const { t, c } = useWords()
  const act = useVisitActions()
  const params = nav.params as { visitId?: string; role?: string }
  const role = roleOfParam(params.role)

  // ---- which visit this frame draws: the live visit, or a seed visit in the status the state names
  const stored = useVisitById(params.visitId ?? HERO_REQUESTED)
  const variant = state === 'default' ? 'requested' : state === 'sending' || state === 'failed' || state === 'offline-queued' ? 'confirmed' : variantOfState(state, 'confirmed')
  const framed = state !== undefined && state !== 'loading' && state !== 'error' && state !== 'role-read-only'
  const visit = framed ? deriveVisit(variant) : (stored ?? deriveVisit('requested'))
  const { conversation, base } = useVisitConversation(visit)
  const repId = useRepresentativeId(visit)
  const session = usePrototype(s => Boolean(s.visitChats[visit.id]))

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline-queued'
  const closed = isChatClosed(visit)
  // Admin and Manager read every chat; Reception (and anyone else with the visit permission) only the ones they are assigned to.
  const assigned = role === 'reception' ? repId === 'user-amal' : true
  const readOnlyRole = state === 'role-read-only' || (canSee(role) && !isLead(role) && !assigned)
  const canWrite = canSee(role) && !closed && !readOnlyRole
  const canAct = canSee(role) && !readOnlyRole

  // ---- a frame's own sample message (sending, failed, queued): the same bubble the thread draws for something typed now
  const sample = useMemo<ChatRow[]>(() => {
    const delivery = state === 'sending' ? 'sending' : state === 'failed' ? 'failed' : state === 'offline-queued' ? 'queued' : null
    if (!delivery || !conversation) return []
    const text = t('hotelVisitsQrConfirmText')
    const message: Message = { id: 'sample-local', conversationId: conversation.id, from: 'venue', senderName: null, at: stamp(0), kind: 'text', text: { en: text, ar: text }, origin: lang, status: 'sent', draft: false }
    return [{ message, delivery, local: true }]
  }, [state, conversation, lang, t])

  const rows = useChatRows(visit, conversation, loading ? [] : base, sample)
  const endRef = useRef<HTMLDivElement>(null)
  const [playing, setPlaying] = useState<string | null>(null)

  useEffect(() => {
    const body = endRef.current?.closest<HTMLElement>('.gz-screen__body')
    if (body) body.scrollTop = body.scrollHeight
  }, [rows.length, state])

  // ---- sending (ADR 0008 D10: chat may queue offline)
  const post = (m: Partial<Message> & Pick<Message, 'kind'>) => {
    if (!conversation) return
    const n = useVisitsLocal.getState().posts[visit.id]?.length ?? 0
    const rep = conversation.members?.find(x => x.role === 'hotel_representative')
    const id = `local-${visit.id}-${n + 1}`
    const message: Message = {
      id,
      conversationId: conversation.id,
      from: 'venue',
      senderName: rep?.nameLatin ?? null,
      at: stamp(n + 1),
      text: null,
      origin: m.text ? scriptOf(m.text[lang]) : lang,
      status: 'sent',
      draft: false,
      ...m,
    }
    useVisitsLocal.getState().post(visit.id, { message, delivery: offline ? 'queued' : 'sending' })
    if (!offline) window.setTimeout(() => useVisitsLocal.getState().patchPost(visit.id, id, { delivery: 'sent' }), 700)
  }
  const sendText = (text: string) => {
    if (session) usePrototype.getState().sendVisitMessage(visit.id, 'venue', text)
    else post({ kind: 'text', text: { en: text, ar: text } })
  }
  const retry = (id: string) => {
    useVisitsLocal.getState().patchPost(visit.id, id, { delivery: 'sending' })
    window.setTimeout(() => useVisitsLocal.getState().patchPost(visit.id, id, { delivery: 'sent' }), 700)
  }
  const attach = (kind: 'camera' | 'photo' | 'document') => {
    if (kind === 'document') {
      const doc = messagesFor('conv-aurelia-reem', 'hotel').find(m => m.kind === 'document')?.document
      if (doc) post({ kind: 'document', document: doc })
      return
    }
    const photo = getVenue(VENUE_ID)?.gallery.find(g => g.zone === 'hall')
    if (photo) post({ kind: 'image', image: { file: photo.file, alt: photo.alt } })
  }

  const quick: QuickReply[] = [
    { id: 'confirm', label: t('hotelVisitsQrConfirm'), text: t('hotelVisitsQrConfirmText') },
    { id: 'entrance', label: t('hotelVisitsQrEntrance'), text: t('hotelVisitsQrEntranceText') },
    { id: 'parking', label: t('hotelVisitsQrParking'), text: t('hotelVisitsQrParkingText') },
  ]

  // ---- header: title row, the three role chips, then the pinned visit
  const top = (
    <>
      <TopBar
        title={t('hotelVisitsChatTitle')}
        actions={[{ icon: 'users-three', label: t('hotelVisitsMembersTitle'), onPress: () => conversation?.members && act.members(conversation.members) }]}
      />
      {offline ? <Banner tone="offline">{t('hotelVisitsChatOfflineBanner', { time: f.time(f.now()) })}</Banner> : null}
      {!loading && !error && conversation?.members ? (
        <div className="hv-chat__head">
          <ParticipantStrip members={conversation.members} onOpen={() => act.members(conversation.members ?? [])} />
          <ChatPinned
            visit={visit}
            canAct={canAct}
            offline={offline}
            onOpen={() => nav.push('HL-VIST-02', { visitId: visit.id })}
            onConfirm={() => act.confirm(visit)}
            onPropose={() => act.propose(visit)}
            onArrived={() => act.arrival(visit)}
          />
        </div>
      ) : null}
    </>
  )

  // ---- bottom: the composer, or why there is none
  const staff = staffById(repId)
  const repName = staff ? (lang === 'ar' ? staff.name : staff.nameLatin) : ''
  const closedWhy = visit.status === 'declined' ? t('hotelVisitsChatClosedDeclined') : visit.status === 'cancelled' ? t('hotelVisitsChatClosedCancelled') : t('hotelVisitsChatClosedAfter')
  let bottom
  if (loading || error) bottom = undefined
  else if (closed) {
    bottom = (
      <div className="hv-chat__readonly" role="status">
        <Icon name="lock" size="sm" tone="secondary" />
        <p className="gz-t-body-s">{closedWhy}</p>
      </div>
    )
  } else if (!canWrite) {
    bottom = (
      <div className="hv-chat__readonly" role="status">
        <Icon name="lock" size="sm" tone="secondary" />
        <p className="gz-t-body-s">{t('hotelVisitsChatReadOnlyRole', { name: repName })}</p>
      </div>
    )
  } else {
    bottom = <Composer quick={quick} onSend={sendText} onAttach={() => act.attach(attach)} onVoice={seconds => post({ kind: 'voice', voice: { seconds } })} onTooShort={() => nav.toast(t('hotelVisitsRecordHold'))} />
  }

  // ---- messages
  let body
  if (!canSee(role)) {
    body = <ErrorState kind="no-access" title={t('hotelVisitsNoAccessTitle')} body={t('hotelVisitsNoAccessBody')} />
  } else if (loading) {
    body = (
      <div className="hv-chat__skel" aria-busy="true" aria-label={c('commonStateLoading')}>
        <Skeleton variant="block" blockSize={72} />
        <Skeleton variant="block" blockSize={96} />
        <div className="hv-chat__skel-end">
          <Skeleton variant="block" inlineSize={216} blockSize={72} />
        </div>
        <Skeleton variant="block" inlineSize={160} blockSize={48} />
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" title={t('hotelVisitsChatErrorTitle')} body={t('hotelVisitsErrorBody')} onRetry={() => nav.replace('HL-VIST-03', params)} />
  } else {
    let day = ''
    let lastSender = ''
    body = (
      <div className="hv-chat__list">
        {rows.map(({ message: m, delivery, icon, local }, i) => {
          const d = m.at.slice(0, 10)
          const head = d !== day
          day = d
          const senderRole: ThreadRole | undefined = ROLE_OF[m.from]
          const member = senderRole ? conversation?.members?.find(x => x.role === senderRole) : undefined
          const showSender = Boolean(member) && (head || lastSender !== m.from)
          lastSender = m.kind === 'system' || m.kind === 'visit_card' ? '' : m.from
          const next = rows[i + 1]?.message
          const lastOfRun = !next || next.from !== m.from || next.kind === 'system' || next.at.slice(0, 10) !== d
          const pending = delivery !== 'sent'
          return (
            <Fragment key={m.id}>
              {head ? <ChatDateDivider date={m.at} /> : null}
              <div className="hv-chat__msg">
                <ChatBubble
                  message={m}
                  side="hotel"
                  group={m.kind === 'system' ? (icon ?? 'info') : false}
                  sender={showSender && member && senderRole ? { name: lang === 'ar' ? member.name : member.nameLatin, role: senderRole } : undefined}
                  showMeta={lastOfRun && !pending}
                  playing={playing === m.id}
                  onPlay={() => setPlaying(p => (p === m.id ? null : m.id))}
                />
                {pending ? (
                  <p className={`hv-chat__state gz-t-caption${delivery === 'failed' ? ' is-failed' : ''}`}>
                    <Icon name={delivery === 'failed' ? 'warning-circle' : 'clock'} size="xs" />
                    <span>{delivery === 'failed' ? t('hotelVisitsMsgFailed') : delivery === 'queued' ? t('hotelVisitsMsgQueued') : t('hotelVisitsMsgSending')}</span>
                    {delivery === 'failed' && local ? (
                      <Button variant="tertiary" onClick={() => retry(m.id)}>
                        {c('commonActionRetry')}
                      </Button>
                    ) : null}
                  </p>
                ) : null}
              </div>
            </Fragment>
          )
        })}
        <div ref={endRef} aria-hidden="true" />
      </div>
    )
  }

  return <Screen top={top} bottom={bottom} bodyClassName="hv-chat">{body}</Screen>
}
