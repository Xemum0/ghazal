// VisitRow (CL-VIST-04): one of the client's visits as a list row that opens its chat (ADR 0034): a 56 photograph (monogram when there is
// none), the venue name in the display face, the status pill (icon + one word) and the day and arrival time as icon + value. No sentence,
// no label; the full day and time are the accessible name. One 44+ target.
import type { VisitAppointment, VisitStatus } from '@gz/contracts'
import { getVenue } from '../../../../mock'
import { Avatar, Icon, Photo, StatusPill, imageSrc, type VisitState } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import { VisitFacts } from './VisitFacts'
import { useV } from './model'
import './visit-row.css'

const PILL: Record<VisitStatus, VisitState> = {
  requested: 'visit_requested',
  confirmed: 'visit_confirmed',
  reschedule_proposed: 'visit_reschedule',
  arrived: 'visit_arrived',
  completed: 'visit_completed',
  declined: 'visit_declined',
  cancelled: 'visit_cancelled',
  missed: 'visit_missed',
}

export function VisitRow({ visit, onOpen }: { visit: VisitAppointment; onOpen: () => void }) {
  const { bi, when } = useV()
  const { lang } = useLang()
  const venue = getVenue(visit.venueId)
  if (!venue) return null
  const name = bi(venue.name)
  return (
    <button type="button" className="gz-reset gzvt-row gz-press" onClick={onOpen} data-status={visit.status} aria-label={`${name}, ${when(visit.slotStart)}`}>
      <span className="gzvt-row__thumb">
        {venue.cover ? <Photo src={imageSrc(venue.cover.file)} alt="" sizes="72px" className="gzvt-row__photo" /> : <Avatar name={name} initial={lang === 'ar' ? venue.name.ar.slice(0, 1) : undefined} size="lg" />}
      </span>
      <span className="gzvt-row__text">
        <bdi dir="auto" className="gzvt-row__name gz-t-d1">
          {name}
        </bdi>
        <StatusPill status={PILL[visit.status]} />
        <VisitFacts slotStart={visit.slotStart} slotEnd={visit.slotEnd} compact startOnly />
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}
