#!/usr/bin/env node
// Assembles packages/contracts/openapi/ghazal.v1.yaml (OpenAPI 3.1) from base.yaml, parameters.yaml, schemas/<tag>.yaml and paths/<tag>.yaml.
// Flow owners extend ONLY their own tag files; this script validates structure, expands the authoring sugar below and writes one file.
//
//   node tools/bundle-openapi.mjs            write ghazal.v1.yaml (and ghazal.v1.json next to it)
//   node tools/bundle-openapi.mjs --check    fail when the committed bundle is stale
//
// Authoring sugar (documented in packages/contracts/openapi/README.md):
//   schema files   `$ref: Name` (short) -> '#/components/schemas/Name'; `nullable: true` next to `type` or `$ref` -> OpenAPI 3.1 null form;
//                  `x-page-of: Name` -> cursor page { items: Name[], nextCursor }; enum ['@error-codes'] -> every code of base.yaml.
//   path files     the tag of every operation is the file name; per operation:
//                    x-access: guest | optional | (default: bearer required)       -> security
//                    x-idempotent / x-if-match / x-partner / x-paged                -> shared header and query parameters
//                    path: { id: Id }  query: { 'month!': IsoMonth, sort: SortName, areaIds: 'Id[]' }   -> parameters (key! = required)
//                    body: SchemaName | 'multipart'                                  -> request body (required)
//                    responses: { 200: Name | 'Name[]' | null (204) , 201: Name }    -> JSON responses; `x-errors: [CODE, ...]` -> problem responses
import fs from 'node:fs'
import path from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const dir = path.join(root, 'packages/contracts/openapi')

/** js-yaml is installed by pnpm as a transitive dependency; resolve it normally, then from the pnpm virtual store. */
function loadDep(name) {
  const req = createRequire(import.meta.url)
  for (const base of [root, path.join(root, 'node_modules/.pnpm/node_modules'), path.join(root, 'design')]) {
    try { return createRequire(path.join(base, 'noop.js'))(name) } catch { /* try next */ }
  }
  try { return req(name) } catch { /* fall through */ }
  throw new Error(`Cannot resolve ${name}. Run pnpm install (request: add ${name} to packages/contracts devDependencies).`)
}
const yaml = loadDep('js-yaml')

const errors = []
const fail = (msg) => errors.push(msg)
const readYaml = (file) => {
  try { return yaml.load(fs.readFileSync(file, 'utf8')) ?? {} } catch (e) {
    console.error(`bundle-openapi: cannot parse ${path.relative(root, file)}: ${String(e.message).split('\n')[0]}`)
    process.exit(1)
  }
}
const HTTP = ['get', 'put', 'post', 'delete', 'patch']

const base = readYaml(path.join(dir, 'base.yaml'))
const tagNames = base.tags.map((t) => t.name)
const errorCodes = base['x-error-codes']
delete base['x-error-codes']

// ------------------------------------------------------------------ schema sugar
const SCHEMA_REF = '#/components/schemas/'
const refOf = (name) => (name.startsWith('#') ? name : SCHEMA_REF + name)

function expandSchema(node, where) {
  if (Array.isArray(node)) return node.map((n) => expandSchema(n, where))
  if (node === null || typeof node !== 'object') return node
  const out = {}
  for (const [k, v] of Object.entries(node)) out[k] = k === 'enum' || k === 'required' || k === 'example' || k === 'examples' || k === 'default' ? v : expandSchema(v, where)
  if (typeof out.$ref === 'string') out.$ref = refOf(out.$ref)
  if (out['x-page-of']) {
    const name = out['x-page-of']
    return {
      type: 'object',
      description: out.description ?? `Cursor page of ${name}.`,
      required: ['items', 'nextCursor'],
      properties: {
        items: { type: 'array', items: { $ref: refOf(name) } },
        nextCursor: { type: ['string', 'null'], description: 'Opaque cursor of the next page; null on the last page.' },
      },
      'x-page-of': name,
    }
  }
  if (out.nullable === true) {
    delete out.nullable
    if (out.$ref) {
      const { $ref, ...rest } = out
      return { oneOf: [{ $ref }, { type: 'null' }], ...rest }
    }
    if (typeof out.type === 'string') out.type = [out.type, 'null']
    else if (out.oneOf) out.oneOf = [...out.oneOf, { type: 'null' }]
    else if (out.allOf) return { oneOf: [out, { type: 'null' }] }
    if (out.enum && !out.enum.includes(null)) out.enum = [...out.enum, null]
  } else if ('nullable' in out) delete out.nullable
  return out
}

