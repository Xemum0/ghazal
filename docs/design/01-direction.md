# Visual direction: Maison identity, Majlis structure, Thread verbs

> **Binding** for both apps and the web prototype (ADR 0030, accepted 2026-10-12). It replaces the interim "state of the explorations" version of this file (which proposed `thread` as the base). Where a value is missing here, copy it from the named exploration CSS (`design/explorations/<key>/direction.css`); do not invent. Tokens move to `packages/design-tokens/src/` at the foundation PR (ADR 0023); until then this file is the value source. Rule 12 and section 9 list every place the direction needs something outside the Flutter subset (ADR 0024, relaxed by ADR 0031).

> **Refined by ADR 0034 (2026-10-19):** the copy volume rules live in `02-text-diet.md` (binding). The illustration layer (one hand: 1.5 px ink line, rose tint, one small gold accent per drawing) is allowed in empty, success, error, offline and onboarding states and as a small leading element in lists; the old "illustration-free blank" is retired; single-purpose state screens may centre their composition. Gold stays a verb in UI chrome; the bounded accent inside a drawing is the only other gold.

## 0. Concept

Ghazal behaves like the front desk of a house you would be glad to be a guest in. **Maison** gives the identity: an ivory canvas, full-bleed uncropped venue photography, serif signage for names and prices, restraint. **Majlis** gives the structure: a 20 px gutter, a strict control-height scale, real system chrome, a labelled compare bar, a triage-first hotel app. **Thread** gives the verbs: غزل means love poem and spun thread, so one gold line, the *khayt*, marks where you are (section rules, the selected tab) and one component, the **Booking Thread** (Request, Approval, Deposit, Balance, Your day), shows status, payment schedule and countdown identically to couple and hotel. Gold is a verb: it appears only where something is chosen, progressing, waiting or actionable. The client app is the aspirational face of the house; the hotel app is its back office, same system, calmer, denser, and serif only for names and the greeting.

## 1. The twelve rules

| # | Rule | Precise form |
|---|---|---|
| 1 | Identity and type | Display = Newsreader 300/400 (EN), Amiri 400 at x1.10 with display word-spacing (AR), for venue names, hero headlines, hero price, brief sentence, countdown numeral. UI = Poppins (EN) + Cairo (AR). Numbers = Cairo tabular Western digits in both languages (section 2.4). Hotel app: serif ONLY for venue names and the greeting; never dates, totals, KPIs, triage data. Fonts self-hosted static files, no runtime fetch. |
| 2 | Colour | Maison ramps (2.1). Gold-500 = fills, hairlines, knots, never text. Gold-700 = the only gold for text and icons. Rose-100 quiet panels only. Gold is a verb (2.3). No gradients except photo scrims. |
| 3 | Shape | Radius 8 (button, input, chip), 12 (card, panel, card image), 20 (sheet top), full (avatar, toggle, count badge); 4 for status pills and micro thumbs. Arch crop only on Home hero and onboarding/splash hero. Lattice dropped. Hairline-first elevation. |
| 4 | Layout | 4-pt scale, one gutter 20, section rhythm 32, heights 44 / 48 / 52 / 56, frame 390x844 with real chrome (safe top 47, bottom 34, home indicator), fluid 360-430, logical properties only, one Arabic scale (2.4). |
| 5 | Signature | Khayt = 1 px gold-500 rule at section heads and under the selected tab. Booking Thread = 5 knots; a knot ties only on a real event; line draws over 480 ms (section 4). Hotel Today: vertical day timeline, depleting reply bar, 7-day strip. |
| 6 | Search | Home = structured brief card (date, area, guests, budget, each at least 44 px) plus CTA `Show 38 halls free on 14 Jan`. The typeset brief sentence is the read-only echo on results, compare and booking headers; tap opens the edit sheet. |
| 7 | Compare | Three fluid thirds, serif names, rectangular 4:5 thumbs, sticky labelled action bar, `Differences only` toggle with hidden-row count, Best rated / Lowest price / Closest badges, `Best in row` marker, per-guest and deposit rows, range bars (price; capacity with tick at your guests), `How you book` row. |
| 8 | Venue details | Full-bleed hero with hairline progress; ruled `YOUR DATE` strip; deposit/balance split plus Booking Thread; hall/session segmented control; packages with checks; Availability / Prices calendar toggle; sticky CTA with `No payment now. Nothing is charged until the hotel approves.` |
| 9 | Hotel app | Ink header band (venue switcher, serif greeting), compact `Needs your reply` rows, one gold Accept, equal-weight Reschedule / Decline, `No other request for this date` line, conflict note with Compare link, day timeline, 7-day strip. No greeting card. Targets at least 44. |
| 10 | Motion | 120 / 200 / 320 / 480 ms (640 success token kept from ADR 0017); three curves (2.7); nothing loops, nothing blocks input; reduced motion = 1 ms. |
| 11 | Wordmark | Newsreader "Ghazal" + Amiri "غزل", thread on the baseline ending in a knot. The Majlis doorway-with-lamp is an app-icon study only. |
| 12 | Flutter subset | ADR 0024 stays. Exceptions and Flutter equivalents are in section 9. Sticky bars are allowed only with `/* flutter-ok: pinned sliver */` (ADR 0031 d3). |

## 2. Tokens

### 2.1 Colour (values from Maison `direction.css`; ratios computed by script, WCAG 2.x)

