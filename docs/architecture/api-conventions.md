# API conventions

> Status: binding for the API, the generated clients, the prototype's mock store and the dashboards. Source: ADR 0020 (contract kernel, NestJS recommendation, **proposed, needs owner**), 0027 (payments boundary), 0028 (auth), 0010 (money), 0019 (analytics), 0003 (state machine). The conventions are framework-agnostic on purpose: the apps depend only on `packages/contracts/openapi.json` and `packages/contracts/fixtures`, so a Laravel flip in Week 0 (OQ-T-01) changes the generator, not these rules. Requirement IDs follow `docs/product/feature-matrix.json`.

> **Amendment 2026-10-20 (ADR 0033, 0035, 0036): the contract is now `packages/contracts/openapi/ghazal.v1.yaml`.** It is written by hand in per-tag files and bundled by `tools/bundle-openapi.mjs` (OpenAPI 3.1; there is no Zod decorator pipeline, no dart-dio client and no Prism: the Dart models, repository interfaces and REST classes are generated from it by `tools/gen-dart-models.mjs`, and `ghazal_mock_api` serves it stateful). The wire rules of sections 2, 3 and 5 to 8 still hold. What changed, because Ghazal sells only the KD 2 voucher:
>
> * **Requests, not bookings with money.** Statuses are `pending, approved, declined, expired, confirmed, redeemed, completed, cancelled`; there is no deposit, balance, payment schedule, `payment-sessions` on a request, invoice, cash, refund or payout. Paths are `/v1/requests` (client) and `/v1/partner/*` (partner), not `/v1/bookings` and `/v1/venue/*`. The only payments are the voucher (`/v1/vouchers/checkout`, `/v1/vouchers/{id}/payment-sessions`) and, when plan rates are decided, a provider listing plan.
> * **Errors.** New codes: `OPEN_REQUEST_LIMIT` (replaces `OPEN_UNPAID_LIMIT`), `VOUCHER_*`, `CONFIRM_WINDOW_ENDED`, `UNDO_WINDOW_ENDED`, `LISTING_*`, `PLAN_RATES_NOT_ANNOUNCED`, `VISIT_*`, `MEDIA_*`, `REVIEW_*`, `STAFF_LAST_ADMIN`, `INVITATION_EXPIRED`, `CREDIT_NOT_ELIGIBLE`, `REFUND_REQUEST_EXISTS` (table in the `x-error-codes` of `base.yaml`). Removed: `BOOKING_NOT_PAYABLE_YET`, `INSTANT_NOT_ELIGIBLE`, `VENUE_KYC_REQUIRED`, `COUPON_*`, `PAYMENT_WINDOW_CLOSED`.
> * **Headers.** `X-Venue-Id` (hotel or hall) is joined by `X-Provider-Id` (service-provider account).
> * **Dates.** Instants carry the `+03:00` offset (fixtures, screens and the wire agree), not `Z`; civil dates, times and money are as in section 2.
> * **Partner sign-in** is email plus password with an emailed code on a new device; staff are invited by email (ADR 0035 D8).
> * **Catalogue.** Section 9 is superseded by [api-coverage](api-coverage.md) (generated; every operation with method, path, access, permissions and flags). Section 7 now applies to 54 operations (`x-idempotent`), section 8's `If-Match` to 16 (`x-if-match`). The server implementation guide is [backend-handoff](backend-handoff.md).

## 1. Contract-first workflow

1. Change the Zod schema or the error/permission registry in `packages/contracts/src/**` (schemas carry `.meta({ id })`; the booking state-machine table, enums, permission keys and fixtures live there too).
2. Declare the operation with the single decorator `@Api({ summary, auth, permissions, params, query, body, responses, errors })`. It registers the operation, stores permission metadata for the guard and, in dev and test, validates responses against the schema.
3. `pnpm -F @ghazal/api openapi:emit` writes `packages/contracts/openapi.json` as **OpenAPI 3.0.3** (the Dart generator documents no 3.1). *(Superseded: see the amendment above, the contract is hand-written OpenAPI 3.1.)* CI fails on drift, runs Spectral, and runs an oasdiff breaking-change check against `main`.
4. `tools/gen-api-clients.sh` regenerates `packages/api-client-ts` (openapi-typescript + openapi-fetch) and `packages/ghazal_api_client` (dart-dio). Generated code is committed, marked `linguist-generated`, never hand-edited; CI regenerates and fails on diff.
5. `prism mock packages/contracts/openapi.json` serves the fixtures, so the Flutter apps start against a mock while the API is built. The design prototype reads the same fixtures.

