// The prototype player (#/play/<app>/<screenId>?lang=&w=&story=): one live Device with a thin bezel on a calm backdrop, the real
// Navigator and store behind it, and a side panel that says what you are looking at. Language switches live (the store follows
// the URL), Esc goes back, hotspot hints outline what is tappable, and a dead tap flashes them, as in a Figma prototype.
import { useCallback, useEffect, useLayoutEffect, useRef, useState, type CSSProperties } from 'react'
import { Button, Chip, Icon } from '../../../system'
import { SegmentedControl } from '../../../system/inputs'
import { PrototypePlayer, type Story } from '../../device'
import { useLang } from '../../lang'
import { go, parseHash } from '../../router'
import { usePrototype } from '../../state'
import { isBuilt } from '../../registry'
import { BuiltMark, Id, Khayt, stateLabel } from '../bits'
import { Glyph } from '../chrome/Glyph'
import { ToolButton } from '../chrome/ToolButton'
import { pickLoc, useCopy } from '../copy'
import { FLOWS, SCREEN_BY_ID, entryScreenOf, getScreen, type ScreenDef } from '../data/inventory'
import { useRequirements } from '../data/requirements'
import { playHash } from '../links'
import { isClientFirstRun, parseStudioRoute, useStudioRoute } from '../route'
import { lastHash, useStudio } from '../store'
import { backButton, hasDialog, openSheetClose, readCurrentScreen, useTrackedScreens } from './track'
import './player.css'

const DEVICE_H = 844
const BEZEL = 8
const STAGE_PAD = 20
/** Control pill (52) plus the gap under it (16), snapped up to the 4-pt grid. */
const CONTROLS_H = 72
const INTERACTIVE = 'button, a, input, select, textarea, [role="button"], [role="tab"], [role="switch"], [role="radio"], [role="checkbox"], [data-gz-id]'

const storyOf = (app: 'client' | 'hotel', signedIn: boolean): Story => (signedIn ? app : 'start')

