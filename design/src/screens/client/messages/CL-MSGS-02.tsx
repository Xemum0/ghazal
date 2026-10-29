// CL-MSGS-02 Conversation (pushed from the Messages tab, a venue, a booking or a notification). Requirements: CA-CHAT-02..09.
// One thread with a venue, a planner, a service provider or Ghazal Support: text, photos, documents and voice notes with a waveform, sent, delivered
// and read ticks, a pinned request bar (date, reception symbol and guests as facts, the status, a chevron to the request), system lines for the request
// (a knot with one or two words: sent, approved with the hours left, confirmed, voucher redeemed, not accepted, no reply, time ran out), and structured
// cards (meeting, quote request). A visit group chat is CL-VIST-03: a thread that is one opens there. Own messages sit at inline-end (left in Arabic) and
// every message aligns by its own first strong character.
// The tab bar is hidden. Text diet (ADR 0034): the header shows the reply time as a fact, a new enquiry is the venue photograph, its name and that fact,
// and the three starters are one-word chips with a glyph; the paragraphs of the old system lines sit behind an info glyph.
// States: loading, empty-enquiry, sending, failed, delivered, read, uploading, recording, recording-locked, voice-playing, offline-queued,
// error, blocked, planner-variant, vendor-variant, support-variant, attaching.
import { Fragment, useEffect, useMemo, useRef, useState } from 'react'
import type { Message } from '@gz/contracts'
import { getVenue, messagesFor, PROTOTYPE_NOW } from '../../../mock'
import {
  Avatar, Banner, Button, ChatBubble, ChatDateDivider, ErrorState, FactChip, FullscreenGallery, Icon, Illustration, Photo, Screen, Sheet, Skeleton, TopBar, imageSrc, useBi, useNav,
} from '../../../system'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { AttachSheet, type AttachPick } from './_components/AttachSheet'
import { MsgComposer as Composer, type QuickReply } from './_components/MsgComposer'
import { MsgContextBar as ContextBar } from './_components/MsgContextBar'
import { DocSheet } from './_components/DocSheet'
import { FactValue } from './_components/FactValue'
import { MessageMeta } from './_components/MessageMeta'
import { SystemLine } from './_components/SystemLine'
import { nextPhoto } from './_components/media'
import {
  HERO_BOOKING, HERO_CONVERSATION, PLANNER_CONVERSATION, byTime, localToMessage, resolveConversation, useHotelReplies, useLiveBooking, providerOf,
  type SystemEvent, type ThreadParams,
} from './_components/model'
import { useMsgStore, type LocalMessage } from './_components/store'
import { useMsg } from './_components/useMsg'
import './CL-MSGS-02.css'

export const states = [
  'loading', 'empty-enquiry', 'sending', 'failed', 'delivered', 'read', 'uploading', 'recording', 'recording-locked', 'voice-playing', 'offline-queued', 'error',
  'blocked', 'planner-variant', 'vendor-variant', 'support-variant', 'attaching',
]

const VENDOR_CONVERSATION = 'conv-vendor-lamha'
const VOICE_CONVERSATION = 'conv-jawharat-reem'
/** The frame states that open a particular thread; every other state shows the story's thread with Aurelia. */
const FRAME_PARAMS: Record<string, ThreadParams> = {
  'planner-variant': { conversationId: PLANNER_CONVERSATION },
  'vendor-variant': { conversationId: VENDOR_CONVERSATION },
  'support-variant': { support: true },
  'empty-enquiry': { venueId: 'V09' },
  'voice-playing': { conversationId: VOICE_CONVERSATION },
}

type Row = { message: Message; local: LocalMessage | null; sys?: SystemEvent['kind']; reason?: SystemEvent['reason'] }

