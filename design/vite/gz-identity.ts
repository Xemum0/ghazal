// Dev-server identity (ADR 0021 D8): GET /__gz answers { app, slot, rootHash, startedAt } and the page carries
// <meta name="gz-app" content="design">. tools/ports.mjs and design/scripts/*.mjs use it to prove the server is ours.
import type { Plugin } from 'vite'
import { resolveSlot, rootHash } from '../../tools/ports.mjs'

export function gzIdentity(app: string): Plugin {
  const startedAt = new Date().toISOString()
  const body = () => JSON.stringify({ app, slot: resolveSlot(), rootHash, startedAt })
  const handler = (req: { url?: string }, res: { setHeader(k: string, v: string): void; end(b: string): void }, next: () => void) => {
    if (req.url?.split('?')[0] !== '/__gz') return next()
    res.setHeader('content-type', 'application/json')
    res.setHeader('cache-control', 'no-store')
    res.end(body())
  }
  return {
    name: 'gz-identity',
    configureServer(server) { server.middlewares.use(handler) },
    configurePreviewServer(server) { server.middlewares.use(handler) },
    transformIndexHtml: () => [{ tag: 'meta', attrs: { name: 'gz-app', content: app }, injectTo: 'head-prepend' }],
  }
}
