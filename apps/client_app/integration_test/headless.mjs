#!/usr/bin/env node
// Runs the journeys of this app HEADLESS on the host test device of `flutter test` (no simulator, no emulator, no `flutter run`).
//
//   node apps/client_app/integration_test/headless.mjs                 # every journey of this app, one after the other
//   node apps/client_app/integration_test/headless.mjs j1 j5           # by name prefix (j1_first_run_test.dart, j5_tour_test.dart)
//   node apps/client_app/integration_test/headless.mjs j1 --lang ar    # the same journey in Arabic (JOURNEY_LANG; J5 always runs both)
//   node apps/client_app/integration_test/headless.mjs j5 --semantics  # with the semantics tree on, as for a VoiceOver user (--trace: print screen changes)
//
// Why a wrapper: with this Flutter (3.47.5) `flutter test integration_test/<file>` ALWAYS needs a device (it fails with "No devices are
// connected" on a Mac without a simulator): the tool treats every file under <app>/integration_test/ as a device test. The same file
// runs on the host when it is started from a path outside that folder, so this script writes a two-line entry point per journey into
// build/journeys/ (git-ignored) that calls the journey's main(), and runs it through the shared slot semaphore (a hung run is killed
// after 10 silent minutes and releases its slot). On a simulator run the files directly, see docs/engineering/flutter-dev.md "Journeys".
import { spawnSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const app = path.dirname(here)
const root = path.resolve(app, '../..')
const args = process.argv.slice(2)
const langAt = args.indexOf('--lang')
const lang = langAt >= 0 ? args.splice(langAt, 2)[1] : null
const trace = args.includes('--trace')
const want = args.filter((a) => !a.startsWith('-'))

const all = fs
  .readdirSync(here)
  .filter((f) => /^j\d+_.*_test\.dart$/.test(f))
  .sort()
const picked = want.length ? all.filter((f) => want.some((w) => f.startsWith(w))) : all
if (!picked.length) {
  console.error(`no journey matches ${want.join(', ') || '(none)'}; available: ${all.join(', ')}`)
  process.exit(2)
}

const out = path.join(app, 'build', 'journeys')
fs.mkdirSync(out, { recursive: true })
let failed = 0
for (const file of picked) {
  fs.writeFileSync(path.join(out, file), `import '../../integration_test/${file}' as journey;\n\nvoid main() => journey.main();\n`)
  const cmd = [
    path.join(root, 'tools/with-slot.mjs'), 'flutter-test', '--idle-min', '10', '--run-min', '25', '--',
    'flutter', 'test', `build/journeys/${file}`,
    '--dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false',
    ...(lang ? [`--dart-define=JOURNEY_LANG=${lang}`] : []),
    ...(args.includes('--semantics') ? ['--dart-define=JOURNEY_SEMANTICS=true'] : []),
    ...(trace ? ['--dart-define=JOURNEY_TRACE=true'] : []),
  ]
  console.log(`\n=== ${file}${lang ? ` (${lang})` : ''} ===`)
  const r = spawnSync('node', cmd, { cwd: app, stdio: 'inherit' })
  if (r.status !== 0) failed++
}
console.log(failed ? `\n${failed} of ${picked.length} journeys FAILED` : `\nall ${picked.length} journeys passed`)
process.exit(failed ? 1 : 0)
