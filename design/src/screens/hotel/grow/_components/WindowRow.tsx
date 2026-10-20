// WindowRow: one voucher-price window of the venue on a hairline row (hotel density, no card). The venue's own title (clamped), the voucher
// price as the headline with the real standard price struck beside it and a glyph for its unit, then the facts as glyph and figure with no
// caption: vouchers bought, the event dates, when it starts or ends. A paused window and a window just published each carry one tag. The
// standing prices are the same row with a ticket disk, "Always on" and the number of packages. The whole row is the target and opens the
// actions sheet.
import type { GzFormat } from '@gz/i18n'
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat } from '../../../../i18n'
import { FactChip, FactRow, Icon, Price, Tag } from '../../../../system'
import { Fig, Fx, dayList, dmy, useBi, useWords, weekdayRun } from './bits'
import { standardOf, voucherPackages, windowRate, type WindowRecord } from './model'
import './window-row.css'

type Fact = { icon: IconName; node: ReactNode; label: string }

/** The facts of a window as glyph and value. `full` writes every date; the row summarises a long list as a count. */
export function useWindowFacts() {
  const f = useFormat()
  const { t } = useWords()
  const arrow = <Icon name="arrow-right" size="xs" tone="secondary" />
  const events = (w: WindowRecord, full = false): Fact | null => {
    const label = t('hotelGrowFactDates')
    if (w.eventDates?.length) {
      if (w.eventDates.length > 3 && !full) return { icon: 'calendar-dots', node: <Fig>{f.integer(w.eventDates.length)}</Fig>, label }
      return { icon: 'calendar', node: <Fx text={dayList(f, w.eventDates)} />, label }
    }
    if (!w.eventTo) return null
    const days = w.eventWeekdays ? weekdayRun(f, w.eventWeekdays) : null
    const from = w.eventFrom
    const to = w.eventTo
    const span =
      full || !days ? (
        <>
          {from ? (
            <>
              <Fx text={dmy(f, from)} /> {arrow}{' '}
            </>
          ) : null}
          <Fx text={dmy(f, to)} />
          {days ? (
            <>
              {' · '}
              <Fx text={days} />
            </>
          ) : null}
        </>
      ) : (
        <>
          <Fx text={days} /> {arrow} <Fx text={dmy(f, to)} />
        </>
      )
    return span ? { icon: 'calendar', node: span, label } : null
  }
  const run = (w: WindowRecord): Fact | null => {
    const day = (iso: string) => <Fx text={dmy(f, iso.slice(0, 10))} />
    if (w.status === 'ended') return { icon: 'calendar-check', node: day(w.endsAt ?? w.startsAt), label: t('hotelGrowStatEnded') }
    if (w.status === 'scheduled') return { icon: 'hourglass', node: day(w.startsAt), label: t('hotelGrowStatStarts') }
    if (w.endsAt) return { icon: 'timer', node: day(w.endsAt), label: t('hotelGrowStatEnds') }
    return null
  }
  return { events, run }
}

/** Glyph for the unit of the rate: per guest, or per package. */
export function UnitGlyph({ unit }: { unit: 'per_guest' | 'flat' }) {
  const { t } = useWords()
  return (
    <>
      <Icon name={unit === 'flat' ? 'package' : 'per-guest'} size="sm" tone="secondary" />
      <span className="gz-sr-only">{t(unit === 'flat' ? 'hotelGrowUnitPackage' : 'hotelGrowUnitGuest')}</span>
    </>
  )
}

export type WindowRowProps = { window: WindowRecord; onOpen: () => void; isNew?: boolean }

export function WindowRow({ window: w, onOpen, isNew }: WindowRowProps) {
  const f = useFormat()
  const bi = useBi()
  const { t, c } = useWords()
  const facts = useWindowFacts()
  const { standard, unit } = standardOf(w)
  const rate = windowRate(w)
  const events = facts.events(w)
  const run = facts.run(w)
  return (
    <button type="button" className="gz-reset gz-press go-row" data-paused={w.paused || undefined} data-new={isNew || undefined} onClick={onOpen} aria-label={bi(w.title)}>
      <span className="go-row__main">
        <span className="go-row__title gz-t-body gz-clamp-2">
          <bdi dir="auto">{bi(w.title)}</bdi>
        </span>
        <span className="go-row__price">
          <UnitGlyph unit={unit} />
          <Price fils={rate} mode="browse" size="strong" was={standard > rate ? standard : undefined} />
          {w.paused ? <Tag icon="pause">{t('hotelGrowPaused')}</Tag> : null}
          {isNew ? <Tag icon="sparkle">{c('commonLabelNew')}</Tag> : null}
        </span>
        <FactRow label={t('hotelGrowFactsLabel')}>
          <FactChip icon="ticket" value={f.integer(w.vouchersBought)} label={t('hotelGrowStatVouchers')} size="sm" tone="muted" />
          {events ? <FactChip icon={events.icon} value={events.node} label={events.label} size="sm" tone="muted" /> : null}
          {run ? <FactChip icon={run.icon} value={run.node} label={run.label} size="sm" tone="muted" /> : null}
        </FactRow>
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" className="go-row__chev" />
    </button>
  )
}

/** The standing voucher prices of every package: one "Always on" row, never a single misleading price. */
export function StandingRow({ onOpen }: { onOpen: () => void }) {
  const f = useFormat()
  const { t } = useWords()
  const count = voucherPackages().length
  return (
    <button type="button" className="gz-reset gz-press go-row go-row--standing" onClick={onOpen} aria-label={t('hotelGrowStandingTitle')}>
      <span className="go-row__disk" aria-hidden="true">
        <Icon name="ticket" size="md" tone="primary" />
      </span>
      <span className="go-row__main">
        <span className="go-row__title gz-t-body">{t('hotelGrowStandingTitle')}</span>
        <span className="go-row__price">
          <Tag icon="check">{t('hotelGrowAlwaysOn')}</Tag>
          <FactChip icon="package" value={f.integer(count)} label={t('hotelGrowStandingCount')} size="sm" tone="muted" />
        </span>
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" className="go-row__chev" />
    </button>
  )
}
