// VenueCard (ADR 0018, direction section 3 "Venue card"): the unframed plate. A 4:5 photograph (radius 12) with one badge, canvas disks
// in 44 targets (compare at inline-start, heart at inline-end), then the wall label: serif name with the rating pinned to the end as
// separate items, area and guest range, section tags, a hairline, the availability line (gold-700 bead) and the price line.
// No border, no shadow, no urgency, no Book or Request action on the card (ADR 0033): the price line carries the voucher price, the
// standard price struck through and the saving; a signed-out visitor sees the standard price and a locked voucher line.
// ADR 0034 (text diet): the wall label is the name, the area and glyphs: `[users] 200 – 650`, the section symbols, the availability as a
// bead (or hourglass, or crossed calendar) and the date, the price and its saving as figures. No "guests", "Available", "Ladies" or "Save"
// words on the card: they are accessible names. A government hall keeps its photo badge; its ministry sentence is read, not shown.
//
// variants   card     4:5 (default: results, home rails, similar venues)
//            feature  4:5 with the larger serif name and the display price (home feature shelf)
//            list     16:10 plate for dense results; opt-in photo dots (`carousel`, ADR 0018 keeps cards single-photo by default)
//            compact  72 x 88 thumbnail row: name, area, price line (carousels, wishlist, tray detail)
//            saved    compact + heart control + a real "Price dropped" note
//            compare  compact + a choice mark (the "Replace which one?" sheet, ADR 0009 D1)
// states     default, pressed (whole card, scale), focus-visible, favourite on, compared, loading (skeleton), no photo, no reviews,
//            governmental facility (ministry line, browse-only: no voucher, no visit), held / booked on your date, guest (voucher price locked).
import { useState, type ReactNode } from 'react'
import type { Audience, CardPrice, Venue, VenueResult } from '@gz/contracts'
import { getArea } from '../../mock'
import { useFormat, useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Badge, Divider, FactChip, Icon, IconButton, Monogram, Rating, Skeleton } from '../core'
import { cx } from '../core/cx'
import { Pager, Photo, imageSrc } from '../overlays'
import { CardPriceLine, Figures, useBi, useInlineSize } from './bits'
import { defineWords, p } from './copy'
import './venue-card.css'

const useW = defineWords({
  guests: p('Guests', 'الضيوف'),
  tagWomen: p('Ladies', 'نسائي'),
  tagMen: p('Men', 'رجالي'),
  tagMixed: p('Mixed', 'مختلط'),
  availableOn: p('Available {date}', 'متاح {date}'),
  held: p('On hold', 'محجوز مؤقتًا'),
  bookedOnDate: p('Booked on your date', 'محجوز في تاريخكم'),
  government: p('Booked through the Ministry of Social Affairs', 'الحجز عبر وزارة الشؤون الاجتماعية'),
  governmentTag: p('Government', 'قاعة حكومية'),
  featured: p('Featured', 'مميزة'),
  window: p('Special voucher price', 'سعر كوبون خاص'),
  noPhotos: p('Photos coming soon', 'الصور قريبًا'),
  hasVideo: p('Has a video tour', 'يتوفر جولة مرئية'),
  priceDropped: p('Price dropped', 'انخفض السعر'),
  select: p('Choose this hall', 'اختيار هذه القاعة'),
  photosOf: p('Photos of {name}', 'صور {name}'),
  open: p('Open {name}', 'فتح {name}'),
})

export type VenueCardVariant = 'card' | 'feature' | 'list' | 'compact' | 'saved' | 'compare'

export type VenueCardProps = {
  venue: Venue
  /** The card price (ADR 0004 D6 grammar), from `cardPrice()` / `VenueResult.price`. */
  price?: CardPrice | null
  /** Availability on the Brief date; omit when no date is set (no empty promise). */
  availability?: VenueResult['availability']
  /** The Brief date, for `Available Thu 14 Jan`. */
  date?: string
  badge?: VenueResult['badge']
  /** `guest`: signed out, so the voucher price is locked behind registration (ADR 0007 D8). Default `member`. */
  audience?: 'member' | 'guest'
  tags?: Audience[]
  guestRange?: { min: number; max: number } | null
  sponsored?: boolean
  variant?: VenueCardVariant
  favourite?: boolean
  onFavouriteChange?: (next: boolean) => void
  compared?: boolean
  onCompareChange?: (next: boolean) => void
  /** Opens the venue (the whole card is the target). */
  onOpen?: () => void
  /** `compare` variant: chosen in the Replace sheet. */
  selected?: boolean
  onSelect?: () => void
  /** `saved` variant: a real earlier price (ADR 0018 D4) turns on the "Price dropped" note. */
  priceDropped?: boolean
  /** Photo dots (`list` and `feature`): swipe through the gallery. */
  carousel?: boolean
  loading?: boolean
  /** Gallery only: show :active without a pointer. */
  previewState?: 'pressed'
  className?: string
}

