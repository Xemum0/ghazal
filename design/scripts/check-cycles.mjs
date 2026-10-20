#!/usr/bin/env node
// Fails (exit 1) when design/src has a runtime import cycle (Tarjan SCC over value imports; `import type` is ignored).
// The system must never import the Studio shell's barrel: use the leaf modules shell/lang, shell/frame, shell/router.
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../src')
const walk = (d, o = []) => {
  for (const f of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, f.name)
    if (f.isDirectory()) walk(p, o)
    else o.push(p)
  }
  return o
}
const files = walk(root).filter((f) => /\.tsx?$/.test(f))
const set = new Set(files)
const resolve = (from, spec) => {
  if (!spec.startsWith('.')) return null
  const b = path.resolve(path.dirname(from), spec)
  for (const c of [b, `${b}.ts`, `${b}.tsx`, `${b}/index.ts`, `${b}/index.tsx`]) if (set.has(c)) return c
  return null
}
const graph = new Map()
for (const f of files) {
  const s = fs.readFileSync(f, 'utf8')
  const deps = new Set()
  for (const m of s.matchAll(/^\s*(?:import|export)\s[^'"]*?from\s+['"]([^'"]+)['"]/gm)) {
    if (/^\s*(?:import|export) type/.test(m[0])) continue
    const r = resolve(f, m[1])
    if (r) deps.add(r)
  }
  for (const m of s.matchAll(/^\s*import\s+['"]([^'"]+)['"]/gm)) {
    const r = resolve(f, m[1])
    if (r) deps.add(r)
  }
  graph.set(f, [...deps])
}
let idx = 0
const stack = []
const on = new Set()
const index = new Map()
const low = new Map()
const cycles = []
function visit(v) {
  index.set(v, idx)
  low.set(v, idx)
  idx++
  stack.push(v)
  on.add(v)
  for (const w of graph.get(v) ?? []) {
    if (!index.has(w)) {
      visit(w)
      low.set(v, Math.min(low.get(v), low.get(w)))
    } else if (on.has(w)) low.set(v, Math.min(low.get(v), index.get(w)))
  }
  if (low.get(v) === index.get(v)) {
    const c = []
    let w
    do {
      w = stack.pop()
      on.delete(w)
      c.push(w)
    } while (w !== v)
    if (c.length > 1) cycles.push(c)
  }
}
for (const f of files) if (!index.has(f)) visit(f)
if (cycles.length) {
  console.error(`import cycles: ${cycles.length}`)
  for (const c of cycles) console.error(` ${c.length} modules: ${c.slice(0, 8).map((f) => path.relative(root, f)).join(', ')}`)
  process.exit(1)
}
console.log(`no import cycles (${files.length} modules)`)
