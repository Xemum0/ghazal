# Backend handoff: implementing `ghazal.v1.yaml` in NestJS

> Status: written with the contract (F1c part i, ADR 0036). Audience: the NestJS team. Source of truth: `packages/contracts/openapi/ghazal.v1.yaml` (OpenAPI 3.1, 217 operations, 463 schemas, 23 tags), assembled from `paths/<tag>.yaml` and `schemas/<tag>.yaml`. Read with [api-conventions](api-conventions.md) (wire rules), [api-coverage](api-coverage.md) (every prototype read and write mapped to an operation), [booking-state-machine](booking-state-machine.md) (R01-R14), [voucher model](../product/voucher-model.md) and ADR 0033, 0035, 0028, 0027. Where api-conventions still describes the pre-voucher booking (deposits, payment sessions on bookings, `/v1/venue/*`), **this contract wins**: see its amendment banner.

## 1. What you get

| Artifact | Use |
|---|---|
| `ghazal.v1.yaml` / `.json` | The contract. Generate Nest DTOs and validation from it; serve it at `/docs`. |
| `x-error-codes` (in the file) | Stable problem+json codes with their HTTP status (54 codes). One exception filter maps domain errors to them. |
| `x-roles`, `x-permissions`, `x-access`, `x-idempotent`, `x-if-match` on every operation | Guard and interceptor metadata, see sections 3 and 5. |
| `packages/contracts/fixtures/*.json` + `openapi/scripts/fixtures-to-wire.mjs` | 1,486 bilingual seed objects that all validate against the schemas, and the exact fixture-to-wire mapping (what is stripped or added). Use as seed data and golden bodies. |
| `packages/contracts/src/engine/*.ts` | The executable spec of pricing (`pricing.ts`), availability (`availability.ts`), voucher rules (`voucher.ts`), transitions R01-R13 (`transitions.ts`), visit slots, SLA. Port or import it; the Dart mock ports it too and is proven equal on shared cases (F1c part ii). |
| `packages/ghazal_mock_api` (F1c part ii) | A readable Dart implementation of every rule below over an in-memory database. |

## 2. Module map

One NestJS module per OpenAPI tag. The controller of a module owns exactly the operations of that tag; cross-module calls go through services, never controllers.

| Tag (module) | Ops | Owns | Collaborates with |
|---|---|---|---|
| `auth` | 17 | OTP (WhatsApp), password, Apple, Google, partner email login, refresh rotation, step-up, invitation acceptance | `profile`, `partner-account`, Resend |
| `home` | 3 | composed home, `/config`, analytics ingestion | `venues`, `requests`, `visits`, `notifications` |
| `venues` | 11 | search, taxonomy, detail, availability, quotes, compare, areas | pricing and availability engines |
| `vouchers` | 8 | wallet, checkout, gateway session, rebind, receipts | `payments` (gateway adapter, ADR 0027), `requests` |
| `requests` | 10 | client commands R01, R07, R08, R05, R10a, R13a, issue report | state machine, `vouchers`, availability claims |
| `visits` | 9 | client visit booking and group chat creation | `chat`, `partner-visits` |
| `chat` | 9 | conversations, messages, drafts, uploads (REST fallback of Socket.IO) | gateway, FCM |
| `notifications` | 6 | centre and client preferences | dispatch service (push, WhatsApp, email) |
| `reviews` | 2 | venue reviews, writing a review | `partner-reviews` |
| `wedding` | 18 | wedding profile, checklist, budget, favourites | `requests` (auto items) |
| `services` | 6 | categories, providers with an active listing, provider quotes, quote requests | `partner-listings` |
| `planners` | 5 | planner packages, consultation requests, meetings | support call centre |
| `profile` | 6 | me, devices, phone change, account deletion | `auth` |
| `support` | 6 | support conversation, refund (credit voucher) requests, FAQ, legal documents | `vouchers`, `chat` |
| `partner-account` | 13 | memberships, account type, context, staff, invitations, preferences | `auth` |
| `partner-requests` | 10 | Today, Needs you, inbox, accept, undo, decline, propose, revoke, cancel | state machine |
| `partner-bookings` | 4 | redeem by code or QR, redeemed list | `vouchers`, state machine |
| `partner-calendar` | 9 | calendar ranges, day, blocks, holds, soft dates, email sync | availability claims, Resend |
| `partner-venue` | 23 | profile, halls, packages and price rules, extras, policies, rules, hours, media | pricing engine, upload service |
| `partner-visits` | 10 | partner visit commands, availability | `visits`, `chat` |
| `partner-growth` | 6 | voucher price windows, analytics | pricing engine, analytics store |
| `partner-listings` | 20 | provider listings, review trail, plans, billing, fee refund records, provider packages | gateway (plan payment), moderation (Super Admin) |
| `partner-reviews` | 6 | review inbox, reply once, report, removal request | support |

