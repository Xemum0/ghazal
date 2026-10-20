// One planner package as a wall-label plate (direction 5): a full-bleed photograph, then the label that does the work: the name in the
// display face with its thread marks, the from-price between two hairlines (the price terms sit behind its info glyph), and the inclusions
// as glyph + two-word rows (short labels from tierMedia). Gold and Royal open with "Everything in Silver / Gold", drawn as `+ ◆ Silver`. Unframed, no card, no shadow (the venue
// card grammar). Flow-local: the system PlannerTierCard is a boxed panel with a 16:10 image inside it, which pushes every inclusion below
// the fold on a phone.
import type { PlannerPackage } from '@gz/contracts'
import { plannerPackages } from '../../../../mock'
import { useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Icon, InfoButton, Photo, Price, Skeleton, imageSrc, useBi } from '../../../../system'
import { TierMarks, useInclusionLabel } from './parts'
import { inclusionGlyph, tierPhoto } from './tierMedia'
import './tier-plate.css'

export function TierPlate({ pkg, loading }: { pkg: PlannerPackage; loading?: boolean }) {
  const t = useT('client-planner')
  const bi = useBi()
  const { lang } = useLang()
  const label = useInclusionLabel()

  if (loading) {
    return (
      <div className="gzp-plate gzp-plate--loading" aria-busy="true" data-gz-id="planner.plate">
        <div className="gzp-plate__photo gzp-plate__photo--ph" />
        <div className="gzp-plate__label">
          <Skeleton inlineSize={160} blockSize={32} />
          <Skeleton blockSize={48} />
          <Skeleton blockSize={20} />
          <Skeleton blockSize={20} />
        </div>
      </div>
    )
  }

  const photo = tierPhoto(pkg.tier)
  // Every tier above Silver opens with a carry-over row ("Everything in Silver"); it is the previous package, so it is drawn as one.
  const index = plannerPackages.findIndex(p => p.id === pkg.id)
  const previous = index > 0 ? plannerPackages[index - 1] : undefined
  const own = previous ? pkg.inclusions.slice(1) : pkg.inclusions
  return (
    <article className="gzp-plate" data-tier={pkg.tier} data-gz-id="planner.plate">
      <div className="gzp-plate__photo">
        <Photo src={imageSrc(photo.file)} alt={bi(photo.alt)} className="gzp-plate__img" priority />
      </div>
      <div className="gzp-plate__label">
        <header className="gzp-plate__head" data-gz-id="planner.price">
          <div className="gzp-plate__id">
            <h2 className="gzp-plate__name gz-t-d2" lang={lang}>
              {bi(pkg.name)}
            </h2>
            <TierMarks tier={pkg.tier} />
          </div>
          <div className="gzp-plate__price">
            <Price fils={pkg.from.fils} size="display" prefix={t('clientPlannerFromPrefix')} />
            <InfoButton title={t('clientPlannerPriceInfoTitle')}>{t('clientPlannerPriceInfo')}</InfoButton>
          </div>
        </header>

        <ul className="gzp-plate__list" aria-label={t('clientPlannerIncludedLabel')} data-gz-id="planner.inclusions">
          {previous ? (
            <li className="gzp-plate__inc gzp-plate__inc--carry gz-t-body-s" data-gz-id="planner.carry">
              <Icon name="plus" size="sm" tone="accent" />
              <span className="gz-sr-only">{t('clientPlannerEverythingIn')}</span>
              <TierMarks tier={previous.tier} />
              <span className="gzp-plate__carry-name">{bi(previous.name)}</span>
            </li>
          ) : null}
          {own.map((inc, i) => (
            <li key={i} className="gzp-plate__inc gz-t-body-s">
              <Icon name={inclusionGlyph(pkg.tier, i)} size="sm" tone="secondary" />
              <span>{label(pkg.tier, i, inc)}</span>
            </li>
          ))}
        </ul>
      </div>
    </article>
  )
}
