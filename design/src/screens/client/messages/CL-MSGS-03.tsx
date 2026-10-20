// CL-MSGS-03 Conversation details (sheet over the conversation). Requirements: CA-CHAT-11.
// Who you are talking to, the linked request (three facts and its status), the photos and documents shared (counts, a rail), mute, a call to
// the venue, and the two safety actions that user-generated content requires: report a message (choose it, then a reason and an optional
// note) and block the conversation (a confirm dialog; for a venue with a request it says updates still arrive and gives the phone).
// Support cannot be blocked. A visit group chat shows its three members and the visit instead of a request; it can be reported but not
// blocked (Ghazal support is one of the three).
// Text diet (ADR 0034): every row is a glyph and one word, no hints. The sentences that explain (why a chat cannot be blocked, who is in
// a visit chat, the privacy of media, what a report does) sit behind an info glyph; the finished states are a drawing, a title and Done.
// States: default, report-select, block-confirm, reported, blocked, error, offline (and shared, a populated default; visit and support, the two
// threads that cannot be blocked).
import { useMemo, useState } from 'react'
import type { Message } from '@gz/contracts'
import { getVenue, getVisit, messagesFor } from '../../../mock'
import {
  Avatar, Banner, Button, Dialog, EmptyState, FactChip, FactRow, Figures, FullscreenGallery, Icon, IconListRow, InfoButton, ParticipantStrip, Photo, Radio, RadioGroup, StatusIcon, TextArea, Toggle, imageSrc, useBi, useNav,
} from '../../../system'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { FactValue } from './_components/FactValue'
import { HERO_CONVERSATION, PLANNER_CONVERSATION, VISIT_PILL, byTime, resolveConversation, useHotelReplies, useLiveBooking, type ThreadParams } from './_components/model'
import { MsgSheetHead as SheetHead } from './_components/MsgSheetHead'
import { RequestFacts } from './_components/RequestFacts'
import { useMsgStore } from './_components/store'
import { useMsg } from './_components/useMsg'
import './CL-MSGS-03.css'

export const states = ['report-select', 'block-confirm', 'reported', 'blocked', 'error', 'offline', 'shared', 'visit', 'support']

type Step = 'main' | 'pick' | 'reason' | 'reported' | 'blocked'
type Reason = 'spam' | 'abusive' | 'inappropriate' | 'other'

const FRAME_PARAMS: Record<string, ThreadParams> = {
  'report-select': { conversationId: PLANNER_CONVERSATION },
  reported: { conversationId: PLANNER_CONVERSATION },
  error: { conversationId: PLANNER_CONVERSATION },
  shared: { conversationId: 'conv-jawharat-reem' },
  visit: { conversationId: 'conv-visit-aurelia-reem' },
  support: { support: true },
}