Tag `partner-visits` is an addition to the list in the build plan (the plan's `visits` covered both sides); it keeps the partner permission `visit:manage` in one module.

## 3. Roles, guards and context

Three roles reach this API (the Super Admin web API under `/v1/admin/*` is out of the contract): **client** (couples), **partner staff** (hotel, hall and provider accounts), **support** (Ghazal call centre and the support representative in visit group chats). Support acts through the web admin and the chat gateway; the REST contract only shows its effects (replies in support and visit chats, refund-request decisions, moderation).

| Guard | Rule |
|---|---|
| `JwtAuthGuard` | ES256 access token (10 min, claims `sub`, `sid`, `typ`, `ver`). `x-access: guest` skips it, `optional` accepts a missing token (guests see public data). 401 `TOKEN_EXPIRED` vs `AUTH_REQUIRED` vs `SESSION_REVOKED` exactly as in api-conventions section 5. |
| `RolesGuard` | `x-roles` of the operation: `client`, `partner` (token `typ`). Operations with both (chat, notifications, `/me`, `/config`) branch on the role inside the service. |
| `PhoneVerifiedGuard` | Request, voucher checkout, conversation start, visit booking, quote request and consultation need a verified phone: `403 PHONE_VERIFICATION_REQUIRED` (the app verifies inline and resumes). |
| `PartnerContextGuard` | Every `partner-*` call (and shared ones with a partner token) needs `X-Venue-Id` or `X-Provider-Id`; membership is validated on every call (`400 VENUE_CONTEXT_REQUIRED`, `403 FORBIDDEN`). The id is never trusted alone. |
| `PermissionsGuard` | `x-permissions` of the operation against the member's role, resolved per request from a cached lookup (never in the token). The keys in use: `booking:read booking:approve booking:decline booking:propose_date booking:cancel booking:revoke calendar:read calendar:block chat:write offer:write analytics:read package:write policy:write media:write review:reply review:report staff:write visit:manage voucher:redeem`. `voucher:redeem` and `visit:manage` are new or derived: add them to the matrix in [security-privacy](security-privacy.md) (Admin, Manager, Reception hold `voucher:redeem`; `payment:record_cash`, `revenue:read`, `bank:*` and `refund:create` are retired by ADR 0033). |
| `StepUpGuard` | Operations whose `x-errors` list `STEP_UP_REQUIRED` (staff invitations, role changes, deactivation, account deletion) need the `X-Step-Up` token from `POST /auth/step-up` (5 minutes). |
| Tenant guard | `venue_id` / `provider_id` on every scoped table; a generated isolation test (venue A cannot read or write venue B) runs in CI over the route list. |

## 4. DTOs and validation

* Generate DTO classes from the schemas (for example `openapi-typescript` for types plus `zod` or `class-validator` schemas generated from the same file). Never hand-write a second source of truth.
* `additionalProperties` is open on responses (clients ignore unknown fields) and **closed on request bodies** (`forbidNonWhitelisted`): an unknown field is `422 VALIDATION_FAILED` with `errors[].path`.
* Money is `{ fils: integer, currency: 'KWD' }`; reject floats and negatives except on signed price lines. Civil dates `YYYY-MM-DD` are never converted through a time zone; instants are stored UTC and serialised with the `+03:00` offset (Kuwait has no DST) by one serializer. Times are `HH:mm` venue-local.
* Localised text is `{ en, ar }` with a missing language `null`; user-typed text (names, notes, chat) is stored as typed and never translated.
* Enum values on the wire are the lowercase strings of the schemas; add new values only with a minimum-app-version gate (clients degrade to `unknown`).
* Validation failures use `VALIDATION_FAILED` with field codes such as `GUESTS_OUT_OF_RANGE`; the voucher price rule of `PriceRuleInput` (15% to 35% below the standard price, always lower) reports `VOUCHER_DISCOUNT_OUT_OF_RANGE` on `rules[n].voucherPerGuest` or `voucherFlat`.
* Responses are validated against the schema in dev and test (the contract is the test oracle).

## 5. Idempotency and concurrency

`x-idempotent` is set on 54 operations (every money, slot, request-state and create command; the full list is in [api-coverage](api-coverage.md) with flag `I`). Rules are those of api-conventions section 7: key per user intent, stored `(key, userId, route, requestHash, status, body)` for 24 h, replay with `Idempotent-Replayed: true`, `422 IDEMPOTENCY_KEY_REUSED`, `409 IDEMPOTENCY_IN_PROGRESS`. Chat sends are idempotent on `clientMsgId`, not on the header.

`x-if-match` is set on 16 commands: the 10 request commands (`confirmRequest`, `withdrawRequest`, `cancelRequest`, `acceptProposal`, `declineProposal`, `acceptRequest`, `declineRequest`, `proposeDates`, `revokeApproval`, `cancelConfirmedRequest`) and 6 settings documents (`updatePartnerVenue`, `updateHall`, `updatePackage`, `putVenuePolicies`, `putBookingRules`, `updateListing`). `Booking.version` is the `ETag` (`"v7"`). A lost compare-and-swap on a request is `409 BOOKING_STATE_CONFLICT` with `currentStatus` and `currentVersion` in the body; a stale settings document is `412 PRECONDITION_FAILED`.

Slot claims (approval holds, blocks, confirmed requests) use a database exclusion constraint per `(hall, date, session)`; a claim failure is `409 SLOT_UNAVAILABLE` with `alternatives`. Requests themselves never claim (ADR 0001 D5): only approval inserts a hold.

## 6. Which rule lives where

All of it lives on the server. The apps hold **no** business rule beyond display helpers (formatting, countdown ticking, hiding an action that `allowedActions` omits).

| Rule | Owner | Notes |
|---|---|---|
| Price per package, tier precedence, complimentary guests, service charge | pricing engine (`engine/pricing.ts`) | Two columns on every quote: standard and voucher. `Quote.voucherOffered` is `savings > voucherFee`. Quotes carry `quoteId` valid 30 min; `QUOTE_CHANGED` when repriced. |
| Card price grammar (`CardPrice`), `fromPrice` per day | pricing and availability engines | Brief-aware reads return computed prices; the client never computes. |
| Availability, lead time (2 days), season, blocks, holds | availability engine plus claims | Other couples' requests are never visible; the client never learns why a day is closed (ADR 0002 D8). |
| Request state machine R01-R14 and `allowedActions` | `engine/transitions.ts` as the single table | R03u undo within 8 s; R05 accept proposal; R09 lapse; R12 completion at event end plus 12 h; R14 admin override is web only. |
| Open-request limit (3 pending plus approved per wedding file) | `requests` | `OPEN_REQUEST_LIMIT`. |
| 24 h confirm window | `confirmBy = approvedAt + 24 h`, fixed, not partner-configurable | Lapse forfeits the voucher (ADR 0035 D4). Client notifications for an approval honour the 8 s undo window. |
| Counter-offer | 1 to 3 dates, 48 h, voucher price held, request stays `pending` | One kind of proposal; no reschedule after confirmation (A-05). |
| Reply SLA | 24 h default, 4 h when the event is 14 days or less away; partner setting 12/24/48 h | Thresholds in `PlatformConfig`. |
| Voucher lifecycle (`unpaid`, `active`, `bound`, `used`, `expired`, `forfeited`, `credit_issued`) | `engine/voucher.ts` | Validity 60 days from payment, never past event date plus 12 h; reuse window 60 days at the same target after a release; checkout lapses after 30 minutes unpaid. Numbers come from `PlatformConfig`, never literals. |
| Release outcomes and credit eligibility | `releaseOutcome(reason)` | Venue-fault releases (declined, no reply, revoked, venue cancelled, suspended, slot taken) are credit-eligible; client withdrawal is reusable but not credit-eligible; a lapsed confirm window and a cancel after confirm are neither. |
| Credit voucher | granted by support on a refund request | Unbound, 60 days, usable at any hall, hotel or service; binds to the target when a request is sent; never money; the gateway `refund` call is not used for vouchers. |
| Redemption checks | `partner-bookings` | Code belongs to this partner, request is `confirmed`, voucher `bound` and unused: `VOUCHER_UNKNOWN`, `VOUCHER_OTHER_PARTNER`, `VOUCHER_NOT_CONFIRMED`, `VOUCHER_ALREADY_USED`. `checkVoucherCode` always answers 200 so the screen can show the specific calm error. |
| Visits | free, independent of the voucher, hotels and halls only | 30-minute windows from partner weekly rules; one group chat of exactly three roles per visit; read-only 24 h after the slot (at once on cancel or decline), archived 30 days later. |
| Listing lifecycle | `draft`, `payment_pending`, `pending_review`, `approved`, `rejected`, `active`, `expired`, `paused` | Never published on payment; plan period starts at approval; a material edit of an active listing returns it to review while the approved version stays live (A-09). While any plan rate is null the pay step answers `409 PLAN_RATES_NOT_ANNOUNCED`. Major hotels (`feeExempt`) pay nothing and are still reviewed. |
| Partner reliability strikes | revoke and venue cancel after approval | No compensation promised in the app. |
| Reviews | reply once, report; hide or delete only through support | A review waits for a reply once it is 7+ days old without one. |
| Notifications | dispatched by event, preference and saved locale | One event may produce push, WhatsApp and email; copy renders on the device from `kind` and `params`. |

## 7. Scheduled work

| Job | Trigger | Effect |
|---|---|---|
| Expire pending | `respondBy` passed | R06: `expired` (`venue_no_response`), voucher released, credit-eligible |
| Expire approval | `confirmBy` passed | R09: `expired` (`client_no_confirmation`), voucher `forfeited`, hold released |
| Expire counter-offer | 48 h | proposal `expired`, request stays `pending` until `respondBy` |
| Complete | event end plus 12 h | R12: `completed`, voucher `used` if not redeemed |
| Voucher validity | `validUntil` / `reuseUntil` | `active` to `expired` |
| Checkout lapse | 30 minutes unpaid | unpaid voucher discarded, nothing charged |
| Visit chat | slot plus 24 h; plus 30 days | read-only, then archived |
| Listing expiry | plan end; reminders at -7 and -1 days | `expired`, hidden from search |
| Undo window | 8 s after approval | the client notification of an approval is sent only when the window closes |

## 8. What the mock fakes (and how a real service replaces it)

| Concern | Real service | Mock behaviour |
|---|---|---|
| Client OTP | Meta WhatsApp Cloud API authentication template | `123456` or any 6-digit code verifies an open challenge; `000000` is locked (423 `OTP_LOCKED`), `111111` expired (410 `OTP_EXPIRED`), `222222` is the wrong code (400 `OTP_INVALID`, `params.remainingAttempts` counts down from 4; the fifth wrong code locks the challenge for good, a right code no longer helps); the sixth code to one phone inside a story minute is `429 RATE_LIMITED` (a strict 60 s resend rule would lock a demo out while the clock is frozen). The real service keeps the attempt counter per challenge exactly like this |
| Partner email and codes | Resend | the code is `123456` and follows the three special codes and the attempt counter above (`000000`, `111111`, `222222`); every email is appended to an inspectable outbox (`/__mock/outbox`) |
| Social sign-in | provider JWKS verification | the identity token is accepted when it parses; the name comes from the token or the body |
| Payment gateway | MyFatoorah hosted pages, webhook plus status re-query (ADR 0027) | `createPaymentSession` returns a hosted-page URL of the mock; the session settles by itself as succeeded after 1.5 s (real timer), or earlier and with another outcome through `payments/{id}/settle` (succeeded, failed, cancelled); `gateway {down: true}` makes new sessions answer 502; the state machine of the voucher is the real one |
| Push (FCM) | Firebase | none; the notification centre is filled by the handlers that would send a push |
| Media upload | signed URLs to object storage | the signed URL points to `/__mock/uploads/{id}` which accepts a PUT and stores nothing; limits (video 500 MB) and types are enforced when the session is created; completing a photo upload reuses a seeded photograph so the library renders |
| Realtime chat | Socket.IO gateway | REST only: the app polls `listMessages?afterSeq=` |
| Support staffing | call centre | support replies to the support conversation and to visit group chats are scripted on a timer; refund requests are decided by the control endpoint (grant creates the credit voucher, decline carries a reason) |
| Moderation | Super Admin web | listing approval and rejection through the control endpoint |
| Clock | system | frozen at `2026-11-12T16:00+03:00` (story time), moved only through the control surface; the system jobs of section 7 (R06, R09, R12, validity, checkout lapse) run lazily at the start of every request and after every clock move; the 8 s undo window and the payment answer use real timers |

What was built (2026-10-20, F1c part ii; full description in [mock-api](mock-api.md)): `packages/ghazal_mock_api` serves all 217 operations in-process (dio adapter) or standalone (`dart run ghazal_mock_api:serve`, reserved port of `node tools/ports.mjs url api`); the Dart handlers in `lib/src/handlers/<tag>.dart` and the rules in `lib/src/domain` and `lib/src/engine` are the readable executable spec of every transition, guard and error code listed in this file. Pricing, availability, voucher life cycle, transitions, SLA and search are ports of `packages/contracts/src` proven equal on 2,170 shared cases (`packages/contracts/fixtures/engine-cases.json`).

Mock control surface (not part of the product API; `POST` under `/__mock` unless noted; the same operations exist in code as `MockBackend.control`): `reset`; `clock {now | advanceDays | advanceHours | advanceMinutes}` (drives R06, R09, R12 and every countdown); `persona {persona}` (token-less calls act as `guest | new_client | reem | hotel_admin | hotel_manager | hotel_non_major | provider`) and `session {persona}` (tokens only); `scenario {scenario, latencyMs}`; `gateway {down}`; `payments/{id}/settle {outcome}`; `listings/{id}/moderate {action: approve | reject, codes, note}`; `support/refund-requests/{id}/decide {action: grant | decline, reason}`; `visits/{id}/support-reply`; `story {point}` (jumps the hero request to a prepared state); `rival` (puts the competing request of Dalal for Thursday 14 January into the database: five requests wait at the story start, the web adds the sixth only when its Decision screen simulates it); `flush`; `plans/{cycle}/rate` and `listings/{id}/billing` (test hooks: no plan rate exists, so a listing fee can only be paid after a test sets one); `GET state | outbox | events`; `shutdown` (standalone). Request headers `X-Mock-Latency` and `X-Mock-Scenario` (`slow`, `error`, `offline`, `empty`, `expired`) apply to a single call; the control surface sets the sticky version.

## 9. Contract tests and how to run them

| Check | Command | What it proves |
|---|---|---|
| Bundle is current | `node tools/bundle-openapi.mjs --check` | the committed `ghazal.v1.yaml` equals its sources |
| Lint | `npx @redocly/cli lint --config packages/contracts/openapi/redocly.yaml packages/contracts/openapi/ghazal.v1.yaml` | valid OpenAPI 3.1, every operation has an id, a 4xx and security, examples match their schemas |
| Fixtures fit | `node packages/contracts/openapi/scripts/fixtures-to-wire.mjs --check` | 1,513 fixture objects and hero examples validate against the component schemas |
| Coverage | `node packages/contracts/openapi/scripts/gen-coverage.mjs --check` | every selector, store action and operation is mapped ([api-coverage](api-coverage.md)) |
| Dart models | `node tools/gen-dart-models.mjs --check` then `cd packages/ghazal_domain && flutter test` | generated code is current; every sample round-trips through its model |
| Client plumbing | `cd packages/ghazal_api && flutter test` | auth refresh single-flight, idempotency, problem+json, pagination, retry |
| Mock serves the whole contract | `node tools/contract-test.mjs` | starts the standalone mock, calls all 217 operations with schema-valid requests and validates every response (and every error body) against `ghazal.v1.json` with Ajv; prints operations hit / 217 |
| Mock equals the TypeScript engine | `node tools/export-engine-cases.mjs --check`, `flutter test packages/ghazal_mock_api/test/engine_equality_test.dart` | 2,170 shared cases: quotes, availability, vouchers, transitions, SLA, visits, search |
| Client and mock agree (typed) | `flutter test packages/ghazal_mock_api/test` | the real `ghazal_api` repositories drive the hero story, forfeit by clock, credit voucher, listing review, visits and chat, staff, scenarios |
| Mock shows what the web shows | `node tools/export-selector-cases.mjs` then `flutter test packages/ghazal_mock_api/test/selector_equality_test.dart` | 148 cases run through the real handlers against the ids, order and counts of the prototype's selectors and screens: Home shelves and counts, every Results filter and sort, the region search, package prices per hall, availability, quotes with extras, compare, reviews, and the Partner today, Needs-you, request segments, calendar, notifications and conversations of the hero partner (see mock-api.md, "Known differences from the web" for what is not covered) |

For the backend: validate every response of your e2e tests against `ghazal.v1.json` (for example with `jest-openapi` or Ajv in a test interceptor), seed the database from the fixtures through `fixtures-to-wire.mjs`, run `oasdiff` against `main` on every PR (api-conventions section 12) and replay the hero story (Reem requests Danah Ballroom, the hotel approves, she confirms inside 24 h, the hotel redeems the voucher) end to end. The Dart handlers of `ghazal_mock_api` are the readable executable spec of every transition and error code.

## 10. Contract decisions the owner should know

1. **Paths.** `/v1/requests` (client) and `/v1/partner/*` (partner) replace `/v1/bookings` and `/v1/venue/*`, because a request is not a booking with money and the Partner app also serves service providers. The booking table and the `GZ-YYMM-XXXX` reference stay.
2. **Two partner context headers.** `X-Venue-Id` (hotel or hall) and the new `X-Provider-Id` (provider account).
3. **Instants carry `+03:00`**, not `Z`, so fixtures, screens and the wire agree; clients store UTC and write Kuwait time back.
4. **Partner sign-in is email plus password with a code on a new device**, staff are invited by email, calendar sync is by email (ADR 0035 D8): no WhatsApp for partners.
5. **`partner-visits` is its own module/tag**, and `visit:manage` and `voucher:redeem` are permission keys to add to the role matrix.
6. **No endpoint exists for** rewards, invoices, cash, revenue, deposits, balances, commissions or payouts (retired screens HL-BOOK-05, HL-DCSN-05, HL-GROW-05, CL-RVRW-03/04). If they return, they are a new contract version.
7. **Plan rates are nullable** (`AdPlan.ratesFils`, `PlanRate.announcedSoon`, `BillingView.payable`); `createListingPaymentSession` is refused with `PLAN_RATES_NOT_ANNOUNCED` until the Super Admin sets them. No number appears anywhere in the contract or the fixtures.
8. **Credit vouchers are unbound**: `createRequest` with a credit voucher binds it to the request target at that moment; `VOUCHER_TARGET_MISMATCH` applies only to bound vouchers.
9. **Chat is REST-complete** (conversations, messages, drafts, attachments) so the mock and a degraded client work without Socket.IO; Socket.IO events stay outside OpenAPI.
10. **Terms and Privacy are served by the API** (`getLegalDocument`), editable in the Super Admin panel (ADR 0035 D9).
