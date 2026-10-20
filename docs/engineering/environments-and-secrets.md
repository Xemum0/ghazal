# Environments and secrets

> Binding. Source: ADR 0026 (CI/CD, environments, secrets), 0021 (ports), 0022 J (flavors), 0027 (payments), 0028 (auth). Nothing here exists yet except the machine facts in section 2; this file says what each environment must be when it is created. Owner-dependent items are in section 12.

## 1. Environments at a glance

| | local | staging | prod |
|---|---|---|---|
| Infra | `docker compose`: Postgres 17 with PostGIS, pg_trgm, btree_gist; Redis; WhatsApp mock; Prism mock API | GCP project `ghazal-staging` | GCP project `ghazal-prod` |
| Database | container (`ghazal_slot<N>`) | Cloud SQL small, single zone | Cloud SQL sized for load, daily backups plus point-in-time recovery (NF-AVL-02), HA when budget allows |
| API | `127.0.0.1:4701 + 10 x slot` | Cloud Run `ghazal-api`, scales to zero | Cloud Run `ghazal-api`, min-instances 1, startup CPU boost (protects the 2 s home budget) |
| Realtime and PDF | `ghazal-realtime` offset 5, `ghazal-pdf` offset 7 | realtime at zero minimum until chat ships (PL-CORE-01 is MVP-P2); pdf scale-to-zero | same; pdf cached by content hash in GCS |
| Payments | MyFatoorah sandbox token, or the scripted fake gateway in tests | MyFatoorah test | MyFatoorah live |
| WhatsApp OTP | mock that prints the code to the console | Meta Cloud API test number | Meta Cloud API production |
| Firebase | emulator or dev project | staging project | prod project |
| Maps keys | dev key | staging key | prod key restricted by bundle ID or package plus SHA-1 |
| Apps | `.dev` bundle IDs, `--dart-define-from-file=config/env.dev.json` | `.stg` (TestFlight, Play internal track) | store builds |
| Data | synthetic fixtures only | synthetic fictional venues only | real data |
| Who deploys | the developer | CI on merge to `main` | CI after a manual approval in a protected GitHub environment |

Region: `me-central1` (Doha), the nearest GCP region, unless an RTT test from a Kuwait 4G SIM or the owner says otherwise (OQ-T-05; latency was not measured). Everything is created in the owner's GCP organisation and billing account.

Parity rules: the same Docker image runs in staging and prod; differences are configuration only; migrations run as a Cloud Run Job before traffic shifts; production data is never copied to local or staging.

## 2. Local machine (verified 2026-10-12) and setup

| Item | Today | Needed |
|---|---|---|
| Node | 23.7.0 (an odd, end-of-life line) | 24 LTS via nvm; `.node-version` pins it |
| pnpm | 10.10.0 | 12.x; the `packageManager` field makes pnpm 10 download the pinned version |
| Flutter | 3.47.5 stable | pinned to `>=3.47.5 <3.48.0` |
| Xcode, Android SDK | not verified here | Xcode 26.6, Android SDK 36.1, licences accepted (`flutter doctor --android-licenses`), remove the duplicate `adb` |
| Tools | `gcloud`, `terraform`, `firebase`, `docker`, Java 21 present | `brew install gitleaks gh` |
| Browser for shots | system Chrome | `playwright-core` with `channel: 'chrome'`; CI uses `playwright install chromium` |

Setup (once the foundation PR lands): `nvm install 24 && nvm alias default 24`; `pnpm install`; `cp .env.example .env`; `docker compose -f infra/docker-compose.yml up -d`; `tools/check-env.sh` (prints versions against the pins); `node tools/ports.mjs url design` (prints the design studio URL for the current slot; never hand-type one, and note that nothing of ours listens on 4700-4799 until the foundation PR lands).

Local ports (slot 0 is the main checkout, slots 1 to 9 are agent worktrees; ADR 0021 D8):

| Service | Port | Service | Port |
|---|---|---|---|
| design studio | `4700 + 10 x slot` | Prism mock | `4704 + 10 x slot` |
| api | `4701 + ...` | realtime | `4705 + ...` |
| venue-dashboard | `4702 + ...` | Flutter web or widget-preview | `4706 + ...` |
| admin-dashboard | `4703 + ...` | pdf renderer | `4707 + ...` |
| Postgres | `54320 + slot` | Redis | `63790 + slot` |

