// VoucherWindowPreview: "what couples see" while the partner edits a voucher-price window (HL-GROW-02 / 03; HA-OFFR superseded by ADR 0033).
// It is the client's own VenueCard, drawn with the draft window: the photo with the "Special voucher price" badge, the wall label and the
// card price line with the voucher price as the headline and the standard price struck through (the real standard price, never an invented
// anchor). Under it, the line a couple reads at checkout: the window title and the saving it makes against the standard price, in exact
// money. It updates as values change, instantly: a changed figure swaps, it never counts up (ADR 0017 D7).
import type { Venue } from '@gz/contracts'
import { useFormat } from '../../../i18n'
import { VenueCard } from '../../domain-client'
import { cx } from '../../core/cx'
import { Figures } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './offers.css'

const useW = defineWords({
  label: p('How couples see it', 'كما يراه العملاء'),
  saving: p('Saving against the standard price', 'التوفير مقارنة بالسعر العادي'),
})

export type VoucherWindowPreviewProps = {
  venue: Venue
  /** Standard and window voucher amounts for the example booking, integer fils, and the guests it is for. */
  standard: number
  voucher: number
  guests: number
  packageId: string
  /** The date shown on the availability line. */
  date: string
  /** The window title in the current language (the screen supplies it from the editor field). */
  title: string
  className?: string
}

export function VoucherWindowPreview({ venue, standard, voucher, guests, packageId, date, title, className }: VoucherWindowPreviewProps) {
  const f = useFormat()
  const w = useW()
  const saving = Math.max(0, standard - voucher)
  const m = f.moneyParts(saving, { mode: 'exact' })
  return (
    <div data-gz="VoucherWindowPreview" className={cx('gz-op', className)}>
      <p className="gz-t-label gz-op__label">{w('label')}</p>
      <VenueCard
        venue={venue}
        variant="list"
        badge="window"
        availability="available"
        date={date}
        price={{
          mode: 'exact',
          amount: { fils: standard, currency: 'KWD' },
          guests,
          packageId,
          tier: 'weekend',
          voucher: voucher < standard ? { fils: voucher, currency: 'KWD' } : null,
          savings: voucher < standard ? { fils: saving, currency: 'KWD' } : null,
        }}
      />
      <div className="gz-op__line">
        <span className="gz-t-body-s gz-op__title">
          <Figures text={`${title} · ${w('saving')}`.trim()} />
        </span>
        <span className="gz-money gz-op__off">
          <span className="gz-money__cur">{m.currency}</span>
          <bdi dir="ltr" className="gz-t-price-strong">
            {m.integer}
            <span className="gz-money__fils">{m.fraction}</span>
          </bdi>
        </span>
      </div>
    </div>
  )
}
