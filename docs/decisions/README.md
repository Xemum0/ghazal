# Architecture and design decisions (ADRs)

Settled decisions for Ghazal (غزل), the Kuwait wedding-venue marketplace. Design phase scope: the Client Mobile App and the Venue/Hotel Mobile App, designed now as a web prototype (`design/`) and built later in Flutter. Every file here records one decision: context, the decision itself, consequences, alternatives considered and the requirement IDs it touches (IDs from `docs/product/feature-matrix.json`).

**Rule for agents:** do not re-litigate an ADR. If it is wrong or incomplete, write a new ADR that supersedes it (see below). Where an ADR and a research file in `docs/research/` disagree, the ADR wins (the research files say so in their headers).

## Status vocabulary

| Status | Meaning | What agents do |
|---|---|---|
| `accepted` | Binding for design and implementation. Some accepted ADRs still list owner questions (OQ ids); the design is built so those answers change configuration or one path, not the structure | Build to it. Quote the ADR and D-number or item number in specs and commits |
| `proposed-needs-owner` | The recommended default, produced by the design phase. **The owner must confirm or change it** (the header lists the questions). Until then it is the working assumption | Design and build against it, keep every owner-set value in configuration, and do not present it to users as final (for example no 'No booking fee' copy). When the owner answers, flip the Status to `accepted` (or amend the numbers) and add a dated line under the table |
| `superseded by NNNN` | Replaced in whole by a later ADR | Do not build to it; follow the ADR named |
| `partially superseded: D3 by NNNN` | Some items replaced; the rest stands | Follow the named ADR for the replaced items |

Accepted here means accepted by the design-phase process. The owner can always overturn an ADR, but only by a new ADR.

## Index

### Booking, money and policy

