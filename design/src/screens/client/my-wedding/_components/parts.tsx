// Small local pieces of the My Wedding hub, all in the diet's voice (ADR 0034): the lead card (the one primary of a phase), the tool tile
// (glyph, figure, one word), the booking glance (photo, name, status, two facts, the icon thread) and the planner module (offer or the
// assigned planner). The rest of the hub is the shared system.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import type { Booking } from '@gz/contracts'
import type { Planner } from '../../../../mock'
import { bookingTarget } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import {
  Avatar,
  BookingThread,
  Button,
  FactChip,
  FactRow,
  Icon,
  IconButton,
  IconListRow,
  Illustration,
  Monogram,
  Photo,
  StatusPill,
  imageSrc,
  useBi,
  type IllustrationName,
} from '../../../../system'
import { DateText } from './DateText'
import './parts.css'

// ---------------------------------------------------------------- lead card

export type LeadCardProps = {
  /** Facts (a FactRow or one FactChip) or one short name. Never a sentence. */
  children?: ReactNode
  /** A drawing at the end of the card (the hall for "choose your venue"). */
  art?: IllustrationName
  /** `lg` (144) for a scene, `md` (96) for a spot drawing such as the ticket. */
  artSize?: 'md' | 'lg'
  actionLabel: string
  actionIcon?: IconName
  onAction: () => void
  /** `quiet` = the rose-100 tint (a sample); default is the paper panel. */
  tone?: 'panel' | 'quiet'
  /** One line: the facts and the action share it (a guest's sample), instead of stacking. */
  inline?: boolean
}

/** The one gold action of a phase, with the figures that explain it. Gold is the button only. */
export function LeadCard({ children, art, artSize = 'lg', actionLabel, actionIcon, onAction, tone = 'panel', inline }: LeadCardProps) {
  return (
    <section className={`gzmw-lead gzmw-lead--${tone}${inline ? ' is-inline' : ''}`} data-gz="LeadCard">
      {children || art ? (
        <div className="gzmw-lead__body">
          {children ? <div className="gzmw-lead__facts">{children}</div> : null}
          {art ? <Illustration name={art} size={artSize} className="gzmw-lead__art" /> : null}
        </div>
      ) : null}
      <Button variant="primary" iconStart={actionIcon} fullWidth={!inline} onClick={onAction}>
        {actionLabel}
      </Button>
    </section>
  )
}

// ---------------------------------------------------------------- mini meter

/** A 4 px meter: the share done (gold line, a state) over the track. Decorative; the figure beside it says the number. */
export function MiniMeter({ share }: { share: number }) {
  const grow = Math.round(Math.min(Math.max(share, 0), 1) * 1000)
  return (
    <span className="gzmw-mini" aria-hidden="true">
      <span className="gzmw-mini__fill" style={{ flexGrow: grow }} />
      <span className="gzmw-mini__rest" style={{ flexGrow: 1000 - grow }} />
    </span>
  )
}

// ---------------------------------------------------------------- tool tile

export type ToolTileProps = {
  icon: IconName
  /** One word. Under the figure. */
  label: string
  /** The figure (a percent, a price, a count). Omit for a tool with none (Services). */
  value?: ReactNode
  /** 0 to 1: a meter under the figure. */
  share?: number
  /** `warn` = the glyph and figure in the danger tone (over budget). */
  tone?: 'default' | 'warn'
  onClick: () => void
}

export function ToolTile({ icon, label, value, share, tone = 'default', onClick }: ToolTileProps) {
  return (
    <button type="button" className={`gz-reset gzmw-tile gz-press${tone === 'warn' ? ' is-warn' : ''}`} onClick={onClick} data-gz="ToolTile">
      <span className="gzmw-tile__glyph">
        <Icon name={icon} size="md" tone={tone === 'warn' ? 'danger' : 'primary'} />
      </span>
      <span className="gzmw-tile__text">
        {value !== undefined ? <span className="gzmw-tile__value gz-t-fig-body">{value}</span> : null}
        <span className="gzmw-tile__label gz-t-caption">{label}</span>
      </span>
      {share !== undefined ? <MiniMeter share={share} /> : null}
    </button>
  )
}

// ---------------------------------------------------------------- booking glance

export type BookingGlanceProps = {
  booking: Booking
  onOpen: () => void
}

