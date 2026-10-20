// PreviewStrip: the client venue card in miniature, the way a couple sees the voucher price: the photograph, the voucher badge, the venue's
// serif name, the voucher price for the example booking with the real standard price struck through, and the facts of the example (guests,
// date, free or not) as glyph and figure, no caption. Pinned under the step thread on step 2 (`compact`), inside the actions sheet (`flat`) and
// as the full card of step 1 (`card`). Only the real standard price is ever struck through (ADR 0018 D4); a changed total swaps instantly,
// it never counts up (ADR 0017 D7).
import { venueAvailabilityOn } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { Badge, FactChip, FactRow, imageSrc, Photo, Price } from '../../../../system'
import { Fx, dm, useBi, useWords } from './bits'
import { exampleQuote, venue } from './model'
import { Saving } from './Saving'
import './preview-strip.css'

export type PreviewStripProps = {
  /** The window's rate in fils, per guest or flat as its packages are priced. */
  rate: number
  packageIds: readonly string[]
  dates: readonly string[]
  /** Quiet variant for the sheet: no panel border. */
  flat?: boolean
  /** Pinned under the step thread: a 56 square photograph, the name and the price line only. */
  compact?: boolean
  /** The full card of the editor: a wide photograph with the voucher badge over it, then name, price and facts. */
  card?: boolean
}

export function PreviewStrip({ rate, packageIds, dates, flat = false, compact = false, card = false }: PreviewStripProps) {
  const f = useFormat()
  const bi = useBi()
  const { t, c } = useWords()
  const v = venue()
  const ex = exampleQuote(packageIds, dates, rate)
  const free = venueAvailabilityOn(v?.id ?? '', ex.date).state === 'available'
  if (!v) return null
  const badge = (
    <Badge variant={card ? 'photo' : 'outline'} bead={false} icon="ticket">
      {c('commonVoucher')}
    </Badge>
  )
  return (
    <div className="gp-strip" data-flat={flat || undefined} data-compact={compact || undefined} data-card={card || undefined} data-gz-id="offer.preview">
      <span className="gp-strip__thumb">
        {v.cover ? <Photo src={imageSrc(v.cover.file)} alt={bi(v.cover.alt)} sizes={card ? '390px' : '96px'} /> : null}
        {card ? <span className="gp-strip__over">{badge}</span> : null}
      </span>
      <span className="gp-strip__body">
        {card || compact ? null : <span className="gp-strip__badge">{badge}</span>}
        <span className="gp-strip__name gz-t-d1">{bi(v.name)}</span>
        <span className="gp-strip__price">
          <Price fils={ex.voucher} mode="browse" size="card" was={ex.saving > 0 ? ex.standard : undefined} />
        </span>
        <FactRow label={t('hotelGrowPreviewLabel')}>
          {ex.unit === 'flat' ? (
            <FactChip icon="package" label={t('hotelGrowUnitPackage')} size="sm" tone="muted" />
          ) : (
            <FactChip icon="users-three" value={f.integer(ex.guests)} label={t('hotelGrowFactGuests')} size="sm" tone="muted" />
          )}
          {compact ? null : (
            <>
              <FactChip icon={free ? 'calendar-check' : 'calendar-x'} value={<Fx text={dm(f, ex.date)} />} label={c(free ? 'commonAvailabilityFree' : 'commonAvailabilityBooked')} size="sm" tone="muted" />
              {ex.saving > 0 ? <Saving fils={ex.saving} label={t('hotelGrowYouSave')} /> : null}
            </>
          )}
        </FactRow>
      </span>
    </div>
  )
}
