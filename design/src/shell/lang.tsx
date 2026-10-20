// GzProvider: language, direction and font stack for the whole document (ADR 0014, ADR 0016).
// The language lives in the URL hash (?lang=ar|en); setLang rewrites it, so a screenshot URL is the full state.
import { createContext, useCallback, useContext, useLayoutEffect, useMemo, type ReactNode } from 'react'
import { setParam, useRoute } from './router'

export type Lang = 'en' | 'ar'
export type Dir = 'ltr' | 'rtl'

export type LangState = {
  lang: Lang
  dir: Dir
  isRtl: boolean
  setLang: (lang: Lang) => void
}

const LangContext = createContext<LangState | null>(null)

export const parseLang = (v: string | null | undefined): Lang => (v === 'ar' ? 'ar' : 'en')
export const dirOf = (lang: Lang): Dir => (lang === 'ar' ? 'rtl' : 'ltr')

export function GzProvider({ children }: { children: ReactNode }) {
  const route = useRoute()
  const lang = parseLang(route.params.get('lang'))
  const dir = dirOf(lang)

  // Layout effect: set before paint so there is no frame in the wrong direction.
  useLayoutEffect(() => {
    const html = document.documentElement
    html.lang = lang
    html.dir = dir
    html.dataset.lang = lang
    html.classList.remove('gz-lang-en', 'gz-lang-ar')
    html.classList.add(`gz-lang-${lang}`)
  }, [lang, dir])

  const setLang = useCallback((next: Lang) => setParam('lang', next), [])
  const value = useMemo<LangState>(() => ({ lang, dir, isRtl: dir === 'rtl', setLang }), [lang, dir, setLang])
  return <LangContext.Provider value={value}>{children}</LangContext.Provider>
}

export function useLang(): LangState {
  const ctx = useContext(LangContext)
  if (!ctx) throw new Error('useLang() needs <GzProvider> above it')
  return ctx
}
