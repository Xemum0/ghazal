// The design documents the Studio can show: docs/design/*.md, loaded as raw text on demand (one dynamic import each).
// Titles are authored here in both languages (design-tool text); the document bodies are the repo's markdown, read-only.
import type { Loc } from '../data/inventory'

const files = import.meta.glob('@docs/design/*.md', { query: '?raw', import: 'default' }) as Record<string, () => Promise<string>>

export type DocDef = { id: string; file: string; title: Loc; note: Loc }

const DEFS: DocDef[] = [
  { id: 'direction', file: '01-direction.md', title: { en: 'Visual direction', ar: 'الاتجاه البصري' }, note: { en: 'Binding: identity, tokens, components', ar: 'ملزم: الهوية والمتغيرات والمكوّنات' } },
  { id: 'brief', file: '00-brief.md', title: { en: 'Design brief', ar: 'وثيقة التصميم' }, note: { en: 'The mandate behind the direction', ar: 'التكليف الذي بُني عليه الاتجاه' } },
  { id: 'tokens', file: 'tokens.md', title: { en: 'Token map', ar: 'خريطة المتغيرات' }, note: { en: 'Names, roles and pipeline', ar: 'الأسماء والأدوار والمسار' } },
  { id: 'content', file: 'content-guidelines.md', title: { en: 'Content guidelines', ar: 'إرشادات المحتوى' }, note: { en: 'Voice, copy and terms', ar: 'النبرة والنصوص والمصطلحات' } },
  { id: 'seed', file: 'seed-rulebook.md', title: { en: 'Seed rulebook', ar: 'قواعد البيانات التجريبية' }, note: { en: 'How fixtures are written', ar: 'كيف تُكتب البيانات' } },
  { id: 'archive', file: 'exploration-archive.md', title: { en: 'Exploration archive', ar: 'أرشيف الاستكشافات' }, note: { en: 'Maison, Majlis, Thread', ar: 'ميزون ومجلس وخيط' } },
]

/** Only the documents that exist as files. */
export const DOCS: DocDef[] = DEFS.filter(d => Object.keys(files).some(p => p.endsWith(`/${d.file}`)))

export const docById = (id: string): DocDef | undefined => DOCS.find(d => d.id === id)

export function loadDoc(def: DocDef): Promise<string> {
  const key = Object.keys(files).find(p => p.endsWith(`/${def.file}`))
  return key ? files[key]!() : Promise.reject(new Error(`${def.file} not found`))
}

// ---------------------------------------------------------------- gallery pages

const GALLERY_TITLES: Record<string, { title: Loc; note: Loc }> = {
  tokens: { title: { en: 'Tokens', ar: 'المتغيرات' }, note: { en: 'Colour, type, space, motion', ar: 'اللون والخط والمسافة والحركة' } },
  core: { title: { en: 'Core components', ar: 'المكوّنات الأساسية' }, note: { en: 'Buttons, chips, pills, thread', ar: 'الأزرار والشارات والخيط' } },
  inputs: { title: { en: 'Inputs', ar: 'الحقول' }, note: { en: 'Fields, pickers, calendar', ar: 'الحقول والمنتقيات والتقويم' } },
  nav: { title: { en: 'Navigation and frames', ar: 'التنقل والإطارات' }, note: { en: 'Bars, sheets, the navigator', ar: 'الأشرطة والأوراق والمتنقل' } },
  i18n: { title: { en: 'Language and numerals', ar: 'اللغة والأرقام' }, note: { en: 'Formatter, bidi, dates', ar: 'المنسّق والاتجاه والتواريخ' } },
  overlays: { title: { en: 'Overlays', ar: 'الطبقات العلوية' }, note: { en: 'Sheets, dialogs, gallery', ar: 'الأوراق والحوارات والمعرض' } },
  charts: { title: { en: 'Charts', ar: 'المخططات' }, note: { en: 'Hotel analytics', ar: 'تحليلات الفندق' } },
}

const titleCase = (id: string) => id.replace(/[-_]+/g, ' ').replace(/^./, c => c.toUpperCase())

export function galleryTitle(id: string): { title: Loc; note: Loc | null } {
  const g = GALLERY_TITLES[id]
  if (g) return g
  const t = titleCase(id)
  return { title: { en: t, ar: t }, note: null }
}

/** Every gallery page is a system page (the harness placeholder was retired). */
export const isSystemPage = (_id: string) => true

const ORDER = ['tokens', 'core', 'inputs', 'nav', 'overlays', 'client', 'hotel', 'charts', 'i18n']
/** Foundations first, then components by layer, then the domain pages, then anything new alphabetically. */
export const galleryRank = (id: string): number => {
  const i = ORDER.indexOf(id)
  return i === -1 ? ORDER.length : i
}
