// The prototype state a screen is captured in (and the persona the Flutter shot harness uses): signed in as Reem for every client screen
// except onboarding and auth (a first-time guest), signed in as the hotel manager for every partner screen except access.
// Shared by ref-shots.mjs and web-text.mjs; the Flutter side is gzShotPersona in packages/ghazal_app_kit (keep the three in step).
import { readdirSync, readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')

export const storyFor = (it) => (it.app === 'hotel' ? (it.id.startsWith('HL-ACCS-') ? 'start' : 'hotel') : /^CL-(ONBD|AUTH)-/.test(it.id) ? 'start' : 'client')

/** Every live screen of the inventory: { id, app: 'client' | 'hotel', flow, kind, states }. */
export function liveScreens() {
  const items = []
  for (const app of ['client', 'hotel']) {
    const dir = join(root, 'docs/product/screens', app)
    for (const f of readdirSync(dir).filter((f) => /^\d.*\.json$/.test(f)).sort()) {
      const j = JSON.parse(readFileSync(join(dir, f), 'utf8'))
      for (const s of j.screens) if (!s.deprecated) items.push({ id: s.id, app, flow: j.id, kind: s.kind, states: (s.states ?? []).filter((x) => x !== 'default') })
    }
  }
  return items
}
