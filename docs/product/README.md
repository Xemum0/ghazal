# docs/product — index

What Ghazal is, who it is for, what is in and out, every requirement as an ID, every screen, every open decision. Start here; follow the reading order for your task. Phase: **design** of the Client Mobile App and the Venue/Hotel Mobile App (web prototype now, Flutter later). Last updated 2026-10-12. Fixture clock: **NOW = Thu 12 Nov 2026, 4:00 PM, Asia/Kuwait**.

> **Business model changed 2026-10-14 (ADR 0033, [`voucher-model.md`](voucher-model.md)).** Ghazal now sells only a KD 2 voucher; venues, halls and service providers sell and collect everything else. Anything in this file about deposits, balances, commission, payouts, cash, instant booking, cancellation tiers or the nine booking statuses is superseded; the screen inventory JSON and the architecture docs are already rewritten.

## Contents

| File | What it is | Read it when |
|---|---|---|
| [`00-source-digest.md`](00-source-digest.md) | Reconciled digest of `project.md` and `Ghazal_PRD_EN.pdf`; the first 12 conflicts and gaps | You need the PRD in five minutes |
| [`vision.md`](vision.md) | One-sentence vision, the problem, six product bets, success measures mapped to analytics events, business model, non-goals | Before any product or design decision |
| [`personas.md`](personas.md) | Reem, Umm Reem, Fahad, Rima; Hind, Amal, Mahmoud, Khalid, Sara; language and access needs | Before designing a screen or writing a string |
| [`journeys.md`](journeys.md) | The shared seed journey from both apps, 19 edge journeys, status pairs, tap budgets, notification landings | Before wiring a flow or a state |
| [`scope-mvp.md`](scope-mvp.md) | Phases, requirement totals, what this design pass delivers, what is not designed, proposals beyond the PRD | Before adding anything; when asked "is X in scope?" |
| [`voucher-model.md`](voucher-model.md) | **The business model (ADR 0033):** KD 2 voucher, three client paths, request and voucher states, price display, visits and group chat, provider module, money map, owner assumptions | Before anything about booking, money, partners or listings |
| [`voucher-model-changes.json`](voucher-model-changes.json) | Per flow: new, changed and deprecated screen ids with what to do | Before building or changing any screen after the pivot |
| [`glossary.md`](glossary.md) | Arabic and English terms, status vocabulary, Kuwait wedding words, banned phrases, timers | Before writing or reviewing any copy |
| [`open-questions.md`](open-questions.md) | 74 open decisions with working assumptions, "needed by", duplicates map | Before inventing a rule; when the PRD is ambiguous |
| [`screen-inventory.md`](screen-inventory.md) | 110 screens rendered from the JSON, with requirement IDs and coverage; data caveats | Before building or reviewing a screen |
| [`feature-matrix.md`](feature-matrix.md) / [`.json`](feature-matrix.json) | 571 requirements with stable IDs, phase, design scope, notes; conflicts register CF-01 to CF-35 | Whenever you cite or check a requirement |
| [`screens/client/`](screens/client/), [`screens/hotel/`](screens/hotel/) | Per-flow JSON: screens, states, interactions, AR and EN content notes (source of `screen-inventory.md`) | You are implementing the screen |

Neighbours: [`../design/00-brief.md`](../design/00-brief.md) (design mandate) · [`../decisions/`](../decisions/) (ADRs) · [`../research/`](../research/) (five analyst reports) · [`../../AGENTS.md`](../../AGENTS.md) (agent rules) · originals `project.md` and `Ghazal_PRD_EN.pdf` (never edited).

## Reading order

1. `00-source-digest.md`, then `../design/00-brief.md`.
2. `vision.md` and `personas.md`: who and why.
3. `journeys.md`: how the booking really flows, including the failure paths.
4. `scope-mvp.md`: what you may and may not build.
5. `screen-inventory.md`, then the JSON flow file of your screen.
6. `glossary.md` before any string; `open-questions.md` before any new rule.

Shortcuts. **Building a client screen:** inventory, flow JSON, ADR 0007 (navigation), 0018 (cards), 0009 (compare), 0001-0006 (booking and money). **Hotel screen:** inventory, ADR 0008, 0003, 0006 D10. **Copy:** glossary, ADR 0013, 0010, 0011, 0012. **RTL or type:** ADR 0014, 0016, 0017. **Money:** ADR 0004, 0005, 0006, 0027.

