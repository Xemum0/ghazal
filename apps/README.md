# apps/

> The future applications of Ghazal. **This folder is empty on purpose.** The current phase is design: the Client App and the Hotel App exist only as the web prototype in `design/`. A member is created in the PR where its first consumer lands (ADR 0021 D7), by the integrator, never as an empty scaffold. Rules and rationale: ADR 0021 (layout), 0022 (Flutter), 0020 (API), 0029 (ownership). Conventions: [docs/engineering/conventions.md](../docs/engineering/conventions.md).

## 1. What will live here

| Directory | Product | Stack | Created | Dev port (slot 0) |
|---|---|---|---|---|
| `client_app/` | Client Mobile App (iOS, Android) | Flutter 3.47.5 | at design freeze, after the baseline commit and tag `design-v1` | Flutter web or widget-preview `4706` (the offset is shared with `hotel_app`: run one at a time) |
| `hotel_app/` | Venue / Hotel Mobile App (iOS, Android) | Flutter 3.47.5 | same PR series as the client shell | `4706` |
| `api/` | REST API, realtime, PDF renderer, jobs | NestJS 12 on Node 24 (recommendation, OQ-T-01) | Week 2 | `4701` (realtime `4705`, pdf `4707`) |
| `venue-dashboard/` | Venue Admin Dashboard (web) | React | after its own design pass | `4702` |
| `admin-dashboard/` | Super Admin Dashboard (web) | React | after its own design pass | `4703` |

Shared code never lives here. Design system, formatter, auth, chat, generated clients, lints and test helpers are `packages/ghazal_*` (Dart) and `packages/*` (TypeScript). Apps import packages; packages never import apps.

## 2. Layout of a Flutter app (ADR 0022 B)

```
apps/client_app/
  pubspec.yaml                     resolution: workspace; flutter '>=3.47.5 <3.48.0'
  analysis_options.yaml            include: package:ghazal_lints/analysis_options.yaml
  l10n.yaml                        template app_en.arb, output lib/l10n/generated, class AppL10n
  config/env.{dev,staging,prod}.json     public values only
  lib/
    main.dart  bootstrap.dart      minimal main(); services initialise after the first frame
    app/{app.dart, router/app_router.dart, theme/}
    features/<feature>/{presentation, application, domain, data, <feature>_routes.dart}
    l10n/                          app_en.arb app_ar.arb (merged, committed), generated/
  test/  integration_test/  goldens/
```

Feature partition (also the ownership partition for parallel agents), mapped to the screen inventories in `docs/product/screens/`:

| App | Feature folder | Screens (inventory IDs) |
|---|---|---|
| client | `auth` | `CL-AUTH-01..05` |
| client | `onboarding` | `CL-ONBD-01..06` |
| client | `home` | `CL-DISC-01` home, `CL-DISC-02` Brief sheet |
| client | `search` | `CL-DISC-03..05` results, filters, map |
| client | `venue` | `CL-VENU-01..06` (details, gallery, calendar, packages, policies, government hall) |
| client | `compare` | `CL-SAVD-02..04` tray, replace sheet, table |
| client | `booking` | `CL-BOOK-01..07` |
| client | `payment` | `CL-PAYM-01..05` |
| client | `bookings` | `CL-BKNG-01..05` |
| client | `planning` | `CL-SAVD-01` Saved, `CL-WEDD-01..05` My Wedding, checklist, budget |
| client | `planner` | `CL-PLAN-01..04` |
| client | `services` | `CL-SERV-01..04` |
| client | `chat`, `notifications` | `CL-MSGS-01..03`; `CL-MSGS-04` |
| client | `reviews` | `CL-RVRW-01..04` (reviews, rewards and credit) |
| client | `profile` | `CL-PROF-01..06` |
| hotel | `today` | `HL-TODY-01..02` |
| hotel | `bookings` | `HL-BOOK-01..05`, `HL-DCSN-01..05` (decisions are part of the booking detail) |
| hotel | `calendar` | `HL-CALN-01..04` |
| hotel | `venue_management` | `HL-VENU-01..06` |
| hotel | `offers`, `analytics` | `HL-GROW-01..03`; `HL-GROW-04..06` |
| hotel | `notifications`, `chat` | `HL-TODY-03`; `HL-TODY-04..05` |
| hotel | `settings` | `HL-SETT-01..05` |
| hotel | `auth` (proposed) | `HL-ACCS-01..04`: ADR 0022's hotel list has no feature for the access screens |