| Ramp | 950 | 900 | 800 | 700 | 600 | 500 | 400 | 300 | 200 | 100 | 50 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Ink | #231C1F | #2E2528 | #3F3337 | **#5A4B4F** (PRD) | #6F5F63 | #8A7A7E | #A89A9D | #C9BEBF | #E3DAD7 | #EFE8E4 | #F7F1ED |

| Ramp | 900 | 800 | 700 | 650* | 600 | 550** | 500 | 400 | 300 | 200 | 100 | 50 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Gold | #3F2F0E | #5B4416 | **#7A5C1E** text | #A67F2E | #B8924D | #C79F57 | **#D8B26E** (PRD) | #E1C386 | #E9D4A6 | #F1E3C4 | #F8EFDC pending | #FCF7EC |

\* `gold-650` is added (from Thread `--gold-600`): the only gold stroke that reaches 3:1 on canvas (3.53), used for rings and bars that are the sole carrier of a state. `gold-600` stays a strong decorative hairline (2.77, never sole carrier). \*\* `gold-550` (Thread) is the pressed fill of the primary button.

| Rose | 400 | 300 | 200 | 100 | 50 |
|---|---|---|---|---|---|
| Rose | #D9A9B6 | #E9C6D0 | #F2D9E0 | **#F8E7EC** (PRD) | #FCF3F5 |

Neutrals: `canvas` #FFF9F5 (PRD), `paper` #FFFDFB (inputs, sheets, raised panels). Functional (status only, always icon + label): `success-700` #4C6A55 on `success-100` #E6EDE6; `danger-700` #9A4640 on `danger-100` #F5E3E0.

| Pair (foreground on background) | Ratio | Use |
|---|---|---|
| ink-900 on canvas | 14.26 | headings, labels |
| ink-700 on canvas / paper / rose-100 | 7.88 / 8.10 / 6.90 | body text |
| ink-600 on canvas / paper / rose-100 / ink-50 | 5.76 / 5.92 / 5.05 / 5.37 | muted text, captions |
| ink-500 on canvas / paper | 3.90 / 4.01 | control borders, open knot ring (non-text only) |
| ink-400 on canvas | 2.59 | disabled and decoration only |
| gold-700 on canvas / paper / rose-100 / gold-100 / rose-50 | 5.96 / 6.13 / 5.22 / 5.44 / 5.71 | gold text and icons |
| gold-800 on gold-100 | 8.05 | pending pill alternative |
| gold-500 on canvas / rose-100 | 1.91 / 1.68 | fails: fill, hairline, knot only |
| gold-650 on canvas / rose-100 | 3.53 / 3.10 | non-text state stroke |
| gold-600 on canvas | 2.77 | decorative hairline only |
| ink-900 on gold-500 / gold-550 / gold-400 | 7.45 / 6.04 / 8.75 | primary label, pressed, hover |
| ink-700 on gold-500 | 4.12 | REJECTED for text |
| canvas on ink-900 / ink-800 / ink-700 | 14.26 / 11.56 / 7.88 | text on dark panels |
| gold-500 / gold-400 / gold-300 on ink-900 | 7.45 / 8.75 / 10.23 | thread and gold text on dark |
| ink-300 / ink-200 on ink-900 | 8.22 / 10.82 | muted text on dark |
| success-700 on success-100 / canvas | 5.03 / 5.75 | confirmed pill, ok line |
| danger-700 on danger-100 / canvas | 5.10 / 6.05 | declined pill, error text |

### 2.2 Semantic roles (components use only these)

| Role | Token | Role | Token |
|---|---|---|---|
| text-strong | ink-900 | line (hairline) | ink-200 |
| text | ink-700 | line-strong | ink-300 |
| text-muted | ink-600 | control-border | ink-500 |
| text-accent | gold-700 | surface | canvas |
| text-on-dark | canvas | surface-raised | paper |
| text-on-dark-muted | ink-300 | surface-quiet | ink-50 |
| text-on-gold | ink-900 | surface-tint | rose-100 |
| mark (khayt, knot, selected) | gold-500 | surface-dark | ink-900 |
| mark-state (sole-carrier ring or bar) | gold-650 | focus-ring | ink-900, 2 px, offset 2 |
| pressed (gold fill) | gold-550 | gold-on-dark | gold-500 (text on dark: gold-400) |

Scrims (single-purpose, named): `scrim-top` rgba(46,37,40,.46), `scrim-mid` .16, `scrim-low` .50, `scrim-bottom` .72, `scrim-modal` .42, `rule-on-photo` rgba(255,249,245,.6), `ring-fab` rgba(46,37,40,.08). Cover gradient stops: top 0, transparent 22%, mid 40%, low 64%, bottom 100%. Gallery: top, transparent 22%, transparent 70%, bottom. Alpha is always a token, never parent opacity (ADR 0023).

### 2.3 "Gold is a verb" (lint)

| Allowed | Form | Forbidden |
|---|---|---|
| (a) the ONE primary action per screen | gold-500 fill, ink-900 label | gold panels, banners, cards, backgrounds, toggles, chips fills, icons fills |
| (b) the selected date or day | gold-500 fill, ink-900 label, ring 2 px canvas + 1 px gold-600 | gold text (use gold-700), gold gradients |
| (c) count badges | gold-500 fill, ink-900 12 px figure | gold borders on cards |
| (d) thread knots and beads | gold-500 fill (8 px diamond bead, 20 px booking knot) | more than one thread per component |
| (e) gold LINE up to 4 px | khayt rules, tab underline, thread, reply-window bar, range bars, strip marks | lines as decoration with no state or place |

