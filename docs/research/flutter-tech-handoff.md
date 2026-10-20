# Research: Technical feasibility, design-to-code handoff, agentic setup

> Produced by an independent analyst agent during the Understand phase (Oct 2026). Inputs to ADRs in `docs/decisions/`; where this file and an ADR disagree, **the ADR wins**.

## Key insights

- Backend: pick NestJS 12 (Fastify, Zod 4, Drizzle, BullMQ, Socket.IO) and stop debating. One language (TypeScript) covers the API, both React dashboards, the design prototype and the token tooling, so permission matrix, validation schemas, money/format fixtures and OpenAPI-derived types are shared. Laravel's real advantages (spatie RBAC/audit packages, mPDF Arabic PDFs, Filament) are either cheap to replace or void because the PRD fixes React dashboards.
- PRD conflict found and verified locally: the installed/current stable Flutter 3.47.5 (released 2026-08-12) generates IPHONEOS_DEPLOYMENT_TARGET = 15.0, not the PRD's iOS 14+. iOS 14 and iOS 15 run on the identical device list (iPhone 6s and later), so raising the floor to iOS 15 excludes no hardware. Needs an ADR; do not downgrade Flutter to keep iOS 14. Android: Flutter defaults minSdk 24; set 26 explicitly to match the PRD's Android 8+.
- Flutter 3.47 split Material/Cupertino into standalone packages (material_ui 1.6.0, cupertino_ui 1.1.2); the in-framework libraries are formally deprecated in the November 2026 stable. `flutter create` still emits `package:flutter/material.dart`, so a greenfield repo must adopt material_ui from commit one and ban the old imports with a grep gate (the analyzer will not flag them yet).
- Web/Flutter parity traps verified by running code: (a) browsers format `ar-KW` with Eastern Arabic-Indic digits while Dart intl `ar`/`ar_KW` gives Western digits, so the prototype must use `ar` plus `-u-nu-latn`; (b) intl/Chrome treat the Arabic week as Saturday-first, Kuwait design wants Sunday-first, so first-day-of-week must be an explicit config, never a locale default; (c) Poppins has NO tabular figures (no tnum feature, digit '1' advance 350 vs '0' 641), Cairo's digits are tabular by default (all 560), so the brief's tabular-figures requirement forces a numeric font role (Cairo digits) or a different Latin face; (d) letter-spacing and italic must be forbidden for Arabic.
- Contrast gate numbers (computed): Ink #5A4B4F on Matte Gold #D8B26E is 4.12:1, which FAILS 4.5:1 for normal text; gold on Warm Off White is 1.91:1 and gold on Soft Rose 1.68:1. Gold button labels need roughly #4A3C40 or darker (5.23:1); gold-as-text needs about #845F20 or darker to pass on both canvas (5.53) and rose (4.85). Gold must never be the only boundary of an input or selected state (WCAG 1.4.11 needs 3:1).
- The same ARB message strings work verbatim in Flutter gen-l10n and in the web prototype via intl-messageformat 12 (verified identical Arabic six-form plural output: 0 zero, 1 one, 2 two, 3-10 few, 11-99 many, 100-102 other, 103 few). Author copy once as ARB parts under packages/i18n and let both prototype and apps consume it; this kills a whole class of AR/EN drift.
- Token pipeline is feasible but needs guard rails: DTCG 2025.10 is stable (Oct 2025); Style Dictionary 5.6.1 contains handling for 2025.10 colour objects and {value,unit} dimensions and a built-in flutter/class.dart format, but its own docs still say 2025.10 support is incomplete, and the built-in Dart output is plain constants, not ThemeExtensions. Use SD with a custom Dart format, restrict tokens to types actually used (colour, dimension, duration, cubicBezier, fontFamily, fontWeight, number, shadow, typography), pin the version and snapshot-test the generated files.
- Avoid web-only effects through tooling, not prose: a Stylelint config can reject backdrop-filter, mix-blend-mode, filter, clip-path, mask, grid, italic, text-align left/right, physical margin/padding properties, em/rem/vh/vw units and raw colour/space values, with a `flutter-ok:` waiver comment. A Playwright redline export (logical insets + sizes per data-gz-id node, per locale and width) lets Flutter layout-parity tests compare geometry to within 1 dp.
- Agentic setup that works in this repo: CLAUDE.md already imports AGENTS.md (correct); keep AGENTS.md under about 120 lines; move detail into path-scoped `.claude/rules/*.md` (frontmatter `paths:` is the only field Claude Code reads); enforce hard rules with PreToolUse hooks (exit 2 or permissionDecision deny), not prose, because CLAUDE.md is advisory. The .rar rule must be a hook plus a permissions.deny entry. The repo has zero commits, which blocks `isolation: worktree` and diff-based gates until a baseline commit exists.
- Parallel-agent safety is mostly a file-ownership problem: never `Write` over an existing shared file (lost updates), single-writer for lockfiles, generated outputs, route registries, ARB/i18n catalogs, OpenAPI contract and migrations; split registries and catalogs per feature so merges are one-line; give each worktree its own ports, Docker project name, database and screenshot directory; and put one `tools/verify.sh <area>` behind every definition of done.
- Non-code gates threaten the 8-week plan more than code does: Google Play personal accounts need a closed test with 12 opted-in testers for 14 continuous days before production (organisation accounts are exempt), Apple organisation enrollment and Meta WhatsApp Business verification have lead times, MyFatoorah authorize/capture needs account-manager approval and has no webhook for authorize transactions, and KNET is a debit scheme so a deposit 'hold' may not exist. Start all of these in Week 0.
- Performance target (home <= 2 s on normal 4G) is achievable with: one composed home endpoint (<= 30 KB gzip), stale-while-revalidate cache of the last home payload, pre-generated WebP image variants plus a blurhash/thumbhash string per image (not AVIF), a native HTTP stack (cronet_http/cupertino_http via native_dio_adapter) because dart:io HttpClient is HTTP/1.1 only, Cloud Run min-instances=1 in the Doha region, and lazy initialisation of Firebase/FCM after first frame. Measure with a named budget, not a feeling.

## Recommendations

### Backend framework  _(confidence: high)_

NestJS 12.x on Node 24 LTS with the Fastify adapter, TypeScript ~6.0.3, Zod 4 via Nest 12's native Standard Schema `schema` option on @Body/@Query/@Param, Drizzle ORM 0.45.x with hand-written SQL migrations for constraints, PostgreSQL + PostGIS, BullMQ on Redis, Socket.IO (websocket-only) with the Redis adapter, `jose` for JWT/JWKS. OpenAPI 3.0.3 emitted from the Zod schemas via @asteasolutions/zod-to-openapi and committed as packages/contracts/openapi.json. Decide in Week 0 and do not revisit.

*Why:* Single TypeScript language across API + dashboards + prototype tooling gives shared contracts; Cloud Run suits Node's stateless HTTP and WebSocket model better than Laravel's always-on Reverb/Horizon; tsc+Vitest give agents a fast deterministic loop. Gaps vs Laravel (RBAC/audit packages, Arabic PDF) are replaced by about 400 lines of guard + DB-trigger audit and a Chromium PDF service. Fallback if Zod glue costs more than one day: Nest 11 + nestjs-zod (its peer range still excludes Nest 12) or classic class-validator DTOs.

### Monorepo layout  _(confidence: high)_

One repo, two native workspaces side by side: pnpm 12 workspace for TypeScript (design/, apps/api, apps/venue-dashboard, apps/admin-dashboard, packages/design-tokens, packages/contracts, packages/api-client-ts, packages/i18n, packages/config-*) and a Dart pub workspace for Flutter (apps/client_app, apps/hotel_app, packages/ghazal_ui, ghazal_core, ghazal_auth, ghazal_chat, ghazal_api_client, ghazal_testing, ghazal_lints). No Melos/Nx/Turbo at the start. Keep `design/` where AGENTS.md puts it. Move the token source of truth to packages/design-tokens/src and update the AGENTS.md hard rule that still says design/tokens/.

