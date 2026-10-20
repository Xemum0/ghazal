// Venue details information blocks (CL-VENU, ADR 0002, ADR 0015 D6): AmenityGrid, PolicyList, FaqAccordion and MapPreview.
// AmenityGrid     three states, always icon + words: Included, Extra (with its price anchor), Not offered (muted); grouped, two columns
// PolicyList      per-section policy facts as plain labelled rows, never a judgement (photography, music, entrance, cut-off, children)
// FaqAccordion    the shared Accordion over a venue's questions (64 min rows, single open, a chevron that turns)
// MapPreview      a static illustration drawn from tokens only (no tiles, no blur): water, blocks, roads, one pin, the area and the drive time
import { useMemo, useState } from 'react'
import type { IconName } from '@gz/tokens'
import type { AmenityDef, FaqItem, PolicyFacts, Venue, VenueAmenity } from '@gz/contracts'
import { amenityDefs, getArea } from '../../mock'
import { useFormat, useT } from '../../i18n'
import { Button, Icon } from '../core'
import { cx } from '../core/cx'
import { Accordion } from '../overlays'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './venue-info.css'

const useW = defineWords({
  gSpace: p('Spaces', 'المساحات'),
  gService: p('Services', 'الخدمات'),
  gProduction: p('Production', 'الإنتاج'),
  gPolicy: p('House rules', 'قواعد المكان'),
  included: p('Included', 'مشمول'),
  extra: p('Extra', 'إضافة'),
  extraFrom: p('Extra, from {price}', 'إضافة، تبدأ من {price}'),
  notOffered: p('Not offered', 'غير متوفر'),
  showAll: p('Show all {n} facilities', 'عرض كل المرافق ({n})'),
  showLess: p('Show fewer', 'عرض أقل'),
  photography: p('Photography', 'التصوير'),
  music: p('Music', 'الموسيقى'),
  entrance: p('Entrance', 'المدخل'),
  cloakroom: p('Abaya cloakroom', 'غرفة العبايات'),
  prayer: p('Prayer room', 'المصلى'),
  security: p('Security', 'الحراسة'),
  boys: p('Boys', 'الأولاد'),
  catering: p('Outside catering', 'الضيافة الخارجية'),
  decor: p('Outside decor', 'الديكور الخارجي'),
  bukhoor: p('Bukhoor', 'البخور'),
  cutOff: p('Event ends by', 'نهاية المناسبة'),
  extraHour: p('Extra hour', 'ساعة إضافية'),
  backup: p('Indoor backup', 'قاعة بديلة داخلية'),
  fPhotoFemale: p('Female photographers only', 'مصوّرات فقط'),
  fPhotoAllowed: p('Photography allowed', 'التصوير مسموح'),
  fPhotoNone: p('No photography', 'لا تصوير'),
  fMusicBand: p('DJ or band', 'منسّق أو فرقة'),
  fMusicLive: p('Live music', 'موسيقى حيّة'),
  fMusicDuff: p('Duff and nasheed only', 'دفوف وأناشيد فقط'),
  fMusicNone: p('No music', 'بلا موسيقى'),
  fYes: p('Yes', 'متوفر'),
  fNo: p('No', 'غير متوفر'),
  fSeparate: p('Separate entrance', 'مدخل منفصل'),
  fSecurityFemale: p('Female security', 'حراسة نسائية'),
  fBoysUpTo: p('Up to age {n}', 'حتى عمر {n} سنوات'),
  fBoysAny: p('Any age', 'لجميع الأعمار'),
  fAllowed: p('Allowed', 'مسموح'),
  fApproval: p('With the hotel’s approval', 'بموافقة المكان'),
  fNotAllowed: p('Not allowed', 'غير مسموح'),
  fIncluded: p('Available', 'متوفرة'),
  mapOpen: p('Open in Maps', 'فتح في الخرائط'),
  mapDrive: p('{time} from {origin}', '{time} من {origin}'),
  mapPin: p('Location of {name}', 'موقع {name}'),
  block: p('Block {n}', 'قطعة {n}'),
})