// ------------------------------------------------------------------ components
const components = { ...base.components, schemas: {}, parameters: {}, responses: {} }
const params = readYaml(path.join(dir, 'parameters.yaml'))
for (const [k, v] of Object.entries(params)) components.parameters[k] = expandSchema(v)

const schemaFiles = ['common', ...tagNames].filter((t) => fs.existsSync(path.join(dir, 'schemas', `${t}.yaml`)))
for (const extra of fs.readdirSync(path.join(dir, 'schemas')).map((f) => f.replace(/\.yaml$/, ''))) if (!schemaFiles.includes(extra)) fail(`schemas/${extra}.yaml is not a known tag`)
const schemaOrigin = {}
for (const f of schemaFiles) {
  const doc = readYaml(path.join(dir, 'schemas', `${f}.yaml`))
  for (const [name, schema] of Object.entries(doc)) {
    if (components.schemas[name]) fail(`schema ${name} defined in ${schemaOrigin[name]} and ${f}`)
    schemaOrigin[name] = f
    const s = expandSchema(schema, `${f}:${name}`)
    if (name === 'ErrorCode') s.enum = Object.keys(errorCodes)
    s['x-tag'] = f
    components.schemas[name] = s
  }
}

// schema examples: packages/contracts/openapi/examples/<Schema>.json (written by scripts/gen-examples.mjs from the hero fixtures)
const exDir = path.join(dir, 'examples')
if (fs.existsSync(exDir)) {
  for (const f of fs.readdirSync(exDir).filter((x) => x.endsWith('.json')).sort()) {
    const name = f.replace(/\.json$/, '')
    if (!components.schemas[name]) { fail(`examples/${f}: no schema ${name}`); continue }
    components.schemas[name].example = JSON.parse(fs.readFileSync(path.join(exDir, f), 'utf8'))
  }
}

// problem responses by status
const STATUS_TEXT = { 400: 'Bad request', 401: 'Unauthorized', 403: 'Forbidden', 404: 'Not found', 409: 'Conflict', 410: 'Gone', 412: 'Precondition failed', 422: 'Unprocessable', 423: 'Locked', 426: 'Upgrade required', 429: 'Too many requests', 502: 'Bad gateway' }
const problemContent = { 'application/problem+json': { schema: { $ref: `${SCHEMA_REF}Problem` } } }
function problemResponse(status, codes) {
  const text = STATUS_TEXT[status] ?? 'Error'
  return { description: codes.length ? `${text}. Codes: ${codes.join(', ')}.` : `${text}.`, content: problemContent, ...(status === 429 ? { headers: { 'Retry-After': { schema: { type: 'integer' } } } } : {}) }
}
components.responses.Problem = { description: 'Unexpected error (problem+json).', content: problemContent }

// ------------------------------------------------------------------ operations
const paramRef = (n) => ({ $ref: `#/components/parameters/${n}` })

function schemaSugar(v) {
  if (v === null || v === undefined) return undefined
  if (Array.isArray(v)) return { type: 'string', enum: v }
  if (typeof v === 'object') return expandSchema(v)
  const arr = v.endsWith('[]')
  const name = arr ? v.slice(0, -2) : v
  const item = ['string', 'integer', 'number', 'boolean'].includes(name) ? { type: name } : { $ref: refOf(name) }
  return arr ? { type: 'array', items: item } : item
}

