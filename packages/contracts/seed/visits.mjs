// Site visits and their three-way group chats (ADR 0033 D9, voucher-model section 11). A visit is free and independent of the voucher; each
// visit creates one dedicated group chat of exactly three roles: the client, a hotel representative and a Ghazal support representative.
import { bil } from './lib.mjs'
import { users } from './people.mjs'
import { venues } from './catalog.mjs'
import { addHours, addDays, kuwaitDateOf } from '../src/engine/dates.ts'
import { config, } from './meta.mjs'

const at = (date, time) => `${date}T${time}:00+03:00`
const user = (id) => users.find((u) => u.id === id)
const venueName = (id) => venues.find((v) => v.id === id).name

const CLIENT_CHIP = bil('Client', 'العميل')
const REP_CHIP = bil('Hotel representative', 'ممثل الفندق')
const SUPPORT_CHIP = bil('Ghazal support', 'دعم غزل')

const member = (userId, role, organisation = null) => {
  const u = user(userId)
  return {
    userId,
    role,
    name: u.name,
    nameLatin: u.nameLatin ?? u.name,
    monogram: u.monogram,
    chip: role === 'client' ? CLIENT_CHIP : role === 'support' ? SUPPORT_CHIP : REP_CHIP,
    organisation,
  }
}

export const SUPPORT_REP = 'user-support-lama'

/** [id, venueId, clientId, representativeUserId, slot date, slot time, visitors, note, status, requestedAt, history[]] */
const rows = [
  {
    id: 'visit-aurelia-reem',
    venueId: 'V01',
    clientId: 'user-reem',
    representativeId: 'user-amal',
    date: '2026-11-14',
    time: '17:00',
    visitors: 3,
    note: 'نحب نشوف قاعة الدانة ومكان الكوشة.',
    status: 'confirmed',
    requestedAt: at('2026-11-10', '20:15'),
    history: [
      { at: at('2026-11-10', '20:15'), status: 'requested', actor: 'client', actorName: 'ريم الدوسري' },
      { at: at('2026-11-11', '09:40'), status: 'confirmed', actor: 'hotel_representative', actorName: 'Amal Al-Balushi' },
    ],
    arrivedAt: null,
    conversationId: 'conv-visit-aurelia-reem',
  },
  {
    id: 'visit-lumi-reem',
    venueId: 'V05',
    clientId: 'user-reem',
    representativeId: 'user-lumi-rep',
    date: '2026-11-04',
    time: '16:30',
    visitors: 2,
    note: null,
    status: 'completed',
    requestedAt: at('2026-11-02', '11:00'),
    history: [
      { at: at('2026-11-02', '11:00'), status: 'requested', actor: 'client', actorName: 'ريم الدوسري' },
      { at: at('2026-11-02', '14:10'), status: 'confirmed', actor: 'hotel_representative', actorName: 'Nadia Al-Failakawi' },
      { at: at('2026-11-04', '16:35'), status: 'arrived', actor: 'hotel_representative', actorName: 'Nadia Al-Failakawi' },
      { at: at('2026-11-04', '17:20'), status: 'completed', actor: 'system' },
    ],
    arrivedAt: at('2026-11-04', '16:35'),
    conversationId: 'conv-visit-lumi-reem',
  },
  {
    id: 'visit-aurelia-rashed',
    venueId: 'V01',
    clientId: 'user-rashed-ajmi',
    representativeId: 'user-amal',
    date: '2026-11-21',
    time: '18:00',
    visitors: 4,
    note: 'نبي نزور القاعة مع الوالدة وأخواتي.',
    status: 'requested',
    requestedAt: at('2026-11-12', '14:35'),
    history: [{ at: at('2026-11-12', '14:35'), status: 'requested', actor: 'client', actorName: 'راشد العجمي' }],
    arrivedAt: null,
    conversationId: 'conv-visit-aurelia-rashed',
  },
]

export const visits = rows.map((r) => {
  const slotStart = at(r.date, r.time)
  // The chat turns read-only 24 h after the slot, or at once on cancel or decline.
  const closedAt = r.status === 'completed' || r.status === 'missed' ? addHours(slotStart, config.visitChatReadonlyHours) : null
  return {
    id: r.id,
    venueId: r.venueId,
    clientId: r.clientId,
    clientName: user(r.clientId).name,
    requestedAt: r.requestedAt,
    slotStart,
    slotEnd: addHours(slotStart, 0.5),
    visitors: r.visitors,
    note: r.note,
    status: r.status,
    representativeId: r.representativeId,
    conversationId: r.conversationId,
    proposedSlotStart: null,
    arrivedAt: r.arrivedAt,
    closedAt: closedAt && closedAt > '2026-11-12T16:00:00+03:00' ? null : closedAt,
    history: r.history,
  }
})

/** The conversation fields of each visit's group chat (messages live in chat.mjs). */
export const groupMembers = (visit) => [
  member(visit.clientId, 'client'),
  member(visit.representativeId, 'hotel_representative', venueName(visit.venueId)),
  member(SUPPORT_REP, 'support'),
]

export const archiveOn = (closedAt) => (closedAt ? addDays(kuwaitDateOf(closedAt), config.visitChatArchiveDays) : null)
