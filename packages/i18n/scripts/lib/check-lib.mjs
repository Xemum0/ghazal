// The i18n lint, as a library so the CLI (check.mjs) and the tests (test/check.test.ts) run the same code.
// Rules come from ADR 0013 D9 (authoring and checks), ADR 0010 D4 (no literal digits, no Intl in strings), ADR 0014 D1
// (no hard-coded left/right), ADR 0024 D7 (key naming) and docs/product/glossary.md section 9 (banned phrases).
import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { join, basename } from 'node:path'
import {
  parse,
  TYPE,
  isLiteralElement,
  isArgumentElement,
  isNumberElement,
  isDateElement,
  isTimeElement,
  isSelectElement,
  isPluralElement,
  isPoundElement,
  isTagElement,
} from '@formatjs/icu-messageformat-parser'

export const LANGS = ['en', 'ar']

/** Latin tokens allowed inside Arabic strings. `KD` and `KWD` are deliberately absent: Arabic says د.ك. */
export const AR_LATIN_ALLOW = ['Ghazal', 'VIP', 'IBAN', 'PACI', 'KNET', 'PDF']

const AR_LETTERS = '؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿'
const RE_ARABIC = new RegExp(`[${AR_LETTERS}]`)
const RE_LATIN = /[A-Za-z]/
const RE_DIGIT = /[0-9٠-٩۰-۹]/
const RE_HEX = /(?:^|[^&\w])#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8}|[0-9a-fA-F]{3})\b|\b(?:rgb|rgba|hsl|hsla)\(/
const RE_LEFT_RIGHT_EN = /\b(left|right)\b/i
const RE_LEFT_RIGHT_AR = /(يمين|يسار)/
const RE_EMOJI = /\p{Extended_Pictographic}/u
const RE_TATWEEL = /ـ/
const RE_ALEF_TANWEEN = /اً/ // alef then fathatan: the ICU form puts the fathatan before the alef (ADR 0013 D3b)
const RE_RELIGIOUS = /(إن شاء الله|ان شاء الله|بإذن الله|الحمد لله|inshallah|in sha allah|god willing)/i
const RE_SENSITIVE_KEY = /(Error|Payment|Legal|Discount|Refund|Terms|Price)/

