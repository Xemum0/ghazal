// Route components for the Device framework. The integrator wires them in shell/App.tsx (see docs/engineering/requests.md):
//   case 'frame': <StaticFrameRoute />   (replaces FrameRoute: same URL contract, now with real chrome)
//   case 'play':  <PlayerRoute />        (#/play?app=client|hotel&screen=<id>&story=start|client|hotel&lang=)
import { useMemo, useState } from 'react'
import { useRoute, setParam } from '../router'
import { useLang } from '../lang'
import { themeNames, useTheme } from '../theme'
import { FrameContext, type FrameState } from '../frame'
import { find, screenEntries } from '../registry'
import { usePrototype } from '../state'
import { StaticFrame } from './StaticFrame'
import { PrototypePlayer, STORY_START, type Story } from './PrototypePlayer'
import type { AppKind } from './context'
import './routes.css'

const toInt = (v: string | null, fallback: number) => {
  const n = Number(v)
  return Number.isFinite(n) && n >= 280 && n <= 1200 ? Math.round(n) : fallback
}

/**
 * #/frame/<screenId>?lang=&state=&w=&h=&story= : the screen in a Device (390 x 844, real chrome).
 * `story` seeds the prototype store before the first paint: `start` (guest, the story start), `client` (Reem, signed in) or `hotel`
 * (Hind, Aurelia). Without it the store keeps whatever it holds (a fresh load is the story start). The reference renders for the Flutter
 * parity loop pass the story by flow (tools/parity/ref-shots.mjs): signed in for every screen except onboarding, auth and hotel access.
 */
export function StaticFrameRoute() {
  const route = useRoute()
  const story = route.params.get('story')
  // Runs once, during the first render and therefore before any child reads the store.
  useState(() => {
    if (story === 'start') usePrototype.getState().resetToStoryStart()
    else if (story === 'client' || story === 'hotel') usePrototype.getState().loadStory(story)
  })
  const screenId = route.segments[1] ?? ''
  const width = toInt(route.params.get('w'), 390)
  const hParam = route.params.get('h')
  const height = hParam === 'auto' ? 'auto' : toInt(hParam, 844)
  const state = route.params.get('state') ?? undefined
  const bezel = route.params.get('bezel') === 'thin' ? 'thin' : 'none'
  const entry = find(screenEntries, screenId)
  const frame = useMemo<FrameState>(() => ({ screenId: entry?.id ?? screenId, state, width }), [entry, screenId, state, width])
  return (
    <div className="gz-frame-stage" data-gz-route="frame">
      <div data-gz-frame={entry?.id ?? screenId} data-gz-state={state}>
        <FrameContext.Provider value={frame}>
          <StaticFrame screenId={entry?.id ?? screenId} state={state} width={width} height={height} bezel={bezel} />
        </FrameContext.Provider>
      </div>
    </div>
  )
}

const STORIES: { id: Story; en: string; ar: string }[] = [
  { id: 'start', en: 'Story start', ar: 'بداية القصة' },
  { id: 'client', en: 'Reem, signed in', ar: 'ريم، مسجلة الدخول' },
  { id: 'hotel', en: 'Hind, Aurelia', ar: 'هند، أوريليا' },
]

/** #/play?app=&screen=&story= : the live prototype with its controls. */
export function PlayerRoute() {
  const route = useRoute()
  const { lang, setLang } = useLang()
  const { theme, setTheme } = useTheme()
  const app: AppKind = route.params.get('app') === 'hotel' ? 'hotel' : 'client'
  const story = (route.params.get('story') as Story | null) ?? 'start'
  const screen = route.params.get('screen') ?? STORY_START[app]
  const [epoch, setEpoch] = useState(0)
  const resetStore = usePrototype(s => s.resetToStoryStart)
  const restart = () => {
    resetStore()
    setEpoch(e => e + 1)
  }
  return (
    <div className="gz-player" data-gz-route="play">
      <div className="gz-player__bar" role="toolbar" aria-label="Player">
        <div className="gz-player__group" role="group" aria-label="App">
          {(['client', 'hotel'] as const).map(a => (
            <button key={a} type="button" className="gz-player__chip" aria-pressed={app === a} onClick={() => { setParam('app', a); setParam('screen', null); setEpoch(e => e + 1) }}>
              {a}
            </button>
          ))}
        </div>
        <div className="gz-player__group" role="group" aria-label="Language">
          {(['en', 'ar'] as const).map(l => (
            <button key={l} type="button" className="gz-player__chip" aria-pressed={lang === l} onClick={() => setLang(l)}>
              {l.toUpperCase()}
            </button>
          ))}
        </div>
        <div className="gz-player__group" role="group" aria-label="Theme">
          {themeNames.map(n => (
            <button key={n} type="button" className="gz-player__chip" aria-pressed={theme === n} onClick={() => setTheme(n)}>
              {n}
            </button>
          ))}
        </div>
        <div className="gz-player__group" role="group" aria-label="Story">
          {STORIES.map(s => (
            <button key={s.id} type="button" className="gz-player__chip" aria-pressed={story === s.id} onClick={() => { setParam('story', s.id); setEpoch(e => e + 1) }}>
              {lang === 'ar' ? s.ar : s.en}
            </button>
          ))}
        </div>
        <button type="button" className="gz-player__chip" onClick={restart}>
          {lang === 'ar' ? 'إعادة' : 'Restart'}
        </button>
      </div>
      <PrototypePlayer key={`${app}:${story}:${screen}:${epoch}`} app={app} initial={screen} story={story} />
    </div>
  )
}
