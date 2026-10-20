// CompareTable (CL-SAVD compare, ADR 0009 D4-D9): the three halls side by side in fluid thirds, built from CompareParts. Rows come from
// `compareSet()` (voucher price, standard price and the saving for the Brief date and guests, per guest, capacity with the tick at your guests, facilities, rating,
// distance, packages, how you book, photos). Objective rows carry the Best-in-row bead; the header carries one outline badge per
// hall (Best rated, Lowest price, Closest); "Differences only" hides rows where all three values match and says how many.
// Copy budget: cells stay within 14 characters in English and 12 in Arabic; anything longer would live behind an expandable row.
import { useMemo, useState, type ReactNode } from 'react'
import type { Brief, CompareColumn } from '@gz/contracts'
import { useFormat, useT } from '../../i18n'
import { Icon, Price, Rating, StatusPill } from '../core'
import { Photo, imageSrc } from '../overlays'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import {
  BestInRow, CompareActionBar, CompareBand, CompareHeader, CompareRow, DifferencesToggle, RangeBar,
  type CompareActionColumn,
} from './CompareParts'

const useW = defineWords({
  gYourDate: p('Your date', 'تاريخكم'),
  gPrice: p('Price', 'السعر'),
  gCapacity: p('Capacity and layout', 'السعة والتجهيز'),
  gFacilities: p('Facilities', 'المرافق'),
  gRating: p('Rating', 'التقييم'),
  gDistance: p('Distance', 'المسافة'),
  gBooking: p('Type and structure', 'النوع والتسعير'),
  gPhotos: p('Photos', 'الصور'),
  rAvailability: p('Availability', 'التوفر'),
  rPriceDate: p('Voucher price for your date', 'سعر الكوبون لتاريخكم'),
  rPriceFrom: p('Voucher price from', 'سعر الكوبون ابتداءً من'),
  rStandard: p('Standard price', 'السعر العادي'),
  rSavings: p('You save', 'توفّرون'),
  noVoucher: p('No voucher price', 'لا يوجد سعر كوبون'),
  rPerGuest: p('Per guest', 'للضيف'),
  rCapacity: p('Largest hall', 'أكبر قاعة'),
  rValet: p('Valet', 'فاليه'),
  rPhoto: p('Photography', 'التصوير'),
  rRating: p('Rating', 'التقييم'),
  rDistance: p('Drive from {origin}', 'المسافة من {origin}'),
  rPackages: p('Packages', 'الباقات'),
  rHow: p('Venue type', 'نوع المكان'),
  rPhotos: p('Photos', 'الصور'),
  pickDate: p('Pick a date', 'اختاروا تاريخًا'),
  included: p('Included', 'مشمول'),
  extra: p('Extra', 'برسوم إضافية'),
  notOffered: p('Not offered', 'غير متوفر'),
  womenOnly: p('Women only', 'مصوّرات فقط'),
  allowed: p('Allowed', 'مسموح'),
  noPhoto: p('Not allowed', 'غير مسموح'),
  fits: p('Fits {n}', 'تستوعب {n}'),
  yours: p('your {n}', 'عددكم {n}'),
  below: p('Below {n}', 'أقل من {n}'),
  upTo: p('Up to {n}', 'حتى {n}'),
  perGuestUnit: p('per guest', 'للضيف'),
  from: p('From', 'من'),
  getVoucher: p('Get voucher', 'الحصول على كوبون'),
  structure: p('Pricing', 'التسعير'),
  official: p('Official', 'رسمي'),
  seeDates: p('See dates', 'التواريخ'),
  bestRated: p('Best rated', 'الأعلى تقييمًا'),
  lowest: p('Lowest price', 'الأقل سعرًا'),
  closest: p('Closest', 'الأقرب'),
  typeOfficial: p('Official channel', 'القناة الرسمية'),
  perPerson: p('Per person', 'سعر للضيف'),
  packages: p('Packages', 'باقات'),
  both: p('Both', 'الاثنان'),
})

type RowDef = { id: string; group: string; label: string; cells: ReactNode[]; keys: string[] }

export type CompareTableProps = {
  columns: readonly CompareColumn[]
  brief: Brief
  /** Name of the reference point in "Drive from Salmiya". */
  origin: string
  /** The hall the couple picked (turns its action gold). */
  pickedId?: string | null
  differencesOnly?: boolean
  onDifferencesOnlyChange?: (next: boolean) => void
  compactHeader?: boolean
  onRemove?: (venueId: string) => void
  onAction?: (venueId: string) => void
  /** Pin the header and the action bar (screens). */
  pinned?: boolean
  className?: string
}

