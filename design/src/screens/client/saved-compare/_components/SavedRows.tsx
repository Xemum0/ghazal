// The rows of the Saved tab (CL-SAVD-01): one row language for halls, services and packages. 72 x 88 thumbnail, serif name, one quiet meta
// line (area, then the availability glyph), the price line, a heart at the end (or a selection mark at the start in select mode).
// Unframed, hairline between rows, the whole row is the target and the heart sits above it.
// Text diet (ADR 0034): no availability sentence (a glyph in a tone disk; the Brief date is stated once, above the list), no "Voucher
// ready" sentence (a ticket glyph under the heart), no tagline, no "No longer listed" sentence (a glyph and one word). Flow-local because the
// system compact card has no availability glyph, no selection mode and no unlisted state (request filed).
// Voucher model (ADR 0033): the price line is the voucher price with the standard price struck beside it (CardPriceLine).
import type { ReactNode } from 'react'
import type { CardPrice, Package, PlannerPackage, ServiceProvider, Venue, Voucher } from '../../../../mock'
import { getArea } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import {
  Button, CardPriceLine, FactChip, Figures, Icon, IconButton, Monogram, Photo, Price, PriceCompare, Rating, Skeleton, StatusIcon,
  ThreadBead, imageSrc, useBi,
} from '../../../../system'
import './saved-rows.css'

type Shell = {
  thumb: ReactNode
  children: ReactNode
  aside?: ReactNode
  /** Select mode: a mark at inline-start, the row toggles it. */
  selecting?: boolean
  selected?: boolean
  openLabel: string
  onOpen?: () => void
  muted?: boolean
}

function Row({ thumb, children, aside, selecting, selected, openLabel, onOpen, muted }: Shell) {
  return (
    <li className={`svd-row${selected ? ' is-selected' : ''}${muted ? ' is-muted' : ''}`} data-gz="SavedRow">
      {selecting ? (
        <span className={`svd-mark${selected ? ' is-on' : ''}`} aria-hidden="true">
          {selected ? <Icon name="check" size="xs" /> : null}
        </span>
      ) : null}
      <div className="svd-row__thumb">{thumb}</div>
      <div className="svd-row__body">{children}</div>
      {aside && !selecting ? <div className="svd-row__aside">{aside}</div> : null}
      <button type="button" className="gz-reset svd-row__open" aria-label={openLabel} aria-pressed={selecting ? Boolean(selected) : undefined} onClick={onOpen} />
    </li>
  )
}

const Ghost = () => (
  <span className="svd-row__ghost">
    <Monogram size="sm" />
  </span>
)

// ---------------------------------------------------------------- hall
export type SavedVenueRowProps = {
  venue: Venue
  price: CardPrice | null
  /** The Brief date, when there is one: the availability glyph is omitted without it (no empty promise). */
  date?: string | null
  availability?: 'available' | 'held' | 'unavailable' | 'closed' | 'unknown' | null
  /** The standard price moved since the family last looked, so the voucher saving is not what they saw. */
  savingChanged?: boolean
  /** A paid voucher the client holds for this hall: the ticket glyph under the heart that opens it. */
  voucher?: Voucher | null
  onOpenVoucher?: () => void
  /** Signed out: the voucher price stays visible but locked (ADR 0007 D8). */
  unlisted?: boolean
  selecting?: boolean
  selected?: boolean
  onOpen?: () => void
  onRemove?: () => void
}

