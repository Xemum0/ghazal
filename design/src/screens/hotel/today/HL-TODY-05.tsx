// HL-TODY-05 Conversation: a real-time conversation with a couple (or Ghazal Support) that always shows the booking it belongs to, so
// staff can answer and decide in one place. Text, photos, documents and voice notes; quick replies; a pinned booking context bar
// with Accept and Decline while the request is pending. The tab bar is hidden while the composer is open (ADR 0008 D2).
// Voucher model (ADR 0033): quick replies are Availability, Voucher price, Visit invitation and Address; the context bar chip follows the
// request statuses (Pending, Awaiting client, Confirmed, Redeemed). A visit group chat is not this screen: it opens HL-VIST-03.
// Text diet (docs/design/02-text-diet.md): the context bar is facts and one status, the states are glyphs (a clock for sending, a warning
// and Retry for failed, a pencil for the draft, a lock for read-only), the quick replies are one word; the messages themselves are the
// couple's and the venue's own words (authored content).
// Requirements: HA-MSG-02, HA-MSG-03, HA-MSG-04, HA-MSG-05, HA-BOOK-07, HA-BOOK-03, HA-BOOK-04
// States: loading, empty, error, offline, sending, failed, recording, attaching, support-mode, role-read-only
import { Fragment, useEffect, useMemo, useRef, useState } from 'react'
import type { Message } from '@gz/contracts'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { conversationsFor, getArea, getBooking, getVenue, hotelStaff, messagesFor, PROTOTYPE_NOW } from '../../../mock'
import { useLang } from '../../../shell/lang'
import { Avatar, Banner, Button, ChatBubble, ChatDateDivider, EmptyState, ErrorState, Figures, Icon, Screen, Sheet, Skeleton, TopBar, useNav } from '../../../system'
import { Composer, type QuickReply } from './_components/Composer'
import { ContextBar } from './_components/ContextBar'
import { UserText, scriptOf, useBi, useWords, VENUE_ID } from './_components/bits'
import { usePendingRequests } from './_components/data'
import { useRequestActions } from './_components/actions'
import { useTodayLocal, type SentMessage } from './_components/store'
import './HL-TODY-05.css'

export const states = ['loading', 'empty', 'error', 'offline', 'sending', 'failed', 'recording', 'attaching', 'support-mode', 'role-read-only']

const DEFAULT_CONVERSATION = 'conv-aurelia-reem'
const SUPPORT_CONVERSATION = 'conv-support-aurelia'

/** Local messages are stamped a few minutes after the prototype clock, after the staged drafts (4:05 to 4:07 PM). */
const stamp = (n: number) => new Date(Date.parse(PROTOTYPE_NOW) + (8 + n) * 60_000).toISOString()

const toMessage = (s: SentMessage): Message => ({
  id: s.id,
  conversationId: s.conversationId,
  from: 'venue',
  senderName: null,
  at: s.at,
  kind: s.kind,
  text: s.text ? { en: s.text, ar: s.text } : null,
  origin: scriptOf(s.text ?? ''),
  voice: s.seconds ? { seconds: s.seconds } : undefined,
  document: s.document ? { ...s.document, mime: 'application/pdf' } : undefined,
  image: s.image,
  status: s.state === 'sent' ? 'delivered' : 'sent',
  draft: false,
})

