# Testing

> Binding strategy per layer. Source: ADR 0025 (strategy and the visual QA loop), 0024 (parity), 0010-0014 (formatter, RTL), 0020 and 0027 (backend and payments). Test code does not exist yet; this file says what each layer must contain when its code lands. Checklists that say when work is done: [definition-of-done.md](definition-of-done.md).

## 1. What testing protects here

| Risk | Why it is specific to Ghazal | Main defence |
|---|---|---|
| Wrong or double-claimed money and dates | Weddings are booked 6-18 months ahead; a lost deposit or a double-booked Thursday is a trust failure | server tests: fils arithmetic, slot-claim concurrency, webhook scenarios, state machine |
| Broken Arabic | Arabic is a first-class target: shaping, bidi, mirroring, Western digits, `د.ك` placement | shared formatter fixtures, Arabic goldens, shaping-and-bidi sheet, RTL review |
| Prototype and Flutter drifting apart | the prototype is the specification | shared fixtures, tokens, ARB, redline parity on hero screens |
| "Done" declared without looking | type-checking is not design QA | the visual QA loop (section 8) and pasted verify output |

Principles: geometry and tokens are gates, pixels are not (web and Flutter never match pixel for pixel). The server is the truth for money; clients display what the server computed. Every test is deterministic: fixed clock (Thu 12 Nov 2026, 4:00 PM Asia/Kuwait), pinned locale (`ar` or `en`, never `ar-KW`), no real network, seeded randomness.

## 2. Pyramid and cadence

| Layer | Tooling | Runs | Result |
|---|---|---|---|
| Static gates | Biome, Stylelint, `tsc`, `dart analyze --fatal-infos`, `tools/check-dart-rules.sh`, `tokens:check`, `i18n:check`, `specs:check` | every save (Stop hook, `--fast`, at most 60 s) and every PR | blocks |
| Unit | Vitest 5 (TS), `flutter test` (Dart) | every PR | blocks |
| Widget and golden | Alchemist 0.14 through `ghazalGoldenTest` in `ghazal_testing` | every PR, Linux | blocks (Ahem CI goldens) |
| Layout parity | `flutter test --tags parity` against `design/.redlines/*.json` | every PR, hero screens only | blocks |
| Prototype | Playwright shots plus axe (`design.yml`) | every PR | axe serious or critical blocks; shots are artefacts |
| Backend integration | Vitest + Testcontainers (PostGIS, Redis) | every PR | blocks |
| Contract | `openapi:emit` drift, Spectral, oasdiff against main, generated-client drift | every PR | blocks |
| App integration | `integration_test` against Prism or a fake server; Patrol 4.10 only for native dialogs | nightly and before release | alerts |
| Performance | `flutter drive --profile`: `home_ttfmc`, scroll jank | nightly | alerts on budget breach |
| Gateway sandbox | MyFatoorah sandbox contract test | nightly, once the sandbox exists (OQ-T-04) | alerts |

One emulator or simulator at a time (`flock tools/.locks/emulator`). Device suites are never per-PR: a solo owner cannot afford the minutes.

## 3. Commands (once the foundation PR lands)

```
pnpm verify design|flutter|api|all|changed [--fast]   # tools/verify.sh: the definition of done
pnpm tokens:check   pnpm i18n:check   pnpm specs:check   pnpm specs:coverage
pnpm shots --screen <id>   pnpm -F design redlines --screen <id>   pnpm a11y
flutter analyze --fatal-infos   flutter test   flutter test --tags golden,parity
flutter widget-preview start
```

`pnpm shots` and every Playwright script resolve the dev-server URL themselves through `tools/ports.mjs` and abort on an identity mismatch. Never pass a hand-typed localhost URL (ADR 0021 D8; see [environments-and-secrets.md](environments-and-secrets.md)).

Test locations: TS tests beside the source as `*.test.ts`; Dart tests under `test/` mirroring `lib/`; Alchemist output in `goldens/ci/` and `goldens/macos/` beside the test; app flows in `integration_test/`; API integration tests in `apps/api/test/integration/`.

## 4. Unit tests

### 4.1 Shared format cases

`packages/contracts/fixtures/format-cases.json` is asserted by both the TS and the Dart suite. Each case: input, locale, `digitStyle`, exact expected string including code points. Illustrative shape (the file is authoritative):

```json
{ "id": "money.browse.whole.ar", "fn": "money",
  "input": { "fils": 18200000, "currency": "KWD" }, "options": { "precision": "browse" },
  "locale": "ar", "digitStyle": "western",
  "expected": "⁦18,200⁩ د.ك" }
```