// ---------------------------------------------------------------- AmenityGrid
/** Amenity id (fixtures/amenities.json) to registry glyph; the nearest meaning where there is no exact one. */
const AMENITY_ICON: Record<string, IconName> = {
  'ladies-hall': 'hall', 'men-hall': 'hall', 'separate-entrance': 'door', 'indoor-backup': 'home', 'garden-terrace': 'flower',
  'bridal-suite': 'bed', 'groom-room': 'armchair', 'abaya-cloakroom': 'dress', 'prayer-room': 'prayer', 'suite-night': 'bed',
  buffet: 'catering', 'welcome-drinks': 'drinks', 'gahwa-tea': 'drinks', valet: 'valet', parking: 'parking', 'female-security': 'shield-check',
  accessibility: 'accessible', 'kids-corner': 'guests', 'show-cake': 'cake', 'bukhoor-service': 'incense', 'coffee-station': 'drinks',
  'sound-lighting': 'sound', 'led-screens': 'video', 'basic-decor': 'decor', kosha: 'decor', florals: 'flower',
  'female-photographer': 'camera', zaffa: 'music', 'outside-catering': 'catering', 'outside-decor': 'decor', 'extra-hour': 'clock',
}

export type AmenityGridProps = {
  amenities: readonly VenueAmenity[]
  /** Facilities shown before "Show all" (default: all). */
  collapsedCount?: number
  className?: string
}

export function AmenityGrid({ amenities, collapsedCount, className }: AmenityGridProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const [open, setOpen] = useState(false)
  const defs = useMemo(() => new Map<string, AmenityDef>(amenityDefs.map(d => [d.id, d])), [])
  const items = amenities.filter(a => defs.has(a.amenityId))
  const limit = collapsedCount && !open ? collapsedCount : items.length
  const visible = items.slice(0, limit)
  const groups: { id: AmenityDef['group']; label: string }[] = [
    { id: 'space', label: w('gSpace') },
    { id: 'service', label: w('gService') },
    { id: 'production', label: w('gProduction') },
    { id: 'policy', label: w('gPolicy') },
  ]
  return (
    <div data-gz="AmenityGrid" className={cx('gz-amen', className)}>
      {groups.map(g => {
        const inGroup = visible.filter(a => defs.get(a.amenityId)?.group === g.id)
        if (inGroup.length === 0) return null
        // Rows of two: flex, never grid; an odd last item leaves its twin cell empty.
        const rows: VenueAmenity[][] = []
        for (let i = 0; i < inGroup.length; i += 2) rows.push(inGroup.slice(i, i + 2))
        return (
          <section key={g.id} className="gz-amen__group" aria-label={g.label}>
            <h3 className="gz-amen__title gz-t-caption">{g.label}</h3>
            <ul className="gz-amen__rows">
              {rows.map((row, ri) => (
                <li key={ri} className="gz-amen__row">
                  {[0, 1].map(ci => {
                    const a = row[ci]
                    if (!a) return <span key={ci} className="gz-amen__item gz-amen__item--empty" />
                    const def = defs.get(a.amenityId)!
                    const off = a.state === 'not_offered'
                    return (
                      <span key={ci} className={cx('gz-amen__item', off && 'is-off')} data-state={a.state} data-gz-id={`amenity.${a.amenityId}`}>
                        <Icon name={AMENITY_ICON[a.amenityId] ?? 'check-circle'} size="md" tone={off ? 'disabled' : 'primary'} />
                        <span className="gz-amen__text">
                          <span className="gz-amen__label gz-t-body-s">{bi(def.label)}</span>
                          <span className="gz-amen__state gz-t-caption">
                            <Icon name={a.state === 'included' ? 'check' : a.state === 'extra' ? 'plus' : 'minus'} size="xs" tone={a.state === 'included' ? 'success' : 'secondary'} />
                            <Figures text={a.state === 'included' ? w('included') : a.state === 'extra' ? (a.from ? w('extraFrom', { price: f.money(a.from.fils) }) : w('extra')) : w('notOffered')} />
                          </span>
                        </span>
                      </span>
                    )
                  })}
                </li>
              ))}
            </ul>
          </section>
        )
      })}
      {collapsedCount && items.length > collapsedCount ? (
        <Button variant="tertiary" iconEnd={open ? 'chevron-up' : 'chevron-down'} onClick={() => setOpen(v => !v)} className="gz-amen__more">
          {open ? w('showLess') : w('showAll', { n: f.integer(items.length) })}
        </Button>
      ) : null}
    </div>
  )
}

