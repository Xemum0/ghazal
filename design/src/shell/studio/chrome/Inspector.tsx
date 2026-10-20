// The inspector: what the selected frame is, from the inventory (purpose, requirements with their text, states, interactions,
// where it leads) and what it actually uses (a token scan of the rendered frame). "Open in player" starts the prototype there.
import { useEffect, useState } from 'react'
import { Button, Chip, Icon } from '../../../system'
import { useLang } from '../../lang'
import { go } from '../../router'
import { isBuilt } from '../../registry'
import { BuiltMark, Id, Khayt, stateLabel } from '../bits'
import { canvas } from '../canvas/bridge'
import { exportedStates } from '../canvas/useBoard'
import { pickLoc, useCopy } from '../copy'
import { FLOWS, SCREEN_BY_ID, getScreen, reachedFrom, type ScreenDef } from '../data/inventory'
import { useRequirements } from '../data/requirements'
import { playHash } from '../links'
import { useStudioRoute } from '../route'
import { useStudio } from '../store'
import { scanTokens, type ScanResult } from './tokenScan'

export function Inspector() {
  const t = useCopy()
  const open = useStudio(s => s.inspectorOpen)
  const selected = useStudio(s => s.selected)
  const toggle = useStudio(s => s.toggle)
  const screen = getScreen(selected)
  return (
    <aside className="gzs-inspector" data-gz="Inspector" data-open={open || undefined} aria-label={t('inspector')} inert={open ? undefined : true}>
      <div className="gzs-inspector__in">
        <div className="gzs-inspector__bar">
          <span className="gz-t-label">{t('inspector')}</span>
          <button type="button" className="gz-reset gz-press gzs-inspector__close" aria-label={t('panelClose')} onClick={() => toggle('inspectorOpen')}>
            <Icon name="close" size="sm" />
          </button>
        </div>
        <div className="gzs-inspector__body gz-no-scrollbar" data-scroll>
          {screen ? <Details key={screen.id} screen={screen} /> : <Empty />}
        </div>
      </div>
    </aside>
  )
}

function Empty() {
  const t = useCopy()
  return (
    <div className="gzs-inspector__empty">
      <Khayt />
      <h2 className="gz-t-d1">{t('noSelectionTitle')}</h2>
      <p className="gz-t-body-s">{t('noSelection')}</p>
    </div>
  )
}

function Details({ screen }: { screen: ScreenDef }) {
  const t = useCopy()
  const { lang } = useLang()
  const r = useStudioRoute()
  const reqs = useRequirements()
  const override = useStudio(s => s.stateOverride[screen.id])
  const setOverride = useStudio(s => s.setStateOverride)
  const built = isBuilt(screen.id)
  const flow = FLOWS[screen.app].find(f => f.id === screen.flowId)
  const kind = screen.kind === 'sheet' ? t('kindSheet') : screen.kind === 'tab-root' ? t('kindTabRoot') : t('kindScreen')
  const from = reachedFrom(screen.id)
  // A built screen that exports its states offers exactly those; otherwise the inventory's list (a design reference).
  const exported = built ? exportedStates(screen.id) : []
  const stateList = exported.length > 0 ? exported : screen.states

  const link = (id: string) => {
    const s = SCREEN_BY_ID.get(id)
    if (s) canvas.focusScreen(id)
  }

  return (
    <article className="gzs-insp">
      <header className="gzs-insp__head">
        <Khayt />
        <h2 className="gzs-insp__title gz-t-d2">{pickLoc(screen.title, lang)}</h2>
        <p className="gzs-insp__line gz-t-caption">
          <Id className="gz-t-fig-body-s">{screen.id}</Id>
          {flow ? <span>{pickLoc(flow.title, lang)}</span> : null}
        </p>
        <div className="gzs-insp__tags">
          <BuiltMark built={built} label />
          <span className="gzs-insp__tag gz-t-caption">{kind}</span>
          <span className="gzs-insp__tag gz-t-caption" data-core={screen.priority === 'core' || undefined}>{screen.priority === 'core' ? t('priorityCore') : t('priorityStd')}</span>
        </div>
        <div className="gzs-insp__actions">
          <Button variant="secondary" size="sm" iconStart="play" onClick={() => go(playHash(screen.app, screen.id, { lang, w: r.w }))}>
            {t('openInPlayer')}
          </Button>
          {built ? (
            <Button variant="tertiary" size="sm" iconEnd="external-link" onClick={() => window.open(`#/frame/${screen.id}?lang=${lang}`, '_blank', 'noopener')}>
              {t('openBare')}
            </Button>
          ) : null}
        </div>
      </header>

      <Section title={t('purpose')}>
        <p className="gz-t-body-s gzs-insp__text" dir="auto">{screen.purpose}</p>
      </Section>

      <Section title={t('requirements')} count={screen.requirementIds.length}>
        <ul className="gzs-reqs" role="list">
          {screen.requirementIds.map(id => (
            <li key={id} className="gzs-reqs__item">
              <Id className="gzs-reqs__id gz-t-fig-caption">{id}</Id>
              <span className="gzs-reqs__text gz-t-body-s" dir="auto">{reqs?.get(id)?.text ?? (reqs ? '' : t('loadingText'))}</span>
            </li>
          ))}
        </ul>
      </Section>

      {stateList.length > 0 ? (
        <Section title={t('states')} count={stateList.length}>
          <div className="gzs-insp__chips" role="group" aria-label={t('states')}>
            {['default', ...stateList.filter(s => s !== 'default')].map(s => (
              <Chip key={s} selected={(override ?? 'default') === s} onClick={() => setOverride(screen.id, s === 'default' ? null : s)}>
                {s === 'default' ? t('default') : stateLabel(s)}
              </Chip>
            ))}
          </div>
          {!built ? <p className="gzs-insp__hint gz-t-caption">{t('notBuiltBody')}</p> : null}
        </Section>
      ) : null}

      <Section title={t('interactions')} count={screen.interactions.length}>
        <ol className="gzs-insp__list gz-t-body-s">
          {screen.interactions.map((x, i) => (
            <li key={i} dir="auto">{x}</li>
          ))}
        </ol>
      </Section>

      <Section title={t('goesTo')} count={screen.navigatesTo.length}>
        <Links ids={screen.navigatesTo} onOpen={link} lang={lang} empty={t('noExits')} />
      </Section>
      {from.length > 0 ? (
        <Section title={t('reachedFrom')} count={from.length}>
          <Links ids={from} onOpen={link} lang={lang} />
        </Section>
      ) : null}

      <TokensUsed screen={screen} built={built} />
    </article>
  )
}

