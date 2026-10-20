# Conventions

> Binding for every change by a human or an agent. Source ADRs: 0010-0016 (format, language, RTL, type), 0020-0024 (stack, layout, handoff), 0029 (agent setup). Where this file and an ADR disagree, the ADR wins; fix this file. Process lives elsewhere: [git-workflow.md](git-workflow.md), [testing.md](testing.md), [definition-of-done.md](definition-of-done.md).

## 1. One source of truth per thing

Never copy a value into a second place. If you need it somewhere else, import or generate it.

| Thing | Lives in | Consumed by |
|---|---|---|
| Colour, space, type, radius, motion values | `packages/design-tokens/src/*.tokens.json` (DTCG) | CSS vars, TS, Dart (all generated). There is no `design/tokens/` directory, ever. |
| Copy (every user-facing string, AR and EN) | `packages/i18n/messages/{common,client,hotel,server}/<feature>.<locale>.json` | merged into ARB for the apps and a catalogue for the prototype |
| API contract, enums, error codes, permission keys, fixtures | `packages/contracts` | API, dashboards, prototype mocks, Flutter tests via generated clients and shared JSON |
| Formatting of money, dates, times, numbers, phones | one module per codebase: `GzFormat` in `packages/ghazal_core` (Dart) and the TS twin | every screen; both tested against `packages/contracts/fixtures/format-cases.json` |
| Booking statuses, timers, deposit and policy numbers | `packages/contracts` enums and config (ADR 0001 D6, 0003 D1, 0005, 0006) | API, both apps, dashboards. Numbers are configuration, never literals in UI. |
| Fonts and icon font | `packages/ghazal_ui/assets` | Flutter and the prototype (`@font-face` on the same TTFs) |
| Requirement IDs | `docs/product/feature-matrix.json` (571 items) | specs, tests, commit footers |
| Analytics events | `packages/contracts/analytics/events.json` (ADR 0019) | apps, API, prototype inspector |
| Hijri and holiday dates | server data, editable by Super Admin (ADR 0011) | apps display only; the client never computes Hijri |

## 2. Repository layout

TypeScript directories are kebab-case, Dart packages snake_case. TS scope `@ghazal/*`, Dart prefix `ghazal_*`. Full tree and rationale: ADR 0021.

```
ghzal/
  AGENTS.md CLAUDE.md README.md
  package.json            scripts only; packageManager pnpm@12.x; engines node ^24
  pnpm-workspace.yaml     explicit member list + catalog
  pubspec.yaml            Dart pub workspace root (created at design freeze)
  biome.json stylelint.config.mjs lefthook.yml commitlint.config.mjs .env.example .mcp.json
  .claude/                settings.json rules/ skills/ agents/ hooks/
  .github/workflows/      design.yml flutter.yml api.yml contracts.yml deploy-api.yml release-mobile.yml
  docs/                   product design architecture engineering decisions research
  design/                 prototype "Ghazal Design Studio": Vite + React + TS
    src/{system,screens/{client,hotel}/<feature>,shell,mock}
    specs/{component.schema.json,screen.schema.json,components,screens/<app>/<feature>}
    scripts/              shots.mjs redlines.mjs a11y.mjs snap.mjs
    .shots/ .redlines/    generated, git-ignored
  apps/                   client_app hotel_app (Flutter), api (NestJS), venue-dashboard admin-dashboard (React, later)
  packages/               TS: design-tokens contracts api-client-ts i18n config-tsconfig
                          Dart: ghazal_ui ghazal_core ghazal_auth ghazal_chat ghazal_api_client ghazal_testing ghazal_lints
  infra/                  Terraform foundations, docker-compose.yml, well-known/
  tools/                  verify.sh check-env.sh check-dart-rules.sh ports.mjs new-adr.mjs fonts/ i18n tooling
```

Dependency direction (grep-enforced where possible):

- `apps/*` import `packages/*`; never the reverse.
- `design/` imports `@ghazal/design-tokens`, `@ghazal/i18n` and `@ghazal/contracts` (types and fixtures only). It never imports `apps/*`.
- `ghazal_ui` knows nothing about the API, auth or any feature.
- A Flutter feature never imports another feature's `presentation/` or `data/`. Cross-feature needs go through a `packages/ghazal_*` package or the router.
- A workspace member is created in the PR where its first consumer lands (birth criteria, ADR 0021 D7). No empty scaffolds.

