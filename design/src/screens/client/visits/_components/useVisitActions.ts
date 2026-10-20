// What a client can do inside one visit: write to the chat, tap the arrival buttons, accept a proposed time. A visit booked in this session
// has its chat in the prototype store (the partner app reads the same messages); a seeded chat keeps what the client adds in the flow-local
// store. Time is the injected clock: a message typed now sits a minute after the last one, never `Date.now()`.
import type { Message, VisitAppointment } from '@gz/contracts'
import { PROTOTYPE_NOW, engine } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { useV, useVisitLocal, type VisitView } from './model'

const ACK_MS = 1800
const ARRIVE_MS = 2200
const DELIVER_MS = 500

export type OutMessage = Pick<Message, 'kind'> & Partial<Pick<Message, 'voice' | 'document' | 'image'>> & { text?: string }

export function useVisitActions(view: VisitView | null, offline: boolean) {
  const { t, lang, live, firstName } = useV()
  const local = useVisitLocal
  const visitId = view?.visit.id ?? ''

  const nextAt = (): string => {
    const here = local.getState().extra[visitId] ?? []
    const last = [...(view?.messages ?? []), ...here].reduce((m, x) => (x.at > m ? x.at : m), PROTOTYPE_NOW)
    return new Date(Date.parse(last) + 60_000).toISOString()
  }
  const nextId = (): string => `local-${visitId}-${(local.getState().extra[visitId]?.length ?? 0) + 1}`
  const inStore = (): boolean => Boolean(usePrototype.getState().visitChats[visitId])

  const post = (from: Message['from'], out: OutMessage, delivery?: 'sending' | 'queued'): Message | null => {
    if (!view) return null
    // A visit of this session: typed text goes to the prototype store, the same chat the partner app reads.
    if (inStore() && out.kind === 'text' && out.text !== undefined) {
      usePrototype.getState().sendVisitMessage(visitId, from === 'venue' ? 'venue' : from === 'support' ? 'support' : 'client', out.text)
      return null
    }
    const member = view.members.find(m => m.role === (from === 'venue' ? 'hotel_representative' : from === 'support' ? 'support' : 'client'))
    const msg: Message = {
      id: nextId(),
      conversationId: view.conversationId,
      from,
      senderName: member?.nameLatin ?? null,
      at: nextAt(),
      kind: out.kind,
      text: out.text !== undefined ? { en: out.text, ar: out.text } : null,
      origin: out.text !== undefined && /[\u0600-\u06FF]/.test(out.text) ? 'ar' : out.text !== undefined ? 'en' : lang,
      voice: out.voice,
      document: out.document,
      image: out.image,
      status: 'sent',
      draft: false,
    }
    // A seeded chat (and any media) keeps what the client adds in the flow store, merged into the thread by `useVisitView`.
    local.getState().push(visitId, msg, delivery)
    return msg
  }

  /** A line in the chat's own voice. A visit of this session already gets the store's line for status changes, so those pass nothing extra. */
  const system = (text: string, tag: string, always = false) => {
    if (!view || (inStore() && !always)) return
    local.getState().push(visitId, {
      id: `${nextId()}-${tag}`, conversationId: view.conversationId, from: 'system', senderName: null, at: nextAt(), kind: 'system', text: { en: text, ar: text }, origin: lang, status: 'read', draft: false,
    })
  }

  /** The hotel representative answers the first thing the client writes (a prototype stand-in for the partner app). */
  const hotelAnswers = () => {
    if (!live || !view || view.closed || local.getState().answered[visitId]) return
    local.getState().setAnswered(visitId)
    window.setTimeout(() => {
      const key = view.phase === 'requested' ? 'clientVisitsDemoHotelAckRequested' : 'clientVisitsDemoHotelAck'
      post('venue', { kind: 'text', text: t(key, { name: firstName(lang === 'ar' ? (view.members.find(m => m.role === 'client')?.name ?? '') : (view.members.find(m => m.role === 'client')?.nameLatin ?? '')) }) })
    }, ACK_MS)
  }

  const send = (out: OutMessage) => {
    if (!view || view.closed) return
    const msg = post('client', out, offline ? 'queued' : 'sending')
    if (msg && !offline) window.setTimeout(() => local.getState().setDelivery(msg.id, null), DELIVER_MS)
    hotelAnswers()
  }

  const retry = (id: string) => {
    local.getState().setDelivery(id, 'sending')
    window.setTimeout(() => local.getState().setDelivery(id, null), DELIVER_MS)
  }
  const discard = (id: string) => local.getState().remove(visitId, id)

  /** "We are on our way". */
  const onTheWay = () => {
    if (!view || offline) return
    local.getState().setOnTheWay(visitId)
    post('client', { kind: 'text', text: t('clientVisitsTapOnTheWay') })
  }

  /** "We have arrived": the client says so; a moment later the representative marks the arrival. */
  const arrived = () => {
    if (!view || offline) return
    post('client', { kind: 'text', text: t('clientVisitsTapArrived') })
    if (!live) return
    window.setTimeout(() => {
      usePrototype.getState().setVisitStatus(visitId, 'arrived', 'hotel_representative')
      system(t('clientVisitsSysArrived'), 'arrived')
    }, ARRIVE_MS)
  }

  /** Accepts the time the hotel proposed: the slot moves, the visit is confirmed again. */
  const acceptProposed = (v: VisitAppointment) => {
    if (!v.proposedSlotStart) return
    const start = v.proposedSlotStart
    usePrototype.setState(s => ({ visits: s.visits.map(x => (x.id === v.id ? { ...x, slotStart: start, slotEnd: engine.slotEnd(start), proposedSlotStart: null } : x)) }))
    usePrototype.getState().setVisitStatus(v.id, 'confirmed', 'client')
    system(t('clientVisitsSysAccepted'), 'confirmed')
  }

  return { send, retry, discard, onTheWay, arrived, acceptProposed, system, post }
}