// ---------------------------------------------------------------- PolicyList
export type PolicyListProps = {
  facts: PolicyFacts
  /** Terms shown after the facts: the children and dress-code lines, already in the current language. */
  extra?: readonly { label: string; value: string }[]
  className?: string
}

export function PolicyList({ facts, extra = [], className }: PolicyListProps) {
  const f = useFormat()
  const w = useW()
  const rows: { icon: IconName; label: string; value: string }[] = [
    { icon: 'camera', label: w('photography'), value: facts.photography === 'female_only' ? w('fPhotoFemale') : facts.photography === 'allowed' ? w('fPhotoAllowed') : w('fPhotoNone') },
    { icon: 'music', label: w('music'), value: facts.music === 'dj_or_band' ? w('fMusicBand') : facts.music === 'live' ? w('fMusicLive') : facts.music === 'duff_only' ? w('fMusicDuff') : w('fMusicNone') },
    { icon: 'door', label: w('entrance'), value: facts.separateEntrance ? w('fSeparate') : w('fNo') },
    { icon: 'dress', label: w('cloakroom'), value: facts.abayaCloakroom ? w('fIncluded') : w('fNo') },
    { icon: 'home', label: w('prayer'), value: facts.prayerRoom ? w('fIncluded') : w('fNo') },
    { icon: 'shield-check', label: w('security'), value: facts.femaleSecurity ? w('fSecurityFemale') : w('fNo') },
    { icon: 'guests', label: w('boys'), value: facts.boysMaxAge === null ? w('fBoysAny') : w('fBoysUpTo', { n: f.integer(facts.boysMaxAge) }) },
    { icon: 'catering', label: w('catering'), value: rule(facts.outsideCatering, w) },
    { icon: 'decor', label: w('decor'), value: rule(facts.outsideDecor, w) },
    { icon: 'sparkle', label: w('bukhoor'), value: rule(facts.bukhoor, w) },
    { icon: 'clock', label: w('cutOff'), value: f.time(`2000-01-01T${facts.cutOff}`) },
  ]
  if (facts.extraHour) rows.push({ icon: 'clock', label: w('extraHour'), value: f.money(facts.extraHour.fils) })
  if (facts.indoorBackup) rows.push({ icon: 'home', label: w('backup'), value: w('fIncluded') })
  return (
    <dl data-gz="PolicyList" className={cx('gz-policy', className)}>
      {[...rows.map(r => ({ ...r })), ...extra.map(e => ({ icon: 'info' as IconName, ...e }))].map((r, i) => (
        <div key={i} className="gz-policy__row" data-gz-id={`policy.${i}`}>
          <dt className="gz-policy__label gz-t-caption">
            <Icon name={r.icon} size="sm" tone="secondary" />
            {r.label}
          </dt>
          <dd className="gz-policy__value gz-t-body-s">
            <Figures text={r.value} />
          </dd>
        </div>
      ))}
    </dl>
  )
}

function rule(r: PolicyFacts['outsideCatering'], w: ReturnType<typeof useW>): string {
  return r === 'allowed' ? w('fAllowed') : r === 'with_approval' ? w('fApproval') : w('fNotAllowed')
}

// ---------------------------------------------------------------- FaqAccordion
export function FaqAccordion({ items, defaultOpenId, multiple = false }: { items: readonly FaqItem[]; defaultOpenId?: string; multiple?: boolean }) {
  const bi = useBi()
  return (
    <div data-gz="FaqAccordion">
      <Accordion
        multiple={multiple}
        defaultOpenIds={defaultOpenId ? [defaultOpenId] : []}
        items={items.map(q => ({ id: q.id, title: <bdi dir="auto">{bi(q.question)}</bdi>, content: <span className="gz-faq__answer">{bi(q.answer)}</span> }))}
      />
    </div>
  )
}

