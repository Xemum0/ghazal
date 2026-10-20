#!/usr/bin/env node
// Contract test of the Dart mock: starts the standalone server (`dart run ghazal_mock_api:serve`) on a free port of the reserved block, then calls
// EVERY operation of packages/contracts/openapi/ghazal.v1.json in a scripted story (guest, new client, Reem, hotel admin and manager, provider) with
// request bodies that are validated against the request schemas first, and validates every response against the bundled spec with ajv: success
// bodies against the response schema, error bodies against `Problem`. Fails on any status or shape mismatch and prints coverage (operations hit / 217).
//
//   node tools/contract-test.mjs                  start the server, run, stop it
//   node tools/contract-test.mjs --url http://127.0.0.1:4701   run against a server that is already up
//   node tools/contract-test.mjs --verbose        print every call
import fs from 'node:fs'
import path from 'node:path'
import { spawn } from 'node:child_process'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import { computePort, portOwner } from './ports.mjs'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const spec = JSON.parse(fs.readFileSync(path.join(root, 'packages/contracts/openapi/ghazal.v1.json'), 'utf8'))
const verbose = process.argv.includes('--verbose')
const urlArg = process.argv.includes('--url') ? process.argv[process.argv.indexOf('--url') + 1] : null

function loadDep(name) {
  for (const base of [root, path.join(root, 'node_modules/.pnpm/node_modules'), path.join(root, 'design')]) {
    try { return createRequire(path.join(base, 'noop.js'))(name) } catch { /* next */ }
  }
  throw new Error(`Cannot resolve ${name}`)
}
const Ajv2020 = loadDep('ajv/dist/2020').default ?? loadDep('ajv/dist/2020')
const ajv = new Ajv2020({ strict: false, validateFormats: false, allErrors: true, discriminator: false })
ajv.addSchema({ $id: 'ghazal', components: spec.components })
const absolutize = (schema) => JSON.parse(JSON.stringify(schema).replaceAll('"#/components/schemas/', '"ghazal#/components/schemas/'))
const validators = new Map()
const validatorFor = (schema) => {
  const key = JSON.stringify(schema)
  if (!validators.has(key)) validators.set(key, ajv.compile(absolutize(schema)))
  return validators.get(key)
}
const problemValidator = ajv.getSchema('ghazal#/components/schemas/Problem')

// ---------------------------------------------------------------- operations index
const ops = new Map()
for (const [p, item] of Object.entries(spec.paths)) {
  for (const [method, op] of Object.entries(item)) {
    if (!['get', 'post', 'put', 'patch', 'delete'].includes(method)) continue
    const ok = Object.keys(op.responses).find((k) => k[0] === '2')
    ops.set(op.operationId, {
      id: op.operationId, method: method.toUpperCase(), path: p, op, tag: op.tags[0], status: Number(ok),
      response: op.responses[ok]?.content?.['application/json']?.schema ?? null,
      pdf: !!op.responses[ok]?.content?.['application/pdf'],
      body: op.requestBody?.content?.['application/json']?.schema ?? null,
      idempotent: JSON.stringify(op.parameters ?? []).includes('IdempotencyKey'),
    })
  }
}

// ---------------------------------------------------------------- server
let base, child
async function startServer() {
  if (urlArg) { base = urlArg.replace(/\/$/, ''); return }
  let port = null
  for (let slot = Number(process.env.GZ_SLOT ?? 0); slot <= 9 && !port; slot += 1) {
    const candidate = computePort('api', slot)
    if (!portOwner(candidate)) port = candidate
  }
  if (!port) throw new Error('no free port in the Ghazal block for the mock')
  child = spawn('dart', ['run', 'ghazal_mock_api:serve', '--port', String(port)], { cwd: path.join(root, 'packages/ghazal_mock_api'), stdio: ['ignore', 'pipe', 'pipe'] })
  let out = ''
  child.stdout.on('data', (d) => { out += d })
  child.stderr.on('data', (d) => { out += d })
  base = `http://127.0.0.1:${port}`
  for (let i = 0; i < 120; i += 1) {
    await new Promise((r) => setTimeout(r, 500))
    try { const r = await fetch(`${base}/__gz`); if (r.ok) return } catch { /* not yet */ }
    if (child.exitCode !== null) throw new Error(`the mock server exited early:\n${out}`)
  }
  throw new Error(`the mock server did not start:\n${out}`)
}
async function stopServer() {
  if (urlArg) return
  try { await fetch(`${base}/__mock/shutdown`, { method: 'POST' }) } catch { /* gone */ }
  await new Promise((r) => setTimeout(r, 300))
  if (child && child.exitCode === null) child.kill('SIGINT')
}

// ---------------------------------------------------------------- calls
const hits = new Set()
const failures = []
const tokens = {}
let calls = 0
const fail = (where, msg) => { failures.push(`${where}: ${msg}`); console.error(`FAIL ${where}: ${msg}`) }
const uuid = () => crypto.randomUUID()

async function control(p, body) {
  const r = await fetch(`${base}/__mock/${p}`, { method: body === undefined ? 'GET' : 'POST', headers: { 'content-type': 'application/json' }, body: body === undefined ? undefined : JSON.stringify(body) })
  return r.json()
}
const sessionOf = async (persona) => { const s = await control('session', { persona }); return s.accessToken }

/**
 * One call of the story. o: as (token label), venue / provider (partner context), path (params), query, body, ifMatch, headers, expect (status),
 * count (false: do not count as coverage). Returns { status, data, headers }.
 */
async function call(opId, o = {}) {
  const r = ops.get(opId)
  if (!r) throw new Error(`unknown operation ${opId}`)
  calls += 1
  let url = r.path.replace(/\{(\w+)\}/g, (_, k) => encodeURIComponent(o.path?.[k] ?? (() => { throw new Error(`${opId}: missing path param ${k}`) })()))
  const q = new URLSearchParams()
  for (const [k, v] of Object.entries(o.query ?? {})) {
    if (v === undefined || v === null) continue
    for (const x of Array.isArray(v) ? v : [v]) q.append(k, String(x))
  }
  if ([...q].length) url += `?${q}`
  const headers = { accept: 'application/json', 'accept-language': o.lang ?? 'en', ...(o.headers ?? {}) }
  if (o.as) headers.authorization = `Bearer ${tokens[o.as] ?? (() => { throw new Error(`${opId}: no token for ${o.as}`) })()}`
  if (o.venue) headers['x-venue-id'] = o.venue
  if (o.provider) headers['x-provider-id'] = o.provider
  if (r.idempotent) headers['idempotency-key'] = o.idempotencyKey ?? uuid()
  if (o.ifMatch) headers['if-match'] = o.ifMatch
  let body
  if (o.body !== undefined) {
    headers['content-type'] = 'application/json'
    body = JSON.stringify(o.body)
    if (r.body && !o.invalidBody) {
      const v = validatorFor(r.body)
      if (!v(o.body)) fail(`${opId} request`, `the example body does not match the request schema: ${JSON.stringify(v.errors?.slice(0, 2))}`)
    }
  }
  const res = await fetch(base + '/v1' + url, { method: r.method, headers, body })
  const expected = o.expect ?? r.status
  const ctype = res.headers.get('content-type') ?? ''
  let data = null
  const text = r.pdf && res.ok ? null : await res.text()
  if (r.pdf && res.ok) {
    const buf = Buffer.from(await res.arrayBuffer())
    if (!buf.subarray(0, 5).toString().startsWith('%PDF-')) fail(`${opId} response`, 'not a PDF')
    data = buf
  } else if (text) {
    try { data = JSON.parse(text) } catch { fail(`${opId} response`, `body is not JSON: ${text.slice(0, 120)}`) }
  }
  const where = `${r.method} ${r.path} (${opId})`
  if (verbose) console.log(`${res.status} ${where}${o.as ? ` as ${o.as}` : ''}`)
  if (res.status !== expected) {
    fail(where, `expected ${expected}, got ${res.status}: ${text?.slice(0, 300)}`)
    return { status: res.status, data, headers: res.headers, ok: false }
  }
  if (expected >= 400) {
    if (!ctype.includes('problem+json')) fail(where, `error content type is ${ctype}`)
    if (!problemValidator(data)) fail(where, `problem body does not match Problem: ${JSON.stringify(problemValidator.errors?.slice(0, 2))}`)
    if (o.code && data?.code !== o.code) fail(where, `expected code ${o.code}, got ${data?.code}`)
    const declared = Object.keys(r.op.responses)
    if (!declared.includes(String(expected)) && !declared.includes('default')) fail(where, `status ${expected} is not declared for this operation (${declared.join(', ')})`)
  } else if (r.response && data !== null && !r.pdf) {
    const v = validatorFor(r.response)
    if (!v(data)) fail(where, `response does not match its schema: ${JSON.stringify(v.errors?.slice(0, 3))}`)
    else if (o.count !== false && expected === r.status) hits.add(opId)
  } else if (o.count !== false && expected === r.status) hits.add(opId)
  return { status: res.status, data, headers: res.headers, ok: true }
}
const D = async (opId, o) => (await call(opId, o)).data

