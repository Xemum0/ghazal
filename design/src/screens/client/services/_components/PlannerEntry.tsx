// PlannerEntry (CL-SERV-01): the wedding-planner door on the services hub. One quiet panel, a photograph of the room a planner would dress,
// the name and the lowest planner price (a "From" and a figure; no sentence, ADR 0034). It opens the planner packages (CL-PLAN-01). It is
// a way in, not a banner: paper and a hairline, no gold, no fill.
import { plannerPackages } from '../../../../mock'
import { useT } from '../../../../i18n'
import { Icon, Photo, Price, Skeleton, imageSrc, useBi } from '../../../../system'
import manifest from '../../../../../public/images/manifest.json'
import './planner-entry.css'

type ManifestImage = { file: string; alt_en: string; alt_ar: string }

/** A calm styled aisle from the curated library (no people); the planner fixtures' own stills are phone-on-desk shots. */
const PHOTO = 'context/context-52-hero-aisle-rose-petals-gold-lanterns.jpg'
const hit = (manifest as { images: ManifestImage[] }).images.find(i => i.file === PHOTO)

export type PlannerEntryProps = {
  onOpen?: () => void
  loading?: boolean
}

export function PlannerEntry({ onOpen, loading }: PlannerEntryProps) {
  const t = useT('client-services')
  const bi = useBi()
  if (loading) {
    return (
      <div className="gzs-planner is-loading" aria-busy="true" data-gz="PlannerEntry">
        <Skeleton variant="block" inlineSize={64} blockSize={80} />
        <div className="gzs-planner__text">
          <Skeleton inlineSize={140} blockSize={24} />
          <Skeleton inlineSize={96} blockSize={20} />
        </div>
      </div>
    )
  }
  const from = Math.min(...plannerPackages.map(p => p.from.fils))
  return (
    <button type="button" className="gz-reset gzs-planner gz-press" onClick={onOpen} data-gz="PlannerEntry">
      <span className="gzs-planner__thumb">
        <Photo src={imageSrc(PHOTO)} alt={hit ? bi({ en: hit.alt_en, ar: hit.alt_ar }) : ''} className="gzs-planner__photo" priority />
      </span>
      <span className="gzs-planner__text">
        <span className="gzs-planner__title gz-t-title">{t('clientServicesHubPlannerTitle')}</span>
        <span className="gzs-planner__price">
          <Price fils={from} size="strong" prefix={t('clientServicesFrom')} />
        </span>
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}
