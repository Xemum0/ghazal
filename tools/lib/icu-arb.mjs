// Shared by tools/gen-l10n.mjs and tools/export-message-cases.mjs: reads the ICU messages of packages/i18n, derives the
// ARB placeholder metadata and rewrites a message into the ARB dialect of Flutter gen_l10n.
import { createRequire } from 'node:module'
import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')
const require = createRequire(resolve(root, 'packages/i18n/package.json'))
const { parse, TYPE } = require('@formatjs/icu-messageformat-parser')

const LRI = '⁦'
const PDI = '⁩'

export const messagesDir = (lang) => resolve(root, 'packages/i18n/messages', lang)
export const partsDir = resolve(root, 'packages/ghazal_ui/l10n_src')

export const namespaces = () =>
  readdirSync(messagesDir('en'))
    .filter((f) => f.endsWith('.json'))
    .map((f) => f.replace(/\.json$/, ''))
    .sort()

export const readNs = (lang, ns) => JSON.parse(readFileSync(resolve(messagesDir(lang), `${ns}.json`), 'utf8'))

/** ghazal_ui component-owned parts: l10n_src/<part>.{en,ar}.json. */
export function readUiParts(lang) {
  if (!existsSync(partsDir)) return {}
  const out = {}
  for (const f of readdirSync(partsDir).filter((x) => x.endsWith(`.${lang}.json`)).sort()) {
    for (const [k, v] of Object.entries(JSON.parse(readFileSync(resolve(partsDir, f), 'utf8')))) {
      if (k in out) throw new Error(`duplicate key ${k} in l10n_src`)
      out[k] = v
    }
  }
  return out
}

export const uiPartNames = () =>
  existsSync(partsDir)
    ? [...new Set(readdirSync(partsDir).filter((f) => /\.(en|ar)\.json$/.test(f)).map((f) => f.replace(/\.(en|ar)\.json$/, '')))].sort()
    : []

/** The three generated bundles. `parts` marks the ghazal_ui bundle that also reads l10n_src. */
export const bundles = () => {
  const all = namespaces()
  return {
    client: { dir: 'apps/client_app/lib/l10n', prefix: 'app', cls: 'AppL10n', namespaces: ['common', ...all.filter((n) => n.startsWith('client-'))] },
    provider: { dir: 'apps/provider_app/lib/l10n', prefix: 'app', cls: 'AppL10n', namespaces: ['common', ...all.filter((n) => n.startsWith('hotel-'))] },
    ui: { dir: 'packages/ghazal_ui/lib/l10n', prefix: 'gz', cls: 'GzL10n', namespaces: ['common'], parts: true },
  }
}

export function bundleMessages(bundle, lang) {
  const out = {}
  for (const ns of bundle.namespaces) {
    for (const [k, v] of Object.entries(readNs(lang, ns))) {
      if (k in out) throw new Error(`duplicate key ${k} (namespace ${ns})`)
      out[k] = v
    }
  }
  if (bundle.parts) {
    for (const [k, v] of Object.entries(readUiParts(lang))) {
      if (k in out) throw new Error(`l10n_src key ${k} collides with a common key`)
      out[k] = v
    }
  }
  return out
}

// ICU AST helpers -------------------------------------------------------------------------------------------------

const ast = (message) => parse(message, { ignoreTag: true })

/**
 * Placeholders of one message, in order of first appearance: name -> {kind: 'plural' | 'number' | 'select' | 'plain',
 * options?: string[]}. Plural beats number beats plain; a name used both in a plural and bare is an error.
 */