*Why:* Verified locally that pub workspaces work with Flutter 3.47.5 (shared lockfile, intra-workspace deps by name, shared lints package, flutter test passes). pnpm and pub never need to know about each other; a justfile-free set of package.json scripts plus tools/*.sh is enough for a solo engineer and is easiest for agents to discover.

### Flutter platform floors and SDK pin  _(confidence: high)_

Pin Flutter 3.47.5 / Dart 3.13 (pubspec environment `flutter: ">=3.47.5 <3.48.0"`, CI `flutter-version: 3.47.5`). iOS deployment target 15.0 (ADR deviating from PRD iOS 14+). Android minSdk 26 (explicit), compile/target 36, Java 17+. Use material_ui and cupertino_ui standalone packages from day one; ban `package:flutter/material.dart` and `package:flutter/cupertino.dart` imports with a CI grep.

*Why:* Verified: `flutter create` on 3.47.5 sets iOS 15.0 and minSdk 24; iOS 14 and 15 support identical hardware, so no device is lost. Staying on 3.44 to keep iOS 14 buys a stale SDK and Xcode 27 UIScene problems for no real user benefit. Standalone Material avoids a forced migration when the in-framework libraries are deprecated in November 2026.

### Flutter state, routing, data  _(confidence: medium)_

Riverpod 3.4 with hand-written Notifier/AsyncNotifier (no riverpod_generator), riverpod_lint plugin, go_router 18 with per-feature route modules and StatefulShellRoute for tabs, dio 5 with native_dio_adapter (HTTP/2/3), hand-written domain entities with equatable, generated Dart API client confined to packages/ghazal_api_client behind mapper classes, no local database in MVP (HTTP cache + shared_preferences), zero build_runner in the apps.

*Why:* Codegen and build_runner are the main source of merge conflicts and slow loops for parallel agents. Riverpod 3 retries every error by default (200 ms doubling to 6.4 s), which is dangerous for non-idempotent calls, so set a global retry policy. The anti-corruption layer means the weak state of Dart OpenAPI generators (flap 0.0.7, 282 downloads) never reaches UI code.

### Localisation, RTL and numerals  _(confidence: high)_

ARB + gen-l10n (template app_en.arb, output lib/l10n/generated, no synthetic-package option), ARB authored as per-feature parts in packages/i18n/messages and merged by a script, CI check for key parity, placeholder parity and all Arabic plural categories. Western digits by default via a shared formatter in ghazal_core with an Eastern-digit switch applied post-format; prototype uses `ar` with `-u-nu-latn` (never `ar-KW`). Week start Sunday as explicit config. Normalise Arabic-Indic and Persian digits on every numeric/phone/OTP input client and server side.

*Why:* All verified by running intl 0.20.3, Chrome-Intl via Node, gen-l10n and intl-messageformat 12. `synthetic-package` now prints 'no longer has any effect'. Browser ar-KW defaults to Eastern digits, Dart does not; both treat Arabic weeks as Saturday-first.

### Fonts and typography handoff  _(confidence: high)_

Bundle static, subset fonts (no google_fonts runtime fetch): Cairo instanced to static 400/500/600/700 with slnt=0 and subset to Arabic+Latin (verified 65 KB each) and Poppins Latin subset 400/500/600/700 (verified 14 KB each). Locale-specific families: AR = Cairo only; EN = Poppins with Cairo fallback. Add a `numeric` type role rendered in Cairo digits (tabular by default) for prices, dates, counters, because Poppins has no tabular figures. Emit TextStyle with leadingDistribution: even and explicit px line-heights; Arabic tokens set letterSpacing 0 and never italic.

*Why:* Verified with fontTools on the original Google Fonts files: Poppins GSUB has no tnum/pnum and proportional digits; Cairo VF is 585 KB with a slnt axis (faux-italic risk) and tabular digits. Static instances remove variable-font differences between Flutter and the browser and cut payload to about 316 KB total.

### Design-token pipeline  _(confidence: medium)_

DTCG 2025.10 JSON in packages/design-tokens/src (ref -> sys -> comp tiers, kebab-case paths, dimension/duration as {value,unit}, colour as {colorSpace,components,hex}), separate typography.en/ar files with identical key sets, Style Dictionary 5.6.x with custom formats emitting CSS variables (--gz-*, outputReferences), a typed TS module, and Dart (abstract final constant classes + ThemeExtension GzColors with copyWith/lerp). Add a `tokens:fmt` formatter that fills components from hex, a snapshot test of generated files, an a11y-pairs.json contrast gate, and a drift check in CI.

*Why:* Stable spec, SD already handles the object forms, and the contrast gate would have caught the Ink-on-Gold 4.12:1 failure immediately. Custom Dart output is required because SD's built-in flutter/class.dart yields flat constants, not theme extensions.

### Prototype authoring rules for clean Flutter handoff  _(confidence: medium)_

Author the web prototype in a Flutter-subset of CSS enforced by Stylelint (logical properties, token-only values, no grid/filter/backdrop/blend/clip-path/mask/italic/em/rem/vh/vw, flex + gap only, border-box, px integers on a 4-pt grid). Every component root carries data-gz and every measured node data-gz-id; a Playwright script exports redlines per screen x locale x width (insetStart, insetTop, w, h, text style token) and component specs live as JSON next to the screens with requirement IDs, states, motion tokens, a11y and RTL mirror lists. Flutter parity tests read the redlines and compare rectangles within 1 dp for the hero screens.

*Why:* Prose rules do not survive parallel agents; a linter and a geometry check do. Logical (start-based) inset measurement makes AR and EN comparable without special-casing mirroring.

### Motion mapping  _(confidence: high)_

Define motion tokens as durations (120/200/320/480 ms), cubic-bezier easings (exact Flutter `Cubic(a,b,c,d)`) and spring physics as numeric tokens (mass, stiffness, damping) used identically by the `motion` library in the prototype and by SpringDescription in Flutter. Do not use duration/bounce spring parameters. Map prefers-reduced-motion to MediaQuery.disableAnimationsOf, shared element transitions to Hero with a tag convention hero:venue:{id}:cover, stroke-dashoffset draw-on to PathMetric.extractPath, and add a haptic column (selection/light/medium/success) that only mobile uses.

*Why:* Cubic-bezier and the damped-spring model are the two places where web and Flutter are mathematically identical, so mapping them exactly gives believable parity; everything else (View Transitions, scroll-linked CSS, blur) is not cheap to reproduce.

### Golden and integration testing  _(confidence: medium)_

Alchemist 0.14.1 with a ghazalGoldenTest helper that expands every case over locale (ar,en) x width (360,390,430 for screens, 390 for components) x text scale (1.0, 2.0). Run Ahem-based CI goldens on Linux as the layout gate and keep a small set of real-font platform goldens generated on macOS for human review. Use integration_test for in-app flows and Patrol 4.10 only for native dialogs (permissions, notifications, biometrics). Run emulator/simulator suites nightly and before release, not per PR.

*Why:* Alchemist CI mode replaces glyphs with Ahem squares, which is good for geometry but useless for Arabic shaping, so real-font goldens must exist separately. Per-PR device suites cost minutes a solo owner cannot afford.

### CI/CD, environments, secrets  _(confidence: medium)_

GitHub Actions with path-filtered workflows (design, api, flutter, contracts), trunk-based development, squash merges and Conventional Commits scoped by package (commitlint + lefthook, gitleaks pre-commit and in CI). GCP via Workload Identity Federation, no JSON keys, Secret Manager per environment project (ghazal-staging, ghazal-prod), Cloud Run revisions deployed with no traffic, smoke tested, then shifted; migrations as a Cloud Run Job before the shift. Mobile releases from tags (client-app/vX.Y.Z+N) via Fastlane to TestFlight and the Play internal track. Terraform/OpenTofu only for foundations (projects, WIF, Artifact Registry, Cloud SQL, buckets, secret stubs).

*Why:* Smallest set that gives reproducible deploys without click-ops. Mobile public config goes through --dart-define-from-file; no secret ever ships in an app binary. Local machine already has gcloud, terraform, firebase, docker, java 21; it lacks gh, gitleaks, fastlane, playwright browsers.

### Agent instructions, rules, skills, subagents, hooks  _(confidence: high)_

Keep AGENTS.md as the single source (CLAUDE.md only imports it), add Stack/Commands/Definition-of-done/Ownership/Generated-files sections, create about 9 path-scoped rules, 8 skills (verify, add-screen, add-token, add-flutter-component, shots, handoff-screen, i18n-add-string, adr; release-mobile as manual-only), 5 subagents (design-qa, a11y-auditor, rtl-reviewer, prd-tracer, handoff-checker; plus worktree-isolated implementers once code exists), and 4 hooks (PreToolUse guard, PostToolUse formatter, Stop fast-verification gate, SessionStart environment banner) with a .mcp.json for `dart mcp-server` and a pinned Playwright MCP.

*Why:* Docs confirm CLAUDE.md is advisory and hooks are the enforcement layer; path-scoped rules cut context cost; AGENTS.md should stay under about 200 lines. Dart's MCP server is available locally (analyze_files, run_tests, launch_app, hot_reload, get_runtime_errors, widget tree).

### Week-0 non-code gates  _(confidence: high)_

Before any build week starts: (1) decide Apple and Google account type (organisation accounts, D-U-N-S) because a Play personal account forces a 12-tester x 14-day closed test; (2) start Meta WhatsApp Business verification and an Arabic+English authentication template; (3) get MyFatoorah sandbox and written answers on KNET deposit holds, authorize/capture, webhook coverage, refunds; (4) buy the domain and host AASA/assetlinks files; (5) create the three GCP projects and Firebase projects; (6) take a baseline git commit so worktrees and diff gates work.

*Why:* Each has a lead time measured in days to weeks and sits on the critical path to the Week-8 store submission; none can be compressed by writing code faster.

## Risks & gaps

- PRD says iOS 14+; current Flutter forces iOS 15 (verified). Needs owner sign-off and a digest entry (new conflict #13). Android 8+ (API 26) vs Flutter default 24 (#14).
- NestJS 12 is about three months old and ESM-only: nestjs-zod 5.5.0 peers only Nest 10/11, @nestjs/swagger 12 peers TypeScript ^5.5||^6 (not 7, which is npm latest at 7.0.2) and typescript-eslint peers TypeScript <6.1. Pin TypeScript ~6.0.3, avoid nestjs-zod, time-box the Zod/OpenAPI glue to one day with Nest 11 as the fallback.
- Dart OpenAPI generation is the weakest link: openapi-generator dart-dio is 'stable' but built_value is the default serializer and json_serializable is beta; native-Dart generators (flap 0.0.7, openapi_flutter_gen) are immature. Emit OpenAPI 3.0.3 (dart-dio documents no 3.1 support), isolate the generated client in its own package behind mappers, and re-run generation in CI.
- Style Dictionary documentation says DTCG 2025.10 support is incomplete even though v5.6.1 code handles colour/dimension objects; unknown composite handling (typography, shadow) must be tested on day one. Fallback is a 150-line in-house generator.
- Riverpod 3 offline persistence and mutations are still marked experimental; automatic retry of every error by default is a correctness hazard for payment/booking calls.
- Material/Cupertino standalone packages release weekly (material_ui 1.6.0, cupertino_ui 1.1.2 on 2026-10-06); third-party widgets that expose Material types cause type-mismatch errors (the compatibility bridge fixes theme/localisation context only). Prefer packages that do not expose Material types and pin versions.
- KNET is a debit scheme: there may be no pre-authorisation, so 'confirm then pay deposit before approval' (PRD gap #8) may force request-then-pay (venue approves, then payment link) or instant-pay-then-refund. MyFatoorah authorize/capture needs account-manager approval and lacks webhooks for authorize transactions (per its docs).
- Budget: PRD estimates $20-100/month for cloud. Cloud SQL alone is about $8 (db-f1-micro) to $26 (db-g1-small) per month in us-central1 list pricing (me-central1 is higher, shared-core has no SLA, HA roughly doubles it); Memorystore Redis, an external load balancer for Cloud CDN, a min-instance API and a separate realtime service each add a fixed line. The ceiling holds only pre-launch. Verify with the pricing calculator before promising it.
- Arabic invoice PDFs are not in the PRD's technical plan but are a requirement (booking flow ends in Invoice). In-process Node PDF libraries do poor Arabic shaping; plan a Chromium (Playwright) renderer service or accept a Laravel-style mPDF equivalent.
- Poppins lacks tabular figures, so the brief's tabular-figures rule cannot be met in English UI with Poppins alone; a numeric role in Cairo (or another face) is required and must be designed, not patched.
- Gold-on-canvas (1.91:1), gold-on-rose (1.68:1) and Ink-on-Gold (4.12:1) all fail common uses; if the design system ships the PRD palette unmodified, labels on gold fills and gold text fail WCAG 2.2 AA.
- Repo has zero commits (branch master), empty .claude/* directories, and AGENTS.md references scripts and docs that do not exist yet (design/README.md, docs/engineering/*, feature-matrix.md, shots.mjs). Until they land, agents cannot verify and worktree isolation fails.
- Local toolchain drift: Node 23.7.0 is an odd (non-LTS, end-of-life) line; Node 24.21 Krypton is LTS and Node 26 reaches LTS later in October 2026. pnpm 10.10 is installed while 12.10.1 is current; Android licences are not accepted and two adb binaries conflict (flutter doctor).
- Play Store personal-account rule (12 testers, 14 days) and Apple organisation/D-U-N-S enrolment can each consume one to three weeks of an 8-week plan.
- Chat on Cloud Run: WebSocket streams are subject to request timeouts (up to 60 minutes, default 5) and session affinity is best-effort, so reconnect, resume-from-sequence and idempotent client message IDs are mandatory, not optional.
- Parallel agents without ownership rules will overwrite shared files (Write on existing files loses concurrent edits), collide on dev-server ports, Docker names, emulators, lockfiles and migration numbers.

## Open questions for the owner

- Do you accept iOS 15 as the minimum (zero hardware lost versus iOS 14) and Android API 26, and will you sign an ADR replacing the PRD's 'iOS 14+'?
- Are the Apple Developer and Google Play accounts personal or organisation accounts? If Play is personal, who are the 12 testers and can the 14-day closed test start by Week 5?
- Does your company have a D-U-N-S number and Kuwait commercial licence for Apple organisation enrolment and Meta WhatsApp Business verification, and has either process started?
- What does MyFatoorah confirm in writing about KNET pre-authorisation, authorize/capture on cards, webhook coverage, partial refunds and Apple Pay merchant setup for your account?
- Is a Cloud spend ceiling of $20-100/month a hard cap pre-launch and post-launch? It determines Memorystore vs a self-run Redis, whether an external load balancer + Cloud CDN is affordable, and Cloud SQL HA.
- Which GCP region do you want (me-central1 Doha is the nearest, but latency to Kuwait was not measured here), and do you need data residency in Kuwait/GCC?
- Which domain will carry universal/app links and the API (needed for apple-app-site-association, assetlinks.json and push deep links), and what is the bundle/application ID prefix?
- Are you personally comfortable maintaining TypeScript plus Dart only (recommended), or do you have deep Laravel experience that would change the backend call? (Only a strong yes should flip it, and only in Week 0.)
- Do you want Arabic-Indic digits ever offered to users (a setting) or Western only? The formatter supports both, the default is Western.
- Is the Kuwait week Sunday-first for every calendar surface, and does 'weekend pricing' mean Friday-Saturday or Thursday-Friday-Saturday? This is venue configuration, not a locale default.
- Who handles Hijri-dependent pricing (Ramadan/Eid seasons) for 'holiday price'? It needs a Hijri conversion source on the backend and dashboards; not in the PRD.
- May agents create a baseline git commit (needed for worktree isolation and diff gates) and may the .rar be moved out of the repo or deleted by you?

---

## Full findings

# Ghazal — Engineering Foundation, Flutter Architecture and Design-to-Code Handoff

Lens: technical feasibility, design-to-code handoff, agentic-coding-ready setup. Everything marked "verified" was checked on 2026-10-10 either by running code on this machine or by reading the cited documentation; anything marked "unverified" is standard practice I did not test. The pirated `BookingSaaS v2.3 Nulled.rar` was not opened or referenced.

## 0. Ground truth snapshot (verified)

**This machine:** Flutter 3.47.5 stable (Dart 3.13.4, DevTools 2.60.0), Xcode 26.6, Android SDK 36.1 (licences not accepted, two adb binaries), Docker 27.5.1, Java 21, jq, rg, terraform, gcloud, firebase CLI, Claude Code 2.1.284. Node is v23.7.0 (an odd, non-LTS line), pnpm 10.10.0 (12.10.1 is current). Missing: gh, gitleaks, fastlane, just, Playwright browsers.

**Repo:** git initialised on `master` with zero commits; `.claude/{agents,rules,skills}`, `apps/`, `design/` are empty; AGENTS.md and CLAUDE.md exist (CLAUDE.md imports `@AGENTS.md`, which is the right pattern); docs contain only `00-source-digest.md` and `00-brief.md`. AGENTS.md references `design/README.md`, `docs/engineering/`, `feature-matrix.md`, `design/scripts/shots.mjs`, `npm run ...` scripts that do not exist yet.

**Current ecosystem (npm/pub latest on 2026-10-10, use as starting pins):**

| Area | Pin |
|---|---|
| Node | 24.21.x LTS "Krypton" (Node 22.23 "Jod" maintenance; 26.11 current, LTS later in Oct 2026) |
| pnpm | 12.10.1 (`packageManager` field auto-switches versions) |
| TypeScript | ~6.0.3 (7.0.2 is npm latest, but `@nestjs/swagger` 12 peers `^5.5 \|\| ^6`, typescript-eslint 8.71 peers `<6.1`) |
| Web | Vite 8.3, React 19.3, Vitest 5.0, Biome 2.5.15, Stylelint 17.16, Playwright 1.64, @axe-core/playwright 4.13, motion 14.1, intl-messageformat 12.1.3, Style Dictionary 5.6.1, sharp 0.35 |
| API | NestJS 12.1.2 (ESM, Node >=20.19/22.12), Zod 4.6.5, @asteasolutions/zod-to-openapi 9.1.0, drizzle-orm 0.45.4 (1.0 RC exists), bullmq 6.3, socket.io 4.8.4, @socket.io/redis-adapter 8.3, jose 6.2, pino 10.4, testcontainers 12.2 |
| Flutter | 3.47.5, material_ui 1.6.0, cupertino_ui 1.1.2, flutter_riverpod 3.4.3, riverpod_lint 3.1.9, go_router 18.0.2, dio 5.11.1, native_dio_adapter 1.8.0, cached_network_image 4.0.4, flutter_svg 2.3.0, intl 0.20.3, alchemist 0.14.1, patrol 4.10.0, google_maps_flutter 2.18.2, geolocator 14.1.1, firebase_core 4.15.0, firebase_messaging 16.7.0, flutter_local_notifications 22.3.1, flutter_secure_storage 11.2.0, local_auth 3.0.2, sign_in_with_apple 8.2.0, google_sign_in 7.2.0, socket_io_client 3.1.6, record 7.1.2, lottie 3.6.1, myfatoorah_flutter 3.3.2 |

Re-run `pnpm outdated` and `flutter pub outdated` monthly; upgrade Flutter quarterly and never mid-build-week.

---

## 1. Backend: NestJS vs Laravel — recommendation: NestJS 12

### 1.1 Decision

**NestJS 12.x on Node 24 LTS**, Fastify adapter (`@nestjs/platform-fastify`), TypeScript ~6.0.3, Zod 4 (validation through Nest 12's native Standard Schema `schema` option, verified in `@nestjs/common` 12.1.2 types: `@Body({ schema })`, `@Query({ schema })`, `@Param({ schema })`), Drizzle ORM 0.45.x, PostgreSQL (+PostGIS, pg_trgm) on Cloud SQL, BullMQ on Redis, Socket.IO 4.8 with `@socket.io/redis-adapter`, `jose` for JWT signing/verification and Apple/Google JWKS, Pino JSON logs, Vitest 5 + Testcontainers.

Decide in Week 0, record as ADR, do not reopen.

### 1.2 Why (decisive reasons, in order)

1. **One language for three of four surfaces.** API, Venue dashboard, Super Admin dashboard, the design prototype and the token tooling are all TypeScript. That lets `packages/contracts` hold the Zod schemas, the permission matrix (`booking:approve`, `pricing:write`, ...), enums such as booking status, the money/rounding helpers and shared test fixtures, imported by the API and by React forms alike. Dart is the only other language. Laravel would add PHP as a third language with nothing shareable except JSON files.
2. **Cloud Run fit for chat and jobs.** NestJS gateways with Socket.IO and the Redis adapter are first-class and stateless; Cloud Run WebSockets work but are HTTP requests with a request timeout (verified: configurable up to 60 minutes, default 5; session affinity is best-effort), so reconnect + resume is part of the design either way. Laravel's real-time (Reverb) and queue (Horizon) story assumes always-on processes, which on Cloud Run means extra services and CPU-always-allocated billing anyway.
3. **Agent feedback loop.** `tsc --noEmit` + Vitest + Biome gives an autonomous agent a deterministic loop in tens of seconds, and Nest's module system gives natural file-ownership boundaries for parallel agents (one module = one directory).

### 1.3 Honest scorecard

| Criterion | NestJS 12 | Laravel 13 | Edge |
|---|---|---|---|
| Language footprint | TS everywhere except Flutter | PHP + TS + Dart | Nest |
| Real-time chat on Cloud Run | Gateways + Redis adapter, websocket-only | Reverb needs always-on host | Nest |
| RBAC | Guard + permission matrix in shared package (~150 lines) | spatie/laravel-permission, one-liner | Laravel |
| Audit log | DB-trigger audit table + interceptor (~200 lines) | spatie/laravel-activitylog | Laravel |
| OpenAPI | Zod -> OpenAPI 3.0.3 (custom glue, ~1 day) | Scramble generates from code | Laravel (slight) |
| Queues/scheduling | BullMQ + @nestjs/schedule | Horizon/Scheduler, more mature | Laravel |
| MyFatoorah | REST wrapper (~200 lines, Zod-validated) | community/official PHP packages | Laravel (slight) |
| Arabic invoice PDF | Needs Chromium renderer service | mPDF handles Arabic shaping | Laravel |
| Admin UI speed | N/A (React dashboards mandated) | Filament would be fastest but PRD says React | tie (void) |
| Ecosystem maturity right now | Nest 12 is ~3 months old, ESM-only; some libs lag | Very stable | Laravel |
| Type-checked verification loop | strict TS | PHPStan/Larastan | Nest |

### 1.4 What we give up and how it is mitigated

- **RBAC/audit packages:** implement `@RequirePermission('x:y')` guard + `TenantGuard` (venue scoping), and a generic Postgres audit trigger writing `audit.log(actor_id, venue_id, table, row_id, op, diff, at, ip, ua)` with the actor passed through `SET LOCAL app.actor_id` inside the request transaction; the audit role has INSERT-only grants. Add a tenant-isolation test generated from the route list (venue A staff cannot read venue B resources). Consider Postgres RLS on `bookings`, `calendar_blocks`, `offers`, `conversations` as a second layer once the first two weeks are done.
- **Arabic PDF:** separate Cloud Run service `ghazal-pdf` (Playwright Chromium, 2 GiB, concurrency 1-2, scale to zero) rendering a bilingual HTML invoice template; cache by content hash in GCS. Do not use pdfmake/pdf-lib for Arabic.
- **Nest 12 ecosystem lag (verified):** `nestjs-zod` 5.5.0 peers `@nestjs/common ^10 || ^11`, so do not use it with Nest 12; use the native `schema` option. `@nestjs/swagger` 12.0.2 peers TypeScript `^5.5 || ^6` and requires class-validator/class-transformer peers, so skip it and build the OpenAPI document from Zod. Time-box the glue to one day. **Fallback:** Nest 11 + nestjs-zod + @nestjs/swagger, or classic class-validator DTOs; both keep the rest of this document valid.

### 1.5 Flip condition (only one)

If the owner has shipped Laravel in production and will write most backend code personally without agent help, **or** decides the two dashboards become Filament (not React), Laravel wins on speed. Anything else: NestJS. This must be answered in Week 0.

### 1.6 OpenAPI "contract kernel" (the part agents must not improvise)

- `packages/contracts/src/**` exports Zod schemas with `.meta({ id: 'Booking' })`, error codes, permission keys, enums and fixtures.
- `apps/api/src/common/api.decorator.ts` exports one `@Api({ summary, auth, permissions, params, query, body, responses, errors })` decorator that (a) registers the operation in the zod-to-openapi registry, (b) stores permission metadata for the guard, (c) in dev/test wraps responses in a response-schema validator.
- `pnpm -F api openapi:emit` writes `packages/contracts/openapi.json` as **OpenAPI 3.0.3** (verified that Zod 4 `z.toJSONSchema(s, { target: 'openapi-3.0' })` emits 3.0 `nullable`; openapi-generator's dart-dio documents no 3.1 support). CI fails on drift, runs Spectral, and runs an `oasdiff` breaking-change check against `main`.
- Clients: `packages/api-client-ts` (openapi-typescript + openapi-fetch, types only plus a 30-line wrapper) for dashboards and prototype mock; `packages/ghazal_api_client` (openapi-generator-cli 2.41, generator `dart-dio`, pinned 7.x, Java already required for Android builds) for Flutter. Generated code is committed, marked `linguist-generated`, never hand-edited, and regenerated only by `tools/gen-api-clients.sh`.
- Contract-first stub for early client work: `@stoplight/prism-cli mock packages/contracts/openapi.json` lets the Flutter apps start Week 3 against a mock while the API is still being built.
- WebSocket events are not in OpenAPI: keep `packages/contracts/events/*.schema.json` plus shared JSON fixtures under `packages/contracts/fixtures/chat/*.json` loaded by both the TS and Dart tests (contract tests on both ends).

### 1.7 Backend rules that are specifically Kuwait/Arabic (put in `.claude/rules/api-nestjs.md`)

- **Money:** KWD has 3 decimals (fils). Store integers (`*_fils BIGINT`), send `{ "fils": 1250000, "currency": "KWD" }`, never floats. Commission in basis points with round-half-up to the fils in one shared function with fixtures. Formatting happens only on clients through the shared formatter.
- **Dates:** `event_date` is a `DATE` in `Asia/Kuwait` (UTC+3, no DST); sessions are `TIME` ranges in venue-local time; everything else `timestamptz` UTC. Never convert an event date through the device time zone (travelling couples, expats).
- **Booking uniqueness:** unit is hall x date x session. Partial unique index on `(hall_id, event_date, session_id) WHERE status IN ('pending','approved')` plus `hold_expires_at` for payment holds; creation in a transaction with `SELECT ... FOR UPDATE` on the slot and an idempotency key. If time-range slots are required, add a `tstzrange` exclusion constraint through a hand-written migration (`drizzle-kit generate --custom`). Men/women sections and multiple halls are separate halls, not flags on a venue.
- **Payment state machine:** `pending_payment -> pending_approval -> approved -> completed`, with `rejected | cancelled -> refunded`. Support both modes behind `venue.booking_mode`: (A) request-then-pay (venue approves, payment link valid N hours), (B) instant (pay now, auto-refund on reject/expiry). KNET is a debit scheme; MyFatoorah authorize/capture requires account-manager approval and has no webhook for authorize transactions (per its docs), so never design on card pre-auth until confirmed. Never trust the app's return URL: verify by webhook signature **and** `GetPaymentStatus` re-query; handlers are idempotent; keep an append-only `payment_events` ledger.
- **OTP via WhatsApp:** Meta Cloud API authentication template (Arabic and English), 6 digits, 5-minute TTL, HMAC-hashed at rest, 5 attempts, rate limit per phone + device + IP. Phone normalisation to E.164 `+965` (8-digit numbers, mobiles typically start 5/6/9). App Store review needs a demo login: provide a reviewer phone with a fixed OTP enabled by a production secret flag, nothing hardcoded.
- **Digits:** normalise Arabic-Indic (U+0660-0669) and Persian (U+06F0-06F9) digits to ASCII in every numeric, phone, OTP and amount field server-side (clients do it too).
- **Search:** store `name_norm` columns (strip tashkeel/tatweel, unify أإآ->ا, ى->ي, ة->ه, lowercase Latin) with `pg_trgm` GIN indexes; `area.aliases[]` covers Salmiya/Salmiyah/السالمية, Mishref/Mishrif/مشرف. Nearby uses PostGIS `geography(Point)` + GiST + `ST_DWithin`.
- **Auth:** access JWT 10-15 min (EdDSA/ES256, `kid` rotation), rotating refresh tokens hashed in DB and bound to device id, Apple/Google identity tokens verified against JWKS with `jose`. Account deletion must also revoke Sign in with Apple tokens (Apple requirement; unverified detail) and cascade/anonymise per policy.
- **Chat:** Socket.IO `transports: ['websocket']`, token in handshake `auth` (never the query string), `clientMsgId` UUID for idempotency, server `seq` per conversation, history via cursor REST, resume with `lastSeq`, FCM push when the socket is offline, media via GCS V4 signed URLs (direct from device), voice as AAC (`record` 7.1.2). Run realtime as its own Cloud Run service `ghazal-realtime` with `--timeout=3600 --session-affinity` (best-effort) and Redis adapter.
- **API conventions:** `/v1` prefix, cursor pagination, RFC 9457 problem+json with a stable `code` string (clients map code -> ARB key; the server never sends user-facing prose), `Idempotency-Key` on POSTs that move money or slots, ETag/Cache-Control on public GETs, `@nestjs/throttler` with Redis storage, `@nestjs/terminus` health.
- **Cloud Run:** `min-instances=1` and startup CPU boost for the prod API (cold start would blow the 2 s budget), concurrency 40-80, 512 MiB-1 GiB, bundle with esbuild/Rspack to shorten cold starts. Region: me-central1 (Doha) is the nearest GCP region to Kuwait; latency was not measured, run a quick RTT test from a Kuwait 4G SIM before committing.

---

## 2. Monorepo layout

### 2.1 Tree

```
ghzal/                                  # repo root
├─ AGENTS.md  CLAUDE.md  README.md
├─ package.json                         # pnpm root: scripts only; packageManager pnpm@12.10.1; engines node ^24
├─ pnpm-workspace.yaml                  # explicit list (see below) + catalog: for shared versions
├─ pubspec.yaml                         # Dart pub workspace root (verified working with Flutter 3.47.5)
├─ .node-version (24)  .editorconfig  .gitattributes  biome.json  stylelint.config.mjs
├─ lefthook.yml  commitlint.config.mjs  .env.example
├─ .mcp.json                            # dart mcp-server + pinned Playwright MCP
├─ .claude/                             # settings.json, rules/, skills/, agents/, hooks/
├─ .github/workflows/                   # design.yml api.yml flutter.yml contracts.yml deploy-api.yml release-mobile.yml
├─ docs/{product,design,architecture,engineering,decisions}
├─ design/                              # existing web prototype ("Ghazal Design Studio"): Vite 8 + React 19 + TS 6
│  ├─ src/{system,screens/client/<feature>,screens/hotel/<feature>,shell,mock}
│  ├─ specs/{component.schema.json,screen.schema.json,components/*.spec.json,screens/**/*.spec.json}
│  ├─ scripts/{shots.mjs,redlines.mjs,a11y.mjs}
│  └─ .shots/ .redlines/                # generated, git-ignored per run id
├─ apps/
│  ├─ client_app/                       # Flutter (iOS/Android)
│  ├─ hotel_app/                        # Flutter (iOS/Android)
│  ├─ api/                              # NestJS 12 (+ drizzle/ migrations)
│  ├─ venue-dashboard/                  # React (later)
│  └─ admin-dashboard/                  # React (later)
├─ packages/
│  ├─ design-tokens/                    # DTCG JSON source + Style Dictionary build + contrast gate
│  ├─ contracts/                        # Zod schemas, permission matrix, error codes, openapi.json (generated), fixtures/
│  ├─ api-client-ts/                    # generated TS types + fetch wrapper
│  ├─ i18n/                             # ARB-format message parts, merge script, parity checks, web catalogue
│  ├─ config-tsconfig/                  # base.json node.json react.json
│  ├─ ghazal_lints/                     # Dart shared analysis_options (file must live in lib/)
│  ├─ ghazal_ui/                        # Flutter design system: theme, components, icons font, fonts, motion
│  ├─ ghazal_core/                      # Money, formatters, digits, phone, env, logging, analytics interface
│  ├─ ghazal_auth/                      # token store, refresh interceptor, biometric gate
│  ├─ ghazal_chat/                      # socket client + chat state + shared chat widgets
│  ├─ ghazal_api_client/                # generated (dart-dio), never hand-edited
│  └─ ghazal_testing/                   # golden helpers, pumpGhazal(), fakes, fixtures loader
├─ infra/                               # Terraform foundations, docker-compose.yml, well-known/ (AASA, assetlinks)
└─ tools/                               # verify.sh, check-env.sh, check-dart-rules.sh, i18n tooling, new-adr.mjs
```

### 2.2 Root files (copy-ready)

`pnpm-workspace.yaml`
```yaml
packages:
  - design
  - apps/api
  - apps/venue-dashboard
  - apps/admin-dashboard
  - packages/design-tokens
  - packages/contracts
  - packages/api-client-ts
  - packages/i18n
  - packages/config-tsconfig