function buildParams(op) {
  const list = []
  for (const [key, v] of Object.entries(op.path ?? {})) list.push({ name: key, in: 'path', required: true, schema: schemaSugar(v) })
  for (const [key, v] of Object.entries(op.query ?? {})) {
    const required = key.endsWith('!')
    const schema = schemaSugar(v)
    list.push({ name: required ? key.slice(0, -1) : key, in: 'query', required, schema, ...(schema.type === 'array' ? { style: 'form', explode: true } : {}) })
  }
  if (op['x-paged']) list.push(paramRef('Cursor'), paramRef('Limit'))
  if (op['x-partner']) list.push(paramRef('XVenueId'), paramRef('XProviderId'))
  if (op['x-idempotent']) list.push(paramRef('IdempotencyKey'))
  if (op['x-if-match']) list.push(paramRef('IfMatch'))
  return list
}

function jsonResponse(v, description = 'OK') {
  if (v === null || v === undefined) return { description: 'No content' }
  if (typeof v === 'string') {
    if (v === 'pdf') return { description, content: { 'application/pdf': { schema: { type: 'string', format: 'binary' } } } }
    const s = schemaSugar(v)
    return { description, content: { 'application/json': { schema: s } } }
  }
  return v
}

function buildOperation(tag, pathKey, method, op) {
  const o = {}
  o.tags = [tag]
  if (!op.operationId) fail(`${method.toUpperCase()} ${pathKey}: operationId missing`)
  o.operationId = op.operationId
  o.summary = op.summary
  if (!op.summary) fail(`${op.operationId}: summary missing`)
  if (op.description) o.description = op.description
  const access = op['x-access'] ?? 'bearer'
  if (access === 'guest') o.security = []
  else if (access === 'optional') o.security = [{}, { bearerAuth: [] }]
  const p = buildParams(op)
  if (p.length) o.parameters = p
  if (op.body) {
    const multipart = op.body === 'multipart'
    o.requestBody = { required: true, content: { 'application/json': { schema: schemaSugar(op.body) } } }
    if (multipart) fail(`${op.operationId}: multipart bodies are not used (uploads go through upload sessions)`)
  }
  const responses = {}
  for (const [code, v] of Object.entries(op.responses ?? {})) responses[code] = jsonResponse(v, code === '201' ? 'Created' : code === '202' ? 'Accepted' : 'OK')
  if (!Object.keys(responses).some((c) => c.startsWith('2'))) fail(`${op.operationId}: no 2xx response`)
  // problem responses: declared codes grouped by status, plus the structural ones every operation can return
  const byStatus = {}
  for (const code of op['x-errors'] ?? []) {
    const e = errorCodes[code]
    if (!e) { fail(`${op.operationId}: unknown error code ${code}`); continue }
    ;(byStatus[e.status] ??= []).push(code)
  }
  const structural = []
  if (access !== 'guest') structural.push(401)
  if (op['x-partner'] || op['x-permissions']) structural.push(403)
  if (Object.keys(op.path ?? {}).length) structural.push(404)
  if (op.body || Object.keys(op.query ?? {}).length) structural.push(422)
  structural.push(429)
  for (const s of structural) byStatus[s] ??= []
  if (op['x-if-match']) byStatus[412] ??= []
  for (const s of Object.keys(byStatus).map(Number).sort((a, b) => a - b)) responses[s] = problemResponse(s, byStatus[s])
  responses.default = { $ref: '#/components/responses/Problem' }
  o.responses = responses
  for (const [k, v] of Object.entries(op)) {
    if (!k.startsWith('x-') || ['x-access', 'x-idempotent', 'x-if-match', 'x-partner', 'x-paged', 'x-errors'].includes(k)) continue
    o[k] = v
  }
  o['x-access'] = access
  const partner = tag.startsWith('partner-')
  o['x-roles'] = op['x-roles'] ?? (tag === 'auth' ? [] : partner ? ['partner'] : ['client'])
  if (op['x-idempotent']) o['x-idempotent'] = true
  if (op['x-if-match']) o['x-if-match'] = true
  if (op['x-paged']) o['x-paged'] = true
  if (op['x-errors']?.length) o['x-errors'] = op['x-errors']
  return o
}

