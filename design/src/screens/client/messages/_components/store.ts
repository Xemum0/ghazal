// Flow-local prototype memory of the Messages flow: what the couple typed, sent, muted, blocked or reported in this session, which
// conversations they opened (their unread count clears), the notification permission and the pre-prompt. The shared prototype store owns
// what crosses flows (auth, the hotel's decision on the hero request, the payment outcome, which notifications were read); a request for a
// shared chat slice is in docs/engineering/requests.md. Nothing is persisted: a reload is the story start.
import { create } from 'zustand'
import { PROTOTYPE_NOW } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'

export type LocalKind = 'text' | 'voice' | 'image' | 'document'
/** `queued` = typed offline: waits with a clock and sends on reconnect (messages may queue, unlike booking decisions). */
export type LocalState = 'uploading' | 'sending' | 'sent' | 'delivered' | 'failed' | 'queued'

export type LocalMessage = {
  id: string
  conversationId: string
  at: string
  kind: LocalKind
  /** Text as typed, in its own language. */
  text?: string
  seconds?: number
  image?: { file: string; alt: { en: string; ar: string } }
  document?: { name: string; sizeKb: number }
  /** Share uploaded (0 to 1) while `state` is `uploading`. */
  progress?: number
  state: LocalState
}

export type Permission = 'unknown' | 'granted' | 'denied'

type MsgStore = {
  sent: LocalMessage[]
  /** Conversations opened in this session: their fixture unread count reads as zero. */
  opened: string[]
  /** How many of the hotel's replies (read from the hotel app's own store) the couple has seen. */
  hotelSeen: number
  muted: string[]
  blocked: string[]
  /** Message ids reported in this session. */
  reported: string[]
  /** Venue ids with an enquiry started here (the first message makes the conversation real). */
  enquiries: string[]
  /** Unsent text per conversation, kept across the sign-in sheet (ADR 0007 D9). */
  drafts: Record<string, string>
  permission: Permission
  /** The pre-prompt shows once per session, after a request exists (never at launch). */
  promptShown: boolean
  send: (m: Omit<LocalMessage, 'id' | 'at' | 'state' | 'progress'>, opts?: { offline?: boolean; upload?: boolean }) => string
  patch: (id: string, patch: Partial<LocalMessage>) => void
  retry: (id: string) => void
  discard: (id: string) => void
  open: (conversationId: string) => void
  seeHotel: (count: number) => void
  setMuted: (conversationId: string, on: boolean) => void
  setBlocked: (conversationId: string, on: boolean) => void
  report: (messageId: string) => void
  startEnquiry: (venueId: string) => void
  setDraft: (conversationId: string, text: string) => void
  setPermission: (p: Permission) => void
  markPromptShown: () => void
  reset: () => void
}

const NOW_MS = Date.parse(PROTOTYPE_NOW)
/** Local messages are stamped a minute apart after the prototype clock, before the hotel's own replies (4:08 PM on). */
const stamp = (n: number) => new Date(NOW_MS + (1 + n) * 60_000).toISOString()

const timers = new Map<string, number[]>()
const later = (id: string, ms: number, fn: () => void) => {
  const handle = window.setTimeout(fn, ms)
  timers.set(id, [...(timers.get(id) ?? []), handle])
}

const initial = {
  sent: [] as LocalMessage[],
  opened: [] as string[],
  hotelSeen: 0,
  muted: [] as string[],
  blocked: [] as string[],
  reported: [] as string[],
  enquiries: [] as string[],
  drafts: {} as Record<string, string>,
  permission: 'unknown' as Permission,
  promptShown: false,
}

export const useMsgStore = create<MsgStore>()((set, get) => {
  /** sending -> sent -> delivered: a 700 ms hop and a 1.2 s hop, so the ticks are seen to change. */
  const deliver = (id: string) => {
    later(id, 700, () => get().patch(id, { state: 'sent' }))
    later(id, 1900, () => get().patch(id, { state: 'delivered' }))
  }
  return {
    ...initial,
    send: (m, opts) => {
      const n = get().sent.length
      const id = `local-${n + 1}`
      const offline = Boolean(opts?.offline)
      const upload = Boolean(opts?.upload) && !offline
      set(s => ({ sent: [...s.sent, { ...m, id, at: stamp(n), state: offline ? 'queued' : upload ? 'uploading' : 'sending', progress: upload ? 0.1 : undefined }] }))
      if (upload) {
        // The share uploaded climbs in four steps, then the message goes out like any other.
        ;[0.35, 0.6, 0.85].forEach((p, i) => later(id, 350 * (i + 1), () => get().patch(id, { progress: p })))
        later(id, 1400, () => {
          get().patch(id, { state: 'sending', progress: undefined })
          deliver(id)
        })
      } else if (!offline) deliver(id)
      return id
    },
    patch: (id, patch) => set(s => ({ sent: s.sent.map(m => (m.id === id ? { ...m, ...patch } : m)) })),
    retry: id => {
      get().patch(id, { state: 'sending' })
      deliver(id)
    },
    discard: id => {
      for (const h of timers.get(id) ?? []) window.clearTimeout(h)
      timers.delete(id)
      set(s => ({ sent: s.sent.filter(m => m.id !== id) }))
    },
    open: conversationId => set(s => (s.opened.includes(conversationId) ? s : { opened: [...s.opened, conversationId] })),
    seeHotel: count => set(s => (s.hotelSeen === count ? s : { hotelSeen: count })),
    setMuted: (conversationId, on) => set(s => ({ muted: on ? [...new Set([...s.muted, conversationId])] : s.muted.filter(x => x !== conversationId) })),
    setBlocked: (conversationId, on) => set(s => ({ blocked: on ? [...new Set([...s.blocked, conversationId])] : s.blocked.filter(x => x !== conversationId) })),
    report: messageId => set(s => ({ reported: [...new Set([...s.reported, messageId])] })),
    startEnquiry: venueId => set(s => (s.enquiries.includes(venueId) ? s : { enquiries: [...s.enquiries, venueId] })),
    setDraft: (conversationId, text) => set(s => ({ drafts: { ...s.drafts, [conversationId]: text } })),
    setPermission: permission => set({ permission }),
    markPromptShown: () => set({ promptShown: true }),
    reset: () => {
      for (const list of timers.values()) for (const h of list) window.clearTimeout(h)
      timers.clear()
      set({ ...initial })
    },
  }
})

// A session ends when the prototype goes back to guest (Restart in the launcher, sign-out): the flow forgets everything with it.
usePrototype.subscribe((state, prev) => {
  if (state.auth === 'guest' && prev.auth === 'signedIn') useMsgStore.getState().reset()
})

/** The unread count a conversation shows now: opening it clears the fixture count. */
export const unreadOf = (id: string, fixture: number, opened: readonly string[]): number => (opened.includes(id) ? 0 : fixture)
