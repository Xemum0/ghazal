// Lazy registries over the file system. One dynamic import per file (import.meta.glob, non-eager): a syntax error or
// throwing import in one gallery page or screen fails only that route, never the Studio or its neighbours.
import { lazy, type ComponentType, type LazyExoticComponent } from 'react'

type Loader = () => Promise<unknown>
type Entry = { id: string; path: string; Component: LazyExoticComponent<ComponentType<any>> }

const galleryFiles = import.meta.glob('../gallery/*.tsx') as Record<string, Loader>
// Screens live in screens/<app>/<feature>/<screenId>.tsx, keyed by file name (the inventory id is canonical, ADR 0031 D5).
// `_components/` holds flow-local pieces, not screens: they must not become registry entries (duplicate keys in the sidebar).
const screenFiles = Object.fromEntries(
  Object.entries(import.meta.glob('../screens/**/*.tsx') as Record<string, Loader>).filter(([path]) => !path.includes('/_components/')),
) as Record<string, Loader>

const baseName = (path: string) => (path.split('/').pop() ?? path).replace(/\.tsx$/, '')

function build(files: Record<string, Loader>): Entry[] {
  return Object.entries(files)
    .map(([path, load]) => ({
      id: baseName(path),
      path,
      // Accept `export default` or, failing that, the single named export that is a component.
      Component: lazy(async () => {
        const mod = (await load()) as Record<string, unknown>
        if (typeof mod.default === 'function') return mod as { default: ComponentType<any> }
        const named = Object.values(mod).find(v => typeof v === 'function')
        if (!named) throw new Error(`${path} has no default export (a React component)`)
        return { default: named as ComponentType<any> }
      }),
    }))
    .sort((a, b) => a.id.localeCompare(b.id))
}

export const galleryPages = build(galleryFiles)
export const screenEntries = build(screenFiles)

// Screen modules by id, for the Studio board: a screen may export `states` (string[], e.g. ['loading', 'empty', 'error']) and the
// canvas then draws one extra frame per state next to the default one. Importing a module is cached, so this costs nothing the
// lazy component would not cost anyway.
const screenLoaders = new Map(Object.entries(screenFiles).map(([path, load]) => [baseName(path).toUpperCase(), load]))

/** The `states` a built screen declares (empty when the screen does not exist or declares none). Never throws. */
export async function loadScreenStates(id: string): Promise<string[]> {
  const load = screenLoaders.get(id.toUpperCase())
  if (!load) return []
  try {
    const mod = (await load()) as { states?: unknown }
    return Array.isArray(mod.states) ? mod.states.filter((x): x is string => typeof x === 'string' && x !== 'default') : []
  } catch {
    return []
  }
}

/** True when a screen file for this inventory id exists (case-insensitive, like `find`). */
export const isBuilt = (id: string): boolean => screenLoaders.has(id.toUpperCase())

/** Exact match first, then case-insensitive (ids are typed by hand in URLs). */
export function find(list: Entry[], id: string): Entry | undefined {
  return list.find(e => e.id === id) ?? list.find(e => e.id.toLowerCase() === id.toLowerCase())
}