The block 4700-4799, 54320-54329 and 63790-63799 was free on 2026-10-12. This machine already runs a Postgres on 5432, MongoDB on 27017 and the owner's other project on 5173; Ghazal never uses those ports and never stops those processes. Every dev server uses `strictPort`, binds `127.0.0.1` and answers `GET /__gz`.

## 3. Three kinds of configuration

| Kind | Examples | Where it lives |
|---|---|---|
| Public build config | API base URL, Firebase identifiers, restricted Maps key, Google server client ID | `apps/*/config/env.{dev,staging,prod}.json` (`--dart-define-from-file`), Vite env; committed where not secret |
| Server config and secrets | database URL, gateway token, JWT keys, WhatsApp token | `.env` locally (git-ignored), Secret Manager per environment project, Cloud Run `--set-secrets` |
| Product configuration | deposit percentage, response and pay windows, cancellation templates, commission, SLA escalation, instant-booking trust thresholds, holiday date ranges | database or the contracts config, editable by the owner or Super Admin; never an env var, never a UI literal |

The third row is deliberate: ADR 0001 D6 and 0005 say all timers and percentages are configuration, so an owner decision changes data, not code.

## 4. Environment variables (proposed names; `.env.example` is authoritative once it exists)

Project variables carry the `GZ_` prefix. The Flutter-only define `GZ_LOCALE=ar|en` is honoured in non-prod flavors only.

| Variable | Kind | Source in staging and prod | Notes |
|---|---|---|---|
| `GZ_ENV` | config | Cloud Run env | `local`, `staging`, `prod` |
| `GZ_SLOT` | local only | `.env` | picks ports and database; also `--slot N` on `ports.mjs` |
| `GZ_API_BASE_URL` | public | `config/env.*.json` | |
| `GZ_DATABASE_URL`, `GZ_REDIS_URL` | secret | Secret Manager | Cloud SQL through the connector; no public IP |
| `GZ_MYFATOORAH_API_TOKEN`, `GZ_MYFATOORAH_WEBHOOK_SECRET` | secret | Secret Manager | server only; the apps never hold the token (ADR 0027) |
| `GZ_MYFATOORAH_BASE_URL` | config | per environment | sandbox or live |
| `GZ_WHATSAPP_ACCESS_TOKEN` | secret | Secret Manager | Meta Cloud API |
| `GZ_WHATSAPP_PHONE_NUMBER_ID`, `GZ_WHATSAPP_TEMPLATE_OTP_AR`, `GZ_WHATSAPP_TEMPLATE_OTP_EN` | config | per environment | template names after Meta approval (OQ-T-08) |
| `GZ_OTP_HMAC_KEY` | secret | Secret Manager | OTP codes are HMAC-hashed at rest |
| `GZ_JWT_SIGNING_KEYS` | secret | Secret Manager | ES256 private keys by `kid`; the public JWKS is served by the API |
| `GZ_APPLE_TEAM_ID`, `GZ_APPLE_KEY_ID`, `GZ_APPLE_SIGNIN_KEY_P8` | config, config, secret | Secret Manager | Sign in with Apple token revocation on account deletion |
| `GZ_GOOGLE_SERVER_CLIENT_ID` | public | per environment | `google_sign_in` `serverClientId` |
| `GZ_FIELD_ENCRYPTION_KEY` | secret | Secret Manager or KMS (decision open) | encrypts IBAN and holder name; deleted after payout (ADR 0006 D5) |
| `GZ_REVIEWER_DEMO_ENABLED`, `GZ_REVIEWER_DEMO_PHONE`, `GZ_REVIEWER_DEMO_OTP` | secret | prod secret flag | store-review demo account scoped to a sandbox user (ADR 0028 D8); never in a binary or the repo |
| `GZ_MAPS_API_KEY_IOS`, `GZ_MAPS_API_KEY_ANDROID` | public, restricted | `config/env.*.json` | restricted by bundle ID or package plus SHA-1 |
| `GZ_GCS_BUCKET_MEDIA`, `GZ_GCS_BUCKET_PDF` | config | per environment | workloads reach GCS through Workload Identity, not keys |