## 3. Naming

| Thing | Convention | Example |
|---|---|---|
| React component file | PascalCase, CSS beside it | `VenueCard.tsx`, `VenueCard.css` |
| Other TS file | kebab-case | `format-money.ts` |
| Design workspace package | named `design` so `pnpm -F design ...` works | `pnpm -F design dev` |
| Dart file | snake_case; test adds `_test` | `venue_card.dart`, `venue_card_test.dart` |
| Design-system widget | `Gz` + component name | `VenueCard` becomes `GzVenueCard` |
| Dart provider / notifier | `<thing>Provider`, `<Thing>Notifier`, `<Thing>Repository`, `<Thing>RepositoryImpl`, `<thing>_mapper.dart` | `bookingDraftProvider` |
| Flutter feature folder | snake_case, ADR 0022 list | `venue_management` |
| Route module | `<feature>_routes.dart` exporting `List<RouteBase>`; typed helpers hand-written | `Routes.venue(id)` |
| CSS custom property | `--gz-` + token path with dashes | `--gz-color-sys-action-primary-bg` |
| Dart token member | camelCase, `color.sys.` dropped | `GzColors.actionPrimaryBg`, `GzSpace.s4` |
| CSS class | `gz-<component>`, `__element`, `--modifier` | `gz-venue-card__price` |
| Component root marker | `data-gz="<Component>"` | `data-gz="VenueCard"` |
| Measured node marker | `data-gz-id="<anatomy.id>"`; Flutter `ValueKey('gz:<id>')` | `media.fav` |
| Component spec | `design/specs/components/<Name>.spec.json` | `VenueCard.spec.json` |
| Screen inventory ID (permanent) | `CL-<GROUP>-NN` client, `HL-<GROUP>-NN` hotel; in `docs/product/screens/` | `CL-BOOK-05`, `HL-BOOK-03` |
| Screen spec id | `<app>.<group>.<slug>` from the inventory file id and slug; file `design/specs/screens/<app>/<group>/<slug>.spec.json` | `client.booking.review` |
| Requirement ID | `CA-` client, `HA-` hotel, `VD-` venue web, `SA-` super admin, `PL-` platform, `NF-` non-functional, `MK-`, `RM-` | `CA-BOOK-11`. The `CL-6.5` and `HT-7.2` notation in `docs/research/*` is void. |
| ARB key | camelCase `<feature><Screen><Element>` | `bookingReviewConfirmCta` |
| Error-code ARB key | `commonError` + code in PascalCase | `commonErrorSlotUnavailable` |
| Booking status | exactly the nine of ADR 0003 D1, lowercase snake_case | `awaiting_deposit`, `no_show` |
| API route | `/v1/<plural-kebab>`; webhooks outside `/v1` | `POST /v1/bookings/{id}/payment-sessions`, `/webhooks/myfatoorah` |
| API JSON property | camelCase | `paymentUrl`, `expiresAt` |
| Money on the wire | `{ "fils": 1250000, "currency": "KWD" }` | never a float |
| Problem code | UPPER_SNAKE in the RFC 9457 `code` | `SLOT_UNAVAILABLE`, `AUTH_REQUIRED`, `PHONE_VERIFICATION_REQUIRED` |
| Permission key | `resource:action` | `booking:approve`, `refund:create` |
| DB table / column | snake_case, tables plural, money `*_fils BIGINT`, instants `*_at timestamptz`, `event_date DATE` | `slot_claims`, `deposit_fils` |
| Migration | `YYYYMMDDHHMMSS_<slug>.sql`, forward-only | `20261105093000_add_slot_claims.sql` |
| Analytics event | `object_verb_pastTense`, snake_case properties | `booking_submitted`, `amount_fils` |
| Env var | `GZ_` prefix; Dart defines `GZ_LOCALE` | `GZ_API_BASE_URL` |
| Hero tag | `hero:<entity>:<id>:<part>` | `hero:venue:V01:cover` |
| Artefacts | shots and redlines `<screen>.<locale>.<width>.<ext>`; goldens add `ts<scale>` | `client.booking.review.ar.390.png`, `review.ar.390.ts2.0.png` |
| Venue fixture id | roster id from `docs/research/kuwait-localization.md` section 8.3 | `V01` Aurelia Gulf Hotel |