export default function Thread() {
  const { state } = useFrame()
  const nav = useNav<ThreadParams>()
  const bi = useBi()
  const { t, f, lang, live, nameOf, duration } = useMsg()
  const params: ThreadParams = { ...nav.params, ...(state ? FRAME_PARAMS[state] : undefined) }
  const conversation = useMemo(() => resolveConversation(params), [params.conversationId, params.bookingId, params.venueId, params.support]) // eslint-disable-line react-hooks/exhaustive-deps
  const isSupport = conversation.kind === 'support'
  const store = useMsgStore.getState
  const sentAll = useMsgStore(s => s.sent)
  const blockedIds = useMsgStore(s => s.blocked)
  const drafts = useMsgStore(s => s.drafts)
  const hotel = useHotelReplies()
  const brief = usePrototype(s => s.searchBrief)
  const liveBooking = useLiveBooking(isSupport ? null : conversation.bookingId)

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline-queued'
  const blocked = state === 'blocked' || blockedIds.includes(conversation.id)
  const emptyEnquiry = state === 'empty-enquiry'

  const [value, setValue] = useState(() => params.draft ?? drafts[conversation.id] ?? '')
  const [viewer, setViewer] = useState<number | null>(null)
  const [playing, setPlaying] = useState<{ id: string; progress: number } | null>(null)
  const endRef = useRef<HTMLDivElement>(null)

  // A visit group chat has its own screen (CL-VIST-03, same chat component, three roles): a link that lands here is sent there.
  useEffect(() => {
    if (live && conversation.kind === 'visit_group' && conversation.visitId) nav.replace('CL-VIST-03', { visitId: conversation.visitId, conversationId: conversation.id })
  }, [live, conversation.kind, conversation.visitId, conversation.id]) // eslint-disable-line react-hooks/exhaustive-deps

  // Opening the thread reads it: the unread count clears, and the hotel's replies are counted as seen.
  useEffect(() => {
    if (loading || error) return
    store().open(conversation.id)
    if (conversation.id === HERO_CONVERSATION) store().seeHotel(hotel.length)
  }, [conversation.id, loading, error, hotel.length]) // eslint-disable-line react-hooks/exhaustive-deps

  // ---------------------------------------------------------------- the messages
  const localHere = useMemo(() => sentAll.filter(m => m.conversationId === conversation.id), [sentAll, conversation.id])
  const sample = useMemo<LocalMessage[]>(() => {
    const base = { id: 'sample', conversationId: conversation.id, at: new Date(Date.parse(PROTOTYPE_NOW) + 60_000).toISOString() }
    const text = t('clientMessagesSuggestAvailabilityAny')
    if (state === 'sending') return [{ ...base, kind: 'text', text, state: 'sending' }]
    if (state === 'delivered') return [{ ...base, kind: 'text', text, state: 'delivered' }]
    if (state === 'failed') return [{ ...base, kind: 'text', text, state: 'failed' }]
    if (state === 'offline-queued') return [{ ...base, kind: 'text', text, state: 'queued' }]
    if (state === 'uploading') return [{ ...base, kind: 'document', document: { name: 'GZ-2611-0147.pdf', sizeKb: 84 }, state: 'uploading', progress: 0.6 }]
    return []
  }, [state, conversation.id, t])

  const rows = useMemo<Row[]>(() => {
    if (loading || error) return []
    const fixture = conversation.id.startsWith('enq-') || emptyEnquiry ? [] : messagesFor(conversation.id, 'client')
    // The request's own events: the knot says it in a word; the line carries the kind, the clock and the venue for its info sheet.
    const system: Message[] = (liveBooking?.events ?? []).map(e => ({ id: e.id, conversationId: conversation.id, from: 'system', senderName: e.kind, at: e.at, kind: 'system', text: null, origin: lang, status: 'read', draft: false }))
    const reasons = new Map((liveBooking?.events ?? []).map(e => [e.id, e.reason]))
    let all: Row[] = [
      ...fixture.map(message => ({ message, local: null })),
      ...(conversation.id === HERO_CONVERSATION ? hotel.map(message => ({ message, local: null })) : []),
      ...system.map(message => ({ message, local: null, sys: message.senderName as SystemEvent['kind'], reason: reasons.get(message.id) })),
      ...[...localHere, ...sample].map(m => ({ message: localToMessage(m), local: m })),
    ]
    all = all.sort((a, b) => byTime(a.message, b.message))
    // `read`: the last message of the couple's own is read by the other side.
    if (state === 'read') {
      const lastOwn = [...all].reverse().find(r => r.message.from === 'client')
      if (lastOwn) all = all.map(r => (r === lastOwn ? { ...r, message: { ...r.message, status: 'read' as const } } : r))
    }
    return all
  }, [loading, error, conversation, emptyEnquiry, liveBooking, localHere, sample, hotel, state, t, lang])

  const photos = useMemo(() => rows.filter(r => r.message.kind === 'image' && r.message.image).map(r => ({ id: r.message.id, src: imageSrc(r.message.image?.file ?? ''), alt: bi(r.message.image?.alt) })), [rows, bi])

  // Scroll to the newest message when the thread opens and when one arrives.
  useEffect(() => {
    const body = endRef.current?.closest<HTMLElement>('.gz-screen__body')
    if (body) body.scrollTop = body.scrollHeight
  }, [rows.length, state, loading])

  // A voice note plays by its own length; a static frame shows it mid-way.
  const firstVoice = rows.find(r => r.message.kind === 'voice')
  useEffect(() => {
    if (state === 'voice-playing' && firstVoice) setPlaying({ id: firstVoice.message.id, progress: 0.4 })
  }, [state, firstVoice?.message.id]) // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => {
    if (!playing || !live) return
    const seconds = rows.find(r => r.message.id === playing.id)?.message.voice?.seconds ?? 1
    const handle = window.setInterval(() => {
      setPlaying(p => (p && p.progress + 0.1 / seconds < 1 ? { ...p, progress: p.progress + 0.1 / seconds } : null))
    }, 100)
    return () => window.clearInterval(handle)
  }, [playing?.id, live, rows]) // eslint-disable-line react-hooks/exhaustive-deps

  // ---------------------------------------------------------------- sending
  const submit = (message: Omit<LocalMessage, 'id' | 'at' | 'state' | 'progress' | 'conversationId'>, opts?: { upload?: boolean }) => {
    if (conversation.id.startsWith('enq-') && conversation.venueId) store().startEnquiry(conversation.venueId)
    store().send({ ...message, conversationId: conversation.id }, { offline, upload: opts?.upload })
  }
  const send = (text: string) => {
    submit({ kind: 'text', text })
    setValue('')
    store().setDraft(conversation.id, '')
  }
  const attach = (pick: AttachPick) => {
    if (pick.kind === 'document') return submit({ kind: 'document', document: { name: `${liveBooking?.booking.ref ?? HERO_BOOKING}.pdf`, sizeKb: 84 } }, { upload: true })
    const photo = pick.kind === 'recent' ? pick.photo : nextPhoto()
    submit({ kind: 'image', image: { file: photo.file, alt: photo.alt } }, { upload: true })
  }
  const openAttach = () => {
    const key = nav.openSheet(
      <AttachSheet
        onPick={pick => {
          nav.closeSheet(key)
          attach(pick)
        }}
      />,
      { title: t('clientMessagesAttachTitle') },
    )
  }
  const openInfo = () => nav.openSheet('CL-MSGS-03', { params: { conversationId: conversation.id, venueId: conversation.venueId ?? undefined, bookingId: conversation.bookingId ?? undefined, support: isSupport || undefined } })
  const openDoc = (m: Message) => nav.openSheet(<DocSheet message={m} conversation={conversation} />)

  // ---------------------------------------------------------------- suggestions on a new enquiry
  const quick = useMemo<QuickReply[]>(() => {
    if (rows.length > 0 || conversation.kind !== 'enquiry') return []
    const date = brief.date ? f.date(brief.date, 'short') : null
    // A visit is for hotels and halls only (a venue with no visit slots, such as a governmental facility, offers none).
    const canVisit = Boolean(conversation.venueId && (getVenue(conversation.venueId)?.visitSlots.length ?? 0) > 0)
    return [
      { id: 'availability', icon: 'calendar', label: t('clientMessagesSuggestAvailability'), text: date ? t('clientMessagesSuggestAvailabilityText', { date }) : t('clientMessagesSuggestAvailabilityAny') },
      ...(canVisit ? [{ id: 'visit', icon: 'calendar-check' as const, label: t('clientMessagesSuggestVisit'), onPress: () => nav.openSheet('CL-VIST-01', { params: { venueId: conversation.venueId } }) }] : []),
      { id: 'voucher', icon: 'ticket', label: t('clientMessagesSuggestVoucher'), text: date ? t('clientMessagesSuggestVoucherText', { date }) : t('clientMessagesSuggestVoucherAny') },
    ]
  }, [rows.length, conversation.kind, conversation.venueId, brief.date, f, t]) // eslint-disable-line react-hooks/exhaustive-deps

  // ---------------------------------------------------------------- header
  const name = nameOf(conversation)
  const hours = conversation.usuallyRepliesHours ?? providerOf(conversation)?.usuallyRepliesHours ?? null
  // The reply time is a fact (`clock 2 h`); the sentence is its accessible name. Planner, vendor and Support threads have no subtitle.
  const replyFact = hours ? <FactChip icon="clock" value={<FactValue text={duration(hours * 3_600_000)} />} label={t('clientMessagesRepliesWithin', { hours })} size="sm" tone="muted" /> : undefined
  const venueName = conversation.venueId ? bi(getVenue(conversation.venueId)?.name) : ''
  const title = (
    <span className="gzm-th__who">
      <Avatar name={name} initial={lang === 'ar' ? conversation.monogram : undefined} size="xs" />
      <bdi dir="auto" className="gzm-th__name">
        {name}
      </bdi>
    </span>
  )
  const top = (
    <>
      <TopBar title={title} subtitle={replyFact} actions={[{ icon: 'more-vertical', label: t('clientMessagesInfoTitle'), onPress: openInfo }]} />
      {offline ? <Banner tone="offline">{t('clientMessagesOfflineQueue')}</Banner> : null}
      {liveBooking && !isSupport && !loading && !error && conversation.kind !== 'planner' ? (
        <ContextBar booking={liveBooking.booking} onOpen={() => nav.push('CL-BKNG-02', { bookingId: liveBooking.booking.id })} />
      ) : null}
    </>
  )

  const bottom =
    loading || error ? null : blocked ? (
      <div className="gzm-th__blocked">
        <Icon name="lock" size="sm" tone="secondary" />
        <span className="gzm-th__blocked-note gz-t-body-s">{t('clientMessagesBlockedNote')}</span>
        <Button
          variant="secondary"
          onClick={() => {
            store().setBlocked(conversation.id, false)
            nav.toast({ message: t('clientMessagesUnblockedToast'), tone: 'success' })
          }}
        >
          {t('clientMessagesUnblock')}
        </Button>
      </div>
    ) : (
      <>
        <Composer
          value={value}
          onChange={v => {
            setValue(v)
            store().setDraft(conversation.id, v)
          }}
          quick={quick}
          previewRecording={state === 'recording' ? 'holding' : state === 'recording-locked' ? 'locked' : undefined}
          onSend={send}
          onAttach={openAttach}
          onVoice={seconds => submit({ kind: 'voice', seconds })}
          onTooShort={() => nav.toast(t('clientMessagesRecordTooShort'))}
        />
      </>
    )

  // ---------------------------------------------------------------- body
  let body
  if (loading) {
    body = (
      <div className="gzm-th__skel" aria-busy="true">
        <Skeleton variant="block" inlineSize={248} blockSize={72} />
        <div className="gzm-th__skel-end">
          <Skeleton variant="block" inlineSize={216} blockSize={72} />
        </div>
        <Skeleton variant="block" inlineSize={160} blockSize={48} />
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('CL-MSGS-02', params)} />
  } else if (rows.length === 0) {
    const cover = conversation.venueId ? getVenue(conversation.venueId)?.cover : null
    body = (
      <section className="gzm-th__intro">
        {cover ? <Photo src={imageSrc(cover.file)} alt={bi(cover.alt)} className="gzm-th__cover" priority /> : <Illustration name="empty-messages" size="lg" />}
        <h2 className="gzm-th__intro-title gz-t-d2">
          <bdi dir="auto">{name}</bdi>
        </h2>
        {replyFact}
      </section>
    )
  } else {
    let day = ''
    let lastSide: 'own' | 'other' | 'system' | null = null
    body = (
      <div className="gzm-th__list">
        {rows.map(({ message: m, local, sys, reason }, i) => {
          const d = f.isoDay(m.at)
          const newDay = d !== day
          day = d
          const side: 'own' | 'other' | 'system' = m.kind === 'system' ? 'system' : m.from === 'client' ? 'own' : 'other'
          const runStart = newDay || side !== lastSide || lastSide === 'system'
          lastSide = side
          const next = rows[i + 1]?.message
          const nextSide = !next ? null : next.kind === 'system' ? 'system' : next.from === 'client' ? 'own' : 'other'
          const runEnd = nextSide !== side || (next ? f.isoDay(next.at) !== d : true)
          const isVoice = m.kind === 'voice'
          const card = m.kind === 'meeting_card' || m.kind === 'quote_request_card'
          return (
            <Fragment key={m.id}>
              {newDay ? <ChatDateDivider date={m.at} /> : null}
              {sys ? (
                <div className="gzm-msg" data-kind="system">
                  <SystemLine kind={sys} reason={reason} at={m.at} venue={venueName} />
                </div>
              ) : (
              <div className={`gzm-msg${runStart && !newDay ? ' is-run-start' : ''}`} data-own={side === 'own' || undefined} data-kind={m.kind}>
                {m.kind === 'document' ? (
                  <div role="button" tabIndex={0} className="gzm-msg__tap" aria-label={t('clientMessagesDocOpen', { name: m.document?.name ?? '' })} onClick={() => openDoc(m)} onKeyDown={e => (e.key === 'Enter' || e.key === ' ') && openDoc(m)}>
                    <ChatBubble message={m} side="client" showMeta={false} />
                  </div>
                ) : (
                  <ChatBubble
                    message={m.card && m.card.lines.length > 0 ? { ...m, card: { ...m.card, at: undefined } } : m}
                    side="client"
                    showMeta={false}
                    playing={isVoice && playing?.id === m.id}
                    progress={isVoice && playing?.id === m.id ? playing.progress : 0}
                    onPlay={isVoice ? () => setPlaying(p => (p?.id === m.id ? null : { id: m.id, progress: 0 })) : undefined}
                    onOpen={m.kind === 'image' ? () => setViewer(Math.max(0, photos.findIndex(p => p.id === m.id))) : undefined}
                  />
                )}
                {card && m.kind === 'meeting_card' ? (
                  <div className="gzm-msg__actions">
                    <Button variant="tertiary" iconStart="calendar-plus" onClick={() => nav.toast({ message: t('clientMessagesCardCalendarToast'), tone: 'success' })}>
                      {t('clientMessagesCardCalendar')}
                    </Button>
                    <Button variant="tertiary" iconStart="edit" onClick={() => nav.openSheet('CL-PLAN-04')}>
                      {t('clientMessagesCardChange')}
                    </Button>
                  </div>
                ) : null}
                {card && m.kind === 'quote_request_card' && conversation.vendorId ? (
                  <div className="gzm-msg__actions gzm-msg__actions--end">
                    <Button variant="tertiary" iconStart="user" onClick={() => nav.push('CL-SERV-03', { vendorId: conversation.vendorId })}>
                      {t('clientMessagesCardVendor')}
                    </Button>
                  </div>
                ) : null}
                {side !== 'system' ? (
                  <MessageMeta
                    message={m}
                    own={side === 'own'}
                    showTime={runEnd}
                    local={local}
                    onRetry={() => local && store().retry(local.id)}
                    onCancel={() => local && store().discard(local.id)}
                  />
                ) : null}
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
    <div className="gzm-th__root">
      <Screen top={top} bottom={bottom} bodyClassName="gzm-th">
        {body}
      </Screen>
      <FullscreenGallery
        open={viewer !== null}
        images={photos.map(p => ({ src: p.src, alt: p.alt }))}
        index={viewer ?? 0}
        onIndexChange={setViewer}
        onClose={() => setViewer(null)}
        label={t('clientMessagesPhotoViewer')}
      />
      {state === 'attaching' ? (
        <Sheet title={t('clientMessagesAttachTitle')}>
          <AttachSheet />
        </Sheet>
      ) : null}
    </div>
  )
}

