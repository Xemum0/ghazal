// The Studio sidebar. Two tabs: Flows (app switcher, build coverage, screen search, the flows and their screens) and System (the
// component gallery pages, the tokens, the direction documents). Counts and the built marks come from comparing the screen registry
// with the inventory, so the list is honest while screens are still being built.
import { useDeferredValue, useEffect, useMemo, useState } from 'react'
import { Icon } from '../../../system'
import { SegmentedControl, Tabs, matchesSearch } from '../../../system/inputs'
import { useLang } from '../../lang'
import { go } from '../../router'
import { galleryPages, isBuilt, screenEntries } from '../../registry'
import { BuiltMark, Id, Khayt } from '../bits'
import { canvas, canvasBridge } from '../canvas/bridge'
import { pickLoc, useCopy } from '../copy'
import { FLOWS, SCREENS, SCREEN_BY_ID, screenCount, type AppId, type FlowDef, type ScreenDef } from '../data/inventory'
import { DOCS, galleryRank, galleryTitle, isSystemPage } from '../docs/docs'
import { canvasHash, docsHash, playHash, systemHash } from '../links'
import { useStudioRoute } from '../route'
import { useStudio } from '../store'
import { Glyph } from './Glyph'

type Tab = 'flows' | 'system'

export function Sidebar() {
  const t = useCopy()
  const r = useStudioRoute()
  const open = useStudio(s => s.sidebarOpen)
  const [tab, setTab] = useState<Tab>(r.view === 'system' || r.view === 'docs' ? 'system' : 'flows')
  // Arriving on a gallery or doc page (a deep link) shows the System tab.
  useEffect(() => {
    if (r.view === 'system' || r.view === 'docs') setTab('system')
    else setTab('flows')
  }, [r.view])

  return (
    <aside className="gzs-sidebar" data-gz="Sidebar" data-open={open || undefined} aria-label={t('studioFull')} inert={open ? undefined : true}>
      <div className="gzs-sidebar__in">
        <Tabs<Tab>
          label={t('studioFull')}
          value={tab}
          onChange={setTab}
          items={[
            { value: 'flows', label: t('flows') },
            { value: 'system', label: t('designSystem') },
          ]}
        />
        {tab === 'flows' ? <FlowsPanel /> : <SystemPanel />}
      </div>
    </aside>
  )
}

// ---------------------------------------------------------------- flows

function useOpenScreen() {
  const r = useStudioRoute()
  const { lang } = useLang()
  return (id: string) => {
    const s = SCREEN_BY_ID.get(id)
    if (!s) return
    if (r.view === 'canvas' && s.app === r.app && canvasBridge.current) canvas.focusScreen(id)
    else if (r.view === 'play') go(playHash(s.app, id, { lang, w: r.w }, { story: r.story }))
    else go(canvasHash(s.app, { lang, w: r.w }, { focus: id }))
  }
}