WebSocket events are not in OpenAPI: `packages/contracts/events/*.schema.json` plus `fixtures/chat/*.json`, loaded by both the TS and Dart suites.

## 2. Basics

| Topic | Rule |
|---|---|
| Base | `https://api.<domain>/v1`. Webhooks live at unversioned `/webhooks/*`. Health: `/healthz`, `/readyz`. Dev servers also answer `GET /__gz` (identity handshake, ADR 0021) |
| Format | JSON, UTF-8. Properties `camelCase`; enum values lowercase `snake_case` (`awaiting_deposit`); ids UUID strings; booking reference `GZ-2611-0147` as `ref`. Query parameters `camelCase`, arrays as repeated keys (`areaIds=…&areaIds=…`) |
| Paths | Plural nouns, kebab-case for multi-word segments. State changes are commands: `POST /v1/bookings/{id}/approve`, not `PATCH {status}`. Hotel and dashboard context comes from `X-Venue-Id` and the `/v1/venue/*` family (no venue id in the path) |
| Methods | `GET` safe and cacheable; `POST` create or command; `PUT` full replace of a settings document (with `If-Match`); `PATCH` partial update; `DELETE` remove. No `PATCH` on `status` |
| Responses | A single resource is returned bare. Lists are `{ "items": [...], "nextCursor": "…" }` with `nextCursor` null on the last page. Errors are problem+json (section 5). `201` with `Location` on create, `202` for accepted-and-asynchronous (analytics, refund submission), `204` for no content |
| Dates and time | `date` is `YYYY-MM-DD` and always a Kuwait civil date (`eventDate`, `balanceDueOn`). Instants are ISO 8601 UTC with `Z` (`respondBy`). Session times are `HH:mm` venue-local. The server never converts an event date through any zone |
| Money | Wire shape `{ "fils": 18200000, "currency": "KWD" }`. Percentages are integer basis points named `*Bps`. The server never returns formatted money. Layering across the stack: DB column `*_fils`, API `Money` object, analytics flat `amount_fils` + `currency` (ADR 0010, 0019) |
| Localised content | Venue-authored text is `{ "ar": "…", "en": "…" }` with a missing language as `null`; the client picks, falls back to the other language and shows a quiet language chip. Language switching therefore needs no refetch (NF-LOC-06) |
| Media | Descriptors `{ id, blurhash, aspect, baseUrl, alt: {ar, en}, zone }`; the client appends `/{width}.webp` (320, 640, 960, 1440) |
| Phone | E.164 on the wire (`+96551234567`) |
| Unknown values | Clients treat unknown enum values as `unknown`, never crash. New enum values ship only after the minimum app version supports them |

## 3. Headers

| Header | Direction | Purpose |
|---|---|---|
| `Authorization: Bearer <access JWT>` | request | Absent for guests (public GETs) |
| `X-Device-Id` | request | Install id; guest rate limiting, session binding |
| `X-Venue-Id` | request | Active venue for hotel and dashboard calls; membership validated every call. Missing: `400 VENUE_CONTEXT_REQUIRED` |
| `X-Platform` | request | `ios`, `android` or `web`; orders payment methods and wallet availability |
| `X-App-Version` | request | Below the minimum: `426 APP_UPDATE_REQUIRED` |
| `X-Request-Id` | both | Client generates a UUID, the server echoes it and logs it; quoted in support cases |
| `Idempotency-Key` | request | UUID per user intent; required on money and slot operations (section 7) |
| `If-Match` / `ETag` | request / response | Optimistic concurrency (section 8) |
| `Accept-Language` | request | Advisory only (search language bias). Push, WhatsApp, email and PDFs use the user's saved locale, not this header |
| `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`, `Retry-After` | response | On `429` |
| `Idempotent-Replayed: true` | response | A stored response was replayed |

## 4. A booking, as the clients receive it

The server computes everything a client would otherwise re-implement: prices, deadlines, policy dates, the permitted commands (`allowedActions`) and the Booking Thread. The client and hotel apps render the same object.