catalog:
  typescript: ~6.0.3
  zod: ^4.6.5
  vitest: ^5.0.3
  react: ^19.3.0
  vite: ^8.3.4
```

`pubspec.yaml` (root; verified that `flutter pub get`, `flutter analyze`, `flutter test` work from here)
```yaml
name: ghazal_workspace
publish_to: none
environment:
  sdk: ^3.13.0
  flutter: ">=3.47.5 <3.48.0"
workspace:
  - apps/client_app
  - apps/hotel_app
  - packages/ghazal_ui
  - packages/ghazal_core
  - packages/ghazal_auth
  - packages/ghazal_chat
  - packages/ghazal_api_client
  - packages/ghazal_testing
  - packages/ghazal_lints
```
Every member has `resolution: workspace`. Cross-package deps are `ghazal_ui: any`; no path overrides.

**Shared lints (verified):** `packages/ghazal_lints/lib/analysis_options.yaml` (the file must be under `lib/` or `include: package:ghazal_lints/analysis_options.yaml` fails with include_file_not_found), each member has `include: package:ghazal_lints/analysis_options.yaml`. Contents: `include: package:flutter_lints/flutter.yaml`, rules `always_use_package_imports` (verified firing), `prefer_const_constructors`, `unawaited_futures` (only flags inside async functions), `require_trailing_commas`, `directives_ordering`, `avoid_print`, analyzer `strict-casts/strict-inference/strict-raw-types: true`. Note: `flutter pub get` rewrites each `analysis_options.yaml` once ("Upgrading analysis_options.yaml to exclude build and platform directories"); commit that change. The analyzer does **not** flag `package:flutter/material.dart` yet; enforce with `tools/check-dart-rules.sh`.

TypeScript shared config: `packages/config-tsconfig/{base,node,react}.json` (strict, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`). One root `biome.json` formats and lints TS/JSON/CSS for the whole repo (single tool = single command for agents); Stylelint handles CSS token/logical-property rules; accessibility is checked at runtime by axe on rendered screens rather than static lint.

