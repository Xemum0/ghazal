#!/usr/bin/env node
// Headless Flutter screenshot of inventory screens (the verification channel of the Flutter build; plan section 6).
//   pnpm fshot --app client --screen CL-DISC-01 --lang ar [--w 360 390] [--state loading]
//   pnpm fshot --app provider --flow today --lang both
//   pnpm fshot --app client --all
// Flags: --app client|provider (required) | --screen ID[,ID...] | --flow <flow-id> | --all
//        --lang ar|en|both (default both) | --w <px>... (default 390) | --h <px> (844) | --scale <dpr> (2)
//        --text-scale <n> (1) | --state <name> | --persona <id> (guest, reem, new_client, hotel_manager ...; default by the persona rule) | --health (record framework errors in <label>.health.json instead of failing) | --story pending|approved|confirmed|redeemed|completed|declined|expired|lapsed|cancelled|counter_offer (the hero story point) | --params '{"venueId":"V05"}' (route params) | --out <dir> (default apps/<app>_app/build/shots)
// Runs `flutter test test/shots/shots_test.dart` through tools/with-slot.mjs (max 4 concurrent runs) and prints the PNG paths.
// Never starts a simulator or an emulator.
import { spawn } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const argv = process.argv.slice(2)
const flags = {}
for (let i = 0; i < argv.length; i++) {
  if (!argv[i].startsWith('--')) continue
  const k = argv[i].slice(2)
  const vals = []
  while (i + 1 < argv.length && !argv[i + 1].startsWith('--')) vals.push(argv[++i])
  flags[k] = vals.length ? vals : [true]
}
const one = (k, d) => (flags[k] && flags[k][0] !== true ? flags[k][0] : d)
const die = (m) => {
  console.error(`fshot: ${m}`)
  process.exit(2)
}

const appKey = one('app')
if (!['client', 'provider'].includes(appKey)) die('--app client|provider is required')
const appDir = path.join(ROOT, 'apps', `${appKey}_app`)
const registryFile = path.join(appDir, 'lib/app/screen_registry.dart')
if (!fs.existsSync(registryFile)) die(`missing ${path.relative(ROOT, registryFile)} (run node tools/gen-routes.mjs)`)
const registry = [...fs.readFileSync(registryFile, 'utf8').matchAll(/'([A-Z]{2}-[A-Z0-9]+-\d+)': ScreenEntry\(path: '([^']+)', kind: ScreenKind\.(\w+), flow: '([^']+)'/g)].map(
  (m) => ({ id: m[1], path: m[2], kind: m[3], flow: m[4] }),
)

let ids
if (flags.all) ids = 'all'
else if (flags.flow) {
  const sel = registry.filter((r) => r.flow === one('flow')).map((r) => r.id)
  if (!sel.length) die(`no screens in flow "${one('flow')}" (flows: ${[...new Set(registry.map((r) => r.flow))].join(', ')})`)
  ids = sel.join(',')
} else if (flags.screen) {
  ids = flags.screen.join(',').split(',').filter(Boolean).join(',')
  for (const id of ids.split(',')) if (!registry.some((r) => r.id === id)) die(`unknown screen id ${id} for ${appKey}`)
} else die('give --screen ID[,ID], --flow <flow-id> or --all')

const lang = one('lang', 'both')
const langs = lang === 'both' ? 'ar,en' : lang
if (!/^(ar|en)(,(ar|en))?$/.test(langs)) die('--lang ar|en|both')
const widths = flags.w ? flags.w.join(',') : '390'
const out = path.resolve(ROOT, one('out', path.join('apps', `${appKey}_app`, 'build', 'shots')))
const defines = [
  `SHOT_IDS=${ids}`,
  `SHOT_LANGS=${langs}`,
  `SHOT_W=${widths}`,
  `SHOT_H=${one('h', '844')}`,
  `SHOT_SCALE=${one('scale', '2')}`,
  `SHOT_TEXT_SCALE=${one('text-scale', '1')}`,
  `SHOT_STATE=${one('state', '')}`,
  `SHOT_PERSONA=${one('persona', '')}`,
  `SHOT_HEALTH=${flags.health ? '1' : ''}`,
  `SHOT_STORY=${one('story', '')}`,
  `SHOT_PARAMS=${flags.params ? flags.params.join(' ') : ''}`,
  `SHOT_OUT=${out}`,
]
const cmd = [
  path.join(ROOT, 'tools/with-slot.mjs'),
  'flutter-test',
  '--',
  'flutter',
  'test',
  'test/shots/shots_test.dart',
  ...defines.flatMap((d) => ['--dart-define', d]),
]
const child = spawn(process.execPath, cmd, { cwd: appDir, stdio: ['ignore', 'pipe', 'pipe'] })
const lines = []
const paths = []
let buf = ''
const onData = (d) => {
  buf += d.toString()
  let i
  while ((i = buf.indexOf('\n')) >= 0) {
    const line = buf.slice(0, i)
    buf = buf.slice(i + 1)
    lines.push(line)
    const m = line.match(/SHOT (.+\.png)\s*$/)
    if (m) paths.push(m[1])
  }
}
child.stdout.on('data', onData)
child.stderr.on('data', onData)
child.on('exit', (code) => {
  fs.mkdirSync(out, { recursive: true })
  const logFile = path.join(out, 'fshot.log')
  fs.writeFileSync(logFile, lines.join('\n'))
  if (code !== 0) {
    // The FIRST exception is the cause (the rest cascades): print it whole, then the tail of the run.
    const first = lines.findIndex((l) => /EXCEPTION CAUGHT|A Timer is still pending|Test failed|Failed assertion|Null check operator/.test(l))
    if (first >= 0) {
      console.error(`--- first problem (line ${first + 1} of ${logFile})`)
      console.error(lines.slice(Math.max(0, first - 1), first + 40).join('\n'))
    }
    console.error('--- end of the run')
    console.error(lines.filter((l) => !/^\s*\d+:\d+ \+\d+/.test(l) || /\[E\]|-\d+/.test(l)).slice(-30).join('\n'))
    console.error(`fshot: flutter test failed (exit ${code}); full log: ${path.relative(ROOT, logFile)}; add --health to keep going past framework errors and read <label>.health.json`)
    process.exit(code ?? 1)
  }
  if (!paths.length) console.log('fshot: no shot written (check ids)')
  for (const p of paths) console.log(p)
  console.log(`fshot: ${paths.length} PNG written to ${path.relative(ROOT, out)}`)
})
