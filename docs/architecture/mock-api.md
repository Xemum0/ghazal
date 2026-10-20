# The Ghazal mock API (`packages/ghazal_mock_api`)

A pure Dart implementation of the whole REST contract (`packages/contracts/openapi/ghazal.v1.yaml`: 217 operations, 23 tags) over an in-memory database seeded from the prototype's fixtures. It is the backend of both Flutter apps during F2-F4 and the readable, executable specification the NestJS backend is written against (`backend-handoff.md`). Status 2026-10-20 (F1c part ii): all 217 operations served, contract test 217 of 217, engine equal to the TypeScript engine on 2,170 shared cases, 54 Dart tests green.

## Two hosting modes, one code base

**In-process** (apps, simulator, tests; no sockets, nothing to start). `MockBackend.httpClientAdapter` is a dio `HttpClientAdapter`; the shelf handler answers inside the process.

```dart
final mock = await MockBackend.create(
  seed: SeedSource.fromLoader((p) => rootBundle.loadString('packages/ghazal_mock_api/assets/$p')), // apps; tests and the server read the package folder
  persona: 'guest', autoRun: true);
final client = GzApiClient.create(config: cfg, environment: env, tokens: store, adapter: mock.httpClientAdapter);
```

**Standalone** (both apps share one world, so the client-to-partner story propagates; `curl` works):

```
dart run ghazal_mock_api:serve [--port N] [--persona reem] [--scenario slow] [--latency 200] [--clock ISO] [--log]
node tools/ports.mjs url api       # the reserved port: 4701 + 10 * slot (GZ_SLOT); `node tools/ports.mjs check api` verifies identity
```

The server answers `GET /__gz` (the identity handshake of `tools/ports.mjs`: app `api`, slot, rootHash), serves `/v1/*`, `/__mock/*` and the photographs under `/images/`, adds CORS, and stops on `POST /__mock/shutdown`. (`dart run` resolves inside the workspace as it is; this Dart has no `--no-pub` flag.) `MockBackend.serve(port:)` does the same from code and returns a `MockServer` with `url` (the API base, `http://127.0.0.1:4701/v1`).

Base URL in the in-process mode is `http://mock.ghazal.local/v1` (`GzApiConfig` default); the router mounts every path under `/v1`.

## Who is who (personas) and how to sign in

| Persona key | Who | Sign-in |
|---|---|---|
| `guest` | anonymous | no token (the real behaviour of gated calls: 401 `AUTH_REQUIRED`) |
| `new_client` | Nora Al-Mutairi, no history, verified phone `+96550000099` | OTP |
| `reem` | Reem Al-Dosari, the hero story, `+96550000012` | OTP or password `Ghazal#2026` |
| `hotel_admin` | Khalid Al-Otaibi, admin (owner) of Aurelia Gulf Hotel (V01, fee-exempt major hotel) | `khalid@aurelia-gulf.example` / `Ghazal#2026` |
| `hotel_manager` | Hind Al-Enezi, manager of V01 | `hind@aurelia-gulf.example` / `Ghazal#2026` |
| `hotel_non_major` | Badriya Al-Kandari, admin of Lumi Marina Hotel (V05, pays fees) | `badriya@lumi-marina.example` / `Ghazal#2026` |
| `provider` | Zahra, owner of Zahra Floral Studio (`vendor-flowers-zahra`, five listings in several review states) | `zahra@zahra-floral.example` / `Ghazal#2026` |

