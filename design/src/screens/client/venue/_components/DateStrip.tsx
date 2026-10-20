// DateStrip (CL-VENU-01, direction rule 8): the ruled YOUR DATE strip. A hairline above and below, not a panel. It answers the two
// questions of the visit: is the hall free on our date, and what will it cost. The date in the display face, the availability as a pill
// (icon + one word), the guests as a glyph and a figure, the two prices of the quote as glyphs and figures (PriceBlock; ADR 0033).
// ADR 0034: no label, caption or sentence. A held date is its pill (the reassurance is its accessible name); an unavailable date offers the
// nearest free dates as chips instead of a dead end; no date is a small calendar drawing and two words.
import type { IsoDate } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Button, Chip, FactChip, FactRow, Figures, Icon, Illustration, Skeleton, StatusPill } from '../../../../system'
import { useGuestsText, useShortDay } from './fmt'
import type { DayStatusKind, PackageRow, QuotePrices, VenueBrief } from './model'
import { PriceBlock } from './PriceBlock'
import './date-strip.css'

export type DateStripProps = {
  brief: VenueBrief
  status: DayStatusKind
  prices: QuotePrices | null
  row: PackageRow | undefined
  /** Signed out: the voucher price shows with a lock. */
  guest?: boolean
  /** The client holds a ready voucher for this venue. */
  owned?: boolean
  /** The venue's voucher window that lowers this price, already picked for the language. */
  windowTitle?: string | null
  /** Unavailable dates: the nearest free dates of the hall. */
  nearest?: readonly IsoDate[]
  onOpenCalendar: () => void
  onEditGuests: () => void
  /** Opens CL-VCHR-01 (the explainer); the (i) shows only when the quote has a voucher price. */
  onHow?: () => void
  onPickDate: (date: IsoDate) => void
  loading?: boolean
}

export function DateStrip({ brief, status, prices, row, guest = false, owned = false, windowTitle, nearest = [], onOpenCalendar, onEditGuests, onHow, onPickDate, loading }: DateStripProps) {
  const f = useFormat()
  const t = useT('client-venue')
  const { lang } = useLang()
  const shortDay = useShortDay()
  const guestsText = useGuestsText()

  if (loading) {
    return (
      <section className="gzv-date is-loading" aria-busy="true">
        <Skeleton inlineSize={200} blockSize={32} />
        <Skeleton inlineSize={96} blockSize={20} />
        <Skeleton blockSize={72} />
      </section>
    )
  }

  const { date, guests } = brief
  const unavailable = status === 'unavailable'

  return (
    <section className="gzv-date" data-gz="DateStrip" data-status={status} aria-label={t('clientVenueDateLabel')}>
      <button type="button" className="gz-reset gz-press gzv-date__main" onClick={onOpenCalendar} aria-label={`${t('clientVenueDateLabel')}. ${t('clientVenueDateChangeLabel')}`} data-gz-id="venue.date">
        {date ? <Icon name="calendar" size="md" tone="secondary" /> : <Illustration name="calendar" size="md" />}
        <span className="gzv-date__value gz-t-d1" lang={lang}>
          {date ? <Figures text={shortDay(date)} /> : t('clientVenueDateChoose')}
        </span>
        <Icon name={date ? 'chevron-down' : 'chevron-right'} size="sm" tone="secondary" />
      </button>

      {date ? (
        <div className="gzv-date__state">
          {status === 'available' ? <StatusPill status="available" /> : null}
          {status === 'held' ? (
            <>
              <StatusPill status="held" />
              <span className="gz-sr-only" data-gz-id="venue.held">
                {t('clientVenueHeldSr')}
              </span>
            </>
          ) : null}
          {unavailable ? <StatusPill status="unavailable" /> : null}
          <button type="button" className="gz-reset gz-press gzv-date__guests" onClick={onEditGuests} aria-label={t('clientVenueGuestsChangeLabel')} data-gz-id="venue.guests">
            {guests !== null ? (
              <>
                <FactChip icon="users-three" value={f.integer(guests)} label={t('clientVenueGuestsLabel')} />
                <Icon name="edit" size="xs" tone="secondary" />
              </>
            ) : (
              <>
                <Icon name="users-three" size="sm" tone="secondary" />
                <span className="gz-t-body-s">{t('clientVenueGuestsAdd')}</span>
              </>
            )}
          </button>
        </div>
      ) : null}

      {unavailable ? (
        <div className="gzv-date__alt" data-gz-id="venue.alternatives">
          {nearest.length > 0 ? (
            <ul className="gzv-date__chips" aria-label={t('clientVenueNearestTitle')}>
              {nearest.map(d => (
                <li key={d}>
                  <Chip iconStart="calendar" onClick={() => onPickDate(d)}>
                    <Figures text={shortDay(d)} />
                  </Chip>
                </li>
              ))}
            </ul>
          ) : null}
          <Button variant="tertiary" iconEnd="calendar" onClick={onOpenCalendar}>
            {t('clientVenueSeeAllDates')}
          </Button>
        </div>
      ) : null}

      {prices && row && (status === 'available' || status === 'held') ? (
        <div className="gzv-date__money" data-gz-id="venue.money">
          <PriceBlock prices={prices} guest={guest} owned={owned} onHow={prices.eligible ? onHow : undefined} />
          {row.belowMinimum || (prices.eligible && windowTitle) ? (
            <FactRow className="gzv-date__facts">
              {row.belowMinimum ? <FactChip icon="users-three" value={`${f.integer(row.minGuests)}+`} label={t('clientVenueEstimateMinimum', { guests: guestsText(row.minGuests) })} tone="accent" /> : null}
              {prices.eligible && windowTitle ? (
                <span data-gz-id="venue.window">
                  <FactChip icon="percent" value={windowTitle} label={t('clientVenueWindowApplied', { title: windowTitle })} tone="accent" />
                </span>
              ) : null}
            </FactRow>
          ) : null}
        </div>
      ) : null}
    </section>
  )
}

/** The slim bar that appears under the top bar once the strip has scrolled away: date, availability, change. It is a zero-height pinned anchor; the bar mounts only while visible. */
export function DateStripCompact({ date, status, onPress, visible, top }: { date: IsoDate | null; status: DayStatusKind; onPress: () => void; visible: boolean; top: number }) {
  const t = useT('client-venue')
  const { lang } = useLang()
  const shortDay = useShortDay()
  return (
    <div className="gzv-compact" style={{ insetBlockStart: top }} data-gz="DateStripCompact">
      {visible ? (
        <div className="gzv-compact__bar gz-fade-in">
          <button type="button" className="gz-reset gz-press gzv-compact__btn" onClick={onPress} aria-label={t('clientVenueDateChangeLabel')}>
            <Icon name="calendar" size="sm" tone="secondary" />
            <span className="gzv-compact__date gz-t-body-s" lang={lang}>
              {date ? <Figures text={shortDay(date)} /> : t('clientVenueDateChoose')}
            </span>
            {status === 'available' ? <StatusPill status="available" /> : null}
            {status === 'held' ? <StatusPill status="held" /> : null}
            {status === 'unavailable' ? <StatusPill status="unavailable" /> : null}
            <Icon name="chevron-down" size="sm" tone="secondary" />
          </button>
        </div>
      ) : null}
    </div>
  )
}
