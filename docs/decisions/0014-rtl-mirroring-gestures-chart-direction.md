# ADR 0014: RTL mirroring registry, gesture rules and chart direction

| Field | Value |
|---|---|
| Status | accepted |
| Date | 2026-10-12 |
| Scope | Layout, icons, navigation, gestures, charts, media, chat and QA in both apps and the web prototype |
| Owner confirmation still needed | OQ-L-05 (mirrored time axes in Arabic charts; test with five Kuwaiti users before hotel analytics screens are frozen) |
| Related ADRs | 0007 (stacks and back), 0008 (hotel calendar gestures), 0009 (compare in RTL), 0010 and 0012 (isolated numbers and LTR fields), 0017 (direction multiplier in motion), 0022 (Flutter directional widgets), 0023 and 0024 (token and spec mirror lists), 0025 (QA matrix) |
| Screens | all, especially CL-SAVD-04, CL-VENU-02, CL-VENU-03, HL-CALN-01..04, HL-GROW-04, HL-GROW-05, CL-MSGS-02 |

## Context

NF-LOC-02 requires that 'layouts mirror in RTL, including directional icons, progress, sliders, calendars and charts'. Arabic is a first-class design target, not a mirrored afterthought. Research established:

- Mirror what carries reading-order meaning; never mirror what is physical, universal or non-directional (media transport, clocks, checkmarks, maps, logos, digits). Apple and Material guidance agree on most of the table.
- **The one place they disagree is charts.** Apple says graphs do not flip; Material says time depicts right-to-left in RTL while circular charts do not mirror. Inside one product the calendar, week strip, stepper and timeline all mirror, so a chart that runs the other way would contradict them. NF-LOC-02 is the tie-breaker.
- iOS edge-swipe back starts at the right edge in Arabic (system behaviour). Horizontal edge swipes elsewhere collide with it, which is also why Compare avoids horizontal scrolling (ADR 0009).
- Swipe-to-reveal row actions are ambiguous when mirrored and inaccessible; the hotel request card has none (ADR 0008 D5).
- Designers drawing Arabic by flipping an English frame get icons, progress and currency placement wrong.
- Hard-coded animation signs break RTL; a direction multiplier fixes it everywhere (ADR 0017).

## Decision

**1. Layout.** Logical properties only (`margin-inline-start`, `inset-inline-end`, `text-align: start`); Flutter `EdgeInsetsDirectional`, `PositionedDirectional`, `AlignmentDirectional`. No physical left/right in layout code, and no hard-coded sign in animations: a `--dir: 1 | -1` multiplier drives all horizontal motion.

**2. Icon registry.** Every icon carries a `mirror` flag; an icon without a flag fails lint; Flutter uses `matchTextDirection` from the same registry.

| Mirror (reading-order meaning) | Never mirror (physical or non-directional) |
|---|---|
| back and forward chevrons and arrows (back points right in Arabic), list-row disclosure chevrons, next/previous | play, pause, skip, rewind and every audio or video scrubber |
| send, reply, forward, undo/redo, external-link, sign-in/sign-out | clocks, timers, circular refresh and circular progress |
| text-line glyphs (list, sort, notes, menu) | checkmark, plus, minus, close |
| help `?` (renders `؟`) | calendar glyph; phone handset |
| switches (on = knob toward inline-end), segmented controls, tab order and bottom-nav order (first tab at the right) | camera, image, microphone; magnifier |
| steppers and breadcrumbs, linear progress, sliders (min at inline-start) | location pin, compass, map |
| calendar grids and month arrows | heart, star, bookmark, bell |
| rating-star row fill, page-indicator order, carousels (first item at the right) | share (box with up arrow) |
| | filter funnel and settings sliders glyph |
| | chart-type icons and trend arrows (up means more) |
| | digits and Latin text; photos, maps, logos, QR codes |

**3. Navigation.** Back is a chevron at the top inline-start. Push enters from inline-end and exits toward inline-start; pop reverses; sheet-over-sheet follows the same rule. iOS edge-swipe back starts at the right edge in Arabic (system behaviour, never overridden); Android system back is unchanged. Bottom sheets drag vertically only and keep a centred handle, title at inline-start, close at inline-end.

**4. Gestures.** Swipe-to-reveal row actions are not used in v1 (hidden, ambiguous when mirrored, inaccessible); every action has a visible control or a long-press menu, and the hotel request card has none. Image galleries and carousels start with the first image at the right in Arabic and advance with a leftward swipe; horizontal shelves start scrolled to inline-start with the peeking card at inline-end. Hotel calendar range select (long-press then drag, plus a tap-select mode for accessibility) mirrors its drag direction with the week. Pinch, pull-to-refresh and vertical scroll are unaffected. Counters read `1 من 6` / `1 of 6` with LTR digits.

