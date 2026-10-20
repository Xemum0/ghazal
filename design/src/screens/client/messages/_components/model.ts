// Messages model: which conversation a screen is about, the messages it holds and the preview each inbox row shows. Content only from
// the fixtures (conversations, messages, bookings, venues, vendors); the hotel's replies are read from the hotel app's own store, so
// what the hotel sends in the shared story reaches this thread (and the unread count) without a copy.
import { useMemo } from 'react'
import type { Booking, Conversation, GroupThread, Message, ServiceProvider, Venue, VisitAppointment } from '@gz/contracts'
import { conversationsFor, getBooking, getVenue, getVisit, messagesFor, PROTOTYPE_NOW, serviceProviders } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { useTodayLocal, type SentMessage } from '../../../hotel/today/_components/store'
import type { VisitState } from '../../../../system'
import { unreadOf, useMsgStore, type LocalMessage } from './store'

export const HERO_CONVERSATION = 'conv-aurelia-reem'
export const SUPPORT_CONVERSATION = 'conv-support-reem'
export const HERO_BOOKING = 'bk-GZ-2611-0147'
export const PLANNER_CONVERSATION = 'conv-planner-nouf'

/** Config of the chat (placeholders the owner still has to set: photos 10 MB, video 60 seconds, PDF 15 MB). */
export const CHAT_LIMITS = { photoMb: 10, videoSeconds: 60, documentMb: 15 } as const

/** The script of typed text: `ar` when it holds Arabic letters (each message keeps its own language and direction, ADR 0014 D8). */
/** Chronological order across instants written with different offsets (fixtures carry +03:00, local messages are stamped in UTC). */
export const byTime = (a: { at: string }, b: { at: string }): number => Date.parse(a.at) - Date.parse(b.at)

export const scriptOf = (text: string): 'ar' | 'en' => (/[؀-ۿݐ-ݿ]/.test(text) ? 'ar' : 'en')

// ---------------------------------------------------------------- the hotel's side of the shared story

const HOTEL_REPLY_MS = Date.parse(PROTOTYPE_NOW)

const fromHotel = (s: SentMessage): Message => ({
  id: `hotel-${s.id}`,
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
  status: 'delivered',
  draft: false,
})

/** What the hotel has sent to the couple in this session (its own store), as client messages. Only the hero thread has a live hotel. */
export function useHotelReplies(): Message[] {
  const sent = useTodayLocal(s => s.sent)
  return useMemo(() => sent.filter(m => m.conversationId === HERO_CONVERSATION && m.state === 'sent' && Date.parse(m.at) >= HOTEL_REPLY_MS).map(fromHotel), [sent])
}

// ---------------------------------------------------------------- conversations

const monogramOfVenue = (v: Venue): string => Array.from(v.name.ar.trim())[0] ?? ''

/** A thread with a venue that has no history yet: the enquiry the couple is about to start (no data is invented; it is the venue's own record). */
export function enquiryFor(venueId: string): Conversation | null {
  const v = getVenue(venueId)
  if (!v) return null
  return {
    id: `enq-${v.id}`,
    kind: 'enquiry',
    title: v.name,
    subtitle: { en: '', ar: '' },
    monogram: monogramOfVenue(v),
    clientId: 'user-reem',
    clientName: '',
    venueId: v.id,
    bookingId: null,
    plannerId: null,
    vendorId: null,
    pinned: false,
    unread: { client: 0, hotel: 0 },
    handledBy: null,
    lastMessageAt: PROTOTYPE_NOW,
    awaitingReplySince: null,
    usuallyRepliesHours: null,
  }
}

/** Ghazal Support for a guest: the one conversation that needs no account to open. */
export function guestSupport(): Conversation {
  const base = conversationsFor('client').find(c => c.id === SUPPORT_CONVERSATION)
  return {
    id: 'support-guest',
    kind: 'support',
    title: base?.title ?? { en: 'Ghazal Support', ar: 'دعم غزل' },
    subtitle: base?.subtitle ?? { en: '', ar: '' },
    monogram: base?.monogram ?? 'غ',
    clientId: null,
    clientName: '',
    venueId: null,
    bookingId: null,
    plannerId: null,
    vendorId: null,
    pinned: true,
    unread: { client: 0, hotel: 0 },
    handledBy: null,
    lastMessageAt: PROTOTYPE_NOW,
    awaitingReplySince: null,
    usuallyRepliesHours: null,
  }
}

