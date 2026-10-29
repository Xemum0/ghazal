// ThemeProvider: the colour theme of the prototype (docs/design/01-direction.md "Rose theme"). Gold is the design and the default;
// rose is an owner comparison experiment (OQ-R2-12), a token overlay emitted by packages/design-tokens as [data-theme='rose'].
// Same pattern as the language: the theme lives in the URL hash (?theme=gold|rose), so a screenshot URL is the full state;
// setTheme rewrites it. The choice is also remembered in localStorage as a convenience only (every read and write is guarded), so
// it survives the places that rebuild a hash without it. The hash always wins over the remembered value.
import { createContext, useCallback, useContext, useLayoutEffect, useMemo, type ReactNode } from 'react'
import { defaultTheme, themeNames, type ThemeName } from '@gz/tokens'
import { setParam, useRoute } from './router'

export type { ThemeName }
export { defaultTheme, themeNames }

const STORAGE_KEY = 'gz-theme'

export type ThemeState = {
  theme: ThemeName
  setTheme: (theme: ThemeName) => void
}

const ThemeContext = createContext<ThemeState | null>(null)

export const parseTheme = (v: string | null | undefined): ThemeName | null => (themeNames as readonly string[]).includes(v ?? '') ? (v as ThemeName) : null

const readStored = (): ThemeName | null => {
  try {
    return parseTheme(window.localStorage.getItem(STORAGE_KEY))
  } catch {
    return null
  }
}
const writeStored = (theme: ThemeName) => {
  try {
    window.localStorage.setItem(STORAGE_KEY, theme)
  } catch {
    /* private window or blocked storage: the hash still carries the choice */
  }
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const route = useRoute()
  const fromHash = parseTheme(route.params.get('theme'))
  const theme = fromHash ?? readStored() ?? defaultTheme

  // Layout effect: set before paint so there is no frame in the wrong theme. [data-theme] sits on <html>, the same element as :root.
  useLayoutEffect(() => {
    document.documentElement.dataset.theme = theme
    writeStored(theme)
  }, [theme])

  // Keep the URL a complete state: a hash rebuilt without ?theme= (a link, a studio route) gets it back when the theme is not the default.
  useLayoutEffect(() => {
    if (!fromHash && theme !== defaultTheme) setParam('theme', theme)
  }, [fromHash, theme, route.raw])

  const setTheme = useCallback((next: ThemeName) => setParam('theme', next), [])
  const value = useMemo<ThemeState>(() => ({ theme, setTheme }), [theme, setTheme])
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}

export function useTheme(): ThemeState {
  const ctx = useContext(ThemeContext)
  if (!ctx) throw new Error('useTheme() needs <ThemeProvider> above it')
  return ctx
}
