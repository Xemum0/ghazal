# Ghazal API contract (OpenAPI 3.1)

`ghazal.v1.yaml` (and the identical `ghazal.v1.json`) is the contract between the two Flutter apps, the mock (`ghazal_mock_api`) and the future NestJS backend. It is **assembled** from small files so that flow owners extend only their own tag:

```
base.yaml            info, servers, tags, security scheme, x-error-codes (code -> HTTP status)
parameters.yaml      shared headers and query parameters (Idempotency-Key, If-Match, X-Venue-Id, X-Provider-Id, cursor, limit)
schemas/<tag>.yaml   component schemas of one tag (common.yaml: money, localized text, ids, upload sessions, problem)
paths/<tag>.yaml     the operations of one tag (the tag of an operation is its file name)
examples/<Schema>.json   hero-story examples (Reem, Danah Ballroom, 14 Jan 2027, 350 guests), inlined as schema examples
scripts/             fixtures-to-wire.mjs, gen-examples.mjs, gen-coverage.mjs
```

## Pipeline (repo root, in this order)

```
node packages/contracts/openapi/scripts/gen-examples.mjs     # examples from the fixtures (hero story)
node tools/bundle-openapi.mjs                                # ghazal.v1.yaml + .json   (--check fails when stale)
npx @redocly/cli lint --config packages/contracts/openapi/redocly.yaml packages/contracts/openapi/ghazal.v1.yaml
node packages/contracts/openapi/scripts/fixtures-to-wire.mjs --write   # every fixture object validates against the schemas; writes the Dart samples
node tools/gen-dart-models.mjs                               # ghazal_domain models and repositories, ghazal_api REST classes (--check)
node packages/contracts/openapi/scripts/gen-coverage.mjs     # docs/architecture/api-coverage.md (fails on an unmapped selector, action or operation)
cd packages/ghazal_domain && flutter test && cd ../ghazal_api && flutter test
```

Node dependencies (`js-yaml`, `ajv`) are resolved from the pnpm virtual store until they are added to `packages/contracts` (request in `docs/engineering/requests.md`).

## Authoring sugar (expanded by `tools/bundle-openapi.mjs`)

| Where | Sugar | Result |
|---|---|---|
| schemas | `$ref: Name` | `#/components/schemas/Name` |
| schemas | `nullable: true` beside `type` or `$ref` | OpenAPI 3.1 null form (`type: [x, 'null']` / `oneOf`) |
| schemas | `x-page-of: Item` | `{ items: Item[], nextCursor }` cursor page (Dart: `Page<Item>`) |
| schemas | `x-dart-name`, `x-abstract` | rename a generated class so it cannot clash with Flutter or `ghazal_core` (`Notification` is `AppNotification`; `Lang`, `DigitStyle`, `PriceUnit`, `AnalyticsEvent` are `Wire*`; `Analytics` is `PartnerAnalytics`); skip a class (allOf base) |
| operations | `x-access: guest \| optional` (default bearer) | `security: []` / anonymous or bearer |
| operations | `x-idempotent`, `x-if-match`, `x-paged`, `x-partner` | the shared header and query parameters |
| operations | `path: { id: Id }`, `query: { 'date!': IsoDate, sort: VenueSort, ids: 'Id[]' }` | parameters (`!` = required) |
| operations | `body: Name`, `responses: { 200: Name, 201: 'Name[]', 204: ~, 200: pdf }` | JSON request and response; no anonymous inline schemas |
| operations | `x-errors: [CODE]` | problem+json responses grouped by HTTP status (table in `base.yaml`); `401/403/404/422/429` are added structurally |
| operations | `x-roles`, `x-permissions` | guard metadata for NestJS (defaults: `partner-*` tags are `partner`, the rest `client`) |

Every operation carries an `operationId`, which is the method name of the generated Dart repository (one interface per tag).

## Wire conventions (the short list)

* Property names `camelCase`, enum values lowercase `snake_case` (a few legacy kebab values: `private-hall`, `no-date`); clients read an unknown enum value as `unknown`.
* Money `{ fils, currency }`, integer fils; localized text `{ en, ar }` (a missing language is `null`); civil dates `YYYY-MM-DD`; instants carry `+03:00`; times `HH:mm`.
* Lists are `{ items, nextCursor }`; mutating POSTs that spend money, claim a slot or change a request take `Idempotency-Key`; request and settings commands take `If-Match` (`"v7"`, see `Booking.version`).
* Partner calls choose their context with `X-Venue-Id` (hotel or hall) or `X-Provider-Id` (service provider).
* Errors are problem+json with a stable `code`; the API sends no user-facing prose.

## Not in the contract

Socket.IO chat events, the payment gateway webhooks and the Super Admin web API (`/v1/admin/*`) are outside this file. The mock exposes a small **control surface** under `/__mock/*` (reset, clock, persona, settle a payment, moderate a listing, decide a refund request); it is not part of the product API and is specified in `docs/architecture/backend-handoff.md`.
