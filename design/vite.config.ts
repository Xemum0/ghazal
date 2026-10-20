import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { fileURLToPath } from 'node:url'
import { computePort, repoRoot, HOST } from '../tools/ports.mjs'
import { gzIdentity } from './vite/gz-identity.ts'

const fromRoot = (p: string) => fileURLToPath(new URL(`../${p}`, import.meta.url))

// Port is computed (ADR 0021 D8: 4700 + 10 x slot + offset), never a tool default. strictPort: a busy port fails loudly.
const port = computePort('design')
const server = { host: HOST, port, strictPort: true, fs: { allow: [repoRoot] } }

export default defineConfig({
  plugins: [react(), gzIdentity('design')],
  resolve: {
    alias: {
      '@gz/tokens': fromRoot('packages/design-tokens'),
      '@gz/i18n': fromRoot('packages/i18n'),
      '@gz/contracts': fromRoot('packages/contracts'),
      '@docs': fromRoot('docs'),
    },
  },
  server,
  preview: { host: HOST, port, strictPort: true },
})