/** Visit group chats created in this session (a visit booked in the prototype): the seed's own chats come from `conversationsFor`. */
export function sessionVisitThreads(): GroupThread[] {
  const chats = usePrototype.getState().visitChats
  const base = new Set(conversationsFor('client').map(c => c.id))
  return Object.values(chats)
    .map(c => c.conversation)
    .filter(c => !base.has(c.id))
}

export type ThreadParams = { conversationId?: string; bookingId?: string; venueId?: string; support?: boolean; draft?: string }

/**
 * Which conversation a screen is about. Order: an explicit id, support, a booking, a venue (an existing thread, or a fresh enquiry),
 * then the story's thread with Aurelia. A guest only ever reaches support and a fresh enquiry.
 */
export function resolveConversation(params: ThreadParams, signedIn: boolean): Conversation {
  const list = signedIn ? [...conversationsFor('client'), ...sessionVisitThreads()] : []
  const byId = (id?: string) => (id ? list.find(c => c.id === id) : undefined)
  const found =
    byId(params.conversationId) ??
    (params.support ? (signedIn ? byId(SUPPORT_CONVERSATION) : guestSupport()) : undefined) ??
    (params.bookingId ? list.find(c => c.bookingId === params.bookingId) : undefined) ??
    (params.venueId ? (list.find(c => c.venueId === params.venueId && c.kind !== 'support') ?? enquiryFor(params.venueId) ?? undefined) : undefined)
  if (found) return found
  return signedIn ? (byId(HERO_CONVERSATION) ?? list[0] ?? guestSupport()) : guestSupport()
}

// ---------------------------------------------------------------- local and system messages

export const localToMessage = (m: LocalMessage): Message => ({
  id: m.id,
  conversationId: m.conversationId,
  from: 'client',
  senderName: null,
  at: m.at,
  kind: m.kind,
  text: m.text ? { en: m.text, ar: m.text } : null,
  origin: scriptOf(m.text ?? ''),
  voice: m.seconds ? { seconds: m.seconds } : undefined,
  document: m.document ? { ...m.document, mime: 'application/pdf' } : undefined,
  image: m.image,
  status: m.state === 'delivered' ? 'delivered' : 'sent',
  draft: false,
})

export type SystemEvent = {
  id: string
  at: string
  kind: 'requested' | 'approved' | 'confirmed' | 'redeemed' | 'not_accepted' | 'expired' | 'cancelled'
  /** Why a request expired: the venue never replied, or the 24 hour confirm window ended (the sentence differs, the voucher stays the client's). */
  reason?: 'venue' | 'client'
}

const KIND_OF_STATUS: Partial<Record<string, SystemEvent['kind']>> = {
  pending: 'requested',
  approved: 'approved',
  confirmed: 'confirmed',
  redeemed: 'redeemed',
  declined: 'not_accepted',
  expired: 'expired',
  cancelled: 'cancelled',
}

/** The request as the prototype holds it now: the client's copy in the shared store follows the hotel's decision and the client's own confirmation. */
export function useLiveBooking(bookingId: string | null | undefined): { booking: Booking; events: SystemEvent[] } | null {
  const live = usePrototype(s => s.clientBookings.find(b => b.id === bookingId) ?? s.hotelBookings.find(b => b.id === bookingId))
  return useMemo(() => {
    if (!bookingId) return null
    const booking = live ?? getBooking(bookingId)
    if (!booking) return null
    const events = booking.events
      .map((e, i): SystemEvent | null => {
        const kind = e.to ? KIND_OF_STATUS[e.to] : undefined
        if (!kind || e.kind !== 'transition') return null
        const reason: SystemEvent['reason'] = kind === 'expired' ? (booking.expiredReason === 'client_no_confirmation' ? 'client' : 'venue') : undefined
        return { id: `sys-${bookingId}-${i}`, at: e.at, kind, reason }
      })
      .filter((e): e is SystemEvent => e !== null)
    return { booking, events }
  }, [bookingId, live])
}

// ---------------------------------------------------------------- the inbox

export type PreviewKind = 'text' | 'voice' | 'image' | 'document' | 'card' | 'system'
export type RowModel = {
  conversation: Conversation
  /** Preview line: text in its own language, or a kind the row words itself. */
  preview: { kind: PreviewKind; text: string; lang: 'ar' | 'en'; seconds?: number }
  mine: boolean
  /** Delivery state of the last message when it is the couple's own (one tick, two, two in gold). */
  status: Message['status']
  at: string
  unread: number
  /** A visit group chat: the visit it belongs to (its slot and status drive the context line). */
  visit?: VisitAppointment
}

