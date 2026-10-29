// The sections of Booking detail (HL-BOOK-03, ADR 0034), in the order of the inventory: header (status, voucher chip, date, the deadline that
// matters as a glyph and a figure), the Booking Thread as five glyph knots, notices, the outcome of a closed request, special requests, the
// client, the counter-offer when one is out, the event (hall photograph, time, section, guests, package), the price at the voucher
// (one big figure, the standard struck, the saving), the voucher panel (once it is confirmed or used), the actions and the history. One
// screen, one set of sections; the status only changes which of them show. There is no payment, cash, invoice or payout section: the event is
// paid to the venue off-app (ADR 0033), so the screen never shows a payment status; the one sentence about it is behind an info glyph.
import { useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { engine, getHall, getPackage, getVoucher, meta, PROTOTYPE_TODAY, type Booking } from '../../../../mock'
import { useFormat, useT, type MessageKey } from '../../../../i18n'
import { usePrototype } from '../../../../shell/state'
import {
  Avatar,
  Button,
  FactChip,
  FactRow,
  Icon,
  IconButton,
  IconListRow,
  IconProgress,
  InfoButton,
  InfoSheet,
  Photo,
  Price,
  StatusPill,
  VoucherChip,
  imageSrc,
  threadModel,
  useNav,
  type IconProgressStep,
  type StatusKey,
} from '../../../../system'
import { Fx, Figures, SECTION_ICON, UserText, canChange, canContact, canDecide, canRedeem, minutesBetween, sessionIcon, sessionRange, useBi, useDayCount, useDays, useDur, useDurLead, useHours, useStaffName } from './bits'
import { useBookingActions, refOf } from './actions'
import { Block, Copyable, Line, Lines, Note, Panel } from './DetailParts'
import { AUDIENCE_KEY, DECLINE_ICON, DECLINE_KEY, silenceHours, wasConfirmed } from './facts'
import { QuietMoney, StruckMoney } from './Money'
import { StateStrip } from './States'
import type { DetailModel } from './detail'
import './detail-sections.css'

// ---------------------------------------------------------------- header

export function pillFor(b: Booking): { status: StatusKey } {
  if (b.status === 'expired') return { status: b.expiredReason === 'client_no_confirmation' ? 'lapsed' : 'missed' }
  return { status: b.status }
}

/** The tone of the voucher chip beside a status: attached to a live request, or quiet once it is used or released. */
export const chipToneOf = (status: string | undefined): 'bound' | 'quiet' => (status === 'bound' ? 'bound' : 'quiet')

/** Share of the 24 h confirm window still left (0..1): the thread bar depletes toward the start, and it never turns red (calm by design). */
function confirmShare(minutesLeft: number): number {
  return Math.min(1, Math.max(0, minutesLeft / (meta.config.confirmWindowHours * 60)))
}

/** A glyph and a figure: the one fact the header carries (time left, days to go, the day it was redeemed). */
function Left({ icon, state = 'neutral', label, children }: { icon: IconName; state?: 'neutral' | 'gold' | 'danger' | 'success'; label: string; children: ReactNode }) {
  return (
    <span className="hbk-left" data-state={state}>
      <Icon name={icon} size="md" tone={state === 'gold' ? 'accent' : state === 'danger' ? 'danger' : state === 'success' ? 'success' : 'secondary'} />
      <span className="gz-sr-only">{label}</span>
      <span className="hbk-left__figure gz-t-fig-title">{children}</span>
    </span>
  )
}

export function HeaderBlock({ m }: { m: DetailModel }) {
  const { booking: b, voucher } = m
  const f = useFormat()
  const t = useT('hotel-bookings')
  const c = useT('common')
  const days = useDays()
  const dur = useDur()
  const lead = useDurLead()
  const dayCount = useDayCount()
  const urgent = b.status === 'pending' && engine.diffDays(meta.today, b.eventDate) <= meta.config.urgentLeadDays
  const pill = pillFor(b)

  let fact: ReactNode = null
  let bar: ReactNode = null
  if (b.status === 'pending' && b.proposal) {
    const left = lead(minutesBetween(meta.now, b.proposal.expiresAt))
    fact = (
      <Left icon="hourglass" state="gold" label={t('hotelBookingsAwaitingCouple')}>
        <Fx text={left.visual} />
      </Left>
    )
  } else if (b.status === 'pending' && b.respondBy) {
    const sla = engine.slaReading(b.createdAt, b.respondBy, meta.now, { goldPct: meta.config.slaGoldPct, dangerPct: meta.config.slaDangerPct })
    const left = dur(sla.minutesLeft)
    const share = Math.min(1, Math.max(0, 1 - sla.elapsed))
    bar = (
      <div className={`hbk-sla hbk-sla--${sla.state}`} aria-hidden="true">
        <span className="hbk-sla__fill gz-thread-draw" style={{ flexGrow: share }} />
        <span style={{ flexGrow: 1 - share }} />
      </div>
    )
    fact = (
      <Left icon="timer" state={sla.state === 'danger' || sla.state === 'expired' ? 'danger' : sla.state === 'gold' ? 'gold' : 'neutral'} label={t('hotelBookingsReplyLeft', { time: left.spoken })}>
        <Fx text={left.visual} />
      </Left>
    )
  } else if (b.status === 'approved' && b.confirmBy) {
    const minutes = minutesBetween(meta.now, b.confirmBy)
    const left = dur(minutes)
    const share = confirmShare(minutes)
    bar = (
      <div className="hbk-sla hbk-sla--gold" aria-hidden="true">
        <span className="hbk-sla__fill gz-thread-draw" style={{ flexGrow: share }} />
        <span style={{ flexGrow: 1 - share }} />
      </div>
    )
    fact = (
      <Left icon="hourglass" state="gold" label={t('hotelBookingsConfirmLeft', { time: left.spoken })}>
        <Fx text={left.visual} />
      </Left>
    )
  } else if (b.status === 'confirmed') {
    const n = f.daysUntil(b.eventDate)
    fact =
      n <= 0 ? (
        <Left icon="calendar-check" label={t('hotelBookingsEventToday')}>
          <span className="gz-t-ui-title">{c('commonLabelToday')}</span>
        </Left>
      ) : (
        <Left icon="calendar-check" label={t('hotelBookingsDaysToGo')}>
          <Fx text={dayCount(n)} />
        </Left>
      )
  } else if (b.status === 'redeemed' && b.redeemedAt) {
    fact = (
      <Left icon="check-circle" state="success" label={t('hotelBookingsRedeemedPlain')}>
        <Fx text={days.dm(b.redeemedAt)} />
      </Left>
    )
  }

  return (
    <header className="hbk-header" data-gz="BookingHeader">
      {bar}
      <div className="hbk-header__body">
        <div className="hbk-header__pills">
          <StatusPill status={pill.status} audience="hotel" />
          {urgent ? <StatusPill status="urgent" /> : null}
          {voucher ? <VoucherChip code={voucher.code} tone={chipToneOf(voucher.status)} /> : null}
        </div>
        <h2 className="hbk-header__date gz-t-ui-xl">
          <Figures text={f.date(b.eventDate, 'short')} />
        </h2>
        {fact}
      </div>
    </header>
  )
}

// ---------------------------------------------------------------- the Booking Thread as five glyph knots

const KNOT_ICON = { voucher: 'ticket', request: 'send', approval: 'verified', confirmation: 'calendar-check', redemption: 'qr-code' } as const satisfies Record<string, IconName>
const KNOT_KEY = {
  voucher: 'hotelBookingsKnotVoucher',
  request: 'hotelBookingsKnotRequest',
  approval: 'hotelBookingsKnotApproval',
  confirmation: 'hotelBookingsKnotConfirmed',
  redemption: 'hotelBookingsKnotRedeemed',
} as const satisfies Record<string, MessageKey<'hotel-bookings'>>

/** The five knots of ADR 0033, a glyph each, one word under the active one; the times of the tied knots are in the history. */
export function ThreadBlock({ b }: { b: Booking }) {
  const t = useT('hotel-bookings')
  const f = useFormat()
  const model = threadModel({ status: b.status, recorded: b.thread, voucherAt: getVoucher(b.voucherId)?.purchasedAt ?? null, expiredReason: b.expiredReason })
  const steps: IconProgressStep[] = model.map(k => ({
    key: k.key,
    icon: KNOT_ICON[k.key],
    label: t(KNOT_KEY[k.key]),
    state: k.state,
    ended: k.ended ? { icon: k.ended.icon, tone: k.ended.tone } : undefined,
  }))
  const at = Math.max(0, model.findIndex(k => k.state === 'now' || k.state === 'ended'))
  const current = model[at]
  return (
    <div className="hbk-thread" data-gz="BookingThread">
      <IconProgress
        steps={steps}
        label={t('hotelBookingsProgressLabel')}
        describe={current ? `${t(KNOT_KEY[current.key])}, ${t('hotelBookingsStepOf', { n: f.integer(at + 1), total: f.integer(model.length) })}` : undefined}
        draw="inview"
      />
    </div>
  )
}

// ---------------------------------------------------------------- notices

export function Notices({ m, others }: { m: DetailModel; others: number }) {
  const { booking: b, lock, held, params } = m
  const t = useT('hotel-bookings')
  const act = useBookingActions()
  const nav = useNav()
  const f = useFormat()
  const notes: ReactNode[] = []
  // The pinned bar already says why a decision is disabled (offline, date held) beside the buttons; the body says it again only when no bar is shown.
  const barSaysWhy = (b.status === 'pending' && !b.proposal && canDecide(m.role)) || (b.status === 'confirmed' && canRedeem(m.role))
  if (lock === 'offline' && !barSaysWhy) {
    notes.push(
      <Note key="offline" icon="offline" tone="secondary">
        <Figures text={t('hotelBookingsOfflineBanner', { time: f.time(f.now()) })} />
      </Note>,
    )
  }
  if (b.overlays.issueReported) {
    notes.push(
      <Note
        key="issue"
        icon="flag"
        tone="danger"
        action={
          <Button variant="tertiary" onClick={act.support}>
            {t('hotelBookingsIssueLink')}
          </Button>
        }
      >
        {t('hotelBookingsIssueReported')}
      </Note>,
    )
  }
  if (b.status === 'pending' && !b.proposal) {
    if (held && !barSaysWhy) {
      notes.push(
        <Note key="held" icon="lock" tone="accent">
          {t('hotelBookingsHeldLine')}
        </Note>,
      )
    } else if (others > 0) {
      notes.push(
        <Note key="others" icon="compare" tone="accent">
          <span className="gz-sr-only">{t('hotelBookingsOthersSameDate', { count: others })}</span>
          <span className="gz-t-fig-body-s" aria-hidden="true">
            +{f.integer(others)}
          </span>
        </Note>,
      )
    }
  }
  if (params.offerPrompt && (b.status === 'cancelled' || b.status === 'declined' || b.status === 'expired')) {
    notes.push(
      <Note
        key="window"
        icon="offer"
        tone="accent"
        action={
          <Button variant="tertiary" onClick={() => nav.push('HL-GROW-02')}>
            {t('hotelBookingsCreateWindow')}
          </Button>
        }
      >
        {t('hotelBookingsDateFreeAgain')}
      </Note>,
    )
  }
  if (lock === 'role-limited') {
    notes.push(
      <Note key="role" icon="lock" tone="secondary">
        {t('hotelBookingsViewOnly')}
      </Note>,
    )
  }
  if (notes.length === 0) return null
  return <div className="hbk-notices">{notes}</div>
}

// ---------------------------------------------------------------- special requests

export function SpecialRequests({ text }: { text: string }) {
  const t = useT('hotel-bookings')
  const [open, setOpen] = useState(false)
  const long = text.length > 60
  return (
    <Panel tone="tint" className="hbk-special">
      <div className="hbk-special__row">
        <Icon name="notes" size="sm" tone="accent" />
        <span className="gz-sr-only">{t('hotelBookingsSpecialRequests')}</span>
        <UserText role="body" className={open ? 'hbk-special__text' : 'hbk-special__text gz-clamp-2'}>
          {text}
        </UserText>
        {long ? (
          <IconButton icon={open ? 'chevron-up' : 'chevron-down'} iconSize="sm" label={open ? t('hotelBookingsShowLess') : t('hotelBookingsShowMore')} aria-expanded={open} onClick={() => setOpen(v => !v)} />
        ) : null}
      </div>
    </Panel>
  )
}

// ---------------------------------------------------------------- client

export function ClientBlock({ m }: { m: DetailModel }) {
  const { booking: b, role } = m
  const t = useT('hotel-bookings')
  const act = useBookingActions()
  const ref = refOf(b)
  const contact = canContact(role)
  return (
    <Panel tone="paper" className="hbk-client">
      <div className="hbk-client__row">
        <Avatar name={b.clientName} size="md" voice="sans" />
        <div className="hbk-client__who">
          <UserText role="title" className="hbk-client__name gz-clamp-2">
            {b.clientName}
          </UserText>
          <span className="hbk-client__marks">
            {b.verifiedPhone ? (
              <span className="hbk-client__mark">
                <Icon name="verified" size="xs" tone="success" />
                <span className="gz-sr-only">{t('hotelBookingsVerified')}</span>
              </span>
            ) : null}
            {b.firstBooking ? (
              <span className="hbk-client__mark">
                <Icon name="sparkle" size="xs" tone="accent" />
                <span className="gz-sr-only">{t('hotelBookingsFirstBooking')}</span>
              </span>
            ) : null}
          </span>
        </div>
        {contact ? (
          <div className="hbk-client__contact">
            <IconButton icon="chat" label={t('hotelBookingsMessageName', { name: b.clientName })} variant="outline" onClick={() => act.chat(ref)} />
            {b.contact.shared ? <IconButton icon="phone" label={t('hotelBookingsCallName', { name: b.clientName })} variant="outline" onClick={() => act.call(ref, role)} /> : null}
          </div>
        ) : null}
      </div>
    </Panel>
  )
}

// ---------------------------------------------------------------- event and package

/** The hall photograph (an empty room, never a person) or its glyph when the hall has no photo yet. */
function HallThumb({ hallId }: { hallId: string }) {
  const bi = useBi()
  const found = getHall(hallId)
  const cover = found?.hall.cover
  return (
    <span className="hbk-thumb" aria-hidden={cover ? undefined : true}>
      {cover ? <Photo src={imageSrc(cover.file)} alt={bi(cover.alt)} className="hbk-thumb__photo" sizes="72px" /> : <Icon name="hall" size="md" tone="secondary" />}
    </span>
  )
}

export function EventBlock({ b }: { b: Booking }) {
  const f = useFormat()
  const t = useT('hotel-bookings')
  const bi = useBi()
  const two = b.sections.length > 1
  if (b.sections.length === 0) {
    return (
      <Panel tone="paper">
        <Lines>
          <Line icon="calendar" label={t('hotelBookingsRowServiceDate')}>
            <Figures text={f.date(b.eventDate, 'short')} />
          </Line>
        </Lines>
      </Panel>
    )
  }
  return (
    <Panel tone="paper" className="hbk-event">
      <Lines label={t('hotelBookingsEventTitle')}>
        {b.sections.map((s, i) => {
          const found = getHall(s.hallId)
          return (
            <Line
              key={i}
              lead={<HallThumb hallId={s.hallId} />}
              facts={
                <FactRow label={t('hotelBookingsFactsLabel')}>
                  <FactChip icon={sessionIcon(s.start)} label={t('hotelBookingsFactTime')} value={<Fx text={sessionRange(f, b.eventDate, s.start, s.end)} />} />
                  <FactChip icon={SECTION_ICON[s.audience]} label={t(AUDIENCE_KEY[s.audience])} />
                  <FactChip icon="users-three" label={t('hotelBookingsFactGuests')} value={f.integer(s.guests)} />
                  {s.billableGuests !== s.guests ? <FactChip icon="receipt" tone="muted" label={t('hotelBookingsBillable', { count: s.billableGuests })} value={f.integer(s.billableGuests)} /> : null}
                </FactRow>
              }
            >
              {found ? bi(found.hall.name) : ''}
            </Line>
          )
        })}
        {b.sections.map((s, i) => {
          const pkg = getPackage(s.packageId)
          return (
            <Line key={`p${i}`} icon="package" label={two ? t(AUDIENCE_KEY[s.audience]) : t('hotelBookingsRowPackage')}>
              {pkg ? bi(pkg.name) : ''}
            </Line>
          )
        })}
      </Lines>
    </Panel>
  )
}

// ---------------------------------------------------------------- price

/** The price at the voucher: what the venue charges the client directly. The standard price sits beside it, struck, with the client's saving. */
export function PriceBlock({ m }: { m: DetailModel }) {
  const { booking: b } = m
  const f = useFormat()
  const t = useT('hotel-bookings')
  const c = useT('common')
  const bi = useBi()
  const { voucherTotal, standardTotal, voucherServiceCharge, savings } = b.totals
  const saves = standardTotal.fils > voucherTotal.fils
  // Venue extras are not shown (CA-SVC-19, ADR 0038): the breakdown lists the packages only.
  const lines = b.lines.filter(l => l.kind !== 'extra')
  const itemised = lines.length > 1 || voucherServiceCharge.fils > 0
  return (
    <Panel tone="paper" className="hbk-price">
      <div className="hbk-price__head">
        <span className="hbk-price__glyph" aria-hidden="true">
          <Icon name="ticket" size="sm" tone="accent" />
        </span>
        <span className="gz-sr-only">{c('commonVoucherPrice')}</span>
        <Copyable value={f.money(voucherTotal.fils, { mode: 'exact' })}>
          <Price fils={voucherTotal.fils} mode="exact" size="total" />
        </Copyable>
        <InfoButton title={t('hotelBookingsInfoPriceTitle')} className="hbk-price__info">
          {itemised ? (
            <Lines label={t('hotelBookingsPriceTitle')}>
              {lines.map((l, i) => (
                <Line key={i} trailing={<QuietMoney fils={l.amount.fils} mode="exact" />}>
                  {bi(l.name)}
                </Line>
              ))}
              {voucherServiceCharge.fils > 0 ? <Line trailing={<QuietMoney fils={voucherServiceCharge.fils} mode="exact" />}>{c('commonMoneyServiceCharge')}</Line> : null}
            </Lines>
          ) : null}
          <p>{t('hotelBookingsDirectNote')}</p>
        </InfoButton>
      </div>
      {saves ? (
        <div className="hbk-price__compare">
          <span className="hbk-price__was">
            <Icon name="offer" size="xs" tone="secondary" />
            <StruckMoney fils={standardTotal.fils} mode="exact" label={c('commonStandardPrice')} />
          </span>
          <span className="hbk-price__save">
            <Icon name="trend-down" size="xs" tone="success" />
            <QuietMoney fils={savings.fils} mode="exact" label={t('hotelBookingsClientSaves')} />
          </span>
        </div>
      ) : null}
    </Panel>
  )
}

// ---------------------------------------------------------------- the voucher panel

const STATE_LABEL = {
  bound: 'hotelBookingsVoucherBound',
  used: 'hotelBookingsVoucherRedeemed',
  active: 'hotelBookingsVoucherReturned',
  expired: 'hotelBookingsVoucherExpired',
  forfeited: 'hotelBookingsVoucherNotValid',
  credit_issued: 'hotelBookingsVoucherNotValid',
  unpaid: 'hotelBookingsVoucherBound',
} as const

/** A voucher still waiting on the request shows as the chip in the header; the panel is for a voucher that is confirmed, used or released. */
export function voucherVisible(m: DetailModel): boolean {
  const { booking: b, voucher } = m
  if (!voucher) return false
  return voucher.status === 'used' || voucher.status === 'active' || voucher.status === 'expired' || voucher.status === 'forfeited' || voucher.status === 'credit_issued' || b.status === 'confirmed'
}

export function VoucherBlock({ m }: { m: DetailModel }) {
  const { booking: b, voucher } = m
  const t = useT('hotel-bookings')
  const c = useT('common')
  const f = useFormat()
  const days = useDays()
  const staff = useStaffName()
  if (!voucher || !voucherVisible(m)) return null
  // The panel is on the page of the request it is bound to, so "In request" would only repeat the page: a state word shows once the voucher changed.
  const changed = voucher.status !== 'bound' && voucher.status !== 'unpaid'
  const last4 = voucher.code.slice(-4)
  const redeemedBy = voucher.redeemedBy ?? b.redeemedBy
  const redeemedAt = voucher.usedAt ?? b.redeemedAt
  return (
    <Block label={c('commonVoucher')} id="hbk-voucher">
      <Panel tone="paper" className="hbk-voucher">
        <div className="hbk-voucher__head">
          <span className="hbk-voucher__disk" aria-hidden="true">
            <Icon name="ticket" size="sm" tone="accent" />
          </span>
          <span className="hbk-voucher__id">
            <span className="gz-sr-only">{c('commonVoucherCode')}</span>
            <span className="hbk-voucher__code gz-t-fig-title">
              <bdi dir="ltr">{`GV-····-${last4}`}</bdi>
            </span>
          </span>
          {changed ? <StatusPill status={`voucher_${voucher.status}` as StatusKey} label={t(STATE_LABEL[voucher.status])} /> : null}
        </div>
        {voucher.status === 'used' && redeemedAt ? (
          <FactRow label={t('hotelBookingsVoucherRedeemed')}>
            <FactChip icon="user" label={t('hotelBookingsRowRedeemedBy')} value={<UserText role="body-s" text={staff(redeemedBy ?? '') || t('hotelBookingsActorVenue')}>{staff(redeemedBy ?? '') || t('hotelBookingsActorVenue')}</UserText>} />
            <FactChip icon="calendar" label={t('hotelBookingsRowDate')} value={<Fx text={days.dm(redeemedAt)} />} />
            <FactChip icon="clock" label={t('hotelBookingsRowTime')} value={<Fx text={f.time(redeemedAt)} />} />
          </FactRow>
        ) : null}
      </Panel>
    </Block>
  )
}

// ---------------------------------------------------------------- proposal out (counter-offer)

export function ProposalBlock({ b }: { b: Booking }) {
  const f = useFormat()
  const t = useT('hotel-bookings')
  const bi = useBi()
  const days = useDays()
  const p = b.proposal
  if (!p) return null
  return (
    <Panel tone="paper" className="hbk-proposal">
      <Lines label={t('hotelBookingsProposalTitle')}>
        {p.options.map(o => {
          const found = getHall(o.hallId)
          return (
            <Line
              key={o.eventDate}
              icon="calendar-dots"
              label={t('hotelBookingsProposalTitle')}
              facts={
                <FactRow label={t('hotelBookingsFactsLabel')}>
                  {o.hallId !== b.sections[0]?.hallId ? <FactChip icon="hall" size="sm" label={t('hotelBookingsFactHall')} value={<Fx text={found ? bi(found.hall.name) : ''} />} /> : null}
                  {o.delta.fils !== 0 ? (
                    <span className="hbk-proposal__price">
                      <Icon name="coins" size="xs" tone="secondary" />
                      <span className="gz-sr-only">{t('hotelBookingsPriceChanged')}</span>
                      <QuietMoney fils={o.quotedTotal.fils} mode="exact" />
                    </span>
                  ) : null}
                </FactRow>
              }
            >
              <Figures text={f.date(o.eventDate, 'short')} />
            </Line>
          )
        })}
      </Lines>
      <FactRow label={t('hotelBookingsAwaitingCouple')}>
        <FactChip icon="hourglass" tone="accent" label={t('hotelBookingsProposalWindow')} value={<Fx text={days.stamp(p.expiresAt)} />} />
      </FactRow>
    </Panel>
  )
}

// ---------------------------------------------------------------- the outcome of a closed request

export function OutcomeBlock({ m }: { m: DetailModel }) {
  const { booking: b } = m
  const t = useT('hotel-bookings')
  const c = useT('common')
  const days = useDays()
  const hours = useHours()
  const last = b.events[b.events.length - 1]?.at
  const when = last ? days.dm(last) : ''
  const voucherInfo = (key: MessageKey<'hotel-bookings'>) => ({ title: c('commonVoucher'), body: <p>{t(key)}</p> })

  switch (b.status) {
    case 'declined': {
      const key = b.rejectReason ?? 'default'
      return (
        <StateStrip
          illustration="envelope"
          quietTitle
          title={c('commonStatusHotelDeclined')}
          info={voucherInfo('hotelBookingsInfoReturned')}
          facts={
            <FactRow label={t('hotelBookingsFactsLabel')}>
              <FactChip icon={DECLINE_ICON[key]} label={t('hotelBookingsDeclineReason')} value={t(DECLINE_KEY[key])} />
              <FactChip icon="calendar" label={t('hotelBookingsRowDate')} value={<Fx text={when} />} />
            </FactRow>
          }
        />
      )
    }
    case 'expired': {
      const lapsed = b.expiredReason === 'client_no_confirmation'
      return (
        <StateStrip
          illustration="hourglass"
          quietTitle
          title={lapsed ? c('commonStatusHotelLapsed') : c('commonStatusHotelMissed')}
          info={voucherInfo('hotelBookingsInfoReturned')}
          facts={
            <FactRow label={t('hotelBookingsFactsLabel')}>
              <FactChip icon="timer" label={t('hotelBookingsSilence', { time: hours(silenceHours(b)) })} value={<Fx text={hours(silenceHours(b))} />} />
              <FactChip icon="calendar" label={t('hotelBookingsRowDate')} value={<Fx text={when} />} />
            </FactRow>
          }
        />
      )
    }
    case 'cancelled': {
      const venue = b.cancelledBy === 'venue'
      return (
        <StateStrip
          illustration="calendar"
          quietTitle
          title={c('commonStatusCancelled')}
          info={voucherInfo(venue ? 'hotelBookingsInfoVenue' : wasConfirmed(b) ? 'hotelBookingsInfoClientUsed' : 'hotelBookingsInfoReturned')}
          facts={
            <FactRow label={t('hotelBookingsFactsLabel')}>
              <FactChip icon={venue ? 'hotel' : 'user'} label={venue ? t('hotelBookingsByVenue') : t('hotelBookingsByClient')} value={venue ? t('hotelBookingsActorVenue') : t('hotelBookingsActorClient')} />
              <FactChip icon="calendar" label={t('hotelBookingsRowDate')} value={<Fx text={when} />} />
            </FactRow>
          }
        />
      )
    }
    case 'completed':
      return (
        <StateStrip
          illustration="seal"
          quietTitle
          title={c('commonStatusCompleted')}
          facts={
            <FactRow label={t('hotelBookingsFactsLabel')}>
              <FactChip icon="calendar-check" label={t('hotelBookingsRowDate')} value={<Fx text={days.dayY(b.eventDate)} />} />
            </FactRow>
          }
        />
      )
    default:
      return null
  }
}

// ---------------------------------------------------------------- actions

/** Whether the event is over (the day has passed): "Complete" appears; otherwise the request completes by itself 12 hours later. */
const eventOver = (b: Booking): boolean => b.eventDate < PROTOTYPE_TODAY

/** What is left to do at the bottom: complete an ended event, or cancel a confirmed booking (Admin and Manager, reason required). */
export function ActionsBlock({ m }: { m: DetailModel }) {
  const { booking: b, role, lock } = m
  const t = useT('hotel-bookings')
  const act = useBookingActions()
  const nav = useNav()
  const offline = lock === 'offline'
  const complete = (b.status === 'confirmed' || b.status === 'redeemed') && eventOver(b) && canChange(role)
  const cancel = b.status === 'confirmed' && canChange(role)
  if (!complete && !cancel) return null
  const markCompleted = () => {
    const now = meta.now
    usePrototype.setState(s => ({
      hotelBookings: s.hotelBookings.map(x =>
        x.id === b.id ? { ...x, status: 'completed' as const, completedAt: now, events: [...x.events, { at: now, kind: 'transition' as const, from: x.status, to: 'completed' as const, actor: 'venue' as const }] } : x,
      ),
    }))
    nav.toast({ message: t('hotelBookingsCompletedToast'), tone: 'success', icon: 'check-double' })
  }
  return (
    <div className="hbk-actions">
      {complete ? (
        <Button variant="secondary" fullWidth iconStart="check-double" disabled={offline} onClick={markCompleted}>
          {t('hotelBookingsMarkCompleted')}
        </Button>
      ) : null}
      {cancel ? (
        <div className="hbk-actions__cancel">
          <Button variant="destructive" fullWidth iconStart="close" disabled={offline} onClick={() => act.cancel(refOf(b))}>
            {t('hotelBookingsCancelBooking')}
          </Button>
          <InfoButton title={t('hotelBookingsCancelInfoTitle')} className="hbk-actions__info">
            <p>{t('hotelBookingsCancelNote')}</p>
          </InfoButton>
        </div>
      ) : null}
    </div>
  )
}

// ---------------------------------------------------------------- history (the audit trail)

const AUDIT_ICON: Record<string, IconName> = {
  pending: 'clock',
  approved: 'hourglass',
  confirmed: 'check',
  redeemed: 'ticket',
  declined: 'close',
  expired: 'clock-off',
  cancelled: 'close',
  completed: 'check-double',
}

/** Who did what and when: one row that opens the trail in a sheet, so the screen itself carries no list of events. */
export function AuditBlock({ b }: { b: Booking }) {
  const t = useT('hotel-bookings')
  const days = useDays()
  const bi = useBi()
  const f = useFormat()
  const staff = useStaffName()
  const [open, setOpen] = useState(false)
  const label = (e: Booking['events'][number]): string => {
    if (e.note) return bi(e.note)
    if (e.kind === 'overlay') return t('hotelBookingsAuditProposal')
    switch (e.to) {
      case 'pending':
        return t('hotelBookingsAuditRequested')
      case 'approved':
        return t('hotelBookingsAuditApproved')
      case 'confirmed':
        return t('hotelBookingsAuditConfirmed')
      case 'redeemed':
        return t('hotelBookingsAuditRedeemed')
      case 'declined':
        return t('hotelBookingsAuditDeclined')
      case 'expired':
        return b.expiredReason === 'client_no_confirmation' ? t('hotelBookingsAuditLapsed') : t('hotelBookingsAuditExpired')
      case 'cancelled':
        return b.reasonCode === 'approval_revoked' ? t('hotelBookingsAuditRevoked') : t('hotelBookingsAuditCancelled')
      case 'completed':
        return t('hotelBookingsAuditCompleted')
      default:
        return t('hotelBookingsAuditUpdated')
    }
  }
  const who = (e: Booking['events'][number]): string => {
    if (e.actor === 'client') return e.actorName ?? b.clientName
    if (e.actor === 'venue') return staff(e.actorName) || t('hotelBookingsActorVenue')
    if (e.actor === 'admin') return t('hotelBookingsActorGhazal')
    return t('hotelBookingsActorSystem')
  }
  return (
    <>
      <IconListRow flush last icon="clock" title={t('hotelBookingsAuditTitle')} chevron onClick={() => setOpen(true)} className="hbk-history" />
      <InfoSheet open={open} onClose={() => setOpen(false)} title={t('hotelBookingsAuditTitle')}>
        <ol className="hbk-audit">
          {[...b.events].reverse().map((e, i) => (
            <li key={i} className="hbk-audit__row">
              <span className="hbk-audit__glyph" aria-hidden="true">
                <Icon name={e.kind === 'overlay' ? 'calendar-dots' : (AUDIT_ICON[e.to ?? ''] ?? 'check')} size="sm" tone="secondary" />
              </span>
              <span className="hbk-audit__text">
                <span className="hbk-audit__what gz-t-body-s">{label(e)}</span>
                <span className="hbk-audit__who gz-t-caption">
                  <UserText role="caption" text={who(e)}>
                    {who(e)}
                  </UserText>
                  {' · '}
                  <Figures text={`${days.dm(e.at)} ${f.time(e.at)}`} />
                </span>
              </span>
            </li>
          ))}
        </ol>
      </InfoSheet>
    </>
  )
}
