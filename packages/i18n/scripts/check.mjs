#!/usr/bin/env node
// pnpm i18n:check [--write] [--quiet]
//   Fails when: a key exists in one language only; ICU syntax is invalid; placeholder sets differ between languages;
//   a plural lacks a required category; a string holds a raw colour value or hard-coded left/right wording; an Arabic
//   string holds Latin letters (except the allowed brand tokens; KD and KWD never) or an English string holds Arabic;
//   banned phrases, exclamation marks, emoji, literal digits in prose, Latin punctuation in Arabic.
//   --write regenerates src/generated/namespaces.ts (the namespace list and the English-derived key types).
// Rules and their sources: scripts/lib/check-lib.mjs. Per-key exceptions: messages/allow.json.
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { checkAll } from './lib/check-lib.mjs'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const messagesDir = join(root, 'messages')
const generatedPath = join(root, 'src', 'generated', 'namespaces.ts')
const args = new Set(process.argv.slice(2))

const run = () =>
  checkAll({
    messagesDir,
    generatedFile: 'src/generated/namespaces.ts',
    readGenerated: () => (existsSync(generatedPath) ? readFileSync(generatedPath, 'utf8') : null),
  })

let result = run()
if (args.has('--write')) {
  mkdirSync(dirname(generatedPath), { recursive: true })
  writeFileSync(generatedPath, result.expectedGenerated)
  console.log(`[i18n:check] wrote src/generated/namespaces.ts (${result.namespaces.join(', ')})`)
  result = run()
}

const fmt = (f) => `  ${f.level === 'error' ? 'error' : 'warn '}  ${f.file}${f.key ? `  ${f.key}` : ''}\n         ${f.message}  [${f.rule}]`
if (!args.has('--quiet')) {
  for (const w of result.warnings) console.log(fmt(w))
}
for (const e of result.errors) console.log(fmt(e))

const { namespaces, keys } = result.stats
if (result.errors.length) {
  console.log(`\n[i18n:check] FAILED: ${result.errors.length} error(s), ${result.warnings.length} warning(s) across ${namespaces} namespace(s), ${keys} key(s).`)
  process.exit(1)
}
console.log(`[i18n:check] ok: ${namespaces} namespace(s), ${keys} key(s) in en and ar, ${result.warnings.length} warning(s).`)
