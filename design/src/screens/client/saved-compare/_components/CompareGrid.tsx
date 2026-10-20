// The compare table (ADR 0009, direction section 3 "Compare") as this flow draws it, in glyphs and figures (ADR 0034): three fluid thirds, no
// label column, no row labels, no sideways scroll. A row is one fact in three cells and each cell carries its own glyph (`[users] 650`,
// `[route] 18 m`, a valet glyph with a check), so the row says what it is without a word; the words are the cells' and rows' accessible names.
// "Differences" is a two-glyph segmented control (differences | all) with the hidden-row count beside it. Best in row is the gold bead on
// objective rows (price, capacity best fit, rating, distance) and a glyph badge under the hall's name. Range bars stay (price; capacity with
// the tick at your guests). The header hands over to the compact pinned strip once it has scrolled away (two layers, so nothing shifts
// under the thumb while the header collapses). Built from the system's CompareParts; the header and the row are local because the system
// ones carry a visible label, no tap-to-open and no pick control (request filed). The bottom bar is `CompareBar` below.
// Voucher model (ADR 0033): the Price cell is the voucher price (bead on the lowest, a lock pair for a signed-out visitor), the standard
// price struck beside it and the saving as a trend glyph and the amount; no deposit row; the footer reads Voucher, Dates, Official, View or Remove.
import { Fragment, useEffect, useRef, useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import type { Brief, CompareColumn } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import {
  Badge, BestInRow, Button, CompareHeader, FactChip, Icon, IconButton, IconSegmented, Monogram, Photo, Price, RangeBar, Rating, StatusPill,
  imageSrc, useBi,
} from '../../../../system'
import { getArea } from '../../../../mock'
import { Fx } from './Fx'
import { actionFor, amenityState, badgeFor, describe, hallSetting, packageList, winners, type ActionKind, type ColumnInfo } from './compare-model'
import './compare-grid.css'

type RowDef = { id: string; label: string; cells: ReactNode[]; keys: string[]; always?: boolean }

export type CompareGridProps = {
  columns: readonly CompareColumn[]
  brief: Brief
  /** Name of the reference point in "Drive from Salmiya" (the distance cell's accessible name). */
  origin: string
  unlistedId?: string | null
  pickedId: string | null
  onPick: (venueId: string) => void
  onRemove: (venueId: string) => void
  onOpen: (venueId: string) => void
  onGallery: (venueId: string, index: number) => void
  onSetDate: () => void
  /** Signed out: the voucher price shows with a lock glyph (the saving is the pitch, registration unlocks the voucher). */
  audience?: 'member' | 'guest'
  diff: boolean
  onDiffChange: (next: boolean) => void
}

/** A cell mark: a glyph that is the whole value (a check, a coin, a dash), named for assistive technology. */
function Mark({ icon, label, tone = 'secondary' }: { icon: IconName; label: string; tone?: 'secondary' | 'success' | 'primary' | 'accent' }) {
  return (
    <span className="svd-cmark" role="img" aria-label={label}>
      <Icon name={icon} size="sm" tone={tone} />
    </span>
  )
}

/** A facility cell: the facility's glyph and its state mark (included = check, extra cost = coins, not offered = a quiet dash). */
function Facility({ icon, state, label, texts }: { icon: IconName; state: 'included' | 'extra' | 'not_offered'; label: string; texts: { included: string; extra: string; not_offered: string } }) {
  return (
    <span className="svd-cfac" role="img" aria-label={`${label}: ${texts[state]}`}>
      <Icon name={icon} size="sm" tone={state === 'not_offered' ? 'disabled' : 'primary'} />
      <Icon name={state === 'included' ? 'check' : state === 'extra' ? 'coins' : 'minus'} size="xs" tone={state === 'included' ? 'success' : state === 'extra' ? 'accent' : 'disabled'} />
    </span>
  )
}

function Row({ label, cells, owners, className }: { label: string; cells: readonly ReactNode[]; owners: readonly string[]; className?: string }) {
  return (
    <div data-gz="CompareRow" className={`gz-cmpr svd-row4${className ? ` ${className}` : ''}`} role="group" aria-label={label}>
      <div className="gz-cmpr__cells">
        {cells.map((c, i) => (
          <div key={i} className="gz-cmpr__cell gz-t-body-s" role="group" aria-label={owners[i]}>
            {c}
          </div>
        ))}
      </div>
    </div>
  )
}

export function CompareGrid({ columns, brief, origin, unlistedId, pickedId, onPick, onRemove, onOpen, onGallery, onSetDate, audience = 'member', diff, onDiffChange }: CompareGridProps) {
  const t = useT('client-saved-compare')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()
  const { lang } = useLang()
  const infos = describe(columns, unlistedId)
  const win = winners(infos, brief)
  const guests = brief.guests ?? null
  const hasDate = Boolean(brief.date)
  const [showPackages, setShowPackages] = useState(false)

  // ---- the header hands over to the compact strip once it has scrolled out of the top of the screen body
  const headRef = useRef<HTMLDivElement>(null)
  const [stuck, setStuck] = useState(false)
  useEffect(() => {
    const el = headRef.current
    if (!el || typeof IntersectionObserver === 'undefined') return
    const root = el.closest<HTMLElement>('.gz-screen__body')
    const io = new IntersectionObserver(
      ([e]) => e && setStuck(!e.isIntersecting && e.boundingClientRect.top < (e.rootBounds?.top ?? 0)),
      { root, threshold: 0 },
    )
    io.observe(el)
    return () => io.disconnect()
  }, [])

  const dash = <span className="gz-cmpr__dash" aria-hidden="true">—</span>
  const names = infos.map(i => (i.kind === 'unlisted' ? t('clientSavedCompareSavedUnlisted') : bi(i.col.venue.name)))
  const each = (fn: (i: ColumnInfo) => ReactNode): ReactNode[] => infos.map(fn)
  const keyed = (fn: (i: ColumnInfo) => string): string[] => infos.map(fn)

  const maxPrice = Math.max(1, ...infos.map(i => (i.priced ? (i.col.price?.fils ?? 0) : 0)))
  const maxCap = Math.max(1, ...infos.map(i => i.col.maxGuests), guests ?? 0)
  const best = (on: boolean, node: ReactNode) => (on ? <BestInRow>{node}</BestInRow> : node)
  const perGuest = <FactChip icon="per-guest" size="sm" tone="muted" label={c('commonUnitPerGuest')} />

  const rows: RowDef[] = []
  const add = (r: RowDef) => rows.push(r)

  // ---- availability on the Brief date: a status pill (glyph + one word), the only words on the table's face
  add({
    id: 'availability', label: t('clientSavedCompareCompareRowAvailability'),
    cells: each(i => {
      if (i.kind !== 'normal' || !hasDate || !i.col.availability) return dash
      return i.booked ? <StatusPill status="booked" /> : i.held ? <StatusPill status="held" /> : <StatusPill status="available" label={c('commonAvailabilityFree')} />
    }),
    keys: keyed(i => `${i.kind}|${i.col.availability}`),
  })

  // ---- price: the voucher price (headline), the standard price struck beside it, the saving; or the per-guest rates without a date
  const lock = audience === 'guest'
  if (hasDate) {
    add({
      id: 'price', label: t('clientSavedCompareCompareRowPrice'),
      cells: each(i => {
        if (i.kind !== 'normal' || i.booked || i.held || !i.col.price) return dash
        const standard = i.col.price.fils
        const voucher = i.col.voucherPrice
        if (!voucher) return <Price fils={standard} size="strong" />
        return (
          <>
            {best(win.price.has(i.col.venue.id), <Price fils={voucher.fils} size="strong" was={standard} />)}
            <RangeBar decorative value={voucher.fils} max={maxPrice} label={f.money(voucher.fils)} />
            {i.col.savings ? (
              <span className="gz-cmpr__fact svd-save">
                <Icon name="trend-down" size="xs" tone="success" mirror={false} />
                <span className="gz-sr-only">{c('commonYouSave', { amount: f.money(i.col.savings.fils, { mode: 'browse' }) })}</span>
                <span aria-hidden="true">
                  <Price fils={i.col.savings.fils} size="card" />
                </span>
              </span>
            ) : null}
            {lock ? (
              <span className="svd-lockpair">
                <Icon name="ticket" size="xs" tone="secondary" />
                <Icon name="lock" size="xs" tone="secondary" />
                <span className="gz-sr-only">{c('commonLabelGuestVoucher')}</span>
              </span>
            ) : null}
          </>
        )
      }),
      keys: keyed(i => `${i.kind}|${i.booked}|${i.held}|${i.col.price?.fils ?? '-'}|${i.col.voucherPrice?.fils ?? '-'}`),
      always: true,
    })
  } else {
    add({
      id: 'priceFrom', label: t('clientSavedCompareCompareRowPriceFrom'),
      cells: each(i => {
        const standard = i.col.fromPerGuest
        const rate = i.col.fromVoucherPerGuest ?? standard
        if (i.kind !== 'normal' || !rate) return dash
        // "From" stays (a from-price must say it); then the per-guest glyph and the money, the standard rate struck beside a voucher rate.
        return (
          <>
            <span className="svd-from gz-t-caption">{t('clientSavedCompareCompareValFrom')}</span>
            <span className="svd-rate">
              {perGuest}
              <Price fils={rate.fils} size="strong" className="svd-rate__price" was={i.col.fromVoucherPerGuest && standard ? standard.fils : undefined} />
            </span>
          </>
        )
      }),
      keys: keyed(i => `${i.col.fromVoucherPerGuest?.fils ?? i.col.fromPerGuest?.fils ?? '-'}`),
      always: true,
    })
  }

  // ---- capacity: the largest hall, a bar with the tick at your guests
  add({
    id: 'capacity', label: t('clientSavedCompareCompareRowCapacity'),
    cells: each(i => {
      if (i.kind === 'unlisted') return dash
      return (
        <>
          {best(win.fit.has(i.col.venue.id), <FactChip icon="users-three" label={t('clientSavedCompareCompareRowCapacity')} value={f.integer(i.col.maxGuests)} />)}
          <RangeBar decorative value={i.col.maxGuests} max={maxCap} mark={guests ?? undefined} markLabel={guests ? f.integer(guests) : undefined} label={f.guests(i.col.maxGuests)} />
          {guests && !i.col.fits ? <Mark icon="warning-circle" label={t('clientSavedCompareCompareValBelow')} /> : null}
        </>
      )
    }),
    keys: keyed(i => `${i.col.maxGuests}|${i.col.fits}`),
    always: true,
  })
  add({
    id: 'setting', label: t('clientSavedCompareCompareRowSetting'),
    cells: each(i => {
      if (i.kind === 'unlisted') return dash
      const s = hallSetting(i)
      return (
        <span className="svd-cfac" role="img" aria-label={s === 'indoor' ? t('clientSavedCompareCompareValIndoor') : s === 'outdoor' ? t('clientSavedCompareCompareValOutdoor') : `${t('clientSavedCompareCompareValIndoor')}, ${t('clientSavedCompareCompareValOutdoor')}`}>
          {s !== 'outdoor' ? <Icon name="hall" size="sm" tone="primary" /> : null}
          {s !== 'indoor' ? <Icon name="garden" size="sm" tone="primary" /> : null}
        </span>
      )
    }),
    keys: keyed(i => (i.kind === 'unlisted' ? '-' : hallSetting(i))),
  })

  // ---- facilities: the facility's glyph and a state mark
  const texts = { included: t('clientSavedCompareCompareValIncluded'), extra: t('clientSavedCompareCompareValExtra'), not_offered: t('clientSavedCompareCompareValNotOffered') }
  const facility = (id: string, label: string, icon: IconName, amenity: string) =>
    add({
      id, label,
      cells: each(i => {
        const s = amenityState(i, amenity)
        return s === null ? dash : <Facility icon={icon} state={s} label={label} texts={texts} />
      }),
      keys: keyed(i => `${amenityState(i, amenity)}`),
    })
  facility('valet', t('clientSavedCompareCompareRowValet'), 'valet', 'valet')
  facility('parking', t('clientSavedCompareCompareRowParking'), 'parking', 'parking')
  facility('bridal', t('clientSavedCompareCompareRowBridal'), 'dress', 'bridal-suite')
  facility('buffet', t('clientSavedCompareCompareRowBuffet'), 'buffet', 'buffet')
  add({
    id: 'photography', label: t('clientSavedCompareCompareRowPhotography'),
    cells: each(i => {
      if (i.kind === 'unlisted' || i.col.photography === null) return dash
      const p = i.col.photography
      return (
        <span className="svd-cfac" role="img" aria-label={`${t('clientSavedCompareCompareRowPhotography')}: ${p === 'female_only' ? t('clientSavedCompareCompareValWomenOnly') : p === 'allowed' ? t('clientSavedCompareCompareValAllowed') : t('clientSavedCompareCompareValNotAllowed')}`}>
          <Icon name="camera" size="sm" tone={p === 'none' ? 'disabled' : 'primary'} />
          <Icon name={p === 'female_only' ? 'section-women' : p === 'allowed' ? 'check' : 'minus'} size="xs" tone={p === 'allowed' ? 'success' : p === 'none' ? 'disabled' : 'secondary'} />
        </span>
      )
    }),
    keys: keyed(i => `${i.kind}|${i.col.photography}`),
  })

  // ---- rating and distance: figures with their own glyph
  add({
    id: 'rating', label: t('clientSavedCompareCompareRowRating'),
    cells: each(i => (i.kind !== 'normal' || i.col.rating.average === null ? dash : best(win.rated.has(i.col.venue.id), <Rating value={i.col.rating.average} count={i.col.rating.count} />))),
    keys: keyed(i => `${i.col.rating.average}|${i.col.rating.count}`),
    always: true,
  })
  add({
    id: 'distance', label: t('clientSavedCompareCompareRowDistance', { origin }),
    cells: each(i => {
      if (i.kind === 'unlisted' || !i.col.distance) return dash
      return best(win.nearest.has(i.col.venue.id), <FactChip icon="route" label={t('clientSavedCompareCompareRowDistance', { origin })} value={<Fx text={t('clientSavedCompareCompareDriveMinutes', { minutes: i.col.distance.minutes })} />} />)
    }),
    keys: keyed(i => `${i.col.distance?.minutes ?? '-'}`),
  })

  // ---- packages: how many; the chevron under the row opens their names (the lowest per-guest rate lives in the no-date price row)
  add({
    id: 'packages', label: t('clientSavedCompareCompareRowPackages'),
    cells: each(i =>
      i.kind !== 'normal' || i.col.packages.count === 0 ? dash : <FactChip icon="package" label={t('clientSavedCompareCompareRowPackages')} value={f.integer(i.col.packages.count)} />,
    ),
    keys: keyed(i => `${i.col.packages.count}`),
  })
  if (showPackages) {
    add({
      id: 'packagesList', label: t('clientSavedCompareCompareRowPackages'),
      cells: each(i =>
        i.kind !== 'normal' ? dash : (
          <ul className="svd-pkglist">
            {packageList(i).map(p => (
              <li key={p.id} className="gz-t-caption" lang={lang}>
                {bi(p.name)}
              </li>
            ))}
          </ul>
        ),
      ),
      keys: keyed(i => i.col.venue.id),
      always: true,
    })
  }

  // ---- how you book: a glyph (voucher, official channel, standard price only)
  add({
    id: 'how', label: t('clientSavedCompareCompareRowHow'),
    cells: each(i => {
      if (i.kind === 'unlisted') return dash
      if (i.kind === 'official') return <Mark icon="bank" label={t('clientSavedCompareCompareValHowOfficial')} tone="primary" />
      return i.col.voucherPrice || i.col.packages.fromVoucher ? <Mark icon="ticket" label={t('clientSavedCompareCompareValHowVoucher')} tone="primary" /> : <Mark icon="minus" label={t('clientSavedCompareCompareValHowStandard')} />
    }),
    keys: keyed(i => `${i.kind}|${Boolean(i.col.voucherPrice || i.col.packages.fromVoucher)}`),
  })

  // ---- photos: three strips per hall that open the gallery
  add({
    id: 'photos', label: t('clientSavedCompareCompareRowPhotos'),
    cells: each(i => {
      const shots = i.kind === 'unlisted' ? [] : i.col.venue.gallery.slice(1, 4)
      return shots.length === 0 ? (
        dash
      ) : (
        <span className="svd-strips">
          {shots.map((s, k) => (
            <button key={s.file} type="button" className="gz-reset svd-strip gz-press" aria-label={bi(s.alt)} onClick={() => onGallery(i.col.venue.id, k + 1)}>
              <Photo src={imageSrc(s.file)} alt="" className="svd-strip__photo" priority />
            </button>
          ))}
        </span>
      )
    }),
    keys: keyed(i => i.col.venue.id),
    always: true,
  })

  const same = (r: RowDef) => !r.always && r.keys.length > 1 && r.keys.every(k => k === r.keys[0])
  const hidden = rows.filter(same).length
  const shown = diff ? rows.filter(r => !same(r)) : rows

  // ---- the expanded header
  const headers = infos.map(i => {
    const v = i.col.venue
    const area = getArea(v.areaId)
    const badge = badgeFor(v.id, win)
    const picked = pickedId === v.id
    const unlisted = i.kind === 'unlisted'
    const name = bi(v.name)
    const badgeIcon = badge === 'lowest' ? 'offer' : badge === 'closest' ? 'navigate' : 'star-fill'
    const badgeName = badge === 'lowest' ? t('clientSavedCompareCompareBadgeLowest') : badge === 'closest' ? t('clientSavedCompareCompareBadgeClosest') : t('clientSavedCompareCompareBadgeRated')
    return (
      <div key={v.id} className="gz-cmph__col svd-head__col" data-gz-id={`head.${v.id}`}>
        <div className={`gz-cmph__thumb svd-head__thumb${picked ? ' is-picked' : ''}`}>
          {v.cover && !unlisted ? <Photo src={imageSrc(v.cover.file)} alt="" className="gz-cmph__photo" /> : <Monogram size="sm" />}
          {unlisted ? null : <button type="button" className="gz-reset svd-head__open" aria-label={t('clientSavedCompareCompareOpen', { name })} onClick={() => onOpen(v.id)} />}
          <button type="button" className="gz-reset gz-cmph__remove" aria-label={t('clientSavedCompareTrayRemove', { name })} onClick={() => onRemove(v.id)}>
            <span className="gz-cmph__x" aria-hidden="true">
              <Icon name="close" size="xs" />
            </span>
          </button>
          {unlisted ? null : (
            <button
              type="button"
              className="gz-reset svd-head__pick gz-press"
              role="checkbox"
              aria-checked={picked}
              aria-label={picked ? t('clientSavedCompareCompareUnpick', { name }) : t('clientSavedCompareComparePick', { name })}
              onClick={() => onPick(v.id)}
            >
              <span className={`svd-head__disk${picked ? ' is-on' : ''}`}>
                <Icon name="check" size="xs" />
              </span>
            </button>
          )}
        </div>
        <div className="gz-cmph__text svd-head__text">
          {unlisted ? (
            <span className="gz-cmph__name gz-t-compare-name gz-clamp-3" lang={lang}>
              {t('clientSavedCompareSavedUnlisted')}
            </span>
          ) : (
            <button type="button" className="gz-reset svd-head__name gz-t-compare-name gz-clamp-3" lang={lang} onClick={() => onOpen(v.id)}>
              {name}
            </button>
          )}
          {!unlisted && area ? <span className="gz-cmph__area gz-t-caption">{bi(area.name)}</span> : null}
          {!unlisted && badge ? (
            <Badge variant="outline" bead={false} icon={badgeIcon}>
              <span className="gz-sr-only">{badgeName}</span>
            </Badge>
          ) : (
            <span className="svd-head__slot" aria-hidden="true" />
          )}
        </div>
      </div>
    )
  })

  return (
    <div className="svd-grid" data-gz="CompareGrid">
      {/* the compact strip: zero height, pinned, shown while the header above is out of view */}
      <div className="svd-pin" aria-hidden={!stuck}>
        <div className={`svd-pin__inner${stuck ? ' is-on' : ''}`} data-gz-id="head.compact">
          <CompareHeader
            compact
            columns={infos.map(i => ({ venue: i.col.venue, unlisted: i.kind === 'unlisted' }))}
          />
        </div>
      </div>
      <div ref={headRef} className="gz-cmph svd-head" data-gz-id="head.expanded">
        {headers}
      </div>
      <div className="svd-diff" data-gz="DifferencesSwitch">
        <IconSegmented
          options={[
            { value: 'diff', icon: 'compare', label: t('clientSavedCompareCompareDiffOnly') },
            { value: 'all', icon: 'list', label: t('clientSavedCompareCompareDiffAll') },
          ]}
          value={diff ? 'diff' : 'all'}
          onChange={v => onDiffChange(v === 'diff')}
          label={t('clientSavedCompareCompareDiffLabel')}
          className="svd-diff__seg"
        />
        {diff && hidden > 0 ? <FactChip icon="eye-off" tone="muted" label={t('clientSavedCompareCompareHidden', { count: hidden })} value={f.integer(hidden)} /> : null}
      </div>
      {!hasDate ? (
        <div className="svd-setdate">
          <Button variant="tertiary" iconStart="calendar-plus" onClick={onSetDate}>
            {t('clientSavedCompareCompareSetDate')}
          </Button>
        </div>
      ) : null}
      {shown.map(r => (
        <Fragment key={r.id}>
          <Row label={r.label} cells={r.cells} owners={names} />
          {r.id === 'packages' ? (
            <div className="svd-expand">
              <IconButton
                icon={showPackages ? 'chevron-up' : 'chevron-down'}
                label={showPackages ? t('clientSavedCompareCompareHidePackages') : t('clientSavedCompareCompareShowPackages')}
                aria-expanded={showPackages}
                onClick={() => setShowPackages(s => !s)}
              />
            </div>
          ) : null}
        </Fragment>
      ))}
    </div>
  )
}

// ---------------------------------------------------------------- the pinned action bar
export type CompareBarProps = {
  columns: readonly CompareColumn[]
  brief: Brief
  unlistedId?: string | null
  pickedId: string | null
  onAction: (venueId: string, kind: ActionKind) => void
}

/**
 * Three 48 outline buttons aligned to the thirds, one word each (the hall's name is the button's accessible name, not a line above it: the
 * pinned strip carries the names once the header has scrolled away), one gold primary only after a hall is picked (ADR 0009 D8). Never Request or Book.
 */
export function CompareBar({ columns, brief, unlistedId, pickedId, onAction }: CompareBarProps) {
  const t = useT('client-saved-compare')
  const c = useT('common')
  const bi = useBi()
  const infos = describe(columns, unlistedId)
  const label = {
    voucher: t('clientSavedCompareCompareActionVoucher'),
    dates: t('clientSavedCompareCompareActionDates'),
    official: t('clientSavedCompareCompareActionOfficial'),
    view: t('clientSavedCompareCompareActionView'),
    remove: c('commonActionRemove'),
  } as const
  const kinds = new Map(infos.map(i => [i.col.venue.id, actionFor(i, brief)]))
  const icon = { voucher: 'ticket', dates: 'calendar', official: undefined, view: undefined, remove: undefined } as const
  return (
    <div className="svd-bar" data-gz="CompareBar">
      <div className="gz-cmpa" role="group">
        {infos.map(i => {
          const id = i.col.venue.id
          const kind = kinds.get(id) ?? 'view'
          const name = i.kind === 'unlisted' ? t('clientSavedCompareSavedUnlisted') : bi(i.col.venue.name)
          return (
            <div key={id} className="gz-cmpa__col" data-gz-id={`action.${id}`}>
              <Button
                variant={pickedId === id ? 'primary' : 'secondary'}
                size="md"
                fullWidth
                iconStart={icon[kind]}
                className="gz-cmpa__btn"
                aria-label={t('clientSavedCompareCompareActionFor', { action: label[kind], name })}
                onClick={() => onAction(id, kind)}
              >
                {label[kind]}
              </Button>
            </div>
          )
        })}
      </div>
    </div>
  )
}
