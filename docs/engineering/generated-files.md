# Generated files

> Every generated file and the generator that owns it (ADR 0021, ADR 0029). Generated files carry a `GENERATED` header and are never hand-edited. Updated 2026-10-13 for the design pass.

| File | Generator | Command | Lands in |
|---|---|---|---|
| `packages/design-tokens/dist/**` (CSS variables, TS, icons, Dart) and `design/src/styles/typography.roles.css` | in-house generator `packages/design-tokens/scripts/build.mjs` from `src/tokens.json` (ADR 0032 D1) | `pnpm tokens` (`pnpm tokens:check` fails on drift) | landed |
| `packages/contracts/fixtures/**` | `packages/contracts/scripts/build.mjs` from `packages/contracts/seed/**` | `pnpm -F @gz/contracts build` (`pnpm contracts:check` = check + validate, part of `pnpm verify`) | landed |
| `packages/i18n/src/generated/namespaces.ts` | `packages/i18n/scripts/check.mjs --write` | `pnpm i18n:check --write` | landed |
| `packages/i18n/dist/**` and `apps/*/lib/l10n/app_*.arb` | per-feature part merge | `pnpm i18n:check` and the merge script | foundation PR |
| `docs/product/screen-inventory.md` | generated from `docs/product/screens/**/*.json` (script lands with the foundation PR); until then edited by hand together with the JSON | n/a | foundation PR |
| `openapi.json` | API emit | `openapi:emit` | Week 2 |
| lockfiles | pnpm | `pnpm install` (integrator only) | foundation PR |
