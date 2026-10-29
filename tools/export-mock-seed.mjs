#!/usr/bin/env node
// Writes the seeds of the Dart mock API (packages/ghazal_mock_api/assets/seed/*.json) from the wire-mapped fixtures and the slim route table
// (assets/spec/routes.json) from the bundled OpenAPI file. The seeds ARE the output of fixtures-to-wire.mjs `wireSets()`: nothing is added or
// re-shaped except (a) the image convention (`id` + `baseUrl: asset://ghazal_mock_api/images/<imageId>` on every ImageRef), (b) the hero-story
// variants (same request in other states) move out of the Booking and Voucher collections into extra.json, because they share ids with the
// stored story rows, and (c) extra.json carries the raw non-schema fixtures the handlers need (config, personas, billing, hotel settings).
//
//   node tools/export-mock-seed.mjs            write
//   node tools/export-mock-seed.mjs --check    fail when the files on disk are stale
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { wireSets } from '../packages/contracts/openapi/scripts/fixtures-to-wire.mjs'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const fixtures = (n) => JSON.parse(fs.readFileSync(path.join(root, 'packages/contracts/fixtures', `${n}.json`), 'utf8'))
const spec = JSON.parse(fs.readFileSync(path.join(root, 'packages/contracts/openapi/ghazal.v1.json'), 'utf8'))
const outDir = path.join(root, 'packages/ghazal_mock_api/assets/seed')
const specDir = path.join(root, 'packages/ghazal_mock_api/assets/spec')
const check = process.argv.includes('--check')
const clone = (v) => JSON.parse(JSON.stringify(v))

export const IMAGE_BASE = 'asset://ghazal_mock_api/images/'
export const imageIdOf = (file) => path.basename(file).replace(/\.[a-z]+$/i, '')

// ------------------------------------------------------------------ images
const imageFiles = new Map() // imageId -> file
function decorateImages(v) {
  if (Array.isArray(v)) return v.forEach(decorateImages)
  if (!v || typeof v !== 'object') return
  if (typeof v.file === 'string' && /\.jpe?g$/i.test(v.file)) {
    const id = imageIdOf(v.file)
    if (imageFiles.has(id) && imageFiles.get(id) !== v.file) throw new Error(`image id clash ${id}`)
    imageFiles.set(id, v.file)
    if ('width' in v) { v.id = id; v.baseUrl = IMAGE_BASE + id }
  }
  for (const x of Object.values(v)) decorateImages(x)
}

// ------------------------------------------------------------------ seeds
const sets = wireSets()
const bookingsFx = fixtures('bookings')
const vouchersFx = fixtures('vouchers')
const variantNames = Object.keys(bookingsFx.heroVariants)

// wireSets() orders Booking as [stored..., one per hero variant (same ids as the story row), competingRequest] and Voucher as
// [stored..., competingVoucher, one per hero variant]: the variants move to extra.json, everything else stays a collection row.
const nB = bookingsFx.bookings.length
const nV = vouchersFx.vouchers.length + 1
const heroVariants = {}
variantNames.forEach((name, i) => {
  const { booking: _b, voucher: _v, ...rest } = bookingsFx.heroVariants[name]
  heroVariants[name] = { booking: sets.Booking[nB + i], voucher: sets.Voucher[nV + i], extra: rest }
})
const collections = { ...sets }
collections.Booking = [...sets.Booking.slice(0, nB), sets.Booking[sets.Booking.length - 1]]
collections.Voucher = sets.Voucher.slice(0, nV)

const meta = fixtures('meta')
const partners = fixtures('partners')
const hotel = fixtures('hotel')
const client = fixtures('client')
const people = fixtures('people')

