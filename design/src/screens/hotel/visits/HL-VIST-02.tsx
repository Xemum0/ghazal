// HL-VIST-02 Visit. Requirement IDs: HA-VIS-02, HA-VIS-03, HA-VIS-04, HA-VIS-06.
// One site visit as the hotel representative sees it: who, when, how many, what they asked, the assigned representative, the three chat
// members and the visit's own timeline. The pinned bar changes with the status (Requested: Confirm, Propose another time, Decline;
// Confirmed: Open chat and, on the day, Mark arrived; Arrived: Complete visit; past: none). Visits are free and have no money. Decline
// asks for a reason and tells the client in the chat; confirming or proposing posts a system line there. The client shows a first name
// and a monogram; the phone is never shown unless the client shares it. Offline disables every decision in place.
// States: requested, confirmed, reschedule-proposed, day-of, arrived, completed, declined, cancelled, missed, loading, error, offline, role-limited
import { useFormat } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import { Avatar, Badge, Banner, Button, ErrorState, Icon, ListRow, ParticipantStrip, Screen, Skeleton, StatusPill, TopBar, useNav, type VisitState } from '../../../system'
import { DetailBar } from './_components/DetailBar'
import { Timeline } from './_components/Timeline'
import { Figures, Notice, Section, UserText, useWords } from './_components/bits'
import { useVisitActions } from './_components/actions'
import {
  HERO_REQUESTED,
  canSee,
  deriveVisit,
  firstName,
  isLead,
  isToday,
  roleOfParam,
  staffById,
  useProposedSlot,
  useRepresentativeId,
  useVisitById,
  useVisitConversation,
  variantOfState,
} from './_components/model'
import { useVisitsLocal } from './_components/store'
import './HL-VIST-02.css'

export const states = ['requested', 'confirmed', 'reschedule-proposed', 'day-of', 'arrived', 'completed', 'declined', 'cancelled', 'missed', 'loading', 'error', 'offline', 'role-limited']

const PILL = {
  requested: 'visit_requested',
  confirmed: 'visit_confirmed',
  reschedule_proposed: 'visit_reschedule',
  arrived: 'visit_arrived',
  completed: 'visit_completed',
  declined: 'visit_declined',
  cancelled: 'visit_cancelled',
  missed: 'visit_missed',
} as const satisfies Record<string, VisitState>