**5. Charts and time axes (the recorded exception).** Time and ordinal axes run in reading direction, so earlier-to-later is right-to-left in Arabic, matching the mirrored calendar, week strip, stepper and timeline in the same product; NF-LOC-02 is the tie-breaker between the Apple and Material guidance. The value axis never flips (up is more); y-axis labels sit at the inline-start edge; horizontal bars (funnel, top packages) grow from inline-start; sparklines mirror; every chart labels its first and last date explicitly and has a table twin; digits stay Western and LTR. Validate with five Kuwaiti users (OQ-L-05).

**6. Media and chat.** Voice-note and message layout mirrors (play button at inline-start, duration at inline-end, fill grows away from the button) but the play triangle never flips; full-screen video and audio keep an LTR scrubber. Own chat bubbles align to inline-end (left in Arabic) and the bubble tail follows. Message text sits in a `dir="auto"` container so each message aligns by its own first strong character.

**7. Compare and lists.** The first venue added sits at inline-start (right in Arabic); the three-column compare table is full-bleed fluid thirds with the label above each row, so no pinned label column fights the edge-swipe. Two-button rows put the primary action at inline-end (left in Arabic).

**8. Mixed-direction text.** Names, search fields, chat and reviews use `dir="auto"`; phone, email, codes and money are LTR isolates (ADR 0010 and 0012). Ellipsis never truncates through a number or isolate; names get two lines first.

**9. Language switch.** Switching language at runtime (NF-LOC-06) flips direction immediately without restart, preserves scroll position and open sheet state where possible, and re-renders formatter output.

**10. QA checklist,** every screen, both languages, 360/390/430: registry respected; no physical left/right; numbers, prices, phones and dates isolated and unscrambled; currency visually left of the number; Arabic sizes per ADR 0016; LTR fields behave; Sunday at inline-start with the Thu-Sat band at inline-end; tabs, stepper, slider, progress and star fill mirror; photos, maps and logos unmirrored; no Eastern digits unless the Settings switch is on.

## Consequences

- A single registry and a single direction multiplier make RTL a property of the system, not of each screen; lint can enforce it (Stylelint `use-logical`, the Dart guardrail script in ADR 0022 K).
- Mirrored time-series charts are the less common choice and could surprise some users; the table twin and explicit first/last labels are the safeguard until tested.
- Dropping swipe actions removes a familiar shortcut; compensated with visible buttons and long-press menus.
- Designers must draw Arabic screens as true mirrors through the real components, not by flipping an English frame in a design tool.
- Component specs carry `rtl.mirror[]` and `rtl.noMirror[]` lists (ADR 0024 item 5); the prototype's `--dir` multiplier maps to Flutter `Directionality`.
- Goldens run both locales at 360/390/430 and a shaping-and-bidi sheet (ADR 0025).
- The hotel analytics screens (HL-GROW-04, HL-GROW-05) are not frozen until OQ-L-05 testing happens or is waived.

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Do not mirror charts (Apple guidance) | Contradicts the mirrored calendar, week strip, stepper and timeline in the same product; NF-LOC-02 says charts mirror |
| Mirror everything including value axes and trend arrows | Up means more; trend and chart-type icons never flip |
| Swipe-to-reveal row actions | Hidden, ambiguous when mirrored, inaccessible |
| Pinned label column in Compare | Collides with the iOS edge back-swipe; third venue off-screen |
| Hard-coded left/right and sign flips per screen | Breaks on every new component; one `--dir` multiplier instead |
| Mirror play, clock and refresh glyphs | Media transport and clockwise rotation are universal |
| Flip an English design frame to draw Arabic | Wrong icons, progress and currency placement; Arabic is designed through real components |
| Override the system edge-swipe-back in RTL | System behaviour is correct (right edge in Arabic) |
| Truncate Arabic names with an end ellipsis | Cuts through numbers or isolates; two lines first |

## Related requirement IDs

| ID | Effect |
|---|---|
| NF-LOC-01, NF-LOC-02, NF-LOC-06 | Full RTL, mirrored layouts and charts, runtime switch |
| CA-CMP-04 | Compare table layout |
| CA-CHAT-06..09 | Chat bubbles, media and voice notes |
| HA-CAL-04 | Hotel range select with tap-select mode |
| HA-ANLY-01..07 | Analytics charts with mirrored time axes and table twins |
| CA-VDET-01, CA-VDET-02 | Gallery and video: first image at the right; LTR scrubber |
| CA-TOOL-18 | Countdown thread fills in reading direction |
