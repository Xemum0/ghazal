# Text diet: say less, show more

> **Binding** for both apps and the prototype (ADR 0034, accepted 2026-10-19; owner request). It sits beside `01-direction.md` (look) and `content-guidelines.md` (voice) and refines ADR 0013 (voice) and ADR 0030 (direction). Where this page and an older screen disagree, this page wins and the screen is changed. Component names below are the ones exported from `design/src/system/`; the gallery pages `#/gallery/illustration` and `#/gallery/diet` show every one of them in both languages.

## 0. The rule in one line

**The app speaks through illustration, icon, number, image and one-word labels. A sentence is the exception, and every exception has a place to live.**

The owner's words (2026-10-19): "reduce the text from the app design and make more icons and illustrative without the most need of texts". A couple planning a wedding on a phone, often one-handed and in a hurry, should understand a screen from its shapes and figures before reading anything. Arabic readers and non-Arabic readers (about 70% of Kuwait's residents are not Kuwaiti) are served by the same icon and the same number.

The ladder, from first choice to last resort:

| Step | Tool | Example |
|---|---|---|
| 1 | Illustration | an empty shelf says "nothing saved yet" |
| 2 | Icon plus value, no label | `[users] 350` |
| 3 | A number with its unit | `4 h`, `KD 12 /guest` |
| 4 | One word (verb first for actions) | `Request`, `Pending` |
| 5 | A short phrase within budget (section 1) | `Pick a date` |
| 6 | A sentence, only for the three exceptions (section 6), behind an info icon | cancellation terms |

If a step above would do the job, the step below is wrong.

## 1. Word budgets per element

Counted as visible words, EN and AR separately. Numbers, units, prices and dates count as one word each (they are values, not prose). User-authored content (chat messages, reviews) and venue-authored content (descriptions, policies written by the partner) are exempt from the budget but are always clamped (2 to 3 lines, `Show more` is the chevron, not a sentence).

| Element | Budget (EN / AR) | Form | Notes |
|---|---|---|---|
| Screen title (top bar, hero headline) | 3 / 3 | noun phrase | `Your vouchers`, `Compare`. Never a sentence, never a greeting banner |
| Section title | 2 (3 max) / 2 | noun | `Facilities`, `Near you` |
| Button, action | 2 / 2 | verb first (AR: verbal noun) | `Send request`, `Redeem`, `إرسال الطلب` |
| Field label | 2 / 2 | noun | `Phone`, `Date` |
| Placeholder | 3 / 3 | noun | no instructions inside a field |
| Caption or helper under a control | 6 / 5 | fragment | only when it prevents an error (a format, a limit, a consequence); otherwise delete |
| Chip, filter, tab label | 1 (2 max) / 1 (2 max) | noun | |
| Status | 1 / 2 | icon + one word | `Pending`, `Confirmed`; Arabic may need two (`بانتظار الرد`) |
| Toast, snackbar | 4 / 4 | fragment | `Saved`, `Request withdrawn`; Undo is a one-word action |
| Empty, success, error, offline title | 4 / 4 | fragment | plus one action (section 5) |
| Onboarding slide | 5 / 5 | fragment under an illustration | no second line, no body |
| List row title | 3 / 3 | noun | no subtitle by default; leading icon or illustration; facts as `FactRow` |
| Notification row | 5 / 5 | fragment | icon says what kind |
| Card (venue, service, request) | name + facts (icon + value) + price | | no sentences, no taglines |
| Body paragraph | 0 | | only the three exceptions in section 6 |

Hard cap per screen, excluding authored content and data values: **35 visible words** for a normal screen and **45** for a form with fields. A screen over the cap needs a reason in its file header.

## 2. Facts are icon plus value, no label

A fact is a property the reader already understands from its glyph. The label moves into the accessible name (visually hidden text), never on screen.

| Fact | Glyph (registry name) | Value form | Example |
|---|---|---|---|
| Guests, capacity | `users-three` | integer or range | `350`, `200-500` |
| Area, size | `ruler` | number + unit | `1,200 m²` |
| Session | `sun` (day), `sunset` (afternoon), `moon` (evening) | the glyph is the value | no word |
| Rating | `star` | figure | `4.8`, reviews as a second quiet figure |
| Price | `coins` | money from the formatter | `KD 4,200` |
| Price per guest | `per-guest` | the glyph, then the money | `[person] KD 12` |
| Distance | `navigate` | number + unit | `3 km` |
| Time left | `timer` | duration figure | `23 h` |
| Duration | `hourglass` | number + unit | `4 h` |
| Date | `calendar` | short date | `Thu 14 Jan` |
| Women, men, mixed section | `section-women`, `section-men`, `section-mixed` | the glyph is the value | abstract symbols, no faces |
| Parking, valet, stage, buffet, music, photography | `parking`, `valet`, `stage`, `buffet`, `music`, `camera` | present = shown, absent = not shown | no "Yes/No" words |