A variable is added to `.env.example` (placeholder value, one-line comment) in the same PR that first reads it. Application code reads configuration through one typed module that fails at startup on a missing or malformed value.

## 5. Secret inventory and rotation

Rotation cadences are recommendations for the owner to confirm; the storage rules are binding (ADR 0026 D5).

| Secret | Stored in | Used by | Recommended rotation | If leaked |
|---|---|---|---|---|
| MyFatoorah API token and webhook secret | Secret Manager | `apps/api/src/payments` | yearly and on staff change | revoke in the MyFatoorah portal, rotate, review payment events since exposure |
| WhatsApp Cloud API token | Secret Manager | OTP and notifications | yearly (system-user token) | revoke in Meta Business, rotate |
| JWT signing keys | Secret Manager, by `kid` | `apps/api/src/auth` | quarterly with `kid` overlap (access tokens live 10 minutes, so overlap is short) | add a new `kid`, retire the old, revoke sessions if the private key leaked |
| OTP HMAC key, field encryption key | Secret Manager or KMS | auth, refunds | on leak, or yearly for the HMAC | rotate; re-encrypt stored IBANs |
| Sign in with Apple `.p8` | Secret Manager | token revocation | on leak | revoke in the Apple Developer account, issue a new key |
| App Store Connect API key, Play service account | protected GitHub environment | `release-mobile.yml` | yearly | revoke and reissue; audit uploads |
| Android upload keystore | protected GitHub environment (encrypted) with Play App Signing enabled | release builds | not rotated unless leaked | request an upload-key reset from Play |
| APNs auth key | uploaded to the Firebase console only | FCM | on leak | revoke in the Apple account, upload a new one |
| DB passwords | Secret Manager | API, migrations job | yearly | rotate; Cloud SQL users are not shared across environments |
| Workload identities | none (no JSON keys) | Cloud Run, GitHub Actions through Workload Identity Federation | n/a | disable the provider binding |
| User TOTP seeds | encrypted in the database | admin 2FA | per user | reset the user's 2FA through a step-up flow |

## 6. Rules for humans and agents

- Agents never read or write `.env*` (except `.env.example`), `*.pem`, `*.p12`, `*.keystore`, `service-account*.json`; the `PreToolUse` guard denies them. An agent that needs a secret value asks the owner; it does not search for one.
- Agents never hold production credentials and never deploy to prod. Staging deploys happen only through CI.
- Apps receive only public identifiers. Nothing secret is compiled into a binary, a bundle or a fixture. Payment card data never touches Ghazal (SAQ-A posture, NF-PAYS-01).
- Logs and analytics never contain tokens, OTPs, IBANs, card data, chat or review text, special-request text, names, phones or emails (ADR 0019).
- No real personal data outside prod. Fixture phones are `+965 5000 00NN`, display-only; fixture IBANs and names are fictional.
- Secrets reach workloads only through Secret Manager (`--set-secrets`) and Workload Identity; GitHub reaches GCP only through Workload Identity Federation. No JSON keys anywhere.
- gitleaks runs in pre-commit and in CI.

## 7. CI/CD bindings

- GitHub Environments: `staging` (auto from `main`) and `production` (required reviewers). Mobile `prod` builds also use a protected environment with required reviewers.
- GitHub stores no GCP secrets: only the Workload Identity provider and service-account identifiers. Mobile signing assets (App Store Connect API key, Play service account, upload keystore) are environment secrets, available only to `release-mobile.yml`.
- API deploy: build and push to Artifact Registry, run migrations as a Cloud Run Job, deploy the revision with `--no-traffic`, smoke test, shift 10% then 100%, keep the previous revision for rollback. Migrations are forward-only (expand then contract).
- Terraform or OpenTofu manages foundations only (projects, Workload Identity Federation, Artifact Registry, Cloud SQL, buckets, secret stubs, Cloud Run service shells). Application deploys are not Terraform.
- Prototype preview: `design.yml` deploys the static build to a Firebase Hosting preview channel in the staging project (7-day expiry, unguessable URL, `noindex`). It contains only fictional venues and credited imagery (OQ-T-13). It is separate from the local dev URL.

