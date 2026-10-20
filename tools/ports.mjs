#!/usr/bin/env node
// Ghazal port + identity tool (ADR 0021 D8). The ONLY way to produce or verify a local URL.
//
//   node tools/ports.mjs url   <service> [--slot N]    print the URL (computed, never typed)
//   node tools/ports.mjs check <service> [--slot N]    GET /__gz; exit 0 only if it is OUR server
//   node tools/ports.mjs who   <service> [--slot N]    print what owns the port (PID + command)
//   node tools/ports.mjs list  [--slot N]              every service, its port and status
//   add --json for machine-readable output.
//
// port = 4700 + 10 * slot + offset. Slot 0 is the main checkout; slots 1-9 are agent worktrees.
// Exit codes: 0 ours and healthy | 1 port owned by something else (PID + command printed) | 2 nothing listening | 64 usage.
// Also importable: computePort, rootHash, identity, checkService, portOwner, serviceUrl.
import { createHash } from 'node:crypto'
import { execFileSync } from 'node:child_process'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const BASE = 4700
export const HOST = '127.0.0.1'
export const SERVICES = {
  design: 0,
  api: 1,
  'venue-dashboard': 2,
  'admin-dashboard': 3,
  prism: 4,
  realtime: 5,
  'flutter-web': 6,
  'pdf-renderer': 7,
}

export const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')
/** Stable id of this checkout; a different worktree or clone answers with a different hash. */
export const rootHash = createHash('sha1').update(repoRoot).digest('hex').slice(0, 8)

export function resolveSlot(slot) {
  const raw = slot ?? process.env.GZ_SLOT ?? '0'
  const n = Number(raw)
  if (!Number.isInteger(n) || n < 0 || n > 9) throw new Error(`invalid slot "${raw}" (0-9)`)
  return n
}

export function computePort(service, slot) {
  if (!(service in SERVICES)) throw new Error(`unknown service "${service}" (${Object.keys(SERVICES).join(', ')})`)
  return BASE + 10 * resolveSlot(slot) + SERVICES[service]
}

export const serviceUrl = (service, slot) => `http://${HOST}:${computePort(service, slot)}/`

/** What owns a TCP port: { pid, command } or null. macOS and Linux (lsof). */
export function portOwner(port) {
  try {
    const out = execFileSync('lsof', ['-nP', `-iTCP:${port}`, '-sTCP:LISTEN', '-Fp'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })
    const pid = out.split('\n').find(l => l.startsWith('p'))?.slice(1)
    if (!pid) return null
    let command = ''
    try { command = execFileSync('ps', ['-p', pid, '-o', 'command='], { encoding: 'utf8' }).trim() } catch { /* gone */ }
    return { pid: Number(pid), command }
  } catch {
    return null
  }
}

/** GET /__gz. Returns { state: 'down' } | { state: 'foreign', reason } | { state: 'ok', identity }. */
export async function identity(url, timeoutMs = 1500) {
  const base = new URL(url)
  let res
  try {
    res = await fetch(new URL('/__gz', base), { signal: AbortSignal.timeout(timeoutMs), headers: { accept: 'application/json' } })
  } catch (e) {
    const code = e?.cause?.code ?? e?.code
    if (code === 'ECONNREFUSED' || code === 'ECONNRESET' || code === 'EHOSTUNREACH') return { state: 'down' }
    if (e?.name === 'TimeoutError') return { state: 'foreign', reason: `no answer within ${timeoutMs} ms (port is open but not responding)` }
    return { state: 'foreign', reason: String(e?.message ?? e) }
  }
  let body = null
  try { body = await res.json() } catch { /* not json */ }
  if (!body || typeof body.app !== 'string' || !('rootHash' in body)) {
    return { state: 'foreign', reason: `GET /__gz returned HTTP ${res.status} and no Ghazal identity` }
  }
  return { state: 'ok', identity: body }
}