export default function Conversation() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { lang } = useLang()
  const { t, c } = useWords()
  const params = nav.params as { conversationId?: string | null; bookingId?: string | null; readOnly?: boolean }
  const support = state === 'support-mode'
  const conversationId = support ? SUPPORT_CONVERSATION : (params.conversationId ?? DEFAULT_CONVERSATION)
  const conversation = useMemo(() => conversationsFor('hotel').find(x => x.id === conversationId), [conversationId])
  const isSupport = conversation?.kind === 'support'
  const booking = !isSupport && conversation?.bookingId ? getBooking(conversation.bookingId) : undefined
  const liveStatus = usePrototype(s => s.hotelBookings.find(b => b.id === booking?.id)?.status)
  const pending = usePendingRequests()
  const request = booking ? (pending.find(r => r.booking.id === booking.id) ?? null) : null
  const actions = useRequestActions()
  const everySent = useTodayLocal(s => s.sent)
  const sent = useMemo(() => everySent.filter(m => m.conversationId === conversationId), [everySent, conversationId])
  const allSent = everySent.length
  const readOnly = state === 'role-read-only' || Boolean(params.readOnly)
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const [playing, setPlaying] = useState<string | null>(null)
  const endRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    useTodayLocal.getState().openConversation(conversationId)
  }, [conversationId])

  // A visit's group chat is its own screen (three members, role chips, arrival buttons): never this two-party thread.
  useEffect(() => {
    if (conversation?.kind === 'visit_group') nav.replace('HL-VIST-03', { visitId: conversation.visitId })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [conversation?.kind, conversation?.visitId])

  // Fixture messages (the hotel's staged drafts included), then what was typed in this session, then a frame's own sample.
  const sample: SentMessage[] = useMemo(() => {
    const base = { conversationId, at: stamp(0), kind: 'text' as const, text: t('hotelTodayQrVisitText') }
    if (state === 'sending') return [{ ...base, id: 'sample-sending', state: 'sending' }]
    if (state === 'failed') return [{ ...base, id: 'sample-failed', state: 'failed' }]
    if (state === 'offline') return [{ ...base, id: 'sample-queued', state: 'queued' }]
    return []
  }, [state, conversationId, t])

  const base = useMemo(() => (state === 'empty' || loading ? [] : messagesFor(conversationId, 'hotel')), [state, loading, conversationId])
  const rows = useMemo(() => {
    const local = [...sent, ...sample].map(m => ({ message: toMessage(m), local: m }))
    // Only the staged text reply is still a draft; the voice note and the quotation went out, so they read as sent and the draft sits last.
    const shown = base
      .map(m => (m.draft && m.kind !== 'text' ? { ...m, draft: false, status: 'delivered' as const } : m))
      .sort((a, b) => Number(a.draft) - Number(b.draft))
    return [...shown.map(m => ({ message: m, local: null as SentMessage | null })), ...local]
  }, [base, sent, sample])

  useEffect(() => {
    const body = endRef.current?.closest<HTMLElement>('.gz-screen__body')
    if (body) body.scrollTop = body.scrollHeight
  }, [rows.length, state])

  // ---- sending (ADR 0008 D10: chat may queue offline)
  const submit = (message: Omit<SentMessage, 'id' | 'conversationId' | 'at' | 'state'>) => {
    const id = `local-${allSent + 1}-${Date.now()}`
    useTodayLocal.getState().send({ ...message, id, conversationId, at: stamp(allSent + 1), state: offline ? 'queued' : 'sending' })
    if (!offline) window.setTimeout(() => useTodayLocal.getState().patchSent(id, { state: 'sent' }), 700)
  }
  const retry = (id: string) => {
    useTodayLocal.getState().patchSent(id, { state: 'sending' })
    window.setTimeout(() => useTodayLocal.getState().patchSent(id, { state: 'sent' }), 700)
  }

  const attach = (kind: 'camera' | 'photo' | 'document') => {
    if (kind === 'document') {
      const doc = messagesFor(DEFAULT_CONVERSATION, 'hotel').find(m => m.kind === 'document')?.document
      submit({ kind: 'document', document: { name: doc?.name ?? '', sizeKb: doc?.sizeKb ?? 0 } })
      return
    }
    const photo = getVenue(VENUE_ID)?.gallery.find(g => g.zone === 'hall')
    if (photo) submit({ kind: 'image', image: { file: photo.file, alt: photo.alt } })
  }
  const openAttach = () => {
    const key = nav.openSheet(<AttachRows onPick={k => { nav.closeSheet(key); attach(k) }} />, { title: t('hotelTodayAttachTitle') })
  }
  const openMenu = () => {
    const key = nav.openSheet(
      <div className="ht-th__menu">
        <Button
          variant="secondary"
          fullWidth
          iconStart="warning"
          onClick={() => {
            nav.closeSheet(key)
            nav.toast({ message: t('hotelTodayReportSent'), tone: 'success' })
          }}
        >
          {t('hotelTodayReport')}
        </Button>
      </div>,
      { title: t('hotelTodayConversationMenu') },
    )
  }

  // ---- quick replies (defaults only, bilingual; the numbers come from the request through the formatter). No payment reminder: the
  // venue is paid directly and off-app, so the chat never chases money (ADR 0033).
  const quick = useMemo<QuickReply[]>(() => {
    if (!booking) return []
    const venue = booking.venueId ? getVenue(booking.venueId) : undefined
    const area = venue?.areaId ? getArea(venue.areaId) : undefined
    const guests = booking.sections.reduce((n, s) => n + s.guests, 0)
    const price = booking.totals.voucherTotal.fils
    const standard = booking.totals.standardTotal.fils
    return [
      { id: 'availability', label: t('hotelTodayQrAvailability'), text: t('hotelTodayQrAvailabilityText', { date: f.date(booking.eventDate, 'full') }) },
      {
        id: 'price',
        label: t('hotelTodayQrPrice'),
        text: t('hotelTodayQrPriceText', { guests: f.guests(guests), total: f.money(price, { mode: 'exact' }), standard: f.money(standard, { mode: 'exact' }) }),
      },
      { id: 'visit', label: t('hotelTodayQrVisit'), text: t('hotelTodayQrVisitText') },
      { id: 'address', label: t('hotelTodayQrAddress'), text: t('hotelTodayQrAddressText', { venue: venue ? bi(venue.name) : '', area: area ? bi(area.name) : '' }) },
    ]
  }, [booking, f, t, bi])

  // ---- header
  const staff = conversation?.handledBy ? hotelStaff.find(s => s.nameLatin === conversation.handledBy) : undefined
  const handled = staff ? (lang === 'ar' ? staff.name : staff.nameLatin) : conversation?.handledBy
  const name = !conversation ? '' : isSupport ? bi(conversation.title) : conversation.clientName
  const canCall = Boolean(booking?.contact.shared) && !isSupport
  const title = (
    <span className="ht-th__who">
      <Avatar name={name} initial={isSupport ? 'غ' : undefined} size="xs" voice="sans" />
      {isSupport ? <span>{name}</span> : <UserText role="title">{name}</UserText>}
      {!isSupport && handled ? <span className="gz-sr-only">{t('hotelTodayHandledBy', { name: handled })}</span> : null}
    </span>
  )
  const live = booking ? { ...booking, status: liveStatus ?? booking.status } : undefined

  const top = (
    <>
      <TopBar
        title={title}
        actions={[
          ...(canCall ? [{ icon: 'phone' as const, label: t('hotelTodayCallClient', { name }), onPress: () => nav.openSheet('HL-BOOK-04', { params: { bookingId: booking?.id } }) }] : []),
          { icon: 'more-vertical' as const, label: t('hotelTodayConversationMenu'), onPress: openMenu },
        ]}
      />
      {offline ? (
        <Banner tone="offline">
          <Figures text={f.time(f.now())} />
          <span className="gz-sr-only">{t('hotelTodayOfflineStamp', { time: f.time(f.now()) })}</span>
        </Banner>
      ) : null}
      {live && !loading && !error ? (
        <ContextBar
          booking={live}
          request={request}
          offline={offline}
          readOnly={readOnly}
          onOpen={() => nav.push('HL-BOOK-03', { bookingId: live.id })}
          onAccept={() => request && actions.accept(request)}
          onDecline={() => request && actions.decline(request)}
        />
      ) : null}
    </>
  )

  const bottom = readOnly ? (
    <div className="ht-th__readonly">
      <Icon name="lock" size="sm" tone="secondary" />
      <p className="gz-t-body-s">{t('hotelTodayReadOnly')}</p>
    </div>
  ) : loading || error ? null : (
    <Composer
      quick={quick}
      previewRecording={state === 'recording' ? 'holding' : undefined}
      onSend={text => submit({ kind: 'text', text })}
      onAttach={openAttach}
      onVoice={seconds => submit({ kind: 'voice', seconds })}
      onTooShort={() => nav.toast(t('hotelTodayRecordHold'))}
    />
  )

  let body
  if (loading) {
    body = (
      <div className="ht-th__skel" aria-busy="true">
        <Skeleton variant="block" inlineSize={248} blockSize={72} />
        <div className="ht-th__skel-end">
          <Skeleton variant="block" inlineSize={216} blockSize={72} />
        </div>
        <Skeleton variant="block" inlineSize={160} blockSize={48} />
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-TODY-05', params)} />
  } else if (rows.length === 0) {
    body = <EmptyState illustration="empty-messages" title={t('hotelTodayThreadEmptyTitle')} />
  } else {
    let day = ''
    let prevDraft = false
    body = (
      <div className="ht-th__list">
        {rows.map(({ message: m, local }) => {
          const d = m.at.slice(0, 10)
          const head = d !== day
          day = d
          const tone = local && local.state !== 'sent' ? local.state : null
          const firstDraft = m.draft && !prevDraft
          prevDraft = m.draft
          return (
            <Fragment key={m.id}>
              {head ? <ChatDateDivider date={m.at} /> : null}
              {firstDraft ? (
                <p className="ht-th__drafts gz-t-caption">
                  <Icon name="edit" size="xs" />
                  <span>{t('hotelTodayDraftTag')}</span>
                </p>
              ) : null}
              <div className="ht-th__msg" data-draft={m.draft || undefined}>
                <ChatBubble
                  message={m}
                  side="hotel"
                  showMeta={!m.draft && !tone}
                  playing={playing === m.id}
                  onPlay={() => setPlaying(p => (p === m.id ? null : m.id))}
                />
                {tone ? (
                  <p className={`ht-th__state gz-t-caption${tone === 'failed' ? ' is-failed' : ''}`}>
                    <Icon name={tone === 'failed' ? 'warning-circle' : tone === 'queued' ? 'offline' : 'clock'} size="xs" />
                    <span className="gz-sr-only">{tone === 'failed' ? t('hotelTodayMsgFailed') : tone === 'queued' ? t('hotelTodayMsgQueued') : t('hotelTodayMsgSending')}</span>
                    {tone === 'failed' && local ? (
                      <Button variant="tertiary" onClick={() => retry(local.id)}>
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

  return (
    <div className="ht-th__root">
      <Screen top={top} bottom={bottom} bodyClassName="ht-th">
        {body}
      </Screen>
      {state === 'attaching' ? (
        <Sheet title={t('hotelTodayAttachTitle')}>
          <AttachRows />
        </Sheet>
      ) : null}
    </div>
  )
}

function AttachRows({ onPick }: { onPick?: (kind: 'camera' | 'photo' | 'document') => void }) {
  const { t } = useWords()
  const rows = [
    { kind: 'camera' as const, icon: 'camera' as const, label: t('hotelTodayAttachCamera') },
    { kind: 'photo' as const, icon: 'image' as const, label: t('hotelTodayAttachPhoto') },
    { kind: 'document' as const, icon: 'document' as const, label: t('hotelTodayAttachDocument') },
  ]
  return (
    <ul className="ht-th__attach">
      {rows.map(r => (
        <li key={r.kind}>
          <button type="button" className="gz-reset ht-th__attach-row gz-press" onClick={() => onPick?.(r.kind)}>
            <span className="ht-th__attach-icon">
              <Icon name={r.icon} size="md" />
            </span>
            <span className="gz-t-body">{r.label}</span>
          </button>
        </li>
      ))}
    </ul>
  )
}
