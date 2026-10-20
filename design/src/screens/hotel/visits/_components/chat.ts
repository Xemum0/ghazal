// The lines of one visit group chat as the hotel representative reads them (HL-VIST-03): the fixture messages, the system lines the visit's own
// history implies (confirmed, another time proposed, arrived, completed, declined, cancelled, missed), and what was typed in this session.
// System lines follow the viewer's language (they are written by the app); typed messages stay in their own script. Nothing here types a
// digit or a date: both come from the formatter.
import { useMemo } from 'react'
import type { IconName } from '@gz/tokens'
import type { GroupThread, Message, VisitAppointment } from '../../../../mock'
import { PROTOTYPE_NOW } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { usePrototype } from '../../../../shell/state'
import { useWords } from './bits'
import { firstName, isChatClosed, scriptOf, useProposedSlot, useRepresentativeId } from './model'
import { useVisitsLocal, type Delivery } from './store'

export type ChatRow = { message: Message; delivery: Delivery; icon?: IconName; local: boolean }

/** Local messages are stamped a few minutes after the prototype clock, in order. */
export const stamp = (n: number): string => new Date(Date.parse(PROTOTYPE_NOW) + (8 + n) * 60_000).toISOString()

const STORE_LINES = new Set(['confirmed', 'arrived', 'completed', 'cancelled', 'declined'])

export function useChatRows(v: VisitAppointment, conversation: GroupThread | null, base: Message[], sample: ChatRow[] = []): ChatRow[] {
  const f = useFormat()
  const { lang } = useLang()
  const { t } = useWords()
  const posted = useVisitsLocal(s => s.posts[v.id])
  const session = usePrototype(s => Boolean(s.visitChats[v.id]))
  const proposed = useProposedSlot(v)
  const repId = useRepresentativeId(v)
  const rep = conversation?.members?.find(m => m.userId === repId) ?? conversation?.members?.find(m => m.role === 'hotel_representative')
  const repName = rep ? (lang === 'ar' ? rep.name : rep.nameLatin) : ''

  return useMemo(() => {
    const hasCard = base.some(m => m.kind === 'visit_card')
    const cid = conversation?.id ?? `conv-${v.id}`
    const sys = (id: string, at: string, text: string, icon: IconName): ChatRow => ({
      message: { id, conversationId: cid, from: 'system', senderName: null, at, kind: 'system', text: { en: text, ar: text }, origin: lang, status: 'read', draft: false },
      delivery: 'sent',
      icon,
      local: false,
    })
    const lines: ChatRow[] = []
    v.history.forEach((h, i) => {
      const id = `hist-${v.id}-${i}`
      if (h.status === 'requested') return
      if (session && STORE_LINES.has(h.status)) return
      if (h.status === 'confirmed' && hasCard) return
      const when = f.dateTime(v.slotStart, 'short')
      switch (h.status) {
        case 'confirmed':
          lines.push(sys(id, h.at, t('hotelVisitsLineConfirmed', { when }), 'calendar-check'))
          break
        case 'reschedule_proposed':
          lines.push(sys(id, h.at, t('hotelVisitsLineReschedule', { name: repName, when: proposed ? f.dateTime(proposed, 'short') : when }), 'calendar-dots'))
          break
        case 'arrived':
          lines.push(sys(id, h.at, t('hotelVisitsLineArrived', { name: firstName(v.clientName) }), 'check-circle'))
          break
        case 'completed':
          lines.push(sys(id, h.at, t('hotelVisitsLineCompleted'), 'check-double'))
          break
        case 'declined':
          lines.push(sys(id, h.at, t('hotelVisitsLineDeclined'), 'lock'))
          break
        case 'cancelled':
          lines.push(sys(id, h.at, t('hotelVisitsLineCancelled'), 'lock'))
          break
        case 'missed':
          lines.push(sys(id, h.at, t('hotelVisitsLineMissed'), 'clock-off'))
          break
      }
    })
    // The closing line: a chat that is read-only says so in the thread itself, once.
    if (isChatClosed(v) && !lines.some(l => l.icon === 'lock') && v.status !== 'declined' && v.status !== 'cancelled') {
      lines.push(sys(`close-${v.id}`, v.closedAt ?? PROTOTYPE_NOW, t('hotelVisitsLineClosed'), 'lock'))
    }
    const fixture: ChatRow[] = base.map(m => ({ message: m, delivery: 'sent' as Delivery, local: false, icon: m.kind === 'system' ? ('info' as IconName) : undefined }))
    const mine: ChatRow[] = (posted ?? []).map(p => ({ message: p.message, delivery: p.delivery, local: true }))
    return [...fixture, ...lines, ...mine, ...sample].sort((a, b) => Date.parse(a.message.at) - Date.parse(b.message.at) || (a.local === b.local ? 0 : a.local ? 1 : -1))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [v, base, conversation, posted, session, proposed, repName, f, lang, t, sample])
}