const AUDIENCE_KEY = { women: 'tagWomen', men: 'tagMen', mixed: 'tagMixed' } as const

function Media({ venue, variant, badge, favourite, onFavouriteChange, compared, onCompareChange, carousel }: Pick<VenueCardProps, 'venue' | 'badge' | 'favourite' | 'onFavouriteChange' | 'compared' | 'onCompareChange' | 'carousel'> & { variant: VenueCardVariant }) {
  const t = useT('common')
  const w = useW()
  const bi = useBi()
  const [box, width] = useInlineSize<HTMLDivElement>()
  const [index, setIndex] = useState(0)
  const shots = carousel && venue.gallery.length > 1 ? venue.gallery.slice(0, 8) : []
  const cover = venue.cover
  const name = bi(venue.name)

  const badgeNode =
    badge === 'window' ? (
      <Badge variant="photo" icon="percent">
        {w('window')}
      </Badge>
    ) : badge === 'featured' ? (
      <Badge variant="photo" icon="sparkle">
        {w('featured')}
      </Badge>
    ) : venue.type === 'governmental' ? (
      <Badge variant="photo" icon="bank">
        {w('governmentTag')}
      </Badge>
    ) : null

  return (
    <div ref={box} className={cx('gz-vcard__media', `gz-vcard__media--${variant === 'list' ? 'list' : 'tall'}`)} data-gz-id="media">
      {shots.length > 0 ? (
        <Pager mode="full" width={width || undefined} index={index} onIndexChange={setIndex} label={w('photosOf', { name })} className="gz-vcard__pager">
          {shots.map(s => (
            <Photo key={s.file} src={imageSrc(s.file)} alt={bi(s.alt)} className="gz-vcard__photo" />
          ))}
        </Pager>
      ) : cover ? (
        <Photo src={imageSrc(cover.file)} alt={bi(cover.alt)} className="gz-vcard__photo" />
      ) : (
        <div className="gz-vcard__empty" data-gz-id="media.empty">
          <Monogram size="md" />
          <span className="gz-sr-only">{w('noPhotos')}</span>
        </div>
      )}

      {onCompareChange ? (
        <span className="gz-vcard__ctl gz-vcard__ctl--start" data-gz-id="media.compare">
          <IconButton
            variant="over-image"
            icon="compare"
            iconActive="check"
            className={compared ? 'is-ink' : undefined}
            active={Boolean(compared)}
            label={t(compared ? 'commonA11yCompareRemove' : 'commonA11yCompareAdd')}
            onClick={() => onCompareChange(!compared)}
          />
        </span>
      ) : null}
      {onFavouriteChange ? (
        <span className="gz-vcard__ctl gz-vcard__ctl--end" data-gz-id="media.fav">
          <IconButton
            variant="over-image"
            icon="heart"
            iconActive="heart-fill"
            active={Boolean(favourite)}
            label={t(favourite ? 'commonA11yFavouriteRemove' : 'commonA11yFavouriteAdd')}
            onClick={() => onFavouriteChange(!favourite)}
          />
        </span>
      ) : null}

      {badgeNode ? (
        <span className="gz-vcard__badge" data-gz-id="media.badge">
          {badgeNode}
        </span>
      ) : null}
      {venue.hasVideo ? (
        <span className="gz-vcard__play" data-gz-id="media.play">
          <Icon name="play" size="sm" />
          <span className="gz-sr-only">{w('hasVideo')}</span>
        </span>
      ) : null}
      {shots.length > 1 ? <PhotoDots count={shots.length} index={index} /> : null}
    </div>
  )
}

