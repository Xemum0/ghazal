#!/usr/bin/env node
// node packages/i18n/scripts/new-namespace.mjs <namespace>
//   Creates messages/en/<namespace>.json and messages/ar/<namespace>.json from templates/ (five example keys that show
//   a plural, a rich-text tag and a pre-formatted value), then regenerates src/generated/namespaces.ts.
//   Namespace = <app>-<flow>, lower-case, dash-separated: client-booking, client-discover, hotel-bookings.
//   Delete the example keys when you add your own. Key rule: every key starts with the camelCase namespace
//   (client-booking -> clientBooking...), then <Screen><Element>: clientBookingReviewConfirmCta.
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { spawnSync } from 'node:child_process'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const ns = process.argv[2]
if (!ns || !/^(?:client|hotel|server|admin)-[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/.test(ns)) {
  console.error('usage: new-namespace.mjs <app>-<flow>   e.g. client-booking, hotel-bookings (lower-case, dashes)')
  process.exit(64)
}
const prefix = ns.replace(/-([a-z0-9])/g, (_, c) => c.toUpperCase())
for (const lang of ['en', 'ar']) {
  const target = join(root, 'messages', lang, `${ns}.json`)
  if (existsSync(target)) {
    console.error(`${target} already exists; nothing written`)
    process.exit(1)
  }
}
for (const lang of ['en', 'ar']) {
  const template = readFileSync(join(root, 'templates', `namespace.${lang}.json`), 'utf8')
  writeFileSync(join(root, 'messages', lang, `${ns}.json`), template.replaceAll('__PREFIX__', prefix))
  console.log(`created packages/i18n/messages/${lang}/${ns}.json`)
}
const r = spawnSync(process.execPath, [join(root, 'scripts', 'check.mjs'), '--write'], { stdio: 'inherit' })
process.exit(r.status ?? 1)