```json
{
  "id": "0192f4c4-7b1a-7c3e-9a2f-5d1e8b6c4a10",
  "ref": "GZ-2611-0147",
  "status": "requested",
  "mode": "request",
  "version": 3,
  "venue": { "id": "…", "name": { "ar": "فندق أوريليا الخليج", "en": "Aurelia Gulf Hotel" }, "bookingChannel": "ghazal" },
  "eventDate": "2027-01-14",
  "sections": [{
    "position": 1,
    "hall": { "id": "…", "name": { "ar": "قاعة الدانة", "en": "Danah Ballroom" } },
    "session": { "id": "…", "start": "19:00", "end": "01:00" },
    "audience": "women",
    "guests": 350,
    "package": { "id": "…", "name": { "ar": "الحفل النسائي · نهاية الأسبوع", "en": "Ladies' Reception, Weekend" } }
  }],
  "total": { "fils": 18200000, "currency": "KWD" },
  "schedule": [
    { "kind": "deposit", "amount": { "fils": 5460000, "currency": "KWD" }, "state": "scheduled", "dueAt": null },
    { "kind": "balance", "amount": { "fils": 12740000, "currency": "KWD" }, "state": "scheduled", "dueOn": "2026-12-31" }
  ],
  "deadlines": { "respondBy": "2026-11-13T09:40:00Z", "payBy": null },
  "policy": { "template": "standard", "freeCancellationUntil": "2026-11-15", "guestLockOn": "2027-01-07" },
  "flags": { "blockedByHold": false, "urgent": false },
  "thread": [{ "node": "request", "at": "2026-11-12T09:40:00Z" }],
  "allowedActions": ["edit", "withdraw", "message", "call"]
}
```

`allowedActions` is the intersection of the state machine, the caller's relation (owner client or venue member) and permission keys; the UI hides what is absent and never re-derives it. The client view masks an approval that is still inside its 8-second undo window (the booking still reads `requested`).

## 5. Errors

All `4xx` and `5xx` are `application/problem+json` (RFC 9457) with a stable `code`. **The API sends no user-facing prose**: clients map `code` plus `params` to an ARB key, so every error is bilingual by construction (NF-LOC-07).

```json
{
  "type": "https://api.<domain>/problems/slot-unavailable",
  "title": "Slot unavailable",
  "status": 409,
  "code": "SLOT_UNAVAILABLE",
  "requestId": "6b0f…",
  "params": { "eventDate": "2027-01-14", "reason": "held" },
  "alternatives": [{ "eventDate": "2027-01-21", "hallId": "…" }]
}
```

`title` and `detail` are for developers and logs only. Validation failures add `errors: [{ "path": "sections[0].guests", "code": "GUESTS_OUT_OF_RANGE", "params": { "min": 300, "max": 650 } }]`.

| Code | HTTP | When | Client behaviour |
|---|---|---|---|
| `VALIDATION_FAILED` | 422 | Body or query invalid | Inline field errors |
| `AUTH_REQUIRED` | 401 | Gated route without a valid session | Guest-gate sheet, then resume the stored intent |
| `TOKEN_EXPIRED` | 401 | Access token expired | Single-flight refresh, replay once |
| `SESSION_REVOKED` | 401 | Refresh token reused or session revoked | Sign out, clear caches |
| `PHONE_VERIFICATION_REQUIRED` | 403 | Request, payment or chat without a verified phone | Inline WhatsApp code in Details |
| `FORBIDDEN` | 403 | Role lacks the permission | "You do not have access. Ask your manager." |
| `STEP_UP_REQUIRED` | 403 | Bank, refund or staff action | OTP or password sheet |
| `NOT_FOUND` | 404 | Unknown or inaccessible resource | Dead-link screen with similar venues |
| `OTP_INVALID`, `OTP_EXPIRED`, `OTP_LOCKED` | 400, 410, 423 | Wrong, old or exhausted code | Field error, resend, lockout copy |
| `RATE_LIMITED` | 429 | Over a limit (`Retry-After`) | Calm retry message |
| `IDEMPOTENCY_KEY_REUSED` | 422 | Same key, different body | Developer bug; log |
| `IDEMPOTENCY_IN_PROGRESS` | 409 | Original call still running | Retry after `Retry-After` |
| `BOOKING_STATE_CONFLICT` | 409 | Compare-and-swap lost; body carries `currentStatus`, `currentVersion` | "Already updated" sheet, refetch |
| `BOOKING_NOT_PAYABLE_YET` | 409 | Payment session inside the undo window | Wait and refetch |
| `SLOT_UNAVAILABLE` | 409 | Claim failed (booked, blocked, held); body carries `alternatives` | `CL-BOOK-07` sheet; hotel: "Date held for another couple" |
| `OPEN_UNPAID_LIMIT` | 409 | Already 3 open unpaid bookings | Explain, link to Bookings |
| `QUOTE_EXPIRED`, `QUOTE_CHANGED` | 410, 409 | Review quote stale or repriced | Re-show Review with the new quote |
| `LEAD_TIME_TOO_SHORT`, `GUESTS_OUT_OF_RANGE`, `AUDIENCE_NOT_ALLOWED` | 422 | Booking inputs outside venue rules | Field-level copy |
| `INSTANT_NOT_ELIGIBLE` | 409 | Instant requested but ineligible | Silent fallback to "Request to book" with one line |
| `CHANNEL_NOT_BOOKABLE` | 409 | Government (`external_link`) hall | "Book via official channel" |
| `VENUE_KYC_REQUIRED` | 409 | Approve or enable instant before payout KYC | "Payouts: action needed" |
| `COUPON_INVALID`, `COUPON_NOT_APPLICABLE` | 422 | Coupon rejected | Inline message |
| `PAYMENT_WINDOW_CLOSED` | 409 | Session for a booking that is not `awaiting_deposit` | Booking detail |
| `PAYMENT_GATEWAY_ERROR` | 502 | Gateway unavailable | Retry or switch method |
| `ACCOUNT_DELETION_BLOCKED` | 409 | Future `confirmed` or `awaiting_deposit` booking | Blocked screen (cancel, or request deletion later) |
| `APP_UPDATE_REQUIRED` | 426 | `X-App-Version` below the minimum | Store link screen |