/** Up to five dots, a window that slides with the photo; the edge dots shrink when more lie beyond. Canvas on the bottom scrim. */
function PhotoDots({ count, index }: { count: number; index: number }) {
  const visible = Math.min(5, count)
  const start = Math.min(Math.max(index - 2, 0), count - visible)
  return (
    <span className="gz-vcard__dots" aria-hidden="true" data-gz-id="media.dots">
      {Array.from({ length: visible }, (_, k) => {
        const i = start + k
        const small = (k === 0 && start > 0) || (k === visible - 1 && start + visible < count)
        return <span key={i} className={cx('gz-vcard__dot', i === index && 'is-on', small && 'is-small')} />
      })}
    </span>
  )
}

function Availability({ venue, availability, date }: Pick<VenueCardProps, 'venue' | 'availability' | 'date'>) {
  const f = useFormat()
  const w = useW()
  if (venue.type === 'governmental' || venue.channel === 'external_link') {
    return (
      <div className="gz-vcard__avail" data-gz-id="avail">
        <Icon name="bank" size="xs" tone="secondary" />
        <span className="gz-sr-only">{w('government')}</span>
      </div>
    )
  }
  if (!availability || availability === 'unknown' || !date) return null
  const free = availability === 'available'
  const held = availability === 'held'
  const word = free ? w('availableOn', { date: '' }).trim() : held ? w('held') : w('bookedOnDate')
  // Glyph and date; the state word is the accessible name: bead = free, hourglass = on hold, crossed calendar = taken.
  return (
    <div className="gz-vcard__avail" data-gz-id="avail" data-state={availability}>
      {free ? <span className="gz-vcard__bead" aria-hidden="true" /> : <Icon name={held ? 'hourglass' : 'calendar-x'} size="xs" tone="secondary" />}
      <span className="gz-sr-only">{word}</span>
      <span className="gz-vcard__avail-text gz-t-caption">
        <Figures text={f.date(date, 'short')} />
      </span>
    </div>
  )
}

function Rate({ venue }: { venue: Venue }) {
  const t = useT('common')
  const { average, count } = venue.rating
  if (average === null || count === 0) return <span className="gz-vcard__new gz-t-body-s">{t('commonLabelNew')}</span>
  return <Rating value={average} count={count} />
}

const AUDIENCE_ICON = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' } as const

function MetaLine({ venue, guestRange, sponsored, tags }: Pick<VenueCardProps, 'venue' | 'guestRange' | 'sponsored'> & { tags?: Audience[] }) {
  const f = useFormat()
  const w = useW()
  const t = useT('common')
  const bi = useBi()
  const area = getArea(venue.areaId)
  const range = guestRange ? `${f.integer(guestRange.min)} – ${f.integer(guestRange.max)}` : null
  const sections = tags && tags.length >= 2 ? tags : []
  return (
    <div className="gz-vcard__meta gz-t-body-s" data-gz-id="meta">
      <span className="gz-vcard__meta-text">{area ? bi(area.name) : null}</span>
      {range ? <FactChip icon="users-three" label={w('guests')} value={range} size="sm" tone="muted" /> : null}
      {sections.map(a => (
        <FactChip key={a} icon={AUDIENCE_ICON[a]} label={w(AUDIENCE_KEY[a])} size="sm" tone="muted" />
      ))}
      {sponsored ? <span className="gz-vcard__sponsored gz-t-caption">{t('commonLabelSponsored')}</span> : null}
    </div>
  )
}

function CardSkeleton({ variant }: { variant: VenueCardVariant }) {
  const compact = variant === 'compact' || variant === 'saved' || variant === 'compare'
  if (compact) {
    return (
      <div className="gz-vcard gz-vcard--compact is-loading" data-gz="VenueCard" data-variant={variant} aria-busy="true">
        <Skeleton variant="block" inlineSize={72} blockSize={88} />
        <div className="gz-vcard__body">
          <Skeleton inlineSize={140} blockSize={20} />
          <Skeleton inlineSize={96} blockSize={16} />
          <Skeleton inlineSize={120} blockSize={20} />
        </div>
      </div>
    )
  }
  return (
    <div className={cx('gz-vcard', `gz-vcard--${variant}`, 'is-loading')} data-gz="VenueCard" data-variant={variant} aria-busy="true">
      <div className="gz-vcard__media gz-vcard__media--skeleton" />
      <div className="gz-vcard__body">
        <Skeleton inlineSize={200} blockSize={28} />
        <Skeleton inlineSize={160} blockSize={20} />
        <Skeleton inlineSize={220} blockSize={20} />
        <Skeleton inlineSize={140} blockSize={24} />
      </div>
    </div>
  )
}

