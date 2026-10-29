// CL-PLAN-01 Planner packages. Covers CA-PLAN-01, CA-PLAN-02, CA-PLAN-03, CA-PLAN-04, CA-PLAN-09.
// Silver | Gold | Royal in a segmented control above one full-width plate (photograph, name and marks, from-price with its terms behind the
// info glyph, the inclusions as glyph + two-word rows), or all three side by side in the compare table (the same row and range parts as Compare
// venues). The one gold action is the pinned "Request consultation"; "Not now" is the close glyph of the offer after a booking and leaves
// no trace; its title is the offer question (CA-PLAN-01). Compare is the scale glyph in the bar. "Other planners" under the plate opens the
// event planning providers (CL-SERV-02, CA-SVC-13: planners who list their own voucher prices). The client is always signed in (ADR 0038).
import { useState } from 'react'
import type { PlannerTier } from '@gz/contracts'
import { plannerPackages, plannerRequest, type PlannerPackage } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import {
  ActionBar, Banner, CompareRow, ErrorState, Icon, IconListRow, Photo, Price, RangeBar, Screen, SegmentedControl, Skeleton, TopBar,
  imageSrc, useBi, useNav,
} from '../../../system'
import { ContextLine, TierMarks, useInclusionLabel } from './_components/parts'
import { TierPlate } from './_components/TierPlate'
import { tierPhoto } from './_components/tierMedia'
import { usePlannerFlow } from './_components/plannerFlow'
import './CL-PLAN-01.css'

export const states = ['from-booking', 'from-my-wedding', 'compare-table', 'loading', 'error', 'offline']

type Entry = 'booking' | 'my-wedding' | 'services'
type Params = { from?: Entry; venueId?: string; date?: string; tier?: PlannerTier }

/** Which tier each inclusion first appears in: Gold and Royal open with "Everything in ..." and then list what they add. */
function inclusionMatrix(pkgs: readonly PlannerPackage[]) {
  const rows: { index: number; label: PlannerPackage['inclusions'][number]; from: number; tier: PlannerTier; position: number }[] = []
  pkgs.forEach((pkg, tierIndex) => {
    pkg.inclusions
      .slice(tierIndex === 0 ? 0 : 1)
      .forEach((label, position) => rows.push({ index: rows.length, label, from: tierIndex, tier: pkg.tier, position }))
  })
  return rows
}

