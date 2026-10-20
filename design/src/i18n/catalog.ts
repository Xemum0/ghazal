// Lazy message loading (ADR 0022 E, ADR 0024 D8): one dynamic import per namespace and language, straight from the JSON in
// packages/i18n/messages. Nothing is bundled until a screen asks for it; after one language of a namespace loads, the
// other is fetched in the background so a language switch never waits on the network.
import type { Catalog, Lang, Namespace } from '@gz/i18n'

type Loader = () => Promise<Catalog>

const loaders = import.meta.glob('../../../packages/i18n/messages/*/*.json', { import: 'default' }) as Record<string, Loader>

const PATH = /\/messages\/(en|ar)\/([^/]+)\.json$/
const byKey = new Map<string, Loader>()
for (const [path, load] of Object.entries(loaders)) {
  const m = PATH.exec(path)
  if (m) byKey.set(`${m[1]}/${m[2]}`, load)
}

// React's `use()` reads `status` and `value` off a promise it has been given; setting them once settled means a re-render
// reads the catalog synchronously instead of suspending again (and keeps `use()` unconditional, as the rules of hooks need).
type Tracked = Promise<Catalog> & { status?: 'pending' | 'fulfilled' | 'rejected'; value?: Catalog; reason?: unknown }
type Slot = { promise: Tracked; value?: Catalog; error?: unknown }
const slots = new Map<string, Slot>()

const keyOf = (lang: Lang, ns: string) => `${lang}/${ns}`

/** Starts (or joins) the load of one namespace in one language. */
export function loadCatalog(lang: Lang, ns: Namespace | string): Promise<Catalog> {
  const key = keyOf(lang, ns)
  const existing = slots.get(key)
  if (existing) return existing.promise
  const load = byKey.get(key)
  const promise: Tracked = (
    load
      ? load().then(value => {
          // Warm the other language in the background.
          const other: Lang = lang === 'en' ? 'ar' : 'en'
          if (byKey.has(keyOf(other, ns))) void loadCatalog(other, ns).catch(() => undefined)
          return value
        })
      : Promise.reject(new Error(`i18n: no messages for namespace "${ns}" in "${lang}" (packages/i18n/messages/${lang}/${ns}.json)`))
  ) as Tracked
  promise.status = 'pending'
  const slot: Slot = { promise }
  promise.then(
    value => {
      promise.status = 'fulfilled'
      promise.value = value
      slot.value = value
    },
    error => {
      promise.status = 'rejected'
      promise.reason = error
      slot.error = error
    },
  )
  slots.set(key, slot)
  return slot.promise
}

/** The catalog if it has finished loading, else undefined. Never suspends. */
export const getLoadedCatalog = (lang: Lang, ns: Namespace | string): Catalog | undefined => slots.get(keyOf(lang, ns))?.value

/** The slot for `use()`: React suspends on its promise until the JSON has arrived. */
export const catalogSlot = (lang: Lang, ns: Namespace | string): { promise: Promise<Catalog>; value?: Catalog } => {
  void loadCatalog(lang, ns)
  return slots.get(keyOf(lang, ns))!
}

/** Call early (a screen module, an effect) to avoid a suspense fallback on first render. */
export function preloadMessages(namespaces: ReadonlyArray<Namespace | string>, langs: ReadonlyArray<Lang> = ['en', 'ar']): Promise<unknown> {
  return Promise.all(namespaces.flatMap(ns => langs.map(lang => loadCatalog(lang, ns).catch(() => undefined))))
}
