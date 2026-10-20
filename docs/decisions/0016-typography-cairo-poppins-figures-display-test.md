# ADR 0016: Typography: Cairo and Poppins as the functional pair, a Cairo 'figures' role, and a tested display slot

| Field | Value |
|---|---|
| Status | accepted. Update: refined by ADR 0030 (display slot filled with Newsreader + Amiri, scale and Arabic column per `docs/design/01-direction.md` 2.4, figures x1.08) |
| Date | 2026-10-12 |
| Scope | Fonts, type scale, weights, Arabic type rules, numeric figures role, display slot, text scaling; tokens and Flutter theme |
| Owner confirmation still needed | OQ-L-09 (run the display-typeface test before visual freeze; name five Kuwaiti reviewers). The display decision is made by amendment, not now |
| Related ADRs | 0010 (numbers and digit styles), 0013 (Arabic copy and length), 0014 (QA), 0017 (motion), 0022 (font bundling and theme), 0023 (typography tokens), 0024 (spec and handoff) |

## Context

The PRD fixes Cairo for Arabic and Poppins for English (NF-DSN-07); the brief asks for a deliberate type scale (state the ratio), language-specific sizes and line-heights, tabular figures for prices and dates, nothing under 12px and body at 15-16px or more, and leaves a refined editorial display face open for exploration. Measurements from the font files (fontTools, 2026-10-10):

- **Poppins has no `tnum` or `pnum` features** (only `ss01`-`ss04`) and proportional digits (advance of '1' is 350, of '0' is 641 on a 1000 UPM). `font-variant-numeric: tabular-nums` and `FontFeature.tabularFigures()` do nothing for Poppins.
- **Cairo's Western digits are all 560 units wide** (tabular by default); its Arabic-Indic digits are 250-678 (not tabular). Cairo digit height is 0.660em against Poppins 0.724em, so Cairo digits are about 9% shorter.
- **Arabic needs about +8-10% size** to match Latin: Cairo's Arabic body-letter height is 0.500em against Poppins' x-height 0.548em. Native line boxes differ a lot (Cairo 1.874em, Poppins 1.5em), so line heights must be explicit.
- Cairo variable font is 585 KB with a `slnt` axis (faux-italic Arabic is a typographic error). Static instances are 65 KB per weight (Arabic plus Latin subset); Poppins Latin subset is 14 KB per weight; about 316 KB in total.
- Contrast facts (computed): Ink #5A4B4F on canvas is 7.88:1; gold on canvas is 1.91:1, so gold is never a text colour.
- Letter-spacing and italics break Arabic joining; Arabic eyebrows use size and colour, not tracking or uppercase.
- Quiet-luxury references (Aman, Four Seasons) use one editorial display face for a few moments and a plain grotesque for everything functional, with hierarchy by size and tracking rather than weight. Naskh display faces carry a religious-connotation risk in a commerce app.

## Decision

