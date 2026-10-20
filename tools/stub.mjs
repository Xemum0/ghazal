#!/usr/bin/env node
// Placeholder for gates whose owners have not landed yet (tokens, i18n). Exits 0 with an honest note,
// never a fake pass: the line says "not run". Replace the root script when the real tool exists.
const name = process.argv[2] ?? 'gate'
console.log(`[${name}] not run: its owner has not landed yet (see docs/engineering/STATUS.md). Exiting 0 so \`pnpm verify\` stays usable.`)
