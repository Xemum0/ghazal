#!/usr/bin/env node
// Counting semaphore for heavy runs (plan section 5): at most N holders of a named slot pool at a time.
//   node tools/with-slot.mjs <name> [--max N] [--timeout-min M] [--idle-min I] [--run-min R] -- <command...>
// Slots are atomic lock directories under tools/.locks/<name>/slot-<i> (mkdir is atomic) holding the owner pid.
// A lock whose pid is gone (crash, kill -9) is stale and is removed by the next waiter. Default N is 4 (env GZ_SLOTS overrides).
// Exit code = the command's exit code. Never kills anything it did not start. --timeout-min is the longest WAIT for a slot (default 60);
// the run itself is guarded too, because a hung `flutter test` (real IO inside fake async, a pending timer) holds a slot forever and no
// agent may kill it: --idle-min (default 6) kills the command's process group when it prints nothing for that long, --run-min (default 45;
// a full sweep passes more) when it runs longer; the slot is released and the exit code is 124.
import { spawn } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = path.dirname(fileURLToPath(import.meta.url))
const argv = process.argv.slice(2)
const sep = argv.indexOf('--')
if (sep < 1 || sep === argv.length - 1) {
  console.error('usage: node tools/with-slot.mjs <name> [--max N] [--timeout-min M] -- <command...>')
  process.exit(2)
}
const head = argv.slice(0, sep)
const cmd = argv.slice(sep + 1)
const name = head[0].replace(/[^a-zA-Z0-9_-]/g, '_')
const opt = (flag, dflt) => (head.includes(flag) ? Number(head[head.indexOf(flag) + 1]) : dflt)
const max = opt('--max', Number(process.env.GZ_SLOTS ?? 4))
const timeoutMs = opt('--timeout-min', 60) * 60_000
const idleMs = opt('--idle-min', Number(process.env.GZ_SLOT_IDLE_MIN ?? 6)) * 60_000
const runMs = opt('--run-min', Number(process.env.GZ_SLOT_RUN_MIN ?? 45)) * 60_000
const dir = path.join(HERE, '.locks', name)
fs.mkdirSync(dir, { recursive: true })

const alive = (pid) => {
  try {
    process.kill(pid, 0)
    return true
  } catch (e) {
    return e.code === 'EPERM'
  }
}

function tryAcquire() {
  for (let i = 0; i < max; i++) {
    const slot = path.join(dir, `slot-${i}`)
    try {
      fs.mkdirSync(slot)
      fs.writeFileSync(path.join(slot, 'pid'), String(process.pid))
      return slot
    } catch (e) {
      if (e.code !== 'EEXIST') throw e
      let pid = NaN
      try {
        pid = Number(fs.readFileSync(path.join(slot, 'pid'), 'utf8'))
      } catch {
        // pid file not written yet by a racing owner: treat as held, unless the dir is old
        try {
          if (Date.now() - fs.statSync(slot).mtimeMs > 10_000) pid = -1
        } catch {
          continue
        }
      }
      if (pid === -1 || (Number.isFinite(pid) && !alive(pid))) {
        fs.rmSync(slot, { recursive: true, force: true })
        i-- // retry this slot at once
      }
    }
  }
  return null
}

const started = Date.now()
let slot = tryAcquire()
let announced = false
while (!slot) {
  if (!announced) {
    console.error(`[with-slot ${name}] all ${max} slots busy, waiting...`)
    announced = true
  }
  if (Date.now() - started > timeoutMs) {
    console.error(`[with-slot ${name}] timed out after ${timeoutMs / 60_000} min`)
    process.exit(75)
  }
  await new Promise((r) => setTimeout(r, 300))
  slot = tryAcquire()
}

let released = false
const release = () => {
  if (released) return
  released = true
  fs.rmSync(slot, { recursive: true, force: true })
}
process.on('exit', release)
const child = spawn(cmd[0], cmd.slice(1), { stdio: ['inherit', 'pipe', 'pipe'], detached: true })
let lastOutput = Date.now()
const runStarted = Date.now()
child.stdout.on('data', (d) => {
  lastOutput = Date.now()
  process.stdout.write(d)
})
child.stderr.on('data', (d) => {
  lastOutput = Date.now()
  process.stderr.write(d)
})
let timedOut = false
const killGroup = (sig) => {
  try {
    process.kill(-child.pid, sig) // the group this run started, nothing else
  } catch {
    /* already gone */
  }
}
const watchdog = setInterval(() => {
  const idle = Date.now() - lastOutput
  const ran = Date.now() - runStarted
  if (idle > idleMs || ran > runMs) {
    timedOut = true
    console.error(`[with-slot ${name}] ${idle > idleMs ? `no output for ${Math.round(idle / 60_000)} min` : `running for ${Math.round(ran / 60_000)} min`}: killing the hung run and freeing the slot`)
    killGroup('SIGTERM')
    setTimeout(() => killGroup('SIGKILL'), 5000).unref()
    clearInterval(watchdog)
  }
}, 10_000)
for (const sig of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
  process.on(sig, () => {
    killGroup(sig)
  })
}
child.on('error', (e) => {
  console.error(`[with-slot ${name}] cannot start ${cmd[0]}: ${e.message}`)
  release()
  process.exit(127)
})
child.on('exit', (code, signal) => {
  clearInterval(watchdog)
  release()
  process.exit(timedOut ? 124 : (code ?? (signal ? 128 : 1)))
})