**1. Functional pair stays as the PRD says.** Arabic UI = Cairo only (so Latin runs inside Arabic text share Cairo's baseline); English UI = Poppins with Cairo as font-family fallback (Arabic venue names inside English UI). Static self-hosted subsets, no runtime font fetching: Cairo 400/500/600/700, Poppins 400/500/600, Arabic plus Latin subsets, no slant instance.

**2. Third role 'figures'.** Standalone numeric components use Cairo Western digits in both languages: price amounts including the currency token, KPI values, calendar cells, times and durations, counters, ratings, table cells, step counters, countdown numbers. Digits inside a sentence of body copy stay in the text font. English figures are sized at 1.09 times the neighbouring Poppins text, rounded to whole px (14 to 15, 16 to 17, 20 to 22, 24 to 26, 32 to 35), because Cairo digits are 9% shorter; Arabic figures equal the Arabic text size (same family). Figures use the weight of the text they sit in. A mixed-run price line such as `From` (Poppins) `KD 2,450` (Cairo) `for 300 guests` (Poppins) must share a baseline and is part of the test below.

**3. Scale.** Base 16, ratio 1.25 (major third) snapped to the 4-pt grid: 16, 20, 24, 32, 40, 48, plus fixed small steps 12 and 14.

| Role | English size/line | Arabic size/line |
|---|---|---|
| caption | 12/16 | 13/20 |
| small | 14/20 | 15/24 |
| body | 16/24 | 17/28 |
| title-3 | 20/28 | 22/32 |
| title-2 | 24/32 | 26/36 |
| title-1 | 32/40 | 35/48 |
| display-2 | 40/48 | 44/60 |
| display-1 | 48/56 | 52/68 |

Arabic sizes are English times 1.08-1.10 rounded. Minimums: 12px English, 13px Arabic; body at least 16 English, 17 Arabic. Line-heights are explicit pixel values in tokens, never `normal`; Flutter styles use even leading distribution. Arabic body 1.65-1.75, Arabic headings at least 1.35.

**4. Weights.** English 400 body, 500 labels and buttons, 600 titles. Arabic uses the same numeric weights by default; whether Arabic captions and small text need one step more (500 at 13/15px) is decided in the on-device test, as a token, not per screen.

**5. Arabic rules enforced in tokens and lint.** Letter-spacing 0, no italics or synthetic slant or bold, no uppercase transforms, no justified text, no hyphenation. English-only eyebrow labels may be uppercase 12px with +0.08em tracking; the Arabic eyebrow equivalent uses size and Ink-muted colour at 13px with no tracking.

**6. Display slot (reserved, not yet filled).** Tokens `type.display.*` exist for at most three brand moments per screen (home hero headline, countdown day count, venue name on the details hero), used at 28px and above. Until a pairing is chosen they alias the functional pair at weight 400, so swapping is a token change. A display face never renders digits (digits fall through to the figures role), because display faces rarely ship `tnum`.

**7. Display test** (decide by amendment before visual freeze; does not block screens). Same three moments, Arabic and English, at 360 and 390 on a real device, three arms:

| Arm | Fonts |
|---|---|
| A control | Poppins 400 plus Cairo 400, hierarchy by size and tracking only |
| B editorial pair | Cormorant Garamond 500 (Latin) plus Amiri 400 (Arabic), both OFL, chosen for the 'ghazal = love poem' idea |
| C single family | El Messiri 500 (Arabic and Latin in one OFL family, removing the cross-script matching problem) |

Criteria: x-height and stroke harmony across scripts at 28-40px; size after subsetting at or under 150 KB per script; baseline alignment against figures in the same line; no cliché (the Arabic display must read as hospitality, not as Quranic Naskh or a government document, hence the Kuwaiti reader question); no `tnum` dependency. Decision rule: B or C replaces A only if at least four of five Kuwaiti reviewers prefer it and it passes every criterion; otherwise A ships. The specimen page lives under `design/explorations/`.

**8. Text scaling.** Respect OS text scale up to 200% for body and labels with reflow (no clipping at 360px); display roles clamp at 1.2 so the hero never overflows.

**9. Colour of type.** Text uses Ink or the Gold-ink token; gold itself is never a text colour (NF-DSN-08, 1.91:1 on canvas).

## Consequences

- Prices, calendars and tables align in both languages; Arabic and English read at the same optical size; a display upgrade is a token swap.
- English price lines mix Cairo digits with Poppins words; the 1.09 compensation must be verified on device (it is the main typographic risk and is in the test).
- Four Cairo plus three Poppins static weights at roughly 65 KB and 14 KB each is about 300 KB; fonts are bundled with the app, so the 2 s budget is protected only if they are never fetched at runtime (ADR 0022 F, G).
- Arabic sizes and line-heights are larger than English ones, so Arabic screens are taller; layouts must be fluid in height.
- Amiri and any Naskh display carry a religious-connotation risk in a commerce app; this is why the display is tested with Kuwaiti readers and limited to at most three moments per screen.
- The same static TTFs load in the prototype through `@font-face` and in Flutter through the `ghazal_ui` package (ADR 0024 item 8, never `@fontsource`); the build script is `tools/fonts/build-fonts.sh`.
- Poppins ships weights 400/500/600 here, while ADR 0023 allows 400/500/600/700 'so both families have every weight'; the Poppins 700 instance is therefore not needed until a token uses it.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Poppins digits for prices and tables | No `tnum`; columns would not align (the brief demands tabular figures) |
| A different Latin face with `tnum` | Departs from the PRD's Poppins without a justified gain; the figures role solves alignment |
| Cairo variable font | 585 KB; `slnt` axis allows faux-italic Arabic; static instances are smaller and identical across Flutter and web |
| `google_fonts` runtime fetch | Offline failure, cost, flash of fallback text against a 2-second target |
| One family for both scripts (El Messiri everywhere) | Tested only as arm C of the display experiment, not for the functional text |
| Editorial display now (Cormorant Garamond plus Amiri) | Cultural-connotation risk and cross-script harmony are unproven; decided by test |
| Same pixel sizes for Arabic and English | Arabic reads smaller at equal size; +8-10% rounded |
| Letter-spaced Arabic eyebrows or uppercase transforms | Breaks joining; Arabic uses size and colour |
| Browser or OS default line-heights | Cairo's native box is 1.874em; explicit pixel line-heights only |
| Gold as a text colour | 1.91:1 on canvas; Gold-ink only |

## Related requirement IDs

| ID | Effect |
|---|---|
| NF-DSN-07 | Cairo for Arabic, Poppins for English |
| NF-DSN-08 | Accessible contrast; gold never a text colour |
| NF-DSN-01, NF-DSN-03 | Luxury, minimal, generous whitespace (display slot restraint) |
| NF-LOC-01, NF-LOC-05 | Both scripts first-class; figures role carries money |
| CF-19 | Palette versus contrast; Gold-ink and deep-ink labels |
