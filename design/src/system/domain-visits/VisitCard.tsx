// VisitCard (CL-VIST visits list, HL-VIST queue and detail header; ADR 0033 D9): one site visit as a quiet card. Status pill, the date and
// the 30-minute arrival window in the figures voice, who it is with, how many people come, and one action into the group chat.
// The client sees the venue; the partner sees the client and the party size. A governmental facility and a provider never have a visit.
import type { VisitAppointment, VisitStatus } from '@gz/contracts'
import { getVenue, groupThreadFor } from '../../mock'
import { useFormat } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Button, Icon, StatusPill, type VisitState } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi } from '../domain-client/bits'
import { defineWords, p } from '../domain-client/copy'
import './visit-card.css'

const useW = defineWords({
  with: p('With {name}', 'مع {name}'),
  party: p('{n}', '{n}'),
  chat: p('Open group chat', 'فتح المحادثة الجماعية'),
  entrance: p('Arrival window', 'وقت الوصول'),
  closed: p('Chat is read-only', 'المحادثة للقراءة فقط'),
})

const STATE: Record<VisitStatus, VisitState> = {
  requested: 'visit_requested',
  confirmed: 'visit_confirmed',
  reschedule_proposed: 'visit_reschedule',
  arrived: 'visit_arrived',
  completed: 'visit_completed',
  declined: 'visit_declined',
  cancelled: 'visit_cancelled',
  missed: 'visit_missed',
}

export type VisitCardProps = {
  visit: VisitAppointment
  /** `client` shows the venue; `hotel` shows the client and the party size. */
  audience?: 'client' | 'hotel'
  onOpenChat?: () => void
  /** Opens the visit (the card body becomes one 44+ target). */
  onOpen?: () => void
  className?: string
}

export function VisitCard({ visit: v, audience = 'client', onOpenChat, onOpen, className }: VisitCardProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  const venue = getVenue(v.venueId)
  const rep = groupThreadFor(v.id, audience)?.thread.members?.find(m => m.role === 'hotel_representative')
  const plain = (s: string) => s.replace(/[‎‏⁦-⁩]/g, '')
  const title = audience === 'client' ? (venue ? bi(venue.name) : '') : v.clientName
  const readOnly = v.status === 'completed' || v.status === 'cancelled' || v.status === 'declined' || v.status === 'missed'

  const head = (
    <>
      <span className="gz-visit__top">
        <StatusPill status={STATE[v.status]} />
        <span className="gz-visit__party gz-t-caption">
          <Icon name="guests" size="xs" tone="secondary" />
          <Figures text={plain(f.guests(v.visitors))} />
        </span>
      </span>
      <span className="gz-visit__when gz-t-ui-title">
        <Figures text={f.date(v.slotStart, 'full')} />
      </span>
      <span className="gz-visit__window gz-t-fig-body-s">
        <Icon name="clock" size="xs" tone="secondary" />
        <bdi dir="ltr">{f.timeRange(v.slotStart, v.slotEnd)}</bdi>
      </span>
      <span className="gz-visit__who gz-t-body-s" dir="auto">
        {title}
      </span>
      {rep && audience === 'client' ? (
        <span className="gz-visit__rep gz-t-caption">{w('with', { name: lang === 'ar' ? rep.name : rep.nameLatin })}</span>
      ) : null}
    </>
  )
  return (
    <article data-gz="VisitCard" data-status={v.status} data-audience={audience} className={cx('gz-visit', className)}>
      {onOpen ? (
        <button type="button" className="gz-reset gz-visit__body gz-press" onClick={onOpen}>
          {head}
        </button>
      ) : (
        <div className="gz-visit__body">{head}</div>
      )}
      {onOpenChat ? (
        <Button variant="secondary" iconStart="chat" fullWidth onClick={onOpenChat}>
          {w('chat')}
        </Button>
      ) : null}
      {readOnly && onOpenChat ? <p className="gz-visit__ro gz-t-caption">{w('closed')}</p> : null}
    </article>
  )
}