// ---------------------------------------------------------------- the story
const lt = (en, ar) => ({ en, ar })
const money = (fils) => ({ fils, currency: 'KWD' })
const contact = (name, phone) => ({ name, phone, bookingFor: 'bride', shared: true })
let phoneSeq = 0
const nextPhone = () => `+9655004${String(1000 + (phoneSeq += 1))}`

async function signUp(label) {
  const phone = nextPhone()
  const ch = await D('requestOtp', { body: { phone, purpose: 'login' } })
  const s = await D('verifyOtp', { body: { challengeId: ch.challengeId, code: '123456' } })
  tokens[label] = s.accessToken
  return { phone, session: s }
}

/** Buys a voucher (checkout, payment session, gateway settles) and returns it. */
async function buyVoucher(as, { venueId = 'V01', hallId, packageId, date, guests }) {
  const co = await D('startVoucherCheckout', { as, body: { targetType: 'venue', targetId: venueId, hallId, packageId, eventDate: date, guests } })
  const ps = await D('createPaymentSession', { as, path: { voucherId: co.voucher.id }, body: { method: 'knet' } })
  await control(`payments/${ps.id}/settle`, { outcome: 'succeeded' })
  const state = await D('getPaymentState', { as, path: { paymentId: ps.id } })
  if (state.status !== 'succeeded') fail('buyVoucher', `payment is ${state.status}`)
  return { voucher: state.voucher, checkout: co, payment: ps }
}

function requestInput({ venueId = 'V01', hallId, sessionId, packageId, date, guests, voucherId, name = 'Test Client', phone = '+96550009999' }) {
  return { targetType: 'venue', venueId, eventDate: date, sections: [{ hallId, sessionId, audience: 'women', guests, packageId }], voucherId, contact: contact(name, phone) }
}