export default function PlannerPackages() {
  const t = useT('client-planner')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const inclusion = useInclusionLabel()
  const { lang } = useLang()
  const frame = useFrame()
  const nav = useNav<Params>()
  const tier = usePlannerFlow(s => s.draft.tier)
  const setTier = usePlannerFlow(s => s.setTier)
  const [compareLive, setCompareLive] = useState(false)

  const state = frame.state
  const compare = state === 'compare-table' || compareLive
  const entry: Entry = state === 'from-booking' ? 'booking' : state === 'from-my-wedding' ? 'my-wedding' : (nav.params.from ?? 'services')
  const venueId = nav.params.venueId ?? plannerRequest.venueId ?? 'V01'
  const weddingDate = nav.params.date ?? plannerRequest.eventDate
  const pkg = plannerPackages.find(p => p.tier === tier) ?? plannerPackages[0]!
  const offline = state === 'offline'

  const request = () => nav.push('CL-PLAN-02', { tier })
  const notNow = () => {
    nav.toast({ message: t('clientPlannerNotNowToast') })
    if (nav.canGoBack) nav.pop()
    else nav.switchTab('my-wedding')
  }

  const top = compare ? (
    <TopBar title={t('clientPlannerCompareTitle')} back={!nav.canGoBack ? true : 'auto'} onBack={() => setCompareLive(false)} />
  ) : (
    <TopBar
      title={entry === 'booking' ? t('clientPlannerOfferTitle') : t('clientPlannerTitle')}
      back={entry === 'booking' ? 'close' : 'auto'}
      onBack={entry === 'booking' ? notNow : undefined}
      actions={
        state === 'loading' || state === 'error'
          ? []
          : [{ icon: 'compare', label: t('clientPlannerCompareLabel'), onPress: () => setCompareLive(true) }]
      }
    />
  )

  const bar = (
    <ActionBar
      action={{
        label: t('clientPlannerRequestConsultation'),
        onPress: request,
        disabled: offline,
      }}
    />
  )

  // ---------------------------------------------------------------- loading and error
  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="gzp1-sticky" aria-busy="true">
          <Skeleton blockSize={52} />
        </div>
        <TierPlate pkg={pkg} loading />
      </Screen>
    )
  }
  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => nav.toast({ message: t('clientPlannerRetryToast'), tone: 'danger' })} />
      </Screen>
    )
  }

  const offlineBanner = offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null

  // ---------------------------------------------------------------- compare table
  if (compare) {
    const rows = inclusionMatrix(plannerPackages)
    const maxFrom = Math.max(...plannerPackages.map(p => p.from.fils))
    const owners = plannerPackages.map(p => bi(p.name))
    return (
      <Screen top={top} bottom={bar}>
        {offlineBanner}
        <div className="gzp1-heads" role="radiogroup" aria-label={t('clientPlannerTierPickerLabel')}>
          {plannerPackages.map(p => {
            const chosen = p.tier === tier
            return (
              <button
                key={p.id}
                type="button"
                role="radio"
                aria-checked={chosen}
                aria-label={chosen ? t('clientPlannerCompareChosen', { name: bi(p.name) }) : t('clientPlannerCompareChoose', { name: bi(p.name) })}
                className={`gz-reset gzp1-headcol gz-press${chosen ? ' is-chosen' : ''}`}
                onClick={() => setTier(p.tier)}
                data-gz-id={`head.${p.tier}`}
              >
                <span className="gzp1-headcol__thumb">
                  <Photo src={imageSrc(tierPhoto(p.tier).file)} alt="" className="gzp1-headcol__photo" />
                </span>
                <span className="gzp1-headcol__name gz-t-compare-name" lang={lang}>
                  {bi(p.name)}
                </span>
                <span className="gzp1-headcol__marks">
                  <TierMarks tier={p.tier} />
                </span>
              </button>
            )
          })}
        </div>
        <CompareRow
          label={t('clientPlannerFromPrefix')}
          owners={owners}
          cells={plannerPackages.map(p => (
            <span key={p.id} className="gzp1-fromcell">
              <Price fils={p.from.fils} size="strong" />
              <RangeBar decorative value={p.from.fils} max={maxFrom} label={f.money(p.from.fils)} />
            </span>
          ))}
        />
        {rows.map(row => (
          <CompareRow
            key={row.index}
            label={inclusion(row.tier, row.position, row.label)}
            owners={owners}
            cells={plannerPackages.map((p, i) => {
              const included = i >= row.from
              return (
                <span key={p.id} className="gzp1-tick">
                  {included ? <Icon name="check" size="sm" tone="accent" /> : <span className="gzp1-dash" aria-hidden="true">—</span>}
                  <span className="gz-sr-only">{included ? t('clientPlannerIncluded') : t('clientPlannerNotIncluded')}</span>
                </span>
              )
            })}
          />
        ))}
      </Screen>
    )
  }

  // ---------------------------------------------------------------- one package at a time
  return (
    <Screen top={top} bottom={bar}>
      {offlineBanner}
      {entry !== 'services' ? (
        <div className="gzp1-context">
          <ContextLine venueId={venueId} date={weddingDate} countdown={entry === 'my-wedding'} />
        </div>
      ) : null}

      <div className="gzp1-sticky">
        {/* flutter-ok: pinned sliver */}
        <SegmentedControl<PlannerTier>
          label={t('clientPlannerTierPickerLabel')}
          value={tier}
          onChange={setTier}
          options={plannerPackages.map(p => ({ value: p.tier, label: bi(p.name) }))}
        />
      </div>

      <TierPlate key={pkg.id} pkg={pkg} />

      <div className="gzp1-more">
        <IconListRow
          flush
          icon="search"
          title={t('clientPlannerOtherPlanners')}
          onClick={() => nav.push('CL-SERV-02', { categoryId: 'event_planning' })}
          last
        />
      </div>
    </Screen>
  )
}
