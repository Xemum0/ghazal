// Planner flow, shared local pieces: the ruled wedding line, the tier marks and thumb, the sheet title row, the planner identity and the
// request summary. System primitives only (FactChip, ThreadBead, Avatar, BarButton); nothing here is a new component of the system.
// Facts are icon + value (docs/design/02-text-diet.md): no label sits on screen, the label is the accessible name.
import type { ReactNode } from 'react'
import type { PlannerTier } from '@gz/contracts'
import type { IconName } from '@gz/tokens'
import { getVenue } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Avatar, BarButton, FactChip, FactRow, Icon, Photo, ThreadBead, imageSrc, useBi, useDuration } from '../../../../system'
import { Fx } from './Fx'
import { inclusionShortKey, tierPhoto } from './tierMedia'
import { dayMonth, packageOf } from './plannerFlow'
import './planner.css'

const DAY_MS = 86_400_000

// ---------------------------------------------------------------- tier marks
export function TierMarks({ tier }: { tier: PlannerTier }) {
  const t = useT('client-planner')
  const count = packageOf(tier).marks
  return (
    <span className="gzp-marks" role="img" aria-label={t('clientPlannerMarks', { count })}>
      {Array.from({ length: count }, (_, i) => (
        <ThreadBead key={i} tone="gold" />
      ))}
    </span>
  )
}

/** The tier's photograph as a square thumb (1:1, radius 8): the request summary and the picker rows. */
export function TierThumb({ tier }: { tier: PlannerTier }) {
  const photo = tierPhoto(tier)
  return (
    <span className="gzp-thumb" aria-hidden="true">
      <Photo src={imageSrc(photo.file)} alt="" className="gzp-thumb__img" />
    </span>
  )
}

// ---------------------------------------------------------------- inclusion label
/** The label of one inclusion: its short label (two words, tier and position as in `inclusionGlyph`), else the fixture phrase. */
export function useInclusionLabel() {
  const t = useT('client-planner')
  const bi = useBi()
  return (tier: PlannerTier, index: number, phrase: { en: string; ar: string }): string => {
    const key = inclusionShortKey(tier, index)
    return key ? t(key) : bi(phrase)
  }
}

// ---------------------------------------------------------------- wedding line
export type ContextLineProps = {
  venueId: string
  /** `YYYY-MM-DD` of the wedding. */
  date: string
  /** Adds the days to go as a gold-700 fact. */
  countdown?: boolean
}

/** The ruled strip (hairline above and below) that says which wedding this is about: hall, date and, from My Wedding, the days to go, as facts. */
export function ContextLine({ venueId, date, countdown }: ContextLineProps) {
  const t = useT('client-planner')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const duration = useDuration()
  const venue = getVenue(venueId)
  const days = f.daysUntil(date)
  return (
    <div className="gzp-context" data-gz-id="planner.context">
      <FactRow label={t('clientPlannerWeddingLabel')}>
        <FactChip icon="hall" label={t('clientPlannerWeddingLabel')} value={bi(venue?.name)} />
        <FactChip icon="calendar" label={t('clientPlannerWeddingLabel')} value={<Fx text={dayMonth(f, date)} />} />
        {countdown && days > 0 ? (
          <FactChip icon="countdown" tone="accent" label={tc('commonCountdownDays', { count: days })} value={<Fx text={duration(days * DAY_MS)} />} />
        ) : null}
      </FactRow>
    </div>
  )
}

// ---------------------------------------------------------------- sheet title row
export function SheetHead({ title, onClose, leading }: { title: string; onClose?: () => void; leading?: ReactNode }) {
  const tc = useT('common')
  return (
    <div className="gzp-sheethead" data-gz-id="planner.sheethead">
      {leading}
      <h2 className="gzp-sheethead__title gz-t-d1">{title}</h2>
      <BarButton icon="close" label={tc('commonActionClose')} onPress={onClose} dataId="sheet.close" />
    </div>
  )
}

// ---------------------------------------------------------------- planner identity
export type PlannerIdentityProps = { name: string; role: string; tier: PlannerTier; action?: ReactNode }

/** The planner as a person: monogram, name, role, her package as thread marks and a word. `action` sits at inline-end (the chat glyph). */
export function PlannerIdentity({ name, role, tier, action }: PlannerIdentityProps) {
  const bi = useBi()
  const pkg = packageOf(tier)
  return (
    <div className="gzp-planner">
      <Avatar name={name} size="lg" />
      <div className="gzp-planner__text">
        <span className="gzp-planner__name gz-t-title">
          <bdi dir="auto">{name}</bdi>
        </span>
        <span className="gzp-planner__role gz-t-caption">{role}</span>
        <span className="gzp-planner__package gz-t-caption">
          <TierMarks tier={tier} />
          <span>{bi(pkg.name)}</span>
        </span>
      </div>
      {action ? <div className="gzp-planner__action">{action}</div> : null}
    </div>
  )
}

// ---------------------------------------------------------------- request summary
/** What was asked: the package (thumb, name, marks) and the wedding as two facts (hall, date). Used while a request waits for a planner. */
export function RequestSummary({ tier, venueId, date }: { tier: PlannerTier; venueId: string; date: string }) {
  const t = useT('client-planner')
  const f = useFormat()
  const bi = useBi()
  const { lang } = useLang()
  const pkg = packageOf(tier)
  const venue = getVenue(venueId)
  return (
    <div className="gzp-panel gzp-summary" data-gz-id="plan.summary">
      <TierThumb tier={tier} />
      <div className="gzp-summary__text">
        <span className="gzp-pkg__name">
          <span className="gz-t-d1" lang={lang}>
            {bi(pkg.name)}
          </span>
          <TierMarks tier={tier} />
        </span>
        <FactRow label={t('clientPlannerWeddingLabel')}>
          <FactChip icon="hall" label={t('clientPlannerWeddingLabel')} value={bi(venue?.name)} />
          <FactChip icon="calendar" label={t('clientPlannerWeddingLabel')} value={<Fx text={dayMonth(f, date)} />} />
        </FactRow>
      </div>
    </div>
  )
}

// ---------------------------------------------------------------- note inside a sheet
/** A quiet line inside a sheet body (the system Banner is built for a full-width screen body and would indent twice in a sheet). */
export function SheetNote({ icon, children, tone = 'tint' }: { icon: IconName; children: ReactNode; tone?: 'tint' | 'quiet' }) {
  return (
    <div className={`gzp-note gzp-note--${tone}`} role="status">
      <Icon name={icon} size="sm" />
      <p className="gzp-note__text gz-t-body-s">{children}</p>
    </div>
  )
}