function FlowsPanel() {
  const t = useCopy()
  const { lang } = useLang()
  const r = useStudioRoute()
  const selected = useStudio(s => s.selected)
  const open = useOpenScreen()
  const [query, setQuery] = useState('')
  const deferred = useDeferredValue(query)
  const [expanded, setExpanded] = useState<ReadonlySet<string>>(() => new Set())

  const flows = FLOWS[r.app]
  const total = screenCount(r.app)
  const built = flows.reduce((n, f) => n + f.screens.filter(s => isBuilt(s.id)).length, 0)
  const selectedFlow = selected ? SCREEN_BY_ID.get(selected)?.flowId : undefined

  // The flow holding the selected screen opens by itself, so the sidebar always shows where you are.
  useEffect(() => {
    if (selectedFlow) setExpanded(prev => (prev.has(selectedFlow) ? prev : new Set(prev).add(selectedFlow)))
  }, [selectedFlow])

  const results = useMemo(() => {
    const q = deferred.trim()
    if (!q) return null
    return SCREENS.filter(s => s.app === r.app).filter(s => matchesSearch(q, s.id, s.title.en, s.title.ar, s.slug, s.requirementIds.join(' ')))
  }, [deferred, r.app])

  const toggle = (id: string) => setExpanded(prev => {
    const next = new Set(prev)
    if (next.has(id)) next.delete(id)
    else next.add(id)
    return next
  })

  const switchApp = (app: AppId) => go(canvasHash(app, { lang, w: r.w }))
  const extra = useMemo(() => screenEntries.filter(e => !SCREEN_BY_ID.has(e.id.toUpperCase())), [])

  return (
    <div className="gzs-sb">
      <div className="gzs-sb__head">
        <SegmentedControl<AppId>
          label={t('studio')}
          value={r.app}
          onChange={switchApp}
          options={[
            { value: 'client', label: <span className="gzs-sb__app">{t('client')} <span className="gz-num gzs-sb__app-n">{screenCount('client')}</span></span> },
            { value: 'hotel', label: <span className="gzs-sb__app">{t('hotel')} <span className="gz-num gzs-sb__app-n">{screenCount('hotel')}</span></span> },
          ]}
        />
        <div className="gzs-cover" role="img" aria-label={`${built} ${t('of')} ${total} ${t('built')}`}>
          <div className="gzs-cover__row gz-t-caption">
            <span className="gz-t-label">{t('coverage')}</span>
            <span><span className="gz-num">{built}</span> {t('of')} <span className="gz-num">{total}</span> {t('built')}</span>
          </div>
          <span className="gzs-cover__track"><span className="gzs-cover__fill" style={{ inlineSize: `${(built / Math.max(1, total)) * 100}%` }} /></span>
        </div>
        <label className="gzs-sb__search">
          <Icon name="search" size="sm" />
          <input
            type="search"
            className="gzs-sb__input gz-t-body-s"
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder={t('searchPlaceholder')}
            aria-label={t('searchLabel')}
            dir="auto"
            enterKeyHint="search"
          />
        </label>
      </div>

      <div className="gzs-sb__list gz-no-scrollbar" data-scroll>
        {results ? (
          results.length === 0 ? (
            <p className="gzs-sb__empty gz-t-body-s">{t('noResults')}</p>
          ) : (
            <ul className="gzs-sb__screens" role="list">
              {results.map(s => (
                <ScreenRow key={s.id} screen={s} selected={selected === s.id} onOpen={open} showFlow lang={lang} />
              ))}
            </ul>
          )
        ) : (
          <>
            <ul className="gzs-sb__flows" role="list">
              {flows.map((f, i) => (
                <FlowItem key={f.id} flow={f} index={i} open={expanded.has(f.id)} onToggle={() => toggle(f.id)} selected={selected} onOpen={open} lang={lang} />
              ))}
            </ul>
            {extra.length > 0 ? (
              <section className="gzs-sb__extra">
                <h3 className="gz-t-label">{t('extraBuilt')}</h3>
                <ul className="gzs-sb__screens" role="list">
                  {extra.map(e => (
                    <li key={e.id}>
                      <a className="gzs-sb__row" href={`#/frame/${e.id}?lang=${lang}`}>
                        <BuiltMark built />
                        <Id className="gz-t-fig-caption">{e.id}</Id>
                      </a>
                    </li>
                  ))}
                </ul>
              </section>
            ) : null}
          </>
        )}
      </div>
    </div>
  )
}

function FlowItem({
  flow,
  index,
  open,
  onToggle,
  selected,
  onOpen,
  lang,
}: {
  flow: FlowDef
  index: number
  open: boolean
  onToggle: () => void
  selected: string | null
  onOpen: (id: string) => void
  lang: 'en' | 'ar'
}) {
  const t = useCopy()
  const total = flow.screens.length
  const built = flow.screens.filter(s => isBuilt(s.id)).length
  const hasSel = selected ? flow.screens.some(s => s.id === selected) : false
  return (
    <li className="gzs-flow" data-open={open || undefined} data-current={hasSel || undefined}>
      <div className="gzs-flow__head">
        <button type="button" className="gz-reset gz-press gzs-flow__toggle" aria-expanded={open} onClick={onToggle}>
          <span className="gzs-flow__num gz-t-fig-caption">{String(index + 1).padStart(2, '0')}</span>
          <span className="gzs-flow__title gz-t-body-s">{pickLoc(flow.title, lang)}</span>
          <span className="gzs-flow__count gz-t-fig-caption" aria-label={`${built} ${t('of')} ${total} ${t('built')}`}>
            <span className="gz-num">{built}</span>/<span className="gz-num">{total}</span>
          </span>
          <Icon name={open ? 'chevron-up' : 'chevron-down'} size="xs" />
        </button>
        <button type="button" className="gz-reset gz-press gzs-flow__fit" aria-label={`${t('fit')}: ${pickLoc(flow.title, lang)}`} title={t('fit')} onClick={() => canvas.fitFlow(flow.id)}>
          <Glyph name="fit" size={16} />
        </button>
      </div>
      {built > 0 ? (
        <span className="gzs-flow__track" aria-hidden="true"><span className="gzs-flow__fill" style={{ inlineSize: `${(built / Math.max(1, total)) * 100}%` }} /></span>
      ) : null}
      {open ? (
        <ul className="gzs-sb__screens" role="list">
          {flow.screens.map(s => (
            <ScreenRow key={s.id} screen={s} selected={selected === s.id} onOpen={onOpen} lang={lang} />
          ))}
        </ul>
      ) : null}
    </li>
  )
}