## Conventions

- **Requirement IDs** `<APP>-<GROUP>-<nn>` (`CA-BOOK-11`, `HA-CAL-03`, `PL-PAY-02`, `NF-LOC-04`, `MK-SUB-04`, `RM-GCC-01`). IDs are append-only and never reused; the `CL-6.5` and `HT-7.2` notation in `docs/research/*` is void (ADR 0021 D6). **Screen IDs** `CL-<FLOW>-nn` and `HL-<FLOW>-nn` are permanent.
- **Open questions** `OQ-B` (booking), `OQ-L` (localisation), `OQ-T` (technical), `OQ-P` (product), `OQ-V` (voucher model, 16 rows, section 2b). **Conflicts** `CF-nn` in the matrix register.
- **Precedence when documents disagree:** accepted ADR > this folder > `docs/research/*`. The feature matrix is authoritative for requirement IDs and phases; the screen JSON for screen IDs.
- **Never invent scope.** New idea: add a row to `open-questions.md` with a working assumption, then keep moving (`AGENTS.md`).
- Dates are absolute with a weekday; money is shown through the shared formatter (`KD 18,200` / `18,200 د.ك`; `KWD` only on invoices, bank settings and the API); no real brands, people, phone numbers or faces in any example.
- Tags in research and docs: **[V]** verified from a source, **[K]** domain assumption to validate with 5-8 venue managers, **[T]** verified by running a tool, **[PRD]** stated in the PRD, **[Derived]** needed to complete a PRD flow.

## Numbers at a glance

> Counts in this table are the pre-pivot figures. Live figures after ADR 0033: requirements 656 (85 appended), screens 139 ids (110 + 29 new: client 85, hotel 54; 5 of them deprecated), flows 26, ADRs 33, open questions +16 (OQ-V-01..16).

| | |
|---|---|
| Requirements | **571**: client 233, hotel 73, venue web 58, super admin 81, platform 33, non-functional 71, monetization 13, roadmap 9 |
| Phases | MVP-P1 435 · MVP-P2 107 · P3 8 · P4 6 · deferred 15 |
| In this design pass | **326** (client 226, hotel 73, NF 26, MK 1); every client and hotel design-scope line is cited by a screen |
| Screens | **110** (client 70, hotel 40): 76 screens, 24 sheets, 10 tab roots; 66 core, 44 supporting; prototype spine 45 |
| Open questions | **74** (B 25, L 18, T 15, P 16), all open, all with working assumptions |
| ADRs | **29**: 24 accepted, 5 proposed and awaiting the owner (0005, 0006, 0015, 0019, 0020) |

Querying the matrix (run from the project root):

```sh
node -e "const m=require('./docs/product/feature-matrix.json');console.log(m.filter(x=>x.app==='client'&&x.group==='BOOK').map(x=>x.id+' | '+x.phase+' | '+x.text).join('\n'))"
node -e "const m=require('./docs/product/feature-matrix.json');console.log(m.filter(x=>/GAP/.test(x.notes)).length)"   # lines carrying a GAP note: 72
```

## Decisions (ADRs) that shape this folder

Files live in `docs/decisions/` as `NNNN-slug.md`; a link may 404 until its author's file lands. Status as recorded when these docs were written; `docs/decisions/` is authoritative.