function Section({ title, count, children }: { title: string; count?: number; children: React.ReactNode }) {
  return (
    <section className="gzs-insp__sec">
      <h3 className="gzs-insp__h gz-t-label">
        {title}
        {count !== undefined ? <span className="gzs-insp__n gz-num">{count}</span> : null}
      </h3>
      {children}
    </section>
  )
}

function Links({ ids, onOpen, lang, empty }: { ids: string[]; onOpen: (id: string) => void; lang: 'en' | 'ar'; empty?: string }) {
  if (ids.length === 0) return empty ? <p className="gz-t-caption gzs-insp__hint">{empty}</p> : null
  return (
    <ul className="gzs-links" role="list">
      {ids.map(id => {
        const s = SCREEN_BY_ID.get(id)
        return (
          <li key={id}>
            <button type="button" className="gz-reset gz-press gzs-links__row" onClick={() => onOpen(id)} disabled={!s}>
              <Id className="gz-t-fig-caption gzs-links__id">{id}</Id>
              <span className="gz-t-body-s gzs-links__name">{s ? pickLoc(s.title, lang) : ''}</span>
              <Icon name="chevron-right" size="xs" />
            </button>
          </li>
        )
      })}
    </ul>
  )
}

// ---------------------------------------------------------------- tokens used

function TokensUsed({ screen, built }: { screen: ScreenDef; built: boolean }) {
  const t = useCopy()
  const [scan, setScan] = useState<ScanResult | null>(null)
  const [busy, setBusy] = useState(false)
  const override = useStudio(s => s.stateOverride[screen.id])

  useEffect(() => {
    setScan(null)
    if (!built) return
    let live = true
    setBusy(true)
    // Give the frame time to mount (it is lazy) and settle, then read it once the browser is idle.
    const timer = window.setTimeout(() => {
      const run = () => {
        const frame = document.querySelector(`[data-frame-key="${screen.id}"][data-mounted] .gz-device__screen`)
        if (live) {
          setScan(frame ? scanTokens(frame) : null)
          setBusy(false)
        }
      }
      if ('requestIdleCallback' in window) window.requestIdleCallback(run, { timeout: 1500 })
      else run()
    }, 700)
    return () => {
      live = false
      window.clearTimeout(timer)
    }
  }, [screen.id, built, override])

  return (
    <Section title={t('tokensUsed')}>
      {!built ? (
        <p className="gzs-insp__hint gz-t-caption">{t('noTokens')}</p>
      ) : busy ? (
        <p className="gzs-insp__hint gz-t-caption">{t('scanning')}</p>
      ) : !scan ? (
        <p className="gzs-insp__hint gz-t-caption">{t('noTokens')}</p>
      ) : (
        <div className="gzs-scan">
          <ul className="gzs-swatches" role="list">
            {scan.colours.slice(0, 18).map(c => (
              <li key={c.token} className="gzs-swatch gz-t-caption" title={`${c.hex} x ${c.count}`}>
                <span className="gzs-swatch__chip" style={{ background: c.hex }} />
                <Id className="gz-t-fig-caption">{c.token}</Id>
              </li>
            ))}
          </ul>
          {scan.offColours.length > 0 ? (
            <p className="gzs-scan__off gz-t-caption">
              {t('offToken')}: {scan.offColours.map(o => o.rgb).join(', ')}
            </p>
          ) : null}
          <p className="gzs-scan__row gz-t-caption">
            <span className="gz-t-label">{t('typeLabel')}</span>
            {scan.fontSizes.slice(0, 8).map(s => (
              <Id key={s.px} className="gzs-scan__pill gz-t-fig-caption" >{s.px}{s.token ? ` ${s.token}` : ' off-scale'}</Id>
            ))}
          </p>
          <p className="gzs-scan__row gz-t-caption">
            <span className="gz-t-label">{t('radiusLabel')}</span>
            {scan.radii.map(s => (
              <Id key={s.px} className="gzs-scan__pill gz-t-fig-caption">{s.px === 9999 ? 'full' : s.px}{s.token ? ` ${s.token}` : ' off-scale'}</Id>
            ))}
          </p>
          <p className="gzs-scan__row gz-t-caption">
            <span className="gz-t-label">{t('faceLabel')}</span>
            {scan.families.slice(0, 4).map(f => (
              <Id key={f.name} className="gzs-scan__pill gz-t-fig-caption">{f.name}</Id>
            ))}
          </p>
        </div>
      )}
    </Section>
  )
}
