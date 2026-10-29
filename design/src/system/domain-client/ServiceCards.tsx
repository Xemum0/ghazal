// Planner and services cards (CA-PLAN, CA-SVC, ADR 0004 D8): PlannerTierCard, ServiceTile and VendorCard.
// PlannerTierCard   Silver / Gold / Royal as a choice: one, two or three thread beads signal the tier, never a metal colour; the price
//                   with its basis, what is included, who it suits, and, for the planner, information only (no voucher: the consultation is a conversation)
// ServiceTile       one of the 16 service categories: a 4:5 photograph and a wall label (name, price anchor with its unit)
// VendorCard        a supplier: portfolio strip, monogram, name, rating (or New), area, the from price with its unit, plain facts, verified mark
import type { PlannerPackage, ServiceCategory, Vendor } from '@gz/contracts'
import { getArea } from '../../mock'
import { useFormat, useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Avatar, Button, Icon, IconButton, Price, Rating, Skeleton, Tag, ThreadBead } from '../core'
import { cx } from '../core/cx'
import { Photo, imageSrc } from '../overlays'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './services.css'

const useW = defineWords({
  from: p('From', 'من'),
  suits: p('Suits', 'مناسبة لـ'),
  consult: p('Request consultation', 'طلب استشارة'),
  selected: p('Selected', 'تم الاختيار'),
  tierMarks: p('{n} of 3 marks', '{n} من 3 علامات'),
  showAll: p('Show all {n} inclusions', 'عرض كل المشمولات ({n})'),
  verified: p('Verified', 'موثّق'),
  femaleTeam: p('Female team for ladies’ halls', 'فريق نسائي للقاعات النسائية'),
  replies: p('Usually replies within {time}', 'يرد عادةً خلال {time}'),
  quote: p('Request a quote', 'طلب عرض سعر'),
  openCat: p('Open {name}', 'فتح {name}'),
})

// ---------------------------------------------------------------- PlannerTierCard
export type PlannerTierCardProps = {
  pkg: PlannerPackage
  selected?: boolean
  onSelect?: () => void
  /** The card's own action (the consultation request); omit when the screen has one sticky bar. */
  onRequest?: () => void
  loading?: boolean
  className?: string
}

export function PlannerTierCard({ pkg, selected = false, onSelect, onRequest, loading, className }: PlannerTierCardProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  if (loading) {
    return (
      <div className={cx('gz-tier gz-cpanel is-loading', className)} data-gz="PlannerTierCard" aria-busy="true">
        <Skeleton variant="block" blockSize={160} />
        <Skeleton inlineSize={140} blockSize={28} />
        <Skeleton blockSize={20} />
        <Skeleton blockSize={20} />
      </div>
    )
  }
  const marks = Array.from({ length: pkg.marks })
  const body = (
    <>
      <span className="gz-tier__image" data-gz-id="image">
        <Photo src={imageSrc(pkg.image.file)} alt={bi(pkg.image.alt)} className="gz-tier__photo" />
      </span>
      <span className="gz-tier__head">
        <span className="gz-tier__title">
          <span className="gz-tier__name gz-t-d2" lang={lang}>
            {bi(pkg.name)}
          </span>
          <span className="gz-tier__marks" role="img" aria-label={w('tierMarks', { n: f.integer(pkg.marks) })}>
            {marks.map((_, i) => (
              <ThreadBead key={i} tone="gold" />
            ))}
          </span>
        </span>
        <span className="gz-tier__tagline gz-t-body-s">{bi(pkg.tagline)}</span>
      </span>
    </>
  )
  return (
    <article data-gz="PlannerTierCard" data-tier={pkg.tier} className={cx('gz-tier gz-cpanel', selected && 'is-selected', className)}>
      {onSelect ? (
        <button type="button" role="radio" aria-checked={selected} className="gz-reset gz-tier__choose gz-press" onClick={onSelect}>
          {body}
        </button>
      ) : (
        <div className="gz-tier__choose">{body}</div>
      )}
      <div className="gz-tier__price" data-gz-id="price">
        <Price fils={pkg.from.fils} size="strong" prefix={w('from')} />
      </div>
      <ul className="gz-tier__list" data-gz-id="inclusions">
        {pkg.inclusions.map((inc, i) => (
          <li key={i} className="gz-tier__inc gz-t-body-s">
            <Icon name="check" size="xs" className="gz-tier__check" />
            <span>{bi(inc)}</span>
          </li>
        ))}
      </ul>
      <p className="gz-tier__suits gz-t-caption">
        <span className="gz-tier__suits-label">{w('suits')} </span>
        {bi(pkg.suits)}
      </p>
      {onRequest ? (
        <Button variant="secondary" fullWidth onClick={onRequest} iconEnd="chevron-right">
          {w('consult')}
        </Button>
      ) : null}
    </article>
  )
}

// ---------------------------------------------------------------- ServiceTile
export type ServiceTileProps = {
  category: ServiceCategory
  onOpen?: () => void
  loading?: boolean
  previewState?: 'pressed'
  className?: string
}