// ---------------------------------------------------------------- MapPreview
export type MapPreviewProps = {
  venue: Pick<Venue, 'name' | 'areaId' | 'address' | 'geo' | 'distances'>
  /** Reference point id for the drive time ("ref-salmiya") and its name. */
  origin?: { id: string; name: string }
  onOpen?: () => void
  className?: string
}

/** A small deterministic offset from the coordinates so each venue's illustration differs, with no randomness. */
const jitter = (n: number, span: number) => Math.round(((Math.abs(Math.sin(n * 12.9898) * 43758.5453) % 1) * span))

export function MapPreview({ venue, origin, onOpen, className }: MapPreviewProps) {
  const t = useT('common')
  const w = useW()
  const bi = useBi()
  const area = getArea(venue.areaId)
  const name = bi(venue.name)
  const drive = origin ? venue.distances[origin.id] : undefined
  const sx = jitter(venue.geo.lat, 60)
  const sy = jitter(venue.geo.lng, 40)
  // The coast runs down the inline-start side of the illustration, as Kuwait Bay lies to the east of the city.
  return (
    <figure data-gz="MapPreview" className={cx('gz-map', className)}>
      <div className="gz-map__plate" role="img" aria-label={w('mapPin', { name })}>
        <svg className="gz-map__svg" viewBox="0 0 320 200" preserveAspectRatio="xMidYMid slice" aria-hidden="true" focusable="false">
          <rect className="gz-map__land" x="0" y="0" width="320" height="200" />
          <path className="gz-map__water" d={`M0 0 H${70 + sx} C${50 + sx} 40 ${90 + sx} 70 ${60 + sx} 110 C${40 + sx} 140 ${80 + sx} 170 ${50 + sx} 200 H0 Z`} />
          <g className="gz-map__blocks">
            <rect x={120 + sx} y={20 + sy} width="44" height="28" rx="4" />
            <rect x={176 + sx} y={20 + sy} width="36" height="28" rx="4" />
            <rect x={120 + sx} y={60 + sy} width="28" height="36" rx="4" />
            <rect x={60 + sy} y={130 - sy} width="52" height="30" rx="4" />
            <rect x={230 - sy} y={110 + sy} width="44" height="36" rx="4" />
            <rect x={196 + sx} y={150} width="52" height="28" rx="4" />
          </g>
          <g className="gz-map__roads-minor">
            <path d={`M${100 + sx} 0 V200`} />
            <path d={`M0 ${100 + sy} H320`} />
            <path d={`M${200 + sx} 0 L${150 + sx} 200`} />
          </g>
          <g className="gz-map__roads">
            <path d={`M${40 + sx} 200 C${120 + sx} 140 ${160 + sx} 90 320 ${60 + sy}`} />
            <path d={`M${90 + sx} 0 C${130 + sx} 70 ${150 + sx} 120 ${260 + sx} 200`} />
          </g>
          <g className="gz-map__pin" transform="translate(160 92)">
            <path className="gz-map__pin-body" d="M0 0 C-14 -16 -20 -26 -20 -36 A20 20 0 0 1 20 -36 C20 -26 14 -16 0 0 Z" />
            <circle className="gz-map__pin-dot" cx="0" cy="-36" r="7" />
          </g>
        </svg>
        {area ? (
          <span className="gz-map__area gz-t-caption" data-gz-id="area">
            {bi(area.name)}
          </span>
        ) : null}
      </div>
      <figcaption className="gz-map__cap">
        <span className="gz-map__addr gz-t-body-s">
          {area ? bi(area.name) : ''}
          {venue.address.block ? <> · <Figures text={w('block', { n: venue.address.block })} /></> : null}
          {venue.address.street ? <> · {bi(venue.address.street)}</> : null}
        </span>
        {drive && origin ? (
          <span className="gz-map__drive gz-t-caption">
            <Icon name="car" size="xs" tone="secondary" />
            <Figures text={w('mapDrive', { time: t('commonCountMinutes', { count: drive.minutes }), origin: origin.name })} />
          </span>
        ) : null}
        <Button variant="tertiary" iconEnd="external-link" onClick={onOpen} className="gz-map__open">
          {w('mapOpen')}
        </Button>
      </figcaption>
    </figure>
  )
}