* **Client OTP** (WhatsApp in production): the code is `123456` or any 6 digits; `000000` is locked (423 `OTP_LOCKED`), `111111` is expired (410 `OTP_EXPIRED`). An unknown phone becomes a new client (`isNewUser: true`). More than five codes to one phone inside one story minute is `429 RATE_LIMITED` (the clock is frozen, so a strict 60 s resend rule would lock a demo out).
* **Partner**: email plus password; a new device (unknown `deviceId`) answers `code_required` and the code is `123456` (also in the outbox); the same device then signs in directly. Staff invited by an admin appear in the outbox with an invitation token; accepting it sets their password.
* Social sign-in accepts any identity token; a JWT-shaped token gives `sub`, `email`, `name`. The account has no verified phone, so requests, checkout and chat answer 403 `PHONE_VERIFICATION_REQUIRED` until `verify_phone`.
* Roles are enforced where it matters: staff management is `admin` only, approve/decline/propose/revoke/cancel are `admin` and `manager`, redeeming is `admin`, `manager`, `reception`. A client token on a `/partner/*` route is 403; a partner call needs `X-Venue-Id` or `X-Provider-Id` (or a single membership, or a context chosen with `switchPartnerContext`).
* A persona can also act without a token: `persona: 'reem'` in `create`, `control.setPersona`, or `--persona reem` makes token-less calls act as that persona (what the Demo tools and the shot harness want). `control.sessionFor(persona)` returns real tokens for a `TokenStore`.

## The clock

The story clock starts at `2026-11-12T16:00:00+03:00` (the prototype clock, so countdowns match the design) and moves only through the control surface: `control.setClock(DateTime)`, `control.advance(Duration)` or `POST /__mock/clock {now | advanceDays | advanceHours | advanceMinutes}`. System jobs run lazily at the start of every request and after every clock move (`domain/jobs.dart`): R06 pending expires at `respondBy`, R09 the 24 h window forfeits the voucher, R12 complete at event end plus 12 h, counter-offer expiry (48 h), voucher validity and the 60-day reuse window, unpaid checkout lapse (30 min), visits `arrived` to `completed`, chat read-only after the slot plus 24 h.

Two things use real time because the story clock is frozen: the **mock payment gateway** settles a session after `gatewayDelay` (1.5 s) and the **8 s approval undo window** closes after 8 s (the client hears of an approval only then) and the **scripted chat replies** arrive after `botDelay` (2.5 s). Tests create the mock with `autoRun: false` and call `await control.flush()` to run all of it at once.

## Scenarios and latency

Per call by header, or sticky through the control surface (`setScenario`, `setLatency`, `POST /__mock/scenario {scenario, latencyMs}`):

| Header | Effect |
|---|---|
| `X-Mock-Latency: 800` | adds 800 ms |
| `X-Mock-Scenario: slow` | 1.5 s delay unless a latency is set |
| `error` | `500` problem+json, code `INTERNAL_ERROR` (outside the contract table: fault injection) |
| `offline` | the in-process adapter throws a connection error (`DioException.connectionError`, which `GzApiClient` maps to `ApiProblem.offline()`); the standalone server answers `503` with `X-Mock-Offline: 1` |
| `empty` | every list and page comes back empty (also `getHome` shelves, Today, windows, listings, staff, visit dates and slots) |
| `expired` | the first authenticated call with each access token answers `401 TOKEN_EXPIRED`; the client refreshes once (single flight), replays and carries on |

Other middleware: `X-App-Version` below `1.0.0` is `426 APP_UPDATE_REQUIRED`; `Idempotency-Key` replays the stored answer of the same user, route and body (`Idempotent-Replayed: true`) and a different body is `422 IDEMPOTENCY_KEY_REUSED`; request bodies and query parameters are validated against the contract schemas (`422 VALIDATION_FAILED` with `errors[{path, code}]`); cursors are opaque base64url offsets (`limit` default 20, max 50, bad cursor 422); `If-Match` on the 16 flagged operations (a stale request tag is `409 BOOKING_STATE_CONFLICT` with `currentStatus` and `currentVersion`, a stale settings tag is `412 PRECONDITION_FAILED`; the matching `GET`s send `ETag: "vN"`); problem+json with `type`, `title`, `status`, `code`, `requestId`, `params`, `errors`, `alternatives`.

## The control surface (not part of the product API)

In code: `MockBackend.control` (`MockControl`). Over HTTP: `POST /__mock/<name>` with a JSON body (the in-process adapter answers them too, at `http://mock.ghazal.local/__mock/...`).

