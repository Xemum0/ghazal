// CL-ONBD-06 Preferred areas. Covers CA-ONB-06, CA-ONB-08, CA-ONB-09.
// Text diet (ADR 0034): the last step is a one-word title, a search and the six governorates as groups of chips; no lead, no sentences. Each
// group first shows the areas that have halls (a chip is just the area's name; how many halls the choice finds is the live count on the CTA), the rest sit behind `+N` (a figure and a chevron), and
// a search (Arabic-normalised, with a small alias table) looks through all of them. The pinned gold CTA is the live count of halls the
// choice will show (`3 halls`), with nothing chosen it counts every hall. It stores the Brief on the device and opens Home. Skip opens Home
// with no area. No location permission is asked here.
// States: default (Salmiya and Sharq, the demo persona), searching (a query typed), none-selected, offline (the count cannot refresh).
import { useState } from 'react'
import { ActionBar, Banner, Button, Chip, CountBadge, EmptyState, FactChip, Fig, Screen, SearchField, matchesSearch, useNav } from '../../../system'
import { useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { areasByGovernorate, listVenues, venues } from '../../../mock'
import { StepBar } from './_components/StepBar'
import { StepHead } from './_components/StepHead'
import { finishOnboarding } from './_components/profile'
import { useInStaticFrame, useScreenState } from './_components/useScreenState'
import './_components/form.css'
import './CL-ONBD-06.css'

export const states = ['searching', 'none-selected', 'offline']

/** The demo persona's areas (docs/product/fixtures.md): Salmiya and Sharq. */
const DEMO_AREAS = ['salmiya', 'sharq']
/** Search aliases (ADR 0012 D8): other spellings people type for the same place. Read by the search only, never shown. */
const ALIASES: Record<string, string[]> = {
  mishref: ['mishrif', 'meshref', 'مشرف'],
  salmiya: ['salmiyah', 'سالمية'],
  'jleeb-al-shuyoukh': ['jleeb', 'jileeb', 'جليب'],
  fahaheel: ['fahaheel', 'fahahil'],
  'al-rai': ['rai', 'الري'],
  khaitan: ['kheitan', 'kaitan'],
}

export default function ClOnbd06() {
  const t = useT('client-onboarding')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const state = useScreenState()
  const framed = useInStaticFrame()
  const saved = usePrototype(s => s.weddingProfile)

  const offline = state === 'offline'
  const startAreas = state === 'none-selected' ? [] : framed ? DEMO_AREAS : (saved?.areaIds ?? [])
  const [picked, setPicked] = useState<string[]>(startAreas)
  const [query, setQuery] = useState(state === 'searching' ? t('clientOnboardingAreasDemoQuery') : '')
  const [open, setOpen] = useState<string[]>([])

  const groups = areasByGovernorate()
  const hallsIn = (areaId: string) => venues.filter(v => v.areaId === areaId).length
  const searching = query.trim().length > 0

  const toggle = (id: string) => setPicked(p => (p.includes(id) ? p.filter(x => x !== id) : [...p, id]))
  const toggleOpen = (id: string) => setOpen(o => (o.includes(id) ? o.filter(x => x !== id) : [...o, id]))

  // What the choice will show on Home: the same query the Brief runs, so the number on the button is the number of cards.
  const guests = saved && saved.guests.women > 0 ? saved.guests.women : null
  const count = listVenues(picked.length ? { areaIds: picked } : {}, { guests, audience: 'women' }).length
  // The count of halls the choice will show; offline it cannot refresh, so the button just continues.
  const label = offline ? c('commonActionContinue') : c('commonCountHalls', { count })

  const rows = groups
    .map(({ governorate, areas }) => {
      const matches = searching ? areas.filter(a => matchesSearch(query, a.name.en, a.name.ar, ...(ALIASES[a.id] ?? []))) : areas
      const expanded = searching || open.includes(governorate.id)
      // Collapsed: the areas with halls and anything already chosen. Expanded or searching: every area of the group.
      const shown = expanded ? matches : matches.filter(a => hallsIn(a.id) > 0 || picked.includes(a.id))
      return { governorate, shown, hidden: matches.length - shown.length, expanded, total: matches.length, chosen: areas.filter(a => picked.includes(a.id)).length }
    })
    .filter(g => g.total > 0)

  const finish = (areaIds: string[]) => {
    finishOnboarding(areaIds)
    nav.reset('CL-DISC-01')
    if (areaIds.length) nav.toast(c('commonStateSaved'))
  }

  return (
    <Screen
      top={
        <>
          <StepBar step={4} total={4} onSkip={() => finish([])} />
          <div className="obd-areas__search">
            <SearchField value={query} onValueChange={setQuery} placeholder={t('clientOnboardingAreasSearch')} label={t('clientOnboardingAreasSearch')} />
          </div>
        </>
      }
      bottom={
        <ActionBar
          action={{ label, iconEnd: offline ? undefined : 'arrow-right', onPress: () => finish(picked) }}
          note={!offline && picked.length > 0 && count === 0 ? t('clientOnboardingAreasNoHallsNote') : undefined}
        />
      }
    >
      <div className="obd-form obd-areas">
        {offline ? <Banner tone="offline" shape="card">{c('commonStateOffline')}</Banner> : null}
        {!searching ? <StepHead title={t('clientOnboardingAreasTitle')} /> : null}

        {picked.length > 0 ? (
          <div className="obd-areas__summary" aria-live="polite">
            <FactChip icon="pin" label={t('clientOnboardingAreasSelected', { count: picked.length })} value={f.integer(picked.length)} />
            <Button variant="tertiary" onClick={() => setPicked([])}>
              {c('commonActionClear')}
            </Button>
          </div>
        ) : null}

        {rows.length === 0 ? (
          <EmptyState fill={false} illustration="no-result" title={c('commonStateTitleEmptySearch')} />
        ) : (
          rows.map(g => (
            <section className="obd-gov" key={g.governorate.id} aria-label={g.governorate.name[f.lang]}>
              <header className="obd-gov__head">
                <h2 className="obd-gov__name gz-t-body">{g.governorate.name[f.lang]}</h2>
                {g.chosen > 0 ? (
                  <span className="obd-gov__count" role="img" aria-label={t('clientOnboardingAreasSelected', { count: g.chosen })}>
                    <CountBadge count={g.chosen} />
                  </span>
                ) : null}
              </header>
              <div className="obd-gov__chips" role="group" aria-label={g.governorate.name[f.lang]}>
                {g.shown.map(a => (
                  <Chip key={a.id} selected={picked.includes(a.id)} onClick={() => toggle(a.id)}>
                    {a.name[f.lang]}
                  </Chip>
                ))}
                {!searching && (g.hidden > 0 || g.expanded) ? (
                  <Button
                    variant="tertiary"
                    iconEnd={g.expanded ? 'chevron-up' : 'chevron-down'}
                    onClick={() => toggleOpen(g.governorate.id)}
                    aria-expanded={g.expanded}
                    aria-label={g.expanded ? c('commonActionShowLess') : t('clientOnboardingAreasMore', { count: g.hidden })}
                  >
                    {g.expanded ? null : <Fig>{`+${f.integer(g.hidden)}`}</Fig>}
                  </Button>
                ) : null}
              </div>
            </section>
          ))
        )}
      </div>
    </Screen>
  )
}