export default function VisitDetail() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { lang } = useLang()
  const { t, c } = useWords()
  const act = useVisitActions()
  const params = nav.params as { visitId?: string; role?: string }
  const role = roleOfParam(params.role)
  const stored = useVisitById(params.visitId ?? HERO_REQUESTED)
  const framed = state && state !== 'loading' && state !== 'error' && state !== 'offline' && state !== 'role-limited'
  const visit = framed ? deriveVisit(variantOfState(state, 'requested')) : (stored ?? deriveVisit('requested'))
  const offline = state === 'offline'
  const limited = state === 'role-limited'
  const { conversation } = useVisitConversation(visit)
  const proposed = useProposedSlot(visit)
  const repId = useRepresentativeId(visit)
  const decline = useVisitsLocal(s => s.declines[visit.id])

  const name = firstName(visit.clientName)
  const rep = staffById(repId)
  const repName = rep ? (lang === 'ar' ? rep.name : rep.nameLatin) : ''
  const lead = isLead(role)
  const canReply = canSee(role) && !limited
  const today = isToday(visit)

  const title = <Figures text={t('hotelVisitsDetailTitle', { when: f.dateTime(visit.slotStart, 'short') })} />
  const top = <TopBar title={title} />

  // ---- the line under the date: what state the visit is in and what to do next
  const note = (() => {
    switch (visit.status) {
      case 'requested':
        return { icon: 'clock' as const, text: t('hotelVisitsNoteRequested', { name }) }
      case 'reschedule_proposed':
        return { icon: 'calendar-dots' as const, text: t('hotelVisitsNoteReschedule', { name, when: proposed ? f.dateTime(proposed, 'short') : '' }) }
      case 'confirmed':
        return today
          ? { icon: 'pin' as const, text: t('hotelVisitsNoteDayOf', { name, time: f.time(visit.slotStart) }) }
          : { icon: 'calendar-check' as const, text: t('hotelVisitsNoteConfirmed', { name }) }
      case 'arrived':
        return { icon: 'check-circle' as const, text: t('hotelVisitsNoteArrived', { name, time: f.time(visit.arrivedAt ?? visit.slotStart) }) }
      case 'completed':
        return { icon: 'check-double' as const, text: t('hotelVisitsNoteCompleted') }
      case 'declined':
        return {
          icon: 'calendar-x' as const,
          text: decline
            ? t('hotelVisitsNoteDeclinedReason', { name, reason: t(decline.reason === 'unavailable' ? 'hotelVisitsReasonUnavailable' : decline.reason === 'closed' ? 'hotelVisitsReasonClosed' : 'hotelVisitsReasonOther') })
            : t('hotelVisitsNoteDeclined', { name }),
        }
      case 'cancelled':
        return { icon: 'close' as const, text: t('hotelVisitsNoteCancelled', { name }) }
      case 'missed':
        return { icon: 'user-minus' as const, text: t('hotelVisitsNoteMissed') }
    }
  })()

  const chatOpen = visit.status === 'confirmed' || visit.status === 'reschedule_proposed' || visit.status === 'arrived'
  const barHasChat = canReply && chatOpen
  const bar = state === 'loading' || state === 'error' ? undefined : <DetailBar visit={visit} role={role} canReply={canReply} offline={offline} />

  let body
  if (!canSee(role)) {
    body = <ErrorState kind="no-access" title={t('hotelVisitsNoAccessTitle')} body={t('hotelVisitsNoAccessBody')} />
  } else if (state === 'loading') {
    body = (
      <div className="hv-detail__skel" aria-busy="true" aria-label={c('commonStateLoading')}>
        <Skeleton variant="block" blockSize={112} />
        <Skeleton variant="block" blockSize={72} />
        <Skeleton variant="block" blockSize={160} />
      </div>
    )
  } else if (state === 'error') {
    body = <ErrorState kind="load" title={t('hotelVisitsDetailErrorTitle')} body={t('hotelVisitsErrorBody')} onRetry={() => nav.replace('HL-VIST-02', params)} />
  } else {
    body = (
      <>
        <header className="hv-hero hv-pad" data-gz="VisitHero">
          <div className="hv-hero__top">
            <StatusPill status={PILL[visit.status]} audience="hotel" />
            {today && visit.status === 'confirmed' ? (
              <Badge variant="quiet" bead={false}>
                {f.relativeDay(visit.slotStart)}
              </Badge>
            ) : null}
          </div>
          <h1 className="gz-t-ui-xl hv-hero__date">
            <Figures text={f.date(visit.slotStart, 'full')} />
          </h1>
          <p className="hv-hero__facts gz-t-fig-body">
            <span className="hv-hero__fact">
              <Icon name="clock" size="sm" tone="secondary" />
              <bdi dir="ltr">{f.timeRange(visit.slotStart, visit.slotEnd)}</bdi>
            </span>
            <span className="hv-hero__fact gz-t-body">
              <Icon name="guests" size="sm" tone="secondary" />
              {t('hotelVisitsVisitors', { count: visit.visitors })}
            </span>
          </p>
        </header>

        <div className="hv-pad hv-detail__notes">
          {limited && visit.status === 'requested' ? null : (
            <Notice icon={note.icon} tone={visit.status === 'requested' || visit.status === 'missed' ? 'rose' : 'quiet'} role="status">
              {note.text}
            </Notice>
          )}
          {limited ? <Notice icon="lock">{t('hotelVisitsLimitedNote', { name: repName })}</Notice> : null}
        </div>

        <Section title={t('hotelVisitsSecClient')}>
          <div className="hv-client">
            <Avatar name={name} initial={lang === 'ar' ? name.slice(0, 1) : undefined} size="md" voice="sans" />
            <span className="hv-client__text">
              <UserText role="ui-title">{name}</UserText>
            </span>
          </div>
        </Section>

        <Section title={t('hotelVisitsSecVisit')}>
          <dl className="hv-facts">
            <div className="hv-facts__row">
              <dt className="gz-t-body-s">{t('hotelVisitsFactRequested')}</dt>
              <dd className="gz-t-body">
                <Figures text={f.dateTime(visit.requestedAt, 'short')} />
              </dd>
            </div>
            {visit.status === 'reschedule_proposed' && proposed ? (
              <div className="hv-facts__row">
                <dt className="gz-t-body-s">{t('hotelVisitsFactProposed')}</dt>
                <dd className="gz-t-body">
                  <Figures text={f.dateTime(proposed, 'short')} />
                </dd>
              </div>
            ) : null}
          </dl>
        </Section>

        {visit.note ? (
          <Section title={t('hotelVisitsSecNote')}>
            <blockquote className="hv-quote">
              <UserText role="body">{visit.note}</UserText>
            </blockquote>
          </Section>
        ) : null}

        <Section title={t('hotelVisitsSecRep')}>
          <div className="hv-rep">
            <ListRow
              flush
              last
              leading={rep ? <Avatar name={repName} initial={lang === 'ar' ? rep.monogram : undefined} size="sm" voice="sans" /> : undefined}
              title={<UserText role="title">{repName}</UserText>}
              subtitle={rep ? rep.roleLabel[lang] : undefined}
              chevron={lead && !limited && !offline}
              onClick={lead && !limited && !offline ? () => act.assign(visit, repId) : undefined}
            />
          </div>
        </Section>

        {conversation?.members ? (
          <Section title={t('hotelVisitsSecChat')}>
            <ParticipantStrip members={conversation.members} onOpen={() => act.members(conversation.members ?? [])} />
            {barHasChat ? null : (
              <Button variant="secondary" size="md" fullWidth iconStart="chat" onClick={() => act.chat(visit)}>
                {t('hotelVisitsOpenChat')}
              </Button>
            )}
          </Section>
        ) : null}

        <Section title={t('hotelVisitsSecTimeline')}>
          <Timeline visit={visit} repName={repName} />
        </Section>
      </>
    )
  }

  return (
    <Screen top={top} bottom={bar} bodyClassName="hv-detail">
      {offline ? <Banner tone="offline">{t('hotelVisitsOfflineBannerShort')}</Banner> : null}
      {body}
    </Screen>
  )
}