### 2.3 What lives where (boundaries that agents must respect)

- `packages/design-tokens` is the **only** source of colour/space/type/radius/motion values. It writes generated files into `packages/design-tokens/dist` (css, ts, json) **and** into `packages/ghazal_ui/lib/src/tokens/generated/` (Dart). Both are committed; CI rebuilds and fails on diff. **Reconcile now:** AGENTS.md says tokens live in `design/tokens/`; change that rule to `packages/design-tokens/src/` and make sure no `design/tokens/` directory is created.
- `packages/i18n/messages/{common,client,hotel}/<feature>.<locale>.json` are ARB-format parts; `pnpm -F @ghazal/i18n build` merges them into `apps/client_app/lib/l10n/app_{en,ar}.arb`, `apps/hotel_app/lib/l10n/app_{en,ar}.arb` and a web catalogue for the prototype (all committed, generated, parity-checked).
- `design/` imports `@ghazal/design-tokens`, `@ghazal/i18n`, `@ghazal/contracts` (types/fixtures only). It never imports from `apps/*`.
- `apps/*` import from `packages/*`, never the reverse. `ghazal_ui` knows nothing about the API or auth. `features/*` inside an app do not import another feature's `presentation/` or `data/` (enforced by grep in `tools/check-dart-rules.sh`).
- No Melos, Nx or Turborepo to start (Melos 8.9 exists and sits on pub workspaces; add it only if the Dart package count passes about 10). Cross-toolchain commands live in root `package.json` scripts and `tools/*.sh`.

### 2.4 Local environment fixes to schedule

`nvm install 24 && nvm alias default 24`; `corepack`-free pnpm: with the `packageManager` field pnpm 10 auto-downloads the pinned 12.10.1; `flutter doctor --android-licenses`; remove the Homebrew `android-platform-tools` adb or put the SDK's first on PATH; `brew install gitleaks gh just`; `pnpm exec playwright install chromium`; `npm i -g @openapitools/openapi-generator-cli` is not needed (use the pinned dev dependency).

---

## 3. Flutter architecture (two apps, one design-system package)

### 3.1 Platform floors and SDK policy

- **Pin Flutter 3.47.5 / Dart 3.13** in pubspec and CI. Quarterly upgrades only.
- **iOS 15.0 deployment target.** Verified: `flutter create` on 3.47.5 emits `IPHONEOS_DEPLOYMENT_TARGET = 15.0`, and the Flutter 3.47 notes raise the floor from 13 to 15. PRD says iOS 14+. iOS 14 and iOS 15 support exactly the same hardware (iPhone 6s and later), so no device is excluded. Record as ADR and new digest conflict #13.
- **Android:** Flutter's default `flutter.minSdkVersion` is 24; set `minSdk = 26` explicitly to match "Android 8+" and shrink the test matrix. `compileSdk`/`targetSdk` follow Flutter's 36; NDK 28.2; Java 17+; the 3.44/3.47 notes mention AGP 9 requiring removal of manual Kotlin Gradle plugin configuration.
- **Swift Package Manager is the iOS default** (3.44+); choose plugins that support SwiftPM (check pub.dev scores). Xcode 27 mandates UIScene lifecycle; use the Flutter template's UIScene setup, not a hand-rolled AppDelegate.
- **Material/Cupertino:** use `material_ui` and `cupertino_ui` (standalone 1.x; new projects should use them per the Flutter migration guide). After any `flutter create`, run `dart fix --apply --code=migrate_design_widgets` (verified: the template still imports `package:flutter/material.dart`). `localizationsDelegates: GlobalMaterialLocalizations.delegates` comes from `material_ui` (it includes Widgets and Cupertino delegates); `flutter_localizations` remains needed for `gen-l10n`'s `AppLocalizations`. Avoid third-party widgets whose public API exposes Material types (type mismatch; the `MaterialUiCompatibilityBridge` only fixes theme/localisation context). Pin `material_ui`/`cupertino_ui`: they release weekly.
- **Guardrail script** `tools/check-dart-rules.sh` fails on: `package:flutter/material.dart`, `package:flutter/cupertino.dart`; `Color(0x` or `Colors.` outside `lib/src/tokens/generated/`; `EdgeInsets.only(left|right`, `Alignment.centerLeft|centerRight`, `Positioned(left|right`, `TextAlign.left|right`; string literals passed to `Text(` outside `*_test.dart`/`l10n/generated`; `letterSpacing` in any Arabic-capable style; cross-feature imports.

### 3.2 Packages and layering

| Package | Contents |
|---|---|
| `ghazal_ui` | `buildGhazalTheme(Locale)`, generated tokens (`GzColors` ThemeExtension, `GzSpace`, `GzRadius`, `GzSize`, `GzMotion`, `GzType`), components (`GzButton`, `GzCard`, `GzSheet`, `GzCalendar`, `GzField`, `GzBadge`, `GzSkeleton`, `GzVenueCard`...), icon font (`GzIcons`), fonts, page transitions, haptics, `@Preview` widget previews |
| `ghazal_core` | `Money` (fils, int), `GzFormat` (money/date/number/digits, bidi isolates), `PhoneKw`, `digit_normalizer`, `AppEnv`, logger, analytics interface, `ApiProblem` (RFC 9457 mapping), retry policy |
| `ghazal_auth` | token store on flutter_secure_storage, refresh interceptor with single-flight, biometric gate (local_auth), Apple/Google/WhatsApp-OTP orchestrators, guest-intent resume |
| `ghazal_chat` | socket_io_client wrapper (resume, ack, dedupe), chat notifiers, shared chat UI |
| `ghazal_api_client` | generated dart-dio client (built_value default; `json_serializable` is beta) |
| `ghazal_testing` | `ghazalGoldenTest`, `pumpGhazal`, fake repositories, fixture loader for `packages/contracts/fixtures` |

App structure (both apps): `lib/{main.dart,bootstrap.dart}`, `lib/app/{app.dart,router/app_router.dart,theme/}`, `lib/features/<feature>/{presentation,application,domain,data,<feature>_routes.dart}`, `lib/l10n/`, `test/`, `integration_test/`, `goldens/`, `config/env.{dev,staging,prod}.json`.

Features (also the ownership partition for parallel agents): client = auth, onboarding, home, search, venue, compare, booking, payment, bookings, planner, services, planning (wishlist/budget/checklist/countdown), chat, notifications, reviews, profile (+loyalty). Hotel = today, bookings, calendar, venue_management, offers, analytics, notifications, settings (staff/bank/hours/languages), chat.

**Data flow:** UI -> Notifier (`AsyncNotifier`) -> repository interface (domain) -> repository impl (data) -> generated client DTO -> **mapper** -> hand-written entity (immutable class + `equatable`). The mapper layer is the anti-corruption boundary so the generator can be swapped without touching UI.

### 3.3 State management: Riverpod 3.4, no code generation

- Hand-written `Notifier`/`AsyncNotifier`; `riverpod_lint` 3.x runs through the analyzer plugin system (`plugins: riverpod_lint: <version>` in `analysis_options.yaml`, no custom_lint, no generator needed). Riverpod's offline persistence and mutations are still **experimental**; do not depend on them.
- **Set a global retry policy.** Riverpod 3 retries any error by default, starting at 200 ms and doubling up to 6.4 s. Configure it (check the exact `retry` parameter signature on `ProviderScope`/`ProviderContainer` in 3.4) so only idempotent GETs retry, only on network errors/5xx, max 3; payments, booking creation, OTP and anything with an idempotency key never auto-retry.
- Entities are hand-written (`equatable` 3.0) because Freezed 4.0 and build_runner add merge-conflict and loop cost. The only build_runner use in the repo is regenerating `ghazal_api_client`, outside the apps.
- No local database in the MVP: `dio_cache_interceptor` file store for GET caching, `shared_preferences` for compare tray/onboarding/preferences. Add Drift only if offline chat or offline calendar becomes a requirement (new ADR).

### 3.4 Routing (RTL-aware) with go_router 18

- One `routes.dart` per feature exporting `List<RouteBase>`; `app_router.dart` only composes them (adding a feature = one line = low conflict). Bottom navigation uses `StatefulShellRoute.indexedStack` so each tab keeps scroll/state.
- **Guest gating** with a `redirect` that stores the intended destination (`GuestIntent(booking step N)`) and resumes after login/OTP, because browsing is open but booking/payment/chat are not.
- **RTL transitions:** one `GhazalPageTransitionsBuilder` that reads `Directionality.of(context)` to flip slide direction (24% travel + fade, `motion.duration.slow`, emphasized curve), iOS keeps the Cupertino interactive back swipe (which flips in RTL by itself), Android uses predictive back (`android:enableOnBackInvokedCallback="true"`). Bottom sheets share a spring (`motion.spring.sheet`).
- Typed route helpers are hand-written (`Routes.venue(id)`), not `go_router_builder` (it needs build_runner).
- Deep-link handling uses go_router's built-in platform route information; `app_links` 7.2 only if a link must be handled outside the router.

### 3.5 Localisation: ARB + intl, Arabic plurals, numerals, calendars

Verified by running the code:

- `l10n.yaml`:
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-dir: lib/l10n/generated
output-localization-file: app_localizations.dart
output-class: AppL10n
nullable-getter: false
required-resource-attributes: true
format: true
```
(Do **not** set `synthetic-package`; Flutter 3.47 prints "no longer has any effect and should be removed".) `supportedLocales: [Locale('ar'), Locale('en')]`; `ar_KW` has no distinct intl data, `ar` is used.
- Arabic plural message that generates and runs correctly (0 -> لا ضيوف, 1 -> ضيف واحد, 2 -> ضيفان, 3 -> 3 ضيوف, 11 -> 11 ضيفًا, 100 -> 100 ضيف, 103 -> 103 ضيوف):
```json
"guestsCount": "{count, plural, =0{لا ضيوف} =1{ضيف واحد} =2{ضيفان} few{{count} ضيوف} many{{count} ضيفًا} other{{count} ضيف}}"
```
CLDR categories for `ar`: 0 zero, 1 one, 2 two, 3-10 few, 11-99 many, 100-102 other, 103-110 few, 111 many. The same string, unchanged, produces identical output in the web prototype with `intl-messageformat` 12 (verified), so the prototype and the apps share catalogues.
- **Key naming:** camelCase because gen-l10n turns keys into Dart identifiers: `<feature><Screen><Element>`, e.g. `bookingReviewConfirmCta`. Descriptions and placeholder metadata live in the English part; Arabic parts carry only strings.
- **CI check** (`pnpm -F @ghazal/i18n check`): identical key sets; identical placeholder names/types; every Arabic plural has `one`, `two`, `few`, `many`, `other` (zero optional via `=0`); no Latin letters in Arabic strings except an allow-list (`KWD`, brand names); no hardcoded digits in prose; no leading/trailing spaces; warn when `len(ar)/len(en) > 1.6` for layout review.
- **Numerals:** Dart intl `NumberFormat(..., 'ar')` and `'ar_KW'` produce **Western** digits (`1,234.500`); `ar_EG` produces Eastern. Browsers differ: Node/Chrome `ar-KW` and `ar-SA` produce **Eastern** digits (`١٬٢٣٤٫٥٠٠`), plain `ar` and `ar-AE` Western. Therefore the prototype must use `ar` with `-u-nu-latn` and never a regional tag, and the Flutter formatter implements a `DigitStyle { western, easternArabic }` switch by post-processing the formatted string (`0-9` -> `٠-٩`, `,` -> `٬`, `.` -> `٫`), applied to dates and times as well.
- **Money format:** one `GzFormat.money(Money)` in `ghazal_core`; output is bidi-safe (isolate the whole amount with U+2066/U+2069 or a RLM-controlled sequence so "1,250.000 د.ك" does not scramble in RTL); shared fixtures in `packages/contracts/fixtures/format-cases.json` are asserted by both TS and Dart tests (input fils/date/locale/digitStyle -> expected string).
- **Calendar:** intl's `ar` data says first day of week index 5 (Saturday) and weekend Fri-Sat; Chrome's `ar-KW` weekInfo says Saturday-first too. The design wants **Sunday-first**. Make `week.startDay = sunday` an explicit config value consumed by `GzCalendar` and the prototype; never read it from the locale. What counts as "weekend pricing" is venue configuration from the backend.
- **Input:** normalise Arabic-Indic/Persian digits in a shared `TextInputFormatter` for phone, OTP, guest count, budget and amounts; phone fields render LTR even in RTL layouts.
- Native strings: `ar.lproj/InfoPlist.strings` and `en.lproj` for `NSFaceIDUsageDescription`, location, camera, photo library, microphone; `CFBundleLocalizations` lists `ar`, `en`; Android `resConfigs`/`locales_config.xml` include `ar`, `en`.

### 3.6 Theming from tokens (ThemeData + ThemeExtension)

- Generated Dart (do not hand-edit) provides `abstract final class GzSpace/GzRadius/GzSize/GzMotion`, `GzType.forLocale(locale)`, and `@immutable class GzColors extends ThemeExtension<GzColors>` with `copyWith`, `lerp`, `static const light`. Access via `GzColors.of(context)` extension. Widgets read semantic tokens only (`textPrimary`, `actionPrimaryBg`, `onGold`, `borderSubtle`), never primitives.
- `buildGhazalTheme(Locale locale)`: **explicit** `ColorScheme(...)` built from semantic tokens (do not use `ColorScheme.fromSeed`, M3 tonal palettes would drift off-brand), `useMaterial3: true` with overrides, `splashFactory: NoSplash.splashFactory` and token-driven press feedback (scale 0.98 / 120 ms), `visualDensity: VisualDensity.standard`, `materialTapTargetSize: MaterialTapTargetSize.padded`, `pageTransitionsTheme` with the custom builder, `textTheme` from the locale's typography tokens, `extensions: [GzColors.light, ...]`. Rebuild the theme when the locale changes (typography differs per script). Light theme only for MVP; the sys-colour layer leaves room for dark.
- Every generated `TextStyle` carries `leadingDistribution: TextLeadingDistribution.even` and an explicit height so Flutter matches CSS half-leading; Arabic styles set `letterSpacing: 0`.
- Define `border.hairline = 1` (not 0.5: 0.5 renders un-crisp on 3x iOS); Flutter `BoxDecoration` borders paint inside the box, matching CSS `border-box`.
- Focus ring: 2 px gold-ink ring with 2 px offset drawn outside bounds; give interactive widgets 4 px of paint room or use a `foregroundDecoration` on a padded parent.

### 3.7 Fonts (Cairo, Poppins, display face)

Verified with fontTools on the original Google Fonts TTFs:

- **Poppins has no `tnum`/`pnum` feature** and proportional digits (advance of "1" is 350, "0" is 641 on a 1000 UPM). `FontFeature.tabularFigures()` and CSS `font-variant-numeric: tabular-nums` do nothing for Poppins. **Cairo's digits are all 560 wide (tabular by default).** The brief requires tabular figures for prices/dates/stats, so introduce a `type.numeric.*` role set in **Cairo digits** for both locales (or choose a different Latin face; if a display face is chosen it must expose `tnum`).
- Poppins vertical metrics: ascent 1050, descent -350, lineGap 100 (UPM 1000). Cairo: ascent 1303, descent -571 (about 1.87 natural line height), `USE_TYPO_METRICS` set on both. Because natural line boxes differ so much, always specify line height explicitly in px/multiplier and use `leadingDistribution.even`; do not rely on defaults.
- Cairo VF is 585 KB with `wght` 200-1000 and a `slnt` axis (faux-italic Arabic is a typographic error). **Ship static instances instead:** `fonttools varLib.instancer Cairo-VF.ttf slnt=0 wght=500 -o Cairo-500.ttf --update-name-table`, then `pyftsubset` to Arabic + Latin (`U+0020-007E,U+00A0-00FF,U+0600-06FF,U+0750-077F,U+FB50-FDFF,U+FE70-FEFF,U+200B-200F,U+2010-2015,U+2018-201F,U+2022,U+2026,U+2066-2069,U+20AC,U+2212`, `--layout-features='*'`) -> **65 KB per weight** (400/500/600/700). Poppins Latin subset -> **14 KB per weight**. Total about 316 KB. Weight tokens are limited to 400/500/600/700 so both families have every weight and Flutter's `FontWeight` mapping is trivial. Script it as `tools/fonts/build-fonts.sh` and commit the outputs under `packages/ghazal_ui/assets/fonts/` (the web prototype loads the same files via `@font-face` for pixel-level parity, not `@fontsource`).
- `pubspec.yaml` of `ghazal_ui` declares `fonts:` families `Cairo` and `Poppins` with `weight:` per file; consumers reference `fontFamily: 'Cairo', package: 'ghazal_ui'` (package fonts need the `package` argument). Locale rule: **AR UI = Cairo only** (Latin glyphs inside Arabic text then share Cairo's baseline, which avoids the Latin/Arabic baseline clash the brief warns about); **EN UI = Poppins with `fontFamilyFallback: ['Cairo']`** so Arabic user-generated content (venue names) still renders.
- **No `google_fonts` runtime fetching** (offline, cost, flash of fallback text against a 2-second target).
- Display face: must be OFL/embeddable TTF/OTF, have both scripts or a justified pairing, be ≤ 150 KB per script after subsetting, and be used only at >= 28 px for a few roles. If it lacks `tnum` it does not touch numerals.
- **Arabic typographic rules (enforced in tokens and lint):** `letterSpacing: 0` and no `font-variation`/italic for Arabic (non-zero tracking breaks cursive joining), no `text-transform`, no synthetic bold/italic, sizes ~+1-2 px and more leading than Latin per the brief.

### 3.8 Images, caching and the 2-second home target

Define the budget first: **cold start to first meaningful home content <= 2.0 s p75** on a mid-range Android on 9 Mbps / 100 ms RTT ("normal 4G"), warm start <= 800 ms; also verify once on 1.6 Mbps/150 ms. Instrumentation: Android `reportFullyDrawn()` after first feed paint, a `home_ttfmc` event, `flutter drive --profile` timeline summaries in the nightly job.

- **One composed home endpoint** (`GET /v1/home`) <= 30 KB gzip carrying all rails with image descriptors (`id`, `blurhash`/`thumbhash`, aspect ratio, base URL), not 8 requests.
- **Stale-while-revalidate:** render the last cached home payload instantly, refresh in the background (`dio_cache_interceptor` file store + `Cache-Control`/ETag).
- **Image variants generated at upload** (Cloud Run Job/worker with `sharp` 0.35): widths 320/640/960/1440 as **WebP** (AVIF decoding is device-dependent on Flutter; iOS 14+ and all supported Androids decode WebP), content-hash file names, `Cache-Control: public, max-age=31536000, immutable`, served from GCS through Cloud CDN. Store a 20-30 byte blurhash/thumbhash string per image in the DB for placeholders. Card thumbnails <= 40 KB at 2x.
- **Flutter side:** `cached_network_image` with `memCacheWidth` = 2x display width (decode at display size), `precacheImage` for the first two rows only, fixed `AspectRatio` boxes so nothing shifts, `FadeInImage`-style 200 ms reveal from the blur placeholder, `cacheExtent` tuned, `SliverList` builders.
- **HTTP stack:** `dart:io` `HttpClient` is HTTP/1.1 only. Use `native_dio_adapter` 1.8 (wraps `cupertino_http`/`cronet_http`) to get HTTP/2/3 and system caching on both platforms; HTTP/3 needs the load balancer in front of Cloud Run.
- **Startup hygiene:** minimal `main()`, brand splash with `flutter_native_splash` until first frame, initialise Firebase/FCM/analytics lazily after first frame, preload `SharedPreferences` into a provider override, `--obfuscate --split-debug-info` for release with symbols uploaded to Crashlytics, R8 on.
- **Server side:** Cloud Run min-instances=1 in the nearest region, Redis cache for home/search composition with short TTLs, PostGIS/GIN indexes, `EXPLAIN` budget in CI for the three hot queries.
- **Video:** short muted H.264 MP4 (<= 15 s, 720p) for hero/card loops transcoded by a job; play only on the details screen or after scroll settles; `video_player` 2.14; HLS later if needed.

### 3.9 Maps

`google_maps_flutter` 2.18. Do not mount a live map in lists. Details screen shows a static styled tile (brand-matched, pre-rendered once per venue at upload and stored with the images) plus "Open in Maps" via `url_launcher`; the interactive map appears on a dedicated full-screen route only. Keys are separate per environment and restricted by bundle ID/package + SHA-1; map styling via a JSON style or a cloud map ID. Area selection uses a curated Kuwait areas list (with aliases) instead of Places Autocomplete (cheaper, better UX). Nearby uses `geolocator` 14 (when-in-use permission requested in context) and server-side PostGIS.

### 3.10 Secure storage, biometrics, auth

- `flutter_secure_storage` 11.2: refresh token + device id only. v10 rewrote Android storage on custom ciphers (RSA-OAEP key cipher, AES-GCM) and deprecated `encryptedSharedPreferences`; `resetOnError` is effectively true. Disable Android Auto Backup for the secure-storage preference file (otherwise a restored backup is undecryptable); on iOS the Keychain survives uninstall, so clear it on first launch after install (flag in `shared_preferences`) to avoid ghost sessions.
- `local_auth` 3.0: biometrics only **unlock** the locally stored session or gate high-risk actions (hotel app: refunds, bank info changes); it is never a server credential. Android needs `FlutterFragmentActivity`; `NSFaceIDUsageDescription` localised.
- Sign-in: `sign_in_with_apple` 8.2 and `google_sign_in` 7.2 (new `GoogleSignIn.instance.initialize(...)` API; use `serverClientId`), WhatsApp OTP through the API. Apple requires Sign in with Apple when Google sign-in is offered; account deletion in-app calls the API which also revokes Apple tokens.
- Refresh interceptor with single-flight (one refresh at a time), logout on refresh failure, clear Riverpod caches and the HTTP cache on logout.

### 3.11 Deep links

One link host for both apps with path prefixes: client `https://link.<domain>/c/*`, hotel `https://link.<domain>/v/*`. Host `apple-app-site-association` and `assetlinks.json` from `infra/well-known/` (a static bucket or the API service). iOS Associated Domains entitlement, Android `autoVerify` intent filters per `pathPrefix`. Payment return and push taps use the same HTTPS links; custom schemes only for internal callbacks. Hosted payment pages (KNET/cards) open through `ASWebAuthenticationSession`/Custom Tabs (`flutter_web_auth_2`) with an HTTPS return link; the server decides payment truth.

### 3.12 Push (FCM)

`firebase_messaging` 16.7 + `flutter_local_notifications` 22.3 for foreground display. One Firebase project per environment containing the 4 mobile apps; upload the APNs auth key in the console (never in the repo). Android channels: `bookings` (high), `messages` (high, grouped), `offers` (default), `reminders` (default). Android 13+ `POST_NOTIFICATIONS` is requested at a moment of value (after the first booking request, not on launch). The server localises title/body from the user's saved locale and sends `data.link` as the HTTPS deep link; the hotel app's new-request push uses iOS `interruption-level: time-sensitive` (Critical Alerts need an Apple entitlement, do not plan on it) and sets the APNs `badge` to the pending count. Initialise messaging after first frame.

### 3.13 Payments

Preferred integration (spike in Week 1): **server-created payment** through MyFatoorah, opened via an in-app authentication session with an HTTPS return link; app never holds the account API token. `myfatoorah_flutter` 3.3.2 initialises with an API key in the app (`MFSDK.init(apiKey, MFCountry.KUWAIT, env)`), which is the main reason not to embed it casually; use it only if MyFatoorah confirms a session-based/scoped-token flow for Apple Pay and Google Pay. No card data touches Ghazal (SAQ-A posture, matches the NFR). Booking screens show the payment state from the API; polling + push update the confirmation screen.

### 3.14 Accessibility

- Semantics for every interactive widget (`label` from ARB), `ExcludeSemantics` for decorative imagery, `SemanticsService.announce` for toasts and booking-status changes, logical focus order in RTL, `kMinInteractiveDimension` (48) or 44 minimum targets.
- Text scaling: layouts must not clip at 200% (`MediaQuery.textScalerOf`), goldens at 1.0 and 2.0 for both locales; no fixed-height text containers.
- Motion: `MediaQuery.disableAnimationsOf(context)` maps to prefers-reduced-motion (swap to 0 ms or a 120 ms cross-fade); no loops.
- Contrast is enforced in tokens (section 4.10), not by hand.

### 3.15 Testing strategy

- **Unit:** domain, mappers (fixtures from `packages/contracts/fixtures`), `Money`, digit normalisation, formatter cases, retry policy.
- **Widget/golden:** `alchemist` 0.14.1. Verified behaviour: *CI goldens replace text with colored squares in the Ahem font (platform-agnostic), platform goldens render real text and are OS-specific*. Strategy: (1) Ahem CI goldens on Linux as the layout/geometry gate; (2) a small, curated set of real-font platform goldens generated on macOS for human review (`goldens/macos/`), run locally and in an optional macOS job. Matrix helper in `ghazal_testing`:
```dart
ghazalGoldenTest('venue_card', (variant) => GzVenueCard(...),
  locales: const [Locale('ar'), Locale('en')],
  widths: const [390], textScales: const [1.0, 2.0]);          // components
// screens: widths [360, 390, 430]; file names: venue_card.ar.390.ts1.0.png
```
 Agents can open golden/failure PNGs with the Read tool, so goldens double as a screenshot channel without a simulator.
- **Layout parity** (hero screens only): load `design/.redlines/*.json`, pump the screen at the same size/locale/fixtures, find nodes by `ValueKey('gz:<id>')`, compare `tester.getRect` converted to start-based insets within 1.0 dp.
- **Widget Previewer:** `flutter widget-preview start` (stable in 3.47) with `@Preview` annotations for every component state/locale; preferred over adding Widgetbook (extra dependency) until stakeholder review needs a hosted catalogue.
- **Integration:** `integration_test` (SDK) for in-app flows against a Prism/fake server; **Patrol 4.10** only for native dialogs (permissions, notifications, biometric prompts). Run on emulator/simulator nightly and before release (Android emulator on Linux with KVM, iOS simulator on macOS runner), not per PR.
- **Perf:** nightly `flutter drive --profile` timeline for home cold start and a scroll jank test (frame build/raster p90 < 8 ms on a mid device in profile mode).
- Coverage gate per package (e.g. 70% for `ghazal_core`, `ghazal_auth`, domain/data layers); no coverage gate on pure UI.

### 3.16 Flavors, env and build

Three flavors (dev, staging, prod) x two apps. Bundle IDs `<prefix>.ghazal[.dev|.stg]` and `<prefix>.ghazal.venue[...]`. Public config via `--dart-define-from-file=config/env.<env>.json` (API base URL, Maps key restricted, Sentry/Crashlytics ids). `--dart-define=GZ_LOCALE=ar` is honoured in non-prod flavors only, so agents and testers can force Arabic without changing simulator language. `flutterfire configure` per flavor, outputs committed (not secrets). No secrets in the binary.

---

## 4. Web prototype -> Flutter handoff contract

### 4.1 Principle

The prototype is a **specification that happens to run**. Everything that has a Flutter meaning is expressed in tokens, a constrained CSS subset, and machine-readable specs; anything that cannot be expressed that way does not ship in the prototype.

### 4.2 Token JSON format (DTCG 2025.10) and generator

Spec status: the Design Tokens Format Module 2025.10 is the first stable version (announced 2025-10-28). Verified value shapes: colour `{ "colorSpace": "srgb", "components": [r,g,b], "alpha": 1, "hex": "#d8b26e" }`; dimension `{ "value": 16, "unit": "px" }` (px or rem); duration `{ "value": 200, "unit": "ms" }`; cubicBezier `[x1,y1,x2,y2]`; fontFamily string or array; fontWeight 1-1000; shadow, typography, border, transition, gradient composites; references `"{color.ref.ink.700}"`; forbidden name characters `$ { } .`.

Files under `packages/design-tokens/src/`: `color.ref.tokens.json`, `color.sys.tokens.json`, `space.tokens.json`, `radius.tokens.json`, `size.tokens.json`, `elevation.tokens.json`, `motion.tokens.json`, `typography.en.tokens.json`, `typography.ar.tokens.json`, `breakpoint-less layout.tokens.json` (screen frame, safe areas, gutters).

