# Ownership (design pass)

> Short pointer. The machine-readable source is [ownership.json](ownership.json) (role to write globs, ADR 0029 D7); this table says who owns what **during the design pass** (ADR 0031). Parallel agents touch only the paths their task names. Need something outside them? Append one line to [requests.md](requests.md) with `>>` and work around it locally.

| Path | Owner role | Notes |
|---|---|---|
| `package.json`, `pnpm-workspace.yaml`, `pnpm-lock.yaml`, `tsconfig.base.json`, `.editorconfig`, `.gitattributes`, `.node-version`, `README.md` | workspace-integrator | root configs; only the integrator runs `pnpm install` / `pnpm add` |
| `AGENTS.md`, `CLAUDE.md`, `.claude/**`, `tools/**` | workspace-integrator | `tools/ports.mjs` is the only way to produce or verify a local URL |
| `docs/engineering/**`, `docs/decisions/**` | workspace-integrator | STATUS.md is maintained here; ADRs change by new ADR |
| `design/package.json`, `design/vite.config.ts`, `design/vite/**`, `design/tsconfig.json`, `design/index.html`, `design/stylelint*`, `design/stylelint/**`, `design/scripts/**`, `design/README.md` | workspace-integrator | the harness and its lint |
| `design/src/main.tsx`, `design/src/shell/**` | workspace-integrator; the Studio UI (`shell/studio/**`) and the Device framework (`shell/device/**`) were built by their own agents and are now integrator-maintained | routes `#/gallery/<name>` and `#/frame/<screenId>` and `GzProvider` stay stable; Studio classes use the `gzs-` prefix |
| `packages/design-tokens/src/**` (and `dist/**` when generated) | tokens-owner | single writer; package.json stub is the integrator's |
| `design/src/system/**` (incl. every barrel `index.ts`) | system-owner | single writer. Groups: `core` (+ `brand`), `inputs`, `nav`, `overlays`, `domain-client`, `domain-hotel`, `charts`; each group's gallery sections live in `<group>/gallery/` |
| `design/src/gallery/**` | system-owner (component pages) | one file per page, lazy, default export; the harness placeholder page is retired |
| `design/src/i18n/**` | copy-owner | the React binding (`useT`, `useFormat`, `<T>`, `defineWords` in `words.ts`) |
| `design/src/screens/<app>/<flow>/<INVENTORY-ID>.tsx`, `packages/i18n/messages/{en,ar}/<app>-<flow>.json` | screens-`<app>`-`<flow>` | one file per screen, named by inventory id; one namespace pair per flow |
| `packages/i18n/messages/{en,ar}/common.json`, `packages/i18n/messages/{en,ar}/{client,hotel}-shell.json`, `packages/i18n/src/**` | copy-owner | package.json stub is the integrator's; `messages/allow.json` lint exceptions need a reason |
| `packages/contracts/fixtures/**`, `packages/contracts/src/**`, `design/src/mock/**` | fixtures-owner | package.json stub is the integrator's |
| `docs/product/**`, `docs/design/**`, `docs/architecture/**` | docs-author | |
| `apps/**`, `infra/**` | not started | birth criteria, ADR 0021 D7 |

Never touched by any agent: `BookingSaaS v2.3 Nulled.rar` (denied in `.claude/settings.json`), `project.md`, `Ghazal_PRD_EN.pdf`.

## Update 2026-10-14

- The second app is the **Partner app** (hotels and halls plus service providers, ADR 0033 D7). Roles, paths and ids keep the `hotel` name (`screens-hotel-<flow>`, `design/src/screens/hotel/`, `HL-` ids, `hotel-<flow>` namespaces). Flows today: client auth, booking, bookings, discover, messages, my-wedding, onboarding, payment, planner, profile, reviews-rewards, saved-compare, services, venue, visits, vouchers; hotel access, bookings, calendar, decisions, grow, provider, settings, today, venue, visits.
- `ownership.json` now agrees with this file: `design/src/shell/**`, `design/scripts/**`, `design/vite/**` and the stylelint files belong to the integrator; `design/src/system/**` (and its barrels) stays with the system-owner.
- Claude Code project rules per area are in `.claude/rules/` (`screens`, `i18n`, `tokens`, `contracts`, `docs`); they repeat these boundaries for the agent editing that area.
- Requests are answered in `requests.md` in "Integrator resolutions" blocks (latest 2026-10-14); nothing is enforced by a hook yet.
