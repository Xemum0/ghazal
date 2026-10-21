#!/usr/bin/env node
// Runs `flutter test` in every workspace member that has a test/ folder, concurrently, each run holding a with-slot slot
// (max 4 at once, so parallel agents and this script never overload the machine). Prints one summary line per member.
//   node tools/flutter-test-all.mjs [member-dir ...]      e.g. apps/client_app packages/ghazal_ui
import { spawn } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const members = process.argv.slice(2).length
  ? process.argv.slice(2)
  : [...fs.readdirSync(path.join(ROOT, 'apps')).map((d) => `apps/${d}`), ...fs.readdirSync(path.join(ROOT, 'packages')).filter((d) => d.startsWith('ghazal_')).map((d) => `packages/${d}`)]
// A test/ folder counts only when it holds a *_test.dart file (a freshly scaffolded package must not fail the gate).
const hasTests = (dir) => fs.readdirSync(dir, { withFileTypes: true }).some((e) => (e.isDirectory() ? hasTests(path.join(dir, e.name)) : e.name.endsWith('_test.dart')))
const withTests = members.filter((m) => fs.existsSync(path.join(ROOT, m, 'pubspec.yaml')) && fs.existsSync(path.join(ROOT, m, 'test')) && hasTests(path.join(ROOT, m, 'test')))

const run = (m) =>
  new Promise((resolve) => {
    const out = []
    const child = spawn(process.execPath, [path.join(ROOT, 'tools/with-slot.mjs'), 'flutter-test', '--', 'flutter', 'test', '--reporter', 'expanded'], {
      cwd: path.join(ROOT, m),
      stdio: ['ignore', 'pipe', 'pipe'],
    })
    child.stdout.on('data', (d) => out.push(d.toString()))
    child.stderr.on('data', (d) => out.push(d.toString()))
    child.on('exit', (code) => {
      const text = out.join('')
      const tail = text.trim().split('\n').slice(-1)[0] ?? ''
      resolve({ m, code: code ?? 1, text, tail })
    })
  })

const results = await Promise.all(withTests.map(run))
let failed = 0
for (const r of results) {
  if (r.code !== 0) {
    failed++
    console.log(`\n--- ${r.m}: FAILED ---\n${r.text.split('\n').slice(-120).join('\n')}`)
  }
}
for (const r of results) console.log(`${r.code === 0 ? 'ok    ' : 'FAIL  '}${r.m}  ${r.tail}`)
if (!withTests.length) console.log('flutter-test-all: no member has a test/ folder')
process.exit(failed ? 1 : 0)