Example (real values from the PRD palette):
```json
{
  "color": {
    "$type": "color",
    "ref": {
      "ink":   { "700": { "$value": { "colorSpace": "srgb", "components": [0.3529, 0.2941, 0.3098], "hex": "#5a4b4f" } } },
      "gold":  { "500": { "$value": { "colorSpace": "srgb", "components": [0.8471, 0.6980, 0.4314], "hex": "#d8b26e" } } },
      "rose":  { "100": { "$value": { "colorSpace": "srgb", "components": [0.9725, 0.9059, 0.9255], "hex": "#f8e7ec" } } },
      "canvas":{ "50":  { "$value": { "colorSpace": "srgb", "components": [1, 0.9765, 0.9608], "hex": "#fff9f5" } } }
    },
    "sys": {
      "text": { "primary": { "$value": "{color.ref.ink.700}" } },
      "surface": { "canvas": { "$value": "{color.ref.canvas.50}" } }
    }
  },
  "motion": {
    "duration": { "$type": "duration", "base": { "$value": { "value": 320, "unit": "ms" } } },
    "easing":   { "$type": "cubicBezier", "emphasized": { "$value": [0.2, 0, 0, 1] } },
    "spring":   { "$type": "number", "sheet": { "mass": { "$value": 1 }, "stiffness": { "$value": 400 }, "damping": { "$value": 36 } } }
  }
}
```
(Spring values are placeholders to be tuned by the design lens.)

Rules:
- Three tiers: `ref` (raw ramps, never used by components), `sys` (semantic roles: text, surface, border, action, status, scrim), `comp` (component overrides, rarely). Spacing/radius/size are `sys`-level by nature.
- Spacing names are `space.N` where **N x 4 = px** (N = 1,2,3,4,5,6,8,10,12,16 for 4,8,12,16,20,24,32,40,48,64) plus semantic aliases (`space.gutter`, `space.section`). Radius `radius.{xs,sm,md,lg,pill}` = 4/8/12/20/9999. Controls `size.control.{sm,md,lg}`, `size.touch-min` = 44, `size.icon.{sm,md,lg}`.
- Typography: `type.<role>.<size>` (`display`, `title`, `body`, `label`, `numeric`) as DTCG typography composites, **one file per script** with identical key sets; Arabic composites set `letterSpacing: 0`. Line height is a multiplier and a check asserts `fontSize x lineHeight` lands on the 2/4-pt grid.
- Use `$extensions."ghazal"` only for notes (reason added, owner), never for values consumed by generators. Do not use `$extends`, `$ref`, `$root` or gradient/transition composites until the generator tests prove them.
- Colours: authors write `hex`; `pnpm -F @ghazal/design-tokens fmt` fills/validates `components` so the file stays spec-valid. Alpha variants are explicit tokens (`color.sys.scrim.photo`), because CSS opacity on a parent becomes `saveLayer` in Flutter.

**Generator:** Style Dictionary 5.6.1 (`sd.config.mjs`) with `source: ['src/**/*.tokens.json']` and three platforms:
- `css` -> `dist/css/tokens.css` (`--gz-` prefix, `outputReferences: true` so sys tokens reference ref tokens: `--gz-color-sys-text-primary: var(--gz-color-ref-ink-700)`) plus `tokens.ar.css`/`tokens.en.css` scoped by `:lang(ar)` for typography.
- `ts` -> `dist/ts/tokens.ts` (typed `as const` + `TokenPath` union) and `dist/tokens.flat.json` for the redline tool.
- `dart` -> custom format `gz/dart-tokens` writing `packages/ghazal_ui/lib/src/tokens/generated/gz_tokens.g.dart` with references resolved to literals (`Color(0xFFD8B26E)`, `Duration(milliseconds: 320)`, `Cubic(0.2, 0, 0, 1)`, `SpringDescription(...)`), post-processed by `dart format`.

Verified: SD 5.6.1 ships `flutter/class.dart` and handles colour objects (`colorSpace`/`components`) and `{value,unit}` dimensions in `transforms.js`, but its docs state 2025.10 support is "work in progress"; the built-in Dart output is plain constants. Therefore: pin 5.6.x, write the Dart format ourselves, add `tokens:test` snapshot tests of all three outputs, and keep a 150-line fallback generator in mind if composites misbehave.

Gates (`pnpm tokens:check`): rebuild + `git diff --exit-code` on generated files; unused-token report; duplicate-value report; Arabic/English typography key parity; line-height grid; **contrast pairs** (4.10).

### 4.3 Naming conventions

| Thing | Convention | Example |
|---|---|---|
| Token path | dot path, kebab-case segments | `color.sys.action.primary.bg` |
| CSS variable | `--gz-` + path with `-` | `--gz-color-sys-action-primary-bg` |
| Dart token class member | camelCase, `color.sys.` prefix dropped | `GzColors.actionPrimaryBg`, `GzSpace.s4`, `GzMotion.durationBase` |
| Component | PascalCase, Flutter name = `Gz` + name | `VenueCard` -> `GzVenueCard` |
| Component anatomy id | lowerCamel path | `media.fav` |
| Screen id | `<app>.<feature>.<screen>` | `client.booking.review` |
| ARB key | camelCase `<feature><Screen><Element>` | `bookingReviewConfirmCta` |
| Requirement ID | PDF section number with app prefix | `CL-6.5`, `HT-7.2` |
| Hero tag | `hero:<entity>:<id>:<part>` | `hero:venue:42:cover` |
| Redline/golden file | `<screen>.<locale>.<width>.<ext>` | `client.home.ar.390.png` |

### 4.4 Component spec format (JSON next to the screens; schema in `design/specs/component.schema.json`)

```json
{
  "$schema": "../component.schema.json",
  "component": "VenueCard",
  "reqs": ["CL-6.5"],
  "variants": { "size": ["feature", "list", "compact"] },
  "frame": { "width": "fill", "height": "hug", "minWidth": 280 },
  "layout": {
    "id": "root", "dir": "column", "gap": "space.0", "radius": "radius.lg", "clip": true,
    "bg": "color.sys.surface.card", "border": { "w": "border.hairline", "color": "color.sys.border.subtle" },
    "children": [
      { "id": "media", "size": { "w": "fill", "aspect": "aspect.4x3" }, "image": { "fit": "cover", "scrim": "scrim.photo-bottom" },
        "overlays": [
          { "id": "fav",   "anchor": "top-end",      "inset": "space.3", "size": 44 },
          { "id": "badge", "anchor": "bottom-start", "inset": "space.3" } ] },
      { "id": "body", "dir": "column", "pad": { "inline": "space.4", "block": "space.4" }, "gap": "space.2", "children": [
          { "id": "title", "text": "type.title.md", "color": "color.sys.text.primary", "lines": 1, "overflow": "ellipsis" },
          { "id": "meta",  "dir": "row", "gap": "space.3", "text": "type.body.sm", "wrap": false },
          { "id": "price", "text": "type.numeric.lg", "key": "venueCardFrom", "align": "end" } ] } ]
  },
  "states": { "pressed": { "scale": 0.98 }, "loading": "skeleton", "unavailable": { "badge": "status.unavailable" } },
  "motion": [ { "on": "press", "prop": "scale", "to": 0.98, "dur": "motion.duration.fast", "ease": "motion.easing.standard", "haptic": "light" } ],
  "a11y": { "role": "button", "label": "venueCardSemantics", "minTarget": 44 },
  "rtl": { "mirror": ["media.fav", "media.badge"], "noMirror": ["media.playIcon"] },
  "flutter": { "widget": "GzVenueCard", "file": "packages/ghazal_ui/lib/src/components/venue_card.dart" }
}
```
Screen specs (`design/specs/screens/<app>/<feature>/<screen>.spec.json`) list: requirement IDs, route, components used, data fixture, states (loading/empty/error/offline), scroll behaviour (pinned headers, collapse ranges in dp), safe-area use, and ARB keys.

### 4.5 Specifying layout measurements unambiguously

1. **Unit:** 1 px in the prototype = 1 dp in Flutter. Canvas 390 x 844 plus fluid verification at 360 and 430; safe areas are named variables (`--gz-safe-top: 47px`, `--gz-safe-bottom: 34px` for the simulated iPhone), never magic numbers, and Flutter uses real `MediaQuery` insets.
2. **Every container declares:** direction, main/cross alignment, gap (token), padding as **logical** `{ start, end, top, bottom }`, per-axis size mode `fixed(px) | fill | hug | flex(n)` with min/max, overflow (`clip`, `scroll`, or `ellipsis`+max lines).
3. **Prototype CSS subset (Stylelint-enforced):** `display:flex` only (plus `position:absolute` for named overlay anchors using `inset-inline-*`/`inset-block-*`), `box-sizing:border-box` globally, spacing via `gap` (never sibling margins, never negative margins), no percentages (except `flex`), no `vh/vw/dvh/em/rem/ch`, no `calc()`, no `grid`, `aspect-ratio` with named tokens, `object-fit: cover`, integer px values on the 4-pt grid (hairline = 1).
4. **Carousels/pagers** are specified by formula (e.g. item width = viewport - 2 x gutter - peek; peek = `space.6`), identical in CSS and Flutter (`PageController(viewportFraction)` computed from the same formula).
5. **Measurement in redlines is logical:** `insetStart`, `insetTop`, `w`, `h` per `data-gz-id` node (distance from the start edge, so AR and EN are directly comparable), plus the text style token name and line count.
6. **Flutter mappings:** `display:flex` row/column -> `Row`/`Column` (`spacing:` parameter), `flex:1` -> `Expanded`, `flex-wrap` -> `Wrap`, `gap` -> `spacing`, `justify:space-between` -> `MainAxisAlignment.spaceBetween`, logical padding -> `EdgeInsetsDirectional`, anchors -> `PositionedDirectional`, `aspect-ratio` -> `AspectRatio`, `position:sticky` -> pinned `SliverPersistentHeader`.

### 4.6 Motion token mapping (CSS -> Flutter)

| Web | Flutter | Notes |
|---|---|---|
| `cubic-bezier(a,b,c,d)` | `Cubic(a,b,c,d)` | exact |
| `200ms` | `Duration(milliseconds: 200)` | exact |
| `transition: transform ...` | `AnimatedScale/Slide/Container(duration, curve)` or controller | |
| `@keyframes` (<= 3 stops) | `TweenSequence` / `Interval` | |
| stagger `calc(var(--i) * 40ms)` | `Interval(i*40/total, ...)` | cap at 5 items |
| spring `{stiffness, damping, mass}` (motion lib) | `SpringDescription(mass, stiffness, damping)` + `SpringSimulation` | same damped-oscillator model; never use `bounce`/`visualDuration` params |
| shared element (View Transitions / layoutId) | `Hero(tag)` + `flightShuttleBuilder` (radius morph) | tag convention in 4.3 |
| `prefers-reduced-motion` | `MediaQuery.disableAnimationsOf` | use `motion.reduced.*` tokens |
| SVG `stroke-dashoffset` draw-on | `PathMetric.extractPath(0, t * length)` | the brand "thread" motif is cheap this way |
| scroll-linked header | `SliverPersistentHeader`/`ScrollController` | specify as f(scrollOffset dp) |
| gesture-driven sheet | `DraggableScrollableSheet` or custom with spring fling | |
| Lottie | `lottie` 3.6 | author without expressions, effects, blend modes, mattes |
| haptics | `HapticFeedback.selectionClick/lightImpact/mediumImpact` | spec column `haptic`, mobile only |

### 4.7 Web-only effects to avoid (Stylelint + review)

| Avoid | Why | Use instead |
|---|---|---|
| `backdrop-filter` | `BackdropFilter` is an offscreen pass per instance; jank on mid Android; banned by the brief | tonal surface token |
| `mix-blend-mode`, `background-blend-mode` | `saveLayer` + blend; unpredictable on photos | bake into the asset |
| CSS `filter` (blur, drop-shadow, grayscale) | `ImageFiltered` cost | shadow tokens; bake grayscale |
| `opacity` on containers | becomes `saveLayer` | colour alpha tokens; fade only while animating |
| inset shadows, > 2 shadow layers | no inset support | hairline/tonal; <= 2 layers |
| `clip-path`, `mask`, `mask-image` | custom clippers per item are costly | radius tokens; one SVG path (0-1 normalised) for an arch crop if required |
| non-uniform border + radius | `BoxDecoration` asserts | divider child |
| `grid`, subgrid | no equivalent | flex rows; calendar = 7 equal columns |
| `position: sticky/fixed` | different model | pinned/overlay anchors in the spec |
| `%`, `vw/vh`, `calc()`, `em/rem` | no equivalent | dp + flex + named formula |
| `text-wrap: balance/pretty`, `hyphens`, `::first-line` | unsupported | none |
| `letter-spacing` on Arabic; `font-style: italic` on Arabic; faux bold | breaks joining / fake slant | forbid |
| `text-transform` | locale pitfalls | write case in copy |
| native `select`, `input[type=date]`, `dialog` | meaningless in Flutter | custom components |
| `:hover`/cursor | touch only | none (`:focus-visible` allowed for a11y testing) |
| scroll-snap/overscroll CSS | platform physics differ | carousel formula |
| SVG filters, `foreignObject` | flutter_svg unsupported | flatten |
| multi-colour `border-image`, conic art | no equivalent | assets |

Stylelint skeleton (`stylelint.config.mjs`): `extends: ['stylelint-config-standard']`, plugins `stylelint-use-logical` (rule `csstools/use-logical: 'always'`) and `stylelint-declaration-strict-value` (colour, font-size, font-family, border-radius, box-shadow, spacing properties must use `var(--gz-*)`, ignoring `0`, `auto`, `transparent`, `currentColor`, `inherit`, `none`), `property-disallowed-list` for the table above, `declaration-property-value-disallowed-list` (`font-style: italic|oblique`, `text-align: left|right`, `display: grid|inline-grid`), `unit-disallowed-list` (`em, rem, vh, vw, dvh, svh, vmin, vmax, ch`). Waivers need a comment `/* flutter-ok: <reason> */` (use `reportDescriptionlessDisables`). TypeScript rule: screens must not branch on `window.innerWidth`.

### 4.8 Icons, fonts, images, i18n parity

- **Icons:** one SVG set on a 24 px grid and a single stroke weight; build an **icon font** with `fantasticon` 4.1 into TTF + a codepoint JSON, generate `GzIcons` (Dart `IconData`) and a CSS class set. The prototype and Flutter then render identical glyph geometry; directional icons use `Icon(matchTextDirection: true)` in Flutter and a `mirror` list in the spec. Multi-colour illustrations only as `flutter_svg` (precompile with `vector_graphics`).
- **Fonts:** same static TTFs in prototype (`@font-face`) and Flutter (4.7/3.7); never `@fontsource` in the prototype, so subset and metrics match exactly.
- **Images:** the prototype uses the same variant sizes/aspect tokens as production (4:3, 16:9, 1:1, 3:4); no faces.
- **Copy:** ARB parts rendered with `intl-messageformat`; `Intl` locale `ar` + `-u-nu-latn`; `Intl.DateTimeFormat` with explicit `timeZone: 'Asia/Kuwait'`; Sunday-first calendar from config.

