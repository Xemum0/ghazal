// VoucherWindowCard (Home shelves "Voucher price drops", venue details; ADR 0033, HL-GROW voucher windows): the one rose-100 panel of the
// client app. A window is a time-boxed LOWER voucher price a venue offers on chosen event dates; it replaces the old offers and coupon
// codes (there is no code to copy: the voucher is the code). The rate is a figure in the figures voice with its unit, the title is the
// venue's own words in the serif, the conditions are plain facts (event window, weekdays, booking ends). Never an urgency counter.
//
// states  default, pressed, ended / scheduled (muted, no action), loading
import type { VoucherWindow } from '@gz/contracts'
import { getVenue } from '../../mock'
import { useFormat } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Button, Icon, Price, Skeleton } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './voucher-window-card.css'

const useW = defineWords({
  eyebrow: p('Voucher price', 'سعر الكوبون'),
  events: p('For events {window}', 'للمناسبات {window}'),
  eventsOn: p('For events on {days}', 'للمناسبات يوم {days}'),
  eventsDates: p('For events on selected dates', 'للمناسبات في تواريخ محددة'),
  until: p('Price available until {date}', 'السعر متاح حتى {date}'),
  view: p('See the hall', 'عرض القاعة'),
  ended: p('This price has ended', 'انتهى هذا السعر'),
  scheduled: p('Starts soon', 'يبدأ قريبًا'),
  fromTo: p('{from} – {to}', 'من {from} إلى {to}'),
  night: p('per night', 'لليلة'),
})

export type VoucherWindowCardProps = {
  window: VoucherWindow
  onOpen?: () => void
  loading?: boolean
  previewState?: 'pressed'
  className?: string
}

/** Weekday indexes as `Sun – Wed` when they run in a row, else a list. Names come from the formatter. */
function useWeekdaySpan() {
  const f = useFormat()
  return (days: readonly number[]): string => {
    const sorted = [...days].sort((a, b) => a - b)
    const first = sorted[0]
    const last = sorted[sorted.length - 1]
    if (first === undefined || last === undefined) return ''
    const consecutive = sorted.every((d, i) => i === 0 || d === (sorted[i - 1] ?? 0) + 1)
    if (consecutive && sorted.length > 2) return `${f.weekdayName(first, 'short')} – ${f.weekdayName(last, 'short')}`
    return f.list(sorted.map(d => f.weekdayName(d, 'short')), 'and')
  }
}

export function VoucherWindowCard({ window: win, onOpen, loading, previewState, className }: VoucherWindowCardProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  const span = useWeekdaySpan()

  if (loading) {
    return (
      <div className={cx('gz-vwin is-loading', className)} data-gz="VoucherWindowCard" aria-busy="true">
        <Skeleton inlineSize={96} blockSize={20} />
        <Skeleton inlineSize={200} blockSize={28} />
        <Skeleton inlineSize={160} blockSize={20} />
      </div>
    )
  }

  const venue = getVenue(win.venueId)
  const windowText =
    win.eventFrom && win.eventTo
      ? w('events', { window: w('fromTo', { from: f.date(win.eventFrom, 'compact'), to: f.date(win.eventTo, 'compact') }) })
      : win.eventDates && win.eventDates.length
        ? w('eventsDates')
        : null
  const daysText = win.eventWeekdays && win.eventWeekdays.length ? w('eventsOn', { days: span(win.eventWeekdays) }) : null
  const live = win.status === 'active'
  const rate = win.voucherPerGuest ?? win.voucherFlat

  return (
    <article
      data-gz="VoucherWindowCard"
      data-status={win.status}
      className={cx('gz-vwin gz-press', !live && 'is-muted', previewState === 'pressed' && 'is-pressed', className)}
    >
      <p className="gz-vwin__eyebrow gz-t-label">
        <Icon name="ticket" size="xs" tone="secondary" />
        {w('eyebrow')}
      </p>
      {rate ? (
        <div className="gz-vwin__rate" data-gz-id="rate">
          <Price fils={rate.fils} size="total" unit={win.voucherPerGuest ? 'perGuest' : 'perNight'} />
        </div>
      ) : null}
      <h3 className="gz-vwin__title gz-t-d1" lang={lang} data-gz-id="title">
        {bi(win.title)}
      </h3>
      <p className="gz-vwin__venue gz-t-body-s">{venue ? bi(venue.name) : ''}</p>
      <ul className="gz-vwin__facts gz-t-caption">
        {[windowText, daysText].filter(Boolean).map((line, i) => (
          <li key={i}>
            <Figures text={line as string} />
          </li>
        ))}
        {win.endsAt && live ? (
          <li>
            <Figures text={w('until', { date: f.date(win.endsAt, 'short') })} />
          </li>
        ) : null}
        {!live ? (
          <li className="gz-vwin__state">
            <Icon name="info" size="xs" tone="secondary" />
            {win.status === 'ended' ? w('ended') : w('scheduled')}
          </li>
        ) : null}
      </ul>
      {live ? (
        <Button variant="tertiary" iconEnd="chevron-right" onClick={onOpen} className="gz-vwin__go">
          {w('view')}
        </Button>
      ) : null}
    </article>
  )
}