const previewOf = (m: Message, lang: 'ar' | 'en'): RowModel['preview'] => {
  if (m.kind === 'voice') return { kind: 'voice', text: '', lang, seconds: m.voice?.seconds }
  if (m.kind === 'image') return { kind: 'image', text: '', lang }
  if (m.kind === 'document') return { kind: 'document', text: m.document?.name ?? '', lang: 'en' }
  if (m.card) return { kind: 'card', text: m.card.title[lang], lang }
  // A system line of a visit chat (opened, arrived, complete, read-only) is a glyph in the row; its words stay as the accessible name.
  if (m.kind === 'system') return { kind: 'system', text: m.text ? m.text[lang] : '', lang }
  return { kind: 'text', text: m.text ? m.text[m.origin] : '', lang: m.origin }
}

/** Every conversation the couple has (venues, planner, providers, support and visit group chats), pinned first and then the most recent. */
export function useInbox(lang: 'ar' | 'en'): RowModel[] {
  const sent = useMsgStore(s => s.sent)
  const opened = useMsgStore(s => s.opened)
  const enquiries = useMsgStore(s => s.enquiries)
  const hotelSeen = useMsgStore(s => s.hotelSeen)
  const hotel = useHotelReplies()
  const visits = usePrototype(s => s.visits)
  const visitChats = usePrototype(s => s.visitChats)
  return useMemo(() => {
    const base = conversationsFor('client')
    const started = enquiries.filter(id => !base.some(c => c.venueId === id)).map(enquiryFor).filter((c): c is Conversation => c !== null)
    const created = Object.values(visitChats)
      .map(c => c.conversation)
      .filter(c => !base.some(b => b.id === c.id))
    const rows = [...base, ...created, ...started].map((conversation): RowModel => {
      const visitChat = conversation.visitId ? visitChats[conversation.visitId] : undefined
      const fixture = conversation.id.startsWith('enq-') ? [] : (visitChat?.messages ?? messagesFor(conversation.id, 'client'))
      const all: Message[] = [...fixture, ...(conversation.id === HERO_CONVERSATION ? hotel : []), ...sent.filter(m => m.conversationId === conversation.id).map(localToMessage)].sort(byTime)
      const last = all[all.length - 1]
      const hotelUnread = conversation.id === HERO_CONVERSATION ? Math.max(0, hotel.length - hotelSeen) : 0
      return {
        conversation,
        preview: last ? previewOf(last, lang) : { kind: 'text', text: '', lang },
        mine: last?.from === 'client',
        status: last?.status ?? 'sent',
        at: last?.at ?? conversation.lastMessageAt,
        unread: unreadOf(conversation.id, conversation.unread.client, opened) + hotelUnread,
        visit: conversation.visitId ? (visits.find(v => v.id === conversation.visitId) ?? getVisit(conversation.visitId)) : undefined,
      }
    })
    return rows.sort((a, b) => (a.conversation.pinned === b.conversation.pinned ? Date.parse(b.at) - Date.parse(a.at) : a.conversation.pinned ? -1 : 1))
  }, [sent, opened, enquiries, hotelSeen, hotel, visits, visitChats, lang])
}

/** The visit's own status as the shared status vocabulary (glyph and word), for the inbox row and the details sheet. */
export const VISIT_PILL: Record<VisitAppointment['status'], VisitState> = {
  requested: 'visit_requested',
  confirmed: 'visit_confirmed',
  reschedule_proposed: 'visit_reschedule',
  arrived: 'visit_arrived',
  completed: 'visit_completed',
  declined: 'visit_declined',
  cancelled: 'visit_cancelled',
  missed: 'visit_missed',
}
/** A visit chat that is over: read-only (the lock glyph stands for it). */
export const VISIT_CLOSED = new Set<VisitAppointment['status']>(['completed', 'declined', 'cancelled', 'missed'])

/** Which inbox chip a conversation belongs to. */
export type InboxFilter = 'all' | 'venues' | 'visits' | 'planner' | 'providers' | 'support'
export const filterOf = (c: Conversation): Exclude<InboxFilter, 'all'> =>
  c.kind === 'visit_group' ? 'visits' : c.kind === 'planner' ? 'planner' : c.kind === 'vendor' ? 'providers' : c.kind === 'support' ? 'support' : 'venues'

export const providerOf = (c: Conversation): ServiceProvider | undefined => (c.vendorId ? serviceProviders.find(v => v.id === c.vendorId) : undefined)
export const venueOf = (c: Conversation): Venue | undefined => (c.venueId ? getVenue(c.venueId) : undefined)
