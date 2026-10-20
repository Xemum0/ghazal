import type { Bilingual, Id, IsoDateTime } from './common.ts'

// ADR 0033 D9 and voucher-model section 11: a site visit is free and independent of the voucher; each visit creates ONE dedicated
// group chat of exactly three roles (client, hotel representative, Ghazal support representative from the call center).

export type VisitStatus =
  | 'requested'
  | 'confirmed'
  | 'reschedule_proposed'
  | 'arrived'
  | 'completed'
  | 'declined'
  | 'cancelled'
  | 'missed'

export interface VisitStatusChange {
  at: IsoDateTime
  status: VisitStatus
  actor: 'client' | 'hotel_representative' | 'support' | 'system'
  actorName?: string
}

export interface VisitAppointment {
  id: Id
  /** Hotels and halls only (A-10): never a governmental facility, never a provider. */
  venueId: Id
  clientId: Id
  /** Client display name as typed. */
  clientName: string
  requestedAt: IsoDateTime
  /** Start of the 30-minute arrival window, Kuwait time. */
  slotStart: IsoDateTime
  slotEnd: IsoDateTime
  visitors: number
  /** Optional note typed by the client, stored as typed. */
  note: string | null
  status: VisitStatus
  /** The assigned hotel representative (a staff user with the `visit:manage` permission). */
  representativeId: Id
  /** The dedicated group chat (conversation kind `visit_group`). */
  conversationId: Id
  /** Proposed other slot while `reschedule_proposed`. */
  proposedSlotStart: IsoDateTime | null
  arrivedAt: IsoDateTime | null
  /** When the group chat became read-only (24 h after the slot, or at once on cancel or decline). */
  closedAt: IsoDateTime | null
  history: VisitStatusChange[]
}

export type ThreadRole = 'client' | 'hotel_representative' | 'support'

/** One of the three members of a visit group chat; the chat header and the member sheet render the role chip beside the name. */
export interface ThreadMember {
  userId: Id
  role: ThreadRole
  /** Name as typed (first name and family name; monogram avatar, never a photograph). */
  name: string
  nameLatin: string
  monogram: string
  /** The role chip text: You / Hotel representative / Ghazal support. */
  chip: Bilingual
  /** Venue name for the hotel representative (the member sheet says who they work for); null otherwise. */
  organisation: Bilingual | null
}
