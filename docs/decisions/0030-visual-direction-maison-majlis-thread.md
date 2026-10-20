# ADR 0030: Visual direction: Maison identity, Majlis structure, Thread verbs

| Field | Value |
|---|---|
| Status | accepted; refines ADR 0016 (typography: scale, display slot, figures sizes) and ADR 0017 (motion tokens: thread draw-on, press, exits, reduced motion, section khayt) |
| Date | 2026-10-12 |
| Scope | Visual identity of the Client app, the Hotel app and the web prototype: colour, type, shape, layout, signature, components, imagery, motion, wordmark; the values live in `docs/design/01-direction.md` |
| Owner confirmation still needed | OQ-L-09 / ADR 0016 D7 (the display test with five Kuwaiti reviewers is now a validation of Newsreader + Amiri, with ADR 0016 arm A as the fallback); resolution of the conflicts listed under Consequences |
| Resolves | OQ-P-20 (which exploration is the direction) |
| Amends | ADR 0016 D2 (figure size 1.09 to 1.08), D3 (scale and Arabic column), D5 (eyebrow tracking), D6 (display slot filled, display digits allowed in named roles, moment cap relaxed); ADR 0017 D2 / D5 / D6 / D9 (see Decision 8); ADR 0018 D3 (name face and size), D9 (hero height); ADR 0009 D6 and D8 (toggle, badges, gold only on a picked hall) by clarification; ADR 0024 aspect-ratio token list (adds 4:5 and 16:10) |
| Related ADRs | 0001 (request-then-pay), 0003 (statuses and Booking Thread), 0007, 0008, 0009, 0010, 0015, 0016, 0017, 0018, 0023, 0024, 0031 |
| Screens | all; hero screens client.home, client.venue.details, client.compare.table, client.bookings.detail, hotel.today.dashboard |

## Context

Three static explorations were built to the same brief (`docs/design/00-brief.md`, sections 3 to 7) and are archived in `design/explorations/{maison,majlis,thread}` (see `docs/design/exploration-archive.md`). Three judges scored them on 13 criteria (total out of 130): a hotel-brand creative director, a head of UX / accessibility / Arabic, and a design-systems engineer and AI-template skeptic.

| Direction | Creative director | UX / a11y / RTL | Systems skeptic |
|---|---|---|---|
| maison | 101 | 99 | 101.5 |
| majlis | 99 | 104 | 103 |
| thread | 93 | 96 | 90 |

All three independently recommended the same hybrid rather than a winner: Maison as the premium identity (photography, serif, restraint), Majlis as the working structure (compare, hotel triage, measurement, Arabic generosity), Thread as the verbs (the Booking Thread as the one status component, the day timeline, the gold-is-a-verb lint, Cairo figures). The recurring defects they asked to fix: Maison's editorial tropes (italic accent word, eyebrow plus dash everywhere, greeting banner) and a serif in the hotel app; Majlis's Ink chrome, lattice and single-letter Arabic weekdays; Thread's thin Light type, sub-12 px decimals and gold-500 hairlines carrying meaning alone.

The owner-side lead decided the hybrid on 2026-10-12. This ADR records it, resolves OQ-P-20 and turns it into rules. It does not re-open the decision.

## Decision