function ScreenRow({ screen, selected, onOpen, showFlow, lang }: { screen: ScreenDef; selected: boolean; onOpen: (id: string) => void; showFlow?: boolean; lang: 'en' | 'ar' }) {
  const built = isBuilt(screen.id)
  const flow = showFlow ? FLOWS[screen.app].find(f => f.id === screen.flowId) : undefined
  return (
    <li>
      <button type="button" className="gz-reset gz-press gzs-sb__row" data-selected={selected || undefined} aria-current={selected || undefined} onClick={() => onOpen(screen.id)}>
        <BuiltMark built={built} />
        <span className="gzs-sb__text">
          <span className="gzs-sb__name gz-t-body-s">{pickLoc(screen.title, lang)}</span>
          <span className="gzs-sb__meta gz-t-caption">
            <Id className="gz-t-fig-caption">{screen.id}</Id>
            {flow ? <span> · {pickLoc(flow.title, lang)}</span> : null}
          </span>
        </span>
      </button>
    </li>
  )
}

// ---------------------------------------------------------------- system

function SystemPanel() {
  const t = useCopy()
  const { lang } = useLang()
  const r = useStudioRoute()
  const pages = galleryPages.filter(p => isSystemPage(p.id)).sort((a, b) => galleryRank(a.id) - galleryRank(b.id) || a.id.localeCompare(b.id))
  const here = (view: 'system' | 'docs', id: string) => r.view === view && r.page === id
  return (
    <div className="gzs-sb gzs-sb--system">
      <div className="gzs-sb__list gz-no-scrollbar" data-scroll>
        <section className="gzs-sys">
          <h3 className="gz-t-label gzs-sys__h">{t('galleryPages')}</h3>
          <ul role="list">
            {pages.map(p => {
              const g = galleryTitle(p.id)
              return (
                <li key={p.id}>
                  <a className="gzs-sys__row gz-press" href={systemHash(p.id, lang)} aria-current={here('system', p.id) || undefined}>
                    <Glyph name={p.id === 'tokens' ? 'swatch' : 'layers'} size={20} />
                    <span className="gzs-sb__text">
                      <span className="gzs-sb__name gz-t-body-s">{pickLoc(g.title, lang)}</span>
                      {g.note ? <span className="gzs-sb__meta gz-t-caption">{pickLoc(g.note, lang)}</span> : null}
                    </span>
                  </a>
                </li>
              )
            })}
          </ul>
        </section>
        <section className="gzs-sys">
          <h3 className="gz-t-label gzs-sys__h">{t('reference')}</h3>
          <ul role="list">
            {DOCS.map(d => (
              <li key={d.id}>
                <a className="gzs-sys__row gz-press" href={docsHash(d.id, lang)} aria-current={here('docs', d.id) || undefined}>
                  <Glyph name="book" size={20} />
                  <span className="gzs-sb__text">
                    <span className="gzs-sb__name gz-t-body-s">{pickLoc(d.title, lang)}</span>
                    <span className="gzs-sb__meta gz-t-caption">{pickLoc(d.note, lang)}</span>
                  </span>
                </a>
              </li>
            ))}
          </ul>
        </section>
        <section className="gzs-sys">
          <Khayt />
          <p className="gzs-sys__note gz-t-caption">{t('fixedNow')}</p>
        </section>
      </div>
    </div>
  )
}
