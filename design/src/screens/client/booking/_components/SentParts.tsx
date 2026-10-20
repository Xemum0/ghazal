// SentParts: the pieces of the outcome screens (request sent, booking confirmed, confirm), spoken in drawings, glyphs and figures (ADR 0034).
//   SuccessHero   the one ink panel: a drawing (settles once in 640 ms, no confetti), the outcome in two words, and the thread under it
//   DateLine      the event date: the calendar glyph, the weekday and full date, and in the Arabic UI only the muted Hijri line (ADR 0011)
//   PlannerOffer  the planner offer, once: a glyph row that opens the planner and a close glyph that dismisses it
//   NotifPrompt   the pre-prompt sheet before the system dialog: a bell drawing, one action, one way out
import type { ReactNode } from 'react'
import { Button, Figures, Icon, IconButton, Illustration, type IllustrationName } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import './sent.css'

export type SuccessHeroProps = {
  illustration: IllustrationName
  id: string
  title: ReactNode
  /** The thread (BookingThread onDark) that completes the moment. */
  children?: ReactNode
  /** The `data-gz` name of the panel (a screen's own hero name). */
  dataGz?: string
}

export function SuccessHero({ illustration, id, title, children, dataGz = 'SuccessHero' }: SuccessHeroProps) {
  return (
    <section className="bk-hero" data-gz={dataGz} aria-labelledby={id}>
      <span className="bk-hero__art">
        <Illustration name={illustration} size="lg" tone="on-dark" />
      </span>
      <h1 id={id} className="bk-hero__title gz-t-d3">
        {title}
      </h1>
      {children}
    </section>
  )
}

/** The event date as a line: full date, and in the Arabic UI only the muted Hijri line beneath it (ADR 0011). */
export function DateLine({ date }: { date: string }) {
  const f = useFormat()
  const parts = f.dateWithHijri(date)
  return (
    <span className="bk-dateline" data-gz="DateLine">
      <Icon name="calendar" size="md" tone="secondary" />
      <span className="bk-dateline__text">
        <span className="bk-dateline__value gz-t-title">
          <Figures text={parts.primary} />
        </span>
        {f.lang === 'ar' && parts.secondary ? (
          <span className="bk-dateline__sub gz-t-caption">
            <Figures text={parts.secondary} />
          </span>
        ) : null}
      </span>
    </span>
  )
}

export type PlannerOfferProps = {
  onYes: () => void
  onNo: () => void
}

export function PlannerOffer({ onYes, onNo }: PlannerOfferProps) {
  const t = useT('client-booking')
  return (
    <div className="bk-planner" data-gz="PlannerOffer" data-gz-id="booking.planner">
      <button type="button" className="gz-reset gz-press bk-planner__main" onClick={onYes}>
        <span className="bk-planner__disk" aria-hidden="true">
          <Icon name="staff" size="md" />
        </span>
        <span className="bk-planner__title gz-t-title">{t('clientBookingPlannerTitle')}</span>
        <Icon name="chevron-right" size="sm" tone="secondary" />
      </button>
      <IconButton icon="close" iconSize="sm" label={t('clientBookingPlannerNo')} onClick={onNo} />
    </div>
  )
}

export function NotifPrompt({ onYes, onNo }: { onYes: () => void; onNo: () => void }) {
  const t = useT('client-booking')
  return (
    <div className="bk-notif" data-gz="NotifPrompt">
      <Illustration name="bell" size="lg" />
      <div className="bk-notif__actions">
        <Button variant="primary" fullWidth iconStart="bell" onClick={onYes}>
          {t('clientBookingSentNotifYes')}
        </Button>
        <Button variant="tertiary" onClick={onNo}>
          {t('clientBookingSentNotifNo')}
        </Button>
      </div>
    </div>
  )
}