export function ServiceTile({ category, onOpen, loading, previewState, className }: ServiceTileProps) {
  const w = useW()
  const bi = useBi()
  if (loading) {
    return (
      <div className={cx('gz-stile is-loading', className)} data-gz="ServiceTile" aria-busy="true">
        <div className="gz-stile__plate" />
        <Skeleton inlineSize={96} blockSize={24} />
        <Skeleton inlineSize={120} blockSize={20} />
      </div>
    )
  }
  const name = bi(category.name)
  return (
    <div data-gz="ServiceTile" data-category={category.id} className={cx('gz-stile gz-press', previewState === 'pressed' && 'is-pressed', className)}>
      <div className="gz-stile__plate" data-gz-id="plate">
        <Photo src={imageSrc(category.image.file)} alt={bi(category.image.alt)} className="gz-stile__photo" />
      </div>
      <div className="gz-stile__label">
        <span className="gz-stile__name gz-t-title">{name}</span>
        <span className="gz-stile__price gz-t-caption">
          <Price fils={category.anchor.min.fils} size="strong" prefix={w('from')} unit={undefined} />
          <span className="gz-stile__unit">{bi(category.anchor.unit)}</span>
        </span>
      </div>
      <button type="button" className="gz-reset gz-stile__open" onClick={onOpen} aria-label={w('openCat', { name })} />
    </div>
  )
}

// ---------------------------------------------------------------- VendorCard
export type VendorCardProps = {
  vendor: Vendor
  favourite?: boolean
  onFavouriteChange?: (next: boolean) => void
  onOpen?: () => void
  variant?: 'card' | 'row'
  loading?: boolean
  previewState?: 'pressed'
  className?: string
}

export function VendorCard({ vendor, favourite, onFavouriteChange, onOpen, variant = 'card', loading, previewState, className }: VendorCardProps) {
  const t = useT('common')
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  if (loading) {
    return (
      <div className={cx('gz-vendor gz-cpanel is-loading', className)} data-gz="VendorCard" aria-busy="true">
        <Skeleton variant="block" blockSize={96} />
        <Skeleton inlineSize={180} blockSize={24} />
        <Skeleton inlineSize={120} blockSize={20} />
      </div>
    )
  }
  const name = bi(vendor.name)
  const area = getArea(vendor.areaId)
  const row = variant === 'row'
  const voucher = vendor.fromVoucher
  return (
    <article
      data-gz="VendorCard"
      data-variant={variant}
      className={cx('gz-vendor gz-cpanel gz-press', row && 'gz-vendor--row', previewState === 'pressed' && 'is-pressed', className)}
    >
      {row ? null : (
        <ul className="gz-vendor__strip" data-gz-id="portfolio">
          {vendor.portfolio.slice(0, 3).map(img => (
            <li key={img.file} className="gz-vendor__shot">
              <Photo src={imageSrc(img.file)} alt={bi(img.alt)} className="gz-vendor__img" />
            </li>
          ))}
        </ul>
      )}
      <div className="gz-vendor__head">
        <Avatar name={name} initial={lang === 'ar' ? vendor.monogram : undefined} size="sm" />
        <div className="gz-vendor__who">
          <h3 className="gz-vendor__name gz-t-d1 gz-clamp-2" lang={lang} data-gz-id="name">
            {name}
          </h3>
          <p className="gz-vendor__meta gz-t-body-s">
            {area ? bi(area.name) : ''}
            {vendor.verified ? (
              <span className="gz-vendor__verified">
                <Icon name="verified" size="xs" tone="success" />
                {w('verified')}
              </span>
            ) : null}
          </p>
        </div>
        {vendor.rating ? <Rating value={vendor.rating.average} count={vendor.rating.count} /> : <span className="gz-t-body-s gz-vendor__new">{t('commonLabelNew')}</span>}
      </div>
      <p className="gz-vendor__price" data-gz-id="price" data-voucher={voucher ? '' : undefined}>
        <Price fils={(voucher ?? vendor.from).fils} size="card" prefix={w('from')} was={voucher ? vendor.from.fils : undefined} />
        <span className="gz-vendor__unit gz-t-caption">{bi(vendor.fromUnit)}</span>
      </p>
      {row ? null : (
        <>
          {vendor.femaleTeamForLadies ? <Tag icon="check-circle">{w('femaleTeam')}</Tag> : null}
          <p className="gz-vendor__reply gz-t-caption">
            <Icon name="clock" size="xs" tone="secondary" />
            <Figures text={w('replies', { time: t('commonCountHours', { count: vendor.usuallyRepliesHours }) })} />
          </p>
        </>
      )}
      {onFavouriteChange ? (
        <span className="gz-vendor__fav">
          <IconButton
            variant={row ? 'plain' : 'over-image'}
            icon="heart"
            iconActive="heart-fill"
            active={Boolean(favourite)}
            label={t(favourite ? 'commonA11yFavouriteRemove' : 'commonA11yFavouriteAdd')}
            onClick={() => onFavouriteChange(!favourite)}
          />
        </span>
      ) : null}
      <button type="button" className="gz-reset gz-vendor__open" onClick={onOpen} aria-label={name} />
    </article>
  )
}