`OFFLINE` is a client-side condition, not an API code: approvals, declines, blocks, cancellations and payments are disabled in place and say "Offline. Reconnect to …".

## 6. Lists, search and the Brief

- **Cursor pagination** only: `?limit=20&cursor=…` (default 20, max 50). The cursor is opaque base64url; sort keys are stable and unique. No offsets.
- **Sorting** is an enumerated `sort` per resource (venues: `relevance`, `price_asc`, `price_desc`, `rating`, `newest`, `distance`).
- **Filters** mirror the PRD (CA-SRCH-*): `areaIds`, `priceMin`, `priceMax`, `capacityMin`, `setting`, `audience`, `amenities`, `instantOnly`, `availableOnDate`, `minRating`, `luxuryLevels`, `brandIds`, `q` (Arabic-normalised by the server).
- **Brief-aware endpoints.** Venue lists, details, Saved, Compare and the calendar accept `date`, `guests` and `audience` and return the computed price and availability per venue, already in fils, with the basis (`priceBasis`, `perGuest`) so cards never compute: `{ priceForBrief, priceBasis, minGuests, availability: { state, label } }`. The hero button's live count is `GET /v1/venues/count` with the same filters, cached.
- **Per-day calendar:** `GET /v1/venues/{id}/calendar?month=2027-01&guests=350&audience=women` returns for each day `{ date, state: available | held | unavailable | closed, fromPrice, tier, sessions[] }`. Other couples' requests are never visible.

## 7. Idempotency

| Rule | Detail |
|---|---|
| Required on | `POST /v1/bookings`, `POST /v1/bookings/{id}/payment-sessions`, approve, undo, decline, cancel, revoke, complete, cash-received, refunds and payouts (server side), amendments, venue block batches |
| Key | A UUID generated when the user taps the CTA and kept until the outcome is known. Retrying the same intent reuses it; a new intent (switching payment method after a failure, a new booking) generates a new one |
| Server | Stores `(key, userId, route, requestHash, responseStatus, responseBody)` for 24 h (**initial**). Same key and body replays the stored response with `Idempotent-Replayed: true`. Same key with a different body: `422 IDEMPOTENCY_KEY_REUSED`. A second call while the first runs: `409 IDEMPOTENCY_IN_PROGRESS` |
| Payment sessions | Same method retry returns the live session while it is valid, otherwise a new attempt linked to the same milestone |
| Webhooks | Not keyed by the client: the inbox row `(gateway, event_code, external_id)` makes duplicates no-ops |
| Client retry policy | Only idempotent `GET`s auto-retry (network errors and 5xx, max 3 with backoff). `POST`, `PATCH`, `DELETE`, OTP, booking creation and payments never auto-retry; a user-initiated retry reuses the key |

## 8. Concurrency and caching