ADR 0024 names its eight hero screens with short ids (`client.home`, `client.venue.details`, `client.compare.table`, `client.booking.review`, `client.payment.outcome`, `client.bookings.detail`, `hotel.today.dashboard`, `hotel.bookings.detail`). Until the integrator reconciles them with the inventory slugs, treat them as aliases of these inventory IDs: `CL-DISC-01`, `CL-VENU-01`, `CL-SAVD-04`, `CL-BOOK-05`, `CL-PAYM-03/04/05`, `CL-BKNG-02`, `HL-TODY-01`, `HL-BOOK-03`; `HL-CALN-01` joins once frozen. Each screen spec records its `inventoryId`.

## 4. TypeScript, React and CSS (prototype, dashboards, API)

- TypeScript `~6.0.3`, `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, from `packages/config-tsconfig` (`base`, `node`, `react`). ESM only (`"type": "module"`).
- One tool formats and lints TS, JSON and CSS: Biome. Style follows `design/scripts/snap.mjs` where it speaks (2 spaces, single quotes, no semicolons); trailing commas, a 100-column limit and LF line endings are set here. `biome.json` is the authority once it exists.
- Types come from Zod schemas in `packages/contracts` (`z.infer`). No hand-written duplicate of a contract type. No `any` (parse `unknown`), no `!` outside tests, no `enum` keyword (string-literal unions or Zod enums), `import type` for types, named exports (default only where a framework requires it).
- No raw numbers or strings in UI. Text goes through `t('key', params)`, numbers and money through `GzFormat`. No `toFixed`, `toLocaleString`, `Intl.*` or `NumberFormat` outside the formatter module.
- Time is injected. Screens and mocks read `clock.now()`; the prototype clock is fixed at Thu 12 Nov 2026, 4:00 PM Asia/Kuwait. No `Date.now()` or argument-less `new Date()` outside the clock provider.
- React: function components and hooks, props typed as `<Component>Props`, no inline `style` except passing a token custom property, no branching on `window.innerWidth` (carousels use the shared formula: item width = viewport - 2 x gutter - peek). Routes register through `src/screens/**/routes.ts` (glob), never a shared route list.
- CSS is the Flutter subset (ADR 0024 D2): flex and `gap` only; `position:absolute` only for named overlay anchors with `inset-inline-*`; integer px on the 4-pt grid (hairline 1); logical properties only; every colour, size, radius, shadow and font through `var(--gz-*)`; no `grid`, `backdrop-filter`, `filter`, `mix-blend-mode`, `clip-path`, `mask`, `sticky`, `fixed`, `%`, `vh/vw/em/rem/ch`, `calc()`, negative or sibling margins, italics, Arabic letter-spacing, `text-transform`, container `opacity`, native `select`, date `input` or `dialog`. A waiver is `/* flutter-ok: <reason> */` and needs a reason a reviewer would accept.
- API code (later) follows `.claude/rules/api-nestjs.md`: money in fils, `event_date` as a DATE in Asia/Kuwait, `@Api` on every route, problem+json codes with no user-facing prose, `Idempotency-Key` on every POST that moves money or a slot.

## 5. Dart and Flutter

- Flutter 3.47.5 / Dart 3.13 pinned (`flutter: '>=3.47.5 <3.48.0'`). iOS 15.0, Android `minSdk` 26 (ADR 0022, owner sign-off pending as CF-35).
- UI imports `material_ui` and `cupertino_ui`. `package:flutter/material.dart` and `package:flutter/cupertino.dart` are banned (grep gate). Prefer packages that do not expose Material types.
- Analysis comes from `ghazal_lints`: `always_use_package_imports`, `prefer_const_constructors`, `unawaited_futures`, `require_trailing_commas`, `directives_ordering`, `avoid_print`, strict casts, inference and raw types; `riverpod_lint` through the analyzer plugin. `dart analyze --fatal-infos` must be clean. `dart format` decides layout.
- State: hand-written `Notifier` and `AsyncNotifier` (Riverpod 3.4). No `riverpod_generator`, `freezed`, `json_serializable` or `build_runner` in apps (build_runner exists only to regenerate `ghazal_api_client`).
- Data flow: widget, notifier, repository interface (domain), repository implementation (data), generated DTO, mapper, immutable entity with `equatable`. Generated types never reach presentation code.
- Widgets are direction-aware: `EdgeInsetsDirectional`, `PositionedDirectional`, `AlignmentDirectional`, `TextAlign.start/end`; icons from the registry with `matchTextDirection` where flagged. Banned by `tools/check-dart-rules.sh`: `EdgeInsets.only(left|right`, `Alignment.centerLeft|centerRight`, `Positioned(left|right`, `TextAlign.left|right`, `Color(0x` and `Colors.` outside generated tokens, string literals in `Text(`, `letterSpacing` in Arabic-capable styles, cross-feature imports.
- Visuals read semantic tokens only (`GzColors`, `GzSpace`, `GzRadius`, `GzSize`, `GzMotion`, `GzType`). No `google_fonts`, no runtime font fetch. Every `TextStyle` has an explicit height and `leadingDistribution: even`.
- Retry policy lives in `ghazal_core`: only idempotent GETs, only on network errors and 5xx, at most 3 with backoff. Booking creation, payment, OTP and anything carrying an `Idempotency-Key` never auto-retry; a user-initiated retry reuses the same key.
- Every interactive widget has a semantic label from the ARB; decorative imagery is `ExcludeSemantics`; booking-status changes call `SemanticsService.announce`; targets are at least 44 dp (48 for primary).
- Time is injected through a clock provider; domain code never calls `DateTime.now()` directly. Event dates are Kuwait calendar dates and are never converted through the device time zone.
- No `print`; use the logger in `ghazal_core`. No `!` force-unwrap without a one-line reason.

## 6. Money, dates, numbers, phones: the shared-formatter contract

| Need | Do | Never |
|---|---|---|
| Show an amount | `GzFormat.money` with precision `browse` (whole dinars when fils are 000, else exactly three decimals), `exact` (always three decimals: booking, deposit, balance, payment, refund, invoice, hotel booking detail) or `axis` (chart ticks) | `toFixed`, `NumberFormat`, hand-typed `KD 18,200`, two decimals, compact `18.4K` outside chart axes |
| Currency token | AR `{n}{NBSP}د.ك` (no trailing period), EN `KD{NBSP}{n}`; `KWD` only on invoices, receipts, bank settings, the gateway hand-off and the API | `KWD` on a consumer screen; `KD` on an invoice |
| Price basis | always a unit: `KD 46 per guest`, `KD 2,800 per night`, `From KD 16,100 for 350 guests` | a bare `From KD X` |
| Store and send money | integer fils plus `currency: 'KWD'`; the server computes totals; the client only formats | floats; client-side totals |
| Digits | Western 0-9 in both languages, comma thousands, dot decimals; locale `ar` with `-u-nu-latn` | `ar-KW`, `ar-SA`, `ar-EG`; Eastern digits except through the Arabic-only Settings row |
| Numeric input | one normaliser maps Arabic-Indic and Persian digits to ASCII on entry (client) and receipt (server) | trusting raw input |
| Dates | explicit patterns: `Thu 14 Jan`, `Thursday 14 January 2027`, `14 Jan 2027`; AR with Gulf month names; Hijri only as a muted line in Arabic summaries | `12/11/2026`; the idiom `ليلة` plus a weekday |
| Times | 12-hour Asia/Kuwait: `9:00 PM` / `9:00 م`; guest-side deadlines absolute; the hotel app may use `5h 20m` | device time zone; a ticking timer on a Pending request |
| Week | Sunday first, from explicit config (`weekStartsOn: 0`, `weekend: [5, 6]`, `peakBand: [4, 5, 6]`) | reading the locale default (intl says Saturday) |
| Phones | store E.164, display `+965 5123 4567` inside an LTR isolate; shape check `[2569]xxxxxxx` or `41xxxxxx`; call via `tel:`, WhatsApp via `wa.me/965...` | libphonenumber `isValid`; tappable fixture numbers |
| Identifiers in RTL | phone, email, OTP, IBAN, coupon, booking and invoice reference, URL render with `dir="ltr"` | letting bidi reorder them |
| Counts and plurals | ICU plural in the ARB with `one`, `two`, `few`, `many`, `other` (and `=0`) | `count + ' guests'` in code |

## 7. Copy and i18n in code

- Every string exists in AR and EN before the screen merges. No hardcoded string in a component, including `aria-label`, `alt`, placeholders and error messages. API error bodies carry codes, not prose.
- Arabic is written, not translated: possessive `كم`, verbal-noun CTAs, no `اختر` or `اختاري`, guests are `ضيف / ضيوف`, no exclamation marks in either language (ADR 0013). The English part carries descriptions and placeholder metadata; the Arabic part carries strings only.
- ARB prose contains no literal digits except placeholders. Arabic strings contain no Latin letters except `KD`, `KWD`, brand names and codes on the allow-list.
- Arabic text is never mirrored from English: check sizes, leading and icon mirroring on their own (ADR 0016 sizes: caption 13/20, small 15/24, body 17/28).
- Server-originated channels (push, WhatsApp, email, PDF) render from `packages/i18n/messages/server` in the user's saved locale.

## 8. Fixtures and seed content

| Rule | Value |
|---|---|
| Fixed NOW | Thu 12 Nov 2026, 4:00 PM, Asia/Kuwait (`2026-11-12T16:00:00+03:00`) in both apps |
| Hero client | Reem Al-Dosari (`ريم الدوسري`), monogram `ر`, wedding Thu 14 Jan 2027 (63 days) |
| Hero booking | Aurelia Gulf Hotel (V01), ladies, 350 guests x 52 = 18,200.000; deposit 30% = 5,460.000; balance 12,740.000 due 14 days before |
| Phones | `+965 5000 00NN` pattern, display-only, never a `tel:` or `wa.me` link |
| Booking reference | `GZ-<YYMM>-<4 characters>`, rendered as an LTR isolate |
| Imagery | empty rooms only, no identifiable faces, credited in `design/public/images/CREDITS.md` |
| Names | fictional venues; no real brands, royal names, mosques or real government halls |
| Empty reviews | show `New` / `جديد`, never 0.0 |

A fixture contains `fils` integers and status enums only; display strings come from the formatter and the ARB. Stress fixtures live in `packages/contracts/fixtures/stress/` (see [testing.md](testing.md)).

## 9. Comments, TODOs and waivers

- Comment the why, not the what. A comment that cites a rule cites its ADR or requirement ID (`// ADR 0001 D5: requests never claim the calendar`).
- A TODO names an open question or an owner: `TODO(OQ-B-14): platform credit cap`. A bare `TODO` fails review.
- Placeholder money rules (commission 8% with a 10% cap, cancellation numbers, deposit percentage) are configuration with a comment naming the open question, never inline literals.
- Generated files carry a `GENERATED` header and are never hand-edited (`docs/engineering/generated-files.md`, created by the integrator in the foundation PR, lists the generator for each).
- Waivers: `flutter-ok:` for CSS, a `// ignore:` in Dart only with a reason on the same line.

## 10. Commit messages

Conventional Commits, enforced by commitlint in the lefthook `commit-msg` hook.

```
<type>(<scope>): <subject>

<body: why, not what; wrap at 100>

Refs: CA-BOOK-11, ADR 0001
```

- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `perf`, `build`, `ci`, `chore`, `revert`.
- Scopes (one per commit): `client-app`, `hotel-app`, `api`, `design`, `tokens`, `i18n`, `contracts`, `ui`, `core`, `auth`, `chat`, `api-client`, `testing`, `lints`, `venue-dashboard`, `admin-dashboard`, `infra`, `tools`, `claude`, `prd`, `adr`, `deps`, `release`. `ci:` may omit the scope.
- Subject: imperative, lower case, at most 72 characters, no full stop. A commit touching two scopes is two commits.
- Footers: `Refs:` lists requirement IDs and ADR numbers; `BREAKING CHANGE:` is mandatory when a contract, token name or ARB key is removed or renamed.
- Agents add the attribution trailer the session supplies. They commit only when asked (see [git-workflow.md](git-workflow.md)).

Examples:

```
feat(client-app): add booking review step with the four-node payment schedule
fix(api): release expired holds inside the claiming transaction
chore(tokens): add gold-ink on soft-rose pair to a11y-pairs
test(ui): add Arabic 2.0 text-scale goldens for GzVenueCard
docs(prd): record owner answer to OQ-B-15
```
