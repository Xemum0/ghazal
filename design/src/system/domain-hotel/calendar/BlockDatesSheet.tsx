// BlockDatesSheet: block (or open) a range of dates in three taps or fewer from anywhere (ADR 0008 D9). The sheet carries the hint
// (DragAffordance), the month grid in select mode (press-hold-drag or tap start and end; booked-out and past days refuse), the
// Ramadan / Eid shortcuts as adjustable ranges (never fixed dates: they are approximate until announced, ADR 0011), the reason
// (Booked offline by default, an offline sale carries no payment and no commission), the scope by hall, and the action bar:
// `N dates` with ONE gold primary (Block) and equal-weight Open and Offer. A confirmed booking cannot be blocked over, so those days
// are not selectable. It is a Sheet: `placement="overlay"` in a screen, `inline` in the gallery.
import { useState } from 'react'
import type { BlockReason, CalendarClaim, Hall, IsoDate } from '@gz/contracts'
import { engine, meta } from '../../../mock'
import { Button } from '../../core'
import { ChipGroup } from '../../inputs'
import { Sheet } from '../../overlays'
import { Figures, useBi } from '../internal/bits'
import { defineWords, definePlurals, p } from '../internal/copy'
import { DragAffordance } from './DragAffordance'
import { HotelMonthGrid } from './HotelMonthGrid'
import type { DateSpan } from './model'
import '../calendar.css'

const useW = defineWords({
  title: p('Block dates', 'إغلاق التواريخ'),
  shortcuts: p('Shortcuts', 'اختصارات'),
  reason: p('Reason', 'السبب'),
  halls: p('Halls', 'القاعات'),
  allHalls: p('All halls', 'كل القاعات'),
  offline_booking: p('Booked offline', 'حجز خارج غزل'),
  maintenance: p('Maintenance', 'صيانة'),
  private_event: p('Private event', 'مناسبة خاصة'),
  other: p('Other', 'أخرى'),
  block: p('Block', 'إغلاق'),
  open: p('Open', 'فتح'),
  offer: p('Offer', 'عرض'),
  none: p('Choose the dates', 'اختاروا التواريخ'),
  grid: p('Choose dates to block', 'اختيار التواريخ المراد إغلاقها'),
  note: p('Hidden from couples as soon as you block.', 'تختفي من نتائج العملاء فور الإغلاق.'),
})

const usePl = definePlurals({
  dates: { en: { one: '{n} date', other: '{n} dates' }, ar: { '=1': 'تاريخ واحد', '=2': 'تاريخان', few: '{n} تواريخ', many: '{n} تاريخًا', other: '{n} تاريخ' } },
})

const REASONS: BlockReason[] = ['offline_booking', 'maintenance', 'private_event', 'other']

export type BlockDatesSheetProps = {
  halls: readonly Hall[]
  claims: readonly CalendarClaim[]
  open?: boolean
  placement?: 'overlay' | 'inline'
  /** The range, controlled by the screen (the default starts empty). */
  value?: DateSpan
  onChange?: (r: DateSpan) => void
  onRequestClose?: () => void
  onBlock?: (v: { range: DateSpan; reason: BlockReason; hallIds: string[] }) => void
  onOpenDates?: (v: { range: DateSpan; hallIds: string[] }) => void
  onOffer?: (range: DateSpan) => void
  /** Initial month shown. */
  defaultMonth?: { year: number; month: number }
}

export function BlockDatesSheet({ halls, claims, open = true, placement = 'overlay', value, onChange, onRequestClose, onBlock, onOpenDates, onOffer, defaultMonth }: BlockDatesSheetProps) {
  const w = useW()
  const pl = usePl()
  const bi = useBi()
  const [inner, setInner] = useState<DateSpan>({ start: null, end: null })
  const range = value ?? inner
  const setRange = (r: DateSpan) => {
    if (!value) setInner(r)
    onChange?.(r)
  }
  const [reason, setReason] = useState<BlockReason>('offline_booking')
  const [hallIds, setHallIds] = useState<string[]>(() => halls.map(h => h.id))
  const dates: IsoDate[] = range.start ? engine.datesBetween(range.start <= (range.end ?? range.start) ? range.start : (range.end as IsoDate), range.start <= (range.end ?? range.start) ? (range.end ?? range.start) : range.start) : []
  const count = dates.length
  const occasions = meta.occasions.filter(o => o.id === 'ramadan-1448' || o.id.startsWith('eid')).slice(0, 3) as { id: string; name: { en: string; ar: string }; from: IsoDate; to: IsoDate; approximate: boolean }[]

  return (
    <Sheet
      open={open}
      placement={placement}
      title={w('title')}
      onRequestClose={onRequestClose}
      footer={
        <div className="gz-bd__bar" data-gz-id="blockdates.bar">
          <p className="gz-bd__count gz-t-body-s">
            <Figures text={count ? pl('dates', count) : w('none')} />
          </p>
          <Button variant="primary" size="cta" fullWidth disabled={count === 0} onClick={() => onBlock?.({ range, reason, hallIds })}>
            {w('block')}
          </Button>
          <div className="gz-bd__pair">
            <Button variant="secondary" disabled={count === 0} onClick={() => onOpenDates?.({ range, hallIds })}>
              {w('open')}
            </Button>
            <Button variant="secondary" disabled={count === 0} onClick={() => onOffer?.(range)}>
              {w('offer')}
            </Button>
          </div>
        </div>
      }
    >
      <div className="gz-bd" data-gz="BlockDatesSheet">
        <DragAffordance />
        <HotelMonthGrid halls={halls} claims={claims} mode="select" range={range} onRangeChange={setRange} legend={false} label={w('grid')} defaultMonth={defaultMonth} />
        {occasions.length ? (
          <div className="gz-bd__group">
            <p className="gz-t-label gz-bd__label">{w('shortcuts')}</p>
            <ChipGroup
              label={w('shortcuts')}
              layout="wrap"
              options={occasions.map(o => ({ value: o.id, label: o.approximate ? `${bi(o.name)}` : bi(o.name) }))}
              onChange={id => {
                const o = occasions.find(x => x.id === id)
                if (o) setRange({ start: o.from, end: o.to })
              }}
              deselectable
            />
          </div>
        ) : null}
        <div className="gz-bd__group">
          <p className="gz-t-label gz-bd__label">{w('reason')}</p>
          <ChipGroup label={w('reason')} layout="wrap" value={reason} onChange={v => v && setReason(v as BlockReason)} options={REASONS.map(r => ({ value: r, label: w(r) }))} />
        </div>
        {halls.length > 1 ? (
          <div className="gz-bd__group">
            <p className="gz-t-label gz-bd__label">{w('halls')}</p>
            <ChipGroup selection="multiple" label={w('halls')} layout="wrap" value={hallIds} onChange={v => setHallIds(v)} options={halls.map(h => ({ value: h.id, label: bi(h.name) }))} />
          </div>
        ) : null}
        <p className="gz-t-caption gz-bd__note">{w('note')}</p>
      </div>
    </Sheet>
  )
}