| ADR | Decision | Status |
|---|---|---|
| [0001](../decisions/0001-booking-model-request-then-pay.md) | Request-then-pay by default, instant booking as an earned opt-in; no money held before a human says yes | accepted |
| [0002](../decisions/0002-booking-granularity-halls-sessions-sections-channels.md) | Hall × date × session, up to two sections, channels including government halls | accepted |
| [0003](../decisions/0003-booking-status-state-machine.md) | Nine statuses under the PRD six; child objects; the Booking Thread | accepted |
| [0004](../decisions/0004-pricing-engine-and-price-display.md) | Deterministic tier engine, frozen quote, all-in display with units | accepted |
| [0005](../decisions/0005-deposit-balance-and-payment-schedule.md) | 30% deposit, balance at T-14, cash for balance only, KNET-safe flow | **proposed** |
| [0006](../decisions/0006-cancellation-refund-reschedule-policy.md) | Policy templates, 48 h cooling-off, live refund calculator | **proposed** |
| [0007](../decisions/0007-client-app-navigation-and-guest-gating.md) | Five client tabs, Brief as context, guest gating at commit moments | accepted |
| [0008](../decisions/0008-hotel-app-navigation-and-request-triage.md) | Five hotel tabs, Needs-you inbox, Accept in two taps with Undo | accepted |
| [0009](../decisions/0009-compare-ux-390px.md) | Anti-nag tray, fluid thirds, differences-only | accepted |
| [0010](../decisions/0010-numerals-currency-shared-formatter.md) | Western digits, KWD rules, one shared formatter | accepted |
| [0011](../decisions/0011-dates-time-week-calendar-policy.md) | Gregorian primary, Hijri secondary, Sunday-first, 12-hour Kuwait time | accepted |
| [0012](../decisions/0012-phone-address-identifiers-ltr-fields.md) | Phone, address, identifiers, LTR data in RTL | accepted |
| [0013](../decisions/0013-arabic-voice-dialect-gender-copy-rules.md) | Clear modern Arabic with Gulf warmth, gender-neutral | accepted |
| [0014](../decisions/0014-rtl-mirroring-gestures-chart-direction.md) | RTL registry, gesture rules, chart direction | accepted |
| [0015](../decisions/0015-imagery-cultural-sensitivity-policy.md) | Empty rooms only, monogram avatars, per-section policy facts | **proposed** |
| [0016](../decisions/0016-typography-cairo-poppins-figures-display-test.md) | Cairo and Poppins, figures role, display test | accepted |
| [0017](../decisions/0017-motion-principles-and-tokens.md) | Four durations, two curves, one thread | accepted |
| [0018](../decisions/0018-venue-card-anatomy-and-hero-search.md) | Card anatomy and the hero brief card | accepted |
| [0019](../decisions/0019-analytics-event-taxonomy.md) | Analytics event taxonomy | **proposed** |
| [0020](../decisions/0020-backend-framework-nestjs.md) | NestJS 12 on Node 24 (owner confirms in Week 0) | **proposed** |
| [0021](../decisions/0021-monorepo-layout-toolchain-ports.md) | Monorepo, toolchain pins, reserved ports | accepted |
| [0022](../decisions/0022-flutter-architecture-platform-floors.md) | Flutter architecture; iOS 15 and Android 26 floors | accepted |
| [0023](../decisions/0023-design-token-pipeline.md) | DTCG tokens to CSS, TypeScript and Dart | accepted |
| [0024](../decisions/0024-prototype-to-flutter-handoff-contract.md) | Component spec and handoff format | accepted |
| [0025](../decisions/0025-testing-strategy-visual-qa-loop.md) | Bilingual goldens and the visual QA loop | accepted |
| [0026](../decisions/0026-ci-cd-environments-secrets.md) | CI/CD, environments, secrets | accepted |
| [0027](../decisions/0027-payments-integration-boundary-myfatoorah.md) | Server-side MyFatoorah, webhook plus re-query, ledger | accepted |
| [0028](../decisions/0028-authentication-sessions-step-up.md) | Backend JWT sessions, WhatsApp OTP, step-up | accepted |
| [0029](../decisions/0029-agentic-development-setup-file-ownership.md) | AGENTS.md, rules, skills, hooks, file ownership | accepted |

## Research behind the ADRs

[`../research/journeys-ia.md`](../research/journeys-ia.md) (personas, IA, screen inventory; its persona names are superseded, see `personas.md`) · [`kuwait-localization.md`](../research/kuwait-localization.md) (culture, Arabic voice, RTL, seed content) · [`booking-payment-logic.md`](../research/booking-payment-logic.md) (booking, pricing, payments, data model) · [`competitive-ux.md`](../research/competitive-ux.md) (patterns and verdicts) · [`flutter-tech-handoff.md`](../research/flutter-tech-handoff.md) (stack, handoff, agent setup). Where a research file and an ADR disagree, the ADR wins.

## Who edits what

`vision`, `personas`, `journeys`, `scope-mvp`, `glossary`, `open-questions`, `README`: the product-docs author; anyone may append a row to `open-questions.md`. `screen-inventory.md`: generated, never edited by hand. `feature-matrix.*`: edited as a pair, IDs append-only. `screens/**/*.json`: the screen-spec authors. `00-source-digest.md`: updated by whoever resolves a conflict, originals untouched. When you change a decision, add an ADR; do not rewrite history in this folder.
