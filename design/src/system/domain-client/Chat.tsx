// Chat pieces (CA-MSG, ADR 0013 D2 dialect rule, ADR 0014 D8): ChatBubble, ChatDateDivider and ConversationRow.
// Group chats (visit_group, ADR 0033 D9): `sender` puts the name and the role badge (Client, Hotel representative, Ghazal support) above a
// bubble, and `group` gives a system line its quiet glyph (appointment confirmed, arrived, read-only).
// ChatBubble     text (as typed, `dir=auto`, in its own language), image, document, voice (a waveform you can read at a glance), and the three
//                structured cards (meeting, quote request, booking); system lines are a centred caption. Own messages sit at inline-end in
//                ink-700 with canvas text, received ones at inline-start on ink-50; the tail corner is the 4 radius. No gold: a chat is not a verb.
// ConversationRow the Messages list row: monogram, title, one line of preview, a time and the gold unread count
import { useMemo } from 'react'
import type { IconName } from '@gz/tokens'
import type { Conversation, Message, ThreadRole } from '@gz/contracts'
import { useFormat, useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Avatar, CountBadge, Icon, ListRow } from '../core'
import { cx } from '../core/cx'
import { Photo, imageSrc } from '../overlays'
import { RoleBadge } from '../domain-visits/RoleBadge'
import { Fig, Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './chat.css'

const useW = defineWords({
  sent: p('Sent', 'أُرسلت'),
  delivered: p('Delivered', 'وصلت'),
  read: p('Read', 'قُرئت'),
  play: p('Play voice message', 'تشغيل الرسالة الصوتية'),
  pause: p('Pause voice message', 'إيقاف الرسالة الصوتية'),
  voice: p('Voice message', 'رسالة صوتية'),
  photo: p('Photo', 'صورة'),
  download: p('Download {name}', 'تنزيل {name}'),
  open: p('Open photo', 'فتح الصورة'),
  pdf: p('PDF', 'PDF'),
  kb: p('{n} KB', '{n} ك.ب'),
  meeting: p('Meeting', 'اجتماع'),
  quote: p('Quote request', 'طلب عرض سعر'),
  booking: p('Booking', 'حجز'),
  draft: p('Draft', 'مسودة'),
  handled: p('Handled by {name}', 'يتابع معكم {name}'),
  you: p('You: ', 'أنتم: '),
  pinned: p('Pinned', 'مثبتة'),
})

export type ChatSide = 'client' | 'hotel'

/** 28 deterministic bar heights (px values from the 4-pt scale) so every voice message has its own, stable waveform. */
function waveform(seed: string, bars = 28): number[] {
  const steps = [4, 8, 12, 16, 20, 24]
  let h = 0
  for (const ch of seed) h = (h * 31 + ch.charCodeAt(0)) >>> 0
  return Array.from({ length: bars }, (_, i) => {
    h = (h * 1103515245 + 12345 + i) >>> 0
    const envelope = Math.sin((i / (bars - 1)) * Math.PI)
    const idx = Math.min(steps.length - 1, Math.max(0, Math.round(envelope * 2 + ((h >>> 8) % 4))))
    return steps[idx] ?? 8
  })
}

export type ChatBubbleProps = {
  message: Message
  /** Whose phone this is: messages from this side sit at inline-end. */
  side?: ChatSide
  /** Voice: the playing state and the share played (0 to 1). */
  playing?: boolean
  progress?: number
  onPlay?: () => void
  onOpen?: () => void
  /** Show the time and the delivery state under the bubble (the last of a run). */
  showMeta?: boolean
  /** Group chat: who wrote it. Shown above the first bubble of a run, name then role badge. */
  sender?: { name: string; role: ThreadRole; you?: boolean }
  /** Group chat: system lines carry a glyph (a check for confirmed or arrived, a clock for closed). */
  group?: boolean | IconName
  className?: string
}

const ownFrom = (m: Message, side: ChatSide) => (side === 'client' ? m.from === 'client' : m.from === 'venue')

export function ChatBubble({ message: m, side = 'client', playing = false, progress = 0, onPlay, onOpen, showMeta = true, sender, group = false, className }: ChatBubbleProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  const own = ownFrom(m, side)
  const bars = useMemo(() => waveform(m.id), [m.id])

  if (m.kind === 'system') {
    // System lines are written by the app, so they follow the viewer's language; typed messages stay in their own.
    const text = m.text ? m.text[group ? lang : m.origin] : ''
    return (
      <p data-gz="ChatBubble" data-kind="system" className={cx('gz-bubble-system gz-t-caption', group && 'gz-bubble-system--group', className)}>
        {group ? <Icon name={typeof group === 'string' ? group : 'info'} size="xs" tone="secondary" /> : null}
        <span>{group ? <Figures text={text} /> : text}</span>
      </p>
    )
  }

  const status = m.status === 'read' ? w('read') : m.status === 'delivered' ? w('delivered') : w('sent')
  const meta = showMeta ? (
    <span className="gz-bubble__meta gz-t-caption" data-gz-id="meta">
      <Fig>{f.time(m.at)}</Fig>
      {own ? (
        <>
          <Icon name={m.status === 'read' ? 'check-double' : 'check'} size="xs" tone={m.status === 'read' ? 'accent' : 'secondary'} />
          <span className="gz-sr-only">{status}</span>
        </>
      ) : null}
      {m.draft ? <span className="gz-bubble__draft">{w('draft')}</span> : null}
    </span>
  ) : null

  let body: React.ReactNode
  switch (m.kind) {
    case 'image':
      body = m.image ? (
        <button type="button" className="gz-reset gz-bubble__image" onClick={onOpen} aria-label={`${w('open')}: ${bi(m.image.alt)}`}>
          <Photo src={imageSrc(m.image.file)} alt={bi(m.image.alt)} className="gz-bubble__photo" />
        </button>
      ) : null
      break
    case 'document':
      body = m.document ? (
        <span className="gz-bubble__doc" data-gz-id="document">
          <span className="gz-bubble__doc-icon">
            <Icon name="document" size="md" />
          </span>
          <span className="gz-bubble__doc-text">
            <bdi dir="ltr" className="gz-bubble__doc-name gz-t-body-s gz-ellipsis">
              {m.document.name}
            </bdi>
            <span className="gz-bubble__doc-meta gz-t-caption">
              {w('pdf')} · <Figures text={w('kb', { n: f.integer(m.document.sizeKb) })} />
            </span>
          </span>
          <span className="gz-bubble__doc-get" role="img" aria-label={w('download', { name: m.document.name })}>
            <Icon name="download" size="sm" />
          </span>
        </span>
      ) : null
      break
    case 'voice': {
      const secs = m.voice?.seconds ?? 0
      const done = Math.round(bars.length * Math.min(Math.max(progress, 0), 1))
      body = (
        <span className="gz-bubble__voice" data-gz-id="voice">
          <button type="button" className="gz-reset gz-bubble__play gz-press" onClick={onPlay} aria-label={playing ? w('pause') : w('play')} aria-pressed={playing}>
            <span className="gz-bubble__disc">{playing ? <Icon name="pause" size="sm" /> : <Icon name="play" size="sm" />}</span>
          </button>
          <span className="gz-bubble__wave" role="img" aria-label={w('voice')}>
            {bars.map((h, i) => (
              <span key={i} className={cx('gz-bubble__bar', i < done && 'is-played')} style={{ blockSize: h }} />
            ))}
          </span>
          <span className="gz-bubble__time gz-t-fig-caption">
            <bdi dir="ltr">
              {f.integer(Math.floor(secs / 60))}:{String(secs % 60).padStart(2, '0')}
            </bdi>
          </span>
        </span>
      )
      break
    }
    case 'meeting_card':
    case 'quote_request_card':
    case 'booking_card':
    case 'visit_card': {
      const c = m.card
      const icon = m.kind === 'meeting_card' ? 'calendar' : m.kind === 'quote_request_card' ? 'clipboard' : m.kind === 'visit_card' ? 'calendar-check' : 'receipt'
      body = c ? (
        <span className="gz-bubble__card" data-gz-id="card">
          <span className="gz-bubble__card-head">
            <Icon name={icon} size="sm" tone="secondary" />
            <span className="gz-bubble__card-title gz-t-title">{bi(c.title)}</span>
          </span>
          {c.lines.map((line, i) => (
            <span key={i} className="gz-bubble__card-line gz-t-body-s">
              <Figures text={bi(line)} />
            </span>
          ))}
          {c.at ? (
            <span className="gz-bubble__card-line gz-t-body-s">
              <Figures text={f.dateTime(c.at, 'short')} />
            </span>
          ) : null}
        </span>
      ) : null
      break
    }
    default:
      body = (
        <span className="gz-bubble__text gz-t-body-s" lang={m.origin} dir="auto" data-gz-id="text">
          {m.text ? m.text[m.origin] : ''}
        </span>
      )
  }

  const bare = m.kind === 'image'
  return (
    <div data-gz="ChatBubble" data-kind={m.kind} data-own={own || undefined} data-lang={lang} className={cx('gz-bubble', own ? 'gz-bubble--own' : 'gz-bubble--other', m.draft && 'is-draft', className)}>
      {sender ? (
        <span className="gz-bubble__sender" data-gz-id="sender">
          <span className="gz-bubble__sender-name gz-t-caption" dir="auto">
            {sender.name}
          </span>
          <RoleBadge role={sender.role} you={sender.you} />
        </span>
      ) : null}
      <div className={cx('gz-bubble__body', bare && 'gz-bubble__body--bare')}>{body}</div>
      {meta}
    </div>
  )
}

/** A day separator: a centred caption between two runs of messages. */
export function ChatDateDivider({ date }: { date: string }) {
  const f = useFormat()
  return (
    <p data-gz="ChatDateDivider" className="gz-bubble-day gz-t-caption">
      <Figures text={f.relativeDay(date)} />
    </p>
  )
}

// ---------------------------------------------------------------- ConversationRow
export type ConversationRowProps = {
  conversation: Conversation
  /** The last message (any kind) for the preview line. */
  last?: Message | null
  side?: ChatSide
  onOpen?: () => void
  className?: string
}

export function ConversationRow({ conversation: c, last, side = 'client', onOpen, className }: ConversationRowProps) {
  const f = useFormat()
  const t = useT('client-shell')
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  const unread = c.unread[side]
  const preview = !last
    ? bi(c.subtitle)
    : last.kind === 'voice'
      ? `${w('voice')} ${f.integer(Math.floor((last.voice?.seconds ?? 0) / 60))}:${String((last.voice?.seconds ?? 0) % 60).padStart(2, '0')}`
      : last.kind === 'image'
        ? w('photo')
        : last.kind === 'document'
          ? last.document?.name ?? ''
          : last.card
            ? bi(last.card.title)
            : last.text
              ? last.text[last.origin]
              : ''
  const mine = last ? ownFrom(last, side) : false
  return (
    <div data-gz="ConversationRow" data-unread={unread > 0 || undefined} className={cx('gz-conv', className)}>
      <ListRow
        title={bi(c.title)}
        autoDir
        subtitle={
          <span className={cx('gz-conv__preview', unread > 0 && 'is-unread')}>
            {mine ? <span className="gz-conv__you">{w('you')}</span> : null}
            <span className="gz-conv__text" dir="auto">
              <Figures text={preview} />
            </span>
          </span>
        }
        leading={<Avatar name={bi(c.title)} initial={lang === 'ar' ? c.monogram : undefined} size="md" />}
        trailing={
          <span className="gz-conv__side">
            <span className="gz-conv__time gz-t-caption">
              <Figures text={f.ago(c.lastMessageAt)} />
            </span>
            {unread > 0 ? <CountBadge count={unread} label={t('clientShellTabUnread', { count: unread })} /> : c.pinned ? <Icon name="bookmark" size="xs" tone="secondary" label={w('pinned')} /> : null}
          </span>
        }
        onClick={onOpen}
      />
    </div>
  )
}
