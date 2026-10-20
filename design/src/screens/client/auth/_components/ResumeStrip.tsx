// ResumeStrip: what is waiting on the other side of the sign-in (ADR 0007 D9, "never loses a draft"), told without a sentence.
// A request, voucher or visit shows the venue (cover thumb, serif name) and two facts, calendar + date and users + guests, with a
// quiet glyph at the end edge for the commit moment (paper plane, ticket, door). Every other reason (message, review, consultation,
// quote, shortlist) is one rose disk with its glyph and a one-word noun. No label, no caption: the strip is the context line.
// It reads the booking draft when there is one and the shared story otherwise (Reem's request to Aurelia, 14 Jan 2027, 350 guests).
import type { IconName } from '@gz/tokens'
import { FactChip, FactRow, Icon, Photo, imageSrc } from '../../../../system'
import { useFormat, useT, type MessageKey } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { usePrototype, type GateReason } from '../../../../shell/state'
import * as mock from '../../../../mock'
import './auth.css'

export const REASON: Record<GateReason, { icon: IconName; key: MessageKey<'client-auth'> }> = {
  'send-request': { icon: 'send', key: 'clientAuthReasonSendRequest' },
  voucher: { icon: 'ticket', key: 'clientAuthReasonVoucher' },
  visit: { icon: 'door', key: 'clientAuthReasonVisit' },
  chat: { icon: 'chat', key: 'clientAuthReasonChat' },
  review: { icon: 'star', key: 'clientAuthReasonReview' },
  planner: { icon: 'checklist', key: 'clientAuthReasonPlanner' },
  quote: { icon: 'receipt', key: 'clientAuthReasonQuote' },
  save: { icon: 'heart', key: 'clientAuthReasonSave' },
}

/** Reasons that carry a booking in flight (a venue, a date, a guest count). The others have nothing to preview. */
const VENUE_REASONS: ReadonlySet<GateReason> = new Set<GateReason>(['send-request', 'voucher', 'visit'])
export const hasResume = (reason: GateReason | null): boolean => reason !== null && VENUE_REASONS.has(reason)

function VenueStrip({ reason, compact }: { reason: GateReason; compact: boolean }) {
  const t = useT('client-auth')
  const f = useFormat()
  const { lang } = useLang()
  const draft = usePrototype(s => s.bookingDraft)
  const story = mock.heroBookingAs('pending')
  const venue = mock.getVenue(draft.venueId ?? story.venueId ?? '')
  if (!venue) return null
  const date = draft.eventDate ?? story.eventDate
  const guests = draft.guests ?? story.sections.reduce((n, s) => n + s.guests, 0)
  const cover = venue.cover
  const meta = REASON[reason]
  return (
    <section className={compact ? 'gza-resume gza-resume--compact' : 'gza-resume'} data-gz="ResumeStrip" data-reason={reason}>
      {cover ? (
        <span className="gza-resume__thumb">
          <Photo src={imageSrc(cover.file)} alt="" sizes="56px" />
        </span>
      ) : null}
      <div className="gza-resume__text">
        <p className="gza-resume__name gz-t-d1">{venue.name[lang]}</p>
        <FactRow>
          <FactChip icon="calendar" value={f.date(date, 'dayMonth')} label={t('clientAuthSharedDate')} size="sm" />
          <FactChip icon="users-three" value={f.integer(guests)} label={t('clientAuthSharedGuests')} size="sm" />
        </FactRow>
      </div>
      <span className="gza-resume__why">
        <Icon name={meta.icon} size="sm" tone="secondary" />
        <span className="gz-sr-only">{t(meta.key)}</span>
      </span>
    </section>
  )
}

export function ResumeStrip({ reason, compact = false }: { reason: GateReason | null; compact?: boolean }) {
  const t = useT('client-auth')
  if (!reason) return null
  if (hasResume(reason)) return <VenueStrip reason={reason} compact={compact} />
  const meta = REASON[reason]
  return (
    <section className="gza-resume gza-resume--compact" data-gz="ResumeStrip" data-reason={reason}>
      <span className="gza-resume__disk" aria-hidden="true">
        <Icon name={meta.icon} size="md" tone="secondary" />
      </span>
      <p className="gza-resume__noun gz-t-title">{t(meta.key)}</p>
    </section>
  )
}