- Bookings and settings documents carry `version`; responses set `ETag: "v7"`. Booking commands send `If-Match`. A lost compare-and-swap returns `409 BOOKING_STATE_CONFLICT` with the current status so the client renders "already updated" without another call. Settings `PUT` with a stale `If-Match` returns `412`.
- Public venue reads: `Cache-Control: public, max-age=60, stale-while-revalidate=300` with `ETag`. Brief-aware and personal responses are `private`. Availability and calendar: `private, no-cache` with `ETag`; any claim write invalidates the Redis availability keys, so a venue block reaches couples within seconds (HA-CAL-08). `GET /v1/home` is one composed response of at most 30 KB gzip, `private, must-revalidate`, and the client paints the cached payload while revalidating (NF-PERF-01). Images are content-hashed and immutable for a year.

## 9. Endpoint catalogue

Auth column: G guest allowed, C client, V venue member (permission key from [security-privacy](security-privacy.md)), P platform role. Screen IDs are from `docs/product/screens/`.

| Endpoint | Purpose | Auth, requirement |
|---|---|---|
| `POST /v1/auth/otp/request`, `/otp/verify` | WhatsApp code request and verification | G, CA-AUTH-05/06 |
| `POST /v1/auth/register`, `/password/login`, `/password/forgot`, `/password/reset` | Password account | G, CA-AUTH-01/02/07 |
| `POST /v1/auth/apple`, `/google`, `/refresh`, `/logout`, `/step-up` | Identity tokens, rotation, step-up | G / C, CA-AUTH-03/04 |
| `GET/PATCH /v1/me`, `DELETE /v1/me`, `PUT /v1/me/devices/{deviceId}` | Profile, permissions, deletion request, push token | C / V, CA-PROF-*, NF-PRIV-01 |
| `GET /v1/home` | Composed home | G, CA-HOME-* |
| `GET /v1/venues`, `GET /v1/venues/count` | Brief-aware search and live count | G, CA-SRCH-*, CA-CARD-* |
| `GET /v1/venues/{id}`, `/calendar`, `/quote`, `/reviews`, `/similar` | Details, per-day availability and prices, quote for a draft, reviews, similar | G, CA-VDET-* |
| `POST /v1/compare/prices` | Price and availability for up to 3 venues on the Brief | G, CA-CMP-* |
| `GET /v1/areas` | Governorates and areas with aliases | G, SA-AREA-01 |
| `GET/PUT/DELETE /v1/wishlist/{type}/{id}`, `GET /v1/wishlist` | Saved items; merge on sign-in | C, CA-PROF-03 |
| `POST /v1/quotes` | Server-priced quote for the Review step (valid 30 min, **initial**) | C, CA-BOOK-09/14 |
| `POST /v1/bookings` | Send request or start instant checkout (`quoteId`, consent flags) | C, CA-BOOK-10/15 |
| `GET /v1/bookings`, `GET /v1/bookings/{id}` | List, detail with `allowedActions` | C / V, CA-STAT-*, `CL-BKNG-01/02` |
| `PATCH /v1/bookings/{id}` | Edit while `requested` (re-snapshot) | C |
| `POST /v1/bookings/{id}/withdraw`, `/cancel`, `GET /cancellation-preview` | Withdraw, cancel with refund preview | C, CA-STAT-09, `CL-BKNG-03` |
| `POST /v1/bookings/{id}/proposals/{pid}/accept`, `/decline` | Answer "Venue proposed another date" | C, CA-STAT-10, `CL-BKNG-04` |
| `POST /v1/bookings/{id}/amendments`, `/cash-acknowledgement` | Guest-count update, cash acknowledgement | C |
| `POST /v1/bookings/{id}/payment-sessions`, `GET /v1/payments/{id}` | Hosted payment session and status | C, CA-PAY-*, `CL-PAYM-01..05` |
| `GET /v1/bookings/{id}/invoices`, `GET /v1/invoices/{id}/pdf` | Receipts, invoice, credit note | C / V, CA-BOOK-13, HA-BOOK-08 |
| `POST /v1/bookings/{id}/review` | Review a completed booking | C, CA-REV-* |
| `GET /v1/venue/today`, `GET /v1/venue/bookings?segment=` | Hotel Today, Pending / Upcoming / Past | V `booking:read`, HA-DASH-*, HA-BOOK-01 |
| `POST /v1/bookings/{id}/approve`, `/undo-approve`, `/decline`, `/proposals` | Accept (8 s undo), decline with reason, propose 1-3 dates | V `booking:approve`, `booking:decline`, `booking:propose_date`, HA-BOOK-03/04, `HL-DCSN-01..03` |
| `POST /v1/bookings/{id}/revoke`, `/venue-cancel`, `/reschedule`, `/complete`, `/no-show`, `/cash-received` | Venue commands on a booking | V per key, HA-BOOK-05/10/11 |
| `GET /v1/venue/calendar`, `POST /v1/venue/blocks`, `DELETE /v1/venue/blocks/{batchId}` | Lanes and sessions, block and open dates | V `calendar:*`, HA-CAL-*, `HL-CALN-*` |
| `GET/POST/PATCH /v1/venue/offers`, `GET/PATCH /v1/venue/packages`, `GET/PUT /v1/venue/policies`, `PUT /v1/venue/media` | Offers, limited package pricing, policy template, media | V, HA-OFFR-*, HA-VMGT-* |
| `GET /v1/venue/analytics/*`, `GET /v1/venue/reviews`, `POST /v1/venue/reviews/{id}/reply` | Funnel, revenue, reviews | V, HA-ANLY-* |
| `GET/POST/PATCH /v1/venue/staff`, `GET/PUT /v1/venue/bank-info`, `PUT /v1/venue/hours` | Staff, bank (step-up), hours | V `staff:write`, `bank:*`, HA-SET-* |
| `GET /v1/conversations`, `GET /v1/conversations/{id}/messages?afterSeq=` | Inbox, history (Socket.IO for live) | C / V, CA-CHAT-*, HA-MSG-* |
| `GET /v1/notifications`, `POST /v1/notifications/{id}/read`, `GET/PUT /v1/notification-preferences` | Centre and preferences | C / V, CA-NOTI-*, HA-NOTI-* |
| `POST /v1/planner/consultations`, `GET /v1/services`, `POST /v1/vendor-leads` | Planner and vendor requests | C, CA-PLAN-*, CA-SVC-* |
| `POST /v1/events` | Analytics batch (section 11) | G / C / V, NF-ANL-* |
| `POST /webhooks/myfatoorah`, `POST /webhooks/whatsapp` | Gateway and WhatsApp status inbound | signature |