## 8. Mobile flavors and identifiers

- Three flavors per app: `dev`, `staging`, `prod`. Bundle IDs `<prefix>.client[.dev|.stg]` and `<prefix>.venue[.dev|.stg]`. Until the owner supplies the domain and prefix (OQ-T-06) the placeholders are `com.ghazal.client` and `com.ghazal.venue` with `.dev` and `.stg`; do not register them with any store.
- `apps/*/config/env.{dev,staging,prod}.json` hold public values only. `flutterfire configure` runs once per flavor and its outputs are committed (not secrets). One Firebase project per environment holds the four mobile apps.
- Deep links: one host `link.<domain>`; `apple-app-site-association` and `assetlinks.json` are served from `infra/well-known/`. Payment return links and push taps use the same HTTPS links. ADR 0022 gives the client `/c/*` and the hotel app `/v/*`, while ADR 0007 D11 lists client links as `/v/{venue}`, `/compare` and `/b/{booking}`: the namespaces collide and must be reconciled before the files are written.
- Android notification channels: `bookings`, `messages`, `offers`, `reminders`. The hotel app's new-request push is iOS time-sensitive with the badge set to the pending count.

## 9. Payments, WhatsApp and auth per environment

- MyFatoorah: sandbox for local and staging, live for prod, always server-side, hosted payment pages opened from the app. Tests use the scripted fake gateway (duplicate, out-of-order, forged signature, late SUCCESS, KNET pending). A sandbox contract test runs nightly once a sandbox exists. Written MyFatoorah answers (OQ-T-04, OQ-B-02) gate any copy about refund timing.
- WhatsApp: locally a mock prints the code; staging uses a Meta test number; prod needs a verified business and an approved Arabic and English authentication template. There is no SMS fallback.
- A fixed OTP is allowed only in local, and for the reviewer demo account behind the production secret flag (ADR 0028 D8). Never hardcode one in code.
- Sign in with Apple and Google use separate client IDs per environment.

## 10. Cost rule

Before the owner relies on the PRD's USD 20 to 100 per month, run the pricing calculator for the real fixed lines (Cloud SQL, Redis, the API minimum instance, realtime, the PDF service, CDN and load balancer, Maps, WhatsApp fees, email, video egress) and record it in `docs/engineering/cost.md` (OQ-T-05). Staging scales to zero; no external load balancer or Cloud SQL HA until after launch.

## 11. If a secret leaks

1. Stop; do not paste the value anywhere, including your reply.
2. Rotate or revoke it first (section 5). A leaked secret is treated as public from the moment it was committed or logged.
3. Tell the owner: what, where, since when. Review the audit and payment logs for use in that window.
4. Remove it from the working tree and from CI logs. History is rewritten only if the owner decides, after rotation.
5. Add the pattern to the gitleaks rules so it cannot recur.

## 12. Owner gates that block environments (all open)

| Item | Blocks | Reference |
|---|---|---|
| Apple Developer and Google Play account type; D-U-N-S; Kuwait commercial licence; if Play is personal, 12 testers for a 14-day closed test (start by Week 5) | bundle IDs, signing, store submission | OQ-T-03 |
| Domain and bundle ID prefix | links, AASA, OAuth clients, push, payment return | OQ-T-06 |
| Meta business verification and the Arabic and English OTP template | WhatsApp OTP in staging and prod | OQ-T-08 |
| MyFatoorah sandbox and written answers (Auto Refund, KNET limits and timing, supplier KYC, tokenisation, fees) | payments spike, refund copy | OQ-T-04, OQ-B-02 |
| GCP organisation, billing, projects, region, cost envelope | all cloud environments | OQ-T-05 |
| GitHub organisation and the baseline commit | CI, worktrees, protected branches | OQ-T-07 |
| Backend confirmation (NestJS or Laravel) before the first commit under `apps/api` | the API | OQ-T-01 |
| iOS 15.0 and `minSdk` 26 sign-off (CF-35) | app scaffolding | OQ-T-02 |
| Analytics tool and consent text | analytics SDK, Settings toggle | OQ-T-14, OQ-L-11 |
