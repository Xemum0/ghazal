# Engineering docs

> How Ghazal (غزل) is built: conventions, testing, git, definition of done, agent workflow, environments. Product and design truth live in `docs/product/` and `docs/design/`; settled decisions live in `docs/decisions/` (ADRs 0001-0029). These documents are binding summaries of the engineering ADRs (0020-0029) plus the format and language ADRs (0010-0016). When a document here disagrees with an ADR, the ADR wins and the document is wrong.

## 1. Where the project stands (2026-10-14)

Phase: **design** of the Client app and the Partner app (hotels and halls, plus service providers; app id and screen prefix stay `hotel` / `HL-`), built as an interactive web prototype in `design/`. Business model: the KD 2 voucher marketplace (ADR 0033). Flutter apps and the backend come later. Web dashboards are context only.

Exists and runs: the pnpm workspace (`design`, `packages/design-tokens`, `packages/i18n`, `packages/contracts`), `tools/ports.mjs`, `design/scripts/{shots,snap,probe,images}.mjs`, `.claude/` (settings, rules, skills, subagents), 139 inventory screens of which 134 are built (5 are deprecated by ADR 0033). Current gate results and what is next: [STATUS.md](STATUS.md). Not started: `apps/`, `.github/`, `infra/`, Biome, lefthook, commitlint (deferred by ADR 0031). Git has no commits yet (branch `master`; baseline commit is an owner decision, OQ-T-07).

> The table that used to be here (what "lands later") is obsolete; ADR 0031 narrowed the birth criteria and the foundation work landed in the working tree.

## 2. Reading order

1. `AGENTS.md` (entry point, hard rules).
2. `docs/product/00-source-digest.md`, then `docs/design/00-brief.md`.
3. The ADRs your task names in `docs/decisions/`.
4. This folder: [conventions](conventions.md) first; then the one document for your kind of work (below).
5. Originals only for deep detail: `project.md` and `Ghazal_PRD_EN.pdf` (read-only). Never `BookingSaaS v2.3 Nulled.rar`: it is pirated software, git-ignored, not part of the project, and no agent opens it.

## 3. Document map

| Document | Answers | Read it when |
|---|---|---|
| [conventions.md](conventions.md) | one source of truth per thing, naming, TS and Dart style, the formatter contract, fixtures, commit messages | before writing any code, spec or copy |
| [testing.md](testing.md) | the layers, Arabic and English goldens, Kuwait stress fixtures, parity, backend suites, the visual QA loop | before writing a test or running QA |
| [git-workflow.md](git-workflow.md) | the baseline commit, branches, worktrees and slots, PRs, conflicts, releases | before branching, committing or releasing |
| [definition-of-done.md](definition-of-done.md) | checklists for a design screen, a Flutter feature, an API endpoint, and the evidence block | before saying "done" |
| [agentic-workflow.md](agentic-workflow.md) | roles, file ownership, task sizing, verification, stop-and-ask, ports and URLs, token hygiene, failure modes | before running or launching an agent |
| [environments-and-secrets.md](environments-and-secrets.md) | local, staging and prod, ports, variables, secret inventory, CI bindings, owner gates | before touching config, CI or a credential |
| [../../apps/README.md](../../apps/README.md) | the future apps layout and prerequisites before each app starts | before creating anything under `apps/` |

Registries named by the ADRs. Created 2026-10-12 and live now: [STATUS.md](STATUS.md) (phase, active owners, token-freeze flag), [ownership.json](ownership.json) (authoritative role to write-glob map; not yet enforced), [generated-files.md](generated-files.md) (every generated file and its generator), [requests.md](requests.md) (append-only requests for a token, component or dependency). To be created by the foundation PR or later: `ownership.md` (pointer), `cost.md` (pricing-calculator result, OQ-T-05). ADR 0026 also names `secrets.md` for rotation; rotation is in [environments-and-secrets.md](environments-and-secrets.md) section 5 instead.

## 4. Stack, pinned