const PASSWORD = 'Ghazal#2026'
const extra = {
  clock: { now: meta.now, today: meta.today, timezone: meta.timezone },
  meta: { ...meta, config: { ...meta.config } },
  story: meta.story,
  personas: [
    { key: 'guest', kind: 'guest', userId: null },
    { key: 'new_client', kind: 'client', userId: 'user-new-client', phone: '+96550000099', name: 'Nora Al-Mutairi', nameAr: 'نورة المطيري', sex: 'female', isNew: true },
    { key: 'reem', kind: 'client', userId: meta.clientUserId, phone: people.users.find((u) => u.id === meta.clientUserId).phone },
    {
      key: 'hotel_admin', kind: 'hotel', userId: 'user-khalid', partnerAccountId: 'partner-V01',
      roleLabel: { en: 'Admin (owner) · Aurelia Gulf Hotel', ar: 'المالك · فندق أوريليا الخليج' },
      phone: people.users.find((u) => u.id === 'user-khalid').phone, email: 'khalid@aurelia-gulf.example', password: PASSWORD,
    },
    // Round 2 (PA-ACC-07): two partner users who applied through the form, so the Partner app's "under review" and "rejected, edit and resubmit"
    // states can be shown without driving the form. The mock creates their user, account and application at reset (domain/applications.dart).
    {
      key: 'provider_applicant', kind: 'applicant', applicant: 'pending', userId: 'user-applicant-rawan', phone: '+96550000098', email: 'rawan@rawan-lens.example', password: PASSWORD,
      name: 'Rawan Al-Kandari', nameAr: 'روان الكندري', roleLabel: { en: 'Applicant · Rawan Lens (under review)', ar: 'مقدّمة طلب · روان لينز (قيد المراجعة)' },
      application: {
        name: { en: 'Rawan Lens', ar: 'روان لينز' }, categoryIds: ['photography'], otherCategoryNote: null, governorateId: 'hawalli', contactName: 'Rawan Al-Kandari',
        phone: '+96550000098', email: 'rawan@rawan-lens.example', description: 'Wedding photography for ladies-only halls, with a women-only team.', licenceRef: 'KW-55021',
      },
    },
    {
      key: 'provider_rejected', kind: 'applicant', applicant: 'rejected', userId: 'user-applicant-bader', phone: '+96550000097', email: 'bader@bader-decor.example', password: PASSWORD,
      name: 'Bader Al-Enezi', nameAr: 'بدر العنزي', roleLabel: { en: 'Applicant · Bader Decor (rejected)', ar: 'مقدّم طلب · بدر للديكور (مرفوض)' },
      application: {
        name: { en: 'Bader Decor', ar: 'بدر للديكور' }, categoryIds: ['decor'], otherCategoryNote: 'Lighting arches and entrance walkways', governorateId: 'farwaniya', contactName: 'Bader Al-Enezi',
        phone: '+96550000097', email: 'bader@bader-decor.example', description: 'Wedding decor, lighting arches and entrance walkways.', licenceRef: null,
      },
      rejection: { en: 'Please add your commercial licence reference and send the application again.', ar: 'يرجى إضافة رقم الترخيص التجاري وإعادة إرسال الطلب.' },
    },
    ...partners.personas.map((p) => ({
      key: p.kind === 'hotel' ? 'hotel_manager' : p.kind === 'hotel_non_major' ? 'hotel_non_major' : 'provider',
      kind: p.kind, userId: p.userId, partnerAccountId: p.partnerAccountId, roleLabel: p.roleLabel, phone: p.phone,
      email: { 'user-hind': 'hind@aurelia-gulf.example', 'user-lumi-manager': 'badriya@lumi-marina.example', 'user-zahra': 'zahra@zahra-floral.example' }[p.userId],
      password: PASSWORD,
    })),
  ],
  credentials: { otpCode: '123456', partnerPassword: PASSWORD, lockedOtp: '000000', expiredOtp: '111111' },
  hotel: {
    memberships: hotel.memberships, settings: hotel.settings, softDates: hotel.softDates, softDateOptOut: hotel.softDateOptOut,
    variants: hotel.variants,
  },
  partnerBilling: partners.billing,
  partnerPersonas: partners.personas,
  dayOverrides: fixtures('day-overrides'),
  client: { state: client.state, budgetVariants: client.budgetVariants, heroVariantNotifications: client.heroVariantNotifications, notificationPrefs: client.notificationPrefs, budget: client.budget },
  heroVariants,
  legal: {
    terms: { kind: 'terms', version: '2026-10', updatedAt: meta.now.replace('16:00:00', '09:00:00'), title: { en: 'Terms of use', ar: 'شروط الاستخدام' }, body: { en: 'Ghazal sells a KD 2 voucher. Prices, contracts and payments for the hall or service are agreed directly with the venue or provider, outside the app.', ar: 'تبيع غزل كوبونًا بقيمة ٢ د.ك. الأسعار والعقود والمدفوعات الخاصة بالقاعة أو الخدمة يتم الاتفاق عليها مباشرة مع القاعة أو المزوّد خارج التطبيق.' } },
    privacy: { kind: 'privacy', version: '2026-10', updatedAt: meta.now.replace('16:00:00', '09:00:00'), title: { en: 'Privacy policy', ar: 'سياسة الخصوصية' }, body: { en: 'We keep the details you give us to run your requests and visits, and nothing else. You can ask us to delete your account at any time.', ar: 'نحتفظ بالمعلومات التي تعطينا إياها لتشغيل طلباتك وزياراتك فقط. يمكنك طلب حذف حسابك في أي وقت.' } },
  },
  minAppVersion: '1.0.0',
  // Round 2 (CA-SVC-20, OQ-R2-04): the store page the Client app's note for service providers points to; configuration, a placeholder host.
  partnerAppUrl: 'https://partners.ghazal.example/app',
}

