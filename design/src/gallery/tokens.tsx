// Tokens gallery: the single page that shows every token namespace live (colour with measured contrast, type in both scripts,
// figures and money, space, shape, elevation, motion, thread, icons). Owner: tokens-owner. Rendered at #/gallery/tokens?lang=en|ar.
// Everything here reads @gz/tokens (generated) and the product CSS; specimen strings are hand-written on purpose (token docs,
// not product screens: product copy and money strings come from @gz/i18n and the shared formatter, ADR 0010).
import { useMemo, useState, type ReactNode } from 'react'
import { brand, flat, iconGroups, icons, iconsLight, iconsRegular, iconNames, mirrorInRtl, type IconName, type TokenPath } from '@gz/tokens'
import flatJson from '@gz/tokens/dist/tokens.flat.json'
import pairsFile from '@gz/tokens/a11y-pairs.json'
import { useLang, type Lang } from '../shell/lang'
import '../styles/gallery-tokens.css'

// ---------------------------------------------------------------------------------------------------------------- helpers
type FlatEntry = { type: string; value: unknown; css: string; ref?: string }
const entries = flatJson.tokens as Record<string, FlatEntry>
const get = (path: string): FlatEntry => {
  const e = entries[path]
  if (!e) throw new Error(`token ${path} not found`)
  return e
}
const val = <T,>(path: TokenPath): T => flat[path] as unknown as T
const cssv = (path: string) => `var(${get(path).css})`