Informative gold glyphs on light surfaces (best-in-row bead, held-day mark, ratings) use gold-700. Compare gold primary appears only on a hall the user picked, never by default.

### 2.4 Type

Families: `font-ui` Poppins 400/500/600 (EN) and Cairo 400/500/600/700 (AR, and Arabic runs in EN); `font-display` Newsreader 300/400 (EN) and Amiri 400 (AR); `font-fig` Cairo (digits, both languages). Static self-hosted instances, no italic, no slant (Newsreader italic is NOT shipped; the italic accent word is dropped). Display minimums: Newsreader at 20 px and above, Amiri at 22 px and above; below that use Cairo/Poppins.

Scale: ratio 1.25 on 16, snapped to the 4-pt grid (Maison). One table for both languages; Arabic = English x1.08 (Cairo) / x1.10 (Amiri), explicit leading, no tracking, no italic, no uppercase.

| Role | EN size/line | AR size/line | Face and weight | Tracking EN / AR |
|---|---|---|---|---|
| label (eyebrow, field label) | 12/16 | 13/20 | UI 500 / 600 | +0.14em uppercase / 0 |
| caption | 13/20 | 14/22 | UI 400 | 0 |
| body-s | 15/24 | 16/26 | UI 400 | 0 |
| body | 16/24 | 17/28 | UI 400; row title 500 | 0 |
| d1 | 20/28 | 22/34 | display 400 | 0 |
| d2 | 24/32 | 26/38 | display 400 | -0.005em / 0 |
| d3 | 32/40 | 36/52 | display 300 EN / 400 AR | -0.01em / 0 |
| d4 | 40/44 | 44/60 | display 300 / 400 | -0.015em / 0 |
| d5 | 48/52 | 52/68 | display 300 / 400 | -0.02em / 0 |
| d6 | 60/60 | 64/72 | display 300 / 400 | -0.025em / 0 |
| brief (sentence) | 24/40 | 26/48 | display 300 / 400 | -0.005em / 0 |
| countdown numeral | 96/96 | 104/104 | display 300 / 400 | -0.03em / 0 |
| compare name | 17/22 | 18/28 | display 400 | 0 |
| tab label | 12/16 | 14/18 | UI 500 / 600 | 0 |
| ui-title (section, hotel) | 20/28 | 22/32 | UI 600 / 700 | 0 |
| ui-xl (hotel date) | 24/32 | 26/38 | UI 600 / 700 | 0 |

Display word-spacing in Arabic (px, token per role, = -0.12 x size): d1 -3, d2 -3, d3 -4, d4 -5, d5 -6, d6 -8, brief -3, countdown -12. Tracking tokens are stored in px (ADR 0024 forbids `em`). Display numerals: `lnum pnum` (Newsreader/Amiri lining proportional); figures: `tnum lnum`.

**Figures role (Thread rule).** Every standalone number and every number inside a Poppins line is Cairo Western digits (560/1000 em, tabular). EN size = Poppins size x1.08 rounded to whole px: 12 to 13, 13 to 14, 15 to 16, 16 to 17, 20 to 22, 24 to 26, 32 to 35; AR figure size = Arabic text size (same family). Weight = weight of the surrounding text. Display numerals (Newsreader/Amiri) are allowed only for: hero price, price in the venue sticky bar, brief sentence, countdown numeral, venue-name plates; never in tables, calendars, hotel screens, compare cells, exact totals.

**Price format** (strings come only from `GzFormat`, ADR 0010; this table fixes type, not text):

| Context | Mode (ADR 0010 D8) | Amount face and size EN / AR | Fils / currency treatment |
|---|---|---|---|
| Card price line, shelf | browse | Cairo 500, 17 / 16 | currency `KD` in label style, ink-600; fils only if non-zero, three decimals |
| Venue sticky bar, plate price | browse | display 400, d1 20 / 22 (hero total d3) | currency label style ink-600 |
| Deposit, balance, schedule, summary | exact | Cairo 600, 17 / 16 (totals 22 / 22) | `.000` at round(0.8 x size), minimum 12 px, colour ink-600 (no opacity) |
| Compare cell | browse | Cairo 600, 17 / 16; per-guest line caption ink-600 | none |
| Hotel Today card / KPI | browse | Cairo 600; KPI hero 32/40 | currency label style; never serif |
| Hotel booking detail, revenue, payout | exact | Cairo 600, 17 | fils as above |
| Strike-through old price | browse | caption, ink-600, 1 px line-through | only when real (ADR 0018 D4) |

Currency sits visually left of the number in both languages (ADR 0010 D7); the number is an LTR isolate; NBSP between number and unit; units are mandatory (`per guest`, `for 350 guests`).

### 2.5 Spacing, layout, control heights

