// Theme switch for the studio chrome: Gold | Rose. Chrome around the prototype, not product UI (OQ-R2-12): plain labels.
// `compact` is a single button (the Launcher on a handheld, where the bar has no room for a second segmented control).
import { SegmentedControl } from '../system/inputs'
import { useLang, type Lang } from './lang'
import { themeNames, useTheme, type ThemeName } from './theme'

const COPY: Record<Lang, { group: string } & Record<ThemeName, string>> = {
  en: { group: 'Theme', gold: 'Gold', rose: 'Rose' },
  ar: { group: 'السمة', gold: 'ذهبي', rose: 'وردي' },
}

export function ThemeToggle({ compact = false, className }: { compact?: boolean; className?: string }) {
  const { lang } = useLang()
  const { theme, setTheme } = useTheme()
  const t = COPY[lang]
  if (compact) {
    const next = themeNames[(themeNames.indexOf(theme) + 1) % themeNames.length] ?? theme
    return (
      <button type="button" className={className} data-gz="ThemeToggle" aria-label={`${t.group}: ${t[theme]}`} onClick={() => setTheme(next)}>
        {t[next]}
      </button>
    )
  }
  return (
    <SegmentedControl<ThemeName>
      label={t.group}
      value={theme}
      onChange={setTheme}
      className={className}
      options={themeNames.map(value => ({ value, label: t[value] }))}
    />
  )
}
