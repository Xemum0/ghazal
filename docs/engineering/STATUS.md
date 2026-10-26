# Status

> Phase, active owners and the token-freeze flag (ADR 0029 D8). Integrator-owned. Read it before acting on a remembered fact. Every number below was produced or read on 2026-10-14.

| Field | Value |
|---|---|
| Date | 2026-10-26 |
| Phase | design: Client app and Partner app (hotels and halls plus service providers; ids stay `hotel` / `HL-`) as a web prototype; Flutter, API and dashboards later |
| Business model | KD 2 voucher marketplace (ADR 0033 accepted; owner round 1 answered 2026-10-20 in ADR 0035: unmentioned items take the prototype assumption; 24 h lapse forfeits the voucher; refund = support-granted credit voucher; no VAT; backend NestJS; bundle ids `com.ghazal.client` and `com.ghazal.provider`). The only in-app client payment is the voucher; partners pay ad fees; venue money is off-app |
| Toolchain | Node 23.7, pnpm 10.10 (ADR 0031 relaxed the ADR 0021 pins; engines node >=22). Installs are allowed |
| Typefaces | El Messiri, Manrope, Almarai (ADR 0031 addendum, owner choice 2026-10-13) |
| Token freeze | off (`pnpm tokens` is the only way to change a token; freezes at design freeze) |
| Design freeze | not reached (needs: display-face reader test, a11y gate, applying owner round 1 to the screens, the open items below) |
| Git | baseline committed 2026-10-20: 4 commits on `master` (docs, workspace, prototype, photo library); the regenerated photo variants are not committed (OQ-T-07 answered) |
| Dev server | `pnpm dev`; URL from `node tools/ports.mjs url design`, verified by `node tools/ports.mjs check design` (port 4700, answered `ok` today). `pnpm shots` starts it when it is down |
| Front door | `#/` is the Launcher: one phone, Client \| Partner switch. Canvas, player, system and docs are explicit hash routes only |

## Flutter build (2026-10-26)

Both apps are built from the prototype and verified headless (ADR 0036, results and deviations in ADR 0037). The design-phase notes below describe the web prototype and stay accurate for it.

| Field | Value |
|---|---|
| Apps | `apps/client_app` (`com.ghazal.client`, 83 screens) and `apps/provider_app` (`com.ghazal.provider`, 51 screens), Flutter 3.47.5 / Dart 3.13.4, mock API in-process or standalone (`docs/engineering/running-the-apps.md`) |
| Tests | 7,805 across packages and apps (client 2,038, provider 1,835, ui 1,439, testing 231, kit 89, mock 78, core 1,986, domain 86, api 23), each suite green when run on its own |
| Contract | 16,612 checks, 0 errors; mock contract test 217 of 217 operations; engine cases 2,170; selector cases 148 |
| Gates | `flutter analyze` clean on both apps, `bash tools/check-dart-rules.sh` ok, `pnpm l10n:check`, `node tools/gen-routes.mjs --check`, `pnpm flutter:edges` (51 of 52 partner screens reachable from the entry screens; the check lists HL-BOOK-02 as unreachable, to be looked at in the simulator pass) |
| Proportions | client 67 of 83 screens under the 0.075 parity bar in both languages, 15 in review with geometry checks, 1 documented above; partner exceptions classified in `docs/engineering/requests.md` |
| Simulator | not yet run: the single pass (iPhone 17e and iPhone 17, standalone mock, journeys J1 to J5) is the last step of `docs/engineering/final-verification.md` |
| Ledger | `docs/engineering/flutter-status.md` |

## Gates (run 2026-10-14)

| Command | Result |
|---|---|
| `pnpm verify` | exit 0 (typecheck + lint + tokens:check + i18n:check + contracts:check) |
| `pnpm typecheck` / `pnpm -F design typecheck` | exit 0 (design, contracts, i18n; strict) |
| `pnpm lint` | exit 0; import cycles: none (748 modules) |
| `pnpm lint:css` | exit 0, **1 warning** (0 errors): `design/src/screens/client/onboarding/CL-ONBD-05.css` line 88 `border: <token> solid <token>` (the `solid` keyword; owner screens-client-onboarding). Before today it was 19: 18 were `@font-face` literals in `design/src/styles/fonts.css`, now exempted in `design/stylelint.config.mjs` |
| `pnpm tokens:check` | 368 tokens, 155 icons, 127 contrast pairs, dist up to date |
| `pnpm i18n:check` | ok: 29 namespaces, 5,177 keys in en and ar, 0 errors, 2 length warnings (`ar/client-services.json clientServicesProfileOfflineVoucher` 1.63x, `ar/hotel-calendar.json hotelCalendarSoftTitle` 1.61x: check they fit) |
| `pnpm -F @gz/i18n test` | 298 tests passed |
| `pnpm contracts:check` | fixtures up to date; 16,244 validation checks, 0 errors, 0 warnings |
| `pnpm -F design build` | exit 0 (tsc + vite); chunk-size warning: main chunk 755 kB, mock chunk 1,208 kB |
| Not run | `a11y` gate, `specs:check`, Flutter and API gates (do not exist yet); display-face reader test; today's browser route sweep and `design/scripts/probe.mjs`; visual review of the 134 screens in this pass |