`FactChip` is one fact (icon, optional value, optional unit; a fact that is its glyph alone, such as the moon of an evening session, omits the value). `FactRow` lays out 2 to 5 of them on one line and wraps only when the width runs out (`overflow="scroll"` keeps one line for a rail). Rules: never more than five facts in a row; the order is the same on every card (guests, area, session, rating, price); a fact that is not known is omitted, never shown as a dash. Colour carries nothing: the glyph and the figure do.

## 3. Statuses are icon plus one word

`StatusPill` and `StatusIcon` always pair a glyph with at most one word (Arabic at most two). The glyph and word table is `statusMeta` in `system/core/StatusPill.tsx`; colour is reinforcement only. Time is a fact, not part of the label: `Approved` plus a `timer` fact `23 h`, never `Approved, confirm within 24 hours`. `StatusIcon` alone (no word) is allowed only inside a row that already names what it is about, and then carries the word as its accessible name.

## 4. Lists, numbers, units

- A list row is a leading icon or illustration, a one-line title (<= 3 words) and a trailing value or chevron: `IconListRow`. The subtitle is the exception; when a row needs a second piece of information it is a fact (icon + value) in the trailing slot or a `FactRow` under the title.
- Numbers and units replace sentences: `350 guests` is `[users] 350`; `Valid until 12 Dec` is `[calendar] 12 Dec`; `Pay the venue directly` is the `receipt` glyph with `Off-app` only where the voucher model needs it.
- Every number goes through the formatter (`useFormat`); money is integer fils; a unit is mandatory next to a bare number unless the glyph names it (guests, area, time).
- The Booking Thread keeps its five knots; each knot is an icon, and only the active knot carries a one-word label (`BookingThread`, `IconProgress`).

## 5. States: illustration, short title, one action

Empty, success, error and offline states are one composition: `Illustration` (hero or lg), a title of at most four words, and exactly one action (a secondary or tertiary link is allowed beside a primary, never a third).

| State | Component | Illustration (examples) | Title (EN) | Action |
|---|---|---|---|---|
| Empty: saved | `EmptyState` | `empty-saved` | `Nothing saved` | `Browse halls` |
| Empty: messages, bookings, vouchers, visits, results, notifications, listings | `EmptyState` | `empty-messages`, `empty-bookings`, `empty-vouchers`, `empty-visits`, `empty-results`, `empty-notifications`, `empty-listings` | two to four words | one verb |
| Success: request sent, voucher ready, booking confirmed, payment done, visit booked | `SuccessState` | `success-request`, `success-voucher`, `success-booking`, `success-payment`, `success-visit` | `Request sent` | `Done` |
| Error | `ErrorState` | `warning`, `card` (payment), `shield` (no access), `no-result` (not found) | `Something went wrong` | `Try again` |
| Offline | `ErrorState kind="network"` | `wifi-off` | `You're offline` | `Try again` |

Error recovery text (what was and was not charged, what to do next) is allowed, but lives behind an info icon (section 6), not on the screen: `ErrorState` carries its catalogue sentence as `detail`. For screens built before the diet, `EmptyState` treats a legacy `body` the same way: six words or fewer stay as a quiet helper, anything longer moves behind the info glyph, and an `icon` maps to its illustration, so those screens get shorter before they are rewritten. One celebratory line per flow (ADR 0013 D5) is the success title itself.

Onboarding: `OnboardingSlide` = illustration + at most five words, nothing else. Photography stays on the language screen and venue content; the intro uses illustration.

Single-purpose state screens (a state, a success, an onboarding slide) may centre their one composition. Content screens never do (direction anti-template rule).

## 6. The three exceptions: paragraphs live behind an info icon

Only three kinds of paragraph survive, and none is on the screen by default:

| Exception | Where it lives |
|---|---|
| Legal consent (terms, privacy, payment authorisation) | `InfoButton` next to the checkbox or CTA, opening `InfoSheet`; the checkbox label is two words (`I agree`) |
| Cancellation, refund and voucher terms | `InfoButton` in the section or card header, opening `InfoSheet` |
| Error recovery (what was charged, what to do) | `InfoButton` on the `ErrorState`, opening `InfoSheet` |

`InfoButton` is a 44 px icon button (the `info` glyph) with an accessible name; `InfoSheet` is the sheet that opens (title <= 3 words, then the paragraph, then `Done`). A paragraph that is not one of the three is deleted, or turned into an icon, a fact or a number.

## 7. Icon-only controls

| Allowed icon-only (universal glyphs) | Never icon-only (keep one word) |
|---|---|
| heart, share, phone, chat, close, search, filter, calendar, pin, camera, back, more, compare (scale) | any control about money (pay, price, amount), accept, decline, delete, remove, confirm, send request, redeem, cancel booking |

Every icon-only control has an accessible name (`aria-label`, in the active language) and a 44 x 44 px target. `IconTabs` and `IconSegmented` show glyphs with the one-word label under the selected item only; when the glyph alone is ambiguous in context, the word is shown on every item.

## 8. Arabic is shorter still

Arabic budgets are the same or lower. No filler (`من فضلكم`, `يرجى`, `نود إعلامكم`), no repeated subject (the honorific `كم` appears once in a screen, not in every line), verbal nouns for actions (ADR 0013 D2), no tashkeel except the two ADR 0013 permits, numbers in Western digits through the formatter. Do not translate an English phrase that the icon already says: write the shortest native word or leave it to the icon. Icons that carry reading direction mirror (ADR 0014); illustrations flag their own mirror (`illustrationMirrors`).

## 9. Illustration (summary; the catalogue is `#/gallery/illustration`)

| Rule | Form |
|---|---|
| Hand | one family: 1.5 px Ink line (constant at every size), round caps and joins, generous negative space |
| Colour | Ink line; Rose tint for one quiet base shape; **one** small Gold accent per drawing (a dot, a flame, a knot); no gradient, no shadow, no photo |
| Subject | Gulf wedding objects and calm architecture; never people, faces or hands; no emoji, no cartoon |
| Tokens | CSS custom properties only (`--gz-illus-*`), no hex; sizes `sm 64`, `md 96`, `lg 144`, `hero 200` |
| Use | one per screen at `lg` or `hero`; `sm` and `md` only as a list leading element (`IconListRow illustration`); never over a photograph; never in a button |
| Accessibility | decorative by default (hidden from assistive technology); give `label` only when the drawing is the only carrier of meaning |
| RTL | directional drawings flip through the registry flag (`illustrationMirrors`: dallah, key, oud, car, route, chat, group-chat, no-result and the compositions built on them), nothing else does |
| Catalogue | 39 spot drawings (arched doorway, chandelier, fanous, dallah, finjan, bouquet, rings, cake, invitation, envelope, voucher, QR, calendar, key, hall, kosha, beach and garden arches, hourglass, clock, group chat, chat, seal, route, camera, vase, buffet, oud, car, suitcase, make-up, dress, shield, shelf, no-result, wifi-off, warning, bell, card) and 21 compositions (`onboard-*` 3, `empty-*` 8, `success-*` 5, `partner-*` 5), in `design/src/system/illustration/` (`registry.ts` is the list) |
| Gold | one accent per drawing, decorative and never interactive: a dot, a flame, a knot or a spark of 10 units or less (about 8 px at `md`), or one gold hairline (the scan line of a QR, a glint). Companions inside a composition are drawn `Quiet` (no gold, no tint), so a composition still has one accent. It never becomes an extra gold block beside the one gold primary action |

## 10. Accessibility

Every icon has a text alternative (visually hidden text or `aria-label`). Colour is never the only signal (icon plus shape plus word, as in 01-direction section 8). Contrast rules are unchanged (WCAG 2.2 AA; ink-600 on canvas for muted values; gold-700 for gold glyphs); decorative line art is exempt, informative glyphs are not. Targets stay 44 x 44. Focus rings and reduced motion are unchanged. A visually hidden label is not counted by the word census and not removed by this policy.

## 11. What changed in the system (flow agents: adopt these)