> Update 2026-10-14: ADR 0031 relaxed the JS toolchain to what runs here: `engines.node >=22`, `packageManager pnpm@10.10.0`, installs are allowed (`pnpm install`). The Node 24 / pnpm 12 pins below are a later chore, nothing may require them yet. The font row is superseded: El Messiri (display), Manrope (English UI), Almarai (Arabic UI) (ADR 0031 addendum). Token tooling is in-house, not Style Dictionary (ADR 0032 D1).

The pins below are the decided targets, not verified facts: no lockfile or `packageManager` field exists yet, local Node is 23.7 and pnpm 10.10 (Flutter 3.47.5 matches), so every JS pin counts as unverified until the foundation PR commits a lockfile. Do not run installs before the owner runs `nvm install 24`.

| Area | Pin |
|---|---|
| Runtime and tooling | Node 24 LTS, pnpm 12.x (via `packageManager`), TypeScript ~6.0, Biome, Stylelint, lefthook, commitlint, gitleaks |
| Prototype | Vite and React 19 in `design/`; Style Dictionary 5.6.x for tokens; intl-messageformat 12; Playwright; axe |
| Mobile | Flutter 3.47.5 / Dart 3.13; iOS 15.0 and Android minSdk 26 (CF-35 awaits owner sign-off); `material_ui` and `cupertino_ui`; Riverpod 3.4; go_router 18; dio 5; ARB through gen-l10n; Alchemist 0.14 |
| Backend | NestJS 12 on Node 24 (recommendation, owner confirms in Week 0: OQ-T-01); Fastify, Zod 4, Drizzle, PostgreSQL 17 with PostGIS, BullMQ, Socket.IO, `jose` |
| Cloud | GCP `me-central1` (to be confirmed), Cloud Run, Cloud SQL, GCS and CDN, Secret Manager, Firebase (FCM, Crashlytics), MyFatoorah |
| Fonts | Cairo (Arabic UI), Poppins (English UI), numeric role in Cairo digits; bundled static subsets, never fetched at runtime |

## 5. Commands (root of the repo; each arrives with the PR that needs it)

> Update 2026-10-14: these exist today: `pnpm install`, `pnpm dev`, `pnpm verify` (no area argument), `pnpm typecheck`, `pnpm lint`, `pnpm lint:css`, `pnpm tokens`, `pnpm tokens:check`, `pnpm i18n:check`, `pnpm contracts:check`, `pnpm shots`, `pnpm -F design build`, `node tools/ports.mjs url|check|who|list design`. Still target only: `specs:check`, `a11y`, Flutter and API gates, `tools/new-adr.mjs`.

```
pnpm install
pnpm -F design dev                         # then: node tools/ports.mjs url design   (prints the URL; tool lands in the foundation PR)
pnpm verify design|flutter|api|all|changed [--fast]
pnpm tokens   pnpm tokens:check   pnpm i18n:check   pnpm specs:check
pnpm shots --screen <id>   pnpm a11y
flutter analyze --fatal-infos   flutter test   flutter test --tags golden,parity
node tools/new-adr.mjs "<title>"           # allocates the next ADR number under a lock
```

**Dev-server URLs are never typed by hand.** The reserved block is 4700-4799 (design studio = offset 0), but the URL is always produced and verified with `node tools/ports.mjs url design` and `node tools/ports.mjs check design`; the server answers `GET /__gz` so a wrong or foreign server is a loud failure. Default ports (for example 5173) belong to other projects on this machine and must never be used or stopped. Today no Ghazal dev server exists: the Vite config with `strictPort`, the `/__gz` plugin and `tools/ports.mjs` arrive with the foundation PR, so nothing of ours listens on 4700-4799 yet and anything answering on a Ghazal URL before then is not Ghazal. Details: [agentic-workflow.md](agentic-workflow.md) section 7 and [environments-and-secrets.md](environments-and-secrets.md) section 2.

## 6. Engineering ADRs at a glance

