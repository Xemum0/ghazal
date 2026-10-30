#!/usr/bin/env node
// Shim for a Vercel project whose Root Directory is `design`: the build command `node tools/vercel-build.mjs` then runs with the working
// directory design/, where this file is. The real build is tools/vercel-build.mjs at the repository root (it needs packages/, docs/ and tools/,
// so the project must also have "Include source files outside of the Root Directory in the Build Step" switched on).
import { spawnSync } from 'node:child_process'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const real = resolve(dirname(fileURLToPath(import.meta.url)), '../../tools/vercel-build.mjs')
process.exit(spawnSync(process.execPath, [real], { stdio: 'inherit', env: process.env }).status ?? 1)