## What exists

| Area | State |
|---|---|
| Workspace | pnpm workspace: `design`, `packages/design-tokens`, `packages/i18n`, `packages/contracts`; `tools/ports.mjs`; `.claude/` (settings, 5 rules, 4 skills, 3 subagents) |
| Tokens | one source file, in-house generator, CSS / TS / Dart / flat JSON, 155 icons, self-hosted fonts in `design/public/fonts` |
| i18n | `packages/i18n`: formatter (money, numbers, dates, phones), ICU messages in `messages/{en,ar}/<namespace>.json` (29 namespaces), lint, Vitest; React binding in `design/src/i18n` |
| Contracts | `packages/contracts`: types, pricing / availability engine, bilingual seed and generated fixtures (venues, packages with standard and voucher prices, requests, vouchers, visits, listings, chat, reviews) |
| Component system | `design/src/system` (about 158 component files): core (+ brand), inputs, nav, overlays, charts, domain-client, domain-hotel, domain-voucher, domain-visits, domain-provider, domain-filters |
| Prototype | `design/src/shell`: Launcher, device framework, Studio (canvas, player, docs), zustand prototype store |
| Screens | 140 inventory entries (HL-CALN-05 added by ADR 0035, not built), 5 deprecated by ADR 0033 (CL-RVRW-03, CL-RVRW-04, HL-BOOK-05, HL-DCSN-05, HL-GROW-05), so 134 live screens (83 client, 51 partner); 134 built under `design/src/screens/` (16 client flows, 10 partner flows) |
| Tools | `pnpm shots`, `snap.mjs`, `probe.mjs`, `images.mjs`, `check-cycles.mjs`, `tools/ports.mjs` |

## What is missing or open

1. **Review of the built screens.** The screens were built by parallel agents; this pass did not re-review them. Next: `design-reviewer` and `rtl-a11y-auditor` subagents per flow, then fixes.
2. **Open integration requests** (`docs/engineering/requests.md`, "Integrator resolutions 2026-10-14"): tab bar rules for the voucher, visit and provider flows in `design/src/system/nav/tabs.ts` (HIDDEN_SCREENS and flow-to-tab maps), the Launcher resetting the prototype store on each Client/Partner switch, flow-local store slices, fixture gaps (16 venues against 21 in the rulebook, English client names, funnel arithmetic), `apple` and `google` icons, currency position in Arabic prices.
3. **Stray files to clean up (owner of the file decides):** `design/scripts/_ct_tmp.mjs`, `_lib_tmp.mjs`, `_signin_tmp.mjs` (temporary scripts), and a root folder `undefined/` containing `ar/` and `en/` screenshot-style output of a tool called without a path. Not deleted by the integrator.
4. **Stale docs:** `docs/product/screen-inventory.md` (generated before ADR 0033; the screen JSON is authoritative), `docs/design/01-direction.md` money wording, `docs/engineering/definition-of-done.md` interim section (still says pnpm gates "land in the foundation PR"; `pnpm verify` takes no area argument today).
5. **Owner decisions:** `docs/product/owner-decisions.md` (46 items, all decided on 2026-10-20; "Still open for the owner": delete the pirated archive, Kuwaiti reader test and Arabic copy reviewer, legal and tax wording, support staffing and hours). The screens touched by round 1 are listed in `docs/product/owner-round1-changes.json` (29 changed, 1 new); the prototype code and i18n messages still carry the old refund and WhatsApp-staff copy until the screen agents apply it.
6. CSS lint stays warnings-only by ADR 0031; flip `defaultSeverity` to `error` at design freeze.
7. `#/gallery/nav` is wider than a 390 viewport by design; read it at a desktop viewport.

## Next

1. Run the visual review per flow in en and ar at 360 and 390 (skills `shots-review`, `rtl-check`; agents `design-reviewer`, `rtl-a11y-auditor`, `prd-tracer`), and fix findings in the owning flow.
2. Apply the system-owner patch list (tab bar maps, component gaps) and the Launcher state decision; re-run `pnpm verify`.
3. Fixtures consistency pass (fixtures-owner) against `docs/design/seed-rulebook.md`.
4. Apply `owner-round1-changes.json` to the prototype; then design freeze: a11y gate, flip stylelint to errors, tag `design-v1` (baseline commit done).
5. Later chores: Node 24 / pnpm 12 (ADR 0021), specs and redlines (ADR 0024 d5, d6), Dart workspace.
