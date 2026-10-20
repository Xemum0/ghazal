// Node resolve hook: lets plain `node` import the TypeScript sources of packages/i18n (extensionless relative
// specifiers). Used by tools/export-*.mjs through `register()` in tools/lib/ts-register.mjs.
import { existsSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

export async function resolve(specifier, context, nextResolve) {
  if ((specifier.startsWith('./') || specifier.startsWith('../')) && !/\.[a-z]+$/.test(specifier) && context.parentURL) {
    const base = new URL(specifier, context.parentURL)
    for (const ext of ['.ts', '/index.ts']) {
      const candidate = new URL(base.href + ext)
      if (existsSync(fileURLToPath(candidate))) return nextResolve(candidate.href, context)
    }
  }
  return nextResolve(specifier, context)
}