export default function ConversationInfo() {
  const { state } = useFrame()
  const nav = useNav<ThreadParams>()
  const bi = useBi()
  const { t, tc, f, lang, live: inPlayer, auth, nameOf, rowTime } = useMsg()
  const signedIn = !(inPlayer && auth === 'guest')
  const params: ThreadParams = { ...nav.params, ...(state ? FRAME_PARAMS[state] : undefined) }
  const conversation = useMemo(() => resolveConversation({ ...params, conversationId: params.conversationId ?? (params.venueId || params.bookingId || params.support ? undefined : HERO_CONVERSATION) }, signedIn), [params.conversationId, params.venueId, params.bookingId, params.support, signedIn]) // eslint-disable-line react-hooks/exhaustive-deps
  const isSupport = conversation.kind === 'support'
  const isVisit = conversation.kind === 'visit_group'
  const liveVisit = usePrototype(s => s.visits.find(v => v.id === conversation.visitId))
  const visit = isVisit && conversation.visitId ? (liveVisit ?? getVisit(conversation.visitId)) : undefined
  const venue = conversation.venueId ? getVenue(conversation.venueId) : undefined
  const live = useLiveBooking(isSupport ? null : conversation.bookingId)
  const hotel = useHotelReplies()
  const visitChat = usePrototype(s => (conversation.visitId ? s.visitChats[conversation.visitId] : undefined))
  const sent = useMsgStore(s => s.sent)
  const muted = useMsgStore(s => s.muted.includes(conversation.id))
  const blockedNow = useMsgStore(s => s.blocked.includes(conversation.id))
  const offline = state === 'offline'

  const initial: Step = state === 'report-select' ? 'pick' : state === 'reported' ? 'reported' : state === 'blocked' ? 'blocked' : state === 'error' ? 'reason' : 'main'
  const [step, setStep] = useState<Step>(initial)
  const [picked, setPicked] = useState<string | null>(state === 'report-select' || state === 'error' ? 'msg-008' : null)
  const [reason, setReason] = useState<Reason | null>(state === 'error' ? 'inappropriate' : null)
  const [note, setNote] = useState('')
  const [viewer, setViewer] = useState<number | null>(null)
  const [failed, setFailed] = useState(state === 'error')

  // What the other side wrote (any kind but a system line) and what has been shared by either side.
  const thread = useMemo<Message[]>(() => {
    const fixture = conversation.id.startsWith('enq-') || conversation.id === 'support-guest' ? [] : conversation.visitId && visitChat ? visitChat.messages : messagesFor(conversation.id, 'client')
    return [...fixture, ...(conversation.id === HERO_CONVERSATION ? hotel : [])].sort(byTime)
  }, [conversation.id, hotel, visitChat]) // eslint-disable-line react-hooks/exhaustive-deps
  const theirs = thread.filter(m => m.from !== 'client' && m.kind !== 'system')
  const photos = thread.filter(m => m.kind === 'image' && m.image)
  const docs = [...thread.filter(m => m.kind === 'document' && m.document), ...sent.filter(m => m.conversationId === conversation.id && m.kind === 'document').map(m => ({ id: m.id, document: m.document }))]
  const gallery = photos.map(m => ({ src: imageSrc(m.image?.file ?? ''), alt: bi(m.image?.alt) }))

  const name = nameOf(conversation)
  const phone = venue?.phone ? f.phone(venue.phone) : null
  const hasBooking = Boolean(live) && !isSupport
  const preview = (m: Message): string =>
    m.kind === 'voice' ? t('clientMessagesPreviewVoice') : m.kind === 'image' ? t('clientMessagesPreviewPhoto') : m.kind === 'document' ? (m.document?.name ?? t('clientMessagesPreviewDocument')) : m.card ? bi(m.card.title) : (m.text?.[m.origin] ?? '')

  const close = () => nav.closeSheet()
  const goBooking = () => {
    if (!live) return
    nav.closeSheet()
    nav.push('CL-BKNG-02', { bookingId: live.booking.id })
  }

  // The consequence in a fragment: only a venue with a request has one (updates still arrive, the phone stays); any other block needs none.
  const blockBody = hasBooking ? t('clientMessagesBlockBodyBooking', { phone: phone ?? '' }) : undefined
  const askBlock = async () => {
    const answer = await nav.openDialog({ title: t('clientMessagesBlockTitle'), body: blockBody, icon: 'warning', confirmLabel: t('clientMessagesBlockConfirm'), cancelLabel: t('clientMessagesBlockKeep'), tone: 'destructive' })
    if (answer !== 'confirm') return
    useMsgStore.getState().setBlocked(conversation.id, true)
    setStep('blocked')
  }
  const submitReport = () => {
    if (state === 'error' && failed) {
      // The frame shows the failed attempt once; the next press goes through (a retry that works).
      setFailed(false)
      return
    }
    if (picked) useMsgStore.getState().report(picked)
    setStep('reported')
  }

  const reasons: { value: Reason; label: string }[] = [
    { value: 'spam', label: t('clientMessagesReasonSpam') },
    { value: 'abusive', label: t('clientMessagesReasonAbusive') },
    { value: 'inappropriate', label: t('clientMessagesReasonInappropriate') },
    { value: 'other', label: t('clientMessagesReasonOther') },
  ]

  // ---------------------------------------------------------------- steps
  let content
  if (step === 'pick') {
    content = (
      <div className="gzm-info__step">
        <SheetHead title={t('clientMessagesReportPick')} onClose={() => setStep('main')} plain />
        {theirs.length === 0 ? (
          <EmptyState fill={false} illustration="empty-messages" title={t('clientMessagesReportNoMessages')} />
        ) : (
          <RadioGroup label={t('clientMessagesReportPick')} value={picked ?? undefined} onChange={setPicked} className="gzm-info__radios">
            {theirs.slice(-6).reverse().map(m => (
              <Radio key={m.id} value={m.id}>
                <span className="gzm-info__msg">
                  <span className="gzm-info__msg-text gz-t-body-s gz-clamp-2" lang={m.origin} dir="auto">
                    <Figures text={preview(m)} />
                  </span>
                  <span className="gzm-info__msg-time gz-t-caption">
                    <Figures text={rowTime(m.at)} />
                  </span>
                </span>
              </Radio>
            ))}
          </RadioGroup>
        )}
        <Button variant="primary" fullWidth disabled={!picked || offline} reason={!picked ? t('clientMessagesReportNeedMessage') : undefined} onClick={() => setStep('reason')}>
          {tc('commonActionContinue')}
        </Button>
      </div>
    )
  } else if (step === 'reason') {
    content = (
      <div className="gzm-info__step">
        <SheetHead title={t('clientMessagesReportReasonTitle')} onClose={() => setStep('main')} plain />
        {failed ? <Banner tone="danger">{t('clientMessagesInfoErrorReport')}</Banner> : null}
        <RadioGroup label={t('clientMessagesReportReasonTitle')} value={reason ?? undefined} onChange={v => setReason(v as Reason)} className="gzm-info__radios">
          {reasons.map(r => (
            <Radio key={r.value} value={r.value}>
              <span className="gz-t-body">{r.label}</span>
            </Radio>
          ))}
        </RadioGroup>
        <TextArea label={t('clientMessagesReportNote')} optional rows={3} value={note} onValueChange={setNote} />
        <Button variant="primary" fullWidth disabled={!reason || offline} reason={!reason ? t('clientMessagesReportNeedReason') : undefined} onClick={submitReport}>
          {t('clientMessagesReportSubmit')}
        </Button>
      </div>
    )
  } else if (step === 'reported' || step === 'blocked') {
    const blocked = step === 'blocked'
    content = (
      <div className="gzm-info__step gzm-info__done">
        <SheetHead onClose={close} />
        <EmptyState
          fill={false}
          kind="success"
          illustration={blocked ? 'shield' : 'seal'}
          title={blocked ? t('clientMessagesBlockedDoneTitle') : t('clientMessagesReportDone')}
          detail={blocked ? t('clientMessagesBlockedDoneDetail') : t('clientMessagesReportDoneDetail')}
          detailTitle={tc('commonLabelDetails')}
          action={{
            label: tc('commonActionDone'),
            variant: 'primary',
            onPress: () => {
              close()
              // A report is confirmed once more in the thread; a block needs no toast: the blocked bar that replaces the composer is the confirmation.
              if (!blocked) nav.toast({ message: t('clientMessagesReportDone'), tone: 'success' })
            },
          }}
          secondary={
            blocked
              ? {
                  label: t('clientMessagesUnblock'),
                  onPress: () => {
                    useMsgStore.getState().setBlocked(conversation.id, false)
                    nav.toast({ message: t('clientMessagesUnblockedToast'), tone: 'success' })
                    setStep('main')
                  },
                }
              : undefined
          }
        />
      </div>
    )
  } else {
    const locked = isSupport || isVisit
    content = (
      <div className="gzm-info">
        <SheetHead title={t('clientMessagesInfoTitle')} onClose={close} />
        {offline ? <Banner tone="offline">{t('clientMessagesInfoNeedsConnection')}</Banner> : null}

        <header className="gzm-info__who">
          {isVisit ? (
            <span className="gzm-info__glyph" aria-hidden="true">
              <Icon name="users-three" size="lg" />
            </span>
          ) : (
            <Avatar name={name} initial={lang === 'ar' ? conversation.monogram : undefined} size="lg" />
          )}
          <bdi dir="auto" className="gzm-info__who-name gz-t-d1">
            {name}
          </bdi>
          {isVisit && conversation.members ? <InfoButton title={t('clientMessagesInfoMembers')}>{t('clientMessagesInfoMembersNote')}</InfoButton> : null}
        </header>

        {isVisit && conversation.members ? (
          <section className="gzm-info__section" aria-label={t('clientMessagesInfoMembers')}>
            <ParticipantStrip members={conversation.members} meId={conversation.clientId ?? undefined} />
          </section>
        ) : null}

        {visit ? (
          <section className="gzm-info__section" aria-label={t('clientMessagesInfoVisit')}>
            <div className="gzm-info__row gzm-info__request">
              <span className="gzm-info__facts">
                <FactRow label={t('clientMessagesInfoVisit')}>
                  <FactChip icon="calendar-check" value={<FactValue text={f.date(visit.slotStart, 'dayMonth')} />} label={t('clientMessagesInfoVisit')} />
                  <FactChip icon="clock" value={<FactValue text={f.time(visit.slotStart)} />} label={t('clientMessagesInfoVisit')} tone="muted" />
                </FactRow>
              </span>
              <span className="gzm-info__end">
                <StatusIcon status={VISIT_PILL[visit.status]} size="md" />
              </span>
            </div>
          </section>
        ) : null}

        {hasBooking && live ? (
          <section className="gzm-info__section" aria-label={t('clientMessagesInfoBooking')}>
            <button type="button" className="gz-reset gzm-info__row gzm-info__request gz-press" onClick={goBooking} aria-label={t('clientMessagesContextView')}>
              <span className="gzm-info__facts">
                <RequestFacts booking={live.booking} />
              </span>
              <span className="gzm-info__end">
                <StatusIcon status={live.booking.status} size="md" />
                <Icon name="chevron-right" size="sm" tone="secondary" />
              </span>
            </button>
          </section>
        ) : null}

        {photos.length > 0 || docs.length > 0 ? (
          <section className="gzm-info__section" aria-label={t('clientMessagesInfoShared')}>
            <div className="gzm-info__sectionhead">
              <FactRow label={t('clientMessagesInfoShared')}>
                {photos.length > 0 ? <FactChip icon="image" value={f.integer(photos.length)} label={t('clientMessagesPreviewPhoto')} /> : null}
                {docs.length > 0 ? <FactChip icon="document" value={f.integer(docs.length)} label={t('clientMessagesPreviewDocument')} /> : null}
              </FactRow>
              <InfoButton title={t('clientMessagesInfoPrivateTitle')}>{t('clientMessagesInfoPrivate')}</InfoButton>
            </div>
            {photos.length > 0 ? (
              <div className="gzm-info__rail" role="group" aria-label={t('clientMessagesOpenPhoto')}>
                {photos.map((m, i) => (
                  <button key={m.id} type="button" className="gz-reset gzm-info__thumb gz-press" onClick={() => setViewer(i)} aria-label={bi(m.image?.alt)}>
                    <Photo src={imageSrc(m.image?.file ?? '')} alt="" sizes="80px" className="gzm-info__photo" />
                  </button>
                ))}
              </div>
            ) : null}
            {docs.map(d => (
              <div key={d.id} className="gzm-info__doc">
                <span className="gzm-info__doc-icon">
                  <Icon name="document" size="sm" />
                </span>
                <bdi dir="ltr" className="gzm-info__doc-name gz-t-body-s gz-ellipsis">
                  {d.document?.name}
                </bdi>
              </div>
            ))}
          </section>
        ) : null}

        <section className="gzm-info__section gzm-info__list">
          <IconListRow
            flush
            icon="bell"
            title={t('clientMessagesInfoMute')}
            trailing={
              <Toggle
                label={t('clientMessagesInfoMute')}
                checked={muted}
                onChange={on => {
                  useMsgStore.getState().setMuted(conversation.id, on)
                  nav.toast(on ? t('clientMessagesInfoMuted') : t('clientMessagesInfoUnmuted'))
                }}
              />
            }
          />
          {phone && venue ? (
            <IconListRow
              flush
              icon="phone"
              title={t('clientMessagesInfoCall')}
              trailing={
                <bdi dir="ltr" className="gz-num">
                  {phone}
                </bdi>
              }
              onClick={() => {
                const href = f.telHref(venue.phone)
                if (href) window.location.href = href
              }}
            />
          ) : null}
          <IconListRow flush icon="warning" title={t('clientMessagesInfoReport')} chevron onClick={offline ? undefined : () => setStep('pick')} />
          {locked ? (
            <IconListRow
              flush
              last
              icon="lock"
              title={t('clientMessagesInfoBlock')}
              className="gzm-info__locked"
              trailing={<InfoButton title={t('clientMessagesInfoBlock')}>{isVisit ? t('clientMessagesInfoVisitNote') : t('clientMessagesInfoSupportNote')}</InfoButton>}
            />
          ) : blockedNow ? (
            <IconListRow
              flush
              last
              icon="lock"
              title={t('clientMessagesUnblock')}
              onClick={() => {
                useMsgStore.getState().setBlocked(conversation.id, false)
                nav.toast({ message: t('clientMessagesUnblockedToast'), tone: 'success' })
              }}
            />
          ) : (
            <IconListRow flush last icon="x-circle" tone="danger" title={t('clientMessagesInfoBlock')} chevron onClick={offline ? undefined : askBlock} />
          )}
        </section>
      </div>
    )
  }

  return (
    <div className="gzm-info__root" data-gz="ConversationInfo">
      {content}
      {state === 'block-confirm' ? (
        <div className="gzm-info__dialog">
          <Dialog placement="inline" title={t('clientMessagesBlockTitle')} body={blockBody} icon="warning" confirmLabel={t('clientMessagesBlockConfirm')} cancelLabel={t('clientMessagesBlockKeep')} tone="destructive" />
        </div>
      ) : null}
      <FullscreenGallery open={viewer !== null} images={gallery} index={viewer ?? 0} onIndexChange={setViewer} onClose={() => setViewer(null)} label={t('clientMessagesPhotoViewer')} />
    </div>
  )
}