export function SavedVenueRow({ venue, price, date, availability, savingChanged, voucher, onOpenVoucher, unlisted, selecting, selected, onOpen, onRemove }: SavedVenueRowProps) {
  const t = useT('client-saved-compare')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()
  const { lang } = useLang()
  const name = bi(venue.name)
  const area = getArea(venue.areaId)

  if (unlisted) {
    return (
      <Row
        muted
        thumb={<Ghost />}
        openLabel={name}
        aside={
          <Button variant="tertiary" onClick={onRemove}>
            {c('commonActionRemove')}
          </Button>
        }
      >
        <h3 className="svd-row__name gz-t-d1 gz-clamp-2" lang={lang}>
          {name}
        </h3>
        <p className="svd-row__meta gz-t-caption">
          <Icon name="eye-off" size="xs" tone="secondary" />
          <span>{t('clientSavedCompareSavedUnlisted')}</span>
        </p>
      </Row>
    )
  }

  // Free = a check, on hold = an hourglass, taken = a crossed calendar; the sentence (with the date) is the accessible name.
  const showAvail = Boolean(date) && availability && availability !== 'unknown' && availability !== 'closed'
  const availStatus = availability === 'available' ? 'available' : availability === 'held' ? 'held' : 'unavailable'
  const availName =
    !date || !availability
      ? ''
      : availability === 'available'
        ? t('clientSavedCompareSavedAvailFree', { date: f.date(date, 'dayMonth') })
        : availability === 'held'
          ? t('clientSavedCompareSavedAvailHeld')
          : t('clientSavedCompareSavedAvailBooked', { date: f.date(date, 'dayMonth') })

  return (
    <Row
      selecting={selecting}
      selected={selected}
      openLabel={selecting ? t(selected ? 'clientSavedCompareSavedDeselectRow' : 'clientSavedCompareSavedSelectRow', { name }) : name}
      onOpen={onOpen}
      thumb={venue.cover ? <Photo src={imageSrc(venue.cover.file)} alt="" className="svd-row__photo" /> : <Ghost />}
      aside={
        <>
          <IconButton icon="heart" iconActive="heart-fill" active label={c('commonA11yFavouriteRemove')} onClick={onRemove} />
          {voucher ? (
            <button type="button" className="gz-reset svd-vtag gz-press" aria-label={t('clientSavedCompareSavedVoucherReadyOpen', { name })} onClick={onOpenVoucher}>
              <StatusIcon status="voucher_active" size="sm" />
            </button>
          ) : null}
        </>
      }
    >
      <h3 className="svd-row__name gz-t-d1 gz-clamp-2" lang={lang}>
        {name}
      </h3>
      <div className="svd-row__meta gz-t-caption">
        {area ? <span>{bi(area.name)}</span> : null}
        {showAvail ? <StatusIcon status={availStatus} label={availName} size="sm" /> : null}
        {savingChanged ? <FactChip icon="trend-down" tone="accent" size="sm" label={t('clientSavedCompareSavedSavingChanged')} /> : null}
      </div>
      {price ? <CardPriceLine price={price} /> : null}
    </Row>
  )
}

// ---------------------------------------------------------------- service
export type SavedVendorRowProps = {
  vendor: ServiceProvider
  onOpen?: () => void
  onRemove?: () => void
}

export function SavedVendorRow({ vendor, onOpen, onRemove }: SavedVendorRowProps) {
  const t = useT('client-saved-compare')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()
  const { lang } = useLang()
  const name = bi(vendor.name)
  const area = getArea(vendor.areaId)
  const shot = vendor.portfolio[0]
  // Two prices on the same basis; a voucher is only sold when the saving beats the fee, so a small saving shows the standard price alone.
  const voucher = vendor.fromVoucher && vendor.fromVoucher.fils < vendor.from.fils ? vendor.fromVoucher : null
  const saving = voucher ? vendor.from.fils - voucher.fils : 0
  const showVoucher = voucher !== null
  return (
    <Row
      openLabel={name}
      onOpen={onOpen}
      thumb={shot ? <Photo src={imageSrc(shot.file)} alt="" className="svd-row__photo" /> : <Ghost />}
      aside={<IconButton icon="heart" iconActive="heart-fill" active label={c('commonA11yFavouriteRemove')} onClick={onRemove} />}
    >
      <h3 className="svd-row__name gz-t-d1 gz-clamp-2" lang={lang}>
        {name}
      </h3>
      <div className="svd-row__meta gz-t-caption">
        {area ? <span>{bi(area.name)}</span> : null}
        {vendor.rating ? <Rating value={vendor.rating.average} count={vendor.rating.count} /> : <span>{c('commonLabelNew')}</span>}
      </div>
      <span className="svd-row__price" data-gz="ServicePriceLine" data-voucher={showVoucher ? '' : undefined}>
        <Price
          fils={showVoucher && voucher ? voucher.fils : vendor.from.fils}
          size="card"
          prefix={t('clientSavedCompareSavedFrom')}
          was={showVoucher ? vendor.from.fils : undefined}
        />
        <span className="svd-row__basis gz-t-caption">{bi(vendor.fromUnit)}</span>
        {showVoucher ? (
          <span className="svd-chip gz-t-pill">
            <Icon name="trend-down" size="xs" mirror={false} />
            <span className="gz-sr-only">{c('commonSaveAmount', { amount: f.money(saving, { mode: 'browse' }) })}</span>
            <span aria-hidden="true">
              <Figures text={f.money(saving, { mode: 'browse' })} />
            </span>
          </span>
        ) : null}
      </span>
    </Row>
  )
}

