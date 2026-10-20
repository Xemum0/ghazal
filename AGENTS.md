# Ghazal (غزل) — Agent Guide

Wedding marketplace for Kuwait (GCC later). Ghazal sells clients one thing in the app: a **KD 2 voucher** (coupon) that lets them request a hall or wedding service at a lower, voucher price. Everything else (price, contract, payment) is between the client and the venue or provider, **off-app**. Partners pay Ghazal advertising or listing fees (major hotels exempt; rates set in Super Admin, not decided yet). Source of truth: ADR 0033, ADR 0035 (owner round 1) and `docs/product/voucher-model.md`.

Two mobile apps: **Client app** (`com.ghazal.client`) and **Partner app** (`com.ghazal.provider`) (hotels and wedding halls, plus service providers; the app id and screen prefix stay `hotel` / `HL-`). Web Super Admin and Venue dashboards are context only.
Current phase: **design**. A Vite + React + TypeScript prototype in `design/` is the specification the Flutter apps will be built from. No backend or Flutter code exists yet (`apps/` is empty); the backend will be NestJS (ADR 0020 accepted by ADR 0035).

> Single source of agent instructions; `CLAUDE.md` imports it. Verified against the repo on 2026-10-20.

## What exists today
- pnpm workspace: `design/` (the prototype), `packages/design-tokens`, `packages/i18n`, `packages/contracts` (types, pricing engine, bilingual fixtures), `tools/ports.mjs`.
- Prototype front door (bare URL): the **Launcher**, one phone with a Client | Partner switch and the EN | AR toggle. Studio views are reached only by explicit hash routes: `#/canvas/<app>`, `#/play/<app>/<id>`, `#/system/<page>`, `#/docs/<name>`; chromeless harness routes `#/gallery/<name>` and `#/frame/<id>`.
- Screen inventory: 140 screens (85 client, 55 partner; 5 deprecated) in `docs/product/screens/**`; 135 are built under `design/src/screens/`. Live numbers: `docs/engineering/STATUS.md`.
- Docs: 665-item feature matrix, ADRs 0001-0035, `docs/product/owner-decisions.md` (what only the owner can decide).
- Typefaces: El Messiri (display), Manrope (English UI), Almarai (Arabic UI), self-hosted (ADR 0031 addendum).

## Read first
1. `docs/product/voucher-model.md` and ADR 0033 (the business model); `docs/product/00-source-digest.md` (older PRD digest, parts superseded).
2. `docs/design/01-direction.md` (binding visual direction), `docs/design/content-guidelines.md`, `docs/design/seed-rulebook.md`, `docs/product/glossary.md`.
3. `design/README.md` (routes, add-a-screen procedure, gates) and `docs/engineering/screen-agent-brief.md` (rules for screen agents).
4. `docs/decisions/` — only `accepted` ADRs bind; `proposed-needs-owner` ones are working assumptions: build as configuration, never present as final. Challenge an ADR with a new ADR, not by deviating.
5. Read-only originals: `project.md`, `Ghazal_PRD_EN.pdf`.

## Commands (repo root)
```
pnpm install                          # Node 23.7 / pnpm 10.10 work; ADR 0031 relaxed the ADR 0021 pins (engines node >=22)
pnpm dev                              # = pnpm -F design dev (Vite, reserved port, strictPort)
node tools/ports.mjs url design       # the only way to get the URL; check = identity probe of /__gz; who = port owner; list = all services
pnpm verify                           # typecheck + lint + tokens:check + i18n:check + contracts:check
pnpm typecheck | pnpm lint | pnpm lint:css | pnpm tokens | pnpm tokens:check | pnpm i18n:check
pnpm contracts:check                  # fixture freshness + `pnpm -F @gz/contracts validate` (the 16k checks)
pnpm -F design build                  # tsc + vite build
pnpm shots --screen CL-BOOK-05 --lang both --w 390 360      # also --route gallery:core, --state, --full, --url-hash
node design/scripts/snap.mjs <file.html> <out.png> --lang ar   # file:// explorations only
node packages/i18n/scripts/new-namespace.mjs client-booking    # new i18n namespace pair
```
Not available yet: a11y gate, specs:check, Flutter and API gates (report them "not run", never fake).

