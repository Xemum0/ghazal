# ADR 0026: CI/CD, environments and secrets

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-12 |
| Scope | Source control and commit conventions, GitHub Actions workflows, environments, infrastructure as code, secrets, prototype preview, observability, budget rule |
| Owner confirmation still needed | OQ-T-03 (Apple and Google account type; D-U-N-S; Play closed test), OQ-T-05 (cost ceiling, region, optional fixed lines), OQ-T-07 (baseline commit, GitHub organisation, the pirated archive), OQ-T-13 (public preview URL), OQ-T-06 (domain and bundle prefix) |
| Related ADRs | 0020 (deployables), 0021 (ports locally, repo layout), 0022 (flavors, release builds), 0025 (what CI runs), 0027 (gateway secrets), 0028 (key rotation by `kid`), 0029 (hooks stop agents touching secrets and prod) |

## Context

The PRD puts hosting on Google Cloud in the owner's accounts (PL-ARCH-08, NF-PRJ-09, NF-DEL-08), requires a transfer of the full source code (NF-DEL-07), and sets a cloud envelope of USD 20-100 per month (NF-CST-01). Research (flutter-tech-handoff section 5):

- A smallest set of workflows gives reproducible deploys without click-ops; mobile public config goes through `--dart-define-from-file`; no secret ships in an app binary.
- Cloud SQL alone is about USD 8 (db-f1-micro) to 26 (db-g1-small) per month in us-central1 list pricing; me-central1 is higher, shared-core has no SLA and HA roughly doubles it. Memorystore Redis, an external load balancer for Cloud CDN, a min-instance API and a separate realtime service each add a fixed line. WhatsApp fees, a transactional email provider, video storage and CDN egress are not in the PDF cost table (CF-28). The USD 20-100 ceiling is realistic pre-launch only.
- Google Play personal accounts need a closed test with 12 opted-in testers for 14 continuous days before production; organisation accounts are exempt. Apple organisation enrolment and Meta WhatsApp Business verification have lead times of days to weeks.
- The local machine has gcloud, terraform, firebase, docker and java 21 but lacks gh, gitleaks, fastlane and Playwright browsers.
- me-central1 (Doha) is the nearest GCP region to Kuwait; latency to Kuwait was not measured.
- The repository has zero commits (branch `master`); worktree isolation and diff-based gates need a baseline commit, while AGENTS.md says not to commit unless asked.
- The nulled commercial script archive in the repo root is a licence and malware risk; it is git-ignored and must never be opened.

## Decision

**1. Source control.** A private GitHub repository created in the owner's organisation from day one (so transfer under NF-DEL-07 is a no-op). Trunk-based development: `main` protected (required checks, linear history, squash merge). Branches `feat/<area>-<slug>`, `fix/...`, `chore/...`, `docs/...`, `agent/<role>-<slug>`. Conventional Commits with package scopes (`feat(client-app)`, `fix(api)`, `chore(tokens)`, `docs(prd)`), enforced by commitlint in a lefthook `commit-msg` hook. Pre-commit (lefthook): `biome check --staged`, stylelint on staged CSS, `dart format --set-exit-if-changed` on staged Dart, `gitleaks protect --staged`. The repo needs a baseline commit before worktree isolation or diff gates work (OQ-T-07).

**2. Workflows** (GitHub Actions, path-filtered, Linux unless noted). Created when their code lands:

| Workflow | Triggers on | Does |
|---|---|---|
| `design.yml` (now) | `design/**`, `packages/design-tokens/**`, `packages/i18n/**`, `packages/contracts/**` | `pnpm install --frozen-lockfile`, tokens build + drift + contrast, i18n parity, specs check, `tsc`, Biome, Stylelint, Vitest, `vite build` with a bundle-size budget, Playwright shots + axe uploaded as artefacts, prototype preview deploy (item 6) |
| `flutter.yml` | `apps/**/*.dart`, `packages/ghazal_*/**`, `pubspec.yaml` | `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, `tools/check-dart-rules.sh`, `flutter test --coverage` (unit, widget, Ahem goldens, parity), coverage gate on logic packages, Flutter version checked against pubspec by `tools/check-env.sh` |
| `api.yml` | `apps/api/**`, `packages/contracts/**` | typecheck, Biome, Vitest unit, Testcontainers integration, `openapi:emit` drift, Spectral, oasdiff vs main, `pnpm audit --prod`, gitleaks, distroless non-root Docker build and image scan |
| `contracts.yml` | contracts | regenerate the TS and Dart API clients and fail on diff |
| `deploy-api.yml` | merge to main | staging automatically; production only after a manual approval in a protected GitHub environment. Workload Identity Federation auth, build and push to Artifact Registry, run migrations as a Cloud Run Job, deploy the revision with `--no-traffic`, smoke test, shift traffic 10% then 100%, keep the previous revision for rollback. Migrations are forward-only with expand/contract |
| `release-mobile.yml` | tags `client-app/vX.Y.Z+N`, `hotel-app/vX.Y.Z+N` (macOS runner for iOS, Linux for Android) | Fastlane lanes build with `--obfuscate --split-debug-info`, upload symbols to Crashlytics, then push to TestFlight / the Play internal track from the `stg` flavor; the `prod` flavor is built only from a release tag by a protected environment with required reviewers. Codemagic is the fallback if macOS minutes become the constraint |

**3. Environments.**

| | local | staging | prod |
|---|---|---|---|
| Infra | `docker compose` (Postgres 17 + PostGIS, Redis, WhatsApp mock, Prism) on ports from ADR 0021 | GCP project `ghazal-staging` | GCP project `ghazal-prod` |
| Database | container | Cloud SQL small, single zone | Cloud SQL sized for load, daily backups + point-in-time recovery (NF-AVL-02), HA when budget allows |
| Firebase | emulator or dev project | staging project | prod project |
| MyFatoorah | sandbox token | test | live |
| Maps keys | dev key | staging key | prod key restricted by bundle ID / package + SHA-1 |
| Apps | `.dev` bundle IDs | `.stg` (TestFlight / internal track) | store |

Region: me-central1 (Doha), the nearest GCP region to Kuwait, unless a quick RTT test from a Kuwait 4G SIM or the owner says otherwise (OQ-T-05). Production API runs min-instances=1 with startup CPU boost; staging scales to zero; `ghazal-realtime` stays at zero minimum until chat ships (PL-CORE-01 is MVP-P2).

**4. Infrastructure as code.** Terraform/OpenTofu only for foundations (projects, Workload Identity Federation, Artifact Registry, Cloud SQL, buckets, secret stubs, Cloud Run service shells); application deploys are not Terraform. Everything is created in the owner's GCP organisation or billing account.

**5. Secrets.**

- Local: `.env` from the committed `.env.example`; `.env*`, `*.pem`, `*.p12`, `*.keystore`, `service-account*.json` are git-ignored, and a PreToolUse hook (ADR 0029) stops agents reading or writing them.
- GCP: Secret Manager per environment project; Cloud Run `--set-secrets`; workloads use service accounts through Workload Identity (FCM Admin, GCS, Cloud SQL) with no JSON keys; GitHub reaches GCP through Workload Identity Federation only.
- Inventory (rotation documented in `docs/engineering/secrets.md`): MyFatoorah API token and webhook secret, WhatsApp Cloud API token, JWT signing keys (rotated by `kid`), Sign in with Apple `.p8` (server-side revocation), App Store Connect API key, Play service account, DB passwords.
- Never in a binary: the apps receive only public identifiers through `--dart-define-from-file`. The APNs auth key is uploaded in the Firebase console, never to the repo. gitleaks runs in pre-commit and CI.
- Agents never hold production credentials and never deploy to prod; staging deploys happen only through CI.

**6. Prototype preview.** `design.yml` deploys the static build to a Firebase Hosting preview channel in the staging project (7-day expiry, unguessable URL, `noindex`), so the owner can review on a real phone without running anything locally. It contains only fictional venues and credited imagery (OQ-T-13). This is separate from the local dev URL, which comes from `tools/ports.mjs` (ADR 0021).

**7. Observability.** Crashlytics for mobile; Cloud Logging and Error Reporting for the API (Pino JSON); no extra paid vendor inside the cost envelope. Request IDs flow from the apps to the API and into logs.

**8. Budget rule.** Before the owner relies on USD 20-100, run the pricing calculator for the real fixed lines (Cloud SQL, Redis, API min instance, realtime, PDF service, CDN/LB, Maps, WhatsApp fees, email provider, video egress) and record it in `docs/engineering/cost.md`.

## Consequences

- Reproducible deploys without click-ops; production changes are always reviewed and reversible by revision.
- No secret is ever in a repo, a binary or an agent's reach.
- The owner owns repo, cloud projects and store accounts from the start, which satisfies NF-PRJ-09 and NF-DEL-07/08.
- GitHub, GCP, Apple and Google accounts all need the owner's participation in Week 0 (OQ-T-03, OQ-T-07).
- macOS runner minutes cost money; Codemagic is the fallback.
- Two GCP projects plus Firebase projects raise fixed cost slightly versus one shared project; accepted for isolation.
- If the Play account is personal, the 14-day closed test must start by Week 5 or the Week-8 submission slips.
- A public unguessable preview URL exposes unreleased design; a password gate is added only if the owner asks (OQ-T-13).
- The pirated archive stays git-ignored; the owner should delete it or move it out of the repo (OQ-T-07). Agents never open it (ADR 0029 item 5).

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Codemagic for all mobile builds | Fallback only if macOS runner minutes become the constraint |
| One shared GCP project for staging and prod | Isolation of data, secrets and IAM is worth a small fixed-cost increase |
| JSON service-account keys | Workload Identity and Workload Identity Federation only |
| Terraform for application deploys | Foundations only; deploys are revision-based via CI |
| Click-ops in the console | Not reproducible; no review trail |
| Secrets in `.env` committed or baked into binaries | Never; Secret Manager and public identifiers only |
| Direct production deploys by agents | Staging via CI only; production needs a protected-environment approval |
| Another region without measuring | me-central1 pending an RTT test; owner can override |
| Trusting the USD 20-100 estimate | Verified with the pricing calculator before the owner relies on it |

## Related requirement IDs

| ID | Effect |
|---|---|
| PL-ARCH-08, NF-AVL-01, NF-AVL-02 | Google Cloud hosting; managed services; daily backups with PITR |
| NF-SEC-01, NF-SEC-02, NF-SEC-05 | Encrypted transport, hashed credentials, audit logs (secrets handling, gitleaks) |
| NF-SCAL-01 | Stateless Cloud Run revisions |
| NF-CST-01, NF-CST-02, NF-CST-03 | Cost envelope, store and domain costs, gateway fees |
| NF-DEL-07, NF-DEL-08, NF-PRJ-09 | Source transfer, deployment on the owner's Google Cloud, accounts in the owner's name |
| NF-PRJ-07 | Deployment and store submission in the final week |
| CF-28 | Cost-table omissions: WhatsApp, email, video egress, Apple enrolment effort |
