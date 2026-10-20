// The prototype store (zustand). One store, ten slices, no persistence: a reload is the story start. Screens read it with
// selectors (`usePrototype(s => s.compareList)`); only the system components that need it (tab badges, the compare tray) read it
// too. Actions are plain functions on the store, so a screen never needs to know how a slice is built.
import { create } from 'zustand'
import * as mock from '../../mock'
import type { Booking, Listing, Message, Voucher, VisitAppointment } from '../../mock'
import { setParam } from '../router'
import { clone as deepClone, newVoucher, paidVoucher, releasedVoucher, forfeitedVoucher, transition, usedVoucher } from './rules'
import {
  EMPTY_BRIEF,
  EMPTY_DRAFT,
  IDLE_PAYMENT,
  addHours,
  clientBookingsCopy,
  clone,
  hotelBookingsCopy,
  hotelVenueId,
  listingsCopy,
  nowIso,
  safe,
  storyBrief,
  storyCompare,
  storyFavourites,
  storyUser,
  storyWeddingProfile,
  todayIso,
  visitsCopy,
  vouchersCopy,
} from './defaults'
import { COMPARE_MAX, type PrototypeState, type VisitChat } from './types'

const { engine } = mock
const CONFIG = () => mock.meta.config
void deepClone

const initial = () => ({
  language: 'en' as const,
  auth: 'guest' as const,
  user: null,
  gate: null,
  weddingProfile: null,
  favourites: { venue: [] as string[], vendor: [] as string[], package: [] as string[] },
  signupNudge: false,
  compareList: [] as string[],
  searchBrief: { ...EMPTY_BRIEF },
  bookingDraft: { ...EMPTY_DRAFT, personal: { ...EMPTY_DRAFT.personal }, extras: [] as string[] },
  payment: { ...IDLE_PAYMENT },
  hotelBookings: hotelBookingsCopy(),
  clientBookings: clientBookingsCopy(),
  vouchers: vouchersCopy(),
  visits: visitsCopy(),
  visitChats: {} as Record<string, VisitChat>,
  listings: listingsCopy(),
  lastHotelAction: null,
  readNotificationIds: [] as string[],
})


/** Writes one changed request into every list that holds it (client and partner see the same request) and, with it, its voucher. */
function syncBooking(s: PrototypeState, next: Booking, voucher: Voucher | null): Partial<PrototypeState> {
  const put = (list: Booking[]) => list.map(x => (x.id === next.id ? next : x))
  return {
    clientBookings: put(s.clientBookings),
    hotelBookings: put(s.hotelBookings),
    ...(voucher ? { vouchers: s.vouchers.map(x => (x.id === voucher.id ? voucher : x)) } : {}),
  }
}