| `MockControl` | HTTP | Does |
|---|---|---|
| `reset()` | `reset` | seeds again, clock back, no sessions, no pending work (persona, scenario, latency stay) |
| `setClock(at)`, `advance(d)` | `clock` | moves story time and runs the jobs that fall due |
| `setPersona(key)`, `sessionFor(key)` | `persona`, `session` | token-less calls act as the persona; tokens of a persona session |
| `setScenario(s)`, `setLatency(d)` | `scenario {scenario, latencyMs}` | sticky scenario and latency |
| `settlePayment(id, outcome: succeeded \| failed \| cancelled)` | `payments/{id}/settle` | the gateway answers now (succeeded activates the voucher, or moves a paid listing to review) |
| `setGatewayDown(bool)` | `gateway {down}` | new payment sessions answer 502 `PAYMENT_GATEWAY_ERROR` |
| `moderateListing(id, approve:, codes:, note:)` | `listings/{id}/moderate {action: approve \| reject, codes, note}` | Super Admin moderation: pending review to active, or rejected with codes and a note |
| `decideRefund(id, grant:, reason:)` | `support/refund-requests/{id}/decide {action: grant \| decline, reason}` | grant creates the credit voucher (original voucher becomes `credit_issued`), decline carries a reason |
| `supportReply(visitId, text:)` | `visits/{id}/support-reply` | a message from Ghazal support in the visit group chat |
| `jumpToStory(point)` | `story {point}` | the hero request in one of `storyPoints`: pending, approved, confirmed, redeemed, completed, declined, expired, lapsed, cancelled, counter_offer (booking, voucher, claims and the client notification) |
| `setPlanRate(cycle, fils)` | `plans/{cycle}/rate {ratesFils}` | test hook: while null (the real state) paying a listing is 409 `PLAN_RATES_NOT_ANNOUNCED` |
| `markListingPaid(id, amountFils:)` | `listings/{id}/billing` | test hook: a paid listing, so the fee-refund record can be exercised |
| `flush()` | `flush` | runs the pending gateway, chat-reply and undo-window work now |
| `outbox`, `events`, `state` | `GET outbox`, `events`, `state` | the emails the mock "sent", the event log, a summary for the Demo tools |

`POST /__mock/shutdown` (standalone only) closes the server; `PUT /__mock/uploads/{id}` accepts an upload and stores nothing.

## Seeds, images and the wire

* `tools/export-mock-seed.mjs` writes `assets/seed/<Schema>.seed.json` (47 files, 1.2 MB), `extra.json` (config, personas, billing, hotel settings, hero variants, legal texts) and `manifest.json` from `fixtures-to-wire.mjs` `wireSets()`: the seeds are exactly the wire-mapped fixtures. The only changes are the image convention and moving the hero-story variants (same ids as the stored story rows) into `extra.json`. It also writes `assets/spec/routes.json`, a slim route table (operation, path, status, access, parameters, request schemas) that the mock builds its router and request validation from. `--check` fails when stale.
* **Image convention.** Every `ImageRef` carries `id: <imageId>` and `baseUrl: asset://ghazal_mock_api/images/<imageId>` (`<imageId>` is the file name without extension). `tools/optimize-mock-images.mjs` writes `assets/images/<imageId>_480.jpg` and `_960.jpg` (long edge, quality 76, ImageMagick; 149 photographs, 298 files, 15.9 MB, budget 35 MB). The UI resolves the base by scheme: `asset://ghazal_mock_api/images/<id>` becomes `AssetImage('images/<id>_480.jpg', package: 'ghazal_mock_api')` (or `_960`); any other scheme is a plain network URL with the same suffix (`<base>_480.jpg`). The standalone server rewrites the prefix in every response to `http://host:port/images/` and serves the files. A `MessageImage.file` is a path under the prototype images; its id is the same rule.
* Internal fields of stored documents are prefixed `_` and stripped from every response. Dates are Kuwait civil dates, instants carry `+03:00`, money is integer fils.

## What the mock implements (the rules, readable in `lib/src/`)

