// The two sheets of Analytics: the custom period (a Sunday-first range calendar, no native picker) and the legend of the numbers ("How we count",
// ADR 0019): a glyph and a name for every figure of the screen, and a fragment of a definition for the four that need one. Both draw their own
// header through SheetFrame; the host's titled header would capture the drag zone.
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import { engine } from '../../../../mock'
import { Button, Calendar, FactChip, FactRow, Icon, InfoButton, type CalendarDayInfo, type DateRange } from '../../../../system'
import { useFormat } from '../../../../i18n'
import { Fx, Figures, dmy, useWords } from './bits'
import { CONVERSION_WINDOW_DAYS, DATA_FROM, VIEW_WINDOW_MINUTES, todayIso, type Span } from './analytics'
import { SheetFrame } from './SheetFrame'
import './analytics-sheets.css'

// Past days are selectable here (the calendar closes days before today by default): every day with data is available.
const DAYS: Record<string, CalendarDayInfo> = Object.fromEntries(engine.datesBetween(DATA_FROM, todayIso).map(d => [d, { status: 'available' as const }]))

export type RangeSheetProps = {
  initial?: Span | null
  onApply: (span: Span) => void
  onClose?: () => void
}

export function RangeSheet({ initial, onApply, onClose }: RangeSheetProps) {
  const f = useFormat()
  const { t, c } = useWords()
  const [range, setRange] = useState<DateRange>({ start: initial?.from ?? null, end: initial?.to ?? null })
  const ready = Boolean(range.start && range.end)
  return (
    <SheetFrame
      title={t('hotelGrowAnCustomTitle')}
      onClose={onClose}
      info={
        <InfoButton title={t('hotelGrowAnCustomTitle')}>
          <p>
            <Figures text={t('hotelGrowAnCustomOutside', { date: f.date(DATA_FROM, 'full') })} />
          </p>
        </InfoButton>
      }
      footer={
        <Button variant="primary" size="cta" fullWidth disabled={!ready} onClick={() => range.start && range.end && onApply({ from: range.start, to: range.end })}>
          {c('commonActionApply')}
        </Button>
      }
    >
      <div className="gas-range">
        <FactRow label={t('hotelGrowAnRangeLabel')}>
          <FactChip icon="calendar" value={range.start ? <Fx text={dmy(f, range.start)} /> : undefined} label={t('hotelGrowAnRangeFrom')} />
          <Icon name="arrow-right" size="xs" tone="secondary" />
          <FactChip icon="calendar-check" value={range.end ? <Fx text={dmy(f, range.end)} /> : undefined} label={t('hotelGrowAnRangeTo')} />
        </FactRow>
        <Calendar mode="range" days={DAYS} value={range} onChange={setRange} minDate={DATA_FROM} maxDate={todayIso} today={todayIso} legend={false} summary={false} label={t('hotelGrowAnCustomTitle')} />
      </div>
    </SheetFrame>
  )
}

export type LegendRow = { id: string; icon: IconName; name: string }

export function DefinitionsSheet({ rows, onClose }: { rows: readonly LegendRow[]; onClose?: () => void }) {
  const { t } = useWords()
  const text: Record<string, string> = {
    views: t('hotelGrowAnDefViews', { minutes: VIEW_WINDOW_MINUTES }),
    clicks: t('hotelGrowAnDefClicks'),
    vouchers: t('hotelGrowAnDefVouchers'),
    conversion: t('hotelGrowAnDefConversion', { days: CONVERSION_WINDOW_DAYS }),
  }
  return (
    <SheetFrame title={t('hotelGrowAnDefsTitle')} onClose={onClose}>
      <ul className="gas-defs">
        {rows.map(r => (
          <li key={r.id} className="gas-defs__row">
            <span className="gas-defs__disk" aria-hidden="true">
              <Icon name={r.icon} size="sm" tone="primary" />
            </span>
            <span className="gas-defs__body">
              <span className="gz-t-body gas-defs__name">{r.name}</span>
              {text[r.id] ? (
                <span className="gz-t-body-s gas-defs__text">
                  <Figures text={text[r.id] as string} />
                </span>
              ) : null}
            </span>
          </li>
        ))}
      </ul>
    </SheetFrame>
  )
}