Mandatory coverage (ADR 0010-0013): browse whole dinars (`18,200`), browse with fils shown as three decimals (`18.500`, never `18.5`), exact (`5,460.000`, `0.500`, `12,500.000`), credit with U+2212 (`-50.000`), per-guest and per-night units, `From ... for 350 guests`, Arabic range `من 22 إلى 52` and the English range `22 – 52` (en dash with spaces, each number isolated), percent `30%`, Eastern-digit mode converting every number except identifiers, dates (`Thu 14 Jan`, `Thursday 14 January 2027`, `الخميس 14 يناير 2027`, year omitted only in the short form inside the current year), the muted Hijri line `6 شعبان 1448 هـ` in Arabic only, times (`9:00 PM`, `9:00 م`, `من 7:00 م إلى 1:00 ص`), phone grouping `+965 5123 4567`, and the Arabic plural for guests at 0, 1, 2, 3, 10, 11, 99, 100, 103, 111, 300, 350, 400 and 650 by the CLDR last-two-digits rule (103 is few, 111 is many, 350 and 650 are many: `350 ضيفًا`; 100, 300 and 400 are other: `300 ضيف`), the hero booking (`KD 18,200 for 350 guests`; deposit 30% = 5,460.000, already a multiple of KD 5, so ADR 0005 D1's round-up leaves it unchanged; balance 12,740.000) and the round-up case 34,160.000 at 30% = 10,248.000 to 10,250.000.

### 4.2 Input and normalisation

- Digit normaliser: `٥١٢٣٤٥٦٧` and `۵۱۲۳۴۵۶۷` both become `51234567`; applied to phone, OTP, guests, budget and amount inputs, on the client and again on the server.
- Kuwait phone shape: accept `51234567`, `65551234`, `91234567`, `22345678`, `41234567`; reject `31234567`, `4123456` (7 digits), `12345678`, `123456789`. Never libphonenumber `isValid`.
- Arabic search normalisation (strip tashkeel and tatweel; unify `أ إ آ` to `ا`, `ى` to `ي`; optional `ة` to `ه` and `ال`; Latin case-fold): `مشرف`, `Mishref`, `Mishrif`, `Meshref` all match one area; `السالمية` matches `Salmiyah`.

### 4.3 Money and policy rules (server, fixtures in `packages/contracts`)

All amounts are integer fils. Percentages are basis points. Rounding is half-up per line; a leftover fil goes to the venue share. The numbers below are the ADR placeholders; they are configuration under test, not hardcoded truths (ADR 0005 and 0006 await owner approval).

| Rule | Case | Expected |
|---|---|---|
| Price engine (ADR 0004 D9) | Thu 21 Jan 2027, Evening: hall 1,800.000 + 360 billable guests x 12.500 = 4,500.000 + extras 920.000; winter percent offer -90.000 (no lead-time rule; add a separate case for early-bird at 120 days and exactly 119 days); 10% service charge; platform credit -50.000 | subtotal 7,220.000; after offer 7,130.000; service 713.000; venue bill 7,843.000; client total 7,793.000 |
| Complimentary guests | 400 guests, 10% complimentary | bills 360 |
| Deposit (ADR 0005 D1) | total 18,200.000, venue 30% | 5,460.000 |
| Deposit rounding | total 34,160.000, venue 30% (10,248.000) | 10,250.000 |
| Deposit floor and ceiling | total 7,793.000 at venue 20% / at venue 50% | 1,560.000 / 3,900.000 |
| Deposit cap | total 3.000 | 3.000 (min with client total) |
| Inside 14 days | event 10 days away | 100% charged |
| Balance | 18,200.000 less 5,460.000, due 14 days before 14 Jan 2027 | 12,740.000 due Thu 31 Dec 2026 |
| Standard policy, event Thu 14 Jan 2027, paid 5,460.000 | cancel Sun 15 Nov 2026 (60 days) | forfeit 0%, refund 5,460.000 |
| | cancel Mon 16 Nov 2026 (59 days) | forfeit 25% = 4,550.000, refund 910.000 |
| | cancel Mon 21 Dec 2026 (24 days) | 50% = 9,100.000 capped at paid, refund 0 |
| Cooling-off (ADR 0006 D2) | paid Thu 12 Nov 4:00 PM, cancel Fri 13 Nov 6:00 PM, event 63 days away | 100% under any template; platform bears gateway fee |
| Venue cancels confirmed | any date | 100% refund; fee netted against the venue |
| Before payment | cancel in `requested` or `awaiting_deposit` | free, no refund object created |

Venue-business-day boundary (ADR 0002 D2): the day runs 06:00 to 06:00 Asia/Kuwait, so a 19:30-01:00 wedding on Thursday belongs to Thursday and an event instant at 00:30 Friday maps to Thursday's date.

### 4.4 State machine and timers

- One test per transition T01-T19 (ADR 0003 D3): allowed from-states, `reason_code`, the `booking_events` row, the claim effect (requests claim nothing; approval, instant checkout, confirmation and venue blocks claim), and the notification dispatched.
- Illegal transitions are rejected: for example `rejected` to `confirmed`, `expired` to `awaiting_deposit`.
- The compare-and-set race: two actors on one version; the loser gets `already updated`, no side effects.
- Timers with a fake clock (ADR 0001 D6): response SLA 24h default, 12/24/48h selectable, forced 4h and `Urgent` when the event is 14 days or less away; pay window 24h default, forced 6h within 14 days; instant hold 10 minutes, plus 5 minutes only while a gateway session is open; counter-offer 48h; venue-proposed reschedule 72h; SLA escalation at 50% (push) and 80% (WhatsApp) then expiry at 100%; at most 3 open unpaid bookings per client (`requested` plus `awaiting_deposit`); gateway invoice expiry equals hold expiry plus 2 minutes.
- Instant eligibility is a truth table: payout KYC approved, hall flag, event at least 30 days away, guests inside package bounds, fixed-price package, and trust (admin flag, or 5 completed bookings at 90% response). Any single failure falls back to request mode; government halls are never eligible.
- Late payment (ADR 0001 D11): SUCCESS after the hold lapsed with the slot still free within 60 minutes goes `expired` to `confirmed`; otherwise automatic 100% refund and the status stays `expired`.

## 5. Widget and golden tests (Arabic and English)

One helper, `ghazalGoldenTest(name, builder, {locales, widths, textScales})`, in `ghazal_testing`. Every golden pumps the real theme (`buildGhazalTheme(Locale)`), real ARB strings and a fixture; never placeholder text, because Arabic strings run up to 1.6 times longer than English and only real strings expose overflow.

| Subject | Locales | Widths | Text scale | Fixture |
|---|---|---|---|---|
| Component (each state) | ar, en | 390 | 1.0 and 2.0 | default |
| The eight hero screens (ADR 0024 D10) | ar, en | 360, 390, 430 | 1.0 and 2.0 | default and stress |
| Every other screen | ar, en | 390 at 1.0, plus 360 at 2.0 in Arabic | as listed | default and stress |

- Names: `<screen>.<locale>.<width>.ts<scale>.png`.
- CI goldens use Ahem (text becomes squares): they gate layout and geometry on Linux, not shaping. A curated set of at most 24 real-font goldens is generated on macOS for human and agent review (hero screens in both languages plus the shaping-and-bidi sheet). They are not a CI gate.
- Budget: at most 1,200 PNGs and 40 MB in the repo, checked by script.
- Hygiene: never run `--update-goldens` without Reading the diff PNGs under `failures/`. Only the golden's owner updates it, in a commit whose message says why. CI uploads failure PNGs. An agent can Read a golden PNG, so goldens double as a screenshot channel without a simulator.
- Layouts must not clip at 200% text scale and must not assume English widths. Compare cells keep to 14 characters (English) and 12 (Arabic).
- `flutter widget-preview start` with an `@Preview` per component state and locale is the human side-by-side against the prototype. Widgetbook is not added.

## 6. Kuwait stress fixtures

`packages/contracts/fixtures/stress/` holds, at minimum:

- a 45-plus character Arabic venue name mixing Latin brand text (a `فندق ... Regency Hotel` style name, fictional);
- a venue with no photos; a venue with zero reviews (card shows `New`, never 0.0);
- prices 12,500.000 and 0.500; capacity 1,500; a seven-digit invoice number;
- three compare items with different price units (per guest, flat per night, ministry rental fee);
- a booking in every one of the nine statuses, including an expired hold and a late-payment rescue;
- separate ladies and men's halls on one venue, and a two-section booking;
- empty, error and offline variants of each list.

The shaping-and-bidi sheet renders: lam-alef ligatures (`لا`), tashkeel and shadda (`الزفّة`), `1,250.000 د.ك` inside running Arabic text, `+965 5123 4567` staying left-to-right inside an RTL line, Western digits beside Arabic words, an IBAN and a booking reference `GZ-2611-0147` as LTR isolates, and a Hijri line.

## 7. Layout parity (hero screens only)

1. `pnpm -F design redlines --screen <id>` writes `design/.redlines/<screen>.<locale>.<width>.json` (per `data-gz-id` node: `insetStart`, `insetTop`, `w`, `h`, text-style token, line count; start-relative so Arabic and English compare directly).
2. The Flutter test (tag `parity`) pumps the screen at the same size, locale and fixture, finds nodes with `ValueKey('gz:<id>')`, converts `tester.getRect` to start-based insets and asserts each rect within 1.0 dp.
3. `handoff-checker` lists any delta above 1 dp. Nothing else is compared; pixel equality is never a gate.

Other screens are covered by component parity plus goldens.

## 8. Prototype tests and the visual QA loop

Prototype suite: Vitest for the formatter, clock, mocks and the i18n merge; Playwright shots at {ar, en} by {360, 390, 430}; axe per route and locale. Shots run with `deviceScaleFactor: 2`, reduced motion, network blocked, carets hidden, after `document.fonts.ready` and the `data-ready` attribute. Arabic uses locale `ar` (never `ar-KW`). Locally the system Chrome is used (`channel: 'chrome'`, no browser download); CI uses `playwright install chromium`.

**The loop (definition of done for UI work, ADR 0025 D7):**

1. Implement. The Stop hook runs `pnpm verify design --fast` and blocks on failure.
2. `pnpm shots --screen <id>` writes six PNGs and one contact sheet to `design/.shots/<run>/`. The URL was identity-checked first; a screenshot of another project's server is invalid.
3. Read the contact sheet, then every Arabic PNG at full size. Judge Arabic on its own: sizes, leading, icon mirroring, bidi, Latin and Arabic baselines, the `د.ك` position, Western digits.
4. Run the read-only reviewers `design-qa`, `rtl-reviewer` and `a11y-auditor`; each returns a table (issue, `data-gz-id`, severity, fix).
5. Fix and re-run. At most three iterations; then escalate what remains to the integrator or the owner. Do not keep looping.
6. Record the run in the screen spec's `qa` field. Paste the tail of `pnpm verify <area>` into the final message and name the PNGs you looked at.

Flutter equivalent: Ahem goldens, `flutter widget-preview`, then `flutter run -d <id> --dart-define=GZ_LOCALE=ar` and a native screenshot (`xcrun simctl io booted screenshot out.png`, `adb exec-out screencap -p > out.png`).

## 9. Backend tests (mandatory suites)

Vitest unit plus Testcontainers integration (Postgres 17 with PostGIS, Redis).

| Suite | Must prove |
|---|---|
| Double booking | 50 parallel claims on one hall and slot leave exactly one active claim; the rest return `SLOT_UNAVAILABLE`; an expired hold is released lazily inside the claiming transaction and by the 30 s sweeper; a Full-day claim conflicts with Afternoon and Evening (overlap by time range) |
| Tenancy | generated from the route list: staff of venue A cannot read or write venue B; `X-Venue-Id` is never trusted alone |
| Payment webhooks | scripted fake gateway: duplicate, out-of-order, forged signature, SUCCESS after hold expiry, KNET pending; status is re-queried before any state change; handlers are idempotent |
| Idempotency | replaying a POST with the same `Idempotency-Key` returns the original result and moves no money twice |
| Money | section 4.3 fixtures; no float anywhere; commission in basis points |
| State machine and timers | section 4.4, including deferred client notification after the 8-second Accept undo window and Undo returning `requested` and releasing the hold |
| Refunds | one request at a time per invoice; bank-transfer fallback with IBAN capture; refund destination stored encrypted and deleted after payout |
| Auth | WhatsApp OTP (5 attempts, 5-minute TTL, 60 s resend), refresh-token rotation and reuse revoking the session family, immediate staff session revocation, step-up `acr` for bank info and refunds |
| Search | Arabic normalisation cases and area aliases; nearby search |
| Contract | `openapi:emit` has no drift; oasdiff shows no breaking change; Prism serves every fixture |

Coverage gate: 70% for `ghazal_core`, `ghazal_auth` and the domain and data layers; none for pure UI. A nightly sandbox test against MyFatoorah is added once the sandbox exists.

## 10. Integration and performance

- Core flows with `integration_test` against a fake server or Prism: guest to WhatsApp OTP to booking request to deposit with a fake gateway to status; hotel: sign in, accept a request, Undo.
- Patrol only for native dialogs (permissions, notifications, biometrics).
- Performance budgets: cold start to first meaningful home content at most 2.0 s p75 on a mid-range Android at 10 Mbps and 100 ms RTT; warm start at most 800 ms; one extra check at 1.6 Mbps and 150 ms; scroll frame build and raster p90 under 8 ms in profile mode. A skeleton does not count as loaded.

## 11. Test hygiene

- No sleeps: wait on a condition or a fake clock. No real network. No test depends on another test's state.
- Test names state the rule: `rejects a fourth open unpaid booking`, not `test3`.
- Do not assert generated files or implementation details; assert behaviour and geometry.
- A flaky test is fixed or deleted within a day, never retried into green.
- A bug fix lands with the test that would have caught it.

## 12. What exists today

Nothing runs yet. `design/scripts/snap.mjs` exists but launches Playwright with locale `ar-KW` and has no server-identity check; it must change to `ar` and call the `tools/ports.mjs` check (ADR 0022 E, ADR 0021 D8). The formatter fixtures and format cases land first, with `packages/contracts`; goldens land with `ghazal_testing` at design freeze; backend suites land with `apps/api` in Week 2.