### 4.9 Parity verification (what agents run, in order of cost)

1. `pnpm -F design shots --screen client.home` -> `design/.shots/<run>/client.home.{ar,en}.{360,390,430}.png` plus one contact sheet (6 variants composed with `sharp`) so one `Read` shows everything.
2. `pnpm -F design redlines --screen client.home` -> `design/.redlines/client.home.<locale>.<width>.json`.
3. `pnpm -F design a11y` -> axe per route, both locales.
4. Flutter: `flutter test --tags golden,parity` (Ahem goldens + redline rectangles within 1 dp).
5. `flutter widget-preview start` for side-by-side human comparison with the prototype.
Pixel equality is **not** a gate (font rasterisation differs); geometry and tokens are.

### 4.10 Contrast gate with real numbers (computed with WCAG 2.x relative luminance)

| Pair | Ratio | Verdict |
|---|---|---|
| Ink `#5A4B4F` on canvas `#FFF9F5` | 7.88 | pass |
| Ink on Soft Rose `#F8E7EC` | 6.90 | pass |
| Matte Gold `#D8B26E` on canvas | 1.91 | fails text and small icons; hairline/fill only |
| Matte Gold on Soft Rose | 1.68 | fails |
| **Ink `#5A4B4F` on Matte Gold** | **4.12** | **fails 4.5:1 for normal text** (large text/UI only) |
| `#4A3C40` on Gold | 5.23 | pass (recommended minimum for gold-button labels) |
| `#3B3033` on Gold | 6.35 | pass |
| `#896525` on canvas / on rose | 5.09 / 4.46 | canvas pass, rose fails |
| `#845F20` on canvas / on rose | 5.53 / 4.85 | passes both (candidate Gold-ink) |

`packages/design-tokens/a11y-pairs.json` lists allowed fg/bg token pairs with minimum ratios (4.5 text, 3.0 large text and UI boundaries); `pnpm tokens:check` fails if a pair drops below. Policy: gold is never the only boundary of an input or selected state (WCAG 1.4.11 needs 3:1); selected state = ink-tinted border or filled ink + gold accent.

---

## 5. CI/CD, quality gates, environments, secrets, git conventions

### 5.1 Branching and commits
- Trunk-based. `main` protected (required checks, linear history, squash merge). Branch names: `feat/<area>-<slug>`, `fix/…`, `chore/…`, `docs/…`, `agent/<role>-<slug>` for agent work.
- Conventional Commits with package scopes: `feat(client-app): …`, `fix(api): …`, `chore(tokens): …`, `docs(prd): …`, `ci: …`; enforced by commitlint 21 in a `lefthook` `commit-msg` hook. Pre-commit (lefthook 2.2, one Go binary): `biome check --staged`, `stylelint` on staged CSS, `dart format --set-exit-if-changed` on staged Dart, `gitleaks protect --staged`.
- Releases: tags `client-app/v1.2.0+34`, `hotel-app/v1.0.0+7`; API images tagged with the git SHA; DB migrations forward-only with expand/contract.
- Baseline: the repo has no commits (branch `master`); with owner approval do `git branch -M main` and an initial commit so worktree isolation and diff gates work. (Nothing in this document commits anything.)

### 5.2 Workflows (path-filtered; all Linux unless noted)
- `design.yml` (`design/**`, `packages/design-tokens/**`, `packages/i18n/**`): `pnpm install --frozen-lockfile`, tokens build + drift + contrast, i18n parity, `tsc --noEmit`, `biome check`, `stylelint`, `vitest run`, `vite build` (bundle-size budget), Playwright shots + axe (upload artifacts).
- `api.yml` (`apps/api/**`, `packages/contracts/**`): typecheck, biome, Vitest unit, integration with Testcontainers (Postgres+PostGIS, Redis), `openapi:emit` drift, Spectral lint, `oasdiff` breaking-change check vs `main`, `pnpm audit --prod`, gitleaks, Docker build (distroless, non-root), image scan.
- `flutter.yml` (`apps/**/*.dart`, `packages/ghazal_*/**`, `pubspec.yaml`): `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `tools/check-dart-rules.sh`, `flutter test --coverage` (unit + widget + Ahem goldens), coverage gate on logic packages. Flutter version pinned in the workflow (`flutter-version: 3.47.5`) and checked against pubspec's constraint by `tools/check-env.sh`.
- `contracts.yml`: regenerate TS and Dart API clients and fail on diff.
- `deploy-api.yml` (merge to `main` -> staging; manual approval -> prod): WIF auth, build + push to Artifact Registry, run migrations as a Cloud Run Job, deploy revision with `--no-traffic`, smoke test, shift traffic (10% -> 100%), keep the previous revision for rollback.
- `release-mobile.yml` (tag, macOS runner for iOS, Linux for Android): Fastlane lanes (build with `--obfuscate --split-debug-info`, upload symbols to Crashlytics, push to TestFlight / Play internal track) using an App Store Connect API key and Play service account from a protected GitHub environment with required reviewers. Codemagic is the fallback if macOS minutes become the constraint.

### 5.3 Environments
| | local | staging | prod |
|---|---|---|---|
| Infra | `docker compose` (Postgres+PostGIS, Redis, WhatsApp mock, mock API via Prism) | GCP project `ghazal-staging` | GCP project `ghazal-prod` |
| Cloud SQL | container | small, single zone | sized for load, daily backups + PITR, HA when budget allows |
| Firebase | emulator or dev project | staging project | prod project |
| MyFatoorah | sandbox/test token | test | live |
| Maps keys | dev key | staging key | prod key (restricted by bundle/SHA-1) |
| Apps | `.dev` bundle IDs | `.stg` (TestFlight/internal track) | store |
Region: me-central1 (Doha) unless the owner says otherwise.

### 5.4 Secrets
- Local: `.env` from the committed `.env.example`; `.env*`, `*.pem`, `*.p12`, `*.keystore`, `service-account*.json` are already git-ignored; a PreToolUse hook blocks agents from reading them (6.6).
- GCP: Secret Manager per environment project; Cloud Run `--set-secrets`; workloads use service accounts via Workload Identity (FCM Admin, GCS, Cloud SQL) with no JSON keys; GitHub -> GCP through Workload Identity Federation.
- Secrets inventory: MyFatoorah API token and webhook secret, WhatsApp Cloud API token, JWT signing keys (rotate by `kid`), Apple Sign-In `.p8` (server-side revocation), App Store Connect API key, Play service account, DB passwords.
- Never in a binary: mobile apps receive only public identifiers through `--dart-define-from-file`.
- gitleaks in pre-commit and CI; document rotation in `docs/engineering/secrets.md`.

### 5.5 Budget note
PRD estimates $20-100/month. Cloud SQL list price alone is about $8 (db-f1-micro) to $26 (db-g1-small) in us-central1 (me-central1 is higher; shared-core has no SLA; HA roughly doubles it). Memorystore Redis, an external load balancer for Cloud CDN/HTTP3, a min-instance API and a separate realtime service each add a fixed monthly line. The ceiling is realistic pre-launch only; get a pricing-calculator estimate before the owner relies on it.

---

## 6. Agentic-development setup for this repo

### 6.1 Assessment of the current AGENTS.md
Good: short (46 lines), concrete hard rules, read-first list, bilingual/token/a11y rules, the nulled-archive prohibition, CLAUDE.md imports AGENTS.md (Claude Code reads AGENTS.md directly only when no CLAUDE.md exists; the `@AGENTS.md` import is the right pattern, and docs recommend < 200 lines).
Gaps to fix: (1) commands point at `npm run` inside `design/` and a README that does not exist; (2) no stack/version pins (Node 24, pnpm 12, Flutter 3.47.5); (3) no definition of done or verification command; (4) token path will change to `packages/design-tokens`; (5) no file-ownership/shared-file/generated-file rules beyond one line in CLAUDE.md; (6) no decision protocol (ADR numbering collisions between parallel writers); (7) no Flutter/backend sections (belong in rules, not here); (8) the .rar rule is prose only (CLAUDE.md is advisory; docs say to use a PreToolUse hook for anything that must be blocked).

### 6.2 AGENTS.md additions (paste as new sections; keep file < 120 lines)

```md
## Stack (pinned)
Node 24 LTS, pnpm 12 (packageManager field), TypeScript ~6.0, Vite 8/React 19 (design/), NestJS 12 (apps/api), Flutter 3.47.5 / Dart 3.13 (apps/*_app, packages/ghazal_*), Material via `material_ui` (never `package:flutter/material.dart`).

## Commands (repo root)
- `pnpm install` · `pnpm -F design dev` · `pnpm verify design|flutter|api|all` (= tools/verify.sh)
- `pnpm tokens` (build) · `pnpm tokens:check` · `pnpm i18n:check` · `pnpm shots --screen <id>` · `pnpm a11y`
- Flutter: `flutter pub get` (root workspace) · `flutter analyze --fatal-infos` · `flutter test` · `flutter test --tags golden`

## Definition of done
A change is done only when `pnpm verify <area>` passes AND (UI work) you have looked at the PNGs in `design/.shots/<run>/` for both ar and en at 360/390/430. Paste the tail of the verify output into your final message.

## Ownership & shared files
- Edit only the paths your task assigns. Shared single-writer files: packages/design-tokens/src/**, design/src/system/**, pnpm-lock.yaml, pubspec.lock, lib/app/router/app_router.dart, packages/i18n/messages/** (your own feature folder only), packages/contracts/openapi.json (generated), apps/api/drizzle/** (migrations).
- Never use Write on an existing file another agent may touch; use Edit or append.
- Generated files (`**/generated/**`, `*.g.dart`, openapi.json, lockfiles, ARB merged outputs) are never hand-edited; run the generator named in docs/engineering/generated-files.md.

## Decisions
New decision = new ADR via `node tools/new-adr.mjs "<title>"` (allocates the number under a lock). Don't re-litigate accepted ADRs.

## Scope
Every screen/spec lists requirement IDs (CL-6.x / HT-7.x). Missing from the PRD -> docs/product/open-questions.md, not the design.
```
Also fix the Hard-rule bullet on tokens to `packages/design-tokens/src/` and remove the `design/tokens/` mention; keep the .rar rule and add "enforced by hook".

### 6.3 Path-scoped rules (`.claude/rules/*.md`; `paths` is the only frontmatter field Claude Code reads; keep each file < 40 lines)

| File | `paths` | Must say |
|---|---|---|
| `i18n-rtl.md` | `design/src/**`, `apps/**/lib/**`, `packages/ghazal_*/lib/**`, `packages/i18n/**` | logical properties only; no hardcoded strings; ARB key naming; plural rule for Arabic (all categories); Western digits default, never `ar-KW`; Sunday-first from config; normalise digits on input; no letter-spacing/italic in Arabic; mirror list for icons |
| `design-tokens.md` | `packages/design-tokens/**`, `design/src/**/*.css` | add a token with a reason; hex only in ref tier; contrast pairs; no raw values; alpha tokens instead of opacity |
| `prototype-handoff.md` | `design/src/**`, `design/specs/**` | Flutter-subset CSS list (4.5, 4.7), `data-gz`/`data-gz-id` on every measured node, spec JSON required for each new component and screen, motion tokens only |
| `flutter.md` | `apps/*_app/**/*.dart`, `packages/ghazal_*/**/*.dart` | material_ui only; Riverpod without codegen; no build_runner in apps; features don't import features; tokens only; `Directionality`-aware widgets (`EdgeInsetsDirectional`, `PositionedDirectional`); no `google_fonts`; retry policy; no `print` |
| `flutter-tests.md` | `**/test/**/*.dart`, `**/integration_test/**` | use `ghazalGoldenTest`; locale x width x text-scale matrix; Ahem CI goldens vs platform goldens; never update goldens without viewing the diff |
| `api-nestjs.md` | `apps/api/src/**/*.ts` | money in fils; dates as DATE in Asia/Kuwait; `@Api` decorator on every route; permissions; idempotency keys; problem+json codes; no business prose from the server |
| `db-migrations.md` | `apps/api/drizzle/**`, `apps/api/src/**/schema/**` | forward-only, expand/contract, hand-written SQL for constraints/PostGIS, one migration per PR, only the migration owner runs `drizzle-kit generate` |
| `payments-security.md` | `apps/api/src/{auth,payments,webhooks}/**`, `packages/ghazal_auth/**` | webhook signature + status re-query; no card data; secrets only via Secret Manager; OTP policy; token handling |
| `docs-adr.md` | `docs/**` | ADR template, requirement-ID traceability, open-questions protocol, no inventing scope |

### 6.4 Skills (`.claude/skills/<name>/SKILL.md`; frontmatter `name`, `description`, optional `disable-model-invocation`, `allowed-tools`, `context: fork`, `paths`; keep < 500 lines)
- `verify` — runs `tools/verify.sh <area>`, summarises failures, loops until green (allowed-tools `Bash(pnpm *) Bash(flutter *) Bash(dart *) Bash(tools/*) Read`).
- `add-screen` — checklist: requirement IDs -> screen spec JSON -> route -> ARB parts (en+ar, plurals) -> states (loading/empty/error/offline) -> `data-gz-id` anchors -> shots (6 variants) -> redlines -> axe.
- `add-token` — reason, tier, hex via `fmt`, regenerate, contrast pairs, drift check.
- `add-flutter-component` — from a component spec to widget + `@Preview` + goldens + parity test.
- `shots` — capture screenshots for both languages and three widths and build the contact sheet.
- `handoff-screen` — export redlines + spec and write the Flutter task brief (files owned, tokens, ARB keys, tests).
- `i18n-add-string` — add the key to both parts, placeholders, plural categories, run parity check.
- `adr` — create an ADR from the template via `tools/new-adr.mjs`.
- `release-mobile` — `disable-model-invocation: true` (manual only): version bump, tag, Fastlane.

### 6.5 Subagents (`.claude/agents/<name>.md`; frontmatter `name`, `description`, `tools`, `model`, `permissionMode`, `isolation: worktree`, `skills`, `hooks`; subagents inherit CLAUDE.md/AGENTS.md and rules, not conversation history)
- `design-qa` (read-only + Bash for shots): grid/spacing/typography/hierarchy review of screenshots in both languages; returns a findings table. `tools: Read, Glob, Grep, Bash`, `permissionMode: plan`.
- `a11y-auditor`: axe results + contrast + target sizes + focus order + reduced motion.
- `rtl-reviewer`: finds `left/right`, un-mirrored icons, hardcoded strings, Latin/Arabic baseline clashes, number/bidi issues.
- `prd-tracer`: verifies every screen/spec carries requirement IDs and flags invented scope against `docs/product/feature-matrix.md`.
- `handoff-checker`: diffs prototype redlines against Flutter parity results and lists deltas > 1 dp.
- Later (once code exists): `flutter-implementer` and `api-implementer`, both `isolation: worktree` (requires at least one commit in the repo), each with a fixed owned-path list in the prompt. Cap concurrent *writers* at 4-5; reviewers are read-only and unlimited. Subagent descriptions must stay concise (combined limit 15,000 tokens).

Example (`.claude/agents/design-qa.md`):
```md
---
name: design-qa
description: Visual QA of a screen in both languages. Use after any UI change, before calling it done.
tools: Read, Glob, Grep, Bash
model: sonnet
permissionMode: plan
---
You review Ghazal screens. For the given screen id, run `pnpm shots --screen <id>` if no fresh PNGs exist, Read the contact sheet, then check: 4-pt grid and token use, gutters/baselines aligned across screens, one primary action, hierarchy at a glance, Arabic sizes/leading, no clipped text at 360, mirrored icons, no banned effects (AGENTS.md anti-patterns), states present. Return a table: issue | where (data-gz-id) | severity | fix. Do not edit files.
```

### 6.6 Hooks and settings (hooks are the enforcement layer; CLAUDE.md is advisory)

Verified from the hooks docs: events `PreToolUse` (can block), `PostToolUse`, `Stop` (can block), `SessionStart`, `UserPromptSubmit`; matcher by tool name regex; command hooks receive JSON on stdin; **exit code 2 blocks** (stderr is shown), or exit 0 with JSON `hookSpecificOutput.permissionDecision` of `allow|deny|ask|defer`; `Stop` returns `{decision:"block", reason}` and its input includes a flag to prevent loops (check `stop_hook_active`); `${CLAUDE_PROJECT_DIR}` expands in commands; `args` selects exec form.

`.claude/settings.json`
```json
{
  "permissions": {
    "allow": [
      "Bash(pnpm *)", "Bash(dart *)", "Bash(flutter *)", "Bash(tools/*)", "Bash(node tools/*)",
      "Bash(git status*)", "Bash(git diff*)", "Bash(git log*)", "Bash(rg *)", "Bash(jq *)",
      "Bash(xcrun simctl *)", "Bash(adb *)"
    ],
    "deny": [
      "Read(./.env)", "Read(./BookingSaaS*)", "Read(**/*.rar)",
      "Edit(./project.md)", "Edit(./Ghazal_PRD_EN.pdf)",
      "Bash(*unrar*)", "Bash(*7z *)", "Bash(*BookingSaaS*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash|Read|Edit|Write|Glob|Grep|NotebookEdit",
        "hooks": [ { "type": "command", "command": "node", "args": ["${CLAUDE_PROJECT_DIR}/.claude/hooks/guard.mjs"], "timeout": 10 } ] }
    ],
    "PostToolUse": [
      { "matcher": "Write|Edit",
        "hooks": [ { "type": "command", "command": "node", "args": ["${CLAUDE_PROJECT_DIR}/.claude/hooks/format.mjs"], "timeout": 30 } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/tools/stop-gate.sh", "timeout": 120 } ] }
    ],
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "node", "args": ["${CLAUDE_PROJECT_DIR}/.claude/hooks/session.mjs"], "timeout": 15 } ] }
    ]
  }
}
```

`.claude/hooks/guard.mjs` (PreToolUse; Node, so no dependency on jq):
```js
#!/usr/bin/env node
import { readFileSync } from 'node:fs';
const { tool_name: tool, tool_input: ti = {} } = JSON.parse(readFileSync(0, 'utf8'));
const out = (decision, reason) => {
  console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: decision, permissionDecisionReason: reason } }));
  process.exit(0);
};
const blob = JSON.stringify(ti);
const path = String(ti.file_path ?? ti.path ?? '');
if (/BookingSaaS|\.rar\b/i.test(blob)) out('deny', 'Hard rule: the nulled .rar is off limits (AGENTS.md).');
if (/(^|\/)\.env(\.(?!example\b)[^/]*)?$/.test(path) || /\.(pem|p12|keystore)$/.test(path) || /service-account[^/]*\.json$/.test(path))
  out('deny', 'Secrets are never read or written by agents.');