## Hard rules
- **Never open, extract, run or copy `BookingSaaS v2.3 Nulled.rar`** (pirated; denied in `.claude/settings.json`). The owner should delete it.
- **Never invent product scope.** Every screen or feature traces to a requirement ID in `docs/product/feature-matrix.json` (append-only). New ideas go to `docs/product/open-questions.md`. Filter the matrix, never open it whole: `node -e "const m=require('./docs/product/feature-matrix.json');console.log(m.filter(x=>x.id.startsWith('CA-VCH')).map(x=>x.id+' | '+x.text).join('\n'))"`.
- **Ports.** Reserved block 4700-4799 (design = offset 0, slot via `GZ_SLOT`). Never type a localhost URL or use 5173; use `tools/ports.mjs`. If the page is another project, stop and report the PID and command; never kill it.
- **Bilingual from day one.** Every user-facing string in Arabic (RTL) and English (LTR) through the i18n layer (`useT`, `<T>`); never hand-type a price, date or number into a string. Logical CSS properties only.
- **Tokens are the only source** of colour, space, type, radius and motion (`packages/design-tokens/src/tokens.json`, then `pnpm tokens`). Missing value: ask for a token (below), never inline one.
- **Prototype CSS is a Flutter-translatable subset** (no grid, backdrop-filter, `%`, `rem`, `calc`; sticky only for pinned bars, annotated). Enforced by `pnpm lint:css` (ADR 0024, 0031 D3).
- **Brand:** 3 core colours (Ink, Matte Gold, Soft Rose) plus warm neutrals and a tiny success/danger set; no heavy gradients, glassmorphism, neon, emoji-as-icons or generic AI-template look.
- **No identifiable human faces.** Avatars are monograms; galleries are empty rooms.
- **Money = integer fils** (`{fils, currency}`), formatted only by `useFormat()` / the shared formatter (ADR 0010). English `KD`; Arabic `د.ك` after an LTR-isolated number; `KWD` only on invoices and the API. The Arabic UI word for the voucher is «كوبون» (OQ-V-15).
- **Voucher model:** the KD 2 voucher (no VAT, valid 60 days, tied to one venue or provider) is the only in-app payment for clients; venue money is off-app. After approval the client must confirm within 24 h at the hotel or service or the voucher is **forfeited** (not valid, never returns). **No money refunds:** a client asks support, which may grant an unbound **credit voucher** (60 days, any hall, hotel or service). No deposit, balance, commission, payout, refund-tier or VAT UI. Partner billing is `plan` (weekly/monthly/annual, rates set in Super Admin; show "Rates announced soon", no number) or `contract` (mostly hotels and halls). Staff are invited by email (Resend); calendar sync is by email; videos up to 500 MB (ADR 0035).
- **Accessibility:** WCAG 2.2 AA contrast, 44x44 px targets, visible focus, `prefers-reduced-motion`.
- Don't commit unless asked. Never commit secrets (`.env*`).

## Stop and ask
Stop that part and report when: two accepted ADRs conflict, or an ADR conflicts with the brief; you must edit outside the paths your task names; verification fails three times; a dev server fails the identity check; anything touches credentials, production, spend, DNS, store accounts or the baseline commit (owner only). When the PRD is ambiguous and no ADR covers it, pick the most defensible option, append the question to `docs/product/open-questions.md` and keep moving. Full table: `docs/engineering/agentic-workflow.md` section 6.

## Ownership
Parallel agents touch only the paths their task names (roles: `docs/engineering/ownership.md`, `ownership.json`). Single-writer: `AGENTS.md`, `CLAUDE.md`, `.claude/**`, `tools/**`, `packages/design-tokens/src/**`, `design/src/system/**`, `design/src/shell/**`, lockfile, generated files. To ask for a token, component or dependency, append one line to `docs/engineering/requests.md` with shell `>>`; never `Write` over a shared file, use `Edit`. The integrator answers each request with a status block.

## Repo map
```
docs/product/       voucher-model.md, owner-decisions.md, open-questions.md, feature-matrix.json, screens/<app>/*.json (inventory), glossary
docs/architecture/  stack, data model, state machine, pricing and payments, i18n/RTL, design-to-code
docs/design/        00-brief, 01-direction (binding), content guidelines, seed rulebook
docs/engineering/   STATUS (gates, what is next), conventions, definition-of-done, ownership, requests, screen-agent-brief
docs/decisions/     ADRs and index (README.md)
design/             the prototype: src/{screens,system,shell,gallery,i18n,mock,styles}, scripts/{shots,snap,probe,images}, stylelint/
packages/           design-tokens, i18n (messages/{en,ar}/<ns>.json), contracts (types, engine, seed, fixtures)
tools/              ports.mjs
.claude/            settings.json, rules/, skills/, agents/
apps/               (future) Flutter client_app and partner_app, API
```

## Claude Code project files
Rules (`.claude/rules/`): `screens.md`, `i18n.md`, `tokens.md`, `contracts.md`, `docs.md`; read the one for the area you edit. Skills: `add-screen`, `shots-review`, `rtl-check`, `voucher-model`. Subagents: `design-reviewer`, `rtl-a11y-auditor`, `prd-tracer`.

## Working agreements
- Prefer editing existing files and components over near-duplicates; each screen declares the requirement IDs it covers.
- Verify visually: render, shoot **both** languages, Read the Arabic PNG. Type-checking is not design QA.
