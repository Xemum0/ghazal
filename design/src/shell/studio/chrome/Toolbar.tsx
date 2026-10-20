// The Studio toolbar. Start: sidebar toggle, wordmark, where you are. Middle (canvas): zoom. End: language, frame width, overlays,
// view options, copy link, inspector, and the one primary action, Present (gold, 44 high: gold is a verb).
import { useEffect, useRef, useState } from 'react'
import { Button, Icon, Switch, Wordmark } from '../../../system'
import { SegmentedControl } from '../../../system/inputs'
import { go, setParam } from '../../router'
import { useLang, type Lang } from '../../lang'
import { Id } from '../bits'
import { useBoardInfo } from '../canvas/useBoard'
import { pickLoc, useCopy } from '../copy'
import { FLOWS, entryScreenOf, getScreen } from '../data/inventory'
import { currentUrl, playHash } from '../links'
import { DEVICE_WIDTHS, useStudioRoute } from '../route'
import { useStudio, type ConnectorMode, type WheelMode } from '../store'
import { Glyph } from './Glyph'
import { Popover } from './Popover'
import { ToolButton } from './ToolButton'

const LANGS: { value: Lang; label: string }[] = [
  { value: 'en', label: 'EN' },
  { value: 'ar', label: 'عربي' },
]