`engine/` pure Dart ports (pricing and quotes: standard against voucher price, per person and package, weekday, weekend, holiday, season and special-date tiers, extras, complimentary guests, service charge, voucher windows; availability by day from the deterministic seeded occupancy; voucher codes, QR payload, validity, reuse, the release and credit table; the transition table R01-R14; visit slots; SLA readings; Arabic search normalisation) and `catalog.dart` (search with filters and sorts, card prices, compare, nearby, region search, quotes). `domain/requests.dart` applies R01-R13 with guards, voucher outcomes, calendar claims and notifications; `domain/vouchers.dart` the voucher life cycle (checkout, payment session, activation, bind, release with the 60-day window, redeem, forfeit, expire, credit vouchers); `domain/visits.dart` visits and the three-member group chat; `domain/chat.dart` messages and the scripted replies. Handlers in `handlers/<tag>.dart`, one file per contract tag, keyed by `operationId` (`handlers/handlers.dart`); the router and every status code come from the contract.

Notes on choices the contract leaves open: a request holds its date as a `requested` claim (not blocking), approval turns it into a `hold` until `confirmBy`, confirmation into a `booking`; approving fails with `SLOT_UNAVAILABLE` if another booking, hold or block took the hall. A counter-offer keeps the voucher price (delta against the voucher total) and leaves the request pending. Credit vouchers bind to the first request and become ordinary bound vouchers. `reportIssue` is allowed 72 h after completion. Provider requests have no calendar claim. `partner/today` tiles and Needs-you rows are computed from live data (the seeded triage rows are only used for the weekly calendar check). Analytics are seeded for the hotel and derived from live data (plus deterministic daily series) for everyone else.

## What is faked (and what replaces it)

OTP and password reset codes (WhatsApp, Resend: the outbox), the payment gateway (MyFatoorah: sessions settle on a timer or by the control endpoint), push (the notification centre is filled by the same events), media upload (signed URL points at `/__mock/uploads/{id}`, nothing is stored; a completed upload reuses a seeded photograph), realtime chat (REST only, `listMessages?afterSeq=`), support and moderation staff (scripted replies and control endpoints), step-up (the tokens are issued but never required), `ghazal_core`'s `ApiProblemCode` only knows part of the contract codes (the rest map to `UNKNOWN`: see requests.md).

## Proof and tests

| Check | Command | Result 2026-10-20 |
|---|---|---|
| Engine equals the TypeScript engine | `node tools/export-engine-cases.mjs` (writes `packages/contracts/fixtures/engine-cases.json`, `--check`) then `flutter test packages/ghazal_mock_api/test/engine_equality_test.dart` | 2,170 cases: 294 date, 66 seeded, 34 text, 271 voucher, 111 transition, 105 SLA, 120 slot-time, 96 visit, 327 venue quotes (97 refusals), 120 provider quotes, 97 availability months (about 3,000 days), 240 venue-day, 160 card-price, 68 search, 24 region, 18 nearby, 19 compare |
| Real client against the mock (typed) | `flutter test packages/ghazal_mock_api/test` | 54 tests: round trip 9, lifecycle stories 14 (hero request end to end, forfeit by clock, R06, withdraw, counter-offer, revoke, purchase to credit voucher, listing review, visits and chat, staff, partner sign-in), scenarios 12, server over sockets 3, typed sweep 4, engine equality 12 |
| Every operation, every response against the spec | `node tools/contract-test.mjs` (starts and stops the standalone server) | 217 of 217 operations, 339 calls, 0 failures |
| Seeds and images current | `node tools/export-mock-seed.mjs --check`, `node tools/optimize-mock-images.mjs --check` | current |

Run the Dart tests through `node tools/with-slot.mjs flutter-test -- flutter test packages/ghazal_mock_api`.

## Public API

`MockBackend.create({seed, clock, latency, scenario, persona, autoRun, gatewayDelay, botDelay})`; `.httpClientAdapter`; `.control` (`MockControl`); `.serve({port, host, logRequests})` returning `MockServer {url, port, close(), closed}`; `.handler` (shelf); `.app` (`MockApp`, for tools). `MockConfig`, `Scenario` (`none, slow, error, offline, empty, expired`), `MockOffline`, `serveMock`, `defaultMockPort`, `SeedSource` (`fromLoader`, `MapSeedSource`), `SeedData`, `storyPoints`, and the engine (`EngineData`, `quote`, `packagePrice`, `availabilityFor`, `transitions`, `slaReading`, ...). `bin/serve.dart`.