/** The booking on the hub: the venue's photo and name, the status, two facts, the five-knot thread (glyphs, no words). The card is one target. */
export function BookingGlance({ booking, onOpen }: BookingGlanceProps) {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()
  const { lang } = useLang()
  const target = bookingTarget(booking)
  const name = bi(target.name)
  const cover = target.venue?.cover ?? target.provider?.portfolio[0] ?? null
  const guests = booking.service ? booking.service.quantity : booking.sections.reduce((n, s) => n + s.guests, 0)
  return (
    <article className="gzmw-glance gz-press" data-gz="BookingGlance" data-status={booking.status}>
      <div className="gzmw-glance__top">
        <span className="gzmw-glance__thumb" data-gz-id="thumb">
          {cover ? <Photo src={imageSrc(cover.file)} alt="" className="gzmw-glance__photo" /> : <Monogram size="sm" />}
        </span>
        <div className="gzmw-glance__who">
          <h3 className="gzmw-glance__name gz-t-d1 gz-clamp-2" lang={lang} data-gz-id="name">
            {name}
          </h3>
          <div className="gzmw-glance__meta">
            <StatusPill status={booking.status} />
            <FactRow>
              <FactChip icon="users-three" value={f.integer(guests)} label={t('clientMyWeddingBookingGuests')} />
              <FactChip icon="coins" value={f.money(booking.totals.voucherTotal.fils)} label={c('commonVoucherPrice')} />
            </FactRow>
          </div>
        </div>
      </div>
      <BookingThread booking={booking} variant="full" labels="none" />
      <button type="button" className="gz-reset gzmw-glance__open" onClick={onOpen} aria-label={name} />
    </article>
  )
}

// ---------------------------------------------------------------- bookings empty

/** No bookings yet: one list row, the empty drawing at its start (a spot drawing is a list's leading element, policy section 9) and one
 * verb. When the screen already carries a lead that sends the couple to the halls, the row only says "none" and is not a control. */
export function BookingsEmpty({ onBrowse }: { onBrowse?: () => void }) {
  const t = useT('client-my-wedding')
  return (
    <div className="gzmw-empty" data-gz="EmptyState" data-gz-illustration="empty-bookings">
      <IconListRow
        illustration="empty-bookings"
        title={onBrowse ? t('clientMyWeddingBookingsEmptyAction') : t('clientMyWeddingBookingsEmptyTitle')}
        chevron={Boolean(onBrowse)}
        onClick={onBrowse}
        last
      />
    </div>
  )
}

// ---------------------------------------------------------------- planner module

export function PlannerOffer({ onSee, onDismiss }: { onSee: () => void; onDismiss: () => void }) {
  const t = useT('client-my-wedding')
  return (
    <section className="gzmw-offer" data-gz="PlannerOffer">
      <Illustration name="kosha" size="md" className="gzmw-offer__art" />
      <Button variant="secondary" onClick={onSee} className="gzmw-offer__action">
        {t('clientMyWeddingPlannerOfferAction')}
      </Button>
      <IconButton icon="close" label={t('clientMyWeddingPlannerDismiss')} onClick={onDismiss} iconSize="sm" />
    </section>
  )
}

export type PlannerCardProps = {
  planner: Planner
  /** The scheduled video call, an absolute instant. */
  meetingAt: string | null
  onOpen: () => void
  onMessage: () => void
}

export function PlannerCard({ planner, meetingAt, onOpen, onMessage }: PlannerCardProps) {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const f = useFormat()
  const { lang } = useLang()
  const name = planner.name[lang]
  return (
    <article className="gzmw-planner" data-gz="PlannerCard">
      <button type="button" className="gz-reset gzmw-planner__head gz-press" onClick={onOpen}>
        <Avatar name={name} initial={lang === 'ar' ? planner.monogram : undefined} size="md" />
        <span className="gzmw-planner__who">
          <span className="gz-t-title">
            <bdi dir="auto">{name}</bdi>
          </span>
          {meetingAt ? (
            <FactChip icon="video" value={<DateText text={f.date(meetingAt, 'dayMonth')} />} label={t('clientMyWeddingPlannerCall', { when: f.dateTime(meetingAt, 'short') })} />
          ) : null}
        </span>
      </button>
      <IconButton icon="chat" variant="outline" label={c('commonActionMessage')} onClick={onMessage} />
    </article>
  )
}
