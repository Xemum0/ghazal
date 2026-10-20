// Launcher: the product's front door. Open it, see a phone, pick Client or Partner (the app id stays `hotel`), start surfing the prototype.
// No canvas, no sidebar, no inspector (those stay available for design work under #/canvas, #/system, #/docs).
// Desktop: one phone, scaled to fit the window. A real phone (narrow viewport): the prototype fills the screen.
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { SegmentedControl } from '../system/inputs'
import { PrototypePlayer } from './device/PrototypePlayer'
import type { AppKind } from './device/context'
import { useLang, type Lang } from './lang'
import { setParam, useRoute } from './router'
import './launcher.css'

const FALLBACK = { w: 414, h: 868 } // natural size of the live Device with its thin bezel, used until it is measured

const COPY: Record<Lang, { client: string; hotel: string; group: string; langGroup: string; restart: string }> = {
  en: { client: 'Client', hotel: 'Partner', group: 'Prototype', langGroup: 'Language', restart: 'Restart' },
  ar: { client: 'العميل', hotel: 'الشريك', group: 'النموذج', langGroup: 'اللغة', restart: 'إعادة' },
}

const parseApp = (v: string | null): AppKind => (v === 'hotel' ? 'hotel' : 'client')

function useViewport() {
  // visualViewport follows the mobile browser's collapsing address bar; innerHeight does not.
  const read = () => ({ w: window.innerWidth, h: Math.round(window.visualViewport?.height ?? window.innerHeight) })
  const [vp, setVp] = useState(read)
  useEffect(() => {
    const on = () => setVp(read())
    window.addEventListener('resize', on)
    window.visualViewport?.addEventListener('resize', on)
    return () => {
      window.removeEventListener('resize', on)
      window.visualViewport?.removeEventListener('resize', on)
    }
  }, [])
  return vp
}

export function Launcher() {
  const route = useRoute()
  const { lang, setLang } = useLang()
  const app = parseApp(route.params.get('app'))
  const [run, setRun] = useState(0)
  // Switching apps keeps the prototype store (a request sent as the client is still there as the partner); Restart reseeds it.
  const [seed, setSeed] = useState(true)
  const vp = useViewport()
  const t = COPY[lang]

  const setApp = useCallback((next: AppKind) => {
    setParam('app', next)
    setSeed(false)
    setRun(n => n + 1)
  }, [])

  const handheld = vp.w <= 520
  // Measure the phone's natural size (before scaling) so the scale fits the window exactly, whatever the bezel draws.
  const phoneRef = useRef<HTMLDivElement>(null)
  const barRef = useRef<HTMLElement>(null)
  const [nat, setNat] = useState(FALLBACK)
  const [barH, setBarH] = useState(64)
  useLayoutEffect(() => {
    const el = phoneRef.current
    if (el && el.offsetWidth > 0 && el.offsetHeight > 0 && (el.offsetWidth !== nat.w || el.offsetHeight !== nat.h)) {
      setNat({ w: el.offsetWidth, h: el.offsetHeight })
    }
    if (barRef.current && barRef.current.offsetHeight !== barH) setBarH(barRef.current.offsetHeight)
  })
  const scale = handheld ? 1 : Math.min(1, (vp.h - barH - 40) / nat.h, (vp.w - 32) / nat.w)

  return (
    <main className="gz-launch" data-gz-route="launcher" data-app={app} style={{ blockSize: vp.h }}>
      <header ref={barRef} className="gz-launch__bar">
        <SegmentedControl<AppKind>
          label={t.group}
          value={app}
          onChange={setApp}
          options={[
            { value: 'client', label: t.client },
            { value: 'hotel', label: t.hotel },
          ]}
        />
        {handheld ? (
          <button type="button" className="gz-launch__lang" aria-label={t.langGroup} onClick={() => setLang(lang === 'en' ? 'ar' : 'en')}>
            {lang === 'en' ? 'عربي' : 'EN'}
          </button>
        ) : (
          <SegmentedControl<Lang>
            label={t.langGroup}
            value={lang}
            onChange={setLang}
            options={[
              { value: 'en', label: 'EN' },
              { value: 'ar', label: 'عربي' },
            ]}
          />
        )}
        <button type="button" className="gz-launch__restart" aria-label={t.restart} onClick={() => { setSeed(true); setRun(n => n + 1) }}>
          <svg aria-hidden="true" viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M4 12a8 8 0 1 0 2.6-5.9" />
            <path d="M4 4v4.5h4.5" />
          </svg>
          <span className="gz-launch__restart-label">{t.restart}</span>
        </button>
      </header>

      {handheld ? (
        <div className="gz-launch__full">
          <PrototypePlayer key={`${app}-${run}`} app={app} seed={seed} bezel="none" chrome="none" width={Math.min(430, Math.max(360, vp.w))} height={Math.max(480, vp.h - barH)} />
        </div>
      ) : (
        <div className="gz-launch__stage" style={{ inlineSize: nat.w * scale, blockSize: nat.h * scale }}>
          <div ref={phoneRef} className="gz-launch__phone" style={{ transform: `translateX(-50%) scale(${scale})` }}>
            <PrototypePlayer key={`${app}-${run}`} app={app} seed={seed} />
          </div>
        </div>
      )}
    </main>
  )
}