const AR_WEEKDAY = '(?:الأحد|الاثنين|الإثنين|الثلاثاء|الأربعاء|الخميس|الجمعة|السبت|أحد|اثنين|ثلاثاء|أربعاء|خميس|جمعة|سبت)'
const AR_WORD = (w) => new RegExp(`(?:^|[\\s.،؛؟:«»(])(?:${w})(?=$|[\\s.،؛؟:«»)])`)
const BANNED_EN = [
  [/\bbook now\b/i, '"Book now" (use "Request to book")'],
  [/\bwelcome back\b/i, '"Welcome back"'],
  [/\boops\b/i, '"Oops"'],
  [/\bhurry\b/i, 'urgency word "Hurry"'],
  [/\bdon[’']?t miss out\b/i, '"Don\'t miss out"'],
  [/\bonly \{?\w*\}? ?(?:#|\d+)? ?left\b/i, 'scarcity "Only N left"'],
  [/\bdream wedding\b/i, '"dream wedding"'],
  [/\brejected\b/i, '"Rejected" (client: "Not accepted"; hotel: "Declined")'],
]
const BANNED_AR = [
  [new RegExp(`ليلة\\s+${AR_WEEKDAY}`), '"ليلة" before a weekday (idiom trap, ADR 0011 D6)'],
  [/بالرفاء والبنين/, '"بالرفاء والبنين"'],
  [/حيّ?اك الله/, '"حيّاك الله"'],
  [/حريمي/, '"حريمي" (use الحفل النسائي)'],
  [AR_WORD('اختر|اختاري'), 'gendered imperative اختر / اختاري (use a verbal noun)'],
  [/مدعو(?:ين|ات|ون|ّون)?\b|المدعو/, '"مدعو / مدعوات" (use ضيف / ضيوف)'],
  [/عزيزي العميل/, '"عزيزي العميل"'],
  [AR_WORD('شنو|وين|شلون|زين|الحين|جذي|تبي'), 'dialect word in a label (dialect only in staff-typed chat)'],
]

/** Walks an ICU AST. `visit(el, scope)` runs for every element; scope carries the enclosing plural variables. */
function walk(els, visit, scope = { plurals: [], inPlural: false }) {
  for (const el of els) {
    visit(el, scope)
    if (isSelectElement(el)) {
      for (const opt of Object.values(el.options)) walk(opt.value, visit, scope)
    } else if (isPluralElement(el)) {
      const inner = { plurals: [...scope.plurals, el.value], inPlural: true }
      for (const opt of Object.values(el.options)) walk(opt.value, visit, inner)
    } else if (isTagElement(el)) {
      walk(el.children, visit, scope)
    }
  }
}

/** A representative rendering for length comparison: literals, `other` branches, 4-character stand-ins for values. */
function sample(els) {
  let out = ''
  for (const el of els) {
    if (isLiteralElement(el)) out += el.value
    else if (isPoundElement(el)) out += '55'
    else if (isArgumentElement(el) || isNumberElement(el) || isDateElement(el) || isTimeElement(el)) out += 'xxxx'
    else if (isSelectElement(el) || isPluralElement(el)) out += sample((el.options.other ?? Object.values(el.options)[0]).value)
    else if (isTagElement(el)) out += sample(el.children)
  }
  return out
}

function analyse(message) {
  const ast = parse(message, { requiresOtherClause: true, shouldParseSkeletons: true })
  const literals = []
  const values = new Set()
  const tags = new Set()
  const problems = []
  const plurals = []
  walk(ast, (el, scope) => {
    if (isLiteralElement(el)) literals.push(el.value)
    else if (isTagElement(el)) tags.add(el.value)
    else if (isPoundElement(el)) return
    else {
      values.add(el.value)
      if (isArgumentElement(el) && scope.plurals.includes(el.value)) {
        problems.push(['plain-count', `{${el.value}} inside its own plural prints an unformatted number: use # or {${el.value}, number}`])
      }
      if (isDateElement(el) || isTimeElement(el)) {
        problems.push(['icu-format', `{${el.value}, ${el.type === TYPE.date ? 'date' : 'time'}} is forbidden: pass a string from GzFormat (Asia/Kuwait, fixed patterns)`])
      }
      if (isNumberElement(el) && el.style) {
        const style = typeof el.style === 'string' ? el.style : '::skeleton'
        if (style !== 'percent') problems.push(['icu-format', `{${el.value}, number, ${style}} is forbidden: money and styled numbers come from GzFormat`])
      }
      if (isPluralElement(el)) plurals.push({ name: el.value, keys: new Set(Object.keys(el.options)), type: el.pluralType })
    }
  })
  return { ast, text: literals.join(''), literals, values, tags, problems, plurals, sample: sample(ast) }
}

function pluralMissing(lang, keys) {
  const has = (cat, exact) => keys.has(cat) || keys.has(exact)
  if (lang === 'en') {
    const missing = []
    if (!has('one', '=1')) missing.push('one')
    if (!keys.has('other')) missing.push('other')
    return missing
  }
  const missing = []
  if (!has('zero', '=0')) missing.push('zero (or =0)')
  if (!has('one', '=1')) missing.push('one (or =1)')
  if (!has('two', '=2')) missing.push('two (or =2)')
  for (const c of ['few', 'many', 'other']) if (!keys.has(c)) missing.push(c)
  return missing
}

const camel = (ns) => ns.replace(/-([a-z0-9])/g, (_, c) => c.toUpperCase())
const KEY_RE = /^[a-z][A-Za-z0-9]*$/

/** Generated file listing the namespaces and typing their keys from the English JSON. */
export function renderNamespacesFile(namespaces) {
  const imports = namespaces.map((n) => `import type en_${camel(n)} from '../../messages/en/${n}.json'`).join('\n')
  const map = namespaces.map((n) => `  '${n}': typeof en_${camel(n)}`).join('\n')
  const list = namespaces.map((n) => `'${n}'`).join(', ')
  return `// GENERATED by \`pnpm i18n:check --write\` from packages/i18n/messages. Do not edit by hand.
// One entry per namespace; the key types come from the English JSON, so \`t('typo')\` fails type-checking.
${imports}

export type NamespaceMessages = {
${map}
}

export type Namespace = keyof NamespaceMessages

export const NAMESPACES = [${list}] as const satisfies readonly Namespace[]
`
}

export function loadAllow(messagesDir) {
  const p = join(messagesDir, 'allow.json')
  if (!existsSync(p)) return {}
  const raw = JSON.parse(readFileSync(p, 'utf8'))
  return Object.fromEntries(Object.entries(raw).filter(([k]) => !k.startsWith('_')))
}

const listNamespaces = (dir) =>
  existsSync(dir)
    ? readdirSync(dir)
        .filter((f) => f.endsWith('.json') && !f.startsWith('_'))
        .map((f) => basename(f, '.json'))
        .sort()
    : []

/**
 * Runs every rule. Returns `{ errors, warnings, namespaces, stats }`; each finding is
 * `{ level, rule, file, key, message }`.
 */
export function checkAll({ messagesDir, generatedFile, readGenerated }) {
  const findings = []
  const add = (level, rule, file, key, message) => findings.push({ level, rule, file, key, message })
  const allow = loadAllow(messagesDir)
  const allowed = (key, rule) => (allow[key] ?? []).includes(rule)
  const flag = (level, rule, file, key, message) => {
    if (!allowed(key, rule)) add(level, rule, file, key, message)
  }

  const nsByLang = Object.fromEntries(LANGS.map((l) => [l, listNamespaces(join(messagesDir, l))]))
  const namespaces = [...new Set(LANGS.flatMap((l) => nsByLang[l]))].sort()
  for (const ns of namespaces) {
    for (const l of LANGS) {
      if (!nsByLang[l].includes(ns)) add('error', 'namespace-parity', `${l}/${ns}.json`, '', `namespace "${ns}" exists in another language but not in ${l}`)
    }
  }

  const catalogs = {}
  let keyCount = 0
  const seenKeys = new Map() // key -> "lang/ns" for cross-namespace duplicates
  for (const ns of namespaces) {
    for (const lang of LANGS) {
      const file = `${lang}/${ns}.json`
      const path = join(messagesDir, file)
      if (!existsSync(path)) continue
      let json
      try {
        json = JSON.parse(readFileSync(path, 'utf8'))
      } catch (e) {
        add('error', 'json', file, '', `invalid JSON: ${e.message}`)
        continue
      }
      if (json === null || typeof json !== 'object' || Array.isArray(json)) {
        add('error', 'json', file, '', 'must be a flat object of key to string')
        continue
      }
      catalogs[`${lang}/${ns}`] = json
    }

    const en = catalogs[`en/${ns}`]
    const ar = catalogs[`ar/${ns}`]
    if (!en || !ar) continue
    const prefix = camel(ns)

    for (const lang of LANGS) {
      const file = `${lang}/${ns}.json`
      const cat = catalogs[`${lang}/${ns}`]
      const other = lang === 'en' ? ar : en
      for (const [key, value] of Object.entries(cat)) {
        if (lang === 'en') keyCount++
        if (!KEY_RE.test(key)) add('error', 'key-name', file, key, 'keys are camelCase letters and digits only: no dots, dashes or underscores')
        else if (!key.startsWith(prefix)) add('error', 'key-name', file, key, `keys in "${ns}" start with "${prefix}" (<feature><Screen><Element>, ADR 0024 D7)`)
        if (typeof value !== 'string') {
          add('error', 'json', file, key, 'value must be a string')
          continue
        }
        if (!(key in other)) {
          add('error', 'key-parity', file, key, `key exists in ${lang} but not in ${lang === 'en' ? 'ar' : 'en'}`)
          continue
        }
        const owner = seenKeys.get(`${lang}:${key}`)
        if (owner && owner !== ns) add('error', 'key-name', file, key, `key also defined in namespace "${owner}"`)
        seenKeys.set(`${lang}:${key}`, ns)
      }
    }

    for (const key of Object.keys(en)) {
      const enMsg = en[key]
      const arMsg = ar[key]
      if (typeof enMsg !== 'string' || typeof arMsg !== 'string') continue
      const parsed = {}
      let ok = true
      for (const [lang, msg] of [['en', enMsg], ['ar', arMsg]]) {
        const file = `${lang}/${ns}.json`
        try {
          parsed[lang] = analyse(msg)
        } catch (e) {
          ok = false
          add('error', 'icu-syntax', file, key, `invalid ICU MessageFormat: ${e.message}`)
        }
      }
      if (!ok) continue

      // Placeholder parity.
      const same = (a, b) => a.size === b.size && [...a].every((x) => b.has(x))
      if (!same(parsed.en.values, parsed.ar.values) || !same(parsed.en.tags, parsed.ar.tags)) {
        const show = (p) => [...p.values, ...[...p.tags].map((t) => `<${t}>`)].sort().join(', ') || 'none'
        add('error', 'placeholders', `ar/${ns}.json`, key, `placeholders differ: en {${show(parsed.en)}} vs ar {${show(parsed.ar)}}`)
      }

      for (const lang of LANGS) {
        const file = `${lang}/${ns}.json`
        const p = parsed[lang]
        const msg = lang === 'en' ? enMsg : arMsg
        for (const [rule, text] of p.problems) flag('error', rule, file, key, text)
        for (const pl of p.plurals) {
          if (pl.type === 'ordinal') {
            flag('error', 'plural', file, key, 'ordinal plurals are not used (ordinal-free copy)')
            continue
          }
          const missing = pluralMissing(lang, pl.keys)
          if (missing.length) flag('error', 'plural', file, key, `plural on {${pl.name}} is missing: ${missing.join(', ')}`)
        }
        const text = p.text
        if (RE_HEX.test(msg)) flag('error', 'hex', file, key, 'contains a raw colour value')
        if (lang === 'en' && RE_LEFT_RIGHT_EN.test(text)) flag('error', 'left-right', file, key, 'hard-coded "left" or "right" wording: use start/end or name the thing (ADR 0014)')
        if (lang === 'ar' && RE_LEFT_RIGHT_AR.test(text)) flag('error', 'left-right', file, key, 'hard-coded يمين / يسار wording: use start/end or name the thing (ADR 0014)')
        if (RE_DIGIT.test(text)) flag('error', 'digits', file, key, 'literal digit in prose: pass numbers as placeholders ({n, number} or #) so they use the formatter (ADR 0010 D4)')
        if (text.includes('!')) flag('error', 'banned', file, key, 'exclamation mark (ADR 0013 D5)')
        if (RE_EMOJI.test(text)) flag('error', 'banned', file, key, 'emoji')
        if (RE_RELIGIOUS.test(text) && RE_SENSITIVE_KEY.test(key)) flag('error', 'banned', file, key, 'religious phrase in payment, error, legal or discount copy (ADR 0013 D5)')
        for (const [re, label] of lang === 'en' ? BANNED_EN : BANNED_AR) {
          if (re.test(text)) flag('error', 'banned', file, key, `banned wording: ${label}`)
        }
        if (lang === 'en' && RE_ARABIC.test(text)) flag('error', 'arabic-in-en', file, key, 'Arabic script in an English string')
        if (lang === 'ar') {
          if (/\bK\.?W?D\b/.test(text)) flag('error', 'latin', file, key, 'KD / KWD in Arabic: write د.ك after the formatted number (ADR 0010 D7)')
          let rest = text
          for (const token of AR_LATIN_ALLOW) rest = rest.split(token).join('')
          if (RE_LATIN.test(rest) && !/\bK\.?W?D\b/.test(text)) flag('error', 'latin', file, key, `Latin letters in an Arabic string (allowed: ${AR_LATIN_ALLOW.join(', ')}): ${rest.match(/[A-Za-z][A-Za-z0-9 ]*/)?.[0]}`)
          if (/[?;]/.test(text)) flag('error', 'punctuation', file, key, 'Latin ? or ; in Arabic text: use ؟ and ؛')
          if (/(?<!\d),|,(?!\d)/.test(text)) flag('error', 'punctuation', file, key, 'Latin comma in Arabic text: use ، (the Latin comma only inside numbers)')
          if (RE_TATWEEL.test(text)) flag('error', 'punctuation', file, key, 'tatweel (ـ) is not used')
          if (/"/.test(text)) flag('warn', 'punctuation', file, key, 'straight quotes in Arabic: use « »')
          if (RE_ALEF_TANWEEN.test(text)) flag('warn', 'tanween', file, key, 'tanween: write the fathatan before the alef (يومًا, مقدمًا) so hand-written text matches ICU plurals (ADR 0013 D3b)')
        } else if (/'/.test(text)) {
          flag('warn', 'punctuation', file, key, "straight apostrophe: use ’ (and it can start ICU quoting)")
        }
      }

      // Length ratio: warn above 1.6x (ADR 0013 D9).
      const a = parsed.ar.sample.length
      const e = parsed.en.sample.length
      if (e >= 14 && a > e * 1.6) flag('warn', 'length', `ar/${ns}.json`, key, `Arabic is ${(a / e).toFixed(2)}x the English length (${a} vs ${e}); check it fits`)
    }
  }

  // The generated namespace/type file must match the directory.
  if (generatedFile) {
    const expected = renderNamespacesFile(namespaces)
    const actual = readGenerated ? readGenerated() : null
    if (actual !== expected) {
      add('error', 'generated', generatedFile, '', 'namespace list is stale: run `pnpm i18n:check --write`')
    }
  }

  const errors = findings.filter((f) => f.level === 'error')
  const warnings = findings.filter((f) => f.level === 'warn')
  return { errors, warnings, namespaces, expectedGenerated: renderNamespacesFile(namespaces), stats: { namespaces: namespaces.length, keys: keyCount } }
}