// ---------------------------------------------------------------- package (a hall package, or a planner tier)
export type SavedPackageRowProps =
  | { kind: 'hall'; pkg: Package; venue: Venue; onOpen?: () => void; onRemove?: () => void }
  | { kind: 'planner'; pkg: PlannerPackage; onOpen?: () => void; onRemove?: () => void }

export function SavedPackageRow(props: SavedPackageRowProps) {
  const t = useT('client-saved-compare')
  const c = useT('common')
  const bi = useBi()
  const { lang } = useLang()
  if (props.kind === 'planner') {
    const { pkg } = props
    return (
      <Row
        openLabel={bi(pkg.name)}
        onOpen={props.onOpen}
        thumb={<Photo src={imageSrc(pkg.image.file)} alt="" className="svd-row__photo" />}
        aside={<IconButton icon="heart" iconActive="heart-fill" active label={c('commonA11yFavouriteRemove')} onClick={props.onRemove} />}
      >
        <h3 className="svd-row__name gz-t-d1 gz-clamp-2" lang={lang}>
          {bi(pkg.name)}
        </h3>
        <div className="svd-row__meta gz-t-caption">
          <span>{t('clientSavedCompareSavedPlannerLabel')}</span>
          <span className="svd-row__marks" aria-hidden="true">
            {Array.from({ length: pkg.marks }, (_, i) => (
              <ThreadBead key={i} tone="gold" />
            ))}
          </span>
        </div>
        <span className="svd-row__price">
          <Price fils={pkg.from.fils} size="card" prefix={t('clientSavedCompareSavedFrom')} />
        </span>
      </Row>
    )
  }
  const { pkg, venue } = props
  return (
    <Row
      openLabel={bi(pkg.name)}
      onOpen={props.onOpen}
      thumb={venue.cover ? <Photo src={imageSrc(venue.cover.file)} alt="" className="svd-row__photo" /> : <Ghost />}
      aside={<IconButton icon="heart" iconActive="heart-fill" active label={c('commonA11yFavouriteRemove')} onClick={props.onRemove} />}
    >
      <h3 className="svd-row__name gz-t-d1 gz-clamp-2" lang={lang}>
        {bi(pkg.name)}
      </h3>
      <div className="svd-row__meta gz-t-caption">
        <span>{bi(venue.name)}</span>
      </div>
      <PriceCompare variant="inline" standard={pkg.standardFils} voucher={pkg.voucherFils} structure={pkg.priceStructure} showNet={false} />
    </Row>
  )
}

// ---------------------------------------------------------------- loading
export function SavedRowSkeleton() {
  return (
    <li className="svd-row svd-row--skeleton" aria-hidden="true">
      <Skeleton variant="block" inlineSize={72} blockSize={88} />
      <div className="svd-row__body">
        <Skeleton inlineSize={160} blockSize={28} />
        <Skeleton inlineSize={96} blockSize={20} />
        <Skeleton inlineSize={176} blockSize={24} />
      </div>
    </li>
  )
}