| ADR | Decides | Status |
|---|---|---|
| 0010 | Western digits, KWD rules, one shared formatter | accepted |
| 0011 | Gregorian primary, Sunday-first weeks, 12-hour Kuwait time | accepted |
| 0012 | Phone, address, identifiers, LTR fields | accepted |
| 0013 | Arabic voice and copy rules | accepted |
| 0014 | RTL mirroring registry, gestures, charts | accepted |
| 0016 | Cairo and Poppins, figures role, display test | accepted |
| 0017 | Motion tokens and the thread | accepted |
| 0019 | Analytics event taxonomy | proposed, needs owner |
| 0020 | NestJS 12 backend | proposed, needs owner (OQ-T-01) |
| 0021 | Monorepo layout, toolchain, reserved ports | accepted |
| 0022 | Flutter architecture and platform floors | accepted (iOS 15.0 floor item awaits owner sign-off, CF-35) |
| 0023 | Design-token pipeline | accepted |
| 0024 | Prototype to Flutter handoff contract | accepted |
| 0025 | Testing strategy and the visual QA loop | accepted |
| 0026 | CI/CD, environments, secrets | accepted |
| 0027 | Payments boundary (MyFatoorah) | accepted |
| 0028 | Authentication and sessions | accepted |
| 0029 | Agentic setup and file ownership | accepted |

Product ADRs 0001-0009, 0015 and 0018 (booking model, granularity, state machine, pricing, deposit, cancellation, navigation, compare, imagery, venue card) are files named `NNNN-<slug>.md` in `docs/decisions/` (for example `0001-booking-model-request-then-pay.md`). Accepted ADRs are not re-litigated; a change is a new ADR.

## 7. Known drift between existing files and the decisions

Fixed on 2026-10-12 (review pass): `AGENTS.md` (token path `packages/design-tokens/src/`, pnpm commands tagged "lands in the foundation PR", money wording per ADR 0010, `docs/engineering/` in read-first, repo map trimmed to files that exist, stop-and-ask, ports rule), `CLAUDE.md` (points at `snap.mjs`), `design/scripts/snap.mjs` (locale `ar`), `.gitignore` (comment fixed; `design/.review/*.mjs` audit scripts are no longer ignored, only images). Still open:

| File | Says | Decision |
|---|---|---|
| `design/scripts/snap.mjs` | no server-identity check | fixed in the interim: it now refuses any local http(s) URL (exit 2) unless `--no-identity`; the real `/__gz` identity check lands with `tools/ports.mjs` (foundation PR) |
| `design/package.json` | name `ghazal-design`, npm lockfile | pnpm workspace member named `design`; `design/package-lock.json` deleted (foundation PR) |
| `design/.review/*.mjs` | six hand-written audit scripts (`audit`, `audit2`, `contrast`, `fm`, `segs`, `segs2`): contrast audit and font metrics | tracked; the foundation PR moves them to `design/scripts/` or retires them; they are not canonical tooling |
| `.gitignore` | lacks `design/.redlines/`, `tools/.locks/`, Flutter build output, key files | additions listed in [git-workflow.md](git-workflow.md) section 8 |
| `docs/research/*` | requirement IDs like `CL-6.5`, bundle id `<prefix>.ghazal` | void; use feature-matrix IDs and ADR 0022 J |

## 8. Owner decisions that gate engineering

Recorded with working assumptions in `docs/product/open-questions.md`. The ones that stop work if unanswered: the baseline commit and the GitHub organisation (OQ-T-07); backend confirmation (OQ-T-01); iOS 15 and Android 8 floors (OQ-T-02); store accounts and the 14-day Play closed test (OQ-T-03); MyFatoorah written answers (OQ-T-04, OQ-B-02); domain and bundle prefix (OQ-T-06); WhatsApp Business verification (OQ-T-08). Full table: [environments-and-secrets.md](environments-and-secrets.md) section 12.

## 9. Changing these documents

Change the ADR first (new ADR through `tools/new-adr.mjs`), then the document. Each file stays focused (about 80 to 300 lines), concrete and Kuwait-specific, cites requirement IDs and ADRs, and has no filler sections. Docs under `docs/engineering/` are integrator-owned; others propose edits through `docs/engineering/requests.md`.
