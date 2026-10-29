// CL-DISC-02 Your Brief (sheet). Covers CA-HOME-02 to CA-HOME-06, CA-ONB-08, CA-ONB-09, CA-FLT-01.
// The single editor of the global Brief, opened from the Home card, the Results echo, Compare ("Set your date") and Saved. Four 64 rows, each
// a glyph and its value (Date, Governorate, Guests with the section glyph, Budget); each opens its focused picker inside the sheet (a calendar
// with the two honest alternatives, wrapping governorate chips, a three-way section control with preset chips and a stepper, budget
// bands over a histogram). Under the rows a strip of the halls that fit (photographs only). The footer is pinned: the one gold CTA with the
// live count and "Clear"; it applies the draft. Dismissing discards it. There is no merge variant (ADR 0038: nobody builds a Brief before signing in).
// ADR 0038 (CA-FLT-08): the region row is governorates only (the shared GovernorateFilter chips, the count in the panel title), never an
// exact area. The Brief keeps the guest count because it prices the card (the capacity range is a filter, CL-DISC-04).
// Text diet (ADR 0034): no row labels, no helper sentences, no preview captions; the budget picker keeps one four-word caption because it
// prevents a real mistake (this is the hall budget, not the whole wedding).
// States: default, date-not-decided, flexible-month, loading, offline.
import { useMemo, useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import * as mock from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { useLang } from '../../../shell/lang'
import { BarButton, Banner, Button, Figures, Icon, Photo, SheetHeader, briefGovernorates, imageSrc, useBi, useNav } from '../../../system'
import { BudgetPanel } from './_components/brief/BudgetPanel'
import { DatePanel, type DateView } from './_components/brief/DatePanel'
import { GovernoratePanel } from './_components/brief/GovernoratePanel'
import { GuestsPanel } from './_components/brief/GuestsPanel'
import type { BriefDraft, PanelId } from './_components/brief/types'
import { NO_FILTERS, freeCount, results, type SearchBrief } from './_components/data'
import { useScenario } from './_components/scenario'
import { useDiscover } from './_components/state'
import { useOpenBudget } from './_components/useOpenBudget'
import { useSheetFill } from './_components/useSheetFill'
import './_components/brief/brief.css'
import './CL-DISC-02.css'

export const states = ['date-not-decided', 'flexible-month', 'loading', 'offline']

const FLEXIBLE_EXAMPLE_DATE = '2027-03-01'

const isPanel = (v: unknown): v is PanelId => v === 'date' || v === 'area' || v === 'guests' || v === 'budget'

export default function BriefSheet() {
  const { state } = useFrame()
  const t = useT('client-discover')
  const shell = useT('client-shell')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const bi = useBi()
  const { lang } = useLang()
  const budgetOver = useOpenBudget()
  const s = useScenario(state)
  const fill = useSheetFill()
  const live = s.live

  const profile = mock.weddingProfile
  const [draft, setDraft] = useState<BriefDraft>(() => {
    let brief: SearchBrief = s.brief
    if (!live && state === 'date-not-decided') brief = { ...brief, date: null, dateMode: 'undecided' }
    if (!live && state === 'flexible-month') brief = { ...brief, date: FLEXIBLE_EXAMPLE_DATE, dateMode: 'flexible_month' }
    const counts = { women: profile.guests.women, men: profile.guests.men }
    return { brief, split: brief.audience !== 'mixed', counts, later: !live && state === 'date-not-decided' }
  })
  const focus = isPanel(nav.params.focus) ? nav.params.focus : null
  const [panel, setPanel] = useState<PanelId | null>(!live && state === 'date-not-decided' ? 'date' : !live && state === 'flexible-month' ? 'date' : focus)

  const loading = state === 'loading'
  const offline = state === 'offline' || !s.online
  const brief = draft.brief
  const count = useMemo(() => freeCount(brief), [brief])
  const fit = useMemo(() => results(brief, { ...NO_FILTERS, available: Boolean(brief.date) }), [brief])
  const preview = fit.slice(0, 4)

  // ---- what each row says: a glyph, then the value (the row's name is the accessible name)
  const none = c('commonLabelNotDecided')
  const governorates = briefGovernorates(brief)
  const names = governorates.map(id => mock.getGovernorate(id)).filter((g): g is NonNullable<ReturnType<typeof mock.getGovernorate>> => Boolean(g)).map(g => bi(g.name))
  const flexible = brief.dateMode === 'flexible_month' && Boolean(brief.date)
  const sectionGlyph = brief.audience === 'men' ? 'section-men' : brief.audience === 'mixed' ? 'section-mixed' : brief.audience === 'women' ? 'section-women' : null
  const rows: { id: PanelId; label: string; icon: IconName; value: string | null; placeholder: string; extra?: ReactNode }[] = [
    {
      id: 'date',
      label: shell('clientShellBriefDate'),
      icon: flexible ? 'calendar-dots' : 'calendar',
      value: flexible && brief.date ? f.date(brief.date, 'monthYear') : brief.date && brief.dateMode === 'exact' ? f.date(brief.date, 'short') : null,
      placeholder: draft.later ? none : t('clientDiscoverBriefChooseDate'),
    },
    { id: 'area', label: t('clientDiscoverBriefChooseGovernorate'), icon: 'pin', value: names.length ? names.join(lang === 'ar' ? '، ' : ', ') : null, placeholder: t('clientDiscoverBriefChooseGovernorate') },
    {
      id: 'guests',
      label: shell('clientShellBriefGuests'),
      icon: 'users-three',
      value: brief.guests ? f.integer(brief.guests) : null,
      placeholder: t('clientDiscoverBriefAddGuests'),
      extra: brief.guests && sectionGlyph ? <Icon name={sectionGlyph} size="sm" tone="secondary" className="gzd-brs__section" /> : null,
    },
    {
      id: 'budget',
      label: shell('clientShellBriefBudget'),
      icon: 'wallet',
      value: brief.budget ? (brief.budget.max ? f.moneyRange(brief.budget.min.fils, brief.budget.max.fils, { mode: 'browse' }) : budgetOver(brief.budget.min.fils)) : null,
      placeholder: t('clientDiscoverBriefSetBudget'),
    },
  ]

  // ---- actions
  const cta = loading ? t('clientDiscoverCtaShow') : offline ? t('clientDiscoverCtaShow') : count === 0 && brief.date ? t('clientDiscoverCtaNearest') : t('clientDiscoverCtaCount', { count })

  const apply = () => {
    if (!live) return nav.closeSheet()
    s.setBrief(brief)
    // The Results list follows the new Brief; keep the filters the person chose, drop only the stale availability default.
    const st = useDiscover.getState()
    if (st.seededFrom !== null) st.replaceFilters({ ...st.filters, available: st.filters.available && Boolean(brief.date) })
    nav.closeSheet()
    if (nav.params.from === 'home') nav.push('CL-DISC-03', { from: 'discover', filters: { ...NO_FILTERS, available: Boolean(brief.date) } })
  }
  // The guests panel shows the story count (350) as selected while the Brief still holds none; Done on that default has to commit it,
  // otherwise "Add guests" stays on the Brief and the venue has no quote to price (walk finding).
  const closePanel = () => {
    if (panel === 'guests' && draft.brief.guests === null) {
      setDraft(d => ({ ...d, brief: { ...d.brief, guests: d.brief.audience === 'men' && d.split ? d.counts.men : d.counts.women } }))
    }
    setPanel(null)
  }
  const clear = () => setDraft(d => ({ ...d, brief: { date: null, guests: null, audience: null, areaIds: [], governorateIds: [], budget: null, dateMode: 'undecided' } }))

  const panelTitle: Record<PanelId, string> = {
    date: t('clientDiscoverBriefDateTitle'),
    area: t('clientDiscoverBriefGovernorateTitle', { count: governorates.length }),
    guests: t('clientDiscoverBriefGuestsTitle'),
    budget: t('clientDiscoverBriefBudgetTitle'),
  }
  const initialDateView: DateView | undefined = !live && state === 'date-not-decided' ? 'undecided' : !live && state === 'flexible-month' ? 'months' : undefined

  return (
    <div className="gzd-brs" data-gz-id="brief.sheet" style={{ blockSize: fill }}>
      {panel ? (
        <header className="gz-sheet__header gzd-brs__panelhead" data-gz-id="brief.panelhead">
          <BarButton icon="back" label={t('clientDiscoverBriefBack')} onPress={() => setPanel(null)} dataId="brief.back" />
          <h2 className="gz-sheet__title gz-t-d1">{panelTitle[panel]}</h2>
        </header>
      ) : (
        <SheetHeader title={t('clientDiscoverBriefTitle')} onClose={() => nav.closeSheet()} />
      )}

      <div className="gzd-brs__scroll gz-no-scrollbar">
        {offline ? (
          <div className="gzd-brs__banner">
            <Banner tone="offline" shape="card">{c('commonStateOffline')}</Banner>
          </div>
        ) : null}

        {panel === null ? (
          <div className="gzd-brs__main">
          <ul className="gzd-brs__rows" aria-label={t('clientDiscoverBriefTitle')}>
            {rows.map(r => (
              <li key={r.id}>
                <button
                  type="button"
                  className="gz-reset gz-briefrow gz-press gzd-brs__row"
                  onClick={() => setPanel(r.id)}
                  data-gz-id={`brief.row.${r.id}`}
                  aria-label={`${r.label}: ${r.value ?? r.placeholder}`}
                >
                  <Icon name={r.icon} size="md" tone="secondary" />
                  <span className="gz-briefrow__text">
                    <span className="gz-sr-only">{r.label}</span>
                    <span className={`gz-briefrow__value gz-t-body gz-ellipsis${r.value === null ? ' is-empty' : ''}`}>
                      <Figures text={r.value ?? r.placeholder} />
                      {r.extra}
                    </span>
                  </span>
                  <Icon name="chevron-right" size="sm" tone="secondary" />
                </button>
              </li>
            ))}
          </ul>
          {!loading && !offline && preview.length > 0 ? (
            <button type="button" className="gz-reset gzd-brs__preview gz-press" onClick={apply} data-gz-id="brief.preview" aria-label={c('commonCountHalls', { count: fit.length })}>
              <span className="gzd-brs__thumbs" aria-hidden="true">
                {preview.map(r => (
                  <span key={r.venue.id} className="gzd-brs__thumb">
                    {r.venue.cover ? <Photo src={imageSrc(r.venue.cover.file)} alt="" className="gzd-brs__photo" /> : null}
                  </span>
                ))}
              </span>
              {fit.length > preview.length ? (
                <span className="gzd-brs__more gz-t-fig-body-s" aria-hidden="true">
                  <Figures text={`+${f.integer(fit.length - preview.length)}`} />
                </span>
              ) : null}
            </button>
          ) : null}
          </div>
        ) : panel === 'date' ? (
          <DatePanel draft={draft} set={setDraft} initialView={initialDateView} />
        ) : panel === 'area' ? (
          <GovernoratePanel draft={draft} set={setDraft} />
        ) : panel === 'guests' ? (
          <GuestsPanel draft={draft} set={setDraft} />
        ) : (
          <BudgetPanel draft={draft} set={setDraft} />
        )}
      </div>

      <div className="gzd-brs__foot" data-gz-id="brief.foot">
        {panel === null ? (
          <>
            <Button variant="primary" fullWidth onClick={apply} loading={loading}>
              <Figures text={cta} />
            </Button>
            <div className="gzd-brs__clear">
              <Button variant="tertiary" onClick={clear}>
                {t('clientDiscoverBriefClear')}
              </Button>
            </div>
          </>
        ) : (
          <Button variant="primary" fullWidth onClick={() => closePanel()}>
            {t('clientDiscoverBriefDone')}
          </Button>
        )}
      </div>
    </div>
  )
}