export function VenueCard(props: VenueCardProps) {
  const { venue, price, availability, date, badge, audience = 'member', tags = [], guestRange, sponsored, variant = 'card', onOpen, className, previewState } = props
  const bi = useBi()
  const w = useW()
  const t = useT('common')
  const { lang } = useLang()
  if (props.loading) return <CardSkeleton variant={variant} />
  const name = bi(venue.name)
  const compact = variant === 'compact' || variant === 'saved' || variant === 'compare'

  const opener = (
    <button type="button" className="gz-reset gz-vcard__open" onClick={onOpen} aria-label={w('open', { name })}>
      <span className="gz-sr-only">{name}</span>
    </button>
  )

  if (compact) {
    return (
      <article
        data-gz="VenueCard"
        data-variant={variant}
        className={cx('gz-vcard gz-vcard--compact gz-press', props.selected && 'is-selected', previewState === 'pressed' && 'is-pressed', className)}
        aria-current={props.selected || undefined}
      >
        <div className="gz-vcard__thumb" data-gz-id="thumb">
          {venue.cover ? (
            <Photo src={imageSrc(venue.cover.file)} alt={bi(venue.cover.alt)} className="gz-vcard__photo" />
          ) : (
            <div className="gz-vcard__empty gz-vcard__empty--thumb">
              <Monogram size="sm" />
            </div>
          )}
        </div>
        <div className="gz-vcard__body">
          <h3 className="gz-vcard__name gz-t-d1 gz-clamp-2" lang={lang}>
            {name}
          </h3>
          <MetaLine venue={venue} guestRange={null} sponsored={false} />
          {price ? <CardPriceLine price={price} audience={audience} lean /> : null}
          {variant === 'saved' && props.priceDropped ? (
            <span className="gz-vcard__drop gz-t-caption">
              <Icon name="trend-down" size="xs" tone="accent" />
              <span className="gz-sr-only">{w('priceDropped')}</span>
            </span>
          ) : null}
        </div>
        {variant === 'saved' && props.onFavouriteChange ? (
          <IconButton
            icon="heart"
            iconActive="heart-fill"
            active={Boolean(props.favourite ?? true)}
            label={t(props.favourite === false ? 'commonA11yFavouriteAdd' : 'commonA11yFavouriteRemove')}
            onClick={() => props.onFavouriteChange?.(!(props.favourite ?? true))}
            className="gz-vcard__aside"
          />
        ) : null}
        {variant === 'compare' ? (
          <span className={cx('gz-vcard__choice', props.selected && 'is-on')} aria-hidden="true">
            {props.selected ? <Icon name="check" size="xs" /> : null}
          </span>
        ) : null}
        {variant === 'compare' ? (
          <button type="button" className="gz-reset gz-vcard__open" onClick={props.onSelect} aria-pressed={Boolean(props.selected)} aria-label={w('select')}>
            <span className="gz-sr-only">{name}</span>
          </button>
        ) : (
          opener
        )}
      </article>
    )
  }

  const feature = variant === 'feature'
  return (
    <article
      data-gz="VenueCard"
      data-variant={variant}
      className={cx('gz-vcard gz-press', `gz-vcard--${variant}`, previewState === 'pressed' && 'is-pressed', className)}
    >
      <Media
        venue={venue}
        variant={variant}
        badge={badge}
        favourite={props.favourite}
        onFavouriteChange={props.onFavouriteChange}
        compared={props.compared}
        onCompareChange={props.onCompareChange}
        carousel={props.carousel}
      />
      <div className="gz-vcard__body">
        <div className="gz-vcard__text">
          <div className="gz-vcard__head">
            <h3 className={cx('gz-vcard__name gz-clamp-2', feature ? 'gz-t-d2' : 'gz-t-d1')} lang={lang} data-gz-id="name">
              {name}
            </h3>
            <span className="gz-vcard__rate" data-gz-id="rating">
              <Rate venue={venue} />
            </span>
          </div>
          <MetaLine venue={venue} guestRange={guestRange} sponsored={sponsored} tags={tags} />
        </div>
        <Divider />
        <div className="gz-vcard__foot">
          <Availability venue={venue} availability={availability} date={date} />
          {price ? <CardPriceLine price={price} size={feature ? 'display' : 'card'} audience={audience} /> : null}
        </div>
      </div>
      {opener}
    </article>
  )
}