Refund issuing, payouts, commission, holiday and authority-order administration, venue approval and CMS belong to the platform and dashboard API under `/v1/admin/*` (roles in [security-privacy](security-privacy.md)); they are web-only and out of this phase.

## 10. Realtime and notifications

- **Chat (MVP-P2, PL-CORE-01):** Socket.IO, `transports: ['websocket']`, token in the handshake `auth`, Redis adapter. Events: `message:send` (ack with `seq`), `message:new`, `message:delivered`, `message:read`, `conversation:resume { lastSeq }`. Every message has a client-generated `clientMsgId` (idempotent send) and a server `seq` per conversation; reconnect resumes from `lastSeq`; history is cursor REST; FCM covers offline users; media goes direct to GCS by V4 signed URLs; voice is AAC.
- **Booking updates in P1** need no socket: pushes carry `data.link` HTTPS deep links (`/c/*` client, `/v/*` hotel) and the apps refetch on foreground and on the push tap. Deferred client notifications for approvals honour the undo window ([booking-state-machine](booking-state-machine.md)).
- Notification dispatch is server-side by event type, user preference and saved locale; the same event may produce push, WhatsApp and email.

## 11. Analytics ingestion

`POST /v1/events` takes a batch of up to 20 events or 30 s of events, at-least-once, deduplicated on `event_id`, answered `202 { accepted, rejected: [{ eventId, code }] }`. Events are `object_verb_pastTense` snake_case, validated against `packages/contracts/analytics/events.json`; an unregistered event fails client CI. Client events are advisory; revenue and conversion use server events (`booking_status_changed`, `payment_succeeded`, `refund_completed`). No names, phones, emails, IBANs, card data or free text in any event.

## 12. Versioning and change policy

- `/v1` stays additive: new optional fields, new endpoints, new optional query parameters. Removing or renaming a field, narrowing a type, adding a required request field or changing semantics is breaking: oasdiff fails the PR and the change goes to `/v2` or behind a minimum-app-version gate.
- Mobile clients live for months after a release, so the API supports the current and the previous minor app version for at least 6 months (**initial**); `Deprecation` and `Sunset` headers announce removals; `426 APP_UPDATE_REQUIRED` is the last resort.
- Spectral rules: every operation has `security`, an `x-permissions` list, `Idempotency-Key` where required, problem+json for all `4xx` and `5xx`, ids declared with `.meta({ id })`, and no inline anonymous schemas.
- Contract tests: Prism must serve every fixture; the TS and Dart suites load the same fixtures; payment webhook scenarios run against a scripted fake gateway ([pricing-and-payments](pricing-and-payments.md)).

Next: [design-to-code](design-to-code.md).