export function CompareTable({
  columns, brief, origin, pickedId = null, differencesOnly, onDifferencesOnlyChange, compactHeader, onRemove, onAction, pinned = false, className,
}: CompareTableProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const bi = useBi()
  const [inner, setInner] = useState(true)
  const diff = differencesOnly ?? inner
  const setDiff = onDifferencesOnlyChange ?? setInner
  const guests = brief.guests ?? null

  const dash = <span className="gz-cmpr__dash">—</span>
  const official = (c: CompareColumn) => c.channel === 'external_link'

  const rows = useMemo<RowDef[]>(() => {
    const maxPrice = Math.max(1, ...columns.map(c => c.voucherPrice?.fils ?? c.price?.fils ?? 0))
    const maxCap = Math.max(1, ...columns.map(c => c.maxGuests), guests ?? 0)
    const bestRated = (() => {
      const eligible = columns.filter(c => c.rating.average !== null && c.rating.count >= 5)
      if (eligible.length < 2) return null
      const top = Math.max(...eligible.map(c => c.rating.average ?? 0))
      return eligible.filter(c => c.rating.average === top).map(c => c.venue.id)
    })()
    const all = <T,>(fn: (c: CompareColumn) => T) => columns.map(fn)
    const R: RowDef[] = []
    const add = (id: string, group: string, label: string, cells: ReactNode[], keys: string[]) => R.push({ id, group, label, cells, keys })

    add('availability', w('gYourDate'), w('rAvailability'),
      all(c => {
        if (official(c)) return dash
        if (!brief.date || !c.availability) return <span className="gz-cmpr__sub">{w('pickDate')}</span>
        const s = c.availability === 'available' ? 'available' : c.availability === 'held' ? 'held' : 'unavailable'
        return <StatusPill status={s} />
      }),
      all(c => `${c.availability}`))

    add('price', w('gYourDate'), brief.date && guests ? w('rPriceDate') : w('rPriceFrom'),
      all(c => {
        const headline = c.voucherPrice ?? null
        if (official(c) || !headline) return official(c) || !c.price ? dash : <span className="gz-cmpr__sub">{w('noVoucher')}</span>
        return (
          <>
            {c.best.price ? (
              <BestInRow>
                <Price fils={headline.fils} size="strong" />
              </BestInRow>
            ) : (
              <Price fils={headline.fils} size="strong" />
            )}
            <RangeBar decorative value={headline.fils} max={maxPrice} label={f.money(headline.fils)} />
          </>
        )
      }),
      all(c => `${c.voucherPrice?.fils ?? '-'}`))

    add('standard', w('gYourDate'), w('rStandard'),
      all(c => (official(c) || !c.price ? dash : <Price fils={c.price.fils} size="card" className="gz-cmpr__quiet" />)),
      all(c => `${c.price?.fils ?? '-'}`))

    add('savings', w('gYourDate'), w('rSavings'),
      all(c => (official(c) || !c.savings ? dash : <Price fils={c.savings.fils} size="strong" />)),
      all(c => `${c.savings?.fils ?? '-'}`))

    add('perGuest', w('gPrice'), w('rPerGuest'),
      all(c =>
        official(c) || !c.fromPerGuest ? dash : (
          <>
            <Price fils={c.fromPerGuest.fils} size="strong" />
            <span className="gz-cmpr__sub gz-t-caption">{w('perGuestUnit')}</span>
          </>
        ),
      ),
      all(c => `${c.fromPerGuest?.fils ?? '-'}`))

    add('capacity', w('gCapacity'), w('rCapacity'),
      all(c => {
        const body = <span className="gz-t-fig-body-s">{c.best.fit ? <BestInRow><Figures text={w('upTo', { n: f.integer(c.maxGuests) })} /></BestInRow> : <Figures text={w('upTo', { n: f.integer(c.maxGuests) })} />}</span>
        return (
          <>
            {body}
            <RangeBar
              decorative
              value={c.maxGuests}
              max={maxCap}
              mark={guests ?? undefined}
              markLabel={guests ? w('yours', { n: f.integer(guests) }) : undefined}
              label={f.guests(c.maxGuests)}
            />
            {guests ? (
              <span className="gz-cmpr__fact gz-t-caption gz-cmpr__sub">
                <Icon name={c.fits ? 'check-circle' : 'info'} size="xs" tone={c.fits ? 'success' : 'secondary'} />
                <Figures text={c.fits ? w('fits', { n: f.integer(guests) }) : w('below', { n: f.integer(guests) })} />
              </span>
            ) : null}
          </>
        )
      }),
      all(c => `${c.maxGuests}|${c.fits}`))

    const state = (s: CompareColumn['valet']) => (s === 'included' ? w('included') : s === 'extra' ? w('extra') : w('notOffered'))
    add('valet', w('gFacilities'), w('rValet'),
      all(c =>
        c.valet === null ? dash : (
          <span className="gz-cmpr__fact">
            <Icon name={c.valet === 'included' ? 'check' : c.valet === 'extra' ? 'plus' : 'minus'} size="xs" tone={c.valet === 'included' ? 'success' : 'secondary'} />
            {state(c.valet)}
          </span>
        ),
      ),
      all(c => `${c.valet}`))

    add('photography', w('gFacilities'), w('rPhoto'),
      all(c =>
        c.photography === null ? dash : (
          <span className="gz-cmpr__fact">
            <Icon name="camera" size="xs" tone="secondary" />
            {c.photography === 'female_only' ? w('womenOnly') : c.photography === 'allowed' ? w('allowed') : w('noPhoto')}
          </span>
        ),
      ),
      all(c => `${c.photography}`))

    add('rating', w('gRating'), w('rRating'),
      all(c =>
        c.rating.average === null ? (
          <span className="gz-cmpr__sub">{t('commonLabelNew')}</span>
        ) : bestRated?.includes(c.venue.id) ? (
          <BestInRow>
            <Rating value={c.rating.average} count={c.rating.count} />
          </BestInRow>
        ) : (
          <Rating value={c.rating.average} count={c.rating.count} />
        ),
      ),
      all(c => `${c.rating.average}|${c.rating.count}`))

    add('distance', w('gDistance'), w('rDistance', { origin }),
      all(c =>
        !c.distance ? dash : (
          <>
            {c.best.nearest ? (
              <BestInRow>
                <Figures text={t('commonCountMinutes', { count: c.distance.minutes })} />
              </BestInRow>
            ) : (
              <Figures text={t('commonCountMinutes', { count: c.distance.minutes })} />
            )}
          </>
        ),
      ),
      all(c => `${c.distance?.minutes ?? '-'}`))

    add('packages', w('gBooking'), w('rPackages'),
      all(c =>
        official(c) || c.packages.count === 0 ? dash : (
          <>
            <Figures text={t('commonCountPackages', { count: c.packages.count })} />
            {c.packages.from ? (
              <span className="gz-cmpr__sub gz-t-caption">
                {w('from')} <Price fils={c.packages.from.fils} size="strong" />
              </span>
            ) : null}
          </>
        ),
      ),
      all(c => `${c.packages.count}|${c.packages.from?.fils ?? '-'}`))

    const typeKey = (c: CompareColumn) => (c.venue.type === 'hotel' ? ('commonVenueTypeHotel' as const) : c.venue.type === 'governmental' ? ('commonVenueTypeGovernmental' as const) : ('commonVenueTypePrivateHall' as const))
    add('how', w('gBooking'), w('rHow'),
      all(c => (
        <>
          <span>{t(typeKey(c))}</span>
          <span className="gz-cmpr__sub gz-t-caption">{official(c) ? w('typeOfficial') : c.structures.length > 1 ? w('both') : c.structures[0] === 'package' ? w('packages') : w('perPerson')}</span>
        </>
      )),
      all(c => `${c.venue.type}|${c.structures.join()}`))

    add('photos', w('gPhotos'), w('rPhotos'),
      all(c => {
        const shot = c.venue.gallery[1] ?? c.venue.cover
        return shot ? (
          <span className="gz-cmpr__strip">
            <Photo src={imageSrc(shot.file)} alt={bi(shot.alt)} className="gz-cmph__photo" />
          </span>
        ) : (
          dash
        )
      }),
      all(c => c.venue.id))
    return R
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [columns, brief, guests, origin, f, t, w])

  const same = (r: RowDef) => r.keys.length > 1 && r.keys.every(k => k === r.keys[0])
  const hidden = rows.filter(same).length
  const shown = diff ? rows.filter(r => !same(r)) : rows

  const header = columns.map(c => ({
    venue: c.venue,
    badge: c.best.price ? w('lowest') : c.best.nearest ? w('closest') : c.rating.average !== null && c.rating.count >= 5 && c.rating.average === Math.max(...columns.map(x => x.rating.average ?? 0)) ? w('bestRated') : undefined,
  }))

  const actions: CompareActionColumn[] = columns.map(c => {
    const kind = official(c) ? 'official' : brief.date && c.availability && c.availability !== 'available' ? 'dates' : 'voucher'
    return { id: c.venue.id, name: bi(c.venue.name), kind, label: kind === 'official' ? w('official') : kind === 'dates' ? w('seeDates') : w('getVoucher') }
  })

  const owners = columns.map(c => bi(c.venue.name))
  let lastGroup = ''
  return (
    <div data-gz="CompareTable" className={className}>
      <CompareHeader columns={header} compact={compactHeader} onRemove={onRemove} pinned={pinned} />
      <DifferencesToggle checked={diff} onChange={setDiff} hidden={hidden} />
      {shown.map(r => {
        const band = r.group !== lastGroup ? <CompareBand key={`b-${r.group}`}>{r.group}</CompareBand> : null
        lastGroup = r.group
        return (
          <div key={r.id}>
            {band}
            <CompareRow label={r.label} cells={r.cells} owners={owners} />
          </div>
        )
      })}
      <CompareActionBar columns={actions} pickedId={pickedId} pinned={pinned} onAction={id => onAction?.(id)} />
    </div>
  )
}