const rgbOf = (hex: string): [number, number, number] => {
  const n = parseInt(hex.slice(1, 7), 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}
const lin = (c: number) => ((c / 255) <= 0.03928 ? c / 255 / 12.92 : ((c / 255 + 0.055) / 1.055) ** 2.4)
const lum = (hex: string) => { const [r, g, b] = rgbOf(hex); return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
const ratio = (a: string, b: string) => { const [hi, lo] = [lum(a), lum(b)].sort((x, y) => y - x); return ((hi ?? 0) + 0.05) / ((lo ?? 0) + 0.05) }
const hexOf = (path: string) => String(get(path).value)

const L = <T,>(lang: Lang, en: T, ar: T): T => (lang === 'ar' ? ar : en)

function Num({ children }: { children: ReactNode }) {
  return <span className="gz-num">{children}</span>
}
const Isolate = ({ children }: { children: ReactNode }) => <bdi className="gz-ltr">{children}</bdi>

function Section({ title, note, children }: { title: string; note?: string; children: ReactNode }) {
  return (
    <section className="tk-sec">
      <header className="tk-sec__head">
        <span className="gz-khayt" aria-hidden="true" />
        <h2 className="gz-t-d2">{title}</h2>
        {note ? <p className="gz-t-body-s tk-note">{note}</p> : null}
      </header>
      {children}
    </section>
  )
}

function Glyph({ name, weight = 'default', mirror = false }: { name: IconName; weight?: 'light' | 'regular' | 'default'; mirror?: boolean }) {
  const set = weight === 'regular' ? iconsRegular : weight === 'light' ? iconsLight : icons
  const g = set[name]
  return (
    <svg viewBox={g.viewBox} fill="currentColor" aria-hidden="true" className={mirror ? 'gz-mirror' : undefined}>
      {g.paths.map((d, i) => <path key={i} d={d} />)}
    </svg>
  )
}

// ---------------------------------------------------------------------------------------------------------------- copy
const T = {
  en: {
    eyebrow: 'Design system',
    title: 'Tokens',
    lede: 'Every colour, space, radius, type size and motion value in the product. Components read them through var(--gz-...) and nothing else; the generator checks contrast, grids and Arabic parity on every build.',
    colour: 'Colour ramps',
    colourNote: 'Hex lives only in these reference ramps. Gold-500 is fill, hairline and knot, never text; gold-700 is the only gold for text and icons.',
    onCanvas: 'canvas',
    onInk: 'ink',
    roles: 'Semantic roles',
    rolesNote: 'The only colour surface for components. Each role names the ramp step it points at.',
    contrast: 'Contrast',
    contrastNote: 'Every allowed foreground and background pair, recomputed from the tokens at build time. Text needs 4.5, UI boundaries 3.',
    failing: 'Recorded failures (must stay failing)',
    type: 'Type',
    typeNote: 'Newsreader and Amiri for display moments; Poppins and Cairo for UI; Cairo tabular digits for every number. Sizes and leading differ per script, so each role is measured twice.',
    figures: 'Figures and money',
    figuresNote: 'Numbers are Cairo Western digits, tabular, an LTR island in both languages. The currency sits visually left of the amount; fils are 0.8 of the amount.',
    space: 'Space and sizes',
    spaceNote: 'A 4-point scale, one gutter (20), one section rhythm (32). Control heights are 44, 48, 52 and 56.',
    shape: 'Shape, elevation, stroke',
    shapeNote: 'Radius 8 for controls, 12 for cards, 20 for sheets, 4 for pills. Hairline first; one warm shadow family for things that float.',
    motion: 'Motion',
    motionNote: 'Four durations, three curves, one spring. Nothing loops and nothing blocks input. With reduced motion the movement goes and the cross-fade stays.',
    thread: 'The thread',
    threadNote: 'Gold is a verb: the khayt marks a place, the knots mark state. Never decoration.',
    icons: 'Icons',
    iconsNote: 'Phosphor, curated subset. Arrows, chevrons, back, send, lists and undo flip in Arabic; nothing else does.',
    replay: 'Replay',
    mirrors: 'mirrors',
    pass: 'pass',
    fail: 'fail',
    ink: 'Ink', gold: 'Gold', rose: 'Rose', neutral: 'Neutrals', functional: 'Functional (status only)',
    tint: 'Quiet panel', strong: 'Strong',
    light: 'Light (comparison only)', regular: 'Regular (product weight, 1.5 px at 24)',
    weightsNote: 'Regular is the product weight: exactly the 1.5 px the stroke token names. Light measures 1.125 px at 24 and stays in the registry for comparison.',
    measured: 'measured', ok: 'ok',
  },
  ar: {
    eyebrow: 'نظام التصميم',
    title: 'رموز التصميم',
    lede: 'كل لون ومسافة وزاوية وحجم خط وحركة في المنتج. تقرأ المكوّنات هذه القيم عبر var(--gz-...) ولا شيء غيرها، ويتحقق المولّد عند كل بناء من التباين والشبكة وتطابق العربية.',
    colour: 'تدرّجات الألوان',
    colourNote: 'القيم السداسية لا تُكتب إلا في هذه التدرّجات المرجعية. الذهبي 500 للتعبئة والخطوط الدقيقة والعُقد، وليس للنص أبداً؛ والذهبي 700 هو الوحيد للنصوص والأيقونات.',
    onCanvas: 'الخلفية',
    onInk: 'الحبر',
    roles: 'الأدوار الدلالية',
    rolesNote: 'السطح اللوني الوحيد للمكوّنات. كل دور يسمّي درجة التدرّج التي يشير إليها.',
    contrast: 'التباين',
    contrastNote: 'كل زوج مسموح من لون الأمام والخلفية، يُحسب من الرموز عند البناء. النص يحتاج 4.5 وحدود الواجهة 3.',
    failing: 'حالات فاشلة مسجّلة (يجب أن تبقى فاشلة)',
    type: 'الخطوط',
    typeNote: 'نيوزريدر وأميري للعناوين الكبيرة؛ بوبينز والقاهرة للواجهة؛ أرقام القاهرة المتساوية العرض لكل رقم. تختلف الأحجام والتباعد بين الكتابتين، لذا يُقاس كل دور مرتين.',
    figures: 'الأرقام والمبالغ',
    figuresNote: 'الأرقام غربية بخط القاهرة، متساوية العرض، وجزيرة من اليسار إلى اليمين في اللغتين. العملة على يسار المبلغ بصرياً، والفلوس بنسبة 0.8 من المبلغ.',
    space: 'المسافات والأحجام',
    spaceNote: 'سلّم من أربع نقاط، وهامش واحد (20)، وإيقاع أقسام واحد (32). ارتفاعات عناصر التحكم 44 و 48 و 52 و 56.',
    shape: 'الشكل والارتفاع والخطوط',
    shapeNote: 'زاوية 8 لعناصر التحكم، و 12 للبطاقات، و 20 للأوراق السفلية، و 4 للشارات. الخط الدقيق أولاً؛ وعائلة ظلال دافئة واحدة لما يطفو.',
    motion: 'الحركة',
    motionNote: 'أربع مدد وثلاثة منحنيات ونابض واحد. لا شيء يتكرر ولا شيء يمنع اللمس. مع تقليل الحركة تزول الحركة ويبقى التلاشي.',
    thread: 'الخيط',
    threadNote: 'الذهبي فعل: الخيط الدقيق يحدّد المكان والعُقد تحدّد الحالة. ليس زينة أبداً.',
    icons: 'الأيقونات',
    iconsNote: 'مجموعة فوسفور منتقاة. الأسهم والأقواس والرجوع والإرسال والقوائم والتراجع تنعكس بالعربية، ولا شيء غيرها.',
    replay: 'أعد التشغيل',
    mirrors: 'تنعكس',
    pass: 'ناجح',
    fail: 'فاشل',
    ink: 'الحبر', gold: 'الذهبي', rose: 'الوردي', neutral: 'المحايدة', functional: 'الوظيفية (للحالة فقط)',
    tint: 'لوحة هادئة', strong: 'قوي',
    light: 'خفيف (للمقارنة فقط)', regular: 'عادي (الأساسي، 1.5 على 24)',
    weightsNote: 'العادي هو السُّمك المعتمد: بالضبط 1.5 التي يسمّيها رمز السُّمك. الخفيف يقيس 1.125 على 24 ويبقى في السجل للمقارنة.',
    measured: 'مقاس', ok: 'سليم',
  },
} as const

const NOTE: Record<string, { en: string; ar: string }> = {
  'color.ref.ink.900': { en: 'headings, label on gold', ar: 'العناوين وتسمية الذهبي' },
  'color.ref.ink.800': { en: 'dark panel raised', ar: 'سطح داكن مرتفع' },
  'color.ref.ink.700': { en: 'body, PRD ink', ar: 'النص الأساسي' },
  'color.ref.ink.600': { en: 'muted text', ar: 'نص خافت' },
  'color.ref.ink.500': { en: 'control border', ar: 'حدّ العناصر' },
  'color.ref.ink.300': { en: 'strong line', ar: 'خط قوي' },
  'color.ref.ink.200': { en: 'hairline', ar: 'خط دقيق' },
  'color.ref.ink.100': { en: 'placeholder, track', ar: 'مكان الصورة' },
  'color.ref.ink.50': { en: 'quiet surface', ar: 'سطح هادئ' },
  'color.ref.gold.700': { en: 'the gold for text', ar: 'ذهبي النص' },
  'color.ref.gold.650': { en: 'state stroke', ar: 'خط الحالة' },
  'color.ref.gold.600': { en: 'decor hairline', ar: 'خط زخرفي' },
  'color.ref.gold.550': { en: 'pressed fill', ar: 'تعبئة الضغط' },
  'color.ref.gold.500': { en: 'fill, never text', ar: 'تعبئة، ليس نصاً' },
  'color.ref.gold.100': { en: 'pending pill', ar: 'شارة الانتظار' },
  'color.ref.rose.100': { en: 'quiet panel', ar: 'لوحة هادئة' },
  'color.ref.neutral.canvas': { en: 'surface', ar: 'السطح' },
  'color.ref.neutral.paper': { en: 'raised, inputs', ar: 'مرتفع، حقول' },
}

// ---------------------------------------------------------------------------------------------------------------- colour
function Swatch({ path, lang }: { path: string; lang: Lang }) {
  const hex = hexOf(path)
  const canvas = hexOf('color.ref.neutral.canvas')
  const ink = hexOf('color.ref.ink.900')
  const onC = ratio(hex, canvas)
  const onI = ratio(hex, ink)
  const textOnChip = ratio(hex, canvas) >= ratio(hex, ink) ? canvas : ink
  const t = T[lang]
  const note = NOTE[path]
  const step = path.split('.').slice(-1)[0] ?? ''
  return (
    <div className="tk-sw" data-gz-id={path}>
      <div className="tk-sw__chip" style={{ background: hex }}>
        <span className="tk-sw__aa" style={{ color: textOnChip }}>Aa</span>
        <span className="tk-sw__aa" style={{ color: textOnChip }}><Num>{Math.max(onC, onI).toFixed(1)}</Num></span>
      </div>
      <div className="tk-sw__meta">
        <span className="gz-t-title tk-sw__step"><Isolate>{step}</Isolate></span>
        <span className="gz-t-caption tk-sw__line"><Isolate>{hex.toUpperCase()}</Isolate></span>
        <span className="gz-t-caption tk-sw__line">{t.onCanvas} <Num>{onC.toFixed(2)}</Num></span>
        <span className="gz-t-caption tk-sw__line">{t.onInk} <Num>{onI.toFixed(2)}</Num></span>
        {note ? <span className="gz-t-caption" style={{ color: 'var(--gz-color-sys-text-gold-ink)' }}>{note[lang]}</span> : null}
      </div>
    </div>
  )
}

/** Invisible fillers so the last row of a flex-wrap ramp keeps the same column width as the rows above it. */
const Ghosts = () => <>{[0, 1, 2, 3].map(i => <span key={i} className="tk-sw tk-sw--ghost" aria-hidden="true" />)}</>

function Ramps({ lang }: { lang: Lang }) {
  const t = T[lang]
  const groups: [string, string][] = [
    [t.ink, 'color.ref.ink.'], [t.gold, 'color.ref.gold.'], [t.rose, 'color.ref.rose.'], [t.neutral, 'color.ref.neutral.'],
  ]
  const paths = (prefix: string) =>
    Object.keys(entries).filter(p => p.startsWith(prefix)).sort((a, b) => Number(b.split('.').pop()) - Number(a.split('.').pop()) || a.localeCompare(b))
  return (
    <Section title={t.colour} note={t.colourNote}>
      {groups.map(([name, prefix]) => (
        <div className="tk-sub" key={prefix}>
          <h3 className="gz-t-ui-title">{name}</h3>
          <div className="tk-ramp">{paths(prefix).map(p => <Swatch key={p} path={p} lang={lang} />)}<Ghosts /></div>
        </div>
      ))}
      <div className="tk-sub">
        <h3 className="gz-t-ui-title">{t.functional}</h3>
        <div className="tk-ramp">
          {['color.ref.success.700', 'color.ref.success.100', 'color.ref.danger.700', 'color.ref.danger.100'].map(p => <Swatch key={p} path={p} lang={lang} />)}
          <Ghosts />
        </div>
      </div>
    </Section>
  )
}

function Roles({ lang }: { lang: Lang }) {
  const t = T[lang]
  const sys = Object.keys(entries).filter(p => p.startsWith('color.sys.') && get(p).type === 'color')
  const groups = new Map<string, string[]>()
  for (const p of sys) {
    const g = p.split('.')[2] ?? ''
    groups.set(g, [...(groups.get(g) ?? []), p])
  }
  return (
    <Section title={t.roles} note={t.rolesNote}>
      {[...groups].map(([g, list]) => (
        <div className="tk-group" key={g}>
          <h3 className="gz-t-ui-title"><Isolate>{g}</Isolate></h3>
          <div className="tk-rows">
            {list.map(p => {
              const e = get(p)
              const refName = (e.ref ?? '').replace('color.ref.', '')
              return (
                <div className="tk-row" key={p} data-gz-id={p}>
                  <span className="tk-row__chip" style={{ background: String(e.value) }} />
                  <span className="tk-row__main">
                    <span className="gz-t-body-s tk-row__name"><Isolate>{p.replace('color.sys.', '')}</Isolate></span>
                  </span>
                  <span className="gz-t-caption tk-row__end"><Isolate>{refName}</Isolate></span>
                </div>
              )
            })}
          </div>
        </div>
      ))}
    </Section>
  )
}

type Pair = { fg: string; bg: string; kind: 'text' | 'ui'; use: string }
function Contrast({ lang }: { lang: Lang }) {
  const t = T[lang]
  const pairs = (pairsFile.pairs as Pair[]).filter(p => p.fg.startsWith('color.sys.'))
  const byFg = new Map<string, Pair[]>()
  for (const p of pairs) byFg.set(p.fg, [...(byFg.get(p.fg) ?? []), p])
  const min = pairsFile.thresholds
  const fails = pairsFile.mustFail as { fg: string; bg: string; why: string }[]
  return (
    <Section title={t.contrast} note={t.contrastNote}>
      <div>
        {[...byFg].map(([fg, list]) => (
          <div className="tk-pair" key={fg}>
            <span className="gz-t-body-s gz-text-strong"><Isolate>{fg.replace('color.sys.', '')}</Isolate></span>
            <div className="tk-pair__tiles">
              {list.map(p => {
                const r = ratio(hexOf(p.fg), hexOf(p.bg))
                const ok = r >= min[p.kind]
                return (
                  <div className="tk-tile" key={p.bg} title={`${p.fg} on ${p.bg}`}>
                    <span className="tk-tile__swatch gz-t-ui-title" style={{ background: cssv(p.bg), color: cssv(p.fg) }}>{p.kind === 'text' ? 'Aa' : <span style={{ inlineSize: 'var(--gz-size-icon-lg)', blockSize: 'var(--gz-stroke-thread)', background: cssv(p.fg) }} />}</span>
                    <span className={`gz-t-caption ${ok ? 'tk-ok' : 'tk-bad'}`}><Num>{r.toFixed(2)}</Num></span>
                  </div>
                )
              })}
            </div>
          </div>
        ))}
      </div>
      <div className="tk-sub">
        <h3 className="gz-t-ui-title">{t.failing}</h3>
        <div className="tk-pair__tiles">
          {fails.map(f => (
            <div className="tk-tile" key={f.fg + f.bg} title={f.why}>
              <span className="tk-tile__swatch gz-t-ui-title" style={{ background: cssv(f.bg), color: cssv(f.fg) }}>Aa</span>
              <span className="gz-t-caption tk-bad"><Num>{ratio(hexOf(f.fg), hexOf(f.bg)).toFixed(2)}</Num></span>
            </div>
          ))}
        </div>
      </div>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- type
const SAMPLE: Record<string, [string, string]> = {
  label: ['Your date', 'تاريخ زفافك'],
  caption: ['Nothing is charged until the hotel approves.', 'لن يُخصم أي مبلغ حتى يوافق الفندق.'],
  'body-s': ['Hall, session and date are held while the hotel replies.', 'تُحجز القاعة والفترة والتاريخ إلى أن يردّ الفندق.'],
  body: ['Request this date, free of charge, in under a minute.', 'اطلب هذا التاريخ مجاناً في أقل من دقيقة.'],
  title: ['Aurelia Gulf Ballroom', 'قاعة أوريليا الخليج'],
  button: ['Request this date', 'اطلب هذا التاريخ'],
  pill: ['Pending', 'قيد الانتظار'],
  tab: ['Discover', 'استكشف'],
  'ui-title': ['Needs your reply', 'بانتظار ردّك'],
  'ui-xl': ['Thursday 14 Jan', 'الخميس 14 يناير'],
  d1: ['Aurelia Gulf Ballroom', 'قاعة أوريليا الخليج'],
  d2: ['Aurelia Gulf Ballroom', 'قاعة أوريليا الخليج'],
  d3: ['Aurelia Gulf', 'أوريليا الخليج'],
  d4: ['Aurelia', 'أوريليا'],
  d5: ['Aurelia', 'أوريليا'],
  d6: ['Aurelia', 'أوريليا'],
  brief: ['A women’s evening for 350 guests on Thursday 14 January in Salmiya.', 'حفل نسائي لعدد 350 مدعواً يوم الخميس 14 يناير في السالمية.'],
  countdown: ['142', '142'],
  'compare-name': ['Aurelia Gulf Ballroom', 'قاعة أوريليا الخليج'],
  wordmark: ['Ghazal', 'غزل'],
}
const NUMBERS: [string, string] = ['2,450', '2,450']

function Spec({ role, lang }: { role: string; lang: Lang }) {
  const en = flat[`type.en.${role}` as TokenPath] as unknown as Record<string, unknown>
  const ar = flat[`type.ar.${role}` as TokenPath] as unknown as Record<string, unknown>
  const fmt = (v: Record<string, unknown>) =>
    `${v.fontSize}/${v.lineHeight} · ${v.fontWeight}${Number(v.letterSpacing) ? ` · ${v.letterSpacing}px` : ''}${Number(v.wordSpacing) ? ` · ws ${v.wordSpacing}` : ''}`
  const sample = SAMPLE[role] ?? NUMBERS
  const isFig = role.startsWith('fig-') || ['price', 'price-strong', 'price-total', 'kpi', 'fils-price', 'fils-total', 'cal-day', 'cal-price', 'badge', 'statusbar', 'timeline-time'].includes(role)
  const enText = isFig ? NUMBERS[0] : sample[0]
  const arText = isFig ? NUMBERS[1] : sample[1]
  const pageLang = lang
  void pageLang
  return (
    <div className="tk-spec" data-gz-id={`type.${role}`}>
      <div className="tk-spec__meta">
        <span className="gz-t-title tk-spec__role"><Isolate>{`.gz-t-${role}`}</Isolate></span>
        <span className="gz-t-caption tk-spec__tag"><Isolate>EN {fmt(en)}</Isolate></span>
        <span className="gz-t-caption tk-spec__tag"><Isolate>AR {fmt(ar)}</Isolate></span>
      </div>
      <div lang="en" dir="ltr" className={`gz-t-${role} tk-spec__sample`}>{enText}</div>
      <div lang="ar" dir="rtl" className={`gz-t-${role} tk-spec__sample tk-spec__sample--ar`}>{arText}</div>
    </div>
  )
}

function TypeSection({ lang }: { lang: Lang }) {
  const t = T[lang]
  const roles = useMemo(() => Object.keys(entries).filter(p => p.startsWith('type.en.')).map(p => p.slice(8)), [])
  return (
    <Section title={t.type} note={t.typeNote}>
      <div>{roles.map(r => <Spec key={r} role={r} lang={lang} />)}</div>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- figures
type PriceRow = { key: string; en: ReactNode; ar: ReactNode; label: string; labelAr: string }
const Money = ({ cur, amt, fils, role, variant }: { cur: string; amt: string; fils?: string; role: string; variant?: string }) => (
  <span className={`gz-money${variant ? ` ${variant}` : ''}`}>
    <span className="gz-money__cur">{cur}</span>
    <span className="gz-money__num">
      <span className={`gz-money__amt ${role}`}>{amt}</span>
      {fils ? <span className="gz-money__fils">{fils}</span> : null}
    </span>
  </span>
)

function Figures({ lang }: { lang: Lang }) {
  const t = T[lang]
  const rows: PriceRow[] = [
    { key: 'card', label: 'Card price line (browse)', labelAr: 'سطر سعر البطاقة (تصفّح)',
      en: <span className="gz-t-body-s">From <Money cur="KD" amt="2,450" role="gz-t-price" /> for <Num>300</Num> guests</span>,
      ar: <span className="gz-t-body-s">من <Money cur="د.ك" amt="2,450" role="gz-t-price" /> لعدد <Num>300</Num> ضيف</span> },
    { key: 'plate', label: 'Plate and sticky bar price (display)', labelAr: 'سعر اللوحة وشريط الحجز (عرض)',
      en: <Money cur="KD" amt="2,450" role="" variant="gz-money--display" />, ar: <Money cur="د.ك" amt="2,450" role="" variant="gz-money--display" /> },
    { key: 'exact', label: 'Deposit and schedule (exact)', labelAr: 'العربون والجدول (دقيق)',
      en: <Money cur="KD" amt="1,225" fils=".000" role="gz-t-price-strong" />, ar: <Money cur="د.ك" amt="1,225" fils=".000" role="gz-t-price-strong" /> },
    { key: 'total', label: 'Total (exact)', labelAr: 'الإجمالي (دقيق)',
      en: <Money cur="KD" amt="18,200" fils=".000" role="gz-t-price-total" variant="gz-money--total" />, ar: <Money cur="د.ك" amt="18,200" fils=".000" role="gz-t-price-total" variant="gz-money--total" /> },
    { key: 'kpi', label: 'Hotel KPI (never serif)', labelAr: 'مؤشر الفندق (بلا خط عرض)',
      en: <span className="gz-t-kpi">38</span>, ar: <span className="gz-t-kpi">38</span> },
  ]
  return (
    <Section title={t.figures} note={t.figuresNote}>
      <div>
        {rows.map(r => (
          <div className="tk-price" key={r.key}>
            <span className="gz-t-caption tk-note">{L(lang, r.label, r.labelAr)}</span>
            <div lang="en" dir="ltr" className="tk-price__line">{r.en}</div>
            <div lang="ar" dir="rtl" className="tk-price__line">{r.ar}</div>
          </div>
        ))}
      </div>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- space
function SpaceSection({ lang }: { lang: Lang }) {
  const t = T[lang]
  const steps = [0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24]
  const controls: [string, number, string, string][] = [
    ['size.control.sm', 44, 'icon buttons, chips, segmented options', 'أزرار الأيقونات والرقاقات وخيارات التبديل'],
    ['size.control.md', 48, 'secondary buttons', 'الأزرار الثانوية'],
    ['size.control.cta', 52, 'primary CTA', 'زر الإجراء الأساسي'],
    ['size.control.lg', 56, 'inputs, top-bar row', 'الحقول وصف الشريط العلوي'],
  ]
  return (
    <Section title={t.space} note={t.spaceNote}>
      <div className="tk-bars">
        {steps.map(n => {
          const px = val<number>(`space.${n}` as TokenPath)
          return (
            <div className="tk-bar" key={n}>
              <span className="gz-t-caption tk-bar__label"><Isolate>{`space.${n}`}</Isolate></span>
              <span className="tk-bar__fill" style={{ inlineSize: px }} />
              <span className="gz-t-caption tk-note"><Num>{px}</Num></span>
            </div>
          )
        })}
        {[['space.gutter', 'gutter'], ['space.section', 'section']].map(([p]) => (
          <div className="tk-bar" key={p}>
            <span className="gz-t-caption tk-bar__label"><Isolate>{p}</Isolate></span>
            <span className="tk-bar__fill tk-bar__fill--ink" style={{ inlineSize: val<number>(p as TokenPath) }} />
            <span className="gz-t-caption tk-note"><Num>{val<number>(p as TokenPath)}</Num></span>
          </div>
        ))}
      </div>
      <div className="tk-controls">
        {controls.map(([p, h, en, ar]) => (
          <div key={p} className={`tk-control${h === 52 ? ' tk-control--gold' : ''}`} style={{ blockSize: h }}>
            <span className="gz-t-button">{L(lang, en, ar)}</span>
            <span className="gz-t-fig-body-s"><Isolate>{p.replace('size.', '')} {h}</Isolate></span>
          </div>
        ))}
      </div>
    </Section>
  )
}

function ShapeSection({ lang }: { lang: Lang }) {
  const t = T[lang]
  const radii: [string, number][] = [['xs', 4], ['sm', 8], ['md', 12], ['lg', 20], ['pill', 9999]]
  const arch = String(flat['shape.arch.path'])
  const crown = arch.replace(/ Z$/, '')
  return (
    <Section title={t.shape} note={t.shapeNote}>
      <div className="tk-boxes">
        {radii.map(([n, px]) => (
          <div className="tk-box" key={n}>
            <span className="tk-box__shape" style={{ borderRadius: cssv(`radius.${n}`) }} />
            <span className="gz-t-caption tk-note"><Isolate>{`radius.${n}`}</Isolate> <Num>{px === 9999 ? '∞' : px}</Num></span>
          </div>
        ))}
        <div className="tk-box">
          <svg viewBox="0 0 100 100" className="tk-box__shape" style={{ border: 0, background: 'none' }} aria-hidden="true">
            <path d={arch} fill={cssv('color.sys.surface.tint')} />
            <path d={crown} fill="none" stroke={cssv('color.sys.mark.khayt')} strokeWidth="1.5" vectorEffect="non-scaling-stroke" />
          </svg>
          <span className="gz-t-caption tk-note"><Isolate>shape.arch</Isolate></span>
        </div>
      </div>
      <div className="tk-boxes">
        {[0, 1, 2, 3].map(n => (
          <div className="tk-box" key={n}>
            <span className={`tk-box__shape${n >= 2 ? ' tk-box__shape--float' : ''}`} style={{ boxShadow: cssv(`elevation.${n}`), borderRadius: cssv('radius.md') }} />
            <span className="gz-t-caption tk-note"><Isolate>{`elevation.${n}`}</Isolate></span>
          </div>
        ))}
      </div>
      <div className="tk-bars">
        {(['stroke.hair', 'stroke.icon', 'stroke.thread', 'stroke.thread-max'] as const).map(p => (
          <div className="tk-bar" key={p}>
            <span className="gz-t-caption tk-bar__label"><Isolate>{p.replace('stroke.', '')}</Isolate></span>
            <span style={{ flex: 1, blockSize: val<number>(p), background: cssv('color.sys.text.strong') }} />
            <span className="gz-t-caption tk-note"><Num>{val<number>(p)}</Num></span>
          </div>
        ))}
      </div>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- motion
function bezier([x1, y1, x2, y2]: number[]) {
  const pts: string[] = []
  const f = (a: number, b: number, t: number) => 3 * (1 - t) ** 2 * t * a + 3 * (1 - t) * t ** 2 * b + t ** 3
  for (let i = 0; i <= 40; i++) {
    const t = i / 40
    pts.push(`${(f(x1 ?? 0, x2 ?? 0, t) * 80 + 4).toFixed(1)},${(80 - f(y1 ?? 0, y2 ?? 0, t) * 72 - 4).toFixed(1)}`)
  }
  return `M${pts.join(' L')}`
}

function MotionSection({ lang }: { lang: Lang }) {
  const t = T[lang]
  const [run, setRun] = useState(0)
  const replay = () => setRun(r => r + 1)
  const durations = ['instant', 'fast', 'base', 'slow', 'expressive', 'success'] as const
  const eases = ['standard', 'emphasized', 'exit'] as const
  const demo = (title: string, node: ReactNode) => (
    <div className="tk-demo">
      <span className="gz-t-ui-title">{title}</span>
      <div className="tk-demo__stage">{node}</div>
    </div>
  )
  return (
    <Section title={t.motion} note={t.motionNote}>
      <div className="tk-bars">
        {durations.map(d => {
          const ms = val<number>(`motion.duration.${d}` as TokenPath)
          return (
            <div className="tk-bar" key={d}>
              <span className="gz-t-caption tk-bar__label"><Isolate>{d}</Isolate></span>
              <span className="tk-bar__fill tk-bar__fill--ink" style={{ inlineSize: Math.max(ms / 4, 4) }} />
              <span className="gz-t-caption tk-note"><Isolate>{ms} ms</Isolate></span>
            </div>
          )
        })}
      </div>
      <div className="tk-curves">
        {eases.map(e => {
          const v = val<number[]>(`motion.ease.${e}` as TokenPath)
          return (
            <div className="tk-curve" key={e}>
              <svg viewBox="0 0 88 88" className="tk-curve__plot" aria-hidden="true">
                <path d={bezier(v)} fill="none" stroke="currentColor" strokeWidth="1.5" />
              </svg>
              <span className="gz-t-caption tk-note"><Isolate>{e}</Isolate></span>
            </div>
          )
        })}
      </div>
      <button type="button" className="tk-replay gz-t-button gz-press" onClick={replay}>{t.replay}</button>
      <div className="tk-demos" key={run}>
        {demo(L(lang, 'Thread draw-on, 480 ms from inline-start', 'رسم الخيط، 480 مللي ثانية من بداية السطر'),
          <div className="gz-thread-track tk-track"><div className="gz-thread-fill gz-thread-draw" /></div>)}
        {demo(L(lang, 'Knot pop, once', 'نبضة العقدة، مرة واحدة'),
          <><span className="gz-knot gz-knot--now gz-knot-pop" /><span className="gz-knot gz-knot--tied gz-knot-pop" /></>)}
        {demo(L(lang, 'Image reveal, 3.5% settle', 'ظهور الصورة، استقرار 3.5%'),
          <div className="gz-reveal-frame tk-photo"><div className="tk-photo__img gz-reveal" /></div>)}
        {demo(L(lang, 'Sheet rise 320 ms', 'صعود الورقة السفلية 320 مللي ثانية'),
          <div className="tk-stage-sheet"><div className="tk-sheet gz-sheet-enter"><span className="tk-sheet__handle" /></div></div>)}
        {demo(L(lang, 'Undo bar, 8 s linear', 'شريط التراجع، 8 ثوانٍ خطياً'),
          <div className="tk-undo"><span className="gz-t-body-s">{L(lang, 'Request withdrawn', 'سُحب الطلب')}</span><span className="tk-undo__line gz-undo-line" /></div>)}
        {demo(L(lang, 'Press: tone step and scale .985 (hold it down)', 'الضغط: تدرّج لوني وتصغير 0.985 (اضغط باستمرار)'),
          <span className="tk-cta gz-t-button gz-press">{L(lang, 'Request this date', 'اطلب هذا التاريخ')}</span>)}
      </div>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- thread
function ThreadSection({ lang }: { lang: Lang }) {
  const t = T[lang]
  const labels = L(lang, ['open', 'now', 'tied', 'bead', 'khayt'], ['مفتوحة', 'الآن', 'معقودة', 'خرزة', 'خيط'])
  return (
    <Section title={t.thread} note={t.threadNote}>
      <div className="tk-knots">
        {[
          <span key="o" className="gz-knot gz-knot--open" />,
          <span key="n" className="gz-knot gz-knot--now" />,
          <span key="t" className="gz-knot gz-knot--tied"><span style={{ inlineSize: 'var(--gz-size-icon-xs)', blockSize: 'var(--gz-size-icon-xs)', display: 'inline-flex' }}><Glyph name="check" /></span></span>,
          <span key="b" className="gz-bead" />,
          <span key="k" className="gz-khayt" />,
        ].map((node, i) => (
          <div className="tk-knotcell" key={i}>
            <div className="tk-knotcell__stage">{node}</div>
            <span className="gz-t-caption tk-note">{labels[i]}</span>
          </div>
        ))}
      </div>
      <div className="tk-darkpanel gz-on-dark">
        <div className="tk-threadrow">
          <span className="gz-knot gz-knot--compact gz-knot--tied" />
          <span className="tk-threadrow__seg tk-threadrow__seg--done" />
          <span className="gz-knot gz-knot--compact gz-knot--tied" />
          <span className="tk-threadrow__seg tk-threadrow__seg--done" />
          <span className="gz-knot gz-knot--compact gz-knot--now" />
          <span className="tk-threadrow__seg" />
          <span className="gz-knot gz-knot--compact gz-knot--open" />
        </div>
        <span className="gz-t-caption gz-text-muted">{L(lang, 'On-dark thread (hotel header, confirmation hero)', 'الخيط على الخلفية الداكنة (شريط الفندق، شاشة التأكيد)')}</span>
      </div>
      <div className="tk-demo__stage">
        <span className="gz-t-caption tk-note" style={{ color: 'var(--gz-color-sys-text-gold-ink)' }}>
          <svg viewBox={brand.divider.viewBox} width="56" height="8" className={brand.divider.mirror ? 'gz-mirror' : undefined} fill="currentColor" aria-hidden="true">
            {brand.divider.paths.map((d, i) => <path key={i} d={d} />)}
          </svg>
        </span>
      </div>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- icons
function IconsSection({ lang }: { lang: Lang }) {
  const t = T[lang]
  const mirror = new Set<string>(mirrorInRtl)
  const sample: IconName[] = ['search', 'calendar', 'pin', 'guests', 'heart', 'bell']
  return (
    <Section title={t.icons} note={t.iconsNote}>
      <div className="tk-weights">
        {(['light', 'regular'] as const).map(w => (
          <div className="tk-weights__col" key={w}>
            <span className="gz-t-ui-title">{t[w]}</span>
            <div className="tk-weights__row">
              {sample.map(n => <span key={n} style={{ inlineSize: 'var(--gz-size-icon-lg)', blockSize: 'var(--gz-size-icon-lg)', display: 'inline-flex' }}><Glyph name={n} weight={w} /></span>)}
            </div>
          </div>
        ))}
      </div>
      <p className="gz-t-caption tk-note">{t.weightsNote}</p>
      <div className="tk-iconsizes">
        {(['xs', 'sm', 'md', 'lg'] as const).map(s => (
          <div className="tk-iconsizes__col" key={s}>
            <span style={{ inlineSize: cssv(`size.icon.${s}`), blockSize: cssv(`size.icon.${s}`), display: 'inline-flex' }}><Glyph name="calendar" /></span>
            <span className="gz-t-caption tk-note"><Num>{val<number>(`size.icon.${s}` as TokenPath)}</Num></span>
          </div>
        ))}
      </div>
      <div className="tk-icons">
        {iconNames.map(n => (
          <div className="tk-icon" key={n} data-gz-id={`icon.${n}`} title={iconGroups[n]}>
            <Glyph name={n} weight="default" mirror={mirror.has(n)} />
            <span className="gz-t-caption tk-icon__name"><Isolate>{n}</Isolate></span>
            {mirror.has(n) ? <span className="gz-t-caption tk-icon__mirror">{t.mirrors}</span> : null}
          </div>
        ))}
      </div>
    </Section>
  )
}

// ---------------------------------------------------------------------------------------------------------------- page
export default function TokensGallery() {
  const { lang } = useLang()
  const t = T[lang]
  return (
    <div className="tk" data-gz="TokensGallery">
      <header className="tk-head">
        <span className="gz-t-label">{t.eyebrow}</span>
        <h1 className="gz-t-d3">{t.title}</h1>
        <p className="gz-t-body tk-note">{t.lede}</p>
      </header>
      <Ramps lang={lang} />
      <Roles lang={lang} />
      <Contrast lang={lang} />
      <TypeSection lang={lang} />
      <Figures lang={lang} />
      <SpaceSection lang={lang} />
      <ShapeSection lang={lang} />
      <MotionSection lang={lang} />
      <ThreadSection lang={lang} />
      <IconsSection lang={lang} />
    </div>
  )
}
