# ADR 0017: Motion principles: explain, never decorate; four durations, two curves, one thread

| Field | Value |
|---|---|
| Status | accepted. Update: refined by ADR 0030 (thread draw-on 480 ms, press, exits, reduced motion, 1 px section khayt; see ADR 0030 Decision 8) |
| Date | 2026-10-12 |
| Scope | All animation and haptics in both apps and the web prototype; motion tokens; reduced motion |
| Owner confirmation still needed | None. Hotel calendar stagger and drag haptics need real-device tuning in the Flutter phase |
| Related ADRs | 0003 (the Booking Thread), 0008 (hotel calendar range select, Undo toast), 0009 (compare tray motion), 0014 (direction multiplier), 0023 (motion tokens), 0024 (CSS to Flutter motion mapping), 0025 (reduced-motion shots) |
| Screens | CL-BOOK-01..06, CL-PAYM-05, CL-SAVD-02, CL-VENU-02, CL-WEDD-02, HL-DCSN-01, HL-CALN-04 |

## Context

The brief says motion explains: every animation answers 'where did that come from / where did it go / did it work?', nothing blocks input, nothing exceeds 500 ms except deliberate success moments, nothing decorative loops, and `prefers-reduced-motion` is respected. Required behaviours include direction-aware push and pop (flipping in RTL), bottom-sheet rise and dismiss with drag, shared-element image expansion, press feedback, stepper progress, selection, skeleton to content, success confirmation, calendar range selection, favourite toggle and compare-tray insertion.

Research and constraints:

- Quiet-luxury references use 120-240 ms responses and opacity or crop reveals, no decorative loops, no parallax everywhere, no confetti, no 3D animated icons (Airbnb's mass-market style).
- A ticking countdown with seconds creates anxiety; money and counts must not count up or roll (readability and honesty).
- Web and Flutter are mathematically identical in two places: cubic-bezier curves and the damped-spring model. Everything else (View Transitions, scroll-linked CSS, blur) is not cheap to reproduce, so mapping must be exact where it can be and the rest forbidden (ADR 0024).
- Springs must use `mass`, `stiffness`, `damping` identically in the `motion` library and Flutter's `SpringDescription`, never duration/bounce parameters.
- Performance: `backdrop-filter` and animated layout are costly on mid Android; animate transform and opacity only.
- The brand idea 'غزل' (thread) should become interaction only when it is always informative.

## Decision

**1. Principle.** Every animation answers one of three questions: where did that come from, where did it go, did it work. If it answers none, it is removed. Nothing loops except an OS-standard activity indicator while work is genuinely pending.

**2. Duration tokens.**

| Token | Value | Use |
|---|---|---|
| `motion.duration.fast` | 120 ms | press, toggle, tooltip, cross-fade |
| `motion.duration.base` | 200 ms | selection, state change, skeleton to content, chip, tray slot |
| `motion.duration.slow` | 320 ms | push and pop, sheet rise, thread draw-on, tray rise |
| `motion.duration.expressive` | 480 ms | shared-element image expansion, one per navigation |
| `motion.duration.success` | 640 ms | the one success moment per flow, the only value above 500 |

Dismissals run at 75% of the entering duration. Nothing blocks input: targets stay tappable during transitions.

**3. Curve tokens.** `motion.ease.standard` = cubic-bezier(0.2, 0, 0, 1) for state changes, small moves and exits; `motion.ease.emphasized` = cubic-bezier(0.05, 0.7, 0.1, 1) for entrances of large elements (sheets, push, shared element). Gesture release uses one critically damped spring `motion.spring.settle` {mass 1, stiffness 400, damping 40}: it continues the finger's velocity and never overshoots.

**4. Direction and distance.** Push enters from inline-end with a 24 px translate plus fade (`motion.distance.push`), pop reverses; all horizontal motion is multiplied by the `--dir` variable of ADR 0014. Sheets rise from the bottom and are dismissed by dragging down or tapping the scrim. Carousels settle in reading direction. Media scrubbers and clock or refresh glyphs never reverse.

**5. Required behaviours.**

| Behaviour | Spec |
|---|---|
| Press | scale 0.98 plus a 6% Ink tonal overlay over 120 ms, no ripple |
| Shared element | tapped card image expands into the gallery over 480 ms with the radius morphing from 12 to 0; swipe-down shrinks it back; the viewer background is the deepest Ink token, not pure black |
| Selection | 200 ms border and check fade; chips and options never resize |
| Skeleton to content | skeletons are static Rose-tint blocks (no shimmer); images reveal from their blurhash by a 200 ms cross-fade; if loading passes 2 s a quiet inline 'still loading' line appears |
| Stepper and progress | the thread draws on over 320 ms |
| Favourite | fill change plus a 120 ms scale 1 to 1.08 to 1, no bounce |
| Compare tray | rises 320 ms, the new thumbnail fades and scales 0.9 to 1 over 200 ms, collapses to a pill after 3 s idle and hides on scroll-down |
| Hotel calendar range select | cells fill with a 120 ms stagger capped at five cells; a haptic tick per day |
| Checklist completion | a 160 ms check draw, then the row moves to Completed after about 600 ms with an undo snackbar; no confetti |
| Success | one moment per flow (booking confirmed, request accepted): the thread completes along the timeline and the check draws within the 640 ms success token, with a success haptic; no confetti, no particles |

**6. The thread (غزل).** One motif: a 2px Gold hairline over an Ink-tint track, used only as progress or timeline (booking stepper, checklist progress, countdown milestones, status timeline, mini payment schedule), drawn on over 320 ms, filling in reading direction (from the right in Arabic). It never loops, never works as a decorative divider or surface ornament, and each component owns at most one thread.

**7. Numbers and text.** Money and counts never roll or count up; a changed total swaps instantly or cross-fades over 120 ms. No per-letter or per-word text animation.

**8. Performance rules.** Animate transform and opacity only; no animated layout or blur; at most two concurrent animations on screen; Flutter parity through the token table in the handoff (Cubic, Duration, Hero with a radius-morph shuttle, SpringDescription, TweenSequence capped at three keyframes).

**9. Reduced motion** (`prefers-reduced-motion`, `MediaQuery.disableAnimations`). Spatial transitions become a 120 ms cross-fade, shared-element becomes a cross-fade, the thread fills instantly, tray collapse and header collapse become instant; nothing is removed that carries information.

**10. Haptics** (mobile only): a selection tick for chips, dates and toggles; a light impact for favourite and compare; one success notification per success moment; none for scroll or navigation.

## Consequences

- Motion is a small, enforceable vocabulary that maps cleanly to Flutter; the thread gives the brand a recognisable gesture that is always informative.
- Static skeletons and no count-up animation trade some perceived polish for readability and battery.
- A 640 ms success token is a deliberate exception to the 500 ms rule and must stay unique per flow.
- The hotel calendar stagger and drag haptics need real-device tuning in the Flutter phase.
- Token additions: `motion.duration.success`, `motion.distance.push`, `motion.spring.settle`, plus `motion.reduced.*`; ADR 0023 lists 120/200/320/480 ms as the pinned set, so the token file must add the 640 ms success value and this ADR records why.
- Flutter mapping: `Cubic`, `Duration`, `SpringDescription(mass, stiffness, damping)`, `Hero` with `flightShuttleBuilder` and tag `hero:<entity>:<id>:<part>`, stroke-dash draw-on through `PathMetric.extractPath`, `MediaQuery.disableAnimationsOf`, haptics via `HapticFeedback` (ADR 0024 item 9).
- Shots and goldens run with reduced motion on so screenshots are deterministic (ADR 0025).

## Alternatives considered

| Alternative | Why rejected |
|---|---|
| Confetti, particles or Lottie flourishes on success | Childish, off-brand; the thread completing is the one success moment |
| Count-up and rolling numbers | Money must be readable and honest; swap or 120 ms cross-fade |
| Shimmer skeletons | Constant motion and battery; static Rose-tint blocks |
| Bounce or overshoot springs (duration/bounce parameters) | Not portable to Flutter; one critically damped spring |
| Longer durations (500-700 ms image reveals as on luxury sites) | Brief caps at 500 ms except one success moment |
| Parallax, auto-advancing carousels, autoplay video | Performance and calm |
| Animated layout, blur or backdrop effects | Jank on mid Android; not expressible in the Flutter subset |
| Per-letter text animation | No information; accessibility cost |
| A looping decorative thread | The thread is progress or timeline only |
| Hard-coded left/right slide directions | `--dir` multiplier (ADR 0014) |
| Material default motion tokens | The brand's four durations and two curves are exact and mapped |

## Related requirement IDs

| ID | Effect |
|---|---|
| NF-DSN-01, NF-DSN-03, NF-DSN-09 | Luxury restraint; one consistent component library |
| NF-LOC-02 | Direction-aware motion |
| CA-TOOL-13, CA-TOOL-18, CA-TOOL-19 | Checklist completion; countdown thread |
| CA-CMP-01..03 | Compare tray insertion and collapse |
| CA-VDET-01 | Card to gallery shared element |
| CA-BOOK-12 | Booking confirmation success moment |
| HA-CAL-04 | Range select stagger and haptics |
| HA-BOOK-03 | Accept toast with Undo bar (ADR 0008 D6) |