The client tabs are Discover, Saved, My Wedding, Messages, Profile (ADR 0007); the hotel tabs are Today, Bookings, Calendar, Messages, More (ADR 0008). ADR 0022 D lists a different client tab set (`Discover, Compare/Planner, Plan, Messages, Profile`); ADR 0007 wins.

## 3. Layout of the API (ADR 0020)

```
apps/api/
  src/<module>/                    auth venues halls pricing availability bookings payments ledger
                                   chat notifications reviews planner content admin
    <module>.module.ts  *.controller.ts  *.service.ts  schema/  README.md
  drizzle/                         hand-written SQL migrations, single writer
  test/integration/                Testcontainers suites
```

One Nest module per domain is the unit of agent ownership. One Docker image, several Cloud Run deployables: `ghazal-api`, `ghazal-realtime`, `ghazal-pdf`, plus Cloud Run Jobs. Contract, error codes, permission keys and fixtures come from `packages/contracts`; the apps depend only on the emitted `openapi.json` and the fixtures, so the backend choice cannot leak into Flutter or design.

## 4. Prerequisites before any app starts

**G0, every app**

- [ ] Owner approved the baseline commit; `design-v1` is tagged (OQ-T-07).
- [ ] The pnpm workspace, `tools/` (verify, ports, check-env, new-adr), hooks and the `design.yml` workflow work; `pnpm verify design` is green.
- [ ] Tokens generate and `pnpm tokens:check` passes including the contrast pairs; `packages/contracts` holds the fixtures and `format-cases.json`; the i18n merge and parity checks pass.
- [ ] Owner signed iOS 15.0 and Android `minSdk` 26 as CF-35 (OQ-T-02) before any `flutter create`.
- [ ] Domain and bundle ID prefix are known (OQ-T-06); placeholders `com.ghazal.client` and `com.ghazal.venue` serve local work only and are never registered with a store or Firebase.
- [ ] `docs/engineering/ownership.json` and `generated-files.md` exist.

**client_app**

- [ ] The client P0 spine is frozen with `qa` recorded and redlines exported for the hero screens: `CL-ONBD-04..06`, `CL-DISC-01..04`, `CL-VENU-01..03`, `CL-SAVD-01`, `CL-SAVD-02`, `CL-SAVD-04`, `CL-BOOK-01..07` in both modes, `CL-PAYM-01..05`, `CL-BKNG-01`, `CL-BKNG-02` (Pending, Approved, Confirmed, Not accepted), `CL-WEDD-01`, `CL-MSGS-01..02`, `CL-AUTH-01..02`. Build the spine first; it carries the novel patterns. Supporting screens recombine shared sheets, lists and forms.
- [ ] The Dart workspace is in place: `ghazal_lints`; `ghazal_ui` (theme from tokens, six base components, widget previews, golden harness); `ghazal_core` (Money, `GzFormat` passing `format-cases.json`, `PhoneKw`, digit normaliser, retry policy); `ghazal_testing`; `tools/check-dart-rules.sh`; `flutter.yml`.
- [ ] The router skeleton has one pre-created line per feature; l10n and the three flavors are configured.
- [ ] Data layers wait for the contract: `openapi.json` plus the Prism mock (Week 2). Until then use fixtures behind repository interfaces.
- [ ] Per feature: `payment` needs the Week-1 payments spike (Apple Pay on the hosted page, return links, ADR 0027 D8) and a MyFatoorah sandbox; `auth` needs `ghazal_auth`, the WhatsApp template status (OQ-T-08) and Apple and Google client IDs; `chat` needs `ghazal_chat` and `ghazal-realtime` (MVP-P2); `notifications` needs the Firebase project and APNs key; maps need the restricted Maps key.
- [ ] Owner-pending money rules (deposit 30%, balance T-14, Standard cancellation, commission, credit cap) are read from configuration with the ADR placeholders and flagged.

**hotel_app**