| Token | px | Use |
|---|---|---|
| space 1,2,3,4,5,6,8,10,12,16,20,24 | 4,8,12,16,20,24,32,40,48,64,80,96 | all gaps |
| gutter | 20 | the only screen gutter (Majlis) |
| section | 32 | between sections |
| card list gap / shelf gap | 24 / 32 | ADR 0018 |
| inside card / panel | 16 (hotel request card 20 / 16 / 12) | padding |
| control sm / md / cta / lg | 44 / 48 / 52 / 56 | 44: icon buttons, chips, segmented options, tertiary, toggles hit area; 48: secondary buttons, quiet actions; 52: primary CTA; 56: inputs, top-bar row |
| minimum target | 44 x 44 | everything tappable |
| list row | 64 min (queue row 80) | |
| frame / safe | 390 x 844; top 47, bottom 34 | real status bar (47, 15/20 Cairo 600, LTR), home indicator 134 x 5 |
| fluid | 360 to 430 | gutter fixed 20; thirds and rails by formula (ADR 0018 D8: card 72% snapped to 4) |
| bars | tab bar 56 + 34; CTA bar 12 + 52 + 12 + 34; compare bar 12 + 20 + 4 + 48 + 12 + 34 | bars are canvas with a 1 px ink-200 top rule, never Ink |

### 2.6 Shape, elevation, stroke, layers

| Token | Value |
|---|---|
| radius xs / sm / md / lg / full | 4 (status pill, micro thumb) / 8 / 12 / 20 / 999 |
| shape.arch | top crown only, path `M0 100 C0 46 28 36 50 0 C72 36 100 46 100 100 Z`, rise 64 (hero), width full; Home hero and onboarding/splash hero ONLY; gold-500 1 px line along the crown |
| elev-0 / elev-1 | none / 1 px border `line` (ring, no shadow layer) |
| elev-2 (floating: toast, tray pill, photo controls) | `0 1px 2px rgba(90,75,79,.08), 0 8px 24px rgba(90,75,79,.10)` |
| elev-3 (sheets) | `0 -1px 0 line, 0 -16px 40px rgba(46,37,40,.14)` |
| stroke hair / icon / thread / focus | 1 / 1.5 on 24 grid (16, 20, 24, 32 sizes) / 2 / 2 |
| knot sizes | bead 8 (rotated square); booking knot 20 (compact 12); now-knot ring 3 px gold-650 + 3 px canvas gap |
| z-index | base 0, raised 2, sticky header 20, bar 30, tray 35, scrim 40, sheet 50, toast 60, modal 70 |

### 2.7 Motion (Maison tokens; ADR 0017 where not changed)

| Token | Value | Use |
|---|---|---|
| dur-1 / 2 / 3 / 4 | 120 / 200 / 320 / 480 ms | press / selection / sheet, tab slide, knot pop / image reveal, thread draw, shared element |
| dur-success | 640 ms (kept, ADR 0017) | one success moment per flow |
| ease-out | cubic-bezier(.2, 0, 0, 1) | state changes, moves |
| ease-emph | cubic-bezier(.05, .7, .1, 1) | sheets, reveals, knot pop |
| ease-in | cubic-bezier(.3, 0, .8, .15) | exits only (sheet dismiss 200) |
| spring settle | mass 1, stiffness 400, damping 40 | gesture release (ADR 0017) |

| Behaviour | Spec |
|---|---|
| Press | tone step (one ramp step darker) + scale .985, 120 ms; gold primary to gold-550 |
| Segmented / tab thread | 2 px gold line slides under the active item, 320 ms ease-out; direction x `--dir` |
| Image reveal | opacity 0 to 1 and scale 1.035 to 1 (3.5%), 480 ms ease-emph, once; static ink-100 placeholder |
| Thread draw | scaleX 0 to 1 from inline-start, 480 ms ease-out, once on first reveal; segments sequential (120 each) |
| Knot pop | on a state change in view: scale .6 to 1.4 to 1, 320 ms ease-emph, once |
| Sheet | rise 320 ease-emph; dismiss 200 ease-in; drag-down; scrim fade 320 |
| Undo bar | 2 px gold line depletes over 8 s linear |
| Reduced motion | every duration 1 ms; state is kept, movement removed |
| Pending | OS activity indicator only; no looping thread loader |

### 2.8 Rose theme (comparison toggle, 2026-10-29)

**What it is.** A second colour theme of the web prototype, `rose`, next to the design above (`gold`, the default and unchanged). The owner asked to compare the gold design with a pinker one that uses the pink already in the product: every gold-bound token (primary fill, selected marks, hairlines and knots, tab-bar mark, pending pill, gold text and icons, the one accent of each drawing) becomes a rose step. Surfaces, ink, success/danger, photo scrims and layout do not change. **This is a client-comparison experiment, not a brand decision**: rules 2.1 to 2.3 still define the brand (Ink, Matte Gold, Soft Rose); the Flutter apps build gold only; if the owner picks rose, the apps take the same overlay (OQ-R2-12).

**How to switch.** A `Gold | Rose` control sits next to the `EN | AR` toggle on the Launcher (a single button on a phone-width window) and in the Studio toolbar (canvas, player, system and docs pages). The choice lives in the hash like the language, `#/?theme=rose` (any route, including `#/frame/<id>?theme=rose` and `#/gallery/<name>?theme=rose` for screenshots), and is remembered in localStorage as a convenience only. The hash always wins; `?theme=gold` returns to the default. Compare: `node tools/ports.mjs url design`, then open `<url>#/?theme=rose`.