| ADR | Title | Status | Owner questions |
|---|---|---|---|
| [0001](0001-booking-model-request-then-pay.md) | Booking model: request-then-pay by default, instant booking as an earned opt-in, no money held or charged before a human says yes | accepted; partially superseded: in-app payment parts (D1 instant, D2, D3, D6, D11 to D13) by 0033 | OQ-B-01, OQ-B-02, OQ-B-07, OQ-B-08 |
| [0002](0002-booking-granularity-halls-sessions-sections-channels.md) | Booking granularity: hall x date x session, up to two event sections (ladies and men's), and booking channels including government halls | accepted | OQ-B-09, OQ-B-10, OQ-B-11 |
| [0003](0003-booking-status-state-machine.md) | Booking status state machine: nine internal statuses under the PRD's six, child objects for changes, and a shared Booking Thread | accepted; partially superseded: D2 chip labels by 0013 D4; D1, D3, D5 to D8 by 0033 | OQ-B-21 |
| [0004](0004-pricing-engine-and-price-display.md) | Pricing model: deterministic tier engine, flat plus per-guest, one best offer, frozen quote, all-in display | accepted; partially superseded: D3 shading by 0011 D4, D6 currency strings by 0010 D7; D4, D6 (second price), D8 by 0033 | OQ-B-14, OQ-B-15, OQ-B-16 |
| [0005](0005-deposit-balance-and-payment-schedule.md) | Deposit, balance and payment schedule: 30% default deposit, balance at T-14, cash for the balance only, KNET-safe payment flow | superseded by 0033 (was proposed-needs-owner) | OQ-B-03, OQ-B-04, OQ-B-06, OQ-B-15 |
| [0006](0006-cancellation-refund-reschedule-policy.md) | Cancellation, refund and reschedule model: policy templates by days-before-event, a 48h cooling-off, absolute dates and a live refund calculator | superseded by 0033 (was proposed-needs-owner) | OQ-B-05, OQ-B-18, OQ-B-23, OQ-B-06 |

### Navigation and product surfaces

| ADR | Title | Status | Owner questions |
|---|---|---|---|
| [0007](0007-client-app-navigation-and-guest-gating.md) | Client app navigation: Discover, Saved, My Wedding, Messages, Profile; the Brief as global context; guest gating at commit moments | accepted | OQ-B-12, OQ-B-20, OQ-B-24, OQ-L-14 |
| [0008](0008-hotel-app-navigation-and-request-triage.md) | Hotel app navigation and request triage: Today, Bookings, Calendar, Messages, More; badge plus Needs-you inbox; Accept in two taps with Undo | accepted; amended by 0033 | OQ-B-16, OQ-B-17, OQ-B-18, OQ-B-22, OQ-B-25 |
| [0009](0009-compare-ux-390px.md) | Compare UX on a 390px screen: anti-nag tray, full-bleed fluid thirds with label above value, differences-only by default | accepted | OQ-B-12 |
| [0018](0018-venue-card-anatomy-and-hero-search.md) | Venue card anatomy and the hero-search 'brief card' | accepted | OQ-L-10, OQ-L-13 |

### Localisation, language and culture

| ADR | Title | Status | Owner questions |
|---|---|---|---|
| [0010](0010-numerals-currency-shared-formatter.md) | Western digits by default, KWD money rules, one shared formatter | accepted | OQ-L-01, OQ-L-02, OQ-T-11 |
| [0011](0011-dates-time-week-calendar-policy.md) | Gregorian primary, Hijri secondary, Sunday-first weeks, 12-hour Kuwait time | accepted | OQ-L-03, OQ-L-04, OQ-T-10 |
| [0012](0012-phone-address-identifiers-ltr-fields.md) | Phone, address and identifier formats, and LTR data inside RTL screens | accepted | OQ-L-14, OQ-L-17, OQ-L-18 |
| [0013](0013-arabic-voice-dialect-gender-copy-rules.md) | Arabic voice: clear modern Arabic with Gulf warmth, gender-neutral, written not translated | accepted | OQ-L-06, OQ-L-16 |
| [0014](0014-rtl-mirroring-gestures-chart-direction.md) | RTL mirroring registry, gesture rules and chart direction | accepted | OQ-L-05 |
| [0015](0015-imagery-cultural-sensitivity-policy.md) | Imagery and cultural-sensitivity policy: empty rooms, monogram avatars, per-section policy facts | **proposed-needs-owner** | OQ-L-07, OQ-L-08, OQ-L-15, OQ-L-17 |

### Visual system and prototype

| ADR | Title | Status | Owner questions |
|---|---|---|---|
| [0016](0016-typography-cairo-poppins-figures-display-test.md) | Typography: Cairo and Poppins as the functional pair, a Cairo 'figures' role, and a tested display slot | accepted | OQ-L-09 |
| [0017](0017-motion-principles-and-tokens.md) | Motion principles: explain, never decorate; four durations, two curves, one thread | accepted | none |
| [0023](0023-design-token-pipeline.md) | Design-token pipeline: DTCG JSON, Style Dictionary, CSS variables, TypeScript and Dart | accepted | none |
| [0024](0024-prototype-to-flutter-handoff-contract.md) | Component spec and prototype-to-Flutter handoff format | accepted | none |
| [0025](0025-testing-strategy-visual-qa-loop.md) | Testing strategy: bilingual goldens, parity checks and the visual QA loop | accepted | none |

### Platform, engineering and delivery

| ADR | Title | Status | Owner questions |
|---|---|---|---|
| [0019](0019-analytics-event-taxonomy.md) | Analytics event taxonomy for search, venue view, compare, booking and payment | **proposed-needs-owner** | OQ-L-11, OQ-L-12, OQ-T-14 |
| [0020](0020-backend-framework-nestjs.md) | Backend framework: NestJS 12 on Node 24 (recommendation; owner confirms in Week 0) | accepted (owner 2026-10-20); Updated by ADR 0035 | OQ-T-01 |
| [0021](0021-monorepo-layout-toolchain-ports.md) | Monorepo layout, toolchain pins and reserved dev-server ports | accepted | OQ-T-02, OQ-T-06, OQ-T-07 |
| [0022](0022-flutter-architecture-platform-floors.md) | Flutter architecture: SDK pins and floors, Riverpod, go_router, ARB localisation, token theming, images | accepted; partially superseded: D tabs by 0007 D1, E money string by 0010 D7; item A (iOS 15.0) is proposed-needs-owner until OQ-T-02 and CF-35 are signed; Updated by ADR 0035 (iOS 15 and bundle id accepted) | OQ-T-02, OQ-T-03, OQ-T-06 |
| [0026](0026-ci-cd-environments-secrets.md) | CI/CD, environments and secrets | accepted; Updated by ADR 0035 (bundle ids) | OQ-T-03, OQ-T-05, OQ-T-07, OQ-T-13 |
| [0027](0027-payments-integration-boundary-myfatoorah.md) | Payments integration boundary: server-side MyFatoorah, hosted pages, webhook plus re-query, ledger | accepted; partially superseded: supplier split, payouts, KYC, event ledger by 0033 (gateway boundary stands); Updated by ADR 0035 (refund parts moot) | OQ-T-04, OQ-B-02, OQ-B-06, OQ-T-12 |
| [0028](0028-authentication-sessions-step-up.md) | Authentication: backend JWT sessions, Apple/Google/WhatsApp OTP, guests, hotel staff, step-up | accepted; Updated by ADR 0035 (staff email invitation, WhatsApp OTP without credentials) | OQ-T-08, OQ-T-09, OQ-B-17 |
| [0029](0029-agentic-development-setup-file-ownership.md) | Agentic-development setup: AGENTS.md, rules, skills, subagents, hooks and file ownership | accepted | OQ-T-07 |
| [0030](0030-visual-direction-maison-majlis-thread.md) | Visual direction: Maison identity, Majlis structure, Thread verbs (refines 0016 typography and 0017 motion) | accepted | none (display-face validation with Kuwaiti reviewers recommended before visual freeze) |
| [0031](0031-design-pass-scope-and-toolchain-amendments.md) | Design-pass scope and toolchain amendments (integrator overrides of 0021 and 0024) | accepted | none |
| [0032](0032-design-pass-implementation-notes.md) | Design-pass implementation notes (token pipeline, icon weight, carousel direction, class namespaces) | accepted | none |
| [0033](0033-voucher-marketplace-model.md) | Voucher marketplace model: Ghazal sells a KD 2 voucher, venues and providers sell and collect everything else (supersedes the in-app payment parts of 0001, 0003, 0004, 0005, 0006, 0027; amends 0008) | accepted (model); assumptions confirmed or replaced by 0035 (A-02 reuse, A-03, A-15 replaced); Updated by ADR 0035 | OQ-V-01 to OQ-V-16 |
| [0034](0034-text-diet-and-illustration.md) | Text diet and illustration: icons, figures and drawings carry the screens, sentences are the exception (refines 0013 and 0030; adds the illustration layer and the info-sheet rule) | accepted | OQ-L-19 |
| [0035](0035-owner-decisions-round-1.md) | Owner decisions round 1 (2026-10-20): voucher forfeited after the 24 h lapse, credit voucher instead of refunds, no VAT, partner plan or contract billing, staff email invitations (Resend), NestJS accepted, bundle ids, 500 MB video | accepted | OQ-V-01 to OQ-V-18 (answered), OQ-T-01, OQ-T-06 |
| [0036](0036-flutter-build-plan-amendments.md) | Flutter build plan: app names (client_app, provider_app), package set, contract-first mock API, icon font and illustrations, material confinement, headless parity loop, simulator only at the end (amends 0021, 0022, 0025) | accepted | none |
| [0037](0037-flutter-build-results-and-deviations.md) | Flutter build results (134 screens, 7,805 tests, parity by screen) and deviations: standalone-mock demo tools, shot persona rule, names as authored, explicit parity exceptions, open items (amends 0036) | accepted | none |
| [0038](0038-owner-decisions-round-2.md) | Owner decisions round 2 (2026-10-29): governorates instead of areas, services independent of venues, partner application form in the Partner app, no guest mode (name and sex required) | accepted | OQ-R2-01 to OQ-R2-04 working assumptions |

Count: 38 ADRs (0001-0038; 0038 records the owner decisions of round 2; 0037 records the Flutter build results and deviations; 0036 is the Flutter build plan; 0035 records the owner answers of 2026-10-20 and accepts 0020; 0032 is the implementation-notes ADR, 0033 the voucher model, 0034 the text diet and illustration policy). 0005 and 0006 are `superseded by 0033`, 0001, 0003, 0004, 0008, 0027 are partially superseded or amended by 0033, 0033 itself is `accepted` for the model with `proposed-needs-owner` assumptions, and 2 others are `proposed-needs-owner` (0015, 0019; 0020 was accepted by 0035). 0022 stays partially superseded on single items and its iOS 15.0 floor item is itself unsigned. The open questions themselves are kept in the open-questions register (`docs/product/open-questions.md`); this index only lists which ADR depends on which.

## Who owns which topic (precedence where ADRs overlap)

Some topics are touched by several ADRs. The owning ADR wins; the others quote it. Overlaps that still disagree are noted in each ADR under 'Notes on conflicting inputs'.

| Topic | Owning ADR |
|---|---|
| Booking modes, timers, request and hold behaviour | 0001 (reply SLA, hold, counter-offers); 0033 (voucher request, 24 h confirm window, no instant mode) |
| Halls, sessions, sections, booking channels, calendar claim styles | 0002 |
| Status names, transitions, chips styling, the Booking Thread | 0033 (request statuses); 0003 D2, D7 for chip style only (the words on chips: 0013) |
| Price engine, quote snapshot, price grammar | 0004 (two prices per package: 0033 D4; currency strings and number precision: 0010) |
| Voucher, listing fees, refunds, payment methods and outcomes | 0033 (gateway integration: 0027); deposit, balance and cash no longer exist (0005 superseded) |
| Voucher refund and reuse, listing review, visits and group chat | 0033 (refund execution: 0027); event cancellation tiers no longer exist (0006 superseded) |
| Client tabs, Brief, guest gating, notification landings | 0007 |
| Hotel tabs, triage, roles, offline rules | 0008 |
| Digits, currency, number formats | 0010 |
| Dates, times, week start, peak band, Hijri | 0011 (pricing day types: 0004) |
| Phone, address, area, OTP shapes | 0012 |
| Arabic and English copy rules | 0013 |
| Mirroring, gestures, chart direction | 0014 |
| Imagery, avatars, per-section policy facts, content timing | 0015 |
| Fonts, type scale, figures | 0016 |
| Motion tokens | 0017 (token file: 0023) |
| Tokens and generators | 0023 |
| Repository layout, ports, toolchain pins | 0021 |
| Auth and sessions | 0028 |

## Adding, changing and superseding an ADR

1. **Numbering.** ADR numbers 0001-0038 are allocated; the next free number is 0039. Numbers are never reused. Until `tools/new-adr.mjs` exists (ADR 0029), allocate by taking the next free number in this folder and adding the row to the index in the same change; once it exists, run `node tools/new-adr.mjs '<title>'`, which allocates under a lock so parallel authors cannot collide. The ADR numbers suggested inside `docs/research/*` are void.
2. **File name:** `NNNN-kebab-slug.md`. Header table: Status, Date, Scope, owner questions, Supersedes, Related ADRs, screens. Sections: Context, Decision (numbered so other documents can quote 'ADR 0001 D7'), Consequences, Alternatives considered, Related requirement IDs, and when needed Notes on conflicting inputs.
3. **New decision, no conflict:** add a new ADR, `proposed-needs-owner` if it needs the owner's numbers or legal sign-off, otherwise `accepted`.
4. **Changing a decision:** write a new ADR that states `Supersedes: NNNN` (and the D-numbers if partial). In the old ADR change only the Status line to `superseded by MMMM` (or `partially superseded: D3 by MMMM`), add the date and one-line reason under the header table, and leave the body as the historical record. Update this index, and then the places that quote the old ADR (AGENTS.md, `.claude/rules`, specs, the feature-matrix notes).
5. **Owner answers:** when a `proposed-needs-owner` ADR is confirmed, edit its Status to `accepted` and add 'Confirmed by the owner on YYYY-MM-DD (OQ-xxx)' under the header table. If the owner changes the numbers, amend the Decision text in the same edit and note it; no new ADR is needed for a confirmation that only fills in configuration values.
6. **Typos and link fixes** may be edited in place. Anything that changes meaning needs step 4.
7. **Scope guard:** an ADR may not add product scope. A new idea goes to `docs/product/open-questions.md` first; every screen and feature traces to a requirement ID.

## Relationship to other documents

- `docs/product/00-source-digest.md` section 9 and the conflicts register (feature-matrix section 11) list the PRD conflicts these ADRs resolve: CF-02, CF-04, CF-05, CF-08, CF-09, CF-10, CF-11, CF-12, CF-25, CF-26, CF-27, CF-32. ADR 0022 registers a new entry, CF-35 (iOS 15.0 floor).
- `AGENTS.md` is the short agent guide. Its token path (`design/tokens/`) and `npm` commands are superseded by ADR 0021 and ADR 0029; the integrator updates it.
- `docs/design/00-brief.md` is the design mandate; its open design questions are answered by ADR 0001 (question 1, request or instant), ADR 0002 (question 2, date, session, halls and sections), ADR 0010 (question 3, digits), ADR 0009 (question 4, Compare) and ADR 0003 with ADR 0017 (question 5, the thread as the memorable idea).