- [ ] Everything above except the client spine; instead the hotel P0 spine is frozen: `HL-ACCS-01`, `HL-TODY-01`, `HL-BOOK-01`, `HL-BOOK-03`, `HL-DCSN-01`, `HL-DCSN-02`, `HL-BOOK-04`, `HL-CALN-01`, `HL-CALN-04`, `HL-GROW-02`, `HL-GROW-03`, `HL-TODY-04`, `HL-TODY-05`.
- [ ] The API offers what the app cannot fake (ADR 0008 consequences): deferred client notification with Undo for Accept, SLA timers and escalation, role permission keys in `/v1/me`, payout KYC state, step-up and device trust (ADR 0028), staff invites, `X-Venue-Id` membership checks.
- [ ] Auth method is settled (OQ-B-17, OQ-T-09); the iOS time-sensitive notification capability is configured for new-request alerts.
- [ ] The fixture caveats in the hotel inventory are resolved by the fixtures owner (Majlis Hall capacity 350 against a 450-guest men's section; the shared booking reference).

**api**

- [ ] Owner confirmed NestJS 12 or flipped to Laravel (OQ-T-01) before the first commit under `apps/api`. A flip changes the contract tooling and the Nest-specific names in ADR 0027, 0028 and 0029 (see their framework notes), not the Flutter apps, design, tokens or the framework-neutral rules; Flutter, design, tokens and i18n are untouched.
- [ ] `packages/contracts` has the Zod kernel, the `@Api` decorator and `openapi:emit` with Spectral and oasdiff in CI; `docker compose` provides Postgres 17 with PostGIS, pg_trgm and btree_gist, Redis, a WhatsApp mock and Prism on the reserved ports.
- [ ] GCP projects, Workload Identity Federation, Artifact Registry and secret stubs exist (`infra/`); the region and cost estimate are recorded (OQ-T-05, `cost.md`).
- [ ] ADRs 0001 to 0006 (booking model, granularity, state machine, pricing, deposit, cancellation) and 0027, 0028 were read by every payments, bookings and auth owner; payments waits for the Week-1 gateway spike.
- [ ] Migration owner, ownership globs and the single `drizzle-kit generate` author are named.

**venue-dashboard and admin-dashboard**

- [ ] Their own design pass is approved first (the design system must extend to the web). The venue dashboard must ship what the phone deliberately does not: the pricing tier editor, season and holiday overrides, cancellation tier editing (ADR 0004 D8, ADR 0006), refund issuing and goodwill refunds.

## 5. Creating an app (the birth PR, integrator only)

```
flutter create --org <prefix> --project-name client_app --platforms ios,android apps/client_app
dart fix --apply --code=migrate_design_widgets      # the template still imports package:flutter/material.dart
```

Then in the same PR: add the member to the root `pubspec.yaml` workspace list and give it `resolution: workspace`; set application IDs by hand to `<prefix>.client[.dev|.stg]` (the template would produce `<org>.client_app`); set `IPHONEOS_DEPLOYMENT_TARGET = 15.0` and Android `minSdk = 26`; add the three flavors and `config/env.*.json`; add `l10n.yaml`, the `ar.lproj` and `en.lproj` InfoPlist strings with `CFBundleLocalizations`, and Android `locales_config.xml`; include `ghazal_lints`; create `lib/` with one `<feature>_routes.dart` per feature and an `app_router.dart` that composes them; run `flutter pub get`, `flutter analyze --fatal-infos`, `tools/check-dart-rules.sh`. The same recipe applies to `hotel_app` with `<prefix>.venue`.

## 6. Working inside `apps/`

- Edit only your feature's folder and its tests and goldens (`apps/<app>/lib/features/<feature>/**`). `app_router.dart`, flavors, `pubspec.yaml` and generated l10n are integrator-owned.
- No `package:flutter/material.dart` or `cupertino.dart`, no hardcoded colour, string or physical left and right, no import across features; `tools/check-dart-rules.sh` enforces it.
- No secret in an app: public identifiers only, through `--dart-define-from-file`. `GZ_LOCALE=ar|en` works in non-prod flavors only.
- Money and slot POSTs never auto-retry and never queue offline.
- Work in a worktree and slot once the baseline commit exists ([git-workflow.md](../docs/engineering/git-workflow.md) section 3), and finish with the evidence block from [definition-of-done.md](../docs/engineering/definition-of-done.md) section C or D.

## 7. Order and timing

Phase 1 design of the Client and Hotel apps is the current work; the PRD gives it one week and 8 weeks overall. Week 0 holds the owner gates (accounts, WhatsApp verification, MyFatoorah answers, domain, GCP, baseline commit) because none can be sped up by writing code. At design freeze the Dart shell lands so the build weeks do not start cold. Week 2 brings the API skeleton, the contract kernel, Prism and the generated clients, and the payments spike. The PRD's two weeks for the whole client app are credible only with the contract-first mock, the prebuilt `ghazal_ui` package and a hard MVP cut recorded in `docs/product/open-questions.md`. Do not let the Play 14-day closed test or Apple review land in Week 8 unplanned.