**Where it lives.** `packages/design-tokens/src/tokens.json` under `$themes.rose`: the extra ramp steps (rose 500 to 900, hue about 344 degrees, harmonised with rose-400 #D9A9B6) and the map gold step to rose step (50 to 900, step for step; gold 50 to 400 land on the existing rose 50 to 400). The generator emits `[data-theme='rose']` at the end of `dist/tokens.css` (it re-points `--gz-color-ref-gold-*` at `--gz-color-ref-rose-*` and redeclares the gold-bound roles), a `themes` export in `dist/tokens.ts` and `tokens.flat.json`; the Dart output is untouched. `pnpm tokens:check` recomputes every pair of `a11y-pairs.json` against the rose model (127 pairs for gold, 127 for rose), so the contrast table below is enforced, not described. Screens need no code change; nothing may hard-code a gold value.

| Rose step | Hex | Role (takes the place of) | Measured |
|---|---|---|---|
| 500 | #E39BAF | fill, hairline, knot, never text (gold-500) | ink-900 label 6.78:1; mark on ink-900 6.78:1; 2.10:1 on canvas, so never a sole boundary |
| 550 | #D8899E | pressed fill (gold-550) | ink-900 label 5.66:1 |
| 600 | #CF7D93 | decorative hairline only (gold-600) | 2.87:1 on canvas |
| 650 | #C8627D | sole-carrier state strokes (gold-650) | 3.66:1 on canvas, 3.21:1 on rose-100 |
| 700 | #9A3C55 | the only rose for text and informative icons (gold-700) | 6.38:1 canvas, 6.57:1 paper, 5.60:1 rose-100, 6.12:1 rose-50 |
| 800 / 900 | #723142 / #4D2631 | strong text, deepest step (gold-800/900) | 7.89:1 / 10.77:1 on rose-100 |
| 400 / 300 | #D9A9B6 / #E9C6D0 | text on ink-900 (gold-400/300) | 7.30:1 / 9.53:1 on ink-900 |

## 3. Components

| Component | Rule |
|---|---|
| Button primary | 52 high (hero Accept 52), radius 8, gold-500 fill, ink-900 label 15/1.2 (EN 500, AR 600), pressed gold-550, disabled ink-100 + ink-500 label with a stated reason. One per screen. |
| Button secondary | 48 high, 1 px ink-700 outline, ink-900 label, pressed ink-50. Pairs (Reschedule / Decline, Request on compare) are equal width and weight. |
| Button tertiary | 44 high, gold-700 label with 1 px gold-700 underline (8 px below baseline); press shortens underline to 40%. Destructive: danger-700 label on danger-100, icon + label, 48. |
| Input | 56 high, radius 8, paper, 1 px ink-500 border; focus ink-900 2 px; error danger-700 border + icon + message; label above (label role), hint caption ink-600; phone is one LTR compound field (ADR 0012). |
| Chip | 44 high, radius 8, 1 px ink-300 border, body-s; selected = ink-900 border on paper + 8 px gold bead, weight 500. |
| Segmented (hall, session, Availability / Prices) | track ink-100 radius 12, 4 inner pad, option 44, selected = ink-700 fill, canvas label, radius 8; serif only for hall names (d1). |
| Tabs | 48 high, label 15 muted; selected ink-900 500 with 2 px gold-500 thread sliding under, 1 px ink-300 baseline rule. |
| Tab bar | canvas, 1 px ink-200 top rule; 5 items min 56; active ink-900 + 24 x 2 gold-500 khayt on the top edge; inactive ink-600; count badge 20 gold. Client: Discover, Saved, Wedding, Messages, Profile (ADR 0007). Hotel: Today, Bookings, Calendar, Messages, More (ADR 0008). |
| Toggle | 52 x 32 (44 hit), off paper + ink-500 ring, on ink-700 with canvas knob and ink-900 check; never gold. |
| Status pill | min 24, radius 4, icon 16 + label 12/16 500 (AR 13/20 600). pending gold-100 / gold-700; confirmed success; declined danger; neutral ink-50 / ink-700; outline. Mapping per ADR 0003 D7. |
| Count badge | 20 min, full radius, gold-500 fill, ink-900 12 px Cairo 600; ring 2 px canvas on tabs; danger variant (danger-700 fill, canvas text) only for SLA danger (ADR 0008 D2). |
| Venue card (ADR 0018) | unframed, 4:5 image radius 12, one badge, canvas 32 px disks in 44 targets (heart end, compare start), name serif d1 (feature card d2) with rating at end as separate items, hairline, availability line with gold-700 bead, price line. No border, no shadow. |
| Panel | paper, 1 px ink-300, radius 12, padding 16; rose-100 panel only for offers and quiet notes; "YOUR DATE" is a ruled strip (hairline above and below), not a panel. |
| List row | min 64, 1 px ink-200 bottom, title 16/24 500 ink-900 (AR 17/28), sub caption ink-600, end slot, chevron mirrored; hotel queue row 80 (name, time-left with icon, amount, chevron). |
| Section head | 24 x 1 gold-500 khayt, then title: client serif d2, hotel ui-title; optional label eyebrow (max 2 per screen); `See all` tertiary at end. |
| Sheet | paper, top radius 20, handle 36 x 4 ink-300, padding 12 / 20 / 24 + safe, elev-3, scrim-modal, max 90% height. |
| Toast / Undo | ink-900, canvas text, radius 8, elev-2, action gold-400 (44 hit), 2 px depleting gold line 8 s; sits 16 above the bar. |
| Calendar cell | Sunday-first 7 flex columns, cell 52 high (min 44 wide): figure Cairo 500 15, price caption 12 ink-600 (Prices mode). available: plain; selected: gold-500 fill, ink-900, radius 8, ring; held: 8 px gold-700 bead at the corner + label; booked: ink-500 figure with 1 px strike + `Booked` in legend; past: ink-400; peak (Thu to Sat) band rose-50 at inline-end; headers are short names, never single letters. |
| Brief card (Home) | paper, 1 px ink-300, radius 12, hairline only (ADR 0018 D9), 4 rows of 64 (Date full; Area and Guests split; Budget), each a button, label 13 above value d1-ish 16/24 500; CTA 52 gold `Show N halls free on {date}`. |
| Brief sentence | display 300 24/40 (AR 26/48); connectives ink-700, the four decisions ink-900 with 1 px gold-500 underline (7 px offset) on Home edit state only; echo variants: `results` d1 up to 3 lines, `compare`/`booking` 17/24 up to 2 lines with the budget (and area on booking) clauses omitted; whole block is one 44+ button opening the Brief sheet. |
| Compare (ADR 0009 + Majlis) | thirds 130 / 120 / 143 at 390 / 360 / 430; sticky header 106 x 132 (4:5) thumbs, remove 24 in 44, serif name 2 lines, area; collapses to 56 / 40 px thumbs; label above value; group bands ink-50; `Best in row` bead gold-700 on objective rows only; badges `Best rated`, `Lowest price`, `Closest` as outline pills with bead; range bars 2 px (track ink-200, fill gold-500, ink tick 1.5 x 12 at your guests); action bar below. |
| Compare action bar | canvas, three 48 secondary buttons aligned to columns, hall name caption above each (ellipsis), `Request` / `Book` / `See dates` / `Notify me` / `Official`; a hall becomes gold primary only after the user picks it. |
| Hotel request card | paper, 1 px ink-300, radius 12, top 2 px reply-window bar (ink-500 under 50%, gold-650 from 50%, danger-700 from 80% or under 1 h, always with text), status pill + time-left, date ui-xl, facts row (guests, session, total), monogram + name + call/chat 44, check line, compact Booking Thread, Accept 52 gold, Reschedule + Decline 48 equal. |
| Check line / conflict note | `No other request for this date`: success-700 check + ink-600 text; conflict: gold-700 info icon + `+2 other requests for this date` + tertiary `Compare`. |
| Day timeline | vertical thread: time column 56 (Cairo 600 14/20 + am/pm caption), rail 16, content; done knot gold-500 12, Now knot 16 with ring, open knot 12 ink-500 ring; gold line to Now, ink-200 beyond. |
| 7-day strip | 7 flex columns, min 88 high: weekday label, figure, three 4 px marks: confirmed ink-700, pending gold-500, open hollow ink-300 outline; today ink-900 1 px outline; legend and aria label carry the counts. |
| Ink panels (max one per screen) | hotel header band ink-900 (+ 1 px gold-500 bottom rule), booking-confirmation hero, countdown card; text canvas, muted ink-300, thread on-dark. Never on client Home. |

## 4. The Booking Thread (ADR 0003 D6, ADR 0001)

Five knots: **Request, Approval, Deposit, Balance, Your day**. One component, variants `full` (20 px knots with labels and timestamps), `compact` (12 px, current label only; hotel request card), `vertical` (booking detail, ADR 0003 D6: past knots with absolute times, at most two faint future knots), `on-dark`. Used on: venue date card, booking detail, confirmation, My Wedding, hotel request card. Line 2 px: track ink-200, fill gold-500; knot states: **open** (hollow, 1.5 px ink-500 ring), **now** (gold-500 centre, 3 px gold-650 ring, 3 px canvas gap), **tied** (gold-500 fill, ink-900 check), **ended** (terminal knot with icon, below). A knot ties only when its event is recorded in `booking_events`; times are absolute (ADR 0001 D7).

| ADR 0003 status | Knot 1 Request | 2 Approval | 3 Deposit | 4 Balance | 5 Your day | Notes |
|---|---|---|---|---|---|---|
| `requested` | tied | now (reply window) | open | open | open | `counter_offer`: knot 2 sub-label "New date proposed" |
| instant checkout (`awaiting_deposit` via T02) | tied | tied (auto) | now (hold timer) | open | open | knots 1 and 2 share one timestamp |
| `awaiting_deposit` | tied | tied | now (pay-by time) | open | open | `deposit_verifying`: static label "Verifying payment" |
| `confirmed`, balance not yet due | tied | tied | tied | now (due date shown) | open | countdown text under knot 5 |
| `confirmed`, balance paid | tied | tied | tied | tied | now (days left) | `reschedule_request`: chip beside knot 5 |
| `completed` | tied | tied | tied | tied | tied | event end + 12 h |
| `rejected` | tied | ended: x, danger-700 | open | open | open | status chip `Not accepted` |
| `expired` | tied | ended: clock-off, ink-600 (venue_no_response) | ended at knot 3 if client_no_payment | open | open | the knot that was now becomes ended; earlier knots stay tied |
| `cancelled` | tied | tied if reached | tied if reached | tied if reached | open | the knot that was now becomes ended: x, ink-700 |
| `refunded` | as cancelled | | | | | terminal knot return-arrow on rose-100 ring; Refunded chip |
| `no_show` | tied | tied | tied | tied | ended: user-minus, danger-700 outline | contest link |

Rules: draw-on 480 ms on first reveal, knot pop once on a live state change, nothing loops; the thread is never the sole signal (label and icon always present); direction follows `dir`; the thread draws from inline-start.

## 5. Imagery

| Rule | Value |
|---|---|
| Subject | empty rooms, details, exteriors; no identifiable faces; avatars are monograms (rose-100 disk, d1 serif initial) (ADR 0015) |
| Aspect tokens | 4:5 (cards, category tiles, compare thumbs, package images), 16:10 (hall tour, gallery thumbs, 128 x 80), 1:1 (40 / 56 / 64 thumbs, tray slots 40); heroes are full-bleed, uncropped by shape: Home 400 high, venue gallery 440 high, both starting under the status bar |
| Fit | `object-fit: cover`, no filters, duotone, borders or rounded hero; card images radius 12 |
| Scrims | named tokens only (2.2); top scrim for status icons, bottom scrim only where a headline or counter sits; no text on photography except wordmark, hero headline (max 2 lines, AR too), eyebrow and counter |
| Chrome over photo | canvas disks 44 (ring-fab), counter in canvas text on scrim-bottom; gallery progress = 1 px rule-on-photo with gold-500 fill and a bead |
| Wall label | under a plate: serif name, 1 px hairline, caption fact line, price row; the label does the work, not an overlay |
| Reveal | 480 ms opacity + 3.5% settle, once; static placeholder ink-100; no shimmer |
| Arch | Home hero and onboarding/splash only, shape.arch; no arch on thumbs, sheets, compare, tray |

## 6. Arabic and RTL

| Topic | Rule |
|---|---|
| Layout | logical properties only; `dir` flips thread draw, tab slide, segmented slide, sheet handles, chevrons, back arrows, progress, calendar arrows, range bars and tick; Sunday on the right; currency stays visually left of the number |
| Scale | the single Arabic scale in 2.4; Amiri only at 22 px and above (Cairo below); display word-spacing negative per role; no tracking, italics, uppercase, justify, tatweel before a digit |
| Copy hazards (fix from review) | no `لـ350` (use `لعدد 350`); no `3 س 04 د` (use `باقي 3 ساعات`, ADR 0013 owns words); single-letter weekdays banned (short names); signed numbers and percents isolated (`+12%` keeps the sign left of the digits) |
| Digits | Western by default (ADR 0010); every numeric token is an LTR isolate; Amiri/Newsreader display digits are lining proportional, figures are Cairo tabular; Eastern mode re-checks home, venue, booking review, hotel Today, hotel calendar |
| Mirror registry | mirror: back, chevron, arrow, send, list, sliders, progress, calendar arrows, undo; never: search, heart, check, clock, plus, share, phone, bell, pin, photos, logos, digits, brand marks |
| Brief sentence | native Arabic written, not translated (`حفل نسائي لعدد 350 مدعواً يوم الخميس 14 يناير 2027، في السالمية أو شرق، بميزانية 20,000-35,000 د.ك.`); clause order may differ from English |
| Hero headline | Amiri d4 to d5, 2 lines max, over scrim-low to scrim-bottom; test at 360 |
| Verification | screenshot every screen in both languages at 360 / 390 / 430; Read the Arabic PNG (AGENTS.md) |

## 7. Wordmark

Newsreader 300 "Ghazal" (+0.02em tracking) and Amiri 400 "غزل" (x1.10, no tracking) on a shared baseline; a gold-500 thread at the baseline of thickness max(1.5, 0.03 x size) ends in a knot of max(5, 0.14 x size); the line draws on once (900 ms, session start only). Weights: 300 above 28 px, 400 below (Latin); minimum 20 px Latin, 24 px Arabic; clear space 0.75 cap-height; never recolour the line, never place it above the letters. App-icon study only: Majlis doorway-with-lamp and the ink-900 initial on the thread.

## 8. DO and DON'T

| DO | DON'T |
|---|---|
| Let the photograph carry the screen; one dark panel at most | Ink tab bars, Ink CTA bars, Ink on the client Home |
| Say it with a glyph, a figure or a drawing; one word where a glyph is ambiguous (`02-text-diet.md`) | Captions under facts, subtitles under rows, paragraphs on screen, stock or cartoon illustration, people in drawings |
| One gold fill per screen, on the verb | Gold text, gold toggles, gold panels, gold on both a CTA and a banner |
| Hairlines and tone before shadows | Drop-shadow card grids, uniform identical shadowed cards |
| Serif for names, hero price, the brief sentence | Serif for hotel dates, totals, KPIs, triage data, tables |
| Cairo tabular figures for every aligned number | Poppins digits in columns, hand-typed price strings |
| State in text + icon + shape, thread as reinforcement | Colour-only status, sole-carrier gold-500 hairlines |
| 44 px targets and 20 px gutter everywhere | Off-grid px, a second gutter, targets under 44 |
| Write Arabic natively, check both scripts | Mirror-and-ship, single-letter weekdays, tatweel before digits |

Anti-AI-template list (instant rejection): purple or indigo gradients; glassmorphism; glow and neon; floating 3D blobs; emoji as icons; `Welcome back` tone and any greeting banner or pink greeting card; italic serif accent word (`your evening.`); eyebrow plus gold dash above every card (eyebrow max 2 per screen, dash only at hero and venue header); rainbow category chips and 3x2 stock icon grids (use photo tiles); gradient buttons; centred-everything layouts; lorem ipsum and `John Doe`; bubbly over-rounded shapes (largest radius 20, arch only on hero); lattice or arabesque wallpaper; confetti; looping decoration; urgency counters; count-up numbers; Poppins 600 section titles on the client (serif d2 + khayt); decorative effects that carry no information.

## 9. Flutter-subset deviations (ADR 0024, relaxed by ADR 0031)

| Needed by this direction | Outside subset because | Prototype form | Flutter equivalent |
|---|---|---|---|
| Sticky tab bar, CTA bar, compare action bar | `position: sticky` | allowed with `/* flutter-ok: pinned sliver */` | `Scaffold.bottomNavigationBar` / persistent footer; on venue details the CTA bar replaces the tab bar |
| Compare header collapse (106 x 132 to 56) | scroll-driven CSS animation (dropped, ADR 0031 d3) | scroll listener toggles `is-compact`, 200 ms height tween | pinned `SliverPersistentHeader` with min/max extent, specified as f(scrollOffset dp) |
| Arch crown on Home and onboarding hero | `clip-path` / `mask` | one named arch clip (ADR 0031 d3) | `CustomClipper` from the shape.arch path |
| Thread geometry (knots, % progress) | `%`, `calc()`, grid | flex row of knot, flex:1 segment, knot; segments scaleX, no calc | `ThreadPainter` (path, progress, nodes) with `PathMetric.extractPath` |
| Compare thirds, calendar, brief grid | CSS `grid`, `subgrid` | flex with equal `flex:1` columns; fixed min-heights for names | `Row` of `Expanded`, `Table` for compare rows |
| Uppercase tracked eyebrow | `text-transform` | string authored in sentence case, uppercased by a shared label component (`/* flutter-ok */`) | `label.toUpperCase()` with locale; letterSpacing on EN only |
| Underlined brief tokens with 7 px offset | `text-underline-offset` has no Flutter equivalent | inline-flex word with 1 px bottom border, 44 px hit | `WidgetSpan` word with bottom border |
| `em` letter / word spacing | `em` unit | px tokens per role (2.4) | `TextStyle.letterSpacing`, `wordSpacing` |
| Hollow knots, chips, selected rings | inset box-shadow | borders | `BoxDecoration.border` |
| Rails with snap | scroll-snap | JS formula, width 72% snapped to 4 | `PageView(viewportFraction)` / snap physics |
| Accordions, sheets | native `<details>`, `position: fixed` | custom button + region; overlay anchor | `ExpansionTile`; `showModalBottomSheet` |
| Text balance | `text-wrap: balance` has no equivalent | not relied on; max-lines and copy length budget | none needed |
| Display optical size | variable `opsz` | static instances per role | static fonts at build |

## 10. Carry over from each exploration

| From | File and element | Becomes |
|---|---|---|
| Maison | `maison/direction.css` sections 1-4 (ramps, scrims, type tables, AR block, motion, radius, stroke) | tokens 2.1 to 2.7 |
| Maison | `.cover`, `.home-cover`, `.gallery`, `.pager`, `.plate`, `.pair` | full-bleed heroes, wall-label plates, hairline progress |
| Maison | `.brief__sentence`, `.tok` (board "Brief sentence") | echo line and Home edit state (44 px fix, 360 wrap rule) |
| Maison | `.datebox`, `.summary`, `.pkg` timeline bullets, `.countdown`, `.cmp__tag`, `.cmp__v.best` | ruled YOUR DATE strip, deposit split, ink countdown card, badges, best-in-row |
| Maison | `.tri` check line + conflict note, `.node`, `.eyebrow`, `.rule--gold`, `.mark` | hotel check line, bead, section khayt, wordmark fonts |
| Majlis | `:root` spacing (gutter 20, safe 47 / 34, heights 44 / 48 / 56), `.statusbar`, `.appbar` | layout rules 2.5, real chrome |
| Majlis | `.brief` rows, `.briefpill`, `.swrow` | structured Home card, compact echo, Differences-only row |
| Majlis | `.cmp__head`, `.cmp__row`, `.cmp__band`, `.cmpbar`, `.cmp__st` | compare structure, labelled action bar |
| Majlis | `.seg`, `.pkgs` + `.pkg__incl`, `.cal` + `.day`, `.yourdate__money` | hall segmented, package checks, calendar toggle, deposit split |
| Majlis | `.hhead`, `.tri`, `.tri__actions2`, `.qrow`, `.quick`, `.kpis` | hotel band, request card, queue rows, quick actions |
| Majlis | `.arch` clip geometry, `--arch-rise-hero: 64` | shape.arch (Home / onboarding only) |
| Thread | `.stepper`, `.sched`, `.step__node`, `.sched__i.is-current` | Booking Thread knots and now-ring |
| Thread | `.vt` (vertical thread), `.sla`, week strip | day timeline, reply bar, 7-day strip |
| Thread | `.bar`, `.bar--tick`, `.bar--end`, "How you book" row | compare range bars and row |
| Thread | `.fig`, `.money`, `.fils`, board "Figures" and price table | figures role (Cairo x1.08), price format |
| Thread | `.wordmark` and `.wordmark__line`; `--gold-600` #A67F2E; `--gold-550` | wordmark geometry, gold-650, pressed fill |
| Thread | gold-is-a-verb header comment | lint 2.3 |
| Review fixes | judges (index in `exploration-archive.md`) | 44 px tokens, 360 wrap, no single-letter weekdays, bidi isolates, serif off hotel data, chrome caps |