export function Toolbar() {
  const { lang, setLang } = useLang()
  const t = useCopy()
  const r = useStudioRoute()
  const prefs = useStudio()
  const selected = useStudio(s => s.selected)
  const info = useBoardInfo()
  const [copied, setCopied] = useState(false)
  const timer = useRef(0)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const onCanvas = r.view === 'canvas'
  const onPlay = r.view === 'play'
  const focus = selected
  const screen = getScreen(focus)

  const setWidth = (w: string) => setParam('w', w)
  const present = () => {
    const id = onPlay ? null : (screen?.id ?? entryScreenOf(r.app))
    go(playHash(screen?.app ?? r.app, id, { lang, w: r.w }))
  }
  const copy = async () => {
    const url = currentUrl()
    try {
      await navigator.clipboard.writeText(url)
    } catch {
      const ta = document.createElement('textarea')
      ta.value = url
      document.body.append(ta)
      ta.select()
      try {
        document.execCommand('copy')
      } catch {
        /* nothing more to try */
      }
      ta.remove()
    }
    setCopied(true)
    window.clearTimeout(timer.current)
    timer.current = window.setTimeout(() => setCopied(false), 2000)
  }

  return (
    <header className="gzs-toolbar" data-gz="Toolbar" role="toolbar" aria-label={t('studioFull')}>
      <div className="gzs-toolbar__start">
        <ToolButton label={prefs.sidebarOpen ? t('collapse') : t('expand')} pressed={prefs.sidebarOpen} onClick={() => prefs.toggle('sidebarOpen')}>
          <Glyph name="sidebar" />
        </ToolButton>
        <a className="gzs-toolbar__brand" href={`#/canvas/${r.app}?lang=${lang}`} aria-label={t('studioFull')}>
          <Wordmark size="md" />
        </a>
        <nav className="gzs-crumbs gz-t-body-s" aria-label={t('currentScreen')}>
          {screen ? (
            <>
              <span className="gzs-crumbs__flow">{pickLoc(FLOWS[screen.app].find(f => f.id === screen.flowId)?.title ?? { en: '', ar: '' }, lang)}</span>
              <Icon name="chevron-right" size="xs" />
              <span className="gzs-crumbs__screen">{pickLoc(screen.title, lang)}</span>
              <Id className="gzs-crumbs__id">{screen.id}</Id>
            </>
          ) : onCanvas && info.frames > 0 ? (
            <span className="gzs-crumbs__count">
              {r.app === 'client' ? t('clientLong') : t('hotelLong')} · <span className="gz-num">{info.flows}</span> {t('flowCount')} · <span className="gz-num">{info.frames}</span> {info.frames === 1 ? t('frame1') : t('frames')}
            </span>
          ) : null}
        </nav>
      </div>

      <div className="gzs-toolbar__end">
        <SegmentedControl<Lang> label={t('language')} value={lang} options={LANGS} onChange={setLang} className="gzs-toolbar__seg" />
        {/* Pixel widths read in ascending order in both languages. */}
        <div dir="ltr" className="gzs-toolbar__ltr gzs-opt-w">
          <SegmentedControl<string>
            label={t('deviceWidth')}
            value={String(r.w)}
            options={DEVICE_WIDTHS.map(w => ({ value: String(w), label: <span className="gz-num">{w}</span> }))}
            onChange={setWidth}
            className="gzs-toolbar__seg gzs-toolbar__seg--width"
          />
        </div>
        <span className="gzs-toolbar__rule gzs-opt" aria-hidden="true" />
        <ToolButton className="gzs-opt" label={t('grid')} pressed={prefs.grid} onClick={() => prefs.toggle('grid')} disabled={!onCanvas}>
          <Glyph name="grid" />
        </ToolButton>
        <ToolButton className="gzs-opt" label={t('redlines')} pressed={prefs.redlines} onClick={() => prefs.toggle('redlines')} disabled={!onCanvas}>
          <Glyph name="boxes" />
        </ToolButton>
        <ToolButton className="gzs-opt" label={t('reducedMotion')} pressed={prefs.reducedMotion} onClick={() => prefs.toggle('reducedMotion')}>
          <Glyph name="motion" />
        </ToolButton>
        <ViewMenu onCanvas={onCanvas} width={r.w} onWidth={setWidth} onCopy={copy} />
        <span className="gzs-toolbar__rule gzs-opt" aria-hidden="true" />
        <span className="gzs-toolbar__copy gzs-opt">
          <ToolButton label={t('copyLink')} onClick={copy}>
            <Icon name="link" size="sm" />
          </ToolButton>
          <span className="gzs-toolbar__toast gz-t-caption" role="status" data-show={copied || undefined}>
            {copied ? t('copied') : ''}
          </span>
        </span>
        <ToolButton label={prefs.inspectorOpen ? t('hideInspector') : t('showInspector')} pressed={prefs.inspectorOpen} onClick={() => prefs.toggle('inspectorOpen')} disabled={onPlay}>
          <Glyph name="panel" />
        </ToolButton>
        {onPlay ? (
          <Button size="sm" variant="secondary" iconStart="back" className="gzs-toolbar__present" onClick={() => go(`#/canvas/${r.app}?lang=${lang}&w=${r.w}${screen ? `&focus=${screen.id}` : ''}`)}>
            {t('backToCanvas')}
          </Button>
        ) : (
          <Button size="sm" variant="primary" iconStart="play" onClick={present} className="gzs-toolbar__present">
            {t('present')}
          </Button>
        )}
      </div>
    </header>
  )
}

// ---------------------------------------------------------------- view options

