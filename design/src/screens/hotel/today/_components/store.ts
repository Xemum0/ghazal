// Flow-local prototype memory for the Today flow: things that must stay in step between Today, Needs you, Notifications and the
// Messages tab but are not part of the shared prototype store (the weekly calendar confirmation, which conversations were opened or
// answered, drafts sent from the thread). Which notifications were read lives in the shared store. Nothing is persisted; a reload is
// the story start.
import { create } from 'zustand'

export type SentMessage = {
  id: string
  conversationId: string
  at: string
  kind: 'text' | 'voice' | 'image' | 'document'
  /** Text as typed (its own language). */
  text?: string
  seconds?: number
  image?: { file: string; alt: { en: string; ar: string } }
  document?: { name: string; sizeKb: number }
  /** `queued` = typed offline, waits with a clock icon and sends on reconnect (ADR 0008 D10). */
  state: 'sending' | 'sent' | 'failed' | 'queued'
}

type TodayLocal = {
  /** The weekly "Confirm your calendar is up to date" check was confirmed in place (OQ-B-22). */
  calendarConfirmed: boolean
  confirmCalendar: () => void
  /** Conversations the hotel has opened (their unread count is cleared in the prototype). */
  openedConversations: string[]
  openConversation: (id: string) => void
  /** Conversations the hotel marked as unread again from the long-press menu. */
  markedUnread: string[]
  setUnread: (id: string, unread: boolean) => void
  /** Conversations the hotel has answered in this session (the `Needs reply` tag clears). */
  repliedConversations: string[]
  /** Messages typed in the prototype thread, per conversation. */
  sent: SentMessage[]
  send: (m: SentMessage) => void
  patchSent: (id: string, patch: Partial<SentMessage>) => void
  reset: () => void
}

export const useTodayLocal = create<TodayLocal>()(set => ({
  calendarConfirmed: false,
  confirmCalendar: () => set({ calendarConfirmed: true }),
  openedConversations: [],
  openConversation: id => set(s => ({ openedConversations: s.openedConversations.includes(id) ? s.openedConversations : [...s.openedConversations, id], markedUnread: s.markedUnread.filter(x => x !== id) })),
  markedUnread: [],
  setUnread: (id, unread) =>
    set(s => ({
      markedUnread: unread ? (s.markedUnread.includes(id) ? s.markedUnread : [...s.markedUnread, id]) : s.markedUnread.filter(x => x !== id),
      openedConversations: unread ? s.openedConversations.filter(x => x !== id) : s.openedConversations.includes(id) ? s.openedConversations : [...s.openedConversations, id],
    })),
  repliedConversations: [],
  sent: [],
  send: m => set(s => ({ sent: [...s.sent, m], repliedConversations: s.repliedConversations.includes(m.conversationId) ? s.repliedConversations : [...s.repliedConversations, m.conversationId] })),
  patchSent: (id, patch) => set(s => ({ sent: s.sent.map(m => (m.id === id ? { ...m, ...patch } : m)) })),
  reset: () => set({ calendarConfirmed: false, openedConversations: [], markedUnread: [], repliedConversations: [], sent: [] }),
}))

/** The unread count of a conversation as the prototype shows it: opened clears it, marked-unread restores at least one. */
export function unreadOf(id: string, fixture: number, opened: string[], marked: string[]): number {
  if (marked.includes(id)) return Math.max(1, fixture)
  return opened.includes(id) ? 0 : fixture
}