export const usePrototype = create<PrototypeState>()((set, get) => ({
  ...initial(),

  // ---------------------------------------------------------------- language
  setLanguage: lang => {
    set({ language: lang })
    setParam('lang', lang)
  },

  // ---------------------------------------------------------------- auth
  signIn: user => set({ auth: 'signedIn', user: user ?? storyUser(), gate: null }),
  signOut: () => set({ auth: 'guest', user: null, gate: null }),
  openGate: (reason, resume = null) => set({ gate: { reason, resume } }),
  clearGate: () => set({ gate: null }),

  // ---------------------------------------------------------------- wedding profile
  setWeddingProfile: weddingProfile => set({ weddingProfile }),
  patchWeddingProfile: patch => set(s => (s.weddingProfile ? { weddingProfile: { ...s.weddingProfile, ...patch } } : s)),

  // ---------------------------------------------------------------- favourites
  toggleFavourite: (kind, id) => {
    const s = get()
    const has = s.favourites[kind].includes(id)
    const list = has ? s.favourites[kind].filter(x => x !== id) : [...s.favourites[kind], id]
    const total = s.favourites.venue.length + s.favourites.vendor.length + s.favourites.package.length + (has ? -1 : 1)
    set({
      favourites: { ...s.favourites, [kind]: list },
      // The sign-up nudge shows once, after the third heart, for a guest (ADR 0007 D10).
      signupNudge: s.signupNudge || (!has && s.auth === 'guest' && total === 3),
    })
    return !has
  },
  clearSignupNudge: () => set({ signupNudge: false }),

  // ---------------------------------------------------------------- compare
  addToCompare: venueId => {
    const list = get().compareList
    if (list.includes(venueId)) return 'exists'
    if (list.length >= COMPARE_MAX) return 'full'
    set({ compareList: [...list, venueId] })
    return 'added'
  },
  removeFromCompare: venueId => set(s => ({ compareList: s.compareList.filter(id => id !== venueId) })),
  replaceInCompare: (oldId, newId) =>
    set(s => (s.compareList.includes(newId) ? s : { compareList: s.compareList.map(id => (id === oldId ? newId : id)) })),
  clearCompare: () => set({ compareList: [] }),

  // ---------------------------------------------------------------- brief
  setBrief: patch => set(s => ({ searchBrief: { ...s.searchBrief, ...patch } })),
  clearBrief: () => set({ searchBrief: { ...EMPTY_BRIEF } }),

  // ---------------------------------------------------------------- booking draft
  startDraft: (venueId, patch = {}) => {
    const brief = get().searchBrief
    const user = get().user
    set({
      bookingDraft: {
        ...EMPTY_DRAFT,
        extras: [],
        personal: { ...EMPTY_DRAFT.personal, name: user?.name ?? '', phone: user?.phone ?? '' },
        venueId,
        eventDate: brief.date ?? null,
        audience: brief.audience ?? null,
        guests: brief.guests ?? null,
        ...patch,
      },
    })
  },
  patchDraft: patch => set(s => ({ bookingDraft: { ...s.bookingDraft, ...patch } })),
  toggleExtra: extraId =>
    set(s => ({
      bookingDraft: {
        ...s.bookingDraft,
        extras: s.bookingDraft.extras.includes(extraId) ? s.bookingDraft.extras.filter(x => x !== extraId) : [...s.bookingDraft.extras, extraId],
      },
    })),
  setStep: step => set(s => ({ bookingDraft: { ...s.bookingDraft, step } })),
  resetDraft: () => set({ bookingDraft: { ...EMPTY_DRAFT, extras: [], personal: { ...EMPTY_DRAFT.personal } } }),

  // ---------------------------------------------------------------- payment (the KD 2 voucher and listing plans only)
  beginPayment: ({ kind, refId, amount, method }) => set({ payment: { outcome: 'processing', method, kind, refId, amount } }),
  setPaymentOutcome: outcome => set(s => ({ payment: { ...s.payment, outcome } })),
  resetPayment: () => set({ payment: { ...IDLE_PAYMENT } }),

  // ---------------------------------------------------------------- vouchers and the client's requests
  startVoucherCheckout: purchase => {
    const s = get()
    const seq = s.vouchers.filter(v => v.id.startsWith('voucher-proto-')).length + 1
    const v = newVoucher({
      seq,
      clientId: s.user?.id ?? mock.meta.clientUserId,
      targetType: purchase.targetType,
      targetId: purchase.targetId,
      hallId: purchase.hallId ?? null,
      packageId: purchase.packageId,
      eventDate: purchase.eventDate,
      guests: purchase.guests ?? null,
      standardFils: purchase.standardFils,
      voucherFils: purchase.voucherFils,
      now: nowIso(),
    })
    set({
      vouchers: [...s.vouchers, v],
      payment: { outcome: 'idle', method: null, kind: 'voucher', refId: v.id, amount: { fils: v.priceFils, currency: 'KWD' } },
      bookingDraft: { ...s.bookingDraft, voucherId: v.id },
    })
    return v.id
  },
  settleVoucherPayment: outcome =>
    set(s => {
      const id = s.payment.refId
      const v = s.vouchers.find(x => x.id === id)
      if (s.payment.kind !== 'voucher' || !v) return s
      if (outcome === 'failed') return { payment: { ...s.payment, outcome: 'failed' } }
      const seq = s.vouchers.filter(x => x.payment).length
      const paid = paidVoucher(v, nowIso(), s.payment.method ?? 'knet', seq)
      return { vouchers: s.vouchers.map(x => (x.id === v.id ? paid : x)), payment: { ...s.payment, outcome: 'success' } }
    }),
  sendRequest: (voucherId, draftPatch = {}) => {
    const s = get()
    const v = s.vouchers.find(x => x.id === voucherId)
    if (!v || v.status !== 'active') return null
    const open = s.clientBookings.filter(b => b.status === 'pending' || b.status === 'approved').length
    if (open >= CONFIG().maxOpenRequests) return null
    const d = { ...s.bookingDraft, ...draftPatch }
    const now = nowIso()
    const seq = s.clientBookings.filter(b => b.id.startsWith('bk-proto-')).length + 1
    const isProvider = v.targetType === 'provider'
    const user = s.user ?? storyUser()
    let quote: mock.Quote
    let sections: Booking['sections'] = []
    let service: Booking['service'] = null
    let sla = CONFIG().defaultReplyHours
    try {
      if (isProvider) {
        const qty = v.guests ?? d.guests ?? 1
        quote = mock.quoteForProvider({ providerId: v.venueOrProviderId, packageId: v.packageId, qty })
        service = { providerId: v.venueOrProviderId, listingId: mock.activeListingOf(v.venueOrProviderId)?.id ?? '', packageId: v.packageId, quantity: qty, venueId: null }
      } else {
        const found = mock.getHall(v.hallId ?? '')
        if (!found) return null
        const audience = d.audience ?? found.hall.sections[0]?.audience ?? 'women'
        const guests = v.guests ?? d.guests ?? found.hall.sections[0]?.minGuests ?? 0
        quote = mock.quoteFor({
          venueId: v.venueOrProviderId,
          eventDate: v.eventDate,
          sections: [{ hallId: found.hall.id, audience, guests, packageId: v.packageId }],
          extras: d.extras.map(extraId => ({ extraId, qty: 1 })),
        })
        const session = found.hall.sessions.find(x => x.id === d.sessionId) ?? found.hall.sessions[0]
        sections = [
          { position: 1, hallId: found.hall.id, sessionId: session?.id ?? '', audience, guests, billableGuests: guests, packageId: v.packageId, start: session?.start ?? '18:00', end: session?.end ?? '23:00' },
        ]
        const lead = engine.diffDays(todayIso(), v.eventDate)
        sla = lead <= CONFIG().urgentLeadDays ? CONFIG().urgentReplyHours : (found.venue.policies.responseSlaHours ?? sla)
      }
    } catch {
      return null
    }
    const booking: Booking = {
      id: `bk-proto-${seq}`,
      ref: `GZ-${now.slice(2, 4)}${now.slice(5, 7)}-${engine.crockford4('proto-ref', seq, v.id)}`,
      seedRole: 'story',
      targetType: isProvider ? 'provider' : 'venue',
      venueId: isProvider ? null : v.venueOrProviderId,
      providerId: isProvider ? v.venueOrProviderId : null,
      clientId: user.id,
      clientName: user.name,
      weddingId: s.weddingProfile ? 'wedding-reem' : null,
      status: 'pending',
      createdAt: now,
      eventDate: v.eventDate,
      sections,
      service,
      lines: quote.lines,
      totals: quote.totals,
      voucherId: v.id,
      respondBy: addHours(now, sla),
      approvedAt: null,
      confirmBy: null,
      confirmedAt: null,
      redeemedAt: null,
      redeemedBy: null,
      completedAt: null,
      slaHours: sla,
      contact: { name: d.personal.name || user.name, phone: d.personal.phone || user.phone, shared: true, bookingFor: d.personal.bookingFor },
      specialRequests: d.requests || null,
      firstBooking: s.clientBookings.length === 0,
      verifiedPhone: true,
      thread: [],
      events: [{ at: now, kind: 'transition', from: null, to: 'pending', actor: 'client' }],
      cancelledBy: null,
      reasonCode: null,
      rejectReason: null,
      expiredReason: null,
      proposal: null,
      overlays: {},
      approvedDiscount: null,
    }
    booking.thread = transition(booking, 'pending', now, 'client').thread
    const bound: Voucher = { ...clone(v), status: 'bound', bookingId: booking.id, releasedAt: null, releaseReason: null, reuseUntil: null, creditEligible: false }
    set({
      clientBookings: [booking, ...s.clientBookings],
      hotelBookings: booking.venueId === hotelVenueId() ? [booking, ...s.hotelBookings] : s.hotelBookings,
      vouchers: s.vouchers.map(x => (x.id === v.id ? bound : x)),
      bookingDraft: { ...d, voucherId: v.id, step: 'sent' },
    })
    return booking.id
  },
  cancelRequest: (bookingId, reason = 'withdrawn') =>
    set(s => {
      const b = s.clientBookings.find(x => x.id === bookingId) ?? s.hotelBookings.find(x => x.id === bookingId)
      if (!b || !['pending', 'approved', 'confirmed'].includes(b.status)) return s
      const now = nowIso()
      const v = s.vouchers.find(x => x.id === b.voucherId)
      const next = transition(b, 'cancelled', now, 'client', { cancelledBy: 'client', reasonCode: reason })
      // R07 and R10a release the voucher (reusable, no credit route); R13a after confirmation consumes it.
      const voucher = v ? (b.status === 'confirmed' ? usedVoucher(v, now, 'cancelled_after_confirm', null) : releasedVoucher(v, 'withdrawn', now)) : null
      return syncBooking(s, next, voucher)
    }),
  confirmBooking: bookingId => {
    const s = get()
    const b = s.clientBookings.find(x => x.id === bookingId) ?? s.hotelBookings.find(x => x.id === bookingId)
    if (!b || b.status !== 'approved' || !b.confirmBy) return false
    const now = nowIso()
    if (engine.instantMs(now) > engine.instantMs(b.confirmBy)) {
      get().lapseApproval(bookingId)
      return false
    }
    set(prev => syncBooking(prev, transition(b, 'confirmed', now, 'client', { confirmedAt: now }), null))
    return true
  },
  lapseApproval: bookingId =>
    set(s => {
      const b = s.clientBookings.find(x => x.id === bookingId) ?? s.hotelBookings.find(x => x.id === bookingId)
      if (!b || b.status !== 'approved') return s
      const now = nowIso()
      const v = s.vouchers.find(x => x.id === b.voucherId)
      const next = transition(b, 'expired', now, 'system', { expiredReason: 'client_no_confirmation', confirmBy: b.confirmBy })
      return syncBooking(s, next, v ? forfeitedVoucher(v, now) : null)
    }),
  /** The client asks support for a credit voucher (ADR 0035 D5): no money goes back; support decides in the chat. */
  askSupportCredit: voucherId =>
    set(s => {
      const v = s.vouchers.find(x => x.id === voucherId)
      if (!v || v.status !== 'active' || !v.creditEligible || v.refundRequestId) return s
      const asked: Voucher = { ...clone(v), refundRequestId: `rr-proto-${v.code}` }
      return { vouchers: s.vouchers.map(x => (x.id === voucherId ? asked : x)) }
    }),

  // ---------------------------------------------------------------- partner request actions
  acceptRequest: (bookingId, opts) =>
    set(s => {
      const b = s.hotelBookings.find(x => x.id === bookingId)
      if (!b || b.status !== 'pending') return s
      const now = nowIso()
      const lower = opts?.lowerVoucherTotal
      const totals =
        lower && lower.fils < b.totals.voucherTotal.fils
          ? { ...b.totals, voucherTotal: lower, savings: { ...lower, fils: b.totals.standardTotal.fils - lower.fils } }
          : b.totals
      const next = transition(b, 'approved', now, 'venue', {
        respondBy: null,
        approvedAt: now,
        // The 24 hour confirm window is the owner's fixed rule (configuration, never partner-editable).
        confirmBy: engine.confirmByFor(now, CONFIG()),
        proposal: null,
        totals,
        approvedDiscount: totals === b.totals ? null : { fils: b.totals.voucherTotal.fils - totals.voucherTotal.fils, currency: 'KWD' },
      })
      return {
        ...syncBooking(s, next, null),
        lastHotelAction: { kind: 'approve', bookingId, before: clone(b), beforeVoucher: null },
      }
    }),
  declineRequest: (bookingId, reason = 'date_unavailable') =>
    set(s => {
      const b = s.hotelBookings.find(x => x.id === bookingId)
      if (!b || b.status !== 'pending') return s
      const now = nowIso()
      const v = s.vouchers.find(x => x.id === b.voucherId)
      const next = transition(b, 'declined', now, 'venue', { rejectReason: reason, respondBy: null })
      return {
        ...syncBooking(s, next, v ? releasedVoucher(v, 'declined', now) : null),
        lastHotelAction: { kind: 'decline', bookingId, before: clone(b), beforeVoucher: v ? clone(v) : null },
      }
    }),
  rescheduleRequest: (bookingId, newDate) =>
    set(s => {
      const b = s.hotelBookings.find(x => x.id === bookingId)
      if (!b || b.status !== 'pending') return s
      const now = nowIso()
      const section = b.sections[0]
      const next: Booking = {
        ...clone(b),
        proposal: {
          id: `proposal-${bookingId}`,
          kind: 'counter_offer',
          status: 'proposed',
          proposedAt: now,
          // Counter-offers last 48 hours; the voucher price is held (booking-state-machine section 7).
          expiresAt: addHours(now, CONFIG().counterOfferValidityHours),
          originalPriceHeld: true,
          options: [{ eventDate: newDate, hallId: section?.hallId ?? '', sessionId: section?.sessionId ?? '', quotedTotal: b.totals.voucherTotal, delta: { fils: 0, currency: 'KWD' } }],
        },
        events: [...b.events, { at: now, kind: 'overlay', from: 'pending', to: 'pending', actor: 'venue' }],
      }
      return { ...syncBooking(s, next, null), lastHotelAction: { kind: 'counter', bookingId, before: clone(b), beforeVoucher: null } }
    }),
  undoLastHotelAction: () =>
    set(s => {
      const a = s.lastHotelAction
      if (!a) return s
      return { ...syncBooking(s, a.before, a.beforeVoucher), lastHotelAction: null }
    }),
  commitHotelAction: () => set({ lastHotelAction: null }),
  redeemVoucher: (code, staffName = 'Reception') => {
    const s = get()
    const target = hotelVenueId()
    const v = s.vouchers.find(x => x.code === code.trim().toUpperCase())
    if (!v) return { ok: false, reason: 'unknown_code' }
    if (v.venueOrProviderId !== target) return { ok: false, reason: 'other_partner' }
    if (v.status === 'used') return { ok: false, reason: 'already_used', usedAt: v.usedAt }
    const b = v.bookingId ? (s.hotelBookings.find(x => x.id === v.bookingId) ?? s.clientBookings.find(x => x.id === v.bookingId)) : undefined
    if (!b || b.status !== 'confirmed' || v.status !== 'bound') return { ok: false, reason: 'not_confirmed' }
    const now = nowIso()
    const booking = transition(b, 'redeemed', now, 'venue', { redeemedAt: now, redeemedBy: staffName }, staffName)
    const voucher = usedVoucher(v, now, 'redeemed', staffName)
    set(prev => syncBooking(prev, booking, voucher))
    return { ok: true, voucher, booking }
  },
  cancelByPartner: (bookingId, reason = 'hall_unavailable') =>
    set(s => {
      const b = s.hotelBookings.find(x => x.id === bookingId)
      if (!b || !['approved', 'confirmed'].includes(b.status)) return s
      const now = nowIso()
      const v = s.vouchers.find(x => x.id === b.voucherId)
      const next = transition(b, 'cancelled', now, 'venue', { cancelledBy: 'venue', reasonCode: b.status === 'approved' ? 'approval_revoked' : reason })
      return syncBooking(s, next, v ? releasedVoucher(v, b.status === 'approved' ? 'approval_revoked' : 'venue_cancelled', now) : null)
    }),

  // ---------------------------------------------------------------- site visits and their group chat
  bookVisit: ({ venueId, slotStart, visitors, note = null }) => {
    const s = get()
    const user = s.user ?? storyUser()
    const venue = mock.getVenue(venueId)
    if (!venue || venue.type === 'governmental') return null
    const now = nowIso()
    const seq = s.visits.filter(v => v.id.startsWith('visit-proto-')).length + 1
    const id = `visit-proto-${seq}`
    const conversationId = `conv-${id}`
    // The three members: this client, the venue's visit representative and a Ghazal support representative (templates from the seed chats).
    const template = mock.groupThreads.find(t => t.venueId === venueId) ?? mock.groupThreads[0]
    const rep = template?.members.find(m => m.role === 'hotel_representative')
    const support = mock.groupThreads.flatMap(t => t.members).find(m => m.role === 'support')
    const me = { userId: user.id, role: 'client' as const, name: user.name, nameLatin: user.name, monogram: user.monogram, chip: { en: 'Client', ar: 'العميل' }, organisation: null }
    if (!rep || !support) return null
    const members = [me, { ...rep, organisation: venue.name }, support]
    const visit: VisitAppointment = {
      id,
      venueId,
      clientId: user.id,
      clientName: user.name,
      requestedAt: now,
      slotStart,
      slotEnd: engine.slotEnd(slotStart),
      visitors,
      note,
      status: 'requested',
      representativeId: rep.userId,
      conversationId,
      proposedSlotStart: null,
      arrivedAt: null,
      closedAt: null,
      history: [{ at: now, status: 'requested', actor: 'client', actorName: user.name }],
    }
    const conversation = {
      id: conversationId,
      kind: 'visit_group' as const,
      title: { en: `Site visit · ${venue.name.en}`, ar: `زيارة · ${venue.name.ar}` },
      subtitle: { en: 'Requested', ar: 'بانتظار التأكيد' },
      monogram: venue.name.ar.slice(0, 1),
      clientId: user.id,
      clientName: user.name,
      venueId,
      bookingId: null,
      plannerId: null,
      vendorId: null,
      pinned: false,
      unread: { client: 0, hotel: 1 },
      handledBy: rep.nameLatin,
      lastMessageAt: now,
      awaitingReplySince: null,
      usuallyRepliesHours: null,
      visitId: id,
      members,
      readOnlyFrom: null,
      archiveOn: null,
    }
    const opening: Message = {
      id: `msg-${id}-0`,
      conversationId,
      from: 'system',
      senderName: null,
      at: now,
      kind: 'system',
      text: {
        en: 'A group chat opened for your visit: you, the hotel and Ghazal support.',
        ar: 'فُتحت محادثة جماعية لزيارتكم: أنتم وممثل المكان ودعم غزل.',
      },
      origin: 'en',
      status: 'read',
      draft: false,
    }
    set({ visits: [visit, ...s.visits], visitChats: { ...s.visitChats, [id]: { conversation, messages: [opening] } } })
    return id
  },
  setVisitStatus: (visitId, status, actor = 'hotel_representative') =>
    set(s => {
      const v = s.visits.find(x => x.id === visitId)
      if (!v) return s
      const now = nowIso()
      const closes = status === 'cancelled' || status === 'declined'
      const next: VisitAppointment = {
        ...clone(v),
        status,
        arrivedAt: status === 'arrived' ? now : v.arrivedAt,
        closedAt: closes ? now : v.closedAt,
        history: [...v.history, { at: now, status, actor }],
      }
      const chat = s.visitChats[visitId]
      const lines: Partial<Record<VisitAppointment['status'], { en: string; ar: string }>> = {
        confirmed: { en: 'The hotel confirmed your visit.', ar: 'أكّد المكان موعد الزيارة.' },
        arrived: { en: 'Arrival confirmed by the hotel representative.', ar: 'أكّد ممثل الفندق وصولكم.' },
        completed: { en: 'The visit is complete.', ar: 'اكتملت الزيارة.' },
        cancelled: { en: 'This visit was cancelled. This chat is now read-only.', ar: 'تم إلغاء الزيارة. أصبحت المحادثة للقراءة فقط.' },
        declined: { en: 'The hotel could not offer this time. This chat is now read-only.', ar: 'تعذّر على المكان توفير هذا الموعد. أصبحت المحادثة للقراءة فقط.' },
      }
      const line = lines[status]
      const messages: Message[] | null =
        chat && line
          ? [...chat.messages, { id: `msg-${visitId}-${chat.messages.length}`, conversationId: chat.conversation.id, from: 'system', senderName: null, at: now, kind: 'system', text: line, origin: 'en', status: 'read', draft: false }]
          : null
      return {
        visits: s.visits.map(x => (x.id === visitId ? next : x)),
        visitChats: chat && messages ? { ...s.visitChats, [visitId]: { ...chat, messages } } : s.visitChats,
      }
    }),
  sendVisitMessage: (visitId, from, text) =>
    set(s => {
      const chat = s.visitChats[visitId]
      if (!chat || !text.trim()) return s
      const now = nowIso()
      const member = chat.conversation.members.find(m => m.role === (from === 'venue' ? 'hotel_representative' : from))
      const msg: Message = {
        id: `msg-${visitId}-${chat.messages.length}`,
        conversationId: chat.conversation.id,
        from,
        senderName: member?.nameLatin ?? null,
        at: now,
        kind: 'text',
        text: { en: text.trim(), ar: text.trim() },
        origin: s.language,
        status: 'sent',
        draft: false,
      }
      return { visitChats: { ...s.visitChats, [visitId]: { ...chat, messages: [...chat.messages, msg] } } }
    }),

  // ---------------------------------------------------------------- service-provider listings
  chooseListingPlan: (listingId, cycle) =>
    set(s => ({
      listings: s.listings.map(l => {
        if (l.id !== listingId) return l
        const exempt = mock.partnerFor(l.partnerAccountId)?.feeExempt === true
        return { ...clone(l), planCycle: cycle, billing: { ...l.billing, status: exempt ? 'exempt' : 'rates_pending' } }
      }),
    })),
  submitListing: listingId =>
    set(s => ({
      listings: s.listings.map(l => {
        if (l.id !== listingId || (l.status !== 'draft' && l.status !== 'rejected')) return l
        const now = nowIso()
        return {
          ...clone(l),
          // Never `active` here: a listing is published only by a moderator decision, never because it was paid for (ADR 0033 D8).
          status: 'pending_review' as const,
          submittedAt: now,
          rejection: null,
          history: [...l.history, { id: `rev-${l.id}-${l.history.length + 1}`, listingId: l.id, at: now, from: l.status, to: 'pending_review' as const, actor: 'provider' as const }],
        }
      }),
    })),
  moderateListing: (listingId, decision) =>
    set(s => ({
      listings: s.listings.map(l => {
        if (l.id !== listingId || l.status !== 'pending_review') return l
        const now = nowIso()
        const today = todayIso()
        const entry = (to: Listing['status'], extra: object = {}) => ({ id: `rev-${l.id}-${l.history.length + 1}`, listingId: l.id, at: now, from: l.status as Listing['status'], to, actor: 'moderator' as const, ...extra })
        if (decision.approve) {
          const plan = mock.adPlans.find(p => p.cycle === l.planCycle)
          return {
            ...clone(l),
            status: 'active' as const,
            decidedAt: now,
            startsOn: today,
            endsOn: plan ? engine.addDays(today, plan.periodDays) : null,
            rejection: null,
            history: [...l.history, entry('approved'), { ...entry('active'), from: 'approved' as const, actor: 'system' as const }],
          }
        }
        const rejection = { codes: decision.codes, note: { en: decision.note ?? '', ar: decision.note ?? '' } }
        return {
          ...clone(l),
          status: 'rejected' as const,
          decidedAt: now,
          rejection,
          planKeptUntil: l.planCycle ? engine.addDays(today, CONFIG().listingRejectedRetentionDays) : null,
          history: [...l.history, entry('rejected', { codes: decision.codes })],
        }
      }),
    })),

  // ---------------------------------------------------------------- notifications
  markNotificationRead: id => set(s => (s.readNotificationIds.includes(id) ? s : { readNotificationIds: [...s.readNotificationIds, id] })),
  markAllNotificationsRead: audience =>
    set(s => {
      const ids = safe(() => mock.notificationsFor(audience).map(n => n.id), [] as string[])
      return { readNotificationIds: [...new Set([...s.readNotificationIds, ...ids])] }
    }),

  // ---------------------------------------------------------------- helpers
  resetToStoryStart: () => {
    const { language } = get()
    set({ ...initial(), language })
  },
  loadStory: persona => {
    const { language } = get()
    if (persona === 'client') {
      const fav = storyFavourites()
      set({
        ...initial(),
        language,
        auth: 'signedIn',
        user: storyUser(),
        weddingProfile: storyWeddingProfile(),
        searchBrief: storyBrief(),
        favourites: fav,
        compareList: storyCompare(),
      })
    } else {
      set({ ...initial(), language, auth: 'signedIn' })
    }
  },
}))

/** Imperative access for code outside React (the player's story buttons, tests). */
export const prototypeStore = usePrototype