if (['Edit', 'Write', 'NotebookEdit'].includes(tool)) {
  if (/(^|\/)(project\.md|Ghazal_PRD_EN\.pdf)$/.test(path)) out('deny', 'Source documents are read-only.');
  const generated = [
    [/\/generated\//, 'Generated: run the generator listed in docs/engineering/generated-files.md.'],
    [/\.g\.dart$/, 'Generated Dart: run its generator.'],
    [/(^|\/)(pnpm-lock\.yaml|pubspec\.lock)$/, 'Lockfile: change it with pnpm/dart pub only.'],
    [/packages\/contracts\/openapi\.json$/, 'Run: pnpm -F api openapi:emit'],
  ];
  for (const [re, msg] of generated) if (re.test(path)) out('deny', msg);
}
if (tool === 'Bash') {
  const c = String(ti.command ?? '');
  if (/\bgit\s+(commit|push|reset\s+--hard|clean\s+-\w*f|checkout\s+--\s)/.test(c)) out('ask', 'AGENTS.md: do not commit/push unless the user asked.');
  if (/\brm\s+-\w*r\w*\s+(\/|~|\.\/?\s|\*)/.test(c)) out('deny', 'Destructive recursive delete blocked.');
}
process.exit(0);
```
`format.mjs` (PostToolUse): runs `node_modules/.bin/biome format --write <file>` for `ts|tsx|json|css`, `dart format <file>` for `dart`, ignores failures, always exits 0.
`tools/stop-gate.sh` (Stop): exits 0 immediately if `stop_hook_active` is true; otherwise runs `tools/verify.sh changed --fast` (typecheck, biome, tokens check, i18n check, dart analyze on touched areas, target <= 60 s) and, on failure, prints `{"decision":"block","reason":"Fast verification failed:\n<last 40 lines>"}` so the agent must fix before finishing.
`session.mjs` (SessionStart): prints Node/pnpm/Flutter versions vs pins (`tools/check-env.sh`), current phase from `docs/engineering/STATUS.md`, and the count of open questions.

`.mcp.json`
```json
{
  "mcpServers": {
    "dart": { "command": "dart", "args": ["mcp-server", "--disable", "create_project"] },
    "playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@0.0.83", "--headless"] }
  }
}
```
Verified: `dart mcp-server` exists in the local SDK (tools include `analyze_files`, `run_tests`, `launch_app`, `hot_reload`, `hot_restart`, `get_runtime_errors`, `get_app_logs`, `get_widget_tree`, `lsp`; features can be disabled with `--disable`).

### 6.7 The autonomous verification loop

`tools/verify.sh <design|flutter|api|all|changed> [--fast]` (bash, `set -euo pipefail`; prints each command, exits non-zero on first failure; `changed` infers areas from `git status --porcelain`):
```
design : biome check design packages  →  pnpm tokens:check (rebuild+diff+contrast)  →  pnpm i18n:check
         →  tsc --noEmit (design)  →  stylelint "design/src/**/*.css"  →  vitest run
         →  [full] vite build  →  pnpm shots --changed  →  pnpm a11y
flutter: dart format --output=none --set-exit-if-changed apps packages  →  flutter analyze --fatal-infos
         →  tools/check-dart-rules.sh  →  flutter test  →  [full] flutter test --tags golden,parity
api    : biome check apps/api packages/contracts  →  tsc --noEmit  →  vitest run
         →  [full] testcontainers integration  →  pnpm -F api openapi:emit && git diff --exit-code packages/contracts
```
Looking at results (agents can Read PNGs):
- Prototype: `design/.shots/<run>/<screen>.<lang>.<w>.png` and the contact sheet.
- Flutter goldens: `apps/*/test/**/failures/*.png`.
- Real device/simulator: `flutter run -d <id> --dart-define=GZ_LOCALE=ar`, then `xcrun simctl io booted screenshot out.png` (iOS) or `adb exec-out screencap -p > out.png` (Android); Dart MCP `launch_app` + `get_runtime_errors` + `get_widget_tree` for runtime checks.
`design/scripts/shots.mjs` contract (the file CLAUDE.md already references): Playwright Chromium, loops `screens x [ar,en] x [360,390,430]`, `deviceScaleFactor: 2`, `reducedMotion: 'reduce'`, waits for `document.fonts.ready` and a `data-ready` attribute, hides carets, blocks network, names files as above, composes a contact sheet with `sharp`. `redlines.mjs` queries `[data-gz-id]` and writes logical insets/sizes; `a11y.mjs` runs `@axe-core/playwright` per route/locale and fails on serious/critical.

### 6.8 Parallel-agent pitfalls and protocol

1. **Lost updates:** `Write` on an existing shared file overwrites a concurrent edit. Rule: shared files are changed only with `Edit`/append; registries are split per feature (`<feature>_routes.dart`, `packages/i18n/messages/<scope>/<feature>.<locale>.json`) so concurrent additions never touch the same file.
2. **Single-writer files:** token JSON, `design/src/system/**`, lockfiles, generated outputs, OpenAPI contract, migrations, `AGENTS.md`, `.claude/**`, `.github/**`. Dependencies are added only by the integrator task. Migration files get timestamp names and only one agent runs `drizzle-kit generate`.
3. **Ownership map:** `docs/engineering/ownership.md` (role -> write globs); subagent frontmatter hooks can pass the role to the guard so out-of-scope writes are denied; for orchestrated general agents the task text must list owned files and the integrator diffs afterwards.
4. **Worktrees need a commit:** `isolation: worktree`/EnterWorktree requires a baseline commit; each worktree needs its own `node_modules`/`.dart_tool` (pnpm's store and the pub cache make this fast) and its own ports (`vite --port <n> --strictPort`), `COMPOSE_PROJECT_NAME`, database name (`ghazal_<agent>`), screenshot directory (`design/.shots/<agent-id>/`).
5. **Scarce resources need locks:** one emulator/simulator at a time (`flock tools/.locks/emulator`), one `build_runner` at a time (only `ghazal_api_client` uses it), one Playwright browser install.
6. **Generated files:** regenerate only in a dedicated step by the owner of the generator, then CI diff-checks; mark them `linguist-generated` in `.gitattributes`.
7. **Honest verification:** agents must paste the tail of `pnpm verify` output; the Stop hook blocks completion if the fast gate fails.
8. **Context drift:** keep AGENTS.md short, move detail to path rules, record decisions as ADRs, keep `docs/engineering/STATUS.md` (phase, active owners, token-freeze flag). After design freeze, token changes require an ADR and a broadcast.
9. **Cost control:** cap parallel writers at 4-5; spawn reviewers read-only; use `model: sonnet` for QA subagents, reserve the strongest model for architecture/integration.
10. **Scope inventors:** a `prd-tracer` pass per milestone; any screen without requirement IDs fails review.

---

## 7. Sequencing and critical path (what to do when)

**Now (design phase, about one day of foundation):** `package.json` + pnpm workspace + Node pin, Biome, Stylelint, lefthook, `packages/design-tokens` (+ contrast gate), `packages/i18n`, `design/` scaffold, `shots/redlines/a11y` scripts, `.claude/*` (rules, skills, agents, hooks), `.mcp.json`, `tools/verify.sh`, ADRs for: NestJS, Flutter floors, token pipeline, handoff contract, Riverpod/routing.
**At design freeze (end of Week 1):** baseline commit and tag `design-v1`; generate Dart tokens; scaffold the Dart workspace with `ghazal_lints`, `ghazal_ui` (theme from tokens + 6 base components + widget previews + golden harness) and both app shells with go_router and l10n — before the API is ready, so Week 3-4 does not start cold.
**Week 2:** API skeleton + contract kernel + `openapi:emit` + Prism mock + generated Dart/TS clients; Terraform foundations; CI workflows; payments spike (KNET, Apple Pay, refund, webhook).
**Week 0 gating items (start today):** account types (Apple/Google), D-U-N-S, WhatsApp Business verification + templates, MyFatoorah written answers, domain + link files, GCP/Firebase projects, baseline commit.

PRD timeline reality check: 2 weeks for the whole client app (16 requirement groups incl. chat, planner, payments, planning tools) is only credible with the contract-first mock, the pre-built design system package, and a hard MVP cut recorded in `open-questions.md`; do not let the Play 14-day closed-test or Apple review land in Week 8 unplanned.

## 8. Sources (checked 2026-10-10)
- Flutter 3.44 / 3.47 notes and migration: https://flutter.dev/blog/whats-new-in-flutter-3-44 , https://flutter.dev/blog/whats-new-in-flutter-3-47 , https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui , https://pub.dev/packages/material_ui
- DTCG 2025.10: https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/ , https://www.w3.org/community/reports/design-tokens/CG-FINAL-format-20251028/ , Style Dictionary DTCG page https://styledictionary.com/info/dtcg/
- Riverpod 3: https://riverpod.dev/docs/whats_new ; riverpod_lint: https://pub.dev/packages/riverpod_lint
- NestJS 12 roadmap: https://infoq.com/news/2026/04/nestjs-12-roadmap-esm ; Laravel/Node comparison: https://www.luckymedia.dev/blog/laravel-vs-nodejs
- Alchemist: https://pub.dev/packages/alchemist ; Dart MCP server: https://pub.dev/packages/dart_mcp_server ; flap: https://pub.dev/packages/flap ; dart-dio generator: https://openapi-generator.tech/docs/generators/dart-dio/
- MyFatoorah: https://docs.myfatoorah.com/docs/flutter , https://docs.myfatoorah.com/docs/v3-auth-capture ; Cloud Run WebSockets: https://docs.cloud.google.com/run/docs/triggering/websockets
- Claude Code docs: https://code.claude.com/docs/en/memory , /hooks , /sub-agents , /skills
- Google Play closed-testing rule (personal accounts, 12 testers, 14 days): https://www.testerscommunity.com/blog/google-play-closed-testing-requirements-2026 , https://extendsclass.com/blog/google-plays-closed-testing-requirement-what-developers-need-to-know-in-2026
- Local experiments in the session scratchpad: pub workspace + shared lints, gen-l10n Arabic plurals, intl digits/first-day, Node Intl digits, intl-messageformat parity, fontTools inspection/subsetting, WCAG contrast computation.