| Was | Use now |
|---|---|
| `KeyFact` (icon + label + value) | `FactChip` / `FactRow` (icon + value) |
| `ListRow` with `subtitle` | `IconListRow` (leading icon, one line); subtitle only for names with a role |
| `EmptyState` with `body` | `EmptyState` with `illustration` + title; `body` is for the rare helper (<= 6 words) |
| Success screens built by hand | `SuccessState` |
| `ErrorState` catalogue sentence | `ErrorState` title + retry; recovery text through `detail` (InfoSheet) |
| Paragraphs under a switch, checkbox or CTA | `InfoButton` + `InfoSheet` |
| `Tabs`, `SegmentedControl` with words | `IconTabs`, `IconSegmented` where the glyph is universal; words otherwise |
| `StatusPill` with a time phrase | `StatusPill` (one word) + a `FactChip` for the time |
| Booking Thread with five labels | `BookingThread` with icon knots, one label on the active knot |
| `VoucherCard`, `PriceCompare` with captions | `variant="compact"`: icon, code, figures; labels in the accessible name |
| `RequestCard`, `KpiTile` with labels | facts as icon + value; KPI tiles as `IconStat` |
| Onboarding intro with photo, title and body | `OnboardingSlide` (illustration + <= 5 words) |

Already trimmed inside the system (screens get shorter without edits, then drop their own captions): `StatusPill` and its labels, `BookingThread`, `VoucherCard` and `VoucherChip`, `PriceCompare`, the venue price line (`CardPriceLine`), `VenueCard` (glyph facts, section symbols, date-only availability line, trend chip), `BriefCard` (glyph rows, `Show 38 halls`), `RequestCard`, `KpiTile` (with `icon`), `EmptyState` / `ErrorState`. Flow-local components that duplicate a system piece should be replaced by it.

## 12. Measuring

Baseline: `docs/engineering/text-diet-baseline.json` (134 screens, 11,700 EN and 10,733 AR visible words before the diet). Gauge: `node design/scripts/wordcount.mjs --lang both --only <ID-prefixes> [--out file.json]` counts visible words in the default state of each screen (status bar, `.gz-sr-only` and `aria-hidden` excluded, so icons and hidden labels cost nothing).

| Target | Value |
|---|---|
| Overall and per screen, EN and AR | at least 45% fewer words than the baseline |
| Hero screens: `CL-DISC-01` (home), `CL-VENU-01` (venue), `CL-SAVD-04` (compare), `CL-VCHR-03` (voucher), `CL-BOOK-05` (request), `CL-BOOK-08` and `CL-BOOK-09` (confirm), `HL-TODY-01` and `HL-TODY-02` (today), `HL-BOOK-01` (partner requests) | at least 55% fewer |
| Requirement coverage | must not drop: the diet removes words, never capabilities. Every requirement ID a screen declares in its header still has a visible, reachable home; `prd-tracer` re-checks a flow after its diet pass |

A flow reports its before and after numbers (EN and AR) in its hand-back. Words saved by deleting a control that a requirement needs do not count. Status on 2026-10-19 (system owner pass only, measured with `wordcount.mjs --lang both` over all 134 screens, no flow has adopted yet): the trimmed system components alone take the census from 11,700 to 11,233 EN words (-4.0%) and from 10,733 to 10,257 AR words (-4.4%). The screens that already moved are the ones built from the trimmed pieces: CL-DISC-01 481 to 288 EN (-40%), CL-SAVD flow -23%, client/discover -31%, client/vouchers -14%, CL-VCHR-03 -28%, CL-BOOK-09 -23%; hero screens built mostly from flow-local components (CL-VENU-01 -5%, CL-BOOK-05, CL-BOOK-08, CL-SAVD-04, HL-TODY-01, HL-TODY-02 unchanged) and flows that have not adopted (auth, messages, onboarding, planner, profile, services, every hotel flow but bookings) are untouched. Reaching the targets above is the flows' work with the pieces in section 11; a screen is accepted when its own before and after numbers meet its target.

## 13. Self-check before handing a screen back

1. Cover the text: can a first-time user say what the screen is for from the illustration, icons and numbers alone?
2. Every label that survives is within its budget (section 1); every sentence is one of the three exceptions and sits behind an info icon.
3. Every icon-only control is on the allowed list, has an accessible name and a 44 px target; nothing about money or a decision is icon-only.
4. Arabic read aloud is shorter than the English; the Arabic PNG has no clipped, wrapped or reversed text.
5. Illustration: one per screen, one gold accent, no people, right direction in Arabic.
6. `wordcount` shows the target; `pnpm i18n:check`, `pnpm typecheck`, `pnpm lint:css` are green.