/** Full verification of a service on a slot. */
export async function checkService(service, slot) {
  const s = resolveSlot(slot)
  const port = computePort(service, s)
  const url = serviceUrl(service, s)
  const r = await identity(url)
  const base = { service, slot: s, port, url }
  if (r.state === 'down') return { ...base, status: 'down', message: `nothing is listening on ${HOST}:${port}` }
  if (r.state === 'foreign') return { ...base, status: 'foreign', message: r.reason, owner: portOwner(port) }
  const id = r.identity
  const problems = []
  if (id.app !== service) problems.push(`app is "${id.app}", expected "${service}"`)
  if (id.slot !== s) problems.push(`slot is ${id.slot}, expected ${s}`)
  if (id.rootHash !== rootHash) problems.push(`rootHash ${id.rootHash} is another checkout (this one is ${rootHash})`)
  if (problems.length) return { ...base, status: 'foreign', message: problems.join('; '), identity: id, owner: portOwner(port) }
  return { ...base, status: 'ok', message: 'ours', identity: id }
}

function printResult(r) {
  if (r.status === 'ok') {
    console.log(`ok     ${r.service} slot ${r.slot} ${r.url} (started ${r.identity.startedAt})`)
    return
  }
  if (r.status === 'down') {
    console.log(`down   ${r.service} slot ${r.slot} ${r.url}: ${r.message}`)
    return
  }
  console.error(`MISMATCH ${r.service} slot ${r.slot} ${r.url}: ${r.message}`)
  if (r.owner) console.error(`  port ${r.port} is owned by PID ${r.owner.pid}: ${r.owner.command}`)
  else console.error(`  port ${r.port} owner could not be determined (lsof found nothing)`)
  console.error('  Do not kill it unless you started it. Report the PID and command; Ghazal never uses a tool default port.')
}

async function main() {
  const argv = process.argv.slice(2)
  const json = argv.includes('--json')
  const si = argv.indexOf('--slot')
  const slot = si > -1 ? argv[si + 1] : undefined
  const pos = argv.filter((a, i) => !a.startsWith('--') && !(si > -1 && i === si + 1))
  const [cmd, service] = pos
  const usage = () => {
    console.error('usage: node tools/ports.mjs url|check|who <service> [--slot N] [--json] | list [--slot N]\nservices: ' + Object.keys(SERVICES).join(', '))
    process.exit(64)
  }
  try {
    if (cmd === 'url' && service) {
      console.log(json ? JSON.stringify({ service, slot: resolveSlot(slot), port: computePort(service, slot), url: serviceUrl(service, slot) }) : serviceUrl(service, slot))
    } else if (cmd === 'check' && service) {
      const r = await checkService(service, slot)
      if (json) console.log(JSON.stringify(r))
      else printResult(r)
      process.exit(r.status === 'ok' ? 0 : r.status === 'down' ? 2 : 1)
    } else if (cmd === 'who' && service) {
      const port = computePort(service, slot)
      const owner = portOwner(port)
      const r = await identity(serviceUrl(service, slot))
      if (json) console.log(JSON.stringify({ port, owner, identity: r }))
      else {
        console.log(owner ? `port ${port}: PID ${owner.pid}: ${owner.command}` : `port ${port}: nothing listening`)
        if (r.state === 'ok') console.log('identity: ' + JSON.stringify(r.identity))
        else if (r.state === 'foreign') console.log('identity: not Ghazal (' + r.reason + ')')
      }
    } else if (cmd === 'list') {
      for (const name of Object.keys(SERVICES)) {
        const r = await checkService(name, slot)
        if (json) console.log(JSON.stringify(r))
        else console.log(`${name.padEnd(16)} ${String(r.port).padEnd(5)} ${r.status}${r.status === 'foreign' ? ': ' + r.message : ''}`)
      }
    } else usage()
  } catch (e) {
    console.error(String(e?.message ?? e))
    process.exit(64)
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main()
