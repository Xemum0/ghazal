// Timeline (HL-VIST-02): what happened to the visit, oldest first, from its own history. A quiet vertical rail with ink dots (never gold:
// a timeline is not a verb); each row says what, who and when in absolute time (ADR 0011 D3).
import type { VisitAppointment, VisitStatusChange } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { Figures, UserText, useWords } from './bits'
import { firstName } from './model'
import './timeline.css'

export function Timeline({ visit, repName }: { visit: VisitAppointment; repName: string }) {
  const f = useFormat()
  const { t } = useWords()

  const what = (s: VisitStatusChange['status']) =>
    s === 'requested' ? t('hotelVisitsTlRequested')
    : s === 'confirmed' ? t('hotelVisitsTlConfirmed')
    : s === 'reschedule_proposed' ? t('hotelVisitsTlReschedule')
    : s === 'arrived' ? t('hotelVisitsTlArrived')
    : s === 'completed' ? t('hotelVisitsTlCompleted')
    : s === 'declined' ? t('hotelVisitsTlDeclined')
    : s === 'cancelled' ? t('hotelVisitsTlCancelled')
    : t('hotelVisitsTlMissed')

  const who = (h: VisitStatusChange): string =>
    h.actor === 'client' ? firstName(visit.clientName)
    : h.actor === 'support' ? t('hotelVisitsActorSupport')
    : h.actor === 'system' ? t('hotelVisitsActorSystem')
    : repName || (h.actorName ?? t('hotelVisitsActorHotel'))

  return (
    <ol className="hv-tl" data-gz="VisitTimeline">
      {visit.history.map((h, i) => (
        <li key={`${h.status}-${h.at}-${i}`} className="hv-tl__row" data-last={i === visit.history.length - 1 || undefined}>
          <span className="hv-tl__mark" aria-hidden="true">
            <span className="hv-tl__dot" />
            {i < visit.history.length - 1 ? <span className="hv-tl__rail" /> : null}
          </span>
          <span className="hv-tl__text">
            <span className="gz-t-title hv-tl__what">{what(h.status)}</span>
            <span className="gz-t-caption hv-tl__meta">
              <UserText role="caption">{who(h)}</UserText>
              <span aria-hidden="true"> · </span>
              <Figures text={f.dateTime(h.at, 'short')} />
            </span>
          </span>
        </li>
      ))}
    </ol>
  )
}