async function main() {
  await startServer()
  const id = await (await fetch(`${base}/__gz`)).json()
  console.log(`mock server ${base} (${id.service ?? 'api'}, slot ${id.slot})`)
  await control('reset', {})
  tokens.reem = await sessionOf('reem')
  tokens.hind = await sessionOf('hotel_manager')
  tokens.khalid = await sessionOf('hotel_admin')
  tokens.zahra = await sessionOf('provider')

  // ============ anonymous reads
  await D('getAppConfig')
  await D('ingestEvents', { body: { events: [{ eventId: uuid(), name: 'venue_viewed', at: '2026-11-12T16:00:00+03:00', props: { venueId: 'V01' } }, { eventId: uuid(), name: 'Bad Name', at: '2026-11-12T16:00:00+03:00' }] } })
  await D('getFilterTaxonomy')
  await D('listAreas')
  await D('searchRegions', { query: { q: 'salmiya' } })
  await D('listFaq')
  await D('getLegalDocument', { path: { kind: 'terms' } })
  await D('listBudgetBands')
  await D('listPlannerPackages')
  await D('getPlanner', { path: { plannerId: 'planner-nouf' } })
  const cats = await D('listServiceCategories')
  const provPage = await D('listServiceProviders', { query: { categoryId: cats.primary[0].id, limit: 5 } })
  await D('getServiceProvider', { path: { providerId: provPage.items[0].id } })
  await D('quoteProvider', { path: { providerId: provPage.items[0].id }, query: { packageId: provPage.items[0].packages[0].id, qty: 1, date: '2027-01-20' } })
  const search = await D('searchVenues', { query: { limit: 4, sort: 'rating', types: ['hotel'], date: '2027-01-14', guests: 350, audience: 'women' } })
  await D('searchVenues', { query: { limit: 4, cursor: search.nextCursor, sort: 'rating', types: ['hotel'] } })
  await D('countVenues', { query: { voucherOnly: true } })
  const detail = await D('getVenue', { path: { venueId: 'V01' }, query: { date: '2027-01-14', guests: 350, audience: 'women' } })
  const danah = detail.venue.halls.find((h) => h.id === 'V01-danah')
  const session = danah.sessions[0].id
  const avail = await D('getVenueAvailability', { path: { venueId: 'V01' }, query: { from: '2027-01-15', to: '2027-03-31', hallId: 'V01-danah', guests: 300, audience: 'women' } })
  const free = avail.days.filter((d) => d.state === 'available' && d.voucherPrice && d.packageId)
  if (free.length < 14) fail('story', `only ${free.length} free voucher days for V01-danah`)
  const day = () => free.shift()
  await D('getVenueDayAvailability', { path: { venueId: 'V01' }, query: { date: '2027-01-14', guests: 350, audience: 'women' } })
  const quote = await D('quoteVenue', { path: { venueId: 'V01' }, body: { eventDate: '2027-01-14', sections: [{ hallId: 'V01-danah', audience: 'women', guests: 350, packageId: 'V01-ladies-weekend' }] } })
  if (quote.totals.standardTotal.fils !== 18200000 || quote.totals.voucherTotal.fils !== 15400000) fail('hero quote', `${quote.totals.standardTotal.fils} / ${quote.totals.voucherTotal.fils}`)
  await D('listNearbyVenues', { path: { venueId: 'V01' }, query: { limit: 3 } })
  await D('compareVenues', { body: { venueIds: ['V01', 'V05', 'V07'], date: '2027-01-14', guests: 350, audience: 'women', originId: 'ref-salmiya' } })
  await D('getHome', { query: { date: '2027-01-14', guests: 350, audience: 'women' } })
  await D('getHome', { as: 'reem' })
  await D('listVenueReviews', { path: { venueId: 'V01' }, query: { sort: 'highest', limit: 5 } })
  const vdates = await D('listVisitDates', { path: { venueId: 'V01' }, query: { days: 14 } })
  const vslots = await D('listVisitSlots', { path: { venueId: 'V01' }, query: { date: vdates.dates[0] } })

  // ============ auth
  const reg = await D('registerAccount', { body: { phone: '+96550003001', name: 'Sara Test', password: 'Passw0rd!x', acceptedTerms: true, locale: 'en', deviceId: 'dev-reg' } })
  const regSession = await D('verifyOtp', { body: { challengeId: reg.challengeId, code: '654321' } })
  tokens.sara = regSession.accessToken
  await D('passwordLogin', { body: { phone: '+96550003001', password: 'Passw0rd!x' } })
  await call('passwordLogin', { body: { phone: '+96550003001', password: 'nope' }, expect: 401, code: 'CREDENTIALS_INVALID' })
  const pw = await D('requestPasswordReset', { body: { phone: '+96550003001' } })
  await D('resetPassword', { body: { challengeId: pw.challengeId, code: '123456', newPassword: 'N3wPassw0rd!' } })
  await call('verifyOtp', { body: { challengeId: pw.challengeId, code: '000000' }, expect: 423, code: 'OTP_LOCKED', count: false })
  const ch2 = await D('requestOtp', { body: { phone: '+96550003002', purpose: 'login' } })
  await call('verifyOtp', { body: { challengeId: ch2.challengeId, code: '111111' }, expect: 410, code: 'OTP_EXPIRED', count: false })
  const jwt = (claims) => `h.${Buffer.from(JSON.stringify(claims)).toString('base64url')}.s`
  const apple = await D('signInWithApple', { body: { identityToken: jwt({ sub: 'apple-1', name: 'Apple Person' }), name: 'Apple Person', acceptedTerms: true } })
  tokens.apple = apple.accessToken
  await call('createRequest', { as: 'apple', body: requestInput({ hallId: 'V01-danah', sessionId: session, packageId: 'V01-ladies-weekend', date: '2027-01-14', guests: 350, voucherId: 'none' }), expect: 403, code: 'PHONE_VERIFICATION_REQUIRED', count: false })
  const google = await D('signInWithGoogle', { body: { identityToken: jwt({ sub: 'google-1', email: 'g@example.com' }) } })
  const refreshed = await D('refreshSession', { body: { refreshToken: google.refreshToken } })
  tokens.google = refreshed.accessToken
  const su = await D('stepUp', { as: 'reem', body: { method: 'password', password: 'Ghazal#2026' } })
  if (!su.token) fail('stepUp', 'no token')
  const out = await signUp('logout')
  await D('signOut', { as: 'logout', body: { refreshToken: out.session.refreshToken } })
  await call('getMe', { as: 'logout', expect: 401, count: false })

  const pl = await D('partnerLogin', { body: { email: 'hind@aurelia-gulf.example', password: 'Ghazal#2026', deviceId: 'dev-p1' } })
  if (pl.status !== 'code_required') fail('partnerLogin', pl.status)
  await D('partnerVerifyCode', { body: { challengeId: pl.challenge.challengeId, code: '123456', deviceId: 'dev-p1' } })
  const pf = await D('partnerForgotPassword', { body: { email: 'hind@aurelia-gulf.example' } })
  await D('partnerResetPassword', { body: { challengeId: pf.challengeId, code: '123456', newPassword: 'Ghazal#2026' } })

  // ============ a new client: profile, wedding tools, chat
  const nora = await signUp('nora')
  await D('getMe', { as: 'nora' })
  await D('updateMe', { as: 'nora', body: { name: 'نورة المطيري', locale: 'ar', marketingOptIn: true } })
  await D('registerDevice', { as: 'nora', path: { deviceId: 'dev-nora' }, body: { platform: 'ios', pushToken: 'tok', locale: 'ar', appVersion: '1.0.0' } })
  await call('getWeddingProfile', { as: 'nora', expect: 404, code: 'NOT_FOUND', count: false })
  await D('putWeddingProfile', { as: 'nora', body: { role: 'bride', brideName: 'نورة', partnerName: 'عبدالله', weddingDate: '2027-03-18', dateMode: 'exact', guests: { women: 300, men: 250 }, venueBudget: { min: money(15000000), max: money(25000000) }, totalBudget: money(50000000), areaIds: ['salmiya'], searching: ['women'] } })
  await D('getWeddingProfile', { as: 'nora' })
  await D('updateWeddingProfile', { as: 'nora', body: { guests: { women: 320, men: 250 } } })
  await D('getWeddingOverview', { as: 'nora' })
  await D('getChecklist', { as: 'nora' })
  const item = await D('createChecklistItem', { as: 'nora', body: { title: 'Book the henna night', group: 'custom', dueOn: '2027-02-01' } })
  await D('updateChecklistItem', { as: 'nora', path: { itemId: item.id }, body: { done: true } })
  await D('deleteChecklistItem', { as: 'nora', path: { itemId: item.id } })
  await D('getBudget', { as: 'nora' })
  await D('setBudget', { as: 'nora', body: { total: money(52000000), allocations: [{ categoryId: 'venue_catering', allocated: money(30000000) }] } })
  const exp = await D('addExpense', { as: 'nora', body: { categoryId: 'makeup_henna', label: 'Henna', amount: money(80000), status: 'paid', date: '2026-11-08' } })
  await D('updateExpense', { as: 'nora', path: { expenseId: exp.id }, body: { status: 'committed' } })
  await D('deleteExpense', { as: 'nora', path: { expenseId: exp.id } })
  await D('saveWishlistItem', { as: 'nora', path: { type: 'venue', id: 'V01' }, body: { lastSeenPrice: money(18200000) } })
  await D('mergeWishlist', { as: 'nora', body: { items: [{ type: 'venue', id: 'V05' }, { type: 'vendor', id: provPage.items[0].id }] } })
  await D('listWishlist', { as: 'nora', query: { date: '2027-01-14', guests: 350, audience: 'women' } })
  await D('removeWishlistItem', { as: 'nora', path: { type: 'venue', id: 'V05' } })
  const qr = await D('createQuoteRequest', { as: 'nora', body: { providerId: provPage.items[0].id, packageId: provPage.items[0].packages[0].id, eventDate: '2027-03-18', guests: 100, note: 'Please send availability.' } })
  await D('listQuoteRequests', { as: 'nora' })
  const pr = await D('createPlannerRequest', { as: 'nora', body: { tier: 'gold', venueId: 'V01', eventDate: '2027-03-18', windows: [{ date: '2026-11-20', part: 'evening' }], note: 'Help with the kosha' } })
  await D('getCurrentPlannerRequest', { as: 'nora' })
  await D('schedulePlannerMeeting', { as: 'nora', path: { requestId: pr.id }, body: { date: pr.slots[0].date, time: pr.slots[0].times[0] } })
  const conv = await D('createConversation', { as: 'nora', body: { kind: 'enquiry', venueId: 'V07', firstMessage: 'Is the hall free in March?' } })
  await D('getConversation', { as: 'nora', path: { conversationId: conv.id } })
  const msg = await D('sendMessage', { as: 'nora', path: { conversationId: conv.id }, body: { clientMsgId: uuid(), kind: 'text', text: 'And parking?', origin: 'en' } })
  await control('flush', {})
  const msgs = await D('listMessages', { as: 'nora', path: { conversationId: conv.id }, query: { afterSeq: 0, limit: 20 } })
  await D('markConversationRead', { as: 'nora', path: { conversationId: conv.id }, body: { upToSeq: msgs.items.at(-1).seq } })
  await D('setConversationPinned', { as: 'nora', path: { conversationId: conv.id }, body: { pinned: true } })
  const up = await D('createAttachmentUpload', { as: 'nora', path: { conversationId: conv.id }, body: { fileName: 'plan.pdf', contentType: 'application/pdf', sizeBytes: 120000, purpose: 'chat_document' } })
  await call('createAttachmentUpload', { as: 'nora', path: { conversationId: conv.id }, body: { fileName: 'big.pdf', contentType: 'application/pdf', sizeBytes: 90 * 1024 * 1024, purpose: 'chat_document' }, expect: 422, code: 'MEDIA_TOO_LARGE', count: false })
  await call('createAttachmentUpload', { as: 'nora', path: { conversationId: conv.id }, body: { fileName: 'x.exe', contentType: 'application/x-msdownload', sizeBytes: 1000, purpose: 'chat_document' }, expect: 422, code: 'MEDIA_TYPE_UNSUPPORTED', count: false })
  await D('sendMessage', { as: 'nora', path: { conversationId: conv.id }, body: { clientMsgId: uuid(), kind: 'document', attachmentId: up.id } })
  await D('listConversations', { as: 'nora', query: { kind: ['enquiry'], limit: 10 } })
  await D('getSupportConversation', { as: 'nora' })
  await D('listNotifications', { as: 'reem', query: { unread: true, limit: 10 } })
  const nn = await D('listNotifications', { as: 'reem' })
  await D('getUnreadNotificationCount', { as: 'reem' })
  await D('markNotificationRead', { as: 'reem', path: { notificationId: nn.items[0].id } })
  await D('markAllNotificationsRead', { as: 'reem' })
  const np = await D('getNotificationPreferences', { as: 'reem' })
  await D('updateNotificationPreferences', { as: 'reem', body: { ...np, marketing: false } })
  const ph = await D('requestPhoneChange', { as: 'nora', body: { phone: '+96550007777' } })
  await D('confirmPhoneChange', { as: 'nora', body: { challengeId: ph.challengeId, code: '123456' } })

  // ============ vouchers and the request lifecycle
  const first = day()
  const { voucher: v1, checkout: co1 } = await buyVoucher('nora', { hallId: 'V01-danah', packageId: first.packageId, date: first.date, guests: 300 })
  await D('listVouchers', { as: 'nora', query: { status: ['active', 'bound'], limit: 5 } })
  await D('getVoucher', { as: 'nora', path: { voucherId: v1.id } })
  const receipts = await D('listReceipts', { as: 'nora' })
  await call('getReceiptPdf', { as: 'nora', path: { receiptNo: receipts.items[0].receiptNo } })
  await call('startVoucherCheckout', { as: 'nora', body: { targetType: 'venue', targetId: 'V01', hallId: 'V01-danah', packageId: 'V01-ladies-weekend', eventDate: '2026-11-13', guests: 300 }, expect: 422, code: 'LEAD_TIME_TOO_SHORT', count: false })

  // quote -> checkout -> request with the voucher of the checkout
  const reqDay = first.date
  const created = await D('createRequest', { as: 'nora', body: requestInput({ hallId: 'V01-danah', sessionId: session, packageId: co1.voucher.packageId, date: reqDay, guests: 300, voucherId: v1.id, name: 'Nora', phone: '+96550007777' }) })
  await D('listRequests', { as: 'nora', query: { status: ['pending', 'approved'], limit: 5 } })
  await D('getRequest', { as: 'nora', path: { requestId: created.id } })
  await D('getConfirmWindow', { as: 'nora', path: { requestId: created.id } })
  await call('createRequest', { as: 'nora', body: requestInput({ hallId: 'V01-danah', sessionId: session, packageId: co1.voucher.packageId, date: reqDay, guests: 300, voucherId: v1.id }), expect: 409, code: 'VOUCHER_NOT_USABLE', count: false })

  // the partner side
  await D('getPartnerMe', { as: 'hind' })
  await D('getPartnerAccount', { as: 'hind', venue: 'V01' })
  await D('getPartnerToday', { as: 'hind', venue: 'V01' })
  await D('listNeedsYou', { as: 'hind', venue: 'V01' })
  await D('listPartnerRequests', { as: 'hind', venue: 'V01', query: { segment: 'pending', limit: 5 } })
  await D('listPartnerRequests', { as: 'hind', venue: 'V01', query: { segment: 'awaiting_client' } })
  await D('listPartnerRequests', { as: 'hind', venue: 'V01', query: { segment: 'upcoming' } })
  await D('listPartnerRequests', { as: 'hind', venue: 'V01', query: { segment: 'past', limit: 5 } })
  const pd = await D('getPartnerRequest', { as: 'hind', venue: 'V01', path: { requestId: created.id } })
  const tag = (b) => `"v${b.version}"`
  // approve, undo inside the window, approve again
  const ap1 = await D('acceptRequest', { as: 'hind', venue: 'V01', path: { requestId: created.id }, body: {}, ifMatch: tag(pd.booking) })
  const undone = await D('undoAcceptRequest', { as: 'hind', venue: 'V01', path: { requestId: created.id } })
  if (undone.status !== 'pending') fail('undoAcceptRequest', undone.status)
  const ap2 = await D('acceptRequest', { as: 'hind', venue: 'V01', path: { requestId: created.id }, body: {}, ifMatch: tag(undone), idempotencyKey: uuid() })
  await call('acceptRequest', { as: 'hind', venue: 'V01', path: { requestId: created.id }, body: {}, ifMatch: tag(ap1), expect: 409, code: 'BOOKING_STATE_CONFLICT', count: false })
  await control('flush', {})
  await call('undoAcceptRequest', { as: 'hind', venue: 'V01', path: { requestId: created.id }, expect: 409, count: false })
  const conf = await D('confirmRequest', { as: 'nora', path: { requestId: created.id }, ifMatch: tag(ap2) })
  const redeemable = await D('listRedeemableVouchers', { as: 'hind', venue: 'V01' })
  if (!redeemable.items.some((x) => x.voucher.code === v1.code)) fail('listRedeemableVouchers', 'the confirmed voucher is not redeemable')
  await D('checkVoucherCode', { as: 'hind', venue: 'V01', path: { code: v1.code } })
  await call('redeemVoucher', { as: 'hind', venue: 'V01', path: { code: 'GV-0000-ZZZZ' }, expect: 404, code: 'VOUCHER_UNKNOWN', count: false })
  await call('redeemVoucher', { as: 'hind', venue: 'V05', path: { code: v1.code }, expect: 403, count: false })
  await D('redeemVoucher', { as: 'hind', venue: 'V01', path: { code: v1.code } })
  await call('redeemVoucher', { as: 'hind', venue: 'V01', path: { code: v1.code }, expect: 409, code: 'VOUCHER_ALREADY_USED', count: false })
  await D('listRedeemedVouchers', { as: 'hind', venue: 'V01' })
  void conf
  // the day passes: completed, report an issue and review
  await control('clock', { now: `${first.date}T23:30:00+03:00` })
  await control('clock', { advanceHours: 30 })
  const done = await D('getRequest', { as: 'nora', path: { requestId: created.id } })
  if (done.booking.status !== 'completed') fail('R12', `status ${done.booking.status}`)
  await D('reportIssue', { as: 'nora', path: { requestId: created.id }, body: { text: 'The sound system was late.' } })
  await D('createReview', { as: 'nora', path: { requestId: created.id }, body: { rating: 4, categories: { venue: 4, food: 4, service: 4, value: 4 }, text: 'Lovely hall.', origin: 'en', anonymous: false } })
  await call('createReview', { as: 'nora', path: { requestId: created.id }, body: { rating: 4, categories: { venue: 4, food: 4, service: 4, value: 4 }, text: 'Again.', anonymous: true }, expect: 409, code: 'REVIEW_NOT_ALLOWED', count: false })
  await control('reset', {})
  tokens.reem = await sessionOf('reem')
  tokens.hind = await sessionOf('hotel_manager')
  tokens.khalid = await sessionOf('hotel_admin')
  tokens.zahra = await sessionOf('provider')
  await signUp('nora') // sessions are gone after a reset: a new client takes over

  // second round after the reset: decline, credit voucher, withdraw, cancel, revoke, cancel confirmed, counter-offer
  const days = free.slice()
  async function openRequest(as, d, guests = 300) {
    const { voucher } = await buyVoucher(as, { hallId: 'V01-danah', packageId: d.packageId, date: d.date, guests })
    const b = await D('createRequest', { as, body: requestInput({ hallId: 'V01-danah', sessionId: session, packageId: d.packageId, date: d.date, guests, voucherId: voucher.id }) })
    return { voucher, booking: b }
  }
  const dayList = days.slice()
  const next = () => dayList.shift()
  // a: declined -> credit voucher
  const a = await openRequest('nora', next())
  await D('declineRequest', { as: 'hind', venue: 'V01', path: { requestId: a.booking.id }, body: { reason: 'date_unavailable', note: 'Booked privately.' }, ifMatch: tag(a.booking) })
  const voucherA = await D('getVoucher', { as: 'nora', path: { voucherId: a.voucher.id } })
  if (!voucherA.options.creditEligible) fail('decline', 'the voucher is not credit-eligible')
  const rr = await D('createRefundRequest', { as: 'nora', body: { voucherId: a.voucher.id, note: 'Please issue a credit voucher.' } })
  await call('createRefundRequest', { as: 'nora', body: { voucherId: a.voucher.id }, expect: 409, code: 'REFUND_REQUEST_EXISTS', count: false })
  await D('listRefundRequests', { as: 'nora' })
  await D('getRefundRequest', { as: 'nora', path: { requestId: rr.id } })
  await control(`support/refund-requests/${rr.id}/decide`, { action: 'grant' })
  const walletA = await D('listVouchers', { as: 'nora', query: { limit: 10 } })
  if (!walletA.items.some((i) => i.voucher.kind === 'credit')) fail('credit voucher', 'no credit voucher in the wallet')
  // b: withdraw ; rebind the released voucher to another date
  const b1 = await openRequest('nora', next())
  await D('withdrawRequest', { as: 'nora', path: { requestId: b1.booking.id }, ifMatch: tag(b1.booking) })
  const rebound = await D('rebindVoucher', { as: 'nora', path: { voucherId: b1.voucher.id }, body: { packageId: dayList[0].packageId, eventDate: next().date, hallId: 'V01-danah', guests: 300 } })
  void rebound
  // c: approve then client cancels
  const c1 = await openRequest('nora', next())
  const c1a = await D('acceptRequest', { as: 'hind', venue: 'V01', path: { requestId: c1.booking.id }, body: {}, ifMatch: tag(c1.booking) })
  await control('flush', {})
  await D('cancelRequest', { as: 'nora', path: { requestId: c1.booking.id }, body: { reason: 'plans_changed' }, ifMatch: tag(c1a) })
  // d: approve then partner revokes
  const d2 = await openRequest('nora', next())
  const d2a = await D('acceptRequest', { as: 'hind', venue: 'V01', path: { requestId: d2.booking.id }, body: {}, ifMatch: tag(d2.booking) })
  await D('revokeApproval', { as: 'hind', venue: 'V01', path: { requestId: d2.booking.id }, body: { reason: 'hall_unavailable', note: 'Maintenance.' }, ifMatch: tag(d2a) })
  // e: confirmed then partner cancels
  const e1 = await openRequest('nora', next())
  const e1a = await D('acceptRequest', { as: 'hind', venue: 'V01', path: { requestId: e1.booking.id }, body: {}, ifMatch: tag(e1.booking) })
  const e1c = await D('confirmRequest', { as: 'nora', path: { requestId: e1.booking.id }, ifMatch: tag(e1a) })
  await D('cancelConfirmedRequest', { as: 'hind', venue: 'V01', path: { requestId: e1.booking.id }, body: { reason: 'safety_or_maintenance' }, ifMatch: tag(e1c) })
  // f: counter-offer, decline it, then accept a second one
  const f1 = await openRequest('nora', next())
  const f1p = await D('proposeDates', { as: 'hind', venue: 'V01', path: { requestId: f1.booking.id }, body: { options: [{ eventDate: next().date, hallId: 'V01-danah', sessionId: session }, { eventDate: next().date, hallId: 'V01-danah', sessionId: session }] }, ifMatch: tag(f1.booking) })
  await D('declineProposal', { as: 'nora', path: { requestId: f1.booking.id, proposalId: f1p.proposal.id }, ifMatch: tag(f1p) })
  const f2 = await openRequest('sara', next()).catch(async () => { await signUp('sara'); return openRequest('sara', next()) })
  const f2p = await D('proposeDates', { as: 'hind', venue: 'V01', path: { requestId: f2.booking.id }, body: { options: [{ eventDate: next().date, hallId: 'V01-danah', sessionId: session }] }, ifMatch: tag(f2.booking) })
  await D('acceptProposal', { as: 'sara', path: { requestId: f2.booking.id, proposalId: f2p.proposal.id }, body: { optionIndex: 0 }, ifMatch: tag(f2p) })
  // g: the clock forfeits the voucher of an approval nobody confirmed
  const g1 = await openRequest('nora', next())
  await D('acceptRequest', { as: 'hind', venue: 'V01', path: { requestId: g1.booking.id }, body: {}, ifMatch: tag(g1.booking) })
  await control('clock', { advanceHours: 25 })
  const g1d = await D('getRequest', { as: 'nora', path: { requestId: g1.booking.id } })
  if (g1d.voucher.status !== 'forfeited') fail('R09', `voucher is ${g1d.voucher.status}`)
  await call('confirmRequest', { as: 'nora', path: { requestId: g1.booking.id }, ifMatch: tag(g1d.booking), expect: 409, count: false })

  // ============ partner: calendar
  const cal = await D('getPartnerCalendar', { as: 'hind', venue: 'V01', query: { from: '2027-01-01', to: '2027-02-15', hallId: 'V01-danah' } })
  void cal
  await D('getPartnerCalendarDay', { as: 'hind', venue: 'V01', path: { date: '2027-01-14' } })
  const blk = await D('createCalendarBlocks', { as: 'hind', venue: 'V01', body: { hallIds: ['V01-majlis'], dates: ['2027-06-08', '2027-06-09'], reason: 'maintenance', note: 'Repainting' } })
  await call('createCalendarBlocks', { as: 'hind', venue: 'V01', body: { hallIds: ['V01-danah'], dates: ['2027-01-15'], reason: 'other' }, expect: 409, code: 'SLOT_UNAVAILABLE', count: false })
  await D('listCalendarHolds', { as: 'hind', venue: 'V01' })
  await D('getSoftDates', { as: 'hind', venue: 'V01' })
  await D('getCalendarSync', { as: 'hind', venue: 'V01' })
  await D('updateCalendarSync', { as: 'hind', venue: 'V01', body: { address: 'calendar@aurelia-gulf.example', ics: true } })
  await D('sendCalendarIcs', { as: 'hind', venue: 'V01' })
  await D('removeCalendarBlockBatch', { as: 'hind', venue: 'V01', path: { batchId: blk.id } })

  // ============ partner: venue, halls, packages, rules, hours, media
  const pv = await call('getPartnerVenue', { as: 'hind', venue: 'V01' })
  await D('updatePartnerVenue', { as: 'hind', venue: 'V01', body: { tagline: lt('Where the evening begins', 'حيث تبدأ الليلة') }, ifMatch: pv.headers.get('etag') })
  await call('updatePartnerVenue', { as: 'hind', venue: 'V01', body: { phone: '+96522270000' }, ifMatch: pv.headers.get('etag'), expect: 412, code: 'PRECONDITION_FAILED', count: false })
  const halls = await D('listPartnerHalls', { as: 'hind', venue: 'V01' })
  const hallInput = (name) => ({ name: lt(name, name), setting: 'indoor', capacity: { min: 50, max: 200 }, exclusiveDay: true, sessions: [{ name: lt('Evening', 'مساء'), start: '19:00', end: '23:30', weekdays: [4, 5, 6] }], sections: [{ audience: 'women', minGuests: 50, maxGuests: 200, policy: halls.halls[0].sections[0].policy }], description: lt('A small hall.', 'قاعة صغيرة.') })
  const hall = await D('createHall', { as: 'hind', venue: 'V01', body: hallInput('Orchid Room') })
  await D('updateHall', { as: 'hind', venue: 'V01', path: { hallId: hall.id }, body: hallInput('Orchid Room II'), ifMatch: '"v1"' })
  const venueNow = await D('getVenue', { path: { venueId: 'V01' } })
  await D('setVenueAmenities', { as: 'hind', venue: 'V01', body: { amenities: venueNow.venue.amenities } })
  const cat = await D('listPartnerPackages', { as: 'hind', venue: 'V01' })
  const pkgIn = (name, std, vch) => ({ hallIds: ['V01-danah'], name: lt(name, name), archetype: 'ladies_standard', audiences: ['women'], pricingBasis: 'per_guest', priceStructure: 'per_person', priceUnit: 'per_guest', minGuests: 100, maxGuests: 400, guestStep: 10, complimentaryBps: 0, inclusions: [], notes: [], active: true, rules: [{ tier: 'weekday', weekdays: [0, 1, 2, 3], priority: 1, perGuest: money(std), voucherPerGuest: vch ? money(vch) : null }] })
  const np1 = await D('createPackage', { as: 'hind', venue: 'V01', body: pkgIn('Garden reception', 40000, 32000) })
  await call('createPackage', { as: 'hind', venue: 'V01', body: pkgIn('Bad price', 40000, 50000), expect: 422, code: 'VALIDATION_FAILED', count: false })
  await D('updatePackage', { as: 'hind', venue: 'V01', path: { packageId: np1.package.id }, body: pkgIn('Garden reception II', 42000, 33000), ifMatch: '"v1"' })
  const ex = await D('createExtra', { as: 'hind', venue: 'V01', body: { category: cat.extras[0]?.category ?? 'lighting', name: lt('Extra lights', 'إضاءة إضافية'), pricingUnit: 'flat', price: money(150000), maxQty: 4 } })
  await D('updateExtra', { as: 'hind', venue: 'V01', path: { extraId: ex.id }, body: { category: ex.category, name: lt('Extra lights', 'إضاءة إضافية'), pricingUnit: 'flat', price: money(160000), maxQty: 5 } })
  const pol = await call('getVenuePolicies', { as: 'hind', venue: 'V01' })
  await D('putVenuePolicies', { as: 'hind', venue: 'V01', body: pol.data, ifMatch: pol.headers.get('etag') })
  const rules = await call('getBookingRules', { as: 'hind', venue: 'V01' })
  await D('putBookingRules', { as: 'hind', venue: 'V01', body: { ...rules.data, responseSlaHours: 12 }, ifMatch: rules.headers.get('etag') })
  const hours = await D('getBusinessHours', { as: 'hind', venue: 'V01' })
  await D('putBusinessHours', { as: 'hind', venue: 'V01', body: hours })
  const lib = await D('listVenueMedia', { as: 'hind', venue: 'V01' })
  const mu = await D('createMediaUploadSession', { as: 'hind', venue: 'V01', body: { kind: 'photo', zone: 'hall', hallId: 'V01-danah', fileName: 'hall.jpg', contentType: 'image/jpeg', sizeBytes: 800000 } })
  await call('createMediaUploadSession', { as: 'hind', venue: 'V01', body: { kind: 'video', zone: 'hall', fileName: 'tour.mp4', contentType: 'video/mp4', sizeBytes: 600 * 1024 * 1024 }, expect: 422, code: 'MEDIA_TOO_LARGE', count: false })
  const mi = await D('completeMediaUpload', { as: 'hind', venue: 'V01', path: { uploadId: mu.id }, body: { alt: lt('The hall', 'القاعة') } })
  await D('updateMediaItem', { as: 'hind', venue: 'V01', path: { mediaId: mi.id }, body: { zone: 'stage_kosha', isCover: false } })
  await D('reorderMedia', { as: 'hind', venue: 'V01', body: { ids: [mi.id, ...lib.items.map((m) => m.id)] } })
  await D('deleteMediaItem', { as: 'hind', venue: 'V01', path: { mediaId: mi.id } })

  // ============ partner: staff
  const staff = await D('listStaff', { as: 'khalid', venue: 'V01' })
  const inv = await D('inviteStaff', { as: 'khalid', venue: 'V01', body: { email: 'ops@aurelia-gulf.example', role: 'reception' } })
  await call('inviteStaff', { as: 'khalid', venue: 'V01', body: { email: 'ops@aurelia-gulf.example', role: 'reception' }, expect: 409, code: 'EMAIL_ALREADY_INVITED', count: false })
  await call('inviteStaff', { as: 'hind', venue: 'V01', body: { email: 'x@aurelia-gulf.example', role: 'reception' }, expect: 403, code: 'FORBIDDEN', count: false })
  await D('resendStaffInvitation', { as: 'khalid', venue: 'V01', path: { invitationId: inv.id } })
  await D('getStaffInvitationPreview', { path: { token: inv.id } })
  const acc = await D('acceptStaffInvitation', { body: { token: inv.id, password: 'Str0ng#Pass1', acceptedTerms: true } })
  void acc
  const inv2 = await D('inviteStaff', { as: 'khalid', venue: 'V01', body: { email: 'temp@aurelia-gulf.example', role: 'marketing' } })
  await D('revokeStaffInvitation', { as: 'khalid', venue: 'V01', path: { invitationId: inv2.id } })
  const sm = staff.staff.find((s) => s.role === 'reception')
  await D('changeStaffRole', { as: 'khalid', venue: 'V01', path: { staffId: sm.id }, body: { role: 'accountant' } })
  await D('deactivateStaff', { as: 'khalid', venue: 'V01', path: { staffId: sm.id } })
  await D('reactivateStaff', { as: 'khalid', venue: 'V01', path: { staffId: sm.id } })
  const me = staff.staff.find((s) => s.isYou)
  await call('deactivateStaff', { as: 'khalid', venue: 'V01', path: { staffId: me.id }, expect: 409, code: 'STAFF_LAST_ADMIN', count: false })
  await D('getPartnerNotificationPreferences', { as: 'hind', venue: 'V01' })
  await D('updatePartnerNotificationPreferences', { as: 'hind', venue: 'V01', body: { newRequestAlwaysOn: true, messages: true, reviews: false, vouchers: true, visits: true } })

  // ============ partner: visits and the group chat (slots again: the story clock has moved)
  const vdates2 = await D('listVisitDates', { path: { venueId: 'V01' }, query: { days: 14 }, count: false })
  const vslots2 = await D('listVisitSlots', { path: { venueId: 'V01' }, query: { date: vdates2.dates[0] }, count: false })
  const vt = await D('bookVisit', { as: 'reem', body: { venueId: 'V01', slotStart: vslots2.slots.find((s) => s.available).start, visitors: 3, note: 'We love the stage.' } })
  await D('listVisits', { as: 'reem', query: { status: ['requested', 'confirmed'] } })
  await D('getVisit', { as: 'reem', path: { visitId: vt.visit.id } })
  await D('getVisitThread', { as: 'reem', path: { visitId: vt.visit.id } })
  await call('bookVisit', { as: 'reem', body: { venueId: 'V01', slotStart: vt.visit.slotStart, visitors: 2 }, expect: 409, code: 'VISIT_SLOT_TAKEN', count: false })
  await call('bookVisit', { as: 'reem', body: { venueId: 'V19', slotStart: vt.visit.slotStart, visitors: 2 }, expect: 409, code: 'VISIT_NOT_ALLOWED', count: false })
  await D('listPartnerVisits', { as: 'hind', venue: 'V01', query: { status: ['requested'] } })
  await D('getPartnerVisit', { as: 'hind', venue: 'V01', path: { visitId: vt.visit.id } })
  await D('getPartnerVisitThread', { as: 'hind', venue: 'V01', path: { visitId: vt.visit.id } })
  await D('confirmVisit', { as: 'hind', venue: 'V01', path: { visitId: vt.visit.id } })
  await call('confirmVisit', { as: 'hind', venue: 'V01', path: { visitId: vt.visit.id }, expect: 409, code: 'VISIT_STATE_CONFLICT', count: false })
  const vs2 = (await D('listVisitSlots', { path: { venueId: 'V01' }, query: { date: vdates2.dates[1] } })).slots.filter((s) => s.available)
  const proposedVisit = await D('proposeVisitSlot', { as: 'hind', venue: 'V01', path: { visitId: vt.visit.id }, body: { slotStart: vs2[1].start } })
  await D('answerVisitProposal', { as: 'reem', path: { visitId: vt.visit.id }, body: { accept: true } })
  await D('rescheduleVisit', { as: 'reem', path: { visitId: vt.visit.id }, body: { slotStart: vs2[2].start } })
  await D('confirmVisit', { as: 'hind', venue: 'V01', path: { visitId: vt.visit.id } })
  await D('markVisitArrived', { as: 'hind', venue: 'V01', path: { visitId: vt.visit.id } })
  void proposedVisit
  const vt2 = await D('bookVisit', { as: 'reem', body: { venueId: 'V01', slotStart: vs2[3].start, visitors: 2 } })
  await D('declineVisit', { as: 'hind', venue: 'V01', path: { visitId: vt2.visit.id }, body: { reason: 'Closed that day' } })
  const vt3 = await D('bookVisit', { as: 'reem', body: { venueId: 'V01', slotStart: vs2[4].start, visitors: 2 } })
  await D('cancelVisit', { as: 'reem', path: { visitId: vt3.visit.id }, body: { reason: 'Plans changed' } })
  const vt4 = await D('bookVisit', { as: 'reem', body: { venueId: 'V01', slotStart: vs2[5].start, visitors: 2 } })
  await D('confirmVisit', { as: 'hind', venue: 'V01', path: { visitId: vt4.visit.id } })
  await D('markVisitMissed', { as: 'hind', venue: 'V01', path: { visitId: vt4.visit.id } })
  await D('getVisitAvailability', { as: 'hind', venue: 'V01' })
  const va = await D('getVisitAvailability', { as: 'hind', venue: 'V01' })
  await D('putVisitAvailability', { as: 'hind', venue: 'V01', body: va })
  // chat from the partner side
  const hotelConvs = await D('listConversations', { as: 'hind', venue: 'V01', query: { limit: 20 } })
  const hc = hotelConvs.items.find((c) => c.kind === 'venue') ?? hotelConvs.items[0]
  await D('sendMessage', { as: 'hind', venue: 'V01', path: { conversationId: hc.id }, body: { clientMsgId: uuid(), kind: 'text', text: 'Welcome, the date is open.', origin: 'en' } })
  await D('saveReplyDraft', { as: 'hind', venue: 'V01', path: { conversationId: hc.id }, body: { text: 'Draft: thank you' } })
  await D('getNotificationPreferences', { as: 'reem' })
  await D('listNotifications', { as: 'hind', venue: 'V01', query: { limit: 5 } })
  await D('getUnreadNotificationCount', { as: 'hind', venue: 'V01' })

  // ============ partner: growth (voucher price windows, analytics) and reviews
  const win = await D('createVoucherWindow', { as: 'hind', venue: 'V01', body: { title: lt('Winter nights', 'ليالي الشتاء'), packageIds: ['V01-ladies-weekday'], voucherPerGuest: money(30000), eventFrom: '2027-02-01', eventTo: '2027-02-28', startsAt: '2026-11-20T00:00:00+03:00', endsAt: '2026-12-20T00:00:00+03:00' } })
  await D('listVoucherWindows', { as: 'hind', venue: 'V01', query: { status: ['active', 'scheduled'] } })
  await D('updateVoucherWindow', { as: 'hind', venue: 'V01', path: { windowId: win.id }, body: { title: lt('Winter nights II', 'ليالي الشتاء ٢'), packageIds: ['V01-ladies-weekday'], voucherPerGuest: money(29000), eventFrom: '2027-02-01', eventTo: '2027-02-28', startsAt: '2026-11-20T00:00:00+03:00', endsAt: '2026-12-20T00:00:00+03:00' } })
  await D('endVoucherWindow', { as: 'hind', venue: 'V01', path: { windowId: win.id } })
  await D('getPartnerAnalytics', { as: 'hind', venue: 'V01' })
  await D('getPartnerAnalytics', { as: 'hind', venue: 'V01', query: { from: '2026-10-20', to: '2026-11-10' } })
  const reviews = await D('listPartnerReviews', { as: 'hind', venue: 'V01', query: { filter: 'awaiting_reply', limit: 5 } })
  const rv = reviews.items[0]
  await D('getPartnerReview', { as: 'hind', venue: 'V01', path: { reviewId: rv.id } })
  await D('saveReviewReplyDraft', { as: 'hind', venue: 'V01', path: { reviewId: rv.id }, body: { text: 'Thank you for the feedback.' } })
  await D('replyToReview', { as: 'hind', venue: 'V01', path: { reviewId: rv.id }, body: { text: 'Thank you for the feedback, we are improving the car park.', origin: 'en' } })
  await call('replyToReview', { as: 'hind', venue: 'V01', path: { reviewId: rv.id }, body: { text: 'Again', origin: 'en' }, expect: 409, code: 'REVIEW_ALREADY_REPLIED', count: false })
  const rv2 = (await D('listPartnerReviews', { as: 'hind', venue: 'V01', query: { limit: 5 } })).items.find((x) => x.id !== rv.id)
  await D('reportReview', { as: 'hind', venue: 'V01', path: { reviewId: rv2.id }, body: { reason: 'not_a_guest', note: 'We cannot find this booking.' } })
  await D('requestReviewRemoval', { as: 'hind', venue: 'V01', path: { reviewId: rv2.id }, body: { action: 'request_hide', note: 'Not a guest.' } })

  // ============ provider: listings, billing, packages, analytics
  const zl = await D('listListings', { as: 'zahra', provider: 'vendor-flowers-zahra' })
  await D('getPartnerBilling', { as: 'zahra', provider: 'vendor-flowers-zahra' })
  await D('getPartnerBilling', { as: 'hind', venue: 'V01' })
  const draft = await D('createListing', { as: 'zahra', provider: 'vendor-flowers-zahra', body: { title: lt('Zahra Spring Collection', 'تشكيلة زهرة للربيع') } })
  await call('submitListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id }, expect: 422, code: 'VALIDATION_FAILED', count: false })
  const lg = await call('getListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id } })
  await D('updateListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id }, body: { description: lt('Fresh seasonal flowers.', 'زهور موسمية طازجة.') }, ifMatch: lg.headers.get('etag') })
  await D('chooseListingPlan', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id }, body: { cycle: 'monthly' } })
  await call('createListingPaymentSession', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id }, body: { method: 'knet' }, expect: 409, code: 'PLAN_RATES_NOT_ANNOUNCED', count: false })
  const lu = await D('createListingUpload', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id }, body: { fileName: 'cover.jpg', contentType: 'image/jpeg', sizeBytes: 500000, purpose: 'listing_photo' } })
  await D('attachListingMedia', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id }, body: { uploadId: lu.id, role: 'cover', alt: lt('Cover', 'الغلاف') } })
  await D('submitListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id } })
  await call('updateListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id }, body: { title: lt('x', 'x') }, expect: 409, code: 'LISTING_NOT_EDITABLE', count: false })
  await control(`listings/${draft.id}/moderate`, { action: 'reject', codes: ['missing_details'], note: 'Add three portfolio photos.' })
  await D('submitListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id } })
  await control(`listings/${draft.id}/moderate`, { action: 'approve' })
  await D('pauseListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id } })
  await D('resumeListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id } })
  await D('renewListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id } })
  await call('requestListingFeeRefund', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id }, body: { note: 'Please refund.' }, expect: 409, code: 'LISTING_STATE_CONFLICT', count: false })
  void zl
  await control(`listings/${draft.id}/billing`, { status: 'paid', amountFils: 1000 }) // test hook: the hosted payment cannot run while rates are undecided
  await D('requestListingFeeRefund', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: draft.id }, body: { note: 'Please refund.' } })
  // once the owner decides a rate (test hook), a non-exempt provider pays through a hosted session, then the review starts
  await control('plans/monthly/rate', { ratesFils: 5000 })
  const paid = await D('createListing', { as: 'zahra', provider: 'vendor-flowers-zahra', body: { title: lt('Zahra Weddings', 'زهرة للأعراس') } })
  await D('chooseListingPlan', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: paid.id }, body: { cycle: 'monthly' } })
  const payable = await D('submitListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: paid.id } })
  if (payable.status !== 'payment_pending') fail('listing payment', `status ${payable.status}`)
  const lps = await D('createListingPaymentSession', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: paid.id }, body: { method: 'knet' } })
  await control(`payments/${lps.id}/settle`, { outcome: 'succeeded' })
  const lpState = await D('getPaymentState', { as: 'zahra', path: { paymentId: lps.id } })
  if (lpState.status !== 'succeeded') fail('listing payment', `payment ${lpState.status}`)
  const afterPay = await D('getListing', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: paid.id }, count: false })
  if (afterPay.status !== 'pending_review' || afterPay.billing.status !== 'paid') fail('listing payment', `listing ${afterPay.status} / ${afterPay.billing.status}`)
  await control('plans/monthly/rate', { ratesFils: null })
  await D('getListingPerformance', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { listingId: 'lst-flowers-zahra' }, query: { from: '2026-10-20', to: '2026-11-10' } })
  const prov = await D('getPartnerProvider', { as: 'zahra', provider: 'vendor-flowers-zahra' })
  await D('updatePartnerProvider', { as: 'zahra', provider: 'vendor-flowers-zahra', body: { about: lt('Floral studio in Hawalli.', 'استوديو زهور في حولي.'), femaleTeamForLadies: true } })
  await D('listProviderPackages', { as: 'zahra', provider: 'vendor-flowers-zahra' })
  const ppk = await D('createProviderPackage', { as: 'zahra', provider: 'vendor-flowers-zahra', body: { name: lt('Table centerpieces', 'تنسيق الطاولات'), price: money(300000), voucherPrice: money(250000), unit: lt('per table', 'للطاولة'), priceStructure: 'per_person', minQuantity: 5, includes: [lt('Fresh roses', 'ورد طازج')] } })
  await D('updateProviderPackage', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { packageId: ppk.id }, body: { name: lt('Table centerpieces II', 'تنسيق الطاولات ٢'), price: money(320000), voucherPrice: money(260000), unit: lt('per table', 'للطاولة'), priceStructure: 'per_person', minQuantity: 5 } })
  await D('deleteProviderPackage', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { packageId: ppk.id } })
  void prov
  // a provider request with a voucher: client buys at the provider and asks
  const pk0 = prov.packages[0]
  const pco = await D('startVoucherCheckout', { as: 'reem', body: { targetType: 'provider', targetId: 'vendor-flowers-zahra', packageId: pk0.id, eventDate: '2027-02-12', guests: pk0.minQuantity ?? 1 } })
  const pps = await D('createPaymentSession', { as: 'reem', path: { voucherId: pco.voucher.id }, body: { method: 'apple_pay' } })
  await control(`payments/${pps.id}/settle`, { outcome: 'succeeded' })
  const preq = await D('createRequest', { as: 'reem', body: { targetType: 'provider', providerId: 'vendor-flowers-zahra', eventDate: '2027-02-12', service: { listingId: 'lst-flowers-zahra', packageId: pk0.id, quantity: pk0.minQuantity ?? 1 }, voucherId: pco.voucher.id, contact: contact('Reem', '+96550000012') } })
  await D('getPartnerToday', { as: 'zahra', provider: 'vendor-flowers-zahra' })
  await D('acceptRequest', { as: 'zahra', provider: 'vendor-flowers-zahra', path: { requestId: preq.id }, body: {}, ifMatch: tag(preq) })

  // ============ partner account: switching context, new account, profile deletion, support
  await D('switchPartnerContext', { as: 'hind', body: { accountId: 'partner-V01', venueId: 'V01' } })
  const fresh = await signUp('partnerless')
  void fresh
  await D('deleteAccount', { as: 'partnerless' })
  tokens.newpartner = await sessionOf('hotel_non_major')
  await D('chooseAccountType', { as: 'newpartner', body: { accountType: 'service_provider', name: lt('Henna Studio', 'استوديو حناء') } })
  await D('getSupportConversation', { as: 'hind', venue: 'V01' })

  // ============ coverage
  const missing = [...ops.keys()].filter((k) => !hits.has(k))
  console.log(`\noperations hit: ${hits.size} / ${ops.size}  (${calls} calls, ${failures.length} failures)`)
  if (missing.length) { console.error(`not exercised successfully: ${missing.join(', ')}`); failures.push(`coverage: ${missing.length} operation(s) not hit`) }
  const byTag = {}
  for (const [k, r] of ops) { byTag[r.tag] ??= [0, 0]; byTag[r.tag][1] += 1; if (hits.has(k)) byTag[r.tag][0] += 1 }
  console.log(Object.entries(byTag).map(([t, [a, b]]) => `${t} ${a}/${b}`).join('  '))
}

let code = 0
try {
  await main()
} catch (e) {
  console.error(e)
  failures.push(String(e?.message ?? e))
}
await stopServer()
if (failures.length) { console.error(`\n${failures.length} problem(s)`); code = 1 } else console.log('contract test passed')
process.exit(code)