export function placeholdersOf(message, where = '') {
  const found = new Map()
  const rank = { plain: 0, select: 1, number: 2, plural: 3 }
  const note = (name, kind, options) => {
    const prev = found.get(name)
    if (!prev) return found.set(name, { kind, options })
    if (prev.kind === 'select' || kind === 'select') {
      if (prev.kind !== kind) throw new Error(`${where}: {${name}} is used as a select and as something else`)
      return
    }
    if (rank[kind] > rank[prev.kind]) prev.kind = kind
  }
  const walk = (nodes) => {
    for (const n of nodes) {
      if (n.type === TYPE.argument) note(n.value, 'plain')
      else if (n.type === TYPE.number) {
        if (n.style) throw new Error(`${where}: {${n.value}, number, ${typeof n.style === 'string' ? n.style : 'style'}} is not supported by the ARB pipeline`)
        note(n.value, 'number')
      } else if (n.type === TYPE.plural) {
        if (n.pluralType === 'ordinal') throw new Error(`${where}: selectordinal is not supported`)
        if (n.offset) throw new Error(`${where}: plural offset is not supported`)
        note(n.value, 'plural')
      } else if (n.type === TYPE.select) note(n.value, 'select', Object.keys(n.options))
      else if (n.type === TYPE.date || n.type === TYPE.time) throw new Error(`${where}: date/time arguments are banned in messages`)
      if (n.options) for (const o of Object.values(n.options)) walk(o.value)
    }
  }
  walk(ast(message))
  return found
}

/** ARB `placeholders` object from the English message (the template). */
export function arbPlaceholders(message, where) {
  const out = {}
  for (const [name, info] of placeholdersOf(message, where)) {
    if (info.kind === 'plural') out[name] = { type: 'int', format: 'decimalPattern' }
    else if (info.kind === 'number') out[name] = { type: 'num', format: 'decimalPattern' }
    else out[name] = { type: 'String' }
  }
  return out
}

/** Dart type of each placeholder, in order: used by the equality-test generator. */
export const dartTypes = (message, where) => [...placeholdersOf(message, where)].map(([name, info]) => ({ name, ...info }))

const NO_ESCAPE = /['{}#]/

/**
 * Re-serialises the AST for gen_l10n. Numbers (`{x, number}` and the `#` of a plural, written `{count}`) print through the Dart number
 * format (Western digits, grouping); in Arabic each is wrapped in an LTR isolate, as the web formatter does.
 */
export function toArbMessage(message, lang, where = '') {
  const iso = (s) => (lang === 'ar' ? `${LRI}${s}${PDI}` : s)
  // gen_l10n has no `#`: inside a plural the count is written as its placeholder, `{count}`.
  const print = (nodes, plural = null) =>
    nodes
      .map((n) => {
        switch (n.type) {
          case TYPE.literal:
            if (NO_ESCAPE.test(n.value)) throw new Error(`${where}: literal ' { } # needs escaping, not supported: ${n.value}`)
            return n.value
          case TYPE.argument:
            return `{${n.value}}`
          case TYPE.number:
            return iso(`{${n.value}}`)
          case TYPE.pound:
            if (!plural) throw new Error(`${where}: # outside a plural`)
            return iso(`{${plural}}`)
          case TYPE.select:
          case TYPE.plural:
            return `{${n.value}, ${n.type === TYPE.select ? 'select' : 'plural'}, ${Object.entries(n.options)
              .map(([k, o]) => `${k}{${print(o.value, n.type === TYPE.plural ? n.value : plural)}}`)
              .join(' ')}}`
          default:
            throw new Error(`${where}: unsupported ICU node type ${n.type}`)
        }
      })
      .join('')
  return print(ast(message))
}

/** Plural categories each language needs (CLDR integer rules; `=0`, `=1`, `=2` count for zero, one, two). */
export const REQUIRED_PLURAL = { en: ['one', 'other'], ar: ['zero', 'one', 'two', 'few', 'many', 'other'] }

export function pluralGaps(message, lang) {
  const gaps = []
  const walk = (nodes) => {
    for (const n of nodes) {
      if (n.type === TYPE.plural) {
        const keys = Object.keys(n.options)
        const has = (c) => keys.includes(c) || keys.includes({ zero: '=0', one: '=1', two: '=2' }[c] ?? '#')
        for (const c of REQUIRED_PLURAL[lang]) {
          // English `=0` is optional and `one` is required; Arabic needs all six either as keyword or exact value.
          if (!has(c)) gaps.push(c)
        }
      }
      if (n.options) for (const o of Object.values(n.options)) walk(o.value)
    }
  }
  walk(ast(message))
  return gaps
}