export function PlayerPage() {
  const r = useStudioRoute()
  const { lang } = useLang()
  const t = useCopy()
  const select = useStudio(s => s.select)
  const hotspots = useStudio(s => s.hotspots)
  const toggle = useStudio(s => s.toggle)
  const reducedMotion = useStudio(s => s.reducedMotion)
  const app = r.app
  const signedIn = r.story === 'signed-in'
  const tracked = useTrackedScreens()

  const [start, setStart] = useState(() => r.screen ?? entryScreenOf(app))
  const [epoch, setEpoch] = useState(0)
  const [current, setCurrent] = useState<string>(start)
  const currentRef = useRef(current)
  currentRef.current = current
  const stage = useRef<HTMLDivElement>(null)
  const deviceBox = useRef<HTMLDivElement>(null)
  const [scale, setScale] = useState(1)
  const [flash, setFlash] = useState(false)
  const flashTimer = useRef(0)

  // ---- a link to another screen (sidebar, deep link, "jump to") restarts the prototype there. The player also writes the current
  // screen into the URL as it goes (replaceState, no history entry); `written` tells those writes from someone else's.
  const written = useRef('')
  const lastApp = useRef(app)
  useEffect(() => {
    const hash = window.location.hash
    if (lastApp.current !== app) {
      lastApp.current = app
      const s = parseStudioRoute(parseHash(hash)).screen ?? entryScreenOf(app)
      setStart(s)
      setCurrent(s)
      setEpoch(e => e + 1)
      return
    }
    if (hash === written.current) return
    const target = parseStudioRoute(parseHash(hash)).screen
    if (target && target !== currentRef.current) {
      setStart(target)
      setCurrent(target)
      setEpoch(e => e + 1)
    }
  }, [r.route.raw, app])

  // ---- follow the navigator: current screen -> selection, URL, panel
  useEffect(() => {
    const el = deviceBox.current
    if (!el) return
    let raf = 0
    const read = () => {
      raf = 0
      const id = readCurrentScreen(el)
      if (id && id !== currentRef.current) {
        setCurrent(id)
      }
    }
    const mo = new MutationObserver(() => {
      if (!raf) raf = requestAnimationFrame(read)
    })
    mo.observe(el, { subtree: true, childList: true, attributes: true, attributeFilter: ['data-hidden', 'data-state', 'data-phase', 'class'] })
    return () => {
      mo.disconnect()
      cancelAnimationFrame(raf)
    }
  }, [epoch])

  useEffect(() => {
    select(current)
    // Signing in inside the player turns the session into the signed-in one in the link, so a reload does not drop back to the first run.
    const story = app === 'client' && usePrototype.getState().auth === 'signedIn' && !isClientFirstRun(current) ? 'signed-in' : r.story
    const hash = playHash(app, current, { lang, w: r.w }, { story })
    window.history.replaceState(null, '', hash)
    written.current = window.location.hash
    lastHash.set(hash)
  }, [current, app, lang, r.w, r.story, select])

  // ---- fit the device in the stage
  useLayoutEffect(() => {
    const el = stage.current
    if (!el) return
    const measure = () => {
      const h = el.clientHeight - STAGE_PAD * 2 - CONTROLS_H
      setScale(Math.max(0.5, Math.min(1, h / (DEVICE_H + BEZEL * 2))))
    }
    measure()
    const ro = new ResizeObserver(measure)
    ro.observe(el)
    return () => ro.disconnect()
  }, [])

  // ---- Esc: close the sheet, else go back
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape' || e.defaultPrevented) return
      const t = e.target as HTMLElement | null
      if (t && (t.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(t.tagName))) return
      const root = deviceBox.current
      if (!root || hasDialog(root)) return
      const target = openSheetClose(root) ?? backButton(root)
      if (target) {
        e.preventDefault()
        target.click()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  const restart = useCallback(() => {
    setStart(entryScreenOf(app))
    setCurrent(entryScreenOf(app))
    setEpoch(e => e + 1)
  }, [app])
  const jump = useCallback((id: string) => {
    setStart(id)
    setCurrent(id)
    setEpoch(e => e + 1)
  }, [])
  const resetData = () => usePrototype.getState().resetToStoryStart()
  const setSession = (v: 'signed-out' | 'signed-in') => {
    // A signed-out client has only the first-run screens (ADR 0038): restart from the entry screen instead of a screen behind the sign-in.
    const at = v === 'signed-out' && app === 'client' && !isClientFirstRun(current) ? entryScreenOf(app) : current
    go(playHash(app, at, { lang, w: r.w }, { story: v }))
    setStart(at)
    setCurrent(at)
    setEpoch(e => e + 1)
  }

  const onPointerDown = (e: React.PointerEvent) => {
    if ((e.target as Element).closest(INTERACTIVE)) return
    setFlash(true)
    window.clearTimeout(flashTimer.current)
    flashTimer.current = window.setTimeout(() => setFlash(false), 700)
  }
  useEffect(() => () => window.clearTimeout(flashTimer.current), [])

  const screen = getScreen(current)
  const boxW = (r.w + BEZEL * 2) * scale
  const boxH = (DEVICE_H + BEZEL * 2) * scale
  const scalerStyle = { transform: `scale(${scale})` } as CSSProperties

  return (
    <div className="gzs-play" data-gz-route="play" data-gz-app={app} data-hotspots={hotspots || undefined} data-flash={flash || undefined} data-reduced={reducedMotion || undefined}>
      <div className="gzs-play__stage" ref={stage}>
        <div className="gzs-play__controls" role="toolbar" aria-label={t('yourPrototype')}>
          <ToolButton label={t('restart')} onClick={restart}>
            <Glyph name="restart" />
          </ToolButton>
          <ToolButton label={t('resetData')} onClick={resetData}>
            <Glyph name="database" />
          </ToolButton>
          <ToolButton label={t('hotspots')} pressed={hotspots} onClick={() => toggle('hotspots')}>
            <Glyph name="tap" />
          </ToolButton>
          <span className="gzs-play__rule" aria-hidden="true" />
          <SegmentedControl<'signed-out' | 'signed-in'>
            label={t('story')}
            value={signedIn ? 'signed-in' : 'signed-out'}
            onChange={setSession}
            options={[
              { value: 'signed-out', label: t('signedOut') },
              { value: 'signed-in', label: t('signedIn') },
            ]}
          />
        </div>
        <div className="gzs-play__box" style={{ inlineSize: boxW, blockSize: boxH }}>
          <div className="gzs-play__scaler" style={scalerStyle} onPointerDownCapture={onPointerDown}>
            <div ref={deviceBox} className="gzs-play__device">
              <PrototypePlayer key={`${app}:${epoch}:${signedIn}`} app={app} initial={start} story={storyOf(app, signedIn)} width={r.w} screens={tracked} />
            </div>
          </div>
        </div>
      </div>
      <Panel screen={screen} onJump={jump} />
    </div>
  )
}

// ---------------------------------------------------------------- side panel

function Panel({ screen, onJump }: { screen: ScreenDef | undefined; onJump: (id: string) => void }) {
  const t = useCopy()
  const { lang } = useLang()
  const reqs = useRequirements()
  const [all, setAll] = useState(false)
  useEffect(() => setAll(false), [screen?.id])
  if (!screen) {
    return (
      <aside className="gzs-playpanel" aria-label={t('currentScreen')}>
        <div className="gzs-playpanel__body gz-no-scrollbar" data-scroll>
          <p className="gz-t-body-s">{t('noSelection')}</p>
        </div>
      </aside>
    )
  }
  const flow = FLOWS[screen.app].find(f => f.id === screen.flowId)
  const shown = all ? screen.requirementIds : screen.requirementIds.slice(0, 4)
  return (
    <aside className="gzs-playpanel" aria-label={t('currentScreen')} data-gz="PlayerPanel">
      <div className="gzs-playpanel__body gz-no-scrollbar" data-scroll>
        <header className="gzs-insp__head">
          <span className="gz-t-label gzs-playpanel__eyebrow">{t('currentScreen')}</span>
          <Khayt />
          <h2 className="gzs-insp__title gz-t-d2" data-gz-id="play.title">{pickLoc(screen.title, lang)}</h2>
          <p className="gzs-insp__line gz-t-caption">
            <Id className="gz-t-fig-body-s" >{screen.id}</Id>
            {flow ? <span>{pickLoc(flow.title, lang)}</span> : null}
          </p>
          <div className="gzs-insp__tags">
            <BuiltMark built={isBuilt(screen.id)} label />
            {screen.states.length > 0 ? <span className="gzs-insp__tag gz-t-caption">{screen.states.length} {screen.states.length === 1 ? t('state1') : t('states')}</span> : null}
          </div>
        </header>

        <section className="gzs-insp__sec">
          <h3 className="gzs-insp__h gz-t-label">{t('requirements')}<span className="gzs-insp__n gz-num">{screen.requirementIds.length}</span></h3>
          <ul className="gzs-reqs" role="list">
            {shown.map(id => (
              <li key={id} className="gzs-reqs__item">
                <Id className="gzs-reqs__id gz-t-fig-caption">{id}</Id>
                <span className="gzs-reqs__text gz-t-body-s" dir="auto">{reqs?.get(id)?.text ?? ''}</span>
              </li>
            ))}
          </ul>
          {screen.requirementIds.length > 4 ? (
            <Button variant="tertiary" size="sm" onClick={() => setAll(a => !a)}>
              {all ? t('less') : `${t('more')} (${screen.requirementIds.length - 4})`}
            </Button>
          ) : null}
        </section>

        <section className="gzs-insp__sec">
          <h3 className="gzs-insp__h gz-t-label">{t('interactions')}<span className="gzs-insp__n gz-num">{screen.interactions.length}</span></h3>
          <ol className="gzs-insp__list gz-t-body-s">
            {screen.interactions.map((x, i) => (
              <li key={i} dir="auto">{x}</li>
            ))}
          </ol>
        </section>

        {screen.navigatesTo.length > 0 ? (
          <section className="gzs-insp__sec">
            <h3 className="gzs-insp__h gz-t-label">{t('jumpTo')}</h3>
            <ul className="gzs-links" role="list">
              {screen.navigatesTo.map(id => {
                const s = SCREEN_BY_ID.get(id)
                return (
                  <li key={id}>
                    <button type="button" className="gz-reset gz-press gzs-links__row" onClick={() => onJump(id)}>
                      <Id className="gz-t-fig-caption gzs-links__id">{id}</Id>
                      <span className="gz-t-body-s gzs-links__name">{s ? pickLoc(s.title, lang) : ''}</span>
                      <Icon name="chevron-right" size="xs" />
                    </button>
                  </li>
                )
              })}
            </ul>
          </section>
        ) : null}

        {screen.states.length > 0 ? (
          <section className="gzs-insp__sec">
            <h3 className="gzs-insp__h gz-t-label">{t('states')}</h3>
            <div className="gzs-insp__chips">
              {screen.states.slice(0, 12).map(s => (
                <Chip key={s}>{stateLabel(s)}</Chip>
              ))}
            </div>
          </section>
        ) : null}
        <p className="gzs-play__hint gz-t-caption">
          <kbd className="gzs-kbd gz-t-fig-caption">Esc</kbd> {t('backHint')}
        </p>
      </div>
    </aside>
  )
}