function ViewMenu({ onCanvas, width, onWidth, onCopy }: { onCanvas: boolean; width: number; onWidth: (w: string) => void; onCopy: () => void }) {
  const t = useCopy()
  const prefs = useStudio()
  const { isRtl } = useLang()
  const connectors: { value: ConnectorMode; label: string }[] = [
    { value: 'flow', label: t('connectorsFlow') },
    { value: 'all', label: t('connectorsAll') },
    { value: 'off', label: t('connectorsOff') },
  ]
  const wheel: { value: WheelMode; label: string }[] = [
    { value: 'zoom', label: t('wheelZoom') },
    { value: 'pan', label: t('wheelPan') },
  ]
  const keys: [string, string][] = [
    ['0', t('kFit')],
    ['1', t('k100')],
    ['+ −', t('kZoom')],
    ['F', t('kFocus')],
    ['Space', t('kPan')],
    ['P', t('kPlay')],
    ['Esc', t('kEsc')],
  ]
  return (
    <Popover
      label={t('viewOptions')}
      trigger={({ toggle, open, id, ref }) => (
        <ToolButton label={t('viewOptions')} pressed={open} ref={ref} aria-haspopup="dialog" aria-expanded={open} aria-controls={open ? id : undefined} onClick={toggle}>
          <Icon name="sliders" size="sm" />
        </ToolButton>
      )}
    >
      {() => (
        <div className="gzs-viewmenu">
          <section className="gzs-viewmenu__sec gzs-viewmenu__narrow">
            <h3 className="gz-t-label gzs-viewmenu__h">{t('deviceWidth')}</h3>
            <div dir="ltr">
              <SegmentedControl<string> label={t('deviceWidth')} value={String(width)} options={DEVICE_WIDTHS.map(w => ({ value: String(w), label: <span className="gz-num">{w}</span> }))} onChange={onWidth} />
            </div>
          </section>
          <section className="gzs-viewmenu__sec">
            <h3 className="gz-t-label gzs-viewmenu__h">{t('connectors')}</h3>
            <SegmentedControl<ConnectorMode> label={t('connectors')} value={prefs.connectors} options={connectors} onChange={v => prefs.set({ connectors: v })} />
          </section>
          <section className="gzs-viewmenu__sec">
            <h3 className="gz-t-label gzs-viewmenu__h">{t('wheel')}</h3>
            <SegmentedControl<WheelMode> label={t('wheel')} value={prefs.wheel} options={wheel} onChange={v => prefs.set({ wheel: v })} />
          </section>
          <section className="gzs-viewmenu__sec gzs-viewmenu__rows">
            <label className="gzs-viewmenu__row gzs-viewmenu__narrow gz-t-body-s" data-off={!onCanvas || undefined}>
              <span>{t('grid')}</span>
              <Switch label={t('grid')} checked={prefs.grid} disabled={!onCanvas} onChange={() => prefs.toggle('grid')} />
            </label>
            <label className="gzs-viewmenu__row gzs-viewmenu__narrow gz-t-body-s" data-off={!onCanvas || undefined}>
              <span>{t('redlines')}</span>
              <Switch label={t('redlines')} checked={prefs.redlines} disabled={!onCanvas} onChange={() => prefs.toggle('redlines')} />
            </label>
            <label className="gzs-viewmenu__row gzs-viewmenu__narrow gz-t-body-s">
              <span>{t('reducedMotion')}</span>
              <Switch label={t('reducedMotion')} checked={prefs.reducedMotion} onChange={() => prefs.toggle('reducedMotion')} />
            </label>
            <label className="gzs-viewmenu__row gz-t-body-s">
              <span>{t('stateVariants')}</span>
              <Switch label={t('stateVariants')} checked={prefs.variants} onChange={() => prefs.toggle('variants')} />
            </label>
            <label className="gzs-viewmenu__row gz-t-body-s" data-off={!isRtl || undefined}>
              <span>{t('mirrorFlow')}</span>
              <Switch label={t('mirrorFlow')} checked={prefs.mirrorFlow} onChange={() => prefs.toggle('mirrorFlow')} />
            </label>
          </section>
          <section className="gzs-viewmenu__sec gzs-viewmenu__narrow">
            <button type="button" className="gz-reset gz-press gzs-viewmenu__link gz-t-body-s" onClick={onCopy}>
              <Icon name="link" size="sm" />
              {t('copyLink')}
            </button>
          </section>
          <section className="gzs-viewmenu__sec">
            <h3 className="gz-t-label gzs-viewmenu__h">{t('shortcuts')}</h3>
            <dl className="gzs-keys">
              {keys.map(([k, what]) => (
                <div key={k} className="gzs-keys__row gz-t-caption">
                  <dt><kbd className="gzs-kbd gz-t-fig-caption">{k}</kbd></dt>
                  <dd>{what}</dd>
                </div>
              ))}
            </dl>
          </section>
        </div>
      )}
    </Popover>
  )
}
