// StatusCard (CL-DISC-01, ADR 0007 D4 and ADR 0033 D3): the one urgency-ranked card under the Brief card. One at a time: a decision waiting
// on you beats everything, then a visit tomorrow, a request in motion, a voucher ready, the Brief. The whole card is one button (the
// disclosure chevron at inline-end); it never carries a second action, so the gold CTA of the Brief card stays the only verb on Home.
//
// ADR 0034 (text diet): a small drawing leads, then a one-word status pill, the venue's name, and the one fact that matters as glyph and
// value (time left, event date). No sentence: the pill and the drawing say what kind of card it is.
//   no date         calendar    Pick a date                          -> the Brief sheet on its Date row
//   brief set       hall        3 halls free  [calendar] Thu 14 Jan  -> Results
//   voucher ready   voucher     [Ready] Aurelia Gulf Hotel           -> the voucher (CL-VCHR-03)
//   pending         envelope    [Pending] Aurelia Gulf Hotel  [timer] 20 h 40 m   -> Booking detail
//   approved        invitation  [Approved] Aurelia Gulf Hotel  [timer] 23 h       -> Booking detail, the Confirm booking action
//   confirmed       seal        [Confirmed] Aurelia Gulf Hotel  [calendar] Thu 14 Jan   -> the voucher (CL-VCHR-03)
//   visit soon      doorway     [Confirmed] Aurelia Gulf Hotel  [calendar] Tomorrow [clock] 12:00 PM -> the visit's group chat (CL-VIST-03)
import type { ReactNode } from 'react'
import type { Booking, VisitAppointment, Voucher } from '../../../../mock'
import * as mock from '../../../../mock'
import { FactRow, Figures, Icon, Illustration, StatusPill, useDuration, type IllustrationName, type StatusKey } from '../../../../system'
import { TextFact } from './TextFact'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import type { StatusKind } from './scenario'
import type { SearchBrief } from './data'
import './status-card.css'

export type StatusModel = {
  kind: StatusKind
  booking?: Booking | null
  voucher?: Voucher | null
  visit?: VisitAppointment | null
  /** Visit only: "today" or "tomorrow" (the card appears inside the last 24 hours). */
  visitDay?: 'today' | 'tomorrow'
  brief: SearchBrief
  /** Halls free on the Brief date (kind `brief-set`). */
  count?: number
}

export type StatusCardProps = {
  model: StatusModel
  onOpen?: () => void
}

const ART: Record<StatusKind, IllustrationName> = {
  'no-date': 'calendar',
  'brief-set': 'hall',
  'voucher-ready': 'voucher',
  pending: 'envelope',
  approved: 'invitation',
  confirmed: 'seal',
  'visit-soon': 'doorway',
}

/** The venue or provider a request or a voucher is addressed to, in the current language. */
function targetName(booking: Booking | null | undefined, voucher: Voucher | null | undefined, lang: 'en' | 'ar'): string {
  if (booking) return mock.bookingTarget(booking).name[lang]
  const id = voucher?.venueOrProviderId
  if (!id) return ''
  return (mock.getVenue(id) ?? mock.getProvider(id))?.name[lang] ?? ''
}

export function StatusCard({ model, onOpen }: StatusCardProps) {
  const t = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const duration = useDuration()
  const { lang } = useLang()
  const { kind, booking, voucher, visit, brief, count = 0 } = model

  let pill: StatusKey | null = null
  let title = ''
  let facts: ReactNode = null
  let spoken = ''
  const now = mock.clock.now()
  // A reply or confirm window is hours and minutes (`24 h`, `20 h 40 m`), the formatter's own unit letters; the compact duration would turn a
  // whole 24 h into `1 d`. Beyond two days it falls back to the compact form (days).
  // The unit letter is read off the first piece of the formatter's own output (`1 h 0 m` -> `h`), so Arabic keeps its letters (\u0633 \u062f).
  const unit = (ms: number) => (f.duration(ms).split(' ')[0] ?? '').replace(/[\d\u00a0\u2066-\u2069]+/g, '')
  const left = (iso: string | null | undefined) => {
    if (!iso) return ''
    const ms = Math.max(0, new Date(iso).getTime() - new Date(now).getTime())
    if (ms >= 48 * 3_600_000) return duration(ms)
    const minutes = Math.floor(ms / 60_000)
    const h = Math.floor(minutes / 60)
    const m = minutes % 60
    const mm = `${f.integer(m)}\u00a0${unit(60_000)}`
    return h > 0 ? `${f.integer(h)}\u00a0${unit(3_600_000)}${m > 0 ? ` ${mm}` : ''}` : mm
  }

  switch (kind) {
    case 'no-date':
      title = t('clientDiscoverStatusNoDate')
      break
    case 'brief-set': {
      const date = f.date(brief.date ?? mock.clock.today(), 'short')
      title = t('clientDiscoverStatusBrief', { count })
      facts = <TextFact icon="calendar" label={t('clientDiscoverA11yDate')} value={date} />
      spoken = date
      break
    }
    case 'voucher-ready':
      pill = 'voucher_active'
      title = targetName(booking, voucher, lang)
      break
    case 'pending': {
      pill = 'pending'
      title = targetName(booking, voucher, lang)
      const time = left(booking?.respondBy)
      facts = time ? <TextFact icon="timer" label={t('clientDiscoverA11yTimeLeft')} value={time} /> : null
      spoken = time
      break
    }
    case 'approved': {
      pill = 'approved'
      title = targetName(booking, voucher, lang)
      const time = left(booking?.confirmBy)
      facts = time ? <TextFact icon="timer" label={t('clientDiscoverA11yTimeLeft')} value={time} tone="accent" /> : null
      spoken = time
      break
    }
    case 'confirmed': {
      pill = 'confirmed'
      title = targetName(booking, voucher, lang)
      const date = f.date(booking?.eventDate ?? mock.clock.today(), 'short')
      facts = <TextFact icon="calendar" label={t('clientDiscoverA11yDate')} value={date} />
      spoken = date
      break
    }
    case 'visit-soon': {
      pill = 'visit_confirmed'
      title = mock.getVenue(visit?.venueId ?? '')?.name[lang] ?? ''
      const day = c(model.visitDay === 'today' ? 'commonLabelToday' : 'commonLabelTomorrow')
      const time = f.time(visit?.slotStart ?? now)
      facts = (
        <>
          <TextFact icon="calendar" label={t('clientDiscoverA11yDate')} value={day} />
          <TextFact icon="clock" label={t('clientDiscoverA11yTime')} value={time} />
        </>
      )
      spoken = `${day} ${time}`
      break
    }
  }

  return (
    <button type="button" className="gzd-status gz-reset gz-press" data-gz="StatusCard" data-kind={kind} onClick={onOpen} aria-label={[title, spoken].filter(Boolean).join('. ')}>
      <span className="gzd-status__art" aria-hidden="true">
        <Illustration name={ART[kind]} size="sm" />
      </span>
      <span className="gzd-status__text">
        {pill ? (
          <span className="gzd-status__pill">
            <StatusPill status={pill} />
          </span>
        ) : null}
        <span className="gzd-status__title gz-t-body">
          <Figures text={title} />
        </span>
        {facts ? <FactRow className="gzd-status__facts">{facts}</FactRow> : null}
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}