1. **Identity = Maison.** Editorial hospitality on the ivory canvas with full-bleed uncropped photography. Display voice (venue names, hero headline, hero price, brief sentence, countdown numeral) is Newsreader 300/400 (EN) and Amiri 400 at x1.10 with a negative display word-space (AR) in the client app. In the hotel app the serif is used only for venue names and the greeting. UI text is Poppins (EN) and Cairo (AR) as the PRD says. Numbers are Cairo tabular Western digits at x1.08 in both languages (Thread's rule); display numerals in the serif are limited to the named roles. Fonts are self-hosted static files; nothing loads from Google Fonts at runtime.
2. **Colour = the Maison ramps** (ink-900 #2E2528 through ink-50; gold-500 #D8B26E fill, hairline and knot only, never text; gold-700 #7A5C1E the only gold for text and icons; rose-100 quiet panels; canvas #FFF9F5; functional success-700 / danger-700 for status only). Two additions: `gold-650` #A67F2E (from Thread) for rings and bars that are the only carrier of a state (3.53:1), and `gold-550` #C79F57 for the pressed gold fill. **Gold is a verb**, enforced by lint: gold FILL only for the one primary action per screen, the selected date, count badges and thread knots; gold LINE up to 4 px only for the khayt, the thread, reply bar, range bars and strip marks. Primary button = gold-500 fill with ink-900 label (7.45:1); secondary = hairline ink outline; tertiary = gold-700 text and underline; destructive = danger-700 on its tint. Solid Ink fill is for selected segments and tabs and one dark panel per screen at most (hotel header band, confirmation hero, countdown card), never the client Home.
3. **Shape.** Radius 8 (button, input, chip), 12 (card, panel, card image), 20 (sheet top), full (avatar, toggle, count badge), 4 for status pills. The Majlis arch crop is one named shape token (`shape.arch`) used only on the Home hero image and the onboarding/splash hero. The lattice is dropped. Elevation is hairline first; one warm soft shadow for floating things (elev-2) and sheets (elev-3). Hairline 1 px, icon stroke 1.5 on a 24 grid.
4. **Spacing and layout (Majlis).** 4-pt scale, one screen gutter 20, section rhythm 32, control heights 44 / 48 / 52 / 56, frame 390 x 844 with real system chrome (safe top 47, bottom 34, home indicator), fluid 360 to 430, logical properties only, one Arabic scale (Maison's table, body 17/28).
5. **Signature.** The gold hairline *khayt* marks section heads and the selected tab. The **Booking Thread** (Request, Approval, Deposit, Balance, Your day) is the single status, payment-schedule and countdown component on the venue date card, booking detail, confirmation, My Wedding and the hotel request card. A knot ties only when the event is recorded; the mapping to the nine ADR 0003 statuses is in `01-direction.md` section 4. Hotel Today adds the vertical day timeline, the depleting reply-window bar and the 7-day strip.
6. **Search.** Home uses the structured brief card (date, area, guests, budget, each at least 44 px) with a live-count CTA (`Show 38 halls free on 14 Jan`). Maison's typeset brief sentence is the read-only echo on results, compare and booking headers; tapping it opens the edit sheet.
7. **Compare.** Majlis layout (ADR 0009 geometry): three fluid thirds, serif names, rectangular 4:5 thumbnails, sticky labelled action bar, Differences-only toggle with hidden-row count, Best rated / Lowest price / Closest badges, Best-in-row marker, per-guest and deposit rows, plus Thread's range bars and `How you book` row.
8. **Motion.** Maison tokens: 120 / 200 / 320 / 480 ms (plus the 640 ms success token from ADR 0017), ease-out (.2,0,0,1), ease-emph (.05,.7,.1,1), ease-in (.3,0,.8,.15) for exits only. Changes to ADR 0017: the thread draws on over 480 ms (was 320); press is a tone step plus scale .985 (was .98 plus 6% overlay); sheet dismiss is 200 ms ease-in (was 75% of entry); the gold 1 px khayt is allowed at section heads and under the selected tab (ADR 0017 D6 forbade a decorative divider; the 2 px state thread stays state-only); a knot pop 0.6 to 1.4 to 1 once on a live state change; reduced motion sets every duration to 1 ms (was a 120 ms cross-fade); Thread's looping loader is not adopted (an OS activity indicator remains the only loop).
9. **Hotel app and venue details.** As in `01-direction.md` rules 8 and 9 and section 3: Ink header band, `Needs your reply` rows, one gold Accept (52 px) with equal-weight Reschedule and Decline (48 px), the check line and conflict note, day timeline and 7-day strip; venue details with the ruled YOUR DATE strip, deposit and balance split, hall/session segmented control, package checks, Availability / Prices toggle, and a sticky CTA with `No payment now`. On venue details the sticky CTA bar replaces the tab bar.
10. **Wordmark.** Newsreader "Ghazal" and Amiri "غزل" with a thread baseline ending in a knot is the master lockup; the Majlis doorway-with-lamp is an app-icon study only.
11. **Flutter subset.** ADR 0024 and ADR 0031 d3 stand. The needs outside the subset and their Flutter equivalents are tabulated in `01-direction.md` section 9 (sticky bars, scroll-linked compare header, the named arch clip, the thread painter, grid replaced by flex, tracked uppercase, brief-token underline, rails).

## Consequences

- One identity and one component vocabulary for 90 screens; the premium feel comes from photography and serif, the operational clarity from Majlis and Thread. The cost is a two-voice type system (serif display, sans UI) and a four-family font set; the figures rule and the hotel serif restriction must be lint-enforced.
- Fonts to add to the font build (`tools/fonts/build-fonts.sh`): Newsreader 300/400 and Amiri 400, static, subset; Arabic display subset should stay under 150 KB (ADR 0016 D7 criterion). Cairo 300 and Newsreader italic are not shipped.
- Token requests for the integrator (single writer, ADR 0029): `color.ref.gold.650`, `color.ref.gold.550`, `size.control.cta` = 52, `shape.arch`, `type.display.*` per section 2.4 (including px word-spacing and letter-spacing), `z.*`, scrim tokens; ADR 0023 pins 4 weights 400 to 700 "so both families have every weight", which Newsreader 300 / Amiri 400 break by design.
- Conflicts with accepted ADRs that the owner or integrator must resolve (this ADR amends where listed in the header; the others are flagged, not silently overridden):

| ADR | Conflict | Proposed resolution |
|---|---|---|
| 0016 D6, D7 | Display slot said display never renders digits and capped moments at three per screen; the Kuwaiti-reviewer test (4 of 5) has not run; ADR 0016 records the religious-connotation risk of Amiri | Digits allowed only in the named display roles; run the test as validation before visual freeze, fallback arm A; Amiri used only at 22 px and above |
| 0016 D3 | Arabic column and EN small steps differ (caption 13/20 became 14/22, small 15/24 became 16/26, EN adds 13 and 15) | Maison table adopted for both languages |
| 0016 D5 | Eyebrow tracking +0.08em; Maison uses +0.14em | Keep Maison's 0.14em, max two eyebrows per screen; confirm or revert |
| 0017 D6 | Thread never a decorative divider, one thread per component | Amended: 1 px khayt allowed as a wayfinding rule |
| 0017 D9 | Reduced motion keeps a 120 ms cross-fade for spatial moves | Direction says 1 ms; confirm that push, sheet and shared element then jump |
| 0017 D5 | Favourite pop has no bounce; knot pop overshoots to 1.4 | Overshoot limited to the knot, once |
| 0003 D6 | At most two faint future nodes | Vertical timeline obeys it; the horizontal 5-knot summary shows all five |
| 0007 D6 | Tab bar visible on pushed detail screens | Venue details show the CTA bar instead of the tab bar |
| 0008 D4, D5 | 14-day strip; Accept 48 px; two secondary text buttons | 7-day strip on Today (14 days stay in Calendar); Accept 52 px; equal-weight outline buttons 48 px |
| 0009 D6, D8 | Differences-only is a segmented control; footer buttons are an outline choice group | Toggle (default ON); outline buttons, gold only after a hall is picked; new column badges are objective-row only |
| 0018 D3, D9 | Card name 16/22 medium; hero about 300 px with 88 px overlap | Serif d1 / d2 names; hero 400 px with 96 px overlap (the structured card is taller than the sentence card) |
| 0010 | none in format; Thread's quiet `.000` fils | Styling of exact mode only: colour ink-600, size round(0.8 x), minimum 12 px, no opacity |
| 0023 | Gold-ink start #845F20, label ink start #4A3C40, weights 400 to 700 | gold-700 #7A5C1E (5.96 / 5.22) and ink-900 label pass the gates; Newsreader 300 is an exception |
| 0024 | aspect tokens 4:3, 16:9, 1:1, 3:4 | 4:5, 16:10, 1:1 added; the old ratios unused |
| NF-DSN-06 | PRD calls Soft Rose the primary surface | Canvas #FFF9F5 is the surface, rose-100 the tinted panel (as ADR 0023 already assumes) |
| Maison gold-600 | #B8924D is 2.77:1 on canvas, below 3:1 for a sole state carrier | `gold-650` added for state strokes; `gold-600` decorative only |

- `docs/design/01-direction.md` is rewritten (the interim file proposed `thread` as the base); `docs/product/open-questions.md` OQ-P-20 and the AGENTS.md repo-map line "direction ... TODO" are now stale and need an integrator edit, as does the ADR index (`docs/decisions/README.md`, row 0030).
- Static pages stay as an archive (`design/explorations/README.md`); the first screen built in the Studio must resolve the Home hero composition (wordmark and bell relative to the arch crown) and report back.

## Alternatives considered

| Alternative | Scores (CD / UX / skeptic) | Why not chosen alone |
|---|---|---|
| Maison | 101 / 99 / 101.5 | Best photography, typography and distinctiveness; weakest hotel app (greeting card, tall request card), thinnest compare, serif in a data app, editorial tropes, tappable-sentence engineering cost and 40 px tokens |
| Majlis | 99 / 104 / 103 | Best compare, hotel triage, measurement and Arabic; Ink-heavy chrome (94 and 120 px bars), arch and lattice read as mosque or gimmick, Markazi too light, conventional booking widget on Home |
| Thread | 93 / 96 / 90 | Best systems idea (one thread, five knots) and operational views; weakest premium feel, thin Poppins/Cairo Light, text on busy photos, sub-12 px decimals, most off-grid CSS |
| Thread as the base (the interim working assumption in the previous `01-direction.md`) | n/a | Rejected by the lead after the judging: premium feel is the product's first requirement; Thread supplies the component, not the identity |
| Pure Majlis with grafts | n/a | Would keep Ink chrome and the arch as identity; the arch is limited to one hero instead |
| Another display pair (Cormorant + Amiri, Newsreader + Markazi, El Messiri) | n/a | Tested in the Maison lab: Cormorant is the wedding-template default with a small x-height; Markazi reads light at +22%; Newsreader + Amiri match x-height and digit height within 0.01 em at x1.10 |
| Poppins and Cairo only, Light display (Thread) | n/a | Remains ADR 0016 arm A, the fallback if the display test fails |

## Related requirement IDs

| ID | Effect |
|---|---|
| NF-DSN-01, NF-DSN-02, NF-DSN-03 | Luxury, large imagery, whitespace: Maison identity |
| NF-DSN-05, NF-DSN-06 | Gold restrained, gold-is-a-verb lint; palette values pinned |
| NF-DSN-07, NF-DSN-08 | Poppins and Cairo for UI; contrast table in the direction |
| NF-DSN-09 | One component library: the Booking Thread and shared components |
| NF-LOC-01, NF-LOC-02, NF-LOC-05 | Arabic scale, mirroring, figures role |
| CA-HOME-01..08 | Structured brief card, categories as photo tiles |
| CA-CMP-01..10 | Compare layout |
| CA-VDET-01 | Full-bleed gallery hero |
| CA-BOOK-12 | Confirmation hero and thread completion |
| HA-BOOK-01, HA-BOOK-03, HA-BOOK-04 | Triage card, Accept, Reschedule, Decline |