// ------------------------------------------------------------------ the slim route table (operations + the schemas request validation needs)
const C = spec.components.schemas
const closure = new Set()
const slimSchema = (x) => {
  if (Array.isArray(x)) return x.map(slimSchema)
  if (!x || typeof x !== 'object') return x
  const out = {}
  for (const [k, v] of Object.entries(x)) {
    if (['description', 'example', 'examples', 'x-tag', 'x-dart-name', 'default', 'x-abstract', 'x-page-of'].includes(k)) continue
    out[k] = k === 'properties' ? Object.fromEntries(Object.entries(v).map(([pk, pv]) => [pk, slimSchema(pv)])) : slimSchema(v)
  }
  return out
}
const visit = (x) => {
  if (!x || typeof x !== 'object') return
  if (Array.isArray(x)) return x.forEach(visit)
  if (x.$ref) {
    const n = x.$ref.split('/').pop()
    if (!closure.has(n)) { closure.add(n); visit(C[n]) }
    return
  }
  for (const v of Object.values(x)) visit(v)
}
const refName = (s) => (s?.$ref ? s.$ref.split('/').pop() : null)
const routes = []
for (const [p, item] of Object.entries(spec.paths)) {
  for (const [method, op] of Object.entries(item)) {
    if (!['get', 'post', 'put', 'patch', 'delete'].includes(method)) continue
    const params = []
    let idempotent = false
    let ifMatch = false
    for (let q of [...(item.parameters ?? []), ...(op.parameters ?? [])]) {
      if (q.$ref) {
        const n = q.$ref.split('/').pop()
        if (n === 'IdempotencyKey') { idempotent = true; continue }
        if (n === 'IfMatch') { ifMatch = true; continue }
        q = spec.components.parameters[n]
      }
      visit(q.schema)
      params.push({ name: q.name, in: q.in, required: !!q.required, schema: slimSchema(q.schema) })
    }
    const body = op.requestBody?.content?.['application/json']?.schema
    if (body) visit(body)
    const okStatus = Object.keys(op.responses).filter((k) => k[0] === '2')[0]
    const okContent = op.responses[okStatus]?.content ?? null
    routes.push({
      id: op.operationId, method: method.toUpperCase(), path: p, tag: op.tags[0], status: Number(okStatus),
      access: op.security && op.security.length === 0 ? (op['x-access'] === 'optional' ? 'optional' : 'guest') : op['x-access'] === 'optional' ? 'optional' : 'bearer',
      idempotent, ifMatch, params,
      body: body ? slimSchema(body) : null, bodyRequired: !!op.requestBody?.required,
      response: okContent ? (okContent['application/pdf'] ? 'pdf' : 'json') : 'none',
      responseSchema: refName(okContent?.['application/json']?.schema),
      errors: op['x-errors'] ?? [],
    })
  }
}
const specOut = { version: spec.info.version, errorCodes: spec['x-error-codes'], routes, schemas: Object.fromEntries([...closure].sort().map((n) => [n, slimSchema(C[n])])) }

// collection files are `<Schema>.seed.json`: a plain `Package.json` would be read as a package manifest by Node on case-insensitive file systems
// ------------------------------------------------------------------ write
const files = new Map()
const manifest = { version: 1, clock: meta.now, files: [], counts: {} }
for (const [name, rows] of Object.entries(collections)) {
  const copy = clone(rows)
  decorateImages(copy)
  files.set(`${name}.seed.json`, copy)
  manifest.files.push(`${name}.seed.json`)
  manifest.counts[name] = copy.length
}
const extraCopy = clone(extra)
decorateImages(extraCopy)
// heroVariants carry whole bookings/vouchers: their images (none today) were decorated above as part of extra
files.set('extra.json', extraCopy)
manifest.files.push('extra.json')
manifest.images = Object.fromEntries([...imageFiles.entries()].sort())
manifest.imageBase = IMAGE_BASE
files.set('manifest.json', manifest)

const stringify = (v) => JSON.stringify(v) + '\n'
let stale = 0
const write = (dir, name, value) => {
  const file = path.join(dir, name)
  const text = stringify(value)
  if (check) {
    if (!fs.existsSync(file) || fs.readFileSync(file, 'utf8') !== text) { stale += 1; console.error(`stale: ${path.relative(root, file)}`) }
    return
  }
  fs.mkdirSync(dir, { recursive: true })
  fs.writeFileSync(file, text)
}
for (const [name, value] of files) write(outDir, name, value)
write(specDir, 'routes.json', specOut)

if (!check) {
  // remove seed files of collections that no longer exist
  for (const f of fs.readdirSync(outDir)) if (!files.has(f)) fs.rmSync(path.join(outDir, f))
}
const bytes = [...files.values()].reduce((s, v) => s + stringify(v).length, 0)
console.log(`${check ? 'checked' : 'wrote'} ${files.size} seed files (${(bytes / 1e6).toFixed(2)} MB), ${routes.length} routes, ${Object.keys(specOut.schemas).length} request schemas, ${imageFiles.size} images`)
if (check && stale) process.exit(1)