const paths = {}
const opIds = new Set()
const opCountByTag = {}
for (const tag of tagNames) {
  const file = path.join(dir, 'paths', `${tag}.yaml`)
  if (!fs.existsSync(file)) { fail(`paths/${tag}.yaml missing`); continue }
  const doc = readYaml(file)
  for (const [pathKey, item] of Object.entries(doc)) {
    if (!pathKey.startsWith('/')) { fail(`${tag}: ${pathKey} is not a path`); continue }
    paths[pathKey] ??= {}
    for (const [method, op] of Object.entries(item)) {
      if (!HTTP.includes(method)) { fail(`${tag}: ${pathKey} has unknown key ${method}`); continue }
      if (paths[pathKey][method]) fail(`${method.toUpperCase()} ${pathKey} defined twice`)
      const built = buildOperation(tag, pathKey, method, op)
      if (opIds.has(built.operationId)) fail(`duplicate operationId ${built.operationId}`)
      opIds.add(built.operationId)
      opCountByTag[tag] = (opCountByTag[tag] ?? 0) + 1
      paths[pathKey][method] = built
    }
  }
}
for (const f of fs.readdirSync(path.join(dir, 'paths'))) if (!tagNames.includes(f.replace(/\.yaml$/, ''))) fail(`paths/${f} is not a known tag`)

// ------------------------------------------------------------------ reference check
const doc = {
  openapi: base.openapi,
  info: base.info,
  servers: base.servers,
  security: base.security,
  tags: base.tags,
  paths,
  components,
  'x-error-codes': errorCodes,
}
const text = JSON.stringify(doc)
for (const m of text.matchAll(/"\$ref":"#\/components\/(\w+)\/([\w.-]+)"/g)) {
  if (!components[m[1]]?.[m[2]]) fail(`unresolved $ref #/components/${m[1]}/${m[2]}`)
}
const used = new Set([...text.matchAll(/#\/components\/schemas\/([\w.-]+)/g)].map((m) => m[1]))
const unused = Object.keys(components.schemas).filter((n) => !used.has(n) && !['ErrorCode'].includes(n))
if (process.argv.includes('--unused') && unused.length) console.log('Unreferenced schemas:', unused.join(', '))

if (errors.length) {
  console.error(`bundle-openapi: ${errors.length} problem(s)\n  - ${errors.join('\n  - ')}`)
  process.exit(1)
}

const header = '# GENERATED by tools/bundle-openapi.mjs from base.yaml, parameters.yaml, schemas/*.yaml and paths/*.yaml. Never edit this file.\n'
const outYaml = header + yaml.dump(doc, { lineWidth: 140, noRefs: true, quotingType: '"' })
const outJson = JSON.stringify(doc, null, 2) + '\n'
const yamlFile = path.join(dir, 'ghazal.v1.yaml')
const jsonFile = path.join(dir, 'ghazal.v1.json')

if (process.argv.includes('--check')) {
  const stale = !fs.existsSync(yamlFile) || fs.readFileSync(yamlFile, 'utf8') !== outYaml || !fs.existsSync(jsonFile) || fs.readFileSync(jsonFile, 'utf8') !== outJson
  if (stale) { console.error('openapi bundle is stale: run node tools/bundle-openapi.mjs'); process.exit(1) }
  console.log('openapi bundle is current')
} else {
  fs.writeFileSync(yamlFile, outYaml)
  fs.writeFileSync(jsonFile, outJson)
  const total = Object.values(opCountByTag).reduce((a, b) => a + b, 0)
  console.log(`wrote ghazal.v1.yaml: ${total} operations, ${Object.keys(components.schemas).length} schemas`)
  console.log(tagNames.map((t) => `${t}=${opCountByTag[t] ?? 0}`).join(' '))
}
